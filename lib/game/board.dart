import 'game_rule_exception.dart';

enum DiagonalTravel { towardCenter, awayFromCenter, centerFinishRoute }

class BoardMoveOption {
  final int destination;
  final DiagonalTravel? diagonalTravel;

  const BoardMoveOption({
    required this.destination,
    required this.diagonalTravel,
  });

  @override
  bool operator ==(Object other) {
    return other is BoardMoveOption &&
        other.destination == destination &&
        other.diagonalTravel == diagonalTravel;
  }

  @override
  int get hashCode {
    return Object.hash(destination, diagonalTravel);
  }

  @override
  String toString() {
    return 'BoardMoveOption('
        'destination: $destination, '
        'diagonalTravel: $diagonalTravel)';
  }
}

class _RoutePosition {
  final int progress;
  final DiagonalTravel? diagonalTravel;

  const _RoutePosition({required this.progress, required this.diagonalTravel});
}

class Board {
  static const int stationCount = 29;
  static const int startStationIndex = 0;

  // Progress 29 means that a piece has crossed the finish.
  // It is not a visible board station.
  static const int finishProgress = stationCount;

  static const Set<int> branchStations = <int>{5, 10, 15, 28};

  static const Set<int> diagonalStations = <int>{
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
  };

  final Map<int, List<int>> _connections;

  Board() : _connections = _createConnections() {
    validateInvariants();
  }

  Map<int, List<int>> get connections {
    final copiedConnections = <int, List<int>>{};

    for (final entry in _connections.entries) {
      copiedConnections[entry.key] = List<int>.unmodifiable(entry.value);
    }

    return Map<int, List<int>>.unmodifiable(copiedConnections);
  }

  static Map<int, List<int>> _createConnections() {
    return {
      // Start and outside path.
      0: [1],
      1: [2],
      2: [3],
      3: [4],
      4: [5],

      // First branch.
      5: [6, 22],

      // Top outside path.
      6: [7],
      7: [8],
      8: [9],
      9: [10],

      // Second branch.
      10: [11, 24],

      // Left outside path.
      11: [12],
      12: [13],
      13: [14],
      14: [15],

      // Third branch.
      15: [16, 26],

      // Bottom outside path and finish.
      16: [17],
      17: [18],
      18: [19],
      19: [finishProgress],

      // Bottom-right diagonal.
      20: [21],
      21: [28],

      // Top-right diagonal.
      22: [23],
      23: [28],

      // Top-left diagonal.
      24: [25],
      25: [28],

      // Bottom-left diagonal.
      26: [27],
      27: [28],

      // Center route choices.
      28: [19, 20],
    };
  }

  bool isValidStation(int stationIndex) {
    return stationIndex >= 0 && stationIndex < stationCount;
  }

  bool isFinishProgress(int progress) {
    return progress == finishProgress;
  }

  bool isDiagonalStation(int stationIndex) {
    return diagonalStations.contains(stationIndex);
  }

  List<int> neighborsOf(int stationIndex) {
    if (!isValidStation(stationIndex)) {
      throw GameRuleException('Station $stationIndex is not valid.');
    }

    return List<int>.unmodifiable(_connections[stationIndex]!);
  }

  List<int> destinationsAfterMove(
    int currentProgress,
    int moveValue, {
    DiagonalTravel? diagonalTravel,
  }) {
    final options = moveOptionsAfterMove(
      currentProgress,
      moveValue,
      diagonalTravel: diagonalTravel,
    );

    final destinations = options
        .map((option) => option.destination)
        .toSet()
        .toList(growable: false);

    destinations.sort();

    return destinations;
  }

  List<BoardMoveOption> moveOptionsAfterMove(
    int currentProgress,
    int moveValue, {
    DiagonalTravel? diagonalTravel,
  }) {
    _validateMoveArguments(currentProgress, moveValue);

    // An inactive piece uses its first movement point
    // to enter station 0.
    if (currentProgress == -1) {
      if (moveValue == 1) {
        return const <BoardMoveOption>[
          BoardMoveOption(destination: startStationIndex, diagonalTravel: null),
        ];
      }

      return _followCommittedRoute(
        startProgress: startStationIndex,
        moveValue: moveValue - 1,
        startingTravel: null,
      );
    }

    // When the move begins at the center,
    // the player uses the special center choices.
    if (currentProgress == 28) {
      return _destinationsFromCenter(moveValue);
    }

    // Route choices exist only when the move begins
    // at stations 5, 10, or 15.
    if (currentProgress == 5 ||
        currentProgress == 10 ||
        currentProgress == 15) {
      return _destinationsFromStartingBranch(currentProgress, moveValue);
    }

    // A diagonal station needs its saved direction.
    // For direct board tests where no direction is supplied,
    // the default is movement toward the center.
    final effectiveTravel = isDiagonalStation(currentProgress)
        ? diagonalTravel ?? DiagonalTravel.towardCenter
        : null;

    return _followCommittedRoute(
      startProgress: currentProgress,
      moveValue: moveValue,
      startingTravel: effectiveTravel,
    );
  }

