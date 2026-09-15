enum GameMode {
  localMultiplayer,
  humanVsAi,
  llmDifficultyTest,
}

extension GameModeDisplay on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.localMultiplayer:
        return 'Play In Person';

      case GameMode.humanVsAi:
        return 'Play Against AI';

      case GameMode.llmDifficultyTest:
        return 'Test AI Difficulty';
    }
  }

  String get description {
    switch (this) {
      case GameMode.localMultiplayer:
        return 'Two to four people play together on the same device.';

      case GameMode.humanVsAi:
        return 'A person plays against a selected AI difficulty.';

      case GameMode.llmDifficultyTest:
        return 'An LLM opponent plays against a selected AI difficulty.';
    }
  }

  bool get requiresAiDifficulty {
    return this == GameMode.humanVsAi ||
        this == GameMode.llmDifficultyTest;
  }

  bool get isPlayableByHuman {
    return this == GameMode.localMultiplayer ||
        this == GameMode.humanVsAi;
  }

  bool get isExperiment {
    return this == GameMode.llmDifficultyTest;
  }
}