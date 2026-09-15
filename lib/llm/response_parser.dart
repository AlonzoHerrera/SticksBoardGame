class ResponseParser {
  const ResponseParser();

  int? parse({
    required String response,
    required int legalMoveCount,
  }) {
    if (legalMoveCount <= 0) {
      return null;
    }

    final match = RegExp(
      r'\b(?:MOVE\s*)?(\d+)\b',
      caseSensitive: false,
    ).firstMatch(response.trim());

    if (match == null) {
      return null;
    }

    final selectedNumber = int.tryParse(
      match.group(1)!,
    );

    if (selectedNumber == null) {
      return null;
    }

    final selectedIndex = selectedNumber - 1;

    if (selectedIndex < 0 ||
        selectedIndex >= legalMoveCount) {
      return null;
    }

    return selectedIndex;
  }
}