  BoardMoveOption optionForDestination(
    int currentProgress,
    int moveValue,
    int destination, {
    DiagonalTravel? diagonalTravel,
  }) {
    final options = moveOptionsAfterMove(
      currentProgress,
      moveValue,
      diagonalTravel: diagonalTravel,
    );

    for (final option in options) {
      if (option.destination == destination) {
        return option;
      }
    }

    throw GameRuleException('Destination $destination is not legal.');
  }

  void _validateMoveArguments(int currentProgress, int moveValue) {
    if (moveValue < 1 || moveValue > 5) {
      throw GameRuleException('Move value must be between 1 and 5.');
    }

    if (currentProgress < -1 || currentProgress >= finishProgress) {
      throw GameRuleException('Current progress is invalid.');
    }
  }

  List<BoardMoveOption> _destinationsFromStartingBranch(
    int startingStation,
    int moveValue,
  ) {
    final options = <BoardMoveOption>{};

    final outsideFirstStep = _outsideNext(startingStation);

    if (outsideFirstStep != null) {
      final outsideOption = _followFromFirstStep(
        startingStation: startingStation,
        firstStep: outsideFirstStep,
        moveValue: moveValue,
        firstStepTravel: null,
      );

      if (outsideOption != null) {
        options.add(outsideOption);
      }
    }

    final diagonalFirstStep = _diagonalEntryForBranch(startingStation);

    if (diagonalFirstStep != null) {
      final diagonalOption = _followFromFirstStep(
        startingStation: startingStation,
        firstStep: diagonalFirstStep,
        moveValue: moveValue,
        firstStepTravel: DiagonalTravel.towardCenter,
      );

      if (diagonalOption != null) {
        options.add(diagonalOption);
      }
    }

    return _sortedOptions(options);
  }

  BoardMoveOption? _followFromFirstStep({
    required int startingStation,
    required int firstStep,
    required int moveValue,
    required DiagonalTravel? firstStepTravel,
  }) {
    var previous = startingStation;

    var current = _RoutePosition(
      progress: firstStep,
      diagonalTravel: firstStepTravel,
    );

    var stepsUsed = 1;

    if (stepsUsed == moveValue) {
      return BoardMoveOption(
        destination: current.progress,
        diagonalTravel: _travelForDestination(current),
      );
    }

    while (stepsUsed < moveValue) {
      if (current.progress == finishProgress) {
        return const BoardMoveOption(
          destination: finishProgress,
          diagonalTravel: null,
        );
      }

      final next = _advanceRoute(current: current, previousProgress: previous);

      if (next == null) {
        return null;
      }

      previous = current.progress;
      current = next;
      stepsUsed++;
    }

    return BoardMoveOption(
      destination: current.progress,
      diagonalTravel: _travelForDestination(current),
    );
  }

  List<BoardMoveOption> _followCommittedRoute({
    required int startProgress,
    required int moveValue,
    required DiagonalTravel? startingTravel,
  }) {
    int? previousProgress;

    var current = _RoutePosition(
      progress: startProgress,
      diagonalTravel: startingTravel,
    );

    for (var step = 0; step < moveValue; step++) {
      if (current.progress == finishProgress) {
        return const <BoardMoveOption>[
          BoardMoveOption(destination: finishProgress, diagonalTravel: null),
        ];
      }

      final next = _advanceRoute(
        current: current,
        previousProgress: previousProgress,
      );

      if (next == null) {
        return const <BoardMoveOption>[];
      }

      previousProgress = current.progress;
      current = next;
    }

    return <BoardMoveOption>[
      BoardMoveOption(
        destination: current.progress,
        diagonalTravel: _travelForDestination(current),
      ),
    ];
  }

