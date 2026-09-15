enum GameMoveType {
  normal,
  specialCapture,
}

class GameMove {
  final GameMoveType type;

  // ID of the piece selected by the AI.
  final int movingPieceId;

  // Required for a normal move.
  // This is the value produced by the stick throw.
  final int? moveValue;

  // Required for a normal move.
  // A value of 29 represents crossing the finish.
  final int? destinationProgress;

  // Required only for an X-stick special capture.
  final int? targetPieceId;

  const GameMove._({
    required this.type,
    required this.movingPieceId,
    this.moveValue,
    this.destinationProgress,
    this.targetPieceId,
  });

  factory GameMove.normal({
    required int movingPieceId,
    required int moveValue,
    required int destinationProgress,
  }) {
    if (movingPieceId < 0) {
      throw ArgumentError.value(
        movingPieceId,
        'movingPieceId',
        'Moving piece ID cannot be negative.',
      );
    }

    if (moveValue < 1 || moveValue > 5) {
      throw ArgumentError.value(
        moveValue,
        'moveValue',
        'Move value must be between 1 and 5.',
      );
    }

    if (destinationProgress < 0 ||
        destinationProgress > 29) {
      throw ArgumentError.value(
        destinationProgress,
        'destinationProgress',
        'Destination progress must be between 0 and 29.',
      );
    }

    return GameMove._(
      type: GameMoveType.normal,
      movingPieceId: movingPieceId,
      moveValue: moveValue,
      destinationProgress: destinationProgress,
    );
  }

  factory GameMove.specialCapture({
    required int movingPieceId,
    required int targetPieceId,
  }) {
    if (movingPieceId < 0) {
      throw ArgumentError.value(
        movingPieceId,
        'movingPieceId',
        'Moving piece ID cannot be negative.',
      );
    }

    if (targetPieceId < 0) {
      throw ArgumentError.value(
        targetPieceId,
        'targetPieceId',
        'Target piece ID cannot be negative.',
      );
    }

    if (movingPieceId == targetPieceId) {
      throw ArgumentError(
        'A piece cannot target itself.',
      );
    }

    return GameMove._(
      type: GameMoveType.specialCapture,
      movingPieceId: movingPieceId,
      targetPieceId: targetPieceId,
    );
  }

  bool get isNormal {
    return type == GameMoveType.normal;
  }

  bool get isSpecialCapture {
    return type == GameMoveType.specialCapture;
  }

  String get moveId {
    if (isNormal) {
      return 'NORMAL_'
          '${movingPieceId}_'
          '${moveValue}_'
          '$destinationProgress';
    }

    return 'SPECIAL_'
        '${movingPieceId}_'
        '$targetPieceId';
  }

  void validate() {
    if (movingPieceId < 0) {
      throw StateError(
        'Moving piece ID cannot be negative.',
      );
    }

    switch (type) {
      case GameMoveType.normal:
        if (moveValue == null) {
          throw StateError(
            'A normal move must contain a move value.',
          );
        }

        if (destinationProgress == null) {
          throw StateError(
            'A normal move must contain a destination.',
          );
        }

        if (targetPieceId != null) {
          throw StateError(
            'A normal move cannot contain a target piece.',
          );
        }

        if (moveValue! < 1 || moveValue! > 5) {
          throw StateError(
            'Normal move value must be between 1 and 5.',
          );
        }

        if (destinationProgress! < 0 ||
            destinationProgress! > 29) {
          throw StateError(
            'Normal destination must be between 0 and 29.',
          );
        }

      case GameMoveType.specialCapture:
        if (targetPieceId == null) {
          throw StateError(
            'A special capture must contain a target piece.',
          );
        }

        if (moveValue != null ||
            destinationProgress != null) {
          throw StateError(
            'A special capture cannot contain normal-move data.',
          );
        }

        if (targetPieceId! < 0) {
          throw StateError(
            'Target piece ID cannot be negative.',
          );
        }

        if (targetPieceId == movingPieceId) {
          throw StateError(
            'A piece cannot target itself.',
          );
        }
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GameMove &&
            other.type == type &&
            other.movingPieceId == movingPieceId &&
            other.moveValue == moveValue &&
            other.destinationProgress ==
                destinationProgress &&
            other.targetPieceId == targetPieceId;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      movingPieceId,
      moveValue,
      destinationProgress,
      targetPieceId,
    );
  }

  @override
  String toString() {
    if (isNormal) {
      return 'GameMove.normal('
          'piece: $movingPieceId, '
          'moveValue: $moveValue, '
          'destination: $destinationProgress'
          ')';
    }

    return 'GameMove.specialCapture('
        'piece: $movingPieceId, '
        'target: $targetPieceId'
        ')';
  }
}