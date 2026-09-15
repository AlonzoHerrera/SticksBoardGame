import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/game/board.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_state.dart';

void main() {
  group('Game B team setup', () {
    test('game always contains exactly two teams', () {
      final game = Game();

      expect(game.teams.length, 2);
      expect(game.teams[0].name, 'Team 1');
      expect(game.teams[1].name, 'Team 2');
    });

    test('two-player game gives each player four pieces', () {
      final game = Game(playerCount: 2);

      expect(game.players.length, 2);

      expect(game.players[0].pieces.length, 4);
      expect(game.players[1].pieces.length, 4);

      expect(game.players[0].teamId, 0);
      expect(game.players[1].teamId, 1);
    });

    test('three-player game assigns four total pieces to each team', () {
      final game = Game(playerCount: 3);

      expect(game.players.length, 3);

      expect(game.piecesForTeam(0).length, 4);
      expect(game.piecesForTeam(1).length, 4);

      expect(game.players[0].pieces.length, 2);
      expect(game.players[1].pieces.length, 4);
      expect(game.players[2].pieces.length, 2);
    });

    test('four-player game gives each player two pieces', () {
      final game = Game(playerCount: 4);

      expect(game.players.length, 4);

      for (final player in game.players) {
        expect(player.pieces.length, 2);
      }
    });

    test('four-player teams are Player 1 and 3 versus Player 2 and 4', () {
      final game = Game(playerCount: 4);

      final player1 = game.players[0];
      final player2 = game.players[1];
      final player3 = game.players[2];
      final player4 = game.players[3];

      expect(player1.teamId, 0);
      expect(player3.teamId, 0);

      expect(player2.teamId, 1);
      expect(player4.teamId, 1);

      expect(
        game.teams[0].playerIds,
        containsAll(<int>[player1.id, player3.id]),
      );

      expect(
        game.teams[1].playerIds,
        containsAll(<int>[player2.id, player4.id]),
      );
    });

    test('each team always controls exactly four pieces', () {
      for (final playerCount in <int>[2, 3, 4]) {
        final game = Game(playerCount: playerCount);

        expect(game.piecesForTeam(0).length, Game.piecesPerTeam);

        expect(game.piecesForTeam(1).length, Game.piecesPerTeam);
      }
    });
  });

  group('Board route structure', () {
    test('board contains exactly 29 visible stations', () {
      final board = Board();

      expect(board.connections.length, Board.stationCount);

      for (var station = 0; station < Board.stationCount; station++) {
        expect(
          board.connections.containsKey(station),
          isTrue,
          reason: 'Board should contain station $station.',
        );
      }
    });

    test('start station does not allow a diagonal move', () {
      final board = Board();

      expect(board.neighborsOf(0), equals(<int>[1]));
    });

    test('only stations 5, 10, 15, and 28 provide route choices', () {
      final board = Board();

      const expectedBranchStations = <int>{5, 10, 15, 28};

      for (var station = 0; station < Board.stationCount; station++) {
        final destinations = board.neighborsOf(station);

        if (expectedBranchStations.contains(station)) {
          expect(
            destinations.length,
            2,
            reason: 'Station $station should provide two routes.',
          );
        } else {
          expect(
            destinations.length,
            1,
            reason: 'Station $station should provide one route.',
          );
        }
      }
    });

    test('station 5 may continue outside or enter its diagonal', () {
      final board = Board();

      expect(board.neighborsOf(5), equals(<int>[6, 22]));
    });

    test('station 10 may continue outside or enter its diagonal', () {
      final board = Board();

      expect(board.neighborsOf(10), equals(<int>[11, 24]));
    });

    test('station 15 may continue outside or enter its diagonal', () {
      final board = Board();

      expect(board.neighborsOf(15), equals(<int>[16, 26]));
    });

    test('station 28 provides its two allowed routes', () {
      final board = Board();

      expect(board.neighborsOf(28), equals(<int>[19, 20]));
    });

    test('station 19 leads directly to the finish', () {
      final board = Board();

      expect(board.neighborsOf(19), equals(<int>[Board.finishProgress]));
    });
  });

  group('Game-level movement integration', () {
    test('game exposes only station 9 from station 4 with a throw of 5', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(4);

      expect(game.legalDestinationsForPiece(piece, 5), equals(<int>[9]));
    });

    test('passing through station 5 does not open the diagonal', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(4);

      final destinations = game.legalDestinationsForPiece(piece, 5);

      expect(destinations, equals(<int>[9]));
      expect(destinations, isNot(contains(22)));
      expect(destinations, isNot(contains(28)));
      expect(destinations, isNot(contains(Board.finishProgress)));
    });

    test('station 5 with a throw of 3 offers only 8 and 28', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(5);

      expect(game.legalDestinationsForPiece(piece, 3), equals(<int>[8, 28]));
    });

    test('station 5 with a throw of 3 cannot cross the finish', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(5);

      expect(
        game.legalDestinationsForPiece(piece, 3),
        isNot(contains(Board.finishProgress)),
      );
    });

    test('station 23 with a throw of 1 reaches station 28', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(23);

      expect(game.legalDestinationsForPiece(piece, 1), equals(<int>[28]));
    });

    test('station 23 with a throw of 3 reaches station 26', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(23);

      expect(game.legalDestinationsForPiece(piece, 3), equals(<int>[26]));
    });

    test('station 23 with a throw of 3 does not reach 21 or finish', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(23);

      final destinations = game.legalDestinationsForPiece(piece, 3);

      expect(destinations, equals(<int>[26]));
      expect(destinations, isNot(contains(21)));
      expect(destinations, isNot(contains(Board.finishProgress)));
    });

    test('station 28 with a throw of 1 offers 19 and 20', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(28);

      expect(game.legalDestinationsForPiece(piece, 1), equals(<int>[19, 20]));
    });

    test('station 28 with a throw of 2 reaches station 21', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(28);

      expect(game.legalDestinationsForPiece(piece, 2), equals(<int>[21]));
    });

    test('station 28 with a throw of 3 offers 19 or finish', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(28);

      expect(
        game.legalDestinationsForPiece(piece, 3),
        equals(<int>[19, Board.finishProgress]),
      );
    });

    test('completed pieces have no legal destinations', () {
      final game = Game(playerCount: 2);
      final piece = game.players[0].pieces[0];

      piece.moveToProgress(Board.finishProgress);

      expect(game.legalDestinationsForPiece(piece, 1), isEmpty);
    });
  });

  group('Team-based special move rules', () {
    test('X-stick targets only opposing-team pieces', () {
      final game = Game(playerCount: 4);

      final player1 = game.players[0];
      final player2 = game.players[1];
      final player3 = game.players[2];

      final currentPlayerPiece = player1.pieces[0];
      final opponentPiece = player2.pieces[0];
      final teammatePiece = player3.pieces[0];

      currentPlayerPiece.moveToProgress(2);
      opponentPiece.moveToProgress(4);
      teammatePiece.moveToProgress(6);

      game.throwSpecificSticks(<bool>[true, false, false, false]);

      expect(game.state, GameState.waitingForSpecialMove);

      final legalTargets = game.legalSpecialTargets();

      expect(legalTargets, contains(opponentPiece));

      expect(legalTargets, isNot(contains(teammatePiece)));

      expect(legalTargets, isNot(contains(currentPlayerPiece)));
    });

    test('teammate piece is not considered an X-stick opponent', () {
      final game = Game(playerCount: 4);

      final teammatePiece = game.players[2].pieces[0];

      teammatePiece.moveToProgress(5);

      game.throwSpecificSticks(<bool>[true, false, false, false]);

      expect(game.currentPlayer?.name, 'Player 1');

      expect(game.currentTeam?.name, 'Team 1');

      expect(game.legalSpecialTargets(), isEmpty);

      expect(game.state, GameState.waitingForThrow);
    });
  });

  group('Initial game state', () {
    test('Player 1 and Team 1 begin the game', () {
      final game = Game();

      expect(game.currentPlayer?.name, 'Player 1');

      expect(game.currentTeam?.name, 'Team 1');

      expect(game.state, GameState.waitingForThrow);

      expect(game.winningTeam, isNull);
    });

    test('all pieces begin inactive', () {
      final game = Game();

      final allPieces = game.players.expand((player) => player.pieces).toList();

      expect(allPieces.every((piece) => piece.isInactive), isTrue);
    });
  });
}