  _RoutePosition? _advanceRoute({
    required _RoutePosition current,
    required int? previousProgress,
  }) {
    final progress = current.progress;

    if (progress == finishProgress) {
      return const _RoutePosition(
        progress: finishProgress,
        diagonalTravel: null,
      );
    }

    if (progress == 28) {
      return _continueThroughCenter(previousProgress);
    }

    switch (current.diagonalTravel) {
      case DiagonalTravel.towardCenter:
        return _moveTowardCenter(progress);

      case DiagonalTravel.awayFromCenter:
        return _moveAwayFromCenter(progress);

      case DiagonalTravel.centerFinishRoute:
        return _moveOnCenterFinishRoute(progress);

      case null:
        return _moveAlongOutside(progress);
    }
  }

  _RoutePosition? _moveAlongOutside(int progress) {
    final next = _outsideNext(progress);

    if (next == null) {
      return null;
    }

    return _RoutePosition(progress: next, diagonalTravel: null);
  }

  int? _outsideNext(int progress) {
    switch (progress) {
      case 0:
        return 1;
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      case 5:
        return 6;
      case 6:
        return 7;
      case 7:
        return 8;
      case 8:
        return 9;
      case 9:
        return 10;
      case 10:
        return 11;
      case 11:
        return 12;
      case 12:
        return 13;
      case 13:
        return 14;
      case 14:
        return 15;
      case 15:
        return 16;
      case 16:
        return 17;
      case 17:
        return 18;
      case 18:
        return 19;
      case 19:
        return finishProgress;
      default:
        return null;
    }
  }

  int? _diagonalEntryForBranch(int branchStation) {
    switch (branchStation) {
      case 5:
        return 22;
      case 10:
        return 24;
      case 15:
        return 26;
      default:
        return null;
    }
  }

