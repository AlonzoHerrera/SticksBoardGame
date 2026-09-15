import '../models/ai_difficulty.dart';

class ExperimentResult {
  final AiDifficulty opponentDifficulty;
  final int requestedGames;
  final int gamesPlayed;
  final int llmWins;
  final int aiWins;
  final int draws;
  final int totalActions;
  final int fallbackMoves;
  final Duration duration;

  /// Stores the most recent reason the LLM used its fallback strategy.
  ///
  /// This will be null when no fallback error was recorded.
  final String? lastLlmError;

  const ExperimentResult({
    required this.opponentDifficulty,
    required this.requestedGames,
    required this.gamesPlayed,
    required this.llmWins,
    required this.aiWins,
    required this.draws,
    required this.totalActions,
    required this.fallbackMoves,
    required this.duration,
    required this.lastLlmError,
  });

  double get llmWinRate {
    if (gamesPlayed == 0) {
      return 0;
    }

    return llmWins / gamesPlayed;
  }

  double get aiWinRate {
    if (gamesPlayed == 0) {
      return 0;
    }

    return aiWins / gamesPlayed;
  }

  double get averageActions {
    if (gamesPlayed == 0) {
      return 0;
    }

    return totalActions / gamesPlayed;
  }

  bool get usedFallback {
    return fallbackMoves > 0;
  }

  bool get hasLlmError {
    return lastLlmError != null && lastLlmError!.trim().isNotEmpty;
  }
}
