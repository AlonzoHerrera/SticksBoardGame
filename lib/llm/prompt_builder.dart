class PromptBuilder {
  String buildPrompt({
    required String currentPlayer,
    required int throwValue,
    required List<String> piecePositions,
    required List<String> legalMoves,
  }) {
    if (legalMoves.isEmpty) {
      throw ArgumentError(
        'At least one legal move is required to build an LLM prompt.',
      );
    }

    final buffer = StringBuffer()
      ..writeln('Turn: $currentPlayer')
      ..writeln('Throw: $throwValue')
      ..writeln('Pieces: ${piecePositions.join(', ')}')
      ..writeln('Moves:');

    for (var index = 0; index < legalMoves.length; index++) {
      buffer.writeln('${index + 1}: ${legalMoves[index]}');
    }

    return buffer.toString().trim();
  }
}
