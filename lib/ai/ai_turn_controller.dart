import '../game/game.dart';
import '../game/game_rule_exception.dart';
import '../game/game_state.dart';
import '../game/throw_result.dart';
import 'ai_game_snapshot.dart';
import 'ai_strategy.dart';
import 'game_move.dart';
import 'game_move_adapter.dart';

enum AiActionType {
  normalMove,
  specialCapture,
  skippedMove,
  specialThrowWithoutTarget,
  gameOver,
}

class AiTurnResult {
  final AiActionType actionType;
  final String strategyName;
  final int? actingPlayerId;
  final String? actingPlayerName;
  final int? actingTeamId;
  final ThrowResult? throwResult;
  final GameMove? selectedMove;
  final int? winningTeamId;
  final String? winningTeamName;

  const AiTurnResult({
    required this.actionType,
    required this.strategyName,
    required this.actingPlayerId,
    required this.actingPlayerName,
    required this.actingTeamId,
    required this.throwResult,
    required this.selectedMove,
    required this.winningTeamId,
    required this.winningTeamName,
  });

  bool get moved {
    return actionType == AiActionType.normalMove ||
        actionType == AiActionType.specialCapture;
  }

  bool get skipped {
    return actionType == AiActionType.skippedMove;
  }

  bool get isGameOver {
    return actionType == AiActionType.gameOver || winningTeamId != null;
  }

  String get message {
    switch (actionType) {
      case AiActionType.normalMove:
        return '$actingPlayerName used $strategyName and made a normal move.';

      case AiActionType.specialCapture:
        return '$actingPlayerName used $strategyName and made an X stick capture.';

      case AiActionType.skippedMove:
        return '$actingPlayerName had no legal move and skipped the move.';

      case AiActionType.specialThrowWithoutTarget:
        return '$actingPlayerName threw the X stick, but there was no opponent piece to capture.';

      case AiActionType.gameOver:
        if (winningTeamName != null) {
          return '$winningTeamName won the game.';
        }

        return 'The game is over.';
    }
  }

  @override
  String toString() {
    return message;
  }
}

class AiTurnController {
  final GameMoveAdapter moveAdapter;

  const AiTurnController({this.moveAdapter = const GameMoveAdapter()});

  /// Runs one AI action for a normal synchronous AI strategy.
  ///
  /// Random Easy, Greedy Medium, and Heuristic Hard can use this method.
  AiTurnResult performNextAction({
    required Game game,
    required AiStrategy strategy,
  }) {
    if (strategy is AsyncAiStrategy) {
      throw GameRuleException(
        '${strategy.name} requires performNextActionAsync().',
      );
    }

    return _performNextActionSync(game: game, strategy: strategy);
  }

  /// Runs one AI action and supports both synchronous and asynchronous
  /// strategies.
  ///
  /// The LLM strategy must use this method because it waits for an API
  /// response before choosing a move.
  Future<AiTurnResult> performNextActionAsync({
    required Game game,
    required AiStrategy strategy,
  }) async {
    final actingPlayer = game.currentPlayer;
    final actingTeam = game.currentTeam;

    if (game.state == GameState.gameOver) {
      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.gameOver,
        actingPlayerId: actingPlayer?.id,
        actingPlayerName: actingPlayer?.name,
        actingTeamId: actingTeam?.id,
        selectedMove: null,
        throwResult: game.lastThrowResult,
      );
    }

    if (actingPlayer == null || actingTeam == null) {
      throw GameRuleException(
        'The AI cannot act because there is no current player or team.',
      );
    }

    if (game.state == GameState.waitingForThrow) {
      game.throwSticks();
    }

    final throwResult = game.lastThrowResult;

