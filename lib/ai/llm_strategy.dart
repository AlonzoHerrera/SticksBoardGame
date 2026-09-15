import '../game/board.dart';
import '../llm/llm_client.dart';
import '../llm/prompt_builder.dart';
import '../llm/response_parser.dart';
import 'ai_game_snapshot.dart';
import 'ai_strategy.dart';
import 'game_move.dart';
import 'greedy_medium_strategy.dart';

class LlmStrategy extends SnapshotAwareAiStrategy implements AsyncAiStrategy {
  final LlmClient client;
  final PromptBuilder promptBuilder;
  final ResponseParser responseParser;
  final GreedyMediumStrategy fallbackStrategy;

  AiGameSnapshot? _snapshot;

  int _fallbackCount = 0;
  String? _lastError;

  LlmStrategy({
    LlmClient? client,
    PromptBuilder? promptBuilder,
    ResponseParser? responseParser,
    GreedyMediumStrategy? fallbackStrategy,
  }) : client = client ?? LlmClient(),
       promptBuilder = promptBuilder ?? PromptBuilder(),
       responseParser = responseParser ?? const ResponseParser(),
       fallbackStrategy = fallbackStrategy ?? GreedyMediumStrategy();

  @override
  String get name => 'OpenAI LLM';

  @override
  String get difficulty => 'Experimental';

  int get fallbackCount => _fallbackCount;

  String? get lastError => _lastError;

  void resetFallbackCount() {
    _fallbackCount = 0;
    _lastError = null;
  }

  @override
  void updateSnapshot(AiGameSnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  GameMove chooseMove({required List<GameMove> legalMoves}) {
    return _fallback(
      legalMoves: legalMoves,
      reason: 'The LLM strategy was called through the synchronous interface.',
    );
  }

  @override
  Future<GameMove> chooseValidatedMoveAsync({
    required List<GameMove> legalMoves,
  }) async {
    if (legalMoves.isEmpty) {
      throw StateError('LLM Strategy cannot choose from an empty move list.');
    }

    final protectedMoves = List<GameMove>.unmodifiable(legalMoves);

    final snapshot = _snapshot;

    if (snapshot == null) {
      return _fallback(
        legalMoves: protectedMoves,
        reason: 'No game snapshot was available.',
      );
    }

    final prompt = promptBuilder.buildPrompt(
      currentPlayer: _currentPlayerDescription(snapshot),
      throwValue: snapshot.pendingMoveValue ?? 0,
      piecePositions: _buildPiecePositions(snapshot),
      legalMoves: _buildLegalMoveDescriptions(protectedMoves),
    );

    String? mostRecentAttemptError;

    // Try the OpenAI request twice before using
    // Greedy Medium as the fallback strategy.
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await client.ask(prompt);

        final selectedIndex = responseParser.parse(
          response: response,
          legalMoveCount: protectedMoves.length,
        );

        if (selectedIndex == null) {
          mostRecentAttemptError =
              'Attempt $attempt: The LLM returned '
              'an invalid move response: $response';

          continue;
        }

        if (selectedIndex < 0 || selectedIndex >= protectedMoves.length) {
          mostRecentAttemptError =
              'Attempt $attempt: The LLM returned '
              'move index $selectedIndex, but only '
              '${protectedMoves.length} legal moves exist.';

          continue;
        }

        final selectedMove = protectedMoves[selectedIndex];

        selectedMove.validate();

        if (!protectedMoves.contains(selectedMove)) {
          mostRecentAttemptError =
              'Attempt $attempt: The LLM selected '
              'a move that was not legal.';

          continue;
        }

        // Do not clear _lastError here.
        // Keeping the most recent fallback reason
        // allows the results screen to report it.
        return selectedMove;
      } catch (error) {
        mostRecentAttemptError = 'Attempt $attempt failed: $error';
      }
    }

    return _fallback(
      legalMoves: protectedMoves,
      reason: mostRecentAttemptError ?? 'The LLM failed after two attempts.',
    );
  }

  GameMove _fallback({
    required List<GameMove> legalMoves,
    required String reason,
  }) {
    _fallbackCount++;
    _lastError = reason;

    return fallbackStrategy.chooseValidatedMove(legalMoves: legalMoves);
  }

  String _currentPlayerDescription(AiGameSnapshot snapshot) {
    final playerId = snapshot.currentPlayerId;
    final teamId = snapshot.currentTeamId;

    if (playerId == null) {
      return 'unknown';
    }

    if (teamId == null) {
      return 'P$playerId';
    }

    return 'P$playerId/T$teamId';
  }

  List<String> _buildPiecePositions(AiGameSnapshot snapshot) {
    return snapshot.pieces
        .map(
          (piece) =>
              '${piece.pieceKey}=P${piece.ownerId}'
              '/T${piece.teamId}'
              '@${_piecePositionDescription(piece)}',
        )
        .toList(growable: false);
  }

  String _piecePositionDescription(AiPieceSnapshot piece) {
    if (piece.isInactive) {
      return 'S';
    }

    if (piece.isCompleted) {
      return 'F';
    }

    return '${piece.progress}';
  }

  List<String> _buildLegalMoveDescriptions(List<GameMove> legalMoves) {
    return legalMoves.map(_describeMove).toList(growable: false);
  }

  String _describeMove(GameMove move) {
    if (move.isSpecialCapture) {
      return 'piece ${move.movingPieceId} '
          'captures ${move.targetPieceId}';
    }

    final destination = move.destinationProgress == Board.finishProgress
        ? 'F'
        : '${move.destinationProgress}';

    return 'piece ${move.movingPieceId}'
        ' -> $destination';
  }
}
