import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/models/ai_difficulty.dart';
import 'package:homework1game/models/game_mode.dart';
import 'package:homework1game/models/match_configuration.dart';

void main() {
  group('GameMode display values', () {
    test(
      'provides the correct menu names',
      () {
        expect(
          GameMode.localMultiplayer.displayName,
          'Play In Person',
        );

        expect(
          GameMode.humanVsAi.displayName,
          'Play Against AI',
        );

        expect(
          GameMode.llmDifficultyTest.displayName,
          'Test AI Difficulty',
        );
      },
    );

    test(
      'identifies modes that require an AI difficulty',
      () {
        expect(
          GameMode.localMultiplayer.requiresAiDifficulty,
          isFalse,
        );

        expect(
          GameMode.humanVsAi.requiresAiDifficulty,
          isTrue,
        );

        expect(
          GameMode.llmDifficultyTest.requiresAiDifficulty,
          isTrue,
        );
      },
    );

    test(
      'identifies the experiment mode',
      () {
        expect(
          GameMode.localMultiplayer.isExperiment,
          isFalse,
        );

        expect(
          GameMode.humanVsAi.isExperiment,
          isFalse,
        );

        expect(
          GameMode.llmDifficultyTest.isExperiment,
          isTrue,
        );
      },
    );
  });

  group('AiDifficulty display values', () {
    test(
      'provides the correct difficulty names',
      () {
        expect(
          AiDifficulty.randomEasy.displayName,
          'Random Easy',
        );

        expect(
          AiDifficulty.greedyMedium.displayName,
          'Greedy Medium',
        );

        expect(
          AiDifficulty.heuristicHard.displayName,
          'Heuristic Hard',
        );
      },
    );

    test(
      'matches the implemented strategy names',
      () {
        expect(
          AiDifficulty.randomEasy.strategyName,
          'Random',
        );

        expect(
          AiDifficulty.greedyMedium.strategyName,
          'Greedy',
        );

        expect(
          AiDifficulty.heuristicHard.strategyName,
          'Heuristic',
        );
      },
    );
  });

  group('Local multiplayer configuration', () {
    test(
      'creates a valid two-player match',
      () {
        final configuration =
            MatchConfiguration.localMultiplayer(
          playerCount: 2,
        );

        expect(
          configuration.gameMode,
          GameMode.localMultiplayer,
        );

        expect(
          configuration.playerCount,
          2,
        );

        expect(
          configuration.aiDifficulty,
          isNull,
        );

        expect(
          configuration.usesAi,
          isFalse,
        );

        expect(
          configuration.title,
          'Play In Person - 2 Players',
        );
      },
    );

    test(
      'supports two, three, and four players',
      () {
        for (final playerCount in <int>[2, 3, 4]) {
          final configuration =
              MatchConfiguration.localMultiplayer(
            playerCount: playerCount,
          );

          expect(
            configuration.playerCount,
            playerCount,
          );
        }
      },
    );

    test(
      'rejects fewer than two players',
      () {
        expect(
          () => MatchConfiguration.localMultiplayer(
            playerCount: 1,
          ),
          throwsA(
            isA<ArgumentError>(),
          ),
        );
      },
    );

    test(
      'rejects more than four players',
      () {
        expect(
          () => MatchConfiguration.localMultiplayer(
            playerCount: 5,
          ),
          throwsA(
            isA<ArgumentError>(),
          ),
        );
      },
    );
  });

  group('Human versus AI configuration', () {
    test(
      'creates a Random Easy match',
      () {
        final configuration =
            MatchConfiguration.humanVsAi(
          aiDifficulty: AiDifficulty.randomEasy,
        );

        expect(
          configuration.gameMode,
          GameMode.humanVsAi,
        );

        expect(
          configuration.playerCount,
          2,
        );

        expect(
          configuration.aiDifficulty,
          AiDifficulty.randomEasy,
        );

        expect(
          configuration.humanTeamId,
          0,
        );

        expect(
          configuration.aiTeamId,
          1,
        );

        expect(
          configuration.usesAi,
          isTrue,
        );
      },
    );

    test(
      'allows the human to select Team 2',
      () {
        final configuration =
            MatchConfiguration.humanVsAi(
          aiDifficulty:
              AiDifficulty.heuristicHard,
          humanTeamId: 1,
        );

        expect(
          configuration.humanTeamId,
          1,
        );

        expect(
          configuration.aiTeamId,
          0,
        );
      },
    );

    test(
      'rejects an invalid human team',
      () {
        expect(
          () => MatchConfiguration.humanVsAi(
            aiDifficulty:
                AiDifficulty.greedyMedium,
            humanTeamId: 2,
          ),
          throwsA(
            isA<ArgumentError>(),
          ),
        );
      },
    );

    test(
      'creates the correct title',
      () {
        final configuration =
            MatchConfiguration.humanVsAi(
          aiDifficulty:
              AiDifficulty.greedyMedium,
        );

        expect(
          configuration.title,
          'Play Against AI - Greedy Medium',
        );
      },
    );
  });

  group('LLM difficulty test configuration', () {
    test(
      'creates a valid experiment',
      () {
        final configuration =
            MatchConfiguration.llmDifficultyTest(
          aiDifficulty:
              AiDifficulty.heuristicHard,
          experimentGameCount: 100,
        );

        expect(
          configuration.gameMode,
          GameMode.llmDifficultyTest,
        );

        expect(
          configuration.aiDifficulty,
          AiDifficulty.heuristicHard,
        );

        expect(
          configuration.experimentGameCount,
          100,
        );

        expect(
          configuration.showExperimentGames,
          isFalse,
        );

        expect(
          configuration.isLlmDifficultyTest,
          isTrue,
        );

        expect(
          configuration.title,
          'LLM vs Heuristic Hard',
        );
      },
    );

    test(
      'supports showing experiment games',
      () {
        final configuration =
            MatchConfiguration.llmDifficultyTest(
          aiDifficulty:
              AiDifficulty.randomEasy,
          experimentGameCount: 10,
          showExperimentGames: true,
        );

        expect(
          configuration.showExperimentGames,
          isTrue,
        );
      },
    );

    test(
      'rejects zero experiment games',
      () {
        expect(
          () =>
              MatchConfiguration.llmDifficultyTest(
            aiDifficulty:
                AiDifficulty.randomEasy,
            experimentGameCount: 0,
          ),
          throwsA(
            isA<ArgumentError>(),
          ),
        );
      },
    );

    test(
      'rejects more than the maximum experiment games',
      () {
        expect(
          () =>
              MatchConfiguration.llmDifficultyTest(
            aiDifficulty:
                AiDifficulty.greedyMedium,
            experimentGameCount: 10001,
          ),
          throwsA(
            isA<ArgumentError>(),
          ),
        );
      },
    );
  });

  group('MatchConfiguration copyWith', () {
    test(
      'updates a Human versus AI difficulty',
      () {
        final original =
            MatchConfiguration.humanVsAi(
          aiDifficulty:
              AiDifficulty.randomEasy,
        );

        final updated = original.copyWith(
          aiDifficulty:
              AiDifficulty.heuristicHard,
        );

        expect(
          updated.aiDifficulty,
          AiDifficulty.heuristicHard,
        );

        expect(
          updated.gameMode,
          original.gameMode,
        );

        expect(
          updated.playerCount,
          original.playerCount,
        );
      },
    );

    test(
      'updates the experiment game count',
      () {
        final original =
            MatchConfiguration.llmDifficultyTest(
          aiDifficulty:
              AiDifficulty.greedyMedium,
          experimentGameCount: 50,
        );

        final updated = original.copyWith(
          experimentGameCount: 200,
          showExperimentGames: true,
        );

        expect(
          updated.experimentGameCount,
          200,
        );

        expect(
          updated.showExperimentGames,
          isTrue,
        );
      },
    );
  });

  group('MatchConfiguration equality', () {
    test(
      'equal configurations have equal values',
      () {
        final first =
            MatchConfiguration.humanVsAi(
          aiDifficulty:
              AiDifficulty.randomEasy,
          humanTeamId: 0,
        );

        final second =
            MatchConfiguration.humanVsAi(
          aiDifficulty:
              AiDifficulty.randomEasy,
          humanTeamId: 0,
        );

        expect(
          first,
          second,
        );

        expect(
          first.hashCode,
          second.hashCode,
        );
      },
    );
  });
}