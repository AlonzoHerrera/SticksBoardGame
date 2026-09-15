import 'dart:math';

import '../ai/ai_strategy.dart';
import '../ai/ai_strategy_factory.dart';
import '../ai/ai_turn_controller.dart';
import '../ai/llm_strategy.dart';
import '../game/game.dart';
import '../game/game_state.dart';
import '../models/match_configuration.dart';
import 'experiment_result.dart';

typedef ExperimentProgressCallback =
    void Function({
      required int completedGames,
      required int totalGames,
      required int llmWins,
      required int aiWins,
      required int draws,
    });

class LlmVsAiRunner {
  static const int maximumActionsPerGame = 2000;

  final AiTurnController turnController;
  final AiStrategyFactory strategyFactory;

  const LlmVsAiRunner({
    this.turnController = const AiTurnController(),
    this.strategyFactory = const AiStrategyFactory(),
  });

  Future<ExperimentResult> run({
    required MatchConfiguration configuration,
    ExperimentProgressCallback? onProgress,
  }) async {
    if (!configuration.isLlmDifficultyTest) {
      throw ArgumentError(
        'The configuration must use LLM difficulty test mode.',
      );
    }

    final opponentDifficulty = configuration.aiDifficulty!;
    final stopwatch = Stopwatch()..start();

    var llmWins = 0;
    var aiWins = 0;
    var draws = 0;
    var totalActions = 0;
    var fallbackMoves = 0;

    String? lastLlmError;

    for (
      var gameIndex = 0;
      gameIndex < configuration.experimentGameCount;
      gameIndex++
    ) {
      final game = Game(playerCount: 2, random: Random(gameIndex + 1));

      final llmStrategy = LlmStrategy();

      final opponentStrategy = strategyFactory.create(
        difficulty: opponentDifficulty,
        random: Random(10000 + gameIndex),
      );

      var actions = 0;

      while (game.state != GameState.gameOver &&
          actions < maximumActionsPerGame) {
        final strategy = _strategyForCurrentTeam(
          game: game,
          llmStrategy: llmStrategy,
          opponentStrategy: opponentStrategy,
        );

        /*
         * CRITICAL:
         * This must use performNextActionAsync and must be awaited.
         *
         * Using performNextAction would call the synchronous LLM fallback
         * instead of waiting for the OpenAI API response.
         */
        await turnController.performNextActionAsync(
          game: game,
          strategy: strategy,
        );

        actions++;
      }

      totalActions += actions;
      fallbackMoves += llmStrategy.fallbackCount;

      final currentError = llmStrategy.lastError;

      if (currentError != null && currentError.trim().isNotEmpty) {
        lastLlmError = currentError.trim();
      }

      final winningTeam = game.winningTeam;

      if (game.state != GameState.gameOver || winningTeam == null) {
        draws++;
      } else if (winningTeam.id == 0) {
        llmWins++;
      } else {
        aiWins++;
      }

      onProgress?.call(
        completedGames: gameIndex + 1,
        totalGames: configuration.experimentGameCount,
        llmWins: llmWins,
        aiWins: aiWins,
        draws: draws,
      );

      // Allows Flutter to refresh the progress screen between games.
      await Future<void>.delayed(Duration.zero);
    }

    stopwatch.stop();

    return ExperimentResult(
      opponentDifficulty: opponentDifficulty,
      requestedGames: configuration.experimentGameCount,
      gamesPlayed: configuration.experimentGameCount,
      llmWins: llmWins,
      aiWins: aiWins,
      draws: draws,
      totalActions: totalActions,
      fallbackMoves: fallbackMoves,
      duration: stopwatch.elapsed,
      lastLlmError: lastLlmError,
    );
  }

  AiStrategy _strategyForCurrentTeam({
    required Game game,
    required LlmStrategy llmStrategy,
    required AiStrategy opponentStrategy,
  }) {
    final currentTeam = game.currentTeam;

    if (currentTeam == null) {
      throw StateError('The game has no current team.');
    }

    // Team 1, ID 0, is controlled by the LLM.
    if (currentTeam.id == 0) {
      return llmStrategy;
    }

    // Team 2, ID 1, uses the selected normal AI difficulty.
    return opponentStrategy;
  }
}
