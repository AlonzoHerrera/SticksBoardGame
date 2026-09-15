import 'ai_difficulty.dart';
import 'game_mode.dart';

class MatchConfiguration {
  static const int minimumPlayerCount = 2;
  static const int maximumPlayerCount = 4;

  static const int minimumExperimentGames = 1;
  static const int maximumExperimentGames = 10000;

  final GameMode gameMode;
  final int playerCount;
  final AiDifficulty? aiDifficulty;
  final int humanTeamId;
  final int experimentGameCount;
  final bool showExperimentGames;

  const MatchConfiguration._({
    required this.gameMode,
    required this.playerCount,
    required this.aiDifficulty,
    required this.humanTeamId,
    required this.experimentGameCount,
    required this.showExperimentGames,
  });

  factory MatchConfiguration.localMultiplayer({
    required int playerCount,
  }) {
    final configuration = MatchConfiguration._(
      gameMode: GameMode.localMultiplayer,
      playerCount: playerCount,
      aiDifficulty: null,
      humanTeamId: 0,
      experimentGameCount: 0,
      showExperimentGames: false,
    );

    configuration.validate();

    return configuration;
  }

  factory MatchConfiguration.humanVsAi({
    required AiDifficulty aiDifficulty,
    int humanTeamId = 0,
  }) {
    final configuration = MatchConfiguration._(
      gameMode: GameMode.humanVsAi,
      playerCount: 2,
      aiDifficulty: aiDifficulty,
      humanTeamId: humanTeamId,
      experimentGameCount: 0,
      showExperimentGames: false,
    );

    configuration.validate();

    return configuration;
  }

  factory MatchConfiguration.llmDifficultyTest({
    required AiDifficulty aiDifficulty,
    int experimentGameCount = 100,
    bool showExperimentGames = false,
  }) {
    final configuration = MatchConfiguration._(
      gameMode: GameMode.llmDifficultyTest,
      playerCount: 2,
      aiDifficulty: aiDifficulty,
      humanTeamId: 0,
      experimentGameCount: experimentGameCount,
      showExperimentGames: showExperimentGames,
    );

    configuration.validate();

    return configuration;
  }

  bool get isLocalMultiplayer {
    return gameMode == GameMode.localMultiplayer;
  }

  bool get isHumanVsAi {
    return gameMode == GameMode.humanVsAi;
  }

  bool get isLlmDifficultyTest {
    return gameMode == GameMode.llmDifficultyTest;
  }

  bool get usesAi {
    return gameMode.requiresAiDifficulty;
  }

  int get aiTeamId {
    if (!isHumanVsAi) {
      throw StateError(
        'AI team is only available for Human versus AI matches.',
      );
    }

    return humanTeamId == 0 ? 1 : 0;
  }

  String get title {
    switch (gameMode) {
      case GameMode.localMultiplayer:
        return '${gameMode.displayName} - $playerCount Players';

      case GameMode.humanVsAi:
        return '${gameMode.displayName} - ${aiDifficulty!.displayName}';

      case GameMode.llmDifficultyTest:
        return 'LLM vs ${aiDifficulty!.displayName}';
    }
  }

  void validate() {
    if (playerCount < minimumPlayerCount ||
        playerCount > maximumPlayerCount) {
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        'Player count must be between '
            '$minimumPlayerCount and $maximumPlayerCount.',
      );
    }

    switch (gameMode) {
      case GameMode.localMultiplayer:
        if (aiDifficulty != null) {
          throw ArgumentError(
            'Local multiplayer must not have an AI difficulty.',
          );
        }

        if (experimentGameCount != 0) {
          throw ArgumentError(
            'Local multiplayer must not have experiment games.',
          );
        }

        break;

      case GameMode.humanVsAi:
        if (playerCount != 2) {
          throw ArgumentError(
            'Human versus AI must use exactly two players.',
          );
        }

        if (aiDifficulty == null) {
          throw ArgumentError(
            'Human versus AI requires an AI difficulty.',
          );
        }

        if (humanTeamId != 0 && humanTeamId != 1) {
          throw ArgumentError.value(
            humanTeamId,
            'humanTeamId',
            'Human team ID must be 0 or 1.',
          );
        }

        if (experimentGameCount != 0) {
          throw ArgumentError(
            'Human versus AI must not have experiment games.',
          );
        }

        break;

      case GameMode.llmDifficultyTest:
        if (playerCount != 2) {
          throw ArgumentError(
            'LLM difficulty tests must use exactly two players.',
          );
        }

        if (aiDifficulty == null) {
          throw ArgumentError(
            'LLM difficulty tests require an AI difficulty.',
          );
        }

        if (experimentGameCount < minimumExperimentGames ||
            experimentGameCount > maximumExperimentGames) {
          throw ArgumentError.value(
            experimentGameCount,
            'experimentGameCount',
            'Experiment game count must be between '
                '$minimumExperimentGames and '
                '$maximumExperimentGames.',
          );
        }

        break;
    }
  }

  MatchConfiguration copyWith({
    AiDifficulty? aiDifficulty,
    int? humanTeamId,
    int? experimentGameCount,
    bool? showExperimentGames,
  }) {
    final updated = MatchConfiguration._(
      gameMode: gameMode,
      playerCount: playerCount,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      humanTeamId: humanTeamId ?? this.humanTeamId,
      experimentGameCount:
          experimentGameCount ?? this.experimentGameCount,
      showExperimentGames:
          showExperimentGames ?? this.showExperimentGames,
    );

    updated.validate();

    return updated;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MatchConfiguration &&
            other.gameMode == gameMode &&
            other.playerCount == playerCount &&
            other.aiDifficulty == aiDifficulty &&
            other.humanTeamId == humanTeamId &&
            other.experimentGameCount == experimentGameCount &&
            other.showExperimentGames == showExperimentGames;
  }

  @override
  int get hashCode {
    return Object.hash(
      gameMode,
      playerCount,
      aiDifficulty,
      humanTeamId,
      experimentGameCount,
      showExperimentGames,
    );
  }

  @override
  String toString() {
    return 'MatchConfiguration('
        'gameMode: $gameMode, '
        'playerCount: $playerCount, '
        'aiDifficulty: $aiDifficulty, '
        'humanTeamId: $humanTeamId, '
        'experimentGameCount: $experimentGameCount, '
        'showExperimentGames: $showExperimentGames'
        ')';
  }
}