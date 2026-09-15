import 'dart:math';

import 'board.dart';
import 'game_engine.dart';
import 'game_rule_exception.dart';
import 'game_state.dart';
import 'piece.dart';
import 'player.dart';
import 'team.dart';
import 'throw_result.dart';

class Game implements GameEngine {
  static const int defaultPlayerCount = 4;
  static const int teamCount = 2;
  static const int piecesPerTeam = 4;

  @override
  final Board board;

  @override
  final List<Player> players;

  @override
  late final List<Team> teams;

  final Random _random;

  GameState _state = GameState.waitingForThrow;
  int _currentPlayerIndex = 0;
  int? _pendingMoveValue;
  bool _extraTurnEarned = false;
  ThrowResult? _lastThrowResult;
  Team? _winningTeam;

  Game({
    Board? board,
    List<Player>? players,
    int playerCount = defaultPlayerCount,
    Random? random,
  }) : board = board ?? Board(),
       players = players ?? _createDefaultPlayers(playerCount),
       _random = random ?? Random() {
    teams = _createTeams(this.players);
    validateInvariants();
  }

  static List<Player> _createDefaultPlayers(int playerCount) {
    switch (playerCount) {
      case 2:
        return [
          Player(id: 0, name: 'Player 1', teamId: 0, numberOfPieces: 4),
          Player(id: 1, name: 'Player 2', teamId: 1, numberOfPieces: 4),
        ];

      case 3:
        return [
          Player(id: 0, name: 'Player 1', teamId: 0, numberOfPieces: 2),
          Player(id: 1, name: 'Player 2', teamId: 1, numberOfPieces: 4),
          Player(id: 2, name: 'Player 3', teamId: 0, numberOfPieces: 2),
        ];

      case 4:
        return [
          Player(id: 0, name: 'Player 1', teamId: 0, numberOfPieces: 2),
          Player(id: 1, name: 'Player 2', teamId: 1, numberOfPieces: 2),
          Player(id: 2, name: 'Player 3', teamId: 0, numberOfPieces: 2),
          Player(id: 3, name: 'Player 4', teamId: 1, numberOfPieces: 2),
        ];

      default:
        throw GameRuleException('Game B supports between 2 and 4 players.');
    }
  }

  static List<Team> _createTeams(List<Player> players) {
    return [
      Team(
        id: 0,
        name: 'Team 1',
        playerIds: players
            .where((player) => player.teamId == 0)
            .map((player) => player.id)
            .toList(growable: false),
      ),
      Team(
        id: 1,
        name: 'Team 2',
        playerIds: players
            .where((player) => player.teamId == 1)
            .map((player) => player.id)
            .toList(growable: false),
      ),
    ];
  }

  @override
  GameState get state => _state;

  @override
  Player? get currentPlayer {
    if (players.isEmpty) {
      return null;
    }

    return players[_currentPlayerIndex];
  }

  @override
  Team? get currentTeam {
    final player = currentPlayer;

    if (player == null) {
      return null;
    }

    return teamById(player.teamId);
  }

  @override
  Team? get winningTeam => _winningTeam;

  @override
  int? get pendingMoveValue {
    return _pendingMoveValue;
  }

  @override
  bool get hasPendingMove {
    return _pendingMoveValue != null;
  }

  @override
  bool get extraTurnEarned {
    return _extraTurnEarned;
  }

  @override
  ThrowResult? get lastThrowResult {
    return _lastThrowResult;
  }

  @override
  bool get specialMovePending {
    return _state == GameState.waitingForSpecialMove;
  }

  Team teamById(int teamId) {
    return teams.firstWhere(
      (team) => team.id == teamId,
      orElse: () {
        throw GameRuleException('Team $teamId does not exist.');
      },
    );
  }

  List<Piece> piecesForTeam(int teamId) {
    return players
        .where((player) => player.teamId == teamId)
        .expand((player) => player.pieces)
        .toList(growable: false);
  }

  @override
  int throwSticks() {
    if (_state == GameState.gameOver) {
      throw GameRuleException('The game is over.');
    }

    if (_state != GameState.waitingForThrow) {
      throw GameRuleException(
        'Cannot throw now. The current throw '
        'must be used first.',
      );
    }

    final result = ThrowResult(
      lightSides: List.generate(4, (_) => _random.nextBool()),
    );

    return _applyThrowResult(result);
  }

  int throwSpecificSticks(List<bool> lightSides) {
    if (lightSides.length != 4) {
      throw GameRuleException('Exactly four stick results are required.');
    }

    if (_state == GameState.gameOver) {
      throw GameRuleException('The game is over.');
    }

    if (_state != GameState.waitingForThrow) {
      throw GameRuleException(
        'Cannot throw now. The current throw '
        'must be used first.',
      );
    }

    final result = ThrowResult(lightSides: lightSides);

    return _applyThrowResult(result);
  }

