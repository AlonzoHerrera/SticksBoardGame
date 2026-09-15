import 'dart:math';

import '../models/ai_difficulty.dart';
import 'ai_strategy.dart';
import 'greedy_medium_strategy.dart';
import 'heuristic_hard_strategy.dart';
import 'random_easy_strategy.dart';

class AiStrategyFactory {
  const AiStrategyFactory();

  AiStrategy create({
    required AiDifficulty difficulty,
    Random? random,
  }) {
    switch (difficulty) {
      case AiDifficulty.randomEasy:
        return RandomEasyStrategy(
          random: random,
        );

      case AiDifficulty.greedyMedium:
        return GreedyMediumStrategy(
          random: random,
        );

      case AiDifficulty.heuristicHard:
        return HeuristicHardStrategy(
          random: random,
        );
    }
  }

  List<AiStrategy> createAll({
    Random? random,
  }) {
    return List<AiStrategy>.unmodifiable(
      AiDifficulty.values.map(
        (difficulty) => create(
          difficulty: difficulty,
          random: random,
        ),
      ),
    );
  }

  bool matchesDifficulty({
    required AiStrategy strategy,
    required AiDifficulty difficulty,
  }) {
    switch (difficulty) {
      case AiDifficulty.randomEasy:
        return strategy is RandomEasyStrategy;

      case AiDifficulty.greedyMedium:
        return strategy is GreedyMediumStrategy;

      case AiDifficulty.heuristicHard:
        return strategy is HeuristicHardStrategy;
    }
  }
}
