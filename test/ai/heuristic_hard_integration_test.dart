import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_turn_controller.dart';
import 'package:homework1game/ai/heuristic_hard_strategy.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_state.dart';

void main() {
  group('Heuristic Hard integration', () {
    test(
      'controller automatically provides the snapshot',
      () {
        final game =
            Game(playerCount: 2);

        final strategy =
            HeuristicHardStrategy(
          random: Random(1),
        );

        const controller =
            AiTurnController();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            false,
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
          result.strategyName,
          'Heuristic',
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
          game.currentPlayer?.name,
          'Player 2',
        );
      },
    );

    test(
      'controller supports an X stick capture',
      () {
        final game =
            Game(playerCount: 2);

        final strategy =
            HeuristicHardStrategy(
          random: Random(2),
        );

        const controller =
            AiTurnController();

        final nearbyOpponent =
            game.players[1].pieces[0];

        final advancedOpponent =
            game.players[1].pieces[1];

        nearbyOpponent.moveToProgress(5);
        advancedOpponent.moveToProgress(16);

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
          advancedOpponent.isInactive,
          isTrue,
        );

        expect(
          nearbyOpponent.progress,
          5,
        );

        expect(
          game.currentPlayer?.name,
          'Player 1',
        );
      },
    );
  });
}