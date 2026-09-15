enum AiDifficulty {
  randomEasy,
  greedyMedium,
  heuristicHard,
}

extension AiDifficultyDisplay on AiDifficulty {
  String get displayName {
    switch (this) {
      case AiDifficulty.randomEasy:
        return 'Random Easy';

      case AiDifficulty.greedyMedium:
        return 'Greedy Medium';

      case AiDifficulty.heuristicHard:
        return 'Heuristic Hard';
    }
  }

  String get shortName {
    switch (this) {
      case AiDifficulty.randomEasy:
        return 'Easy';

      case AiDifficulty.greedyMedium:
        return 'Medium';

      case AiDifficulty.heuristicHard:
        return 'Hard';
    }
  }

  String get strategyName {
    switch (this) {
      case AiDifficulty.randomEasy:
        return 'Random';

      case AiDifficulty.greedyMedium:
        return 'Greedy';

      case AiDifficulty.heuristicHard:
        return 'Heuristic';
    }
  }

  String get description {
    switch (this) {
      case AiDifficulty.randomEasy:
        return 'Selects one legal move at random.';

      case AiDifficulty.greedyMedium:
        return 'Prefers immediate progress, captures, and finishing moves.';

      case AiDifficulty.heuristicHard:
        return 'Evaluates captures, stacking, finishing, and team progress.';
    }
  }
}
