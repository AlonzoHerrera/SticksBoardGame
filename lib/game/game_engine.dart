import 'board.dart';
import 'game_state.dart';
import 'piece.dart';
import 'player.dart';
import 'team.dart';
import 'throw_result.dart';

abstract interface class GameEngine {
  GameState get state;

  Board get board;

  List<Player> get players;

  List<Team> get teams;

  Player? get currentPlayer;

  Team? get currentTeam;

  Team? get winningTeam;

  int? get pendingMoveValue;

  bool get hasPendingMove;

  bool get extraTurnEarned;

  ThrowResult? get lastThrowResult;

  bool get specialMovePending;

  int throwSticks();

  void movePiece(
    Piece piece,
    int moveValue,
  );

  void movePieceToStation(
    Piece piece,
    int moveValue,
    int destinationStation,
  );

  bool canMovePiece(
    Piece piece,
    int moveValue,
  );

  List<Piece> legalPiecesForCurrentThrow();

  List<int> legalDestinationsForPiece(
    Piece piece,
    int moveValue,
  );

  List<Piece> legalSpecialTargets();

  void specialCapture({
    required Piece movingPiece,
    required Piece targetPiece,
  });

  void skipMoveIfNoLegalMove();
}