  _RoutePosition? _moveTowardCenter(int progress) {
    switch (progress) {
      case 20:
        return const _RoutePosition(
          progress: 21,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 21:
        return const _RoutePosition(
          progress: 28,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 22:
        return const _RoutePosition(
          progress: 23,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 23:
        return const _RoutePosition(
          progress: 28,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 24:
        return const _RoutePosition(
          progress: 25,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 25:
        return const _RoutePosition(
          progress: 28,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 26:
        return const _RoutePosition(
          progress: 27,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      case 27:
        return const _RoutePosition(
          progress: 28,
          diagonalTravel: DiagonalTravel.towardCenter,
        );

      default:
        return null;
    }
  }

  _RoutePosition? _continueThroughCenter(int? previousProgress) {
    switch (previousProgress) {
      // Top-right to bottom-left.
      case 23:
        return const _RoutePosition(
          progress: 27,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      // Bottom-left to top-right.
      case 27:
        return const _RoutePosition(
          progress: 23,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      // Top-left to bottom-right.
      case 25:
        return const _RoutePosition(
          progress: 21,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      // Bottom-right to top-left.
      case 21:
        return const _RoutePosition(
          progress: 25,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      default:
        return null;
    }
  }

  _RoutePosition? _moveAwayFromCenter(int progress) {
    switch (progress) {
      case 27:
        return const _RoutePosition(
          progress: 26,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      case 26:
        return const _RoutePosition(progress: 15, diagonalTravel: null);

      case 23:
        return const _RoutePosition(
          progress: 22,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      case 22:
        return const _RoutePosition(progress: 5, diagonalTravel: null);

      case 21:
        return const _RoutePosition(
          progress: 20,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      case 20:
        return const _RoutePosition(progress: 0, diagonalTravel: null);

      case 25:
        return const _RoutePosition(
          progress: 24,
          diagonalTravel: DiagonalTravel.awayFromCenter,
        );

      case 24:
        return const _RoutePosition(progress: 10, diagonalTravel: null);

      default:
        return null;
    }
  }

  _RoutePosition? _moveOnCenterFinishRoute(int progress) {
    switch (progress) {
      case 20:
        return const _RoutePosition(
          progress: 21,
          diagonalTravel: DiagonalTravel.centerFinishRoute,
        );

      case 21:
        return const _RoutePosition(progress: 19, diagonalTravel: null);

      default:
        return null;
    }
  }

  List<BoardMoveOption> _destinationsFromCenter(int moveValue) {
    final options = <BoardMoveOption>{};

    // Short center route:
    // 28 -> 19 -> finish.
    //
    // A throw of 1 reaches station 19.
    // A throw of at least 3 crosses the finish.
    if (moveValue == 1) {
      options.add(const BoardMoveOption(destination: 19, diagonalTravel: null));
    } else if (moveValue >= 3) {
      options.add(
        const BoardMoveOption(
          destination: finishProgress,
          diagonalTravel: null,
        ),
      );
    }

    // Long center route:
    // 28 -> 20 -> 21 -> 19 -> finish.
    const longRoute = <int>[20, 21, 19, finishProgress];

    final destination = moveValue <= longRoute.length
        ? longRoute[moveValue - 1]
        : finishProgress;

    DiagonalTravel? travel;

    if (destination == 20 || destination == 21) {
      travel = DiagonalTravel.centerFinishRoute;
    }

    options.add(
      BoardMoveOption(destination: destination, diagonalTravel: travel),
    );

    return _sortedOptions(options);
  }

  DiagonalTravel? _travelForDestination(_RoutePosition position) {
    if (!isDiagonalStation(position.progress)) {
      return null;
    }

    return position.diagonalTravel;
  }

  List<BoardMoveOption> _sortedOptions(Set<BoardMoveOption> options) {
    final result = options.toList(growable: false);

    result.sort((first, second) {
      final destinationComparison = first.destination.compareTo(
        second.destination,
      );

      if (destinationComparison != 0) {
        return destinationComparison;
      }

      return first.diagonalTravel.toString().compareTo(
        second.diagonalTravel.toString(),
      );
    });

    return result;
  }

  int nextProgress(
    int currentProgress,
    int moveValue, {
    DiagonalTravel? diagonalTravel,
  }) {
    final destinations = destinationsAfterMove(
      currentProgress,
      moveValue,
      diagonalTravel: diagonalTravel,
    );

    if (destinations.isEmpty) {
      throw GameRuleException('No legal destination exists for this move.');
    }

    if (destinations.length > 1) {
      throw GameRuleException(
        'This move has multiple possible destinations. Choose one.',
      );
    }

    return destinations.first;
  }

  int? stationForProgress(int progress) {
    if (progress == -1 || progress == finishProgress) {
      return null;
    }

    if (!isValidStation(progress)) {
      throw GameRuleException('Progress $progress is not a valid station.');
    }

    return progress;
  }

  void validateInvariants() {
    if (_connections.length != stationCount) {
      throw StateError('Board must contain exactly 29 stations.');
    }

    for (var station = 0; station < stationCount; station++) {
      if (!_connections.containsKey(station)) {
        throw StateError('Board is missing station $station.');
      }
    }

    for (final entry in _connections.entries) {
      final station = entry.key;
      final destinations = entry.value;

      if (!isValidStation(station)) {
        throw StateError('Invalid station index: $station.');
      }

      if (destinations.isEmpty) {
        throw StateError(
          'Station $station must have at least one destination.',
        );
      }

      for (final destination in destinations) {
        final validDestination =
            isValidStation(destination) || destination == finishProgress;

        if (!validDestination) {
          throw StateError(
            'Station $station connects to invalid '
            'destination $destination.',
          );
        }
      }
    }

    for (final entry in _connections.entries) {
      final station = entry.key;
      final hasMultipleRoutes = entry.value.length > 1;
      final shouldHaveMultipleRoutes = branchStations.contains(station);

      if (shouldHaveMultipleRoutes && !hasMultipleRoutes) {
        throw StateError('Station $station must provide two route choices.');
      }

      if (!shouldHaveMultipleRoutes && hasMultipleRoutes) {
        throw StateError('Station $station cannot provide multiple routes.');
      }
    }

    if (!_sameValues(_connections[0]!, const <int>[1])) {
      throw StateError('Station 0 must connect only to station 1.');
    }

    if (!_sameValues(_connections[5]!, const <int>[6, 22])) {
      throw StateError('Station 5 must connect to stations 6 and 22.');
    }

    if (!_sameValues(_connections[10]!, const <int>[11, 24])) {
      throw StateError('Station 10 must connect to stations 11 and 24.');
    }

    if (!_sameValues(_connections[15]!, const <int>[16, 26])) {
      throw StateError('Station 15 must connect to stations 16 and 26.');
    }

    if (!_sameValues(_connections[28]!, const <int>[19, 20])) {
      throw StateError('Station 28 must connect to stations 19 and 20.');
    }

    if (!_sameValues(_connections[19]!, const <int>[finishProgress])) {
      throw StateError('Station 19 must lead directly to the finish.');
    }
  }

  bool _sameValues(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) {
      return false;
    }

    for (var index = 0; index < actual.length; index++) {
      if (actual[index] != expected[index]) {
        return false;
      }
    }

    return true;
  }
}
