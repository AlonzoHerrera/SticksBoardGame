import 'package:flutter/material.dart';

import 'models/match_configuration.dart';
import 'widgets/game_screen.dart';
import 'widgets/human_vs_ai_setup_screen.dart';
import 'widgets/llm_vs_ai_experiment_screen.dart';
import 'widgets/llm_vs_ai_setup_screen.dart';
import 'widgets/main_menu_screen.dart';

void main() {
  runApp(
    const GameBApp(),
  );
}

class GameBApp extends StatelessWidget {
  const GameBApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title: 'Game B "AI-Rena"',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xFF1F5D89),
        scaffoldBackgroundColor:
            const Color(0xFFF5F2EA),
      ),
      home:
          const _MainNavigationScreen(),
    );
  }
}

class _MainNavigationScreen
    extends StatelessWidget {
  const _MainNavigationScreen();

  @override
  Widget build(BuildContext context) {
    return MainMenuScreen(
      onPlayInPerson: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) {
              return const GameScreen();
            },
          ),
        );
      },

      onPlayAgainstAi: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (
              setupContext,
            ) {
              return HumanVsAiSetupScreen(
                onStartMatch: (
                  configuration,
                ) {
                  _openConfiguredGame(
                    setupContext,
                    configuration,
                  );
                },
              );
            },
          ),
        );
      },

      onTestAiDifficulty: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (
              setupContext,
            ) {
              return LlmVsAiSetupScreen(
                onStartExperiment: (
                  configuration,
                ) {
                  Navigator.of(
                    setupContext,
                  ).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return LlmVsAiExperimentScreen(
                          configuration:
                              configuration,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openConfiguredGame(
    BuildContext context,
    MatchConfiguration configuration,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return GameScreen(
            configuration:
                configuration,
          );
        },
      ),
    );
  }
}