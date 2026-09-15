class Team {
  final int id;
  final String name;
  final List<int> playerIds;

  Team({
    required this.id,
    required this.name,
    required List<int> playerIds,
  }) : playerIds = List.unmodifiable(playerIds) {
    validateInvariants();
  }

  void validateInvariants() {
    if (id < 0) {
      throw StateError('Team ID cannot be negative.');
    }

    if (playerIds.isEmpty || playerIds.length > 2) {
      throw StateError(
        '$name must contain either one or two players.',
      );
    }

    if (playerIds.toSet().length != playerIds.length) {
      throw StateError('$name cannot contain duplicate players.');
    }
  }

  bool containsPlayer(int playerId) {
    return playerIds.contains(playerId);
  }

  @override
  String toString() => name;
}