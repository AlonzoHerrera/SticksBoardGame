import 'dart:math';

import '../game/board.dart';
import 'ai_game_snapshot.dart';
import 'ai_strategy.dart';
import 'game_move.dart';

class HeuristicHardStrategy
    extends SnapshotAwareAiStrategy {
  final Random _random;

  AiGameSnapshot? _snapshot;

  HeuristicHardStrategy({
    Random? random,
  }) : _random = random ?? Random();

  @override
  String get name => 'Heuristic';

  @override
  String get difficulty => 'Hard';

  @override
  void updateSnapshot(
    AiGameSnapshot snapshot,
  ) {
    _snapshot = snapshot;
  }

  @override
  GameMove chooseMove({
    required List<GameMove> legalMoves,
  }) {
    if (legalMoves.isEmpty) {
      throw StateError(
        'Heuristic Hard cannot choose from an empty move list.',
      );
    }

    final snapshot = _snapshot;

    if (snapshot == null) {
      throw StateError(
        'Heuristic Hard requires a game snapshot before choosing a move.',
      );
    }

    var highestScore = _scoreMove(
      legalMoves.first,
      snapshot,
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

      final score = _scoreMove(
        move,
        snapshot,
      );

      if (score > highestScore) {
        highestScore = score;

        bestMoves
          ..clear()
          ..add(move);
      } else if (score == highestScore) {
        bestMoves.add(move);
      }
    }

    return bestMoves[
        _random.nextInt(bestMoves.length)];
  }

  int _scoreMove(
    GameMove move,
    AiGameSnapshot snapshot,
  ) {
    if (move.isSpecialCapture) {
      return _scoreSpecialCapture(
        move,
        snapshot,
      );
    }

    return _scoreNormalMove(
      move,
      snapshot,
    );
  }

  int _scoreSpecialCapture(
    GameMove move,
    AiGameSnapshot snapshot,
  ) {
    final targetPiece = snapshot.pieceForKey(
      move.targetPieceId!,
    );

    var score = 60000;

    // Capturing a piece farther along the board is more valuable.
    if (targetPiece.isActive) {
      score += targetPiece.progress * 200;
    }

    // Capturing part of an opponent stack is especially valuable.
    final targetStack =
        snapshot.opponentsAtProgress(
      teamId: snapshot.currentTeamId!,
      progress: targetPiece.progress,
    );

    score += targetStack.length * 5000;

    return score;
  }

  int _scoreNormalMove(
    GameMove move,
    AiGameSnapshot snapshot,
  ) {
    final movingPiece = snapshot.pieceForKey(
      move.movingPieceId,
    );

    final destination =
        move.destinationProgress!;

    var score = 0;

    // Finishing a piece is the strongest normal move.
    if (destination == Board.finishProgress) {
      score += 100000;
    }

    // Reward general forward movement.
    score += destination * 100;

    // Reward bringing an inactive piece onto the board.
    if (movingPiece.isInactive) {
      score += 1500;
    }

    final opponentsAtDestination =
        snapshot.opponentsAtProgress(
      teamId: movingPiece.teamId,
      progress: destination,
    );

    // A normal landing capture is highly valuable.
    if (opponentsAtDestination.isNotEmpty) {
      score += 30000;

      score +=
          opponentsAtDestination.length *
              5000;

      for (final opponent
          in opponentsAtDestination) {
        if (opponent.isActive) {
          score += opponent.progress * 100;
        }
      }
    }

    final teammatesAtDestination =
        snapshot.teammatesAtProgress(
      teamId: movingPiece.teamId,
      progress: destination,
      excludingPieceKey:
          movingPiece.pieceKey,
    );

    // Reward creating or growing a teammate stack.
    if (teammatesAtDestination.isNotEmpty) {
      score += 12000;

      score +=
          teammatesAtDestination.length *
              2000;
    }

    // Slightly reward moving a piece that is behind the team's leaders.
    // This helps avoid moving only one piece for the entire game.
    if (movingPiece.isActive) {
      score +=
          Board.finishProgress -
              movingPiece.progress;
    }

    return score;
  }
}