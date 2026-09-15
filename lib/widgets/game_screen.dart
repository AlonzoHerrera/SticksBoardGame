import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/ai_strategy.dart';
import '../ai/ai_strategy_factory.dart';
import '../ai/ai_turn_controller.dart';
import '../game/board.dart';
import '../game/game.dart';
import '../game/game_engine.dart';
import '../game/game_rule_exception.dart';
import '../game/game_state.dart';
import '../game/piece.dart';
import '../models/match_configuration.dart';
import 'board_view.dart';

class GameScreen extends StatefulWidget {
  final MatchConfiguration? configuration;

  const GameScreen({
    super.key,
    this.configuration,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Game _engine;

  AiStrategy? _aiStrategy;

  final AiTurnController _aiTurnController =
      const AiTurnController();

  bool _aiActionInProgress = false;

  String? _finishAnnouncement;
  bool _finishAnnouncementIsWinner = false;
  Timer? _finishAnnouncementTimer;

  String _message = 'Press Throw Sticks to begin.';

  Piece? _selectedSpecialPiece;
  Piece? _selectedMovePiece;

  List<int> _selectedDestinations = [];

  @override
  void initState() {
    super.initState();

    final configuration = widget.configuration;

    _engine = Game(
      playerCount: configuration?.playerCount ?? 4,
    );

    if (configuration?.isHumanVsAi == true) {
      _aiStrategy = const AiStrategyFactory().create(
        difficulty: configuration!.aiDifficulty!,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAiTurn();
    });
  }


  int _completedPiecesForTeam(int teamId) {
    return _engine.players
        .where((player) => player.teamId == teamId)
        .expand((player) => player.pieces)
        .where((piece) => piece.isCompleted)
        .length;
  }

  int _totalPiecesForTeam(int teamId) {
    return _engine.players
        .where((player) => player.teamId == teamId)
        .expand((player) => player.pieces)
        .length;
  }

  List<int> _completedPieceCounts() {
    return <int>[
      _completedPiecesForTeam(0),
      _completedPiecesForTeam(1),
    ];
  }

  void _checkForFinishAnnouncement(
    List<int> completedBefore,
  ) {
    final winner = _engine.winningTeam;

    if (winner != null) {
      _showFinishAnnouncement(
        '🏆 ${winner.name.toUpperCase()} WINS THE GAME!\nCongratulations!',
        isWinner: true,
      );
      return;
    }

    for (var teamId = 0; teamId < 2; teamId++) {
      final completedAfter = _completedPiecesForTeam(teamId);

      if (completedAfter <= completedBefore[teamId]) {
        continue;
      }

      final totalPieces = _totalPiecesForTeam(teamId);
      final remaining = totalPieces - completedAfter;
      final crossedCount = completedAfter - completedBefore[teamId];
      final teamName = 'Team ${teamId + 1}';

      String announcement;

      if (remaining == 1) {
        announcement =
            '🔥 Almost there, $teamName!\nJust 1 more piece to win!';
      } else if (remaining == 2) {
        announcement =
            '🎉 Great move, $teamName!\nOnly 2 more pieces to win!';
      } else {
        final pieceText = crossedCount == 1 ? 'Piece' : 'Pieces';
        announcement =
            '🏁 $pieceText crossed the finish for $teamName!\n$remaining more pieces to win!';
      }

      _showFinishAnnouncement(announcement);
      return;
    }
  }

  void _showFinishAnnouncement(
    String announcement, {
    bool isWinner = false,
  }) {
    _finishAnnouncementTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _finishAnnouncement = announcement;
      _finishAnnouncementIsWinner = isWinner;
    });

    if (!isWinner) {
      _finishAnnouncementTimer = Timer(
        const Duration(seconds: 5),
        () {
          if (!mounted) {
            return;
          }

          setState(() {
            _finishAnnouncement = null;
            _finishAnnouncementIsWinner = false;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _finishAnnouncementTimer?.cancel();
    super.dispose();
  }

  bool get _isHumanVsAi {
    return widget.configuration?.isHumanVsAi == true;
  }

  bool get _isAiTurn {
    final configuration = widget.configuration;

    if (!_isHumanVsAi ||
        configuration == null ||
        _engine.state == GameState.gameOver) {
      return false;
    }

    return _engine.currentTeam?.id == configuration.aiTeamId;
  }

  void _scheduleAiTurn() {
    if (!mounted ||
        !_isAiTurn ||
        _aiStrategy == null ||
        _aiActionInProgress) {
      return;
    }

    _aiActionInProgress = true;

    Future<void>.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) {
          return;
        }

        try {
          final completedBefore = _completedPieceCounts();

          final result = _aiTurnController.performNextAction(
            game: _engine,
            strategy: _aiStrategy!,
          );

          setState(() {
            _selectedSpecialPiece = null;
            _selectedMovePiece = null;
            _selectedDestinations = [];
            _message = result.message;
          });

          _checkForFinishAnnouncement(completedBefore);
        } on GameRuleException catch (e) {
          setState(() {
            _message = 'AI error: ${e.message}';
          });
        } catch (e) {
          setState(() {
            _message = 'AI error: $e';
          });
        } finally {
          _aiActionInProgress = false;
        }

        if (mounted && _isAiTurn) {
          _scheduleAiTurn();
        }
      },
    );
  }

  void _throwSticks() {
    if (_isAiTurn ||
        _aiActionInProgress ||
        _engine.state != GameState.waitingForThrow) {
      return;
    }

    try {
      final result = _engine.throwSticks();

      setState(() {
        _selectedSpecialPiece = null;
        _selectedMovePiece = null;
        _selectedDestinations = [];

        if (_engine.specialMovePending) {
          _message =
              'X-stick special move! Choose one of your pieces, then choose an opposing-team piece to capture.';
        } else if (_engine.lastThrowResult?.specialMove == true) {
          _message =
              'X-stick special move was thrown, but no opposing-team pieces are on the board. The same player throws again.';
        } else {
          _message =
              '${_engine.currentPlayer?.name} threw a $result.';
        }
      });

      _scheduleAiTurn();
    } on GameRuleException catch (e) {
      setState(() {
        _message = e.message;
      });
    }
  }

  void _movePiece(Piece piece) {
    if (_isAiTurn || _aiActionInProgress) {
      return;
    }

    if (_engine.state == GameState.waitingForSpecialMove) {
      final currentPlayer = _engine.currentPlayer;

      if (currentPlayer?.id == piece.ownerId) {
        setState(() {
          _selectedSpecialPiece = piece;
          _selectedMovePiece = null;
          _selectedDestinations = [];

          _message =
              'Selected Piece ${piece.id + 1}. Now choose an opposing-team piece to capture.';
        });
      }

      return;
    }

    if (_engine.state != GameState.waitingForMove) {
      return;
    }

    final moveValue = _engine.pendingMoveValue;

    if (moveValue == null) {
      return;
    }

    final destinations = _engine.legalDestinationsForPiece(
      piece,
      moveValue,
    );

    if (destinations.isEmpty) {
      return;
    }

    if (destinations.length > 1) {
      setState(() {
        _selectedMovePiece = piece;
        _selectedDestinations = destinations;

        _message =
            'Piece ${piece.id + 1} has more than one route. Choose a destination.';
      });

      return;
    }

    _movePieceToDestination(
      piece,
      destinations.first,
    );
  }

  void _movePieceToDestination(
    Piece piece,
    int destination,
  ) {
    if (_isAiTurn || _aiActionInProgress) {
      return;
    }

    final moveValue = _engine.pendingMoveValue;

    if (moveValue == null) {
      return;
    }

    try {
      final completedBefore = _completedPieceCounts();

      _engine.movePieceToStation(
        piece,
        moveValue,
        destination,
      );

      setState(() {
        _selectedMovePiece = null;
        _selectedDestinations = [];

        final winner = _engine.winningTeam;

        if (winner != null) {
          _message = '${winner.name} wins the game!';
        } else if (destination == Board.finishProgress) {
          _message =
              'Piece ${piece.id + 1} crossed the finish.';
        } else {
          _message =
              'Moved Piece ${piece.id + 1} to station $destination.';
        }
      });

      _checkForFinishAnnouncement(completedBefore);
      _scheduleAiTurn();
    } on GameRuleException catch (e) {
      setState(() {
        _message = e.message;
      });
    }
  }

  void _specialCapture(Piece targetPiece) {
    if (_isAiTurn || _aiActionInProgress) {
      return;
    }

    final selectedPiece = _selectedSpecialPiece;

    if (selectedPiece == null) {
      setState(() {
        _message = 'Choose one of your pieces first.';
      });

      return;
    }

    try {
      _engine.specialCapture(
        movingPiece: selectedPiece,
        targetPiece: targetPiece,
      );

      setState(() {
        _selectedSpecialPiece = null;
        _selectedMovePiece = null;
        _selectedDestinations = [];

        final winner = _engine.winningTeam;

        if (winner != null) {
          _message = '${winner.name} wins the game!';
        } else {
          _message =
              'X-stick capture completed. The same player gets another throw.';
        }
      });

      _scheduleAiTurn();
    } on GameRuleException catch (e) {
      setState(() {
        _message = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canThrow =
        _engine.state == GameState.waitingForThrow &&
        !_isAiTurn &&
        !_aiActionInProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      appBar: AppBar(
        title: Text(
          widget.configuration?.title ?? 'Play In Person',
        ),
        backgroundColor: const Color(0xFFFFFBF2),
      ),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: _SidePanel(
                engine: _engine,
                message: _aiActionInProgress
                    ? '${_engine.currentPlayer?.name} is thinking...'
                    : _message,
                canThrow: canThrow,
                selectedSpecialPiece:
                    _selectedSpecialPiece,
                selectedMovePiece:
                    _selectedMovePiece,
                selectedDestinations:
                    _selectedDestinations,
                onThrow: _throwSticks,
                onMovePiece: _movePiece,
                onDestinationSelected:
                    _movePieceToDestination,
                onSpecialCapture:
                    _specialCapture,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _finishAnnouncement == null
                        ? const SizedBox.shrink()
                        : _FinishAnnouncementBanner(
                            key: ValueKey(_finishAnnouncement),
                            message: _finishAnnouncement!,
                            isWinner: _finishAnnouncementIsWinner,
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Card(
                        elevation: 4,
                        color: const Color(0xFFFFF8E8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: BoardView(
                            engine: _engine,
                          ),
                        ),
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

class _FinishAnnouncementBanner extends StatelessWidget {
  final String message;
  final bool isWinner;

  const _FinishAnnouncementBanner({
    super.key,
    required this.message,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: isWinner
              ? const Color(0xFFFFD54F)
              : const Color(0xFF1E6F5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isWinner
                ? const Color(0xFF8D6E00)
                : const Color(0xFF0E473A),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWinner
                ? const Color(0xFF3E2F00)
                : Colors.white,
            fontSize: isWinner ? 30 : 25,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final GameEngine engine;
  final String message;
  final bool canThrow;

  final Piece? selectedSpecialPiece;
  final Piece? selectedMovePiece;

  final List<int> selectedDestinations;

  final VoidCallback onThrow;
  final void Function(Piece piece) onMovePiece;

  final void Function(
    Piece piece,
    int destination,
  ) onDestinationSelected;

  final void Function(
    Piece targetPiece,
  ) onSpecialCapture;

  const _SidePanel({
    required this.engine,
    required this.message,
    required this.canThrow,
    required this.selectedSpecialPiece,
    required this.selectedMovePiece,
    required this.selectedDestinations,
    required this.onThrow,
    required this.onMovePiece,
    required this.onDestinationSelected,
    required this.onSpecialCapture,
  });

  @override
  Widget build(BuildContext context) {
    final currentPlayer = engine.currentPlayer;
    final currentTeam = engine.currentTeam;
    final pendingMove = engine.pendingMoveValue;
    final winningTeam = engine.winningTeam;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ListView(
            children: [
              const Center(
                child: Text(
                  'Game B',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _InfoBox(
                currentPlayer:
                    currentPlayer?.name ?? 'None',
                currentTeam:
                    currentTeam?.name ?? 'None',
                state: _stateText(engine.state),
                throwValue:
                    pendingMove?.toString() ?? '-',
                extraTurn:
                    engine.extraTurnEarned
                        ? 'Yes'
                        : 'No',
                winner:
                    winningTeam?.name ?? '-',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed:
                      canThrow ? onThrow : null,
                  icon: const Icon(Icons.casino),
                  label:
                      const Text('Throw Sticks'),
                ),
              ),
              const SizedBox(height: 12),
              _LastThrowBox(
                engine: engine,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final player in engine.players)
                _PlayerPieceGroup(
                  playerName:
                      player == currentPlayer
                          ? '${player.name} - Team ${player.teamId + 1} (Current)'
                          : '${player.name} - Team ${player.teamId + 1}',
                  playerId: player.id,
                  pieces: player.pieces,
                  engine: engine,
                  selectedSpecialPiece:
                      selectedSpecialPiece,
                  selectedMovePiece:
                      selectedMovePiece,
                  onMovePiece: onMovePiece,
                ),
              if (selectedMovePiece != null &&
                  selectedDestinations.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Choose Destination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      selectedDestinations.map(
                    (destination) {
                      final buttonText =
                          destination ==
                                  Board.finishProgress
                              ? 'Cross Finish'
                              : 'Go to $destination';

                      return FilledButton(
                        onPressed: () {
                          onDestinationSelected(
                            selectedMovePiece!,
                            destination,
                          );
                        },
                        child: Text(buttonText),
                      );
                    },
                  ).toList(),
                ),
              ],
              if (engine.specialMovePending) ...[
                const Divider(),
                const Text(
                  'X-Stick Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _SpecialTargets(
                  engine: engine,
                  onSpecialCapture:
                      onSpecialCapture,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _stateText(GameState state) {
    switch (state) {
      case GameState.waitingForThrow:
        return 'Waiting for Throw';

      case GameState.waitingForMove:
        return 'Waiting for Move';

      case GameState.waitingForSpecialMove:
        return 'Waiting for Special Move';

      case GameState.gameOver:
        return 'Game Over';
    }
  }
}

class _InfoBox extends StatelessWidget {
  final String currentPlayer;
  final String currentTeam;
  final String state;
  final String throwValue;
  final String extraTurn;
  final String winner;

  const _InfoBox({
    required this.currentPlayer,
    required this.currentTeam,
    required this.state,
    required this.throwValue,
    required this.extraTurn,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black12,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _InfoLine(
            label: 'Current Player',
            value: currentPlayer,
          ),
          _InfoLine(
            label: 'Current Team',
            value: currentTeam,
          ),
          _InfoLine(
            label: 'State',
            value: state,
          ),
          _InfoLine(
            label: 'Current Throw',
            value: throwValue,
          ),
          _InfoLine(
            label: 'Extra Turn',
            value: extraTurn,
          ),
          _InfoLine(
            label: 'Winner',
            value: winner,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
          ),
          children: [
            TextSpan(text: '$label\n'),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastThrowBox extends StatelessWidget {
  final GameEngine engine;

  const _LastThrowBox({
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final throwResult =
        engine.lastThrowResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black12,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Throw',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children:
                List.generate(4, (index) {
              final isLight =
                  throwResult
                          ?.lightSides[index] ??
                      false;

              final isXStick = index == 0;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 14,
                ),
                child: _StickView(
                  isLight: isLight,
                  isXStick: isXStick,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _throwText(throwResult),
            style: TextStyle(
              color:
                  throwResult?.specialMove ==
                          true
                      ? Colors.green
                      : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const Text(
            'How to Read',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '• Light side = 1',
          ),
          const Text(
            '• Dark side = 0',
          ),
          const Text(
            '• X light side alone = Special Move',
          ),
          const Text(
            '• All dark = 5 spaces',
          ),
          const Text(
            '• All light = 4 spaces and another throw',
          ),
        ],
      ),
    );
  }

  String _throwText(dynamic throwResult) {
    if (throwResult == null) {
      return 'No throw yet.';
    }

    if (throwResult.specialMove) {
      return 'Total: 1 (X-Stick Special Move)';
    }

    if (throwResult.allDark) {
      return 'Total: 0 → Move 5 spaces';
    }

    if (throwResult.lightCount == 4) {
      return 'Total: 4 → Move 4 spaces and earn another throw';
    }

    return 'Total: ${throwResult.lightCount} → Move ${throwResult.moveValue} spaces';
  }
}

class _StickView extends StatelessWidget {
  final bool isLight;
  final bool isXStick;

  const _StickView({
    required this.isLight,
    required this.isXStick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFFFF8EA)
            : Colors.black87,
        borderRadius:
            BorderRadius.circular(4),
        border: Border.all(
          color: isLight
              ? Colors.brown.shade200
              : Colors.black,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            offset: Offset(1, 2),
            color: Colors.black26,
          ),
        ],
      ),
      child: isXStick && isLight
          ? const Text(
              'X',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class _PlayerPieceGroup extends StatelessWidget {
  final String playerName;
  final int playerId;
  final List<Piece> pieces;
  final GameEngine engine;

  final Piece? selectedSpecialPiece;
  final Piece? selectedMovePiece;

  final void Function(Piece piece)
      onMovePiece;

  const _PlayerPieceGroup({
    required this.playerName,
    required this.playerId,
    required this.pieces,
    required this.engine,
    required this.selectedSpecialPiece,
    required this.selectedMovePiece,
    required this.onMovePiece,
  });

  @override
  Widget build(BuildContext context) {
    final moveValue =
        engine.pendingMoveValue;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            playerName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  _pieceColor(playerId),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pieces.map((piece) {
              final normalEnabled =
                  engine.currentPlayer?.id ==
                          piece.ownerId &&
                      engine.state ==
                          GameState.waitingForMove &&
                      moveValue != null &&
                      engine.canMovePiece(
                        piece,
                        moveValue,
                      );

              final specialEnabled =
                  engine.currentPlayer?.id ==
                          piece.ownerId &&
                      engine.state ==
                          GameState
                              .waitingForSpecialMove;

              final selectedSpecial =
                  selectedSpecialPiece == piece;

              final selectedMove =
                  selectedMovePiece == piece;

              final pieceLabel =
                  piece.isCompleted
                      ? 'F'
                      : '${piece.id + 1}';

              return ElevatedButton(
                onPressed:
                    normalEnabled ||
                            specialEnabled
                        ? () =>
                            onMovePiece(piece)
                        : null,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedSpecial ||
                              selectedMove
                          ? Colors.purple
                          : _pieceColor(
                              playerId,
                            ),
                  foregroundColor:
                      Colors.white,
                  shape:
                      const CircleBorder(),
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                ),
                child: Text(pieceLabel),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _pieceColor(int ownerId) {
    switch (ownerId) {
      case 0:
        return Colors.red;

      case 1:
        return Colors.blue;

      case 2:
        return Colors.green;

      case 3:
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }
}

class _SpecialTargets extends StatelessWidget {
  final GameEngine engine;

  final void Function(
    Piece targetPiece,
  ) onSpecialCapture;

  const _SpecialTargets({
    required this.engine,
    required this.onSpecialCapture,
  });

  @override
  Widget build(BuildContext context) {
    final currentPlayer =
        engine.currentPlayer;

    if (currentPlayer == null) {
      return const Text(
        'No current player.',
      );
    }

    final targets =
        engine.legalSpecialTargets();

    if (targets.isEmpty) {
      return const Text(
        'No opposing-team pieces are currently on the board.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: targets.map((piece) {
        return OutlinedButton(
          onPressed: () {
            onSpecialCapture(piece);
          },
          child: Text(
            'P${piece.ownerId + 1}-${piece.id + 1} @ ${piece.stationIndex}',
          ),
        );
      }).toList(),
    );
  }
}