import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/game_move.dart';
import 'package:homework1game/ai/greedy_medium_strategy.dart';
import 'package:homework1game/game/board.dart';

void main() {
  group('GreedyMediumStrategy identity', () {
    test(
      'reports the correct name and difficulty',
      () {
        final strategy =
            GreedyMediumStrategy();

        expect(
          strategy.name,
          'Greedy',
        );

        expect(
          strategy.difficulty,
          'Medium',
        );

        expect(
          strategy.toString(),
          'Greedy (Medium)',
        );
      },
    );
  });

  group('GreedyMediumStrategy move selection', () {
    test(
      'returns the only legal move',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(1),
        );

        final onlyMove = GameMove.normal(
          movingPieceId: 0,
          moveValue: 2,
          destinationProgress: 4,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            onlyMove,
          ],
        );

        expect(
          selectedMove,
          onlyMove,
        );
      },
    );

    test(
      'prefers finishing a piece',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(2),
        );

        final regularMove =
            GameMove.normal(
          movingPieceId: 0,
          moveValue: 3,
          destinationProgress: 20,
        );

        final finishingMove =
            GameMove.normal(
          movingPieceId: 1,
          moveValue: 2,
          destinationProgress:
              Board.finishProgress,
        );

        final captureMove =
            GameMove.specialCapture(
          movingPieceId: 2,
          targetPieceId: 10,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            regularMove,
            finishingMove,
            captureMove,
          ],
        );

        expect(
          selectedMove,
          finishingMove,
        );
      },
    );

    test(
      'prefers a special capture over a regular move',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(3),
        );

        final regularMove =
            GameMove.normal(
          movingPieceId: 0,
          moveValue: 5,
          destinationProgress: 28,
        );

        final captureMove =
            GameMove.specialCapture(
          movingPieceId: 1,
          targetPieceId: 20,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            regularMove,
            captureMove,
          ],
        );

        expect(
          selectedMove,
          captureMove,
        );
      },
    );

    test(
      'chooses the normal move with the highest destination progress',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(4),
        );

        final moveToFive =
            GameMove.normal(
          movingPieceId: 0,
          moveValue: 3,
          destinationProgress: 5,
        );

        final moveToTwelve =
            GameMove.normal(
          movingPieceId: 1,
          moveValue: 3,
          destinationProgress: 12,
        );

        final moveToEight =
            GameMove.normal(
          movingPieceId: 2,
          moveValue: 3,
          destinationProgress: 8,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            moveToFive,
            moveToTwelve,
            moveToEight,
          ],
        );

        expect(
          selectedMove,
          moveToTwelve,
        );
      },
    );

    test(
      'always returns one of the supplied legal moves',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(5),
        );

        final legalMoves = <GameMove>[
          GameMove.normal(
            movingPieceId: 0,
            moveValue: 2,
            destinationProgress: 4,
          ),
          GameMove.normal(
            movingPieceId: 1,
            moveValue: 2,
            destinationProgress: 7,
          ),
          GameMove.specialCapture(
            movingPieceId: 2,
            targetPieceId: 10,
          ),
        ];

        for (
          var attempt = 0;
          attempt < 50;
          attempt++
        ) {
          final selectedMove =
              strategy.chooseValidatedMove(
            legalMoves: legalMoves,
          );

          expect(
            legalMoves,
            contains(selectedMove),
          );
        }
      },
    );

    test(
      'does not change the supplied legal move list',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(6),
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
        ];

        final originalMoves =
            List<GameMove>.from(
          legalMoves,
        );

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
      'can choose between equally valued moves',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(42),
        );

        final firstMove =
            GameMove.normal(
          movingPieceId: 0,
          moveValue: 2,
          destinationProgress: 6,
        );

        final secondMove =
            GameMove.normal(
          movingPieceId: 1,
          moveValue: 2,
          destinationProgress: 6,
        );

        final legalMoves = <GameMove>[
          firstMove,
          secondMove,
        ];

        final selectedMoves = <GameMove>{};

        for (
          var attempt = 0;
          attempt < 100;
          attempt++
        ) {
          selectedMoves.add(
            strategy.chooseValidatedMove(
              legalMoves: legalMoves,
            ),
          );
        }

        expect(
          selectedMoves,
          contains(firstMove),
        );

        expect(
          selectedMoves,
          contains(secondMove),
        );
      },
    );
  });

  group('GreedyMediumStrategy error handling', () {
    test(
      'chooseMove rejects an empty move list',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(7),
        );

        expect(
          () => strategy.chooseMove(
            legalMoves:
                const <GameMove>[],
          ),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );

    test(
      'chooseValidatedMove rejects an empty move list',
      () {
        final strategy =
            GreedyMediumStrategy(
          random: Random(8),
        );

        expect(
          () =>
              strategy.chooseValidatedMove(
            legalMoves:
                const <GameMove>[],
          ),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );
  });
}