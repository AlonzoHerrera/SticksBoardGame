import 'package:flutter/material.dart';

import '../experiments/llm_vs_ai_runner.dart';
import '../models/match_configuration.dart';
import 'llm_vs_ai_results_screen.dart';

class LlmVsAiExperimentScreen
    extends StatefulWidget {
  final MatchConfiguration configuration;

  const LlmVsAiExperimentScreen({
    super.key,
    required this.configuration,
  });

  @override
  State<LlmVsAiExperimentScreen>
      createState() {
    return _LlmVsAiExperimentScreenState();
  }
}

class _LlmVsAiExperimentScreenState
    extends State<LlmVsAiExperimentScreen> {
  final LlmVsAiRunner _runner =
      const LlmVsAiRunner();

  int _completed = 0;
  int _llmWins = 0;
  int _aiWins = 0;
  int _draws = 0;

  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        _run();
      },
    );
  }

  Future<void> _run() async {
    try {
      final result = await _runner.run(
        configuration:
            widget.configuration,
        onProgress: ({
          required int completedGames,
          required int totalGames,
          required int llmWins,
          required int aiWins,
          required int draws,
        }) {
          if (!mounted) {
            return;
          }

          setState(() {
            _completed = completedGames;
            _llmWins = llmWins;
            _aiWins = aiWins;
            _draws = draws;
          });
        },
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) {
            return LlmVsAiResultsScreen(
              result: result,
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        widget.configuration.experimentGameCount;

    final progress = total == 0
        ? 0.0
        : _completed / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.configuration.title,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _error == null
                          ? 'Running experiment...'
                          : 'Experiment stopped',
                      textAlign:
                          TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 24),

                    if (_error == null) ...[
                      LinearProgressIndicator(
                        value: progress,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        '$_completed of $total '
                        'games complete',
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      _StatRow(
                        label: 'LLM wins',
                        value: _llmWins,
                      ),
                      _StatRow(
                        label: 'AI wins',
                        value: _aiWins,
                      ),
                      _StatRow(
                        label: 'Draws',
                        value: _draws,
                      ),
                    ] else ...[
                      Text(
                        _error!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop();
                        },
                        child: const Text(
                          'Return',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value'),
        ],
      ),
    );
  }
}