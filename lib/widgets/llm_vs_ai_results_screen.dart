import 'package:flutter/material.dart';

import '../experiments/experiment_result.dart';

class LlmVsAiResultsScreen extends StatelessWidget {
  final ExperimentResult result;

  const LlmVsAiResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experiment Results')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.analytics_rounded, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'LLM vs ${_difficultyName(result.opponentDifficulty)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 28),
                    _ResultRow(
                      label: 'Games played',
                      value: '${result.gamesPlayed}',
                    ),
                    _ResultRow(label: 'LLM wins', value: '${result.llmWins}'),
                    _ResultRow(label: 'AI wins', value: '${result.aiWins}'),
                    _ResultRow(label: 'Draws', value: '${result.draws}'),
                    _ResultRow(
                      label: 'LLM win rate',
                      value: '${(result.llmWinRate * 100).toStringAsFixed(1)}%',
                    ),
                    _ResultRow(
                      label: 'AI win rate',
                      value: '${(result.aiWinRate * 100).toStringAsFixed(1)}%',
                    ),
                    _ResultRow(
                      label: 'Average actions',
                      value: result.averageActions.toStringAsFixed(1),
                    ),
                    _ResultRow(
                      label: 'Fallback moves',
                      value: '${result.fallbackMoves}',
                    ),
                    _ResultRow(
                      label: 'Run time',
                      value: _formatDuration(result.duration),
                    ),
                    if (result.fallbackMoves == 0) ...[
                      const SizedBox(height: 24),
                      const _StatusMessage(
                        icon: Icons.check_circle_rounded,
                        title: 'OpenAI responses succeeded',
                        message:
                            'No fallback moves were recorded during this experiment.',
                      ),
                    ],
                    if (result.fallbackMoves > 0) ...[
                      const SizedBox(height: 24),
                      _ErrorMessage(
                        fallbackMoves: result.fallbackMoves,
                        error: result.lastLlmError,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Return to Setup'),
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

  String _difficultyName(dynamic difficulty) {
    final text = difficulty.toString();

    if (text.contains('.')) {
      final rawName = text.split('.').last;

      switch (rawName) {
        case 'randomEasy':
          return 'Random Easy';
        case 'greedyMedium':
          return 'Greedy Medium';
        case 'heuristicHard':
          return 'Heuristic Hard';
        default:
          return rawName;
      }
    }

    return text;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);

      return '$minutes min ${seconds.toString().padLeft(2, '0')} s';
    }

    if (duration.inSeconds >= 1) {
      final remainingMilliseconds = duration.inMilliseconds.remainder(1000);

      return '${duration.inSeconds}.'
          '${remainingMilliseconds.toString().padLeft(3, '0')} s';
    }

    return '${duration.inMilliseconds} ms';
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final int fallbackMoves;
  final String? error;

  const _ErrorMessage({required this.fallbackMoves, required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final displayedError = error == null || error!.trim().isEmpty
        ? 'No detailed error was recorded. Confirm that the '
              'experiment runner uses performNextActionAsync().'
        : error!.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LLM fallback detected',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$fallbackMoves move${fallbackMoves == 1 ? '' : 's'} '
            'used Greedy Medium instead of the LLM.',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          Text(
            'Most recent error:',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            displayedError,
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
