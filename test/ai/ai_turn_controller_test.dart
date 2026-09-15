import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_turn_controller.dart';
import 'package:homework1game/ai/random_easy_strategy.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_state.dart';

class FixedStickRandom implements Random {
  final List<bool> stickResults;
  int _boolIndex = 0;

  FixedStickRandom(
    this.stickResults,
  ) {
    if (stickResults.length != 4) {
      throw ArgumentError(
        'FixedStickRandom requires exactly four stick results.',
      );
    }
  }

  @override
  bool nextBool() {
    final result =
        stickResults[_boolIndex % stickResults.length];

    _boolIndex++;

    return result;
  }

  @override
  double nextDouble() {
    return 0.0;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(
        max,
        'max',
        'Maximum must be greater than zero.',
      );
    }

    return 0;
  }
}

void main() {
  group('AiTurnController normal turns', () {
    test(
      'throws the sticks and applies a normal AI move',
      () {
        final game = Game(
          playerCount: 2,
          random: FixedStickRandom(
            <bool>[
              true,
              true,
              false,
              false,
            ],
          ),
        );

        final strategy = RandomEasyStrategy(
          random: Random(1),
        );

        const controller = AiTurnController();

        final playerBefore =
            game.currentPlayer;

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(
          result.actionType,
          AiActionType.normalMove,
        );

        expect(
          result.selectedMove,
          isNotNull,
        );

        expect(
          result.selectedMove!.isNormal,
          isTrue,
        );

        expect(
          result.throwResult?.moveValue,
          2,
        );

        expect(
          result.actingPlayerId,
          playerBefore?.id,
        );

        expect(
          game.currentPlayer?.name,
          'Player 2',
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );

    test(
      'can apply a move when the sticks were already thrown',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy = RandomEasyStrategy(
          random: Random(2),
        );

        const controller = AiTurnController();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            true,
            false,
          ],
        );

        expect(
          game.state,
          GameState.waitingForMove,
        );

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(
          result.actionType,
          AiActionType.normalMove,
        );

        expect(
          result.selectedMove?.moveValue,
          3,
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );

    test(
      'records the acting player before the turn changes',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy = RandomEasyStrategy(
          random: Random(3),
        );

        const controller = AiTurnController();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(
          result.actingPlayerName,
          'Player 1',
        );

        expect(
          result.actingTeamId,
          0,
        );

        expect(
          game.currentPlayer?.name,
          'Player 2',
        );
      },
    );
  });

  group('AiTurnController special turns', () {
    test(
      'applies an X stick capture through the AI',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy = RandomEasyStrategy(
          random: Random(4),
        );

        const controller = AiTurnController();

        final opponentPiece =
            game.players[1].pieces[0];

        opponentPiece.moveToProgress(5);

        game.throwSpecificSticks(
          <bool>[
            true,
            false,
            false,
            false,
          ],
        );

        expect(
          game.state,
          GameState.waitingForSpecialMove,
        );

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(
          result.actionType,
          AiActionType.specialCapture,
        );

        expect(
          result.selectedMove?.isSpecialCapture,
          isTrue,
        );

        expect(
          opponentPiece.isInactive,
          isTrue,
        );

        // An X stick capture gives the same player another throw.
        expect(
          game.currentPlayer?.name,
          'Player 1',
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );

    test(
      'reports an X stick throw with no legal target',
      () {
        final game = Game(
          playerCount: 2,
          random: FixedStickRandom(
            <bool>[
              true,
              false,
              false,
              false,
            ],
          ),
        );

        final strategy = RandomEasyStrategy(
          random: Random(5),
        );

        const controller = AiTurnController();

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(
          result.actionType,
          AiActionType.specialThrowWithoutTarget,
        );

        expect(
          result.selectedMove,
          isNull,
        );

        expect(
          game.currentPlayer?.name,
          'Player 1',
        );

        expect(
          game.state,
          GameState.waitingForThrow,
        );
      },
    );
  });

  group('AiTurnResult', () {
    test(
      'normal move result reports that a move occurred',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy = RandomEasyStrategy(
          random: Random(6),
        );

        const controller = AiTurnController();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
            false,
          ],
        );

        final result =
            controller.performNextAction(
          game: game,
          strategy: strategy,
        );

        expect(result.moved, isTrue);
        expect(result.skipped, isFalse);
        expect(result.isGameOver, isFalse);

        expect(
          result.message,
          contains('normal move'),
        );
      },
    );
  });
}