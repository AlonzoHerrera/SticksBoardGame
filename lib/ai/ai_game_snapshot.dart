import '../game/board.dart';
import '../game/game.dart';
import '../game/game_state.dart';
import 'game_move_adapter.dart';

class AiPieceSnapshot {
  final int pieceKey;
  final int pieceId;
  final int ownerId;
  final int teamId;
  final int progress;

  const AiPieceSnapshot({
    required this.pieceKey,
    required this.pieceId,
    required this.ownerId,
    required this.teamId,
    required this.progress,
  });

  bool get isInactive {
    return progress == -1;
  }

  bool get isCompleted {
    return progress == Board.finishProgress;
  }

  bool get isActive {
    return !isInactive && !isCompleted;
  }

  int? get stationIndex {
    if (!isActive) {
      return null;
    }

    return progress;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AiPieceSnapshot &&
            other.pieceKey == pieceKey &&
            other.pieceId == pieceId &&
            other.ownerId == ownerId &&
            other.teamId == teamId &&
            other.progress == progress;
  }

  @override
  int get hashCode {
    return Object.hash(
      pieceKey,
      pieceId,
      ownerId,
      teamId,
      progress,
    );
  }

  @override
  String toString() {
    return 'AiPieceSnapshot('
        'pieceKey: $pieceKey, '
        'pieceId: $pieceId, '
        'ownerId: $ownerId, '
        'teamId: $teamId, '
        'progress: $progress'
        ')';
  }
}

class AiGameSnapshot {
  final GameState gameState;
  final int? currentPlayerId;
  final int? currentTeamId;
  final int? pendingMoveValue;
  final int? winningTeamId;
  final List<AiPieceSnapshot> pieces;

  AiGameSnapshot({
    required this.gameState,
    required this.currentPlayerId,
    required this.currentTeamId,
    required this.pendingMoveValue,
    required this.winningTeamId,
    required List<AiPieceSnapshot> pieces,
  }) : pieces = List<AiPieceSnapshot>.unmodifiable(
          pieces,
        );

  factory AiGameSnapshot.fromGame(
    Game game, {
    GameMoveAdapter adapter =
        const GameMoveAdapter(),
  }) {
    final pieceSnapshots = <AiPieceSnapshot>[];

    for (final player in game.players) {
      for (final piece in player.pieces) {
        pieceSnapshots.add(
          AiPieceSnapshot(
            pieceKey: adapter.pieceKey(piece),
            pieceId: piece.id,
            ownerId: piece.ownerId,
            teamId: piece.teamId,
            progress: piece.progress,
          ),
        );
      }
    }

    return AiGameSnapshot(
      gameState: game.state,
      currentPlayerId: game.currentPlayer?.id,
      currentTeamId: game.currentTeam?.id,
      pendingMoveValue: game.pendingMoveValue,
      winningTeamId: game.winningTeam?.id,
      pieces: pieceSnapshots,
    );
  }

  AiPieceSnapshot pieceForKey(
    int pieceKey,
  ) {
    for (final piece in pieces) {
      if (piece.pieceKey == pieceKey) {
        return piece;
      }
    }

    throw StateError(
      'No snapshot piece exists for key $pieceKey.',
    );
  }

  List<AiPieceSnapshot> piecesForTeam(
    int teamId,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) => piece.teamId == teamId,
      ),
    );
  }

  List<AiPieceSnapshot> opposingPieces(
    int teamId,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) => piece.teamId != teamId,
      ),
    );
  }

  List<AiPieceSnapshot> activePiecesForTeam(
    int teamId,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) =>
            piece.teamId == teamId &&
            piece.isActive,
      ),
    );
  }

  List<AiPieceSnapshot> completedPiecesForTeam(
    int teamId,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) =>
            piece.teamId == teamId &&
            piece.isCompleted,
      ),
    );
  }

  List<AiPieceSnapshot> inactivePiecesForTeam(
    int teamId,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) =>
            piece.teamId == teamId &&
            piece.isInactive,
      ),
    );
  }

  List<AiPieceSnapshot> piecesAtProgress(
    int progress,
  ) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) => piece.progress == progress,
      ),
    );
  }

  List<AiPieceSnapshot> teammatesAtProgress({
    required int teamId,
    required int progress,
    int? excludingPieceKey,
  }) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) =>
            piece.teamId == teamId &&
            piece.progress == progress &&
            piece.pieceKey != excludingPieceKey,
      ),
    );
  }

  List<AiPieceSnapshot> opponentsAtProgress({
    required int teamId,
    required int progress,
  }) {
    return List<AiPieceSnapshot>.unmodifiable(
      pieces.where(
        (piece) =>
            piece.teamId != teamId &&
            piece.progress == progress,
      ),
    );
  }

  int teamProgressScore(
    int teamId,
  ) {
    var score = 0;

    for (final piece in piecesForTeam(teamId)) {
      if (piece.isCompleted) {
        score += Board.finishProgress;
      } else if (piece.isActive) {
        score += piece.progress;
      }
    }

    return score;
  }

  int completedPieceCount(
    int teamId,
  ) {
    return completedPiecesForTeam(
      teamId,
    ).length;
  }

  int activePieceCount(
    int teamId,
  ) {
    return activePiecesForTeam(
      teamId,
    ).length;
  }

  int inactivePieceCount(
    int teamId,
  ) {
    return inactivePiecesForTeam(
      teamId,
    ).length;
  }

  bool areOpponents(
    int firstPieceKey,
    int secondPieceKey,
  ) {
    final first = pieceForKey(
      firstPieceKey,
    );

    final second = pieceForKey(
      secondPieceKey,
    );

    return first.teamId != second.teamId;
  }

  bool areTeammates(
    int firstPieceKey,
    int secondPieceKey,
  ) {
    final first = pieceForKey(
      firstPieceKey,
    );

    final second = pieceForKey(
      secondPieceKey,
    );

    return first.teamId == second.teamId;
  }
}