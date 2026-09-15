import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_game_snapshot.dart';
import 'package:homework1game/ai/game_move_adapter.dart';
import 'package:homework1game/game/board.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_state.dart';

void main() {
  group('AiGameSnapshot creation', () {
    test(
      'copies the current game information',
      () {
        final game = Game(
          playerCount: 4,
        );

        final snapshot =
            AiGameSnapshot.fromGame(game);

        expect(
          snapshot.gameState,
          GameState.waitingForThrow,
        );

        expect(
          snapshot.currentPlayerId,
          game.currentPlayer?.id,
        );

        expect(
          snapshot.currentTeamId,
          game.currentTeam?.id,
        );

        expect(
          snapshot.pendingMoveValue,
          isNull,
        );

        expect(
          snapshot.winningTeamId,
          isNull,
        );

        expect(
          snapshot.pieces.length,
          8,
        );
      },
    );

    test(
      'contains four pieces for each team',
      () {
        final game = Game(
          playerCount: 4,
        );

        final snapshot =
            AiGameSnapshot.fromGame(game);

        expect(
          snapshot.piecesForTeam(0).length,
          4,
        );

        expect(
          snapshot.piecesForTeam(1).length,
          4,
        );
      },
    );

    test(
      'copies piece ownership and progress',
      () {
        final game = Game(
          playerCount: 2,
        );

        const adapter =
            GameMoveAdapter();

        final originalPiece =
            game.players[0].pieces[0];

        originalPiece.moveToProgress(7);

        final snapshot =
            AiGameSnapshot.fromGame(
          game,
          adapter: adapter,
        );

        final copiedPiece =
            snapshot.pieceForKey(
          adapter.pieceKey(originalPiece),
        );

        expect(
          copiedPiece.pieceId,
          originalPiece.id,
        );

        expect(
          copiedPiece.ownerId,
          originalPiece.ownerId,
        );

        expect(
          copiedPiece.teamId,
          originalPiece.teamId,
        );

        expect(
          copiedPiece.progress,
          7,
        );

        expect(
          copiedPiece.isActive,
          isTrue,
        );
      },
    );

    test(
      'snapshot does not change when the game changes later',
      () {
        final game = Game(
          playerCount: 2,
        );

        const adapter =
            GameMoveAdapter();

        final originalPiece =
            game.players[0].pieces[0];

        final snapshot =
            AiGameSnapshot.fromGame(
          game,
          adapter: adapter,
        );

        originalPiece.moveToProgress(10);

        final copiedPiece =
            snapshot.pieceForKey(
          adapter.pieceKey(originalPiece),
        );

        expect(
          copiedPiece.progress,
          -1,
        );

        expect(
          originalPiece.progress,
          10,
        );
      },
    );
  });

  group('AiGameSnapshot piece states', () {
    test(
      'identifies inactive, active, and completed pieces',
      () {
        final game = Game(
          playerCount: 2,
        );

        final teamPiece1 =
            game.players[0].pieces[0];

        final teamPiece2 =
            game.players[0].pieces[1];

        teamPiece1.moveToProgress(5);
        teamPiece2.complete();

        final snapshot =
            AiGameSnapshot.fromGame(game);

        expect(
          snapshot.activePieceCount(0),
          1,
        );

        expect(
          snapshot.completedPieceCount(0),
          1,
        );

        expect(
          snapshot.inactivePieceCount(0),
          2,
        );
      },
    );

    test(
      'calculates team progress',
      () {
        final game = Game(
          playerCount: 2,
        );

        final teamPieces =
            game.players[0].pieces;

        teamPieces[0].moveToProgress(5);
        teamPieces[1].moveToProgress(9);
        teamPieces[2].complete();

        final snapshot =
            AiGameSnapshot.fromGame(game);

        expect(
          snapshot.teamProgressScore(0),
          5 + 9 + Board.finishProgress,
        );
      },
    );

    test(
      'finds pieces at the same station',
      () {
        final game = Game(
          playerCount: 4,
        );

        final teammate1 =
            game.players[0].pieces[0];

        final opponent =
            game.players[1].pieces[0];

        final teammate2 =
            game.players[2].pieces[0];

        teammate1.moveToProgress(8);
        opponent.moveToProgress(8);
        teammate2.moveToProgress(8);

        const adapter =
            GameMoveAdapter();

        final snapshot =
            AiGameSnapshot.fromGame(
          game,
          adapter: adapter,
        );

        final teammateStack =
            snapshot.teammatesAtProgress(
          teamId: 0,
          progress: 8,
          excludingPieceKey:
              adapter.pieceKey(teammate1),
        );

        final opponents =
            snapshot.opponentsAtProgress(
          teamId: 0,
          progress: 8,
        );

        expect(
          teammateStack.length,
          1,
        );

        expect(
          teammateStack.first.pieceKey,
          adapter.pieceKey(teammate2),
        );

        expect(
          opponents.length,
          1,
        );

        expect(
          opponents.first.pieceKey,
          adapter.pieceKey(opponent),
        );
      },
    );

    test(
      'identifies teammates and opponents',
      () {
        final game = Game(
          playerCount: 4,
        );

        const adapter =
            GameMoveAdapter();

        final player1Piece =
            game.players[0].pieces[0];

        final player2Piece =
            game.players[1].pieces[0];

        final player3Piece =
            game.players[2].pieces[0];

        final snapshot =
            AiGameSnapshot.fromGame(
          game,
          adapter: adapter,
        );

        expect(
          snapshot.areTeammates(
            adapter.pieceKey(player1Piece),
            adapter.pieceKey(player3Piece),
          ),
          isTrue,
        );

        expect(
          snapshot.areOpponents(
            adapter.pieceKey(player1Piece),
            adapter.pieceKey(player2Piece),
          ),
          isTrue,
        );
      },
    );
  });

  group('AiGameSnapshot validation', () {
    test(
      'throws when a piece key does not exist',
      () {
        final game = Game(
          playerCount: 2,
        );

        final snapshot =
            AiGameSnapshot.fromGame(game);

        expect(
          () => snapshot.pieceForKey(999999),
          throwsA(
            isA<StateError>(),
          ),
        );
      },
    );
  });
}