    // An X stick was thrown without an available target.
    // The same player stays active and may throw again.
    if (game.state == GameState.waitingForThrow) {
      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.specialThrowWithoutTarget,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: null,
        throwResult: throwResult,
      );
    }

    if (game.state == GameState.waitingForMove) {
      final legalMoves = moveAdapter.legalMoves(game);

      if (legalMoves.isEmpty) {
        game.skipMoveIfNoLegalMove();

        return _result(
          game: game,
          strategy: strategy,
          actionType: AiActionType.skippedMove,
          actingPlayerId: actingPlayer.id,
          actingPlayerName: actingPlayer.name,
          actingTeamId: actingTeam.id,
          selectedMove: null,
          throwResult: throwResult,
        );
      }

      _prepareStrategy(game: game, strategy: strategy);

      final selectedMove = await _selectMoveAsync(
        strategy: strategy,
        legalMoves: legalMoves,
      );

      if (!selectedMove.isNormal) {
        throw GameRuleException(
          'The AI selected a special move during a normal move state.',
        );
      }

      moveAdapter.applyMove(game, selectedMove);

      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.normalMove,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: selectedMove,
        throwResult: throwResult,
      );
    }

    if (game.state == GameState.waitingForSpecialMove) {
      final legalMoves = moveAdapter.legalMoves(game);

      if (legalMoves.isEmpty) {
        throw GameRuleException(
          'A special move is pending, but no legal special moves were generated.',
        );
      }

      _prepareStrategy(game: game, strategy: strategy);

      final selectedMove = await _selectMoveAsync(
        strategy: strategy,
        legalMoves: legalMoves,
      );

      if (!selectedMove.isSpecialCapture) {
        throw GameRuleException(
          'The AI selected a normal move during a special move state.',
        );
      }

      moveAdapter.applyMove(game, selectedMove);

      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.specialCapture,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: selectedMove,
        throwResult: throwResult,
      );
    }

    throw GameRuleException(
      'The AI cannot act during game state ${game.state}.',
    );
  }

  AiTurnResult _performNextActionSync({
    required Game game,
    required AiStrategy strategy,
  }) {
    final actingPlayer = game.currentPlayer;
    final actingTeam = game.currentTeam;

    if (game.state == GameState.gameOver) {
      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.gameOver,
        actingPlayerId: actingPlayer?.id,
        actingPlayerName: actingPlayer?.name,
        actingTeamId: actingTeam?.id,
        selectedMove: null,
        throwResult: game.lastThrowResult,
      );
    }

    if (actingPlayer == null || actingTeam == null) {
      throw GameRuleException(
        'The AI cannot act because there is no current player or team.',
      );
    }

    if (game.state == GameState.waitingForThrow) {
      game.throwSticks();
    }

    final throwResult = game.lastThrowResult;

    // An X stick was thrown without an available target.
    // The same player stays active and may throw again.
    if (game.state == GameState.waitingForThrow) {
      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.specialThrowWithoutTarget,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: null,
        throwResult: throwResult,
      );
    }

    if (game.state == GameState.waitingForMove) {
      final legalMoves = moveAdapter.legalMoves(game);

      if (legalMoves.isEmpty) {
        game.skipMoveIfNoLegalMove();

        return _result(
          game: game,
          strategy: strategy,
          actionType: AiActionType.skippedMove,
          actingPlayerId: actingPlayer.id,
          actingPlayerName: actingPlayer.name,
          actingTeamId: actingTeam.id,
          selectedMove: null,
          throwResult: throwResult,
        );
      }

      _prepareStrategy(game: game, strategy: strategy);

      final selectedMove = strategy.chooseValidatedMove(legalMoves: legalMoves);

      if (!selectedMove.isNormal) {
        throw GameRuleException(
          'The AI selected a special move during a normal move state.',
        );
      }

      moveAdapter.applyMove(game, selectedMove);

      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.normalMove,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: selectedMove,
        throwResult: throwResult,
      );
    }

    if (game.state == GameState.waitingForSpecialMove) {
      final legalMoves = moveAdapter.legalMoves(game);

      if (legalMoves.isEmpty) {
        throw GameRuleException(
          'A special move is pending, but no legal special moves were generated.',
        );
      }

      _prepareStrategy(game: game, strategy: strategy);

      final selectedMove = strategy.chooseValidatedMove(legalMoves: legalMoves);

      if (!selectedMove.isSpecialCapture) {
        throw GameRuleException(
          'The AI selected a normal move during a special move state.',
        );
      }

      moveAdapter.applyMove(game, selectedMove);

      return _result(
        game: game,
        strategy: strategy,
        actionType: AiActionType.specialCapture,
        actingPlayerId: actingPlayer.id,
        actingPlayerName: actingPlayer.name,
        actingTeamId: actingTeam.id,
        selectedMove: selectedMove,
        throwResult: throwResult,
      );
    }

    throw GameRuleException(
      'The AI cannot act during game state ${game.state}.',
    );
  }

  /// Chooses a move using the correct synchronous or asynchronous interface.
  ///
  /// This method is placed directly inside AiTurnController. It is not
  /// nested inside another method.
  Future<GameMove> _selectMoveAsync({
    required AiStrategy strategy,
    required List<GameMove> legalMoves,
  }) async {
    if (strategy is AsyncAiStrategy) {
      final asyncStrategy = strategy as AsyncAiStrategy;

      return asyncStrategy.chooseValidatedMoveAsync(legalMoves: legalMoves);
    }

    return strategy.chooseValidatedMove(legalMoves: legalMoves);
  }

  void _prepareStrategy({required Game game, required AiStrategy strategy}) {
    if (strategy is SnapshotAwareAiStrategy) {
      final snapshot = AiGameSnapshot.fromGame(game, adapter: moveAdapter);

      strategy.updateSnapshot(snapshot);
    }
  }

  AiTurnResult _result({
    required Game game,
    required AiStrategy strategy,
    required AiActionType actionType,
    required int? actingPlayerId,
    required String? actingPlayerName,
    required int? actingTeamId,
    required GameMove? selectedMove,
    required ThrowResult? throwResult,
  }) {
    final winner = game.winningTeam;

    return AiTurnResult(
      actionType: winner == null ? actionType : AiActionType.gameOver,
      strategyName: strategy.name,
      actingPlayerId: actingPlayerId,
      actingPlayerName: actingPlayerName,
      actingTeamId: actingTeamId,
      throwResult: throwResult,
      selectedMove: selectedMove,
      winningTeamId: winner?.id,
      winningTeamName: winner?.name,
    );
  }
}
