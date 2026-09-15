import 'package:flutter/material.dart';

import '../models/game_mode.dart';

class MainMenuScreen extends StatelessWidget {
  final VoidCallback onPlayInPerson;
  final VoidCallback onPlayAgainstAi;
  final VoidCallback onTestAiDifficulty;

  const MainMenuScreen({
    super.key,
    required this.onPlayInPerson,
    required this.onPlayAgainstAi,
    required this.onTestAiDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 760,
              ),
              child: Column(
                children: [
                  const _GameHeader(),
                  const SizedBox(height: 36),
                  _ModeCard(
                    key: const Key(
                      'play-in-person-card',
                    ),
                    icon: Icons.groups_rounded,
                    mode: GameMode.localMultiplayer,
                    buttonText: 'Play In Person',
                    onPressed: onPlayInPerson,
                  ),
                  const SizedBox(height: 18),
                  _ModeCard(
                    key: const Key(
                      'play-against-ai-card',
                    ),
                    icon:
                        Icons.smart_toy_rounded,
                    mode: GameMode.humanVsAi,
                    buttonText:
                        'Play Against AI',
                    onPressed: onPlayAgainstAi,
                  ),
                  const SizedBox(height: 18),
                  _ModeCard(
                    key: const Key(
                      'test-ai-difficulty-card',
                    ),
                    icon:
                        Icons.analytics_rounded,
                    mode:
                        GameMode.llmDifficultyTest,
                    buttonText:
                        'Test AI Difficulty',
                    onPressed:
                        onTestAiDifficulty,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Game B AI Capstone',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6A665D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme =
        Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: const Color(0xFF1F5D89),
            borderRadius:
                BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.casino_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Game B "AI-Rena"',
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF25313A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to play',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium
              ?.copyWith(
            color: const Color(0xFF6A665D),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final GameMode mode;
  final String buttonText;
  final VoidCallback onPressed;

  const _ModeCard({
    super.key,
    required this.icon,
    required this.mode,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme =
        Theme.of(context).textTheme;

    return Card(
      elevation: 3,
      color: const Color(0xFFFFFBF2),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE3EEF5),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 34,
                color:
                    const Color(0xFF1F5D89),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style:
                        textTheme.titleLarge
                            ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                      color: const Color(
                        0xFF25313A,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    mode.description,
                    style:
                        textTheme.bodyMedium
                            ?.copyWith(
                      height: 1.4,
                      color: const Color(
                        0xFF6A665D,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child:
                        FilledButton.icon(
                      key: Key(
                        '${mode.name}-button',
                      ),
                      onPressed: onPressed,
                      icon: const Icon(
                        Icons.arrow_forward,
                      ),
                      label: Text(
                        buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}