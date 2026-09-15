import '../game/game.dart';
import '../game/game_rule_exception.dart';
import '../game/game_state.dart';
import '../game/piece.dart';
import 'game_move.dart';

class GameMoveAdapter {
  const GameMoveAdapter();

  /// Creates a unique number for every piece.
  ///
  /// Piece IDs repeat between players. For example, Player 1 and
  /// Player 2 may both own a Piece 0. This key combines the owner
  /// ID and piece ID so the AI can identify the exact piece.
  int pieceKey(Piece piece) {
    return (piece.ownerId * 1000) + piece.id;
  }

  /// Finds the exact piece represented by an AI piece key.
  Piece pieceForKey(
    Game game,
    int pieceKey,
  ) {
    for (final player in game.players) {
      for (final piece in player.pieces) {
        if (this.pieceKey(piece) == pieceKey) {
          return piece;
        }
      }
    }

    throw GameRuleException(
      'Piece key $pieceKey does not exist.',
    );
  }

  /// Converts the current game state into a list of legal GameMove
  /// objects that may be given to an AI strategy.
  List<GameMove> legalMoves(Game game) {
    if (game.state == GameState.gameOver) {
      return const <GameMove>[];
    }

    if (game.state == GameState.waitingForMove) {
      return _normalMoves(game);
    }

    if (game.state == GameState.waitingForSpecialMove) {
      return _specialMoves(game);
    }

    return const <GameMove>[];
  }

  List<GameMove> _normalMoves(Game game) {
    final currentPlayer = game.currentPlayer;
    final moveValue = game.pendingMoveValue;

    if (currentPlayer == null || moveValue == null) {
      return const <GameMove>[];
    }

    final moves = <GameMove>[];

    for (final piece in currentPlayer.pieces) {
      final destinations =
          game.legalDestinationsForPiece(
        piece,
        moveValue,
      );

      for (final destination in destinations) {
        moves.add(
          GameMove.normal(
            movingPieceId: pieceKey(piece),
            moveValue: moveValue,
            destinationProgress: destination,
          ),
        );
      }
    }

    return List<GameMove>.unmodifiable(moves);
  }

  List<GameMove> _specialMoves(Game game) {
    final currentPlayer = game.currentPlayer;

    if (currentPlayer == null) {
      return const <GameMove>[];
    }

    final targets = game.legalSpecialTargets();

    if (targets.isEmpty) {
      return const <GameMove>[];
    }

    final moves = <GameMove>[];

    for (final movingPiece in currentPlayer.pieces) {
      for (final targetPiece in targets) {
        moves.add(
          GameMove.specialCapture(
            movingPieceId: pieceKey(movingPiece),
            targetPieceId: pieceKey(targetPiece),
          ),
        );
      }
    }

    return List<GameMove>.unmodifiable(moves);
  }

  /// Applies a GameMove through the existing game engine.
  ///
  /// The adapter first rebuilds the current legal move list.
  /// This prevents an AI from applying a move that is no longer legal.
  void applyMove(
    Game game,
    GameMove move,
  ) {
    if (game.state == GameState.gameOver) {
      throw GameRuleException(
        'The game is over.',
      );
    }

    move.validate();

    final currentLegalMoves = legalMoves(game);

    if (!currentLegalMoves.contains(move)) {
      throw GameRuleException(
        'The selected AI move is not legal in the current game state.',
      );
    }

    final movingPiece = pieceForKey(
      game,
      move.movingPieceId,
    );

    if (move.isNormal) {
      game.movePieceToStation(
        movingPiece,
        move.moveValue!,
        move.destinationProgress!,
      );

      return;
    }

    final targetPiece = pieceForKey(
      game,
      move.targetPieceId!,
    );

    game.specialCapture(
      movingPiece: movingPiece,
      targetPiece: targetPiece,
    );
  }
}