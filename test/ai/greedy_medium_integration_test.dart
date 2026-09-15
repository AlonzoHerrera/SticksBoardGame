import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/ai/ai_turn_controller.dart';
import 'package:homework1game/ai/game_move_adapter.dart';
import 'package:homework1game/ai/greedy_medium_strategy.dart';
import 'package:homework1game/game/game.dart';
import 'package:homework1game/game/game_state.dart';

void main() {
  group('Greedy Medium game integration', () {
    test(
      'selects and applies a real legal game move',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy =
            GreedyMediumStrategy(
          random: Random(1),
        );

        const adapter =
            GameMoveAdapter();

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

        final legalMoves =
            adapter.legalMoves(game);

        final selectedMove =
            strategy.chooseValidatedMove(
          legalMoves: legalMoves,
        );

        expect(
          legalMoves,
          contains(selectedMove),
        );

        final selectedPiece =
            adapter.pieceForKey(
          game,
          selectedMove.movingPieceId,
        );

        adapter.applyMove(
          game,
          selectedMove,
        );

        expect(
          selectedPiece.progress,
          selectedMove
              .destinationProgress,
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
      'works through the AI turn controller',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy =
            GreedyMediumStrategy(
          random: Random(2),
        );

        const controller =
            AiTurnController();

        game.throwSpecificSticks(
          <bool>[
            true,
            true,
            true,
            false,
          ],
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
          'Greedy',
        );

        expect(
          result.selectedMove,
          isNotNull,
        );

        expect(
          result.selectedMove!.isNormal,
          isTrue,
        );
      },
    );

    test(
      'prefers an X stick capture in a real game state',
      () {
        final game = Game(
          playerCount: 2,
        );

        final strategy =
            GreedyMediumStrategy(
          random: Random(3),
        );

        const controller =
            AiTurnController();

        final opponentPiece =
            game.players[1].pieces[0];

        opponentPiece.moveToProgress(6);

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
          result.strategyName,
          'Greedy',
        );

        expect(
          opponentPiece.isInactive,
          isTrue,
        );
      },
    );
  });
}