import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework1game/widgets/main_menu_screen.dart';

void main() {
  Widget buildMenu({
    VoidCallback? onPlayInPerson,
    VoidCallback? onPlayAgainstAi,
    VoidCallback? onTestAiDifficulty,
  }) {
    return MaterialApp(
      home: MainMenuScreen(
        onPlayInPerson: onPlayInPerson ?? () {},
        onPlayAgainstAi: onPlayAgainstAi ?? () {},
        onTestAiDifficulty: onTestAiDifficulty ?? () {},
      ),
    );
  }

  group('MainMenuScreen display', () {
    testWidgets(
      'shows the game title',
      (tester) async {
        await tester.pumpWidget(
          buildMenu(),
        );

        expect(
          find.text('Game B "AI-Rena"'),
          findsOneWidget,
        );

        expect(
          find.text(
            'Choose how you want to play',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows all three menu options',
      (tester) async {
        await tester.pumpWidget(
          buildMenu(),
        );

        expect(
          find.text('Play In Person'),
          findsNWidgets(2),
        );

        expect(
          find.text('Play Against AI'),
          findsNWidgets(2),
        );

        expect(
          find.text('Test AI Difficulty'),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'shows a description for each mode',
      (tester) async {
        await tester.pumpWidget(
          buildMenu(),
        );

        expect(
          find.text(
            'Two to four people play together on the same device.',
          ),
          findsOneWidget,
        );

        expect(
          find.text(
            'A person plays against a selected AI difficulty.',
          ),
          findsOneWidget,
        );

        expect(
          find.text(
            'An LLM opponent plays against a selected AI difficulty.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('MainMenuScreen actions', () {
    testWidgets(
      'calls Play In Person action',
      (tester) async {
        var wasPressed = false;

        await tester.pumpWidget(
          buildMenu(
            onPlayInPerson: () {
              wasPressed = true;
            },
          ),
        );

        await tester.tap(
          find.byKey(
            const Key(
              'localMultiplayer-button',
            ),
          ),
        );

        await tester.pump();

        expect(
          wasPressed,
          isTrue,
        );
      },
    );

    testWidgets(
      'calls Play Against AI action',
      (tester) async {
        var wasPressed = false;

        await tester.pumpWidget(
          buildMenu(
            onPlayAgainstAi: () {
              wasPressed = true;
            },
          ),
        );

        await tester.tap(
          find.byKey(
            const Key(
              'humanVsAi-button',
            ),
          ),
        );

        await tester.pump();

        expect(
          wasPressed,
          isTrue,
        );
      },
    );

    testWidgets(
      'calls Test AI Difficulty action',
      (tester) async {
        var wasPressed = false;

        await tester.pumpWidget(
          buildMenu(
            onTestAiDifficulty: () {
              wasPressed = true;
            },
          ),
        );

        await tester.ensureVisible(
          find.byKey(
            const Key(
              'llmDifficultyTest-button',
            ),
          ),
        );

        await tester.tap(
          find.byKey(
            const Key(
              'llmDifficultyTest-button',
            ),
          ),
        );

        await tester.pump();

        expect(
          wasPressed,
          isTrue,
        );
      },
    );
  });
}