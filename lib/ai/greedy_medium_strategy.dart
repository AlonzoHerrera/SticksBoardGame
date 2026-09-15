import 'dart:math';

import '../game/board.dart';
import 'ai_strategy.dart';
import 'game_move.dart';

class GreedyMediumStrategy extends AiStrategy {
  final Random _random;

  GreedyMediumStrategy({
    Random? random,
  }) : _random = random ?? Random();

  @override
  String get name => 'Greedy';

  @override
  String get difficulty => 'Medium';

  @override
  GameMove chooseMove({
    required List<GameMove> legalMoves,
  }) {
    if (legalMoves.isEmpty) {
      throw StateError(
        'Greedy Medium cannot choose from an empty move list.',
      );
    }

    var highestScore = _scoreMove(
      legalMoves.first,
    );

    final bestMoves = <GameMove>[
      legalMoves.first,
    ];

    for (
      var index = 1;
      index < legalMoves.length;
      index++
    ) {
      final move = legalMoves[index];
      final score = _scoreMove(move);

      if (score > highestScore) {
        highestScore = score;

        bestMoves
          ..clear()
          ..add(move);
      } else if (score == highestScore) {
        bestMoves.add(move);
      }
    }

    final selectedIndex = _random.nextInt(
      bestMoves.length,
    );

    return bestMoves[selectedIndex];
  }

  int _scoreMove(GameMove move) {
    if (move.isNormal &&
        move.destinationProgress ==
            Board.finishProgress) {
      return 100000;
    }

    if (move.isSpecialCapture) {
      return 50000;
    }

    if (move.isNormal) {
      return move.destinationProgress ?? 0;
    }

    return 0;
  }
}