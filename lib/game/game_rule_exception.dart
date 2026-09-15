class GameRuleException implements Exception {
  final String message;

  GameRuleException(this.message);

  @override
  String toString() => 'GameRuleException: $message';
}