  int _applyThrowResult(ThrowResult result) {
    _lastThrowResult = result;

    if (result.specialMove) {
      _pendingMoveValue = null;
      _extraTurnEarned = false;

      if (legalSpecialTargets().isEmpty) {
        _state = GameState.waitingForThrow;
      } else {
        _state = GameState.waitingForSpecialMove;
      }

      validateInvariants();

      return 0;
    }

    _pendingMoveValue = result.moveValue;
    _extraTurnEarned = result.lightCount == 4;
    _state = GameState.waitingForMove;

    validateInvariants();

    return result.moveValue;
  }

  @override
  void movePiece(Piece piece, int moveValue) {
    final destinations = legalDestinationsForPiece(piece, moveValue);

    if (destinations.isEmpty) {
      throw GameRuleException('This piece has no legal move.');
    }

    if (destinations.length > 1) {
      throw GameRuleException('Choose a destination for this move.');
    }

    movePieceToStation(piece, moveValue, destinations.first);
  }

  @override
  void movePieceToStation(Piece piece, int moveValue, int destinationStation) {
    if (_state == GameState.gameOver) {
      throw GameRuleException('The game is over.');
    }

    if (_state != GameState.waitingForMove) {
      throw GameRuleException('A player must throw before moving.');
    }

    if (_pendingMoveValue == null) {
      throw GameRuleException('There is no pending move value.');
    }

    if (moveValue != _pendingMoveValue) {
      throw GameRuleException(
        'Move value $moveValue does not match '
        'pending throw $_pendingMoveValue.',
      );
    }

    final player = currentPlayer;

    if (player == null) {
      throw GameRuleException('There is no current player.');
    }

    if (!player.controlsPiece(piece)) {
      throw GameRuleException(
        'The current player may only select '
        'a piece they control.',
      );
    }

    final moveOption = board.optionForDestination(
      piece.progress,
      moveValue,
      destinationStation,
      diagonalTravel: piece.diagonalTravel,
    );

    final movingStack = _friendlyStackFor(piece);

    for (final movingPiece in movingStack) {
      movingPiece.moveToProgress(
        moveOption.destination,
        diagonalTravel: moveOption.diagonalTravel,
      );
    }

    var captured = false;

    if (destinationStation != Board.finishProgress) {
      captured = _captureOpponentsAt(destinationStation, player.teamId);
    }

    _completeAction(extraTurn: captured || _extraTurnEarned);

    validateInvariants();
  }

  List<Piece> _friendlyStackFor(Piece selectedPiece) {
    if (selectedPiece.isInactive || selectedPiece.isCompleted) {
      return [selectedPiece];
    }

    return piecesForTeam(selectedPiece.teamId)
        .where((piece) => piece.stationIndex == selectedPiece.stationIndex)
        .toList(growable: false);
  }

  bool _captureOpponentsAt(int station, int currentTeamId) {
    var captured = false;

    for (final player in players) {
      if (player.teamId == currentTeamId) {
        continue;
      }

      for (final piece in player.pieces) {
        if (piece.stationIndex == station) {
          piece.sendToStart();
          captured = true;
        }
      }
    }

    return captured;
  }

  @override
  List<Piece> legalSpecialTargets() {
    final player = currentPlayer;

    if (player == null) {
      return [];
    }

    return players
        .where((otherPlayer) => otherPlayer.teamId != player.teamId)
        .expand((otherPlayer) => otherPlayer.pieces)
        .where((piece) => piece.stationIndex != null)
        .toList(growable: false);
  }

  @override
  void specialCapture({
    required Piece movingPiece,
    required Piece targetPiece,
  }) {
    if (_state == GameState.gameOver) {
      throw GameRuleException('The game is over.');
    }

    if (_state != GameState.waitingForSpecialMove) {
      throw GameRuleException('There is no special move pending.');
    }

    final player = currentPlayer;

    if (player == null) {
      throw GameRuleException('There is no current player.');
    }

    if (!player.controlsPiece(movingPiece)) {
      throw GameRuleException('You must select a piece you control.');
    }

    if (targetPiece.teamId == player.teamId) {
      throw GameRuleException(
        'The X-stick special move must target '
        'the opposing team.',
      );
    }

    if (!legalSpecialTargets().contains(targetPiece)) {
      throw GameRuleException(
        'That piece is not a legal '
        'special-move target.',
      );
    }

    final targetStation = targetPiece.stationIndex;

    if (targetStation == null) {
      throw GameRuleException('Target piece is not on the board.');
    }

    // Preserve the target's direction before
    // the captured piece is returned to start.
    final targetTravel = targetPiece.diagonalTravel;

    final movingStack = _friendlyStackFor(movingPiece);

    _captureOpponentsAt(targetStation, player.teamId);

    for (final piece in movingStack) {
      piece.moveToProgress(targetStation, diagonalTravel: targetTravel);
    }

    _completeAction(extraTurn: true);

    validateInvariants();
  }

  @override
  bool canMovePiece(Piece piece, int moveValue) {
    return legalDestinationsForPiece(piece, moveValue).isNotEmpty;
  }

  @override
  List<int> legalDestinationsForPiece(Piece piece, int moveValue) {
    if (moveValue < 1 || moveValue > 5) {
      return [];
    }

    if (piece.isCompleted) {
      return [];
    }

    return board.destinationsAfterMove(
      piece.progress,
      moveValue,
      diagonalTravel: piece.diagonalTravel,
    );
  }

