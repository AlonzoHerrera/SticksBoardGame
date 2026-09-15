import 'package:flutter/material.dart';

import '../models/game_mode.dart';

class ModeSetupPlaceholderScreen
    extends StatelessWidget {
  final GameMode gameMode;

  const ModeSetupPlaceholderScreen({
    super.key,
    required this.gameMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F2EA),
      appBar: AppBar(
        title: Text(
          gameMode.displayName,
        ),
        backgroundColor:
            const Color(0xFFFFFBF2),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 560,
            ),
            child: Card(
              elevation: 3,
              color:
                  const Color(0xFFFFFBF2),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  32,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForMode(),
                      size: 74,
                      color: const Color(
                        0xFF1F5D89,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Text(
                      gameMode.displayName,
                      textAlign:
                          TextAlign.center,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      gameMode.description,
                      textAlign:
                          TextAlign.center,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Text(
                      _nextStepMessage(),
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color:
                            Color(0xFF6A665D),
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                      ),
                      label: const Text(
                        'Back to Main Menu',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForMode() {
    switch (gameMode) {
      case GameMode.localMultiplayer:
        return Icons.groups_rounded;

      case GameMode.humanVsAi:
        return Icons.smart_toy_rounded;

      case GameMode.llmDifficultyTest:
        return Icons.analytics_rounded;
    }
  }

  String _nextStepMessage() {
    switch (gameMode) {
      case GameMode.localMultiplayer:
        return 'The local player setup will allow two, three, or four players.';

      case GameMode.humanVsAi:
        return 'The next setup screen will allow the user to select Random Easy, Greedy Medium, or Heuristic Hard.';

      case GameMode.llmDifficultyTest:
        return 'The next setup screen will allow the LLM to play multiple games against a selected AI difficulty.';
    }
  }
}