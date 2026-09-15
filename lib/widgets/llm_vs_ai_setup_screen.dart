import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../models/match_configuration.dart';

class LlmVsAiSetupScreen extends StatefulWidget {
  final ValueChanged<MatchConfiguration>
      onStartExperiment;

  const LlmVsAiSetupScreen({
    super.key,
    required this.onStartExperiment,
  });

  @override
  State<LlmVsAiSetupScreen> createState() {
    return _LlmVsAiSetupScreenState();
  }
}

class _LlmVsAiSetupScreenState
    extends State<LlmVsAiSetupScreen> {
  AiDifficulty _difficulty =
      AiDifficulty.randomEasy;

  int _gameCount = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LLM vs AI Setup',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose the AI opponent',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The LLM controls Team 1. '
                      'The selected AI controls Team 2.',
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<
                        AiDifficulty>(
                      initialValue: _difficulty,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Opponent difficulty',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: AiDifficulty.values
                          .map(
                            (difficulty) =>
                                DropdownMenuItem<
                                    AiDifficulty>(
                              value: difficulty,
                              child: Text(
                                difficulty
                                    .displayName,
                              ),
                            ),
                          )
                          .toList(
                            growable: false,
                          ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _difficulty = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Number of games: '
                      '$_gameCount',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),

                    Slider(
                      value:
                          _gameCount.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: '$_gameCount',
                      onChanged: (value) {
                        setState(() {
                          _gameCount =
                              value.round();
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                      ),
                      label: const Text(
                        'Run Experiment',
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

  void _start() {
    final configuration =
        MatchConfiguration.llmDifficultyTest(
      aiDifficulty: _difficulty,
      experimentGameCount: _gameCount,
      showExperimentGames: false,
    );

    widget.onStartExperiment(
      configuration,
    );
  }
}