  @override
  List<Piece> legalPiecesForCurrentThrow() {
    final moveValue = _pendingMoveValue;

    if (moveValue == null) {
      return [];
    }

    final player = currentPlayer;

    if (player == null) {
      return [];
    }

    return player.pieces
        .where((piece) => canMovePiece(piece, moveValue))
        .toList(growable: false);
  }

  @override
  void skipMoveIfNoLegalMove() {
    if (_state != GameState.waitingForMove) {
      throw GameRuleException('There is no normal move to skip.');
    }

    if (legalPiecesForCurrentThrow().isNotEmpty) {
      throw GameRuleException(
        'Cannot skip because at least one '
        'legal move exists.',
      );
    }

    _completeAction(extraTurn: false);

    validateInvariants();
  }

  void _completeAction({required bool extraTurn}) {
    _pendingMoveValue = null;
    _extraTurnEarned = false;

    _updateWinningTeam();

    if (_winningTeam != null) {
      _state = GameState.gameOver;
      return;
    }

    _state = GameState.waitingForThrow;

    if (extraTurn) {
      return;
    }

    _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
  }

  void _updateWinningTeam() {
    for (final team in teams) {
      final teamPieces = piecesForTeam(team.id);

      if (teamPieces.length == piecesPerTeam &&
          teamPieces.every((piece) => piece.isCompleted)) {
        _winningTeam = team;
        return;
      }
    }

    _winningTeam = null;
  }

  void validateInvariants() {
    board.validateInvariants();

    if (players.length < 2 || players.length > 4) {
      throw StateError(
        'Game B must contain between '
        '2 and 4 players.',
      );
    }

    if (teams.length != teamCount) {
      throw StateError(
        'Game B must contain exactly '
        'two teams.',
      );
    }

    final playerIds = <int>{};

    for (final player in players) {
      if (!playerIds.add(player.id)) {
        throw StateError('Player IDs must be unique.');
      }
    }

    for (final team in teams) {
      team.validateInvariants();

      final teamPlayers = players
          .where((player) => player.teamId == team.id)
          .toList(growable: false);

      if (teamPlayers.isEmpty || teamPlayers.length > 2) {
        throw StateError(
          '${team.name} must contain '
          'one or two players.',
        );
      }

      final expectedPiecesPerPlayer = teamPlayers.length == 1 ? 4 : 2;

      for (final player in teamPlayers) {
        player.validateInvariants(expectedPieceCount: expectedPiecesPerPlayer);
      }

      final teamPieces = piecesForTeam(team.id);

      if (teamPieces.length != piecesPerTeam) {
        throw StateError(
          '${team.name} must control '
          'exactly four pieces.',
        );
      }
    }

    if (_currentPlayerIndex < 0 || _currentPlayerIndex >= players.length) {
      throw StateError('Current player index is invalid.');
    }

    if (_state == GameState.waitingForThrow && _pendingMoveValue != null) {
      throw StateError(
        'There cannot be a pending move '
        'while waiting to throw.',
      );
    }

    if (_state == GameState.waitingForMove && _pendingMoveValue == null) {
      throw StateError(
        'There must be a pending move '
        'while waiting to move.',
      );
    }

    if (_state == GameState.waitingForSpecialMove &&
        _pendingMoveValue != null) {
      throw StateError(
        'A special move cannot also have '
        'a normal move value.',
      );
    }

    if (_state == GameState.gameOver && _winningTeam == null) {
      throw StateError(
        'A completed game must have '
        'a winning team.',
      );
    }

    if (_state != GameState.gameOver && _winningTeam != null) {
      throw StateError(
        'A winning team requires '
        'the game-over state.',
      );
    }

    if (_pendingMoveValue != null &&
        (_pendingMoveValue! < 1 || _pendingMoveValue! > 5)) {
      throw StateError(
        'Pending move value must be '
        'between 1 and 5.',
      );
    }

    final seenPieces = <Piece>{};

    for (final player in players) {
      for (final piece in player.pieces) {
        if (!seenPieces.add(piece)) {
          throw StateError(
            'The same piece cannot belong '
            'to two players.',
          );
        }

        if (piece.ownerId != player.id) {
          throw StateError(
            'Piece owner does not match '
            'its player.',
          );
        }

        if (piece.teamId != player.teamId) {
          throw StateError(
            'Piece team does not match '
            'its player team.',
          );
        }

        piece.validateInvariants();

        if (piece.isActive) {
          final station = piece.stationIndex;

          if (station == null || !board.isValidStation(station)) {
            throw StateError(
              'An active piece must be on '
              'a valid board station.',
            );
          }

          if (board.isDiagonalStation(station) &&
              piece.diagonalTravel == null) {
            throw StateError(
              'A piece on diagonal station '
              '$station must store its '
              'travel direction.',
            );
          }

          if (!board.isDiagonalStation(station) &&
              piece.diagonalTravel != null) {
            throw StateError(
              'A piece outside a diagonal '
              'cannot store diagonal travel.',
            );
          }
        }
      }
    }
  }
}
