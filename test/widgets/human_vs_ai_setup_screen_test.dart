import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/models/ai_difficulty.dart';
import 'package:homework1game/models/match_configuration.dart';
import 'package:homework1game/widgets/human_vs_ai_setup_screen.dart';

void main() {
  Widget buildScreen({
    required void Function(
      MatchConfiguration configuration,
    ) onStartMatch,
  }) {
    return MaterialApp(
      home: HumanVsAiSetupScreen(
        onStartMatch: onStartMatch,
      ),
    );
  }

  testWidgets(
    'shows all AI difficulty choices',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          onStartMatch: (_) {},
        ),
      );

      expect(
        find.text('Random Easy'),
        findsOneWidget,
      );

      expect(
        find.text('Greedy Medium'),
        findsOneWidget,
      );

      expect(
        find.text('Heuristic Hard'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'uses Random Easy and Team 1 by default',
    (tester) async {
      MatchConfiguration?
          createdConfiguration;

      await tester.pumpWidget(
        buildScreen(
          onStartMatch:
              (configuration) {
            createdConfiguration =
                configuration;
          },
        ),
      );

      await tester.ensureVisible(
        find.byKey(
          const Key(
            'start-human-vs-ai-button',
          ),
        ),
      );

      await tester.tap(
        find.byKey(
          const Key(
            'start-human-vs-ai-button',
          ),
        ),
      );

      await tester.pump();

      expect(
        createdConfiguration,
        isNotNull,
      );

      expect(
        createdConfiguration
            ?.aiDifficulty,
        AiDifficulty.randomEasy,
      );

      expect(
        createdConfiguration
            ?.humanTeamId,
        0,
      );
    },
  );

  testWidgets(
  'allows Heuristic Hard selection',
  (tester) async {
    MatchConfiguration? createdConfiguration;

    await tester.pumpWidget(
      buildScreen(
        onStartMatch: (configuration) {
          createdConfiguration = configuration;
        },
      ),
    );

    final heuristicOption = find.byKey(
      const Key('difficulty-heuristicHard'),
    );

    await tester.ensureVisible(heuristicOption);
    await tester.pumpAndSettle();

    await tester.tap(heuristicOption);
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const Key('start-human-vs-ai-button'),
    );

    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(
      createdConfiguration,
      isNotNull,
    );

    expect(
      createdConfiguration!.aiDifficulty,
      AiDifficulty.heuristicHard,
    );
  },
);
  testWidgets(
    'shows the selected match summary',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          onStartMatch: (_) {},
        ),
      );

      expect(
        find.text(
          'You control: Team 1',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'AI controls: Team 2',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'AI difficulty: Random Easy',
        ),
        findsOneWidget,
      );
    },
  );
}