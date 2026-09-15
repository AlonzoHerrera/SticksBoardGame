import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_game_snapshot.dart';
import 'package:homework1game/ai/game_move.dart';
import 'package:homework1game/ai/game_move_adapter.dart';
import 'package:homework1game/ai/heuristic_hard_strategy.dart';
import 'package:homework1game/game/board.dart';
import 'package:homework1game/game/game.dart';

void main() {
  group('HeuristicHardStrategy identity', () {
    test(
      'reports the correct name and difficulty',
      () {
        final strategy =
            HeuristicHardStrategy();

        expect(
          strategy.name,
          'Heuristic',
        );

        expect(
          strategy.difficulty,
          'Hard',
        );

        expect(
          strategy.toString(),
          'Heuristic (Hard)',
        );
      },
    );
  });

  group('HeuristicHardStrategy validation', () {
    test(
      'requires a snapshot before choosing',
      () {
        final strategy =
            HeuristicHardStrategy(
          random: Random(1),
        );

        final move =
            GameMove.normal(
          movingPieceId: 0,
          moveValue: 2,
          destinationProgress: 4,
        );

        expect(
          () => strategy.chooseMove(
            legalMoves: <GameMove>[
              move,
            ],
          ),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );

    test(
      'rejects an empty legal move list',
      () {
        final game =
            Game(playerCount: 2);

        final strategy =
            HeuristicHardStrategy(
          random: Random(2),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
          ),
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
  });

  group('HeuristicHardStrategy decisions', () {
    test(
      'prefers finishing a piece',
      () {
        final game =
            Game(playerCount: 2);

        const adapter =
            GameMoveAdapter();

        final firstPiece =
            game.players[0].pieces[0];

        final secondPiece =
            game.players[0].pieces[1];

        firstPiece.moveToProgress(20);
        secondPiece.moveToProgress(12);

        final strategy =
            HeuristicHardStrategy(
          random: Random(3),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
            adapter: adapter,
          ),
        );

        final regularMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            secondPiece,
          ),
          moveValue: 4,
          destinationProgress: 16,
        );

        final finishingMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            firstPiece,
          ),
          moveValue: 4,
          destinationProgress:
              Board.finishProgress,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            regularMove,
            finishingMove,
          ],
        );

        expect(
          selectedMove,
          finishingMove,
        );
      },
    );

    test(
      'prefers a normal capture over a regular move',
      () {
        final game =
            Game(playerCount: 2);

        const adapter =
            GameMoveAdapter();

        final movingPiece =
            game.players[0].pieces[0];

        final otherTeamPiece =
            game.players[0].pieces[1];

        final opponentPiece =
            game.players[1].pieces[0];

        movingPiece.moveToProgress(4);
        otherTeamPiece.moveToProgress(5);
        opponentPiece.moveToProgress(8);

        final strategy =
            HeuristicHardStrategy(
          random: Random(4),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
            adapter: adapter,
          ),
        );

        final captureMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            movingPiece,
          ),
          moveValue: 4,
          destinationProgress: 8,
        );

        final regularMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            otherTeamPiece,
          ),
          moveValue: 5,
          destinationProgress: 10,
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
      'prefers creating a teammate stack over a plain move',
      () {
        final game =
            Game(playerCount: 2);

        const adapter =
            GameMoveAdapter();

        final movingPiece =
            game.players[0].pieces[0];

        final plainPiece =
            game.players[0].pieces[1];

        final teammate =
            game.players[0].pieces[2];

        movingPiece.moveToProgress(4);
        plainPiece.moveToProgress(5);
        teammate.moveToProgress(8);

        final strategy =
            HeuristicHardStrategy(
          random: Random(5),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
            adapter: adapter,
          ),
        );

        final stackingMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            movingPiece,
          ),
          moveValue: 4,
          destinationProgress: 8,
        );

        final plainMove =
            GameMove.normal(
          movingPieceId:
              adapter.pieceKey(
            plainPiece,
          ),
          moveValue: 5,
          destinationProgress: 10,
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            plainMove,
            stackingMove,
          ],
        );

        expect(
          selectedMove,
          stackingMove,
        );
      },
    );

    test(
      'prefers capturing a farther opponent with the X stick',
      () {
        final game =
            Game(playerCount: 2);

        const adapter =
            GameMoveAdapter();

        final movingPiece =
            game.players[0].pieces[0];

        final firstOpponent =
            game.players[1].pieces[0];

        final secondOpponent =
            game.players[1].pieces[1];

        firstOpponent.moveToProgress(5);
        secondOpponent.moveToProgress(18);

        final strategy =
            HeuristicHardStrategy(
          random: Random(6),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
            adapter: adapter,
          ),
        );

        final captureFirst =
            GameMove.specialCapture(
          movingPieceId:
              adapter.pieceKey(
            movingPiece,
          ),
          targetPieceId:
              adapter.pieceKey(
            firstOpponent,
          ),
        );

        final captureSecond =
            GameMove.specialCapture(
          movingPieceId:
              adapter.pieceKey(
            movingPiece,
          ),
          targetPieceId:
              adapter.pieceKey(
            secondOpponent,
          ),
        );

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: <GameMove>[
            captureFirst,
            captureSecond,
          ],
        );

        expect(
          selectedMove,
          captureSecond,
        );
      },
    );

    test(
      'always returns a supplied legal move',
      () {
        final game =
            Game(playerCount: 2);

        const adapter =
            GameMoveAdapter();

        final strategy =
            HeuristicHardStrategy(
          random: Random(7),
        );

        strategy.updateSnapshot(
          AiGameSnapshot.fromGame(
            game,
            adapter: adapter,
          ),
        );

        final legalMoves =
            game.players[0].pieces
                .map(
                  (piece) =>
                      GameMove.normal(
                    movingPieceId:
                        adapter.pieceKey(
                      piece,
                    ),
                    moveValue: 2,
                    destinationProgress:
                        1,
                  ),
                )
                .toList();

        final selectedMove =
            strategy.chooseValidatedMove(
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