import 'piece.dart';

class Player {
  final int id;
  final String name;
  final int teamId;
  final List<Piece> pieces;

  Player({
    required this.id,
    required this.name,
    required this.teamId,
    required int numberOfPieces,
  }) : pieces = List.generate(
          numberOfPieces,
          (index) => Piece(
            id: index,
            ownerId: id,
            teamId: teamId,
          ),
        ) {
    validateInvariants(
      expectedPieceCount: numberOfPieces,
    );
  }

  void validateInvariants({
    required int expectedPieceCount,
  }) {
    if (id < 0) {
      throw StateError('Player ID cannot be negative.');
    }

    if (teamId < 0 || teamId > 1) {
      throw StateError(
        '$name must belong to Team 1 or Team 2.',
      );
    }

    if (expectedPieceCount != 2 &&
        expectedPieceCount != 4) {
      throw StateError(
        'A player must control either two or four pieces.',
      );
    }

    if (pieces.length != expectedPieceCount) {
      throw StateError(
        '$name must have exactly $expectedPieceCount pieces.',
      );
    }

    for (final piece in pieces) {
      if (piece.ownerId != id) {
        throw StateError(
          '$name owns a piece with the wrong owner ID.',
        );
      }

      if (piece.teamId != teamId) {
        throw StateError(
          '$name owns a piece assigned to the wrong team.',
        );
      }

      piece.validateInvariants();
    }
  }

  bool controlsPiece(Piece piece) {
    return pieces.contains(piece);
  }

  @override
  String toString() => name;
}