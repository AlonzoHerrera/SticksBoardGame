import 'ai_game_snapshot.dart';
import 'game_move.dart';

abstract class AiStrategy {
  String get name;

  String get difficulty;

  GameMove chooseMove({
    required List<GameMove> legalMoves,
  });

  GameMove chooseValidatedMove({
    required List<GameMove> legalMoves,
  }) {
    if (legalMoves.isEmpty) {
      throw StateError(
        '$name cannot choose a move because the legal move list is empty.',
      );
    }

    final protectedMoves = List<GameMove>.unmodifiable(
      legalMoves,
    );

    final selectedMove = chooseMove(
      legalMoves: protectedMoves,
    );

    _validateSelectedMove(
      selectedMove: selectedMove,
      legalMoves: legalMoves,
    );

    return selectedMove;
  }

  void _validateSelectedMove({
    required GameMove selectedMove,
    required List<GameMove> legalMoves,
  }) {
    selectedMove.validate();

    if (!legalMoves.contains(selectedMove)) {
      throw StateError(
        '$name selected a move that was not included in the legal move list.',
      );
    }
  }

  @override
  String toString() {
    return '$name ($difficulty)';
  }
}

/// Used by strategies that must wait for an external service,
/// such as an LLM API, before selecting a move.
abstract interface class AsyncAiStrategy {
  Future<GameMove> chooseValidatedMoveAsync({
    required List<GameMove> legalMoves,
  });
}

/// A strategy that needs a read-only copy of the game before choosing.
///
/// Random Easy and Greedy Medium do not require a snapshot.
/// Heuristic Hard and the LLM strategy can inspect the current game state.
abstract class SnapshotAwareAiStrategy extends AiStrategy {
  void updateSnapshot(
    AiGameSnapshot snapshot,
  );
}