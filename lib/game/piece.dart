import 'board.dart';
import 'game_rule_exception.dart';

class Piece {
  final int id;
  final int ownerId;
  final int teamId;

  int _progress = -1;
  DiagonalTravel? _diagonalTravel;

  Piece({required this.id, required this.ownerId, required this.teamId});

  int get progress => _progress;

  DiagonalTravel? get diagonalTravel {
    return _diagonalTravel;
  }

  bool get isInactive => _progress == -1;

  bool get isCompleted {
    return _progress == Board.finishProgress;
  }

  bool get isActive {
    return !isInactive && !isCompleted;
  }

  int? get stationIndex {
    if (isInactive || isCompleted) {
      return null;
    }

    return _progress;
  }

  void moveToProgress(int newProgress, {DiagonalTravel? diagonalTravel}) {
    if (newProgress < -1 || newProgress > Board.finishProgress) {
      throw GameRuleException('Invalid piece progress: $newProgress.');
    }

    _progress = newProgress;

    if (newProgress == -1 ||
        newProgress == Board.finishProgress ||
        !Board.diagonalStations.contains(newProgress)) {
      _diagonalTravel = null;
    } else {
      _diagonalTravel = diagonalTravel;
    }

    validateInvariants();
  }

  void setDiagonalTravel(DiagonalTravel? diagonalTravel) {
    if (!isActive ||
        stationIndex == null ||
        !Board.diagonalStations.contains(stationIndex)) {
      _diagonalTravel = null;
    } else {
      _diagonalTravel = diagonalTravel;
    }

    validateInvariants();
  }

  void sendToStart() {
    moveToProgress(-1);
  }

  void complete() {
    moveToProgress(Board.finishProgress);
  }

  void validateInvariants() {
    if (id < 0) {
      throw StateError('Piece ID cannot be negative.');
    }

    if (ownerId < 0) {
      throw StateError('Piece owner ID cannot be negative.');
    }

    if (teamId < 0 || teamId > 1) {
      throw StateError('Piece must belong to Team 1 or Team 2.');
    }

    if (_progress < -1 || _progress > Board.finishProgress) {
      throw StateError('Piece $id has invalid progress $_progress.');
    }

    if (isInactive || isCompleted) {
      if (_diagonalTravel != null) {
        throw StateError(
          'Inactive and completed pieces cannot '
          'store diagonal travel.',
        );
      }
    }

    if (isActive &&
        !Board.diagonalStations.contains(_progress) &&
        _diagonalTravel != null) {
      throw StateError(
        'A piece outside the diagonal paths cannot '
        'store diagonal travel.',
      );
    }
  }

  @override
  String toString() {
    if (isInactive) {
      return 'Piece $id: inactive';
    }

    if (isCompleted) {
      return 'Piece $id: completed';
    }

    if (_diagonalTravel != null) {
      return 'Piece $id: station $stationIndex '
          '($_diagonalTravel)';
    }

    return 'Piece $id: station $stationIndex';
  }
}
