import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/game_move.dart';
import 'package:homework1game/ai/game_move_adapter.dart';
import 'package:homework1game/ai/random_easy_strategy.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_rule_exception.dart';
import 'package:homework1game/game/game_state.dart';

void main() {
  group('GameMoveAdapter normal moves', () {
    test(
      'returns no moves while the game is waiting for a throw',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        expect(
          game.state,
          GameState.waitingForThrow,
        );

        expect(
          adapter.legalMoves(game),
          isEmpty,
        );
      },
    );

    test(
      'creates legal GameMove objects after a normal throw',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final moves = adapter.legalMoves(game);

        expect(
          game.state,
          GameState.waitingForMove,
        );

        expect(
          moves,
          isNotEmpty,
        );

        expect(
          moves.every(
            (move) => move.isNormal,
          ),
          isTrue,
        );

        expect(
          moves.every(
            (move) => move.moveValue == 2,
          ),
          isTrue,
        );

        expect(
          moves.every(
            (move) =>
                move.destinationProgress == 1,
          ),
          isTrue,
        );
      },
    );

    test(
      'creates one move for every legal piece and destination',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final moves = adapter.legalMoves(game);

        expect(
          moves.length,
          game.currentPlayer!.pieces.length,
        );

        final movingPieceKeys = moves
            .map(
              (move) => move.movingPieceId,
            )
            .toSet();

        expect(
          movingPieceKeys.length,
          game.currentPlayer!.pieces.length,
        );
      },
    );

    test(
      'applies a legal normal move through the game engine',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final legalMoves = adapter.legalMoves(game);
        final selectedMove = legalMoves.first;

        final movingPiece = adapter.pieceForKey(
          game,
          selectedMove.movingPieceId,
        );

        expect(
          movingPiece.isInactive,
          isTrue,
        );

        adapter.applyMove(
          game,
          selectedMove,
        );

        expect(
          movingPiece.progress,
          selectedMove.destinationProgress,
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );

        expect(
          game.currentPlayer?.name,
          'Player 2',
        );
      },
    );

    test(
      'rejects a normal move that is not currently legal',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final illegalMove = GameMove.normal(
          movingPieceId: 9999,
          moveValue: 2,
          destinationProgress: 10,
        );

        expect(
          () => adapter.applyMove(
            game,
            illegalMove,
          ),
          throwsA(
            isA<GameRuleException>(),
          ),
        );
      },
    );
  });

  group('GameMoveAdapter X-stick moves', () {
    test(
      'creates special moves for opposing pieces on the board',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        final opponentPiece =
            game.players[1].pieces[0];

        opponentPiece.moveToProgress(4);

        game.throwSpecificSticks(
          <bool>[
            true,
            false,
            false,
            false,
          ],
        );

        final moves = adapter.legalMoves(game);

        expect(
          game.state,
          GameState.waitingForSpecialMove,
        );

        expect(
          moves,
          isNotEmpty,
        );

        expect(
          moves.every(
            (move) => move.isSpecialCapture,
          ),
          isTrue,
        );

        expect(
          moves.every(
            (move) =>
                move.targetPieceId ==
                adapter.pieceKey(opponentPiece),
          ),
          isTrue,
        );
      },
    );

    test(
      'applies a legal X-stick capture',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        final opponentPiece =
            game.players[1].pieces[0];

        opponentPiece.moveToProgress(4);

        game.throwSpecificSticks(
          <bool>[
            true,
            false,
            false,
            false,
          ],
        );

        final selectedMove =
            adapter.legalMoves(game).first;

        final movingPiece = adapter.pieceForKey(
          game,
          selectedMove.movingPieceId,
        );

        adapter.applyMove(
          game,
          selectedMove,
        );

        expect(
          opponentPiece.isInactive,
          isTrue,
        );

        expect(
          movingPiece.progress,
          4,
        );

        expect(
          game.currentPlayer?.name,
          'Player 1',
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );
  });

  group('Random Easy game integration', () {
    test(
      'Random Easy selects and applies a real legal game move',
      () {
        final game = Game(playerCount: 2);
        const adapter = GameMoveAdapter();

        final strategy = RandomEasyStrategy(
          random: Random(10),
        );

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final legalMoves = adapter.legalMoves(game);

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: legalMoves,
        );

        expect(
          legalMoves,
          contains(selectedMove),
        );

        final selectedPiece =
            adapter.pieceForKey(
          game,
          selectedMove.movingPieceId,
        );

        adapter.applyMove(
          game,
          selectedMove,
        );

        expect(
          selectedPiece.progress,
          selectedMove.destinationProgress,
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );
  });
}