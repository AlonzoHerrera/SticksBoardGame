import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_strategy_factory.dart';
import 'package:homework1game/ai/greedy_medium_strategy.dart';
import 'package:homework1game/ai/heuristic_hard_strategy.dart';
import 'package:homework1game/ai/random_easy_strategy.dart';
import 'package:homework1game/models/ai_difficulty.dart';

void main() {
  group('AiStrategyFactory creation', () {
    test(
      'creates Random Easy strategy',
      () {
        const factory =
            AiStrategyFactory();

        final strategy = factory.create(
          difficulty:
              AiDifficulty.randomEasy,
          random: Random(1),
        );

        expect(
          strategy,
          isA<RandomEasyStrategy>(),
        );

        expect(
          strategy.name,
          'Random',
        );

        expect(
          strategy.difficulty,
          'Easy',
        );
      },
    );

    test(
      'creates Greedy Medium strategy',
      () {
        const factory =
            AiStrategyFactory();

        final strategy = factory.create(
          difficulty:
              AiDifficulty.greedyMedium,
          random: Random(2),
        );

        expect(
          strategy,
          isA<GreedyMediumStrategy>(),
        );

        expect(
          strategy.name,
          'Greedy',
        );

        expect(
          strategy.difficulty,
          'Medium',
        );
      },
    );

    test(
      'creates Heuristic Hard strategy',
      () {
        const factory =
            AiStrategyFactory();

        final strategy = factory.create(
          difficulty:
              AiDifficulty.heuristicHard,
          random: Random(3),
        );

        expect(
          strategy,
          isA<HeuristicHardStrategy>(),
        );

        expect(
          strategy.name,
          'Heuristic',
        );

        expect(
          strategy.difficulty,
          'Hard',
        );
      },
    );
  });

  group('AiStrategyFactory createAll', () {
    test(
      'creates all three strategies',
      () {
        const factory =
            AiStrategyFactory();

        final strategies =
            factory.createAll(
          random: Random(4),
        );

        expect(
          strategies.length,
          3,
        );

        expect(
          strategies[0],
          isA<RandomEasyStrategy>(),
        );

        expect(
          strategies[1],
          isA<GreedyMediumStrategy>(),
        );

        expect(
          strategies[2],
          isA<HeuristicHardStrategy>(),
        );
      },
    );

    test(
      'returns an unmodifiable list',
      () {
        const factory =
            AiStrategyFactory();

        final strategies =
            factory.createAll(
          random: Random(5),
        );

        expect(
          () => strategies.add(
            RandomEasyStrategy(),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });

  group('AiStrategyFactory matching', () {
    test(
      'matches Random Easy correctly',
      () {
        const factory =
            AiStrategyFactory();

        final strategy =
            RandomEasyStrategy();

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.randomEasy,
          ),
          isTrue,
        );

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.greedyMedium,
          ),
          isFalse,
        );
      },
    );

    test(
      'matches Greedy Medium correctly',
      () {
        const factory =
            AiStrategyFactory();

        final strategy =
            GreedyMediumStrategy();

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.greedyMedium,
          ),
          isTrue,
        );

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.heuristicHard,
          ),
          isFalse,
        );
      },
    );

    test(
      'matches Heuristic Hard correctly',
      () {
        const factory =
            AiStrategyFactory();

        final strategy =
            HeuristicHardStrategy();

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.heuristicHard,
          ),
          isTrue,
        );

        expect(
          factory.matchesDifficulty(
            strategy: strategy,
            difficulty:
                AiDifficulty.randomEasy,
          ),
          isFalse,
        );
      },
    );
  });

  group('AiDifficulty and strategy consistency', () {
    test(
      'all difficulty values create matching strategies',
      () {
        const factory =
            AiStrategyFactory();

        for (final difficulty
            in AiDifficulty.values) {
          final strategy =
              factory.create(
            difficulty: difficulty,
            random: Random(6),
          );

          expect(
            factory.matchesDifficulty(
              strategy: strategy,
              difficulty: difficulty,
            ),
            isTrue,
          );

          expect(
            strategy.name,
            difficulty.strategyName,
          );

          expect(
            strategy.difficulty,
            difficulty.shortName,
          );
        }
      },
    );
  });
}
