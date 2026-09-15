import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/game_move.dart';
import 'package:homework1game/ai/random_easy_strategy.dart';

void main() {
  group('RandomEasyStrategy identity', () {
    test(
      'reports the correct strategy name and difficulty',
      () {
        final strategy = RandomEasyStrategy();

        expect(strategy.name, 'Random');
        expect(strategy.difficulty, 'Easy');
        expect(strategy.toString(), 'Random (Easy)');
      },
    );
  });

  group('RandomEasyStrategy legal move selection', () {
    test(
      'returns the only available legal move',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(1),
        );

        final onlyMove = GameMove.normal(
          movingPieceId: 0,
          moveValue: 3,
          destinationProgress: 5,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            onlyMove,
          ],
        );

        expect(selectedMove, onlyMove);
      },
    );

    test(
      'always returns one of the supplied legal moves',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(7),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 2,
            destinationProgress: 1,
          ),
          GameMove.normal(
            movingPieceId: 1,
            moveValue: 2,
            destinationProgress: 4,
          ),
          GameMove.normal(
            movingPieceId: 2,
            moveValue: 2,
            destinationProgress: 7,
          ),
        ];

        for (var attempt = 0; attempt < 100; attempt++) {
          final selectedMove =
              strategy.chooseValidatedMove(
            legalMoves: legalMoves,
          );

          expect(
            legalMoves,
            contains(selectedMove),
            reason:
                'Random Easy must only return a supplied legal move.',
          );
        }
      },
    );

    test(
      'works with normal and X-stick special moves',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(12),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 4,
            destinationProgress: 6,
          ),
          GameMove.specialCapture(
            movingPieceId: 1,
            targetPieceId: 4,
          ),
        ];

        for (var attempt = 0; attempt < 50; attempt++) {
          final selectedMove =
              strategy.chooseValidatedMove(
            legalMoves: legalMoves,
          );

          expect(
            legalMoves,
            contains(selectedMove),
          );

          expect(
            selectedMove.isNormal ||
                selectedMove.isSpecialCapture,
            isTrue,
          );
        }
      },
    );

    test(
      'does not add, remove, or reorder legal moves',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(20),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 1,
            destinationProgress: 0,
          ),
          GameMove.normal(
            movingPieceId: 1,
            moveValue: 1,
            destinationProgress: 0,
          ),
          GameMove.specialCapture(
            movingPieceId: 2,
            targetPieceId: 5,
          ),
        ];

        final originalMoves =
            List<GameMove>.from(legalMoves);

        strategy.chooseValidatedMove(
          legalMoves: legalMoves,
        );

        expect(
          legalMoves,
          orderedEquals(originalMoves),
        );
      },
    );

    test(
      'can select different moves over repeated attempts',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(42),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 2,
            destinationProgress: 3,
          ),
          GameMove.normal(
            movingPieceId: 1,
            moveValue: 2,
            destinationProgress: 4,
          ),
          GameMove.normal(
            movingPieceId: 2,
            moveValue: 2,
            destinationProgress: 5,
          ),
        ];

        final selectedMoves = <GameMove>{};

        for (var attempt = 0; attempt < 100; attempt++) {
          selectedMoves.add(
            strategy.chooseValidatedMove(
              legalMoves: legalMoves,
            ),
          );
        }

        expect(
          selectedMoves.length,
          greaterThan(1),
          reason:
              'Repeated random selections should not always return the same move.',
        );
      },
    );
  });

  group('RandomEasyStrategy error handling', () {
    test(
      'chooseMove rejects an empty legal move list',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(1),
        );

        expect(
          () => strategy.chooseMove(
            legalMoves: const <GameMove>[],
          ),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );

    test(
      'chooseValidatedMove rejects an empty legal move list',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(1),
        );

        expect(
          () => strategy.chooseValidatedMove(
            legalMoves: const <GameMove>[],
          ),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );

    test(
      'chooseRandomMove returns a validated legal move',
      () {
        final strategy = RandomEasyStrategy(
          random: Random(3),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 5,
            destinationProgress: 9,
          ),
          GameMove.normal(
            movingPieceId: 1,
            moveValue: 5,
            destinationProgress: 12,
          ),
        ];

        final selectedMove =
            strategy.chooseRandomMove(
          legalMoves: legalMoves,
        );

        expect(
          legalMoves,
          contains(selectedMove),
        );
      },
    );
  });
}