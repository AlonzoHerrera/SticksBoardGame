import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../models/match_configuration.dart';

class HumanVsAiSetupScreen extends StatefulWidget {
  final void Function(
    MatchConfiguration configuration,
  ) onStartMatch;

  const HumanVsAiSetupScreen({
    super.key,
    required this.onStartMatch,
  });

  @override
  State<HumanVsAiSetupScreen> createState() {
    return _HumanVsAiSetupScreenState();
  }
}

class _HumanVsAiSetupScreenState
    extends State<HumanVsAiSetupScreen> {
  AiDifficulty _selectedDifficulty =
      AiDifficulty.randomEasy;

  int _selectedHumanTeamId = 0;

  void _startMatch() {
    final configuration =
        MatchConfiguration.humanVsAi(
      aiDifficulty: _selectedDifficulty,
      humanTeamId: _selectedHumanTeamId,
    );

    widget.onStartMatch(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F2EA),
      appBar: AppBar(
        title: const Text(
          'Play Against AI',
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
              maxWidth: 650,
            ),
            child: Card(
              elevation: 3,
              color:
                  const Color(0xFFFFFBF2),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    const Icon(
                      Icons.smart_toy_rounded,
                      size: 72,
                      color:
                          Color(0xFF1F5D89),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Text(
                      'Human vs AI Setup',
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
                      height: 8,
                    ),
                    const Text(
                      'Choose the AI difficulty and the team you want to control.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(0xFF6A665D),
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Text(
                      'AI Difficulty',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    for (
                      final difficulty
                          in AiDifficulty
                              .values
                    )
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 12,
                        ),
                        child:
                            _DifficultyOption(
                          difficulty:
                              difficulty,
                          selected:
                              _selectedDifficulty ==
                                  difficulty,
                          onSelected: () {
                            setState(() {
                              _selectedDifficulty =
                                  difficulty;
                            });
                          },
                        ),
                      ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      'Choose Your Team',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SegmentedButton<int>(
                      key: const Key(
                        'human-team-selector',
                      ),
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          icon: Icon(
                            Icons.person,
                          ),
                          label: Text(
                            'Team 1',
                          ),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: Icon(
                            Icons.person,
                          ),
                          label: Text(
                            'Team 2',
                          ),
                        ),
                      ],
                      selected: {
                        _selectedHumanTeamId,
                      },
                      onSelectionChanged:
                          (selection) {
                        setState(() {
                          _selectedHumanTeamId =
                              selection.first;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _MatchSummary(
                      difficulty:
                          _selectedDifficulty,
                      humanTeamId:
                          _selectedHumanTeamId,
                    ),
                    const SizedBox(
                      height: 26,
                    ),
                    SizedBox(
                      height: 52,
                      child:
                          FilledButton.icon(
                        key: const Key(
                          'start-human-vs-ai-button',
                        ),
                        onPressed:
                            _startMatch,
                        icon: const Icon(
                          Icons.play_arrow,
                        ),
                        label: const Text(
                          'Start Match',
                        ),
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
}

class _DifficultyOption
    extends StatelessWidget {
  final AiDifficulty difficulty;
  final bool selected;
  final VoidCallback onSelected;

  const _DifficultyOption({
    required this.difficulty,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(
        'difficulty-${difficulty.name}',
      ),
      onTap: onSelected,
      borderRadius:
          BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(
                  0xFFE3EEF5,
                )
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(
                    0xFF1F5D89,
                  )
                : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons
                      .radio_button_checked
                  : Icons
                      .radio_button_unchecked,
              color: selected
                  ? const Color(
                      0xFF1F5D89,
                    )
                  : const Color(
                      0xFF6A665D,
                    ),
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    difficulty
                        .displayName,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    difficulty
                        .description,
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF6A665D,
                      ),
                      height: 1.35,
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

class _MatchSummary
    extends StatelessWidget {
  final AiDifficulty difficulty;
  final int humanTeamId;

  const _MatchSummary({
    required this.difficulty,
    required this.humanTeamId,
  });

  @override
  Widget build(BuildContext context) {
    final aiTeamId =
        humanTeamId == 0 ? 1 : 0;

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF2EFE7),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Summary',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'You control: Team ${humanTeamId + 1}',
          ),
          Text(
            'AI controls: Team ${aiTeamId + 1}',
          ),
          Text(
            'AI difficulty: ${difficulty.displayName}',
          ),
        ],
      ),
    );
  }
}