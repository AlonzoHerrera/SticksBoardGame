import 'dart:math';

import 'ai_strategy.dart';
import 'game_move.dart';

class RandomEasyStrategy extends AiStrategy {
  final Random _random;

  RandomEasyStrategy({
    Random? random,
  }) : _random = random ?? Random();

  @override
  String get name => 'Random';

  @override
  String get difficulty => 'Easy';

  @override
  GameMove chooseMove({
    required List<GameMove> legalMoves,
  }) {
    if (legalMoves.isEmpty) {
      throw StateError(
        'Random Easy cannot choose from an empty move list.',
      );
    }

    final index = _random.nextInt(
      legalMoves.length,
    );

    return legalMoves[index];
  }

  /// Returns the legal move selected at random after validating it.
  GameMove chooseRandomMove({
    required List<GameMove> legalMoves,
  }) {
    return chooseValidatedMove(
      legalMoves: legalMoves,
    );
  }

  @override
  String toString() {
    return '$name ($difficulty)';
  }
}