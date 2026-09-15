import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class LlmClientException implements Exception {
  final String message;

  const LlmClientException(this.message);

  @override
  String toString() {
    return 'LlmClientException: $message';
  }
}

class LlmClient {
  static const String defaultModel = 'gpt-5-mini';

  static const String _definedApiKey = String.fromEnvironment('OPENAI_API_KEY');

  static const String _instructions =
      'You select one legal move for Game B. '
      'Choose only from the numbered move list. '
      'Prefer, in order: finishing a piece, capturing an opponent, '
      'using a useful shortcut, then making the strongest forward progress. '
      'Return exactly MOVE followed by the move number. '
      'Examples: MOVE 1 or MOVE 3. '
      'Do not include punctuation, explanation, or any other text.';

  static final Uri _responsesEndpoint = Uri.parse(
    'https://api.openai.com/v1/responses',
  );

  final http.Client _httpClient;
  final String model;
  final Duration timeout;
  final String? _apiKeyOverride;

  LlmClient({
    http.Client? httpClient,
    this.model = defaultModel,
    this.timeout = const Duration(seconds: 45),
    String? apiKey,
  }) : _httpClient = httpClient ?? http.Client(),
       _apiKeyOverride = apiKey;

  Future<String> ask(String prompt) async {
    final apiKey = _readApiKey();

    final requestBody = jsonEncode(<String, Object>{
      'model': model,

      // This task is simple move selection, so minimal reasoning
      // reduces cost, latency, and hidden reasoning-token use.
      'reasoning': <String, String>{'effort': 'minimal'},

      'instructions': _instructions,
      'input': prompt,

      // This includes reasoning and visible output tokens.
      // 512 gives the model enough room to produce MOVE <number>.
      'max_output_tokens': 512,

      // Keep the visible response brief.
      'text': <String, Object>{'verbosity': 'low'},
    });

    final response = await _sendRequest(
      apiKey: apiKey,
      requestBody: requestBody,
    );

    final decodedBody = _decodeJsonObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmClientException(
        'OpenAI returned HTTP ${response.statusCode}: '
        '${_extractApiError(decodedBody)}',
      );
    }

    final outputText = _extractOutputText(decodedBody);

    if (outputText != null && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    throw LlmClientException(_describeMissingOutput(decodedBody));
  }

  Future<http.Response> _sendRequest({
    required String apiKey,
    required String requestBody,
  }) async {
    try {
      return await _httpClient
          .post(
            _responsesEndpoint,
            headers: <String, String>{
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const LlmClientException('The OpenAI request timed out.');
    } on http.ClientException catch (error) {
      throw LlmClientException('The HTTP request failed: ${error.message}');
    } catch (error) {
      throw LlmClientException('The OpenAI request failed: $error');
    }
  }

  String _readApiKey() {
    final apiKey = _apiKeyOverride ?? _definedApiKey;

    if (apiKey.trim().isEmpty) {
      throw const LlmClientException(
        'OPENAI_API_KEY was not supplied. '
        'Launch Flutter with '
        '--dart-define=OPENAI_API_KEY=your_key.',
      );
    }

    return apiKey.trim();
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const LlmClientException(
        'OpenAI returned an unexpected JSON structure.',
      );
    } on FormatException {
      throw const LlmClientException(
        'OpenAI returned a response that was not valid JSON.',
      );
    }
  }

  String? _extractOutputText(Map<String, dynamic> body) {
    // Some SDK-style responses expose a direct output_text value.
    final directOutputText = body['output_text'];

    if (directOutputText is String && directOutputText.trim().isNotEmpty) {
      return directOutputText.trim();
    }

    final output = body['output'];

    if (output is! List) {
      return null;
    }

    final textParts = <String>[];

    for (final outputItem in output) {
      if (outputItem is! Map) {
        continue;
      }

      final content = outputItem['content'];

      if (content is! List) {
        continue;
      }

      for (final contentItem in content) {
        if (contentItem is! Map) {
          continue;
        }

        final type = contentItem['type'];
        final text = contentItem['text'];

        if (type == 'output_text' && text is String && text.trim().isNotEmpty) {
          textParts.add(text.trim());
        }
      }
    }

    if (textParts.isEmpty) {
      return null;
    }

    return textParts.join('\n');
  }

  String _describeMissingOutput(Map<String, dynamic> body) {
    final status = body['status'];

    if (status == 'incomplete') {
      final incompleteDetails = body['incomplete_details'];

      if (incompleteDetails is Map) {
        final reason = incompleteDetails['reason'];

        if (reason == 'max_output_tokens') {
          return 'OpenAI used the available output-token budget '
              'before producing a visible move.';
        }

        if (reason is String && reason.isNotEmpty) {
          return 'OpenAI returned an incomplete response: $reason.';
        }
      }

      return 'OpenAI returned an incomplete response.';
    }

    final output = body['output'];

    if (output is List) {
      for (final outputItem in output) {
        if (outputItem is! Map) {
          continue;
        }

        if (outputItem['type'] == 'message') {
          final messageStatus = outputItem['status'];

          if (messageStatus is String) {
            return 'OpenAI returned a message with status '
                '$messageStatus but no output text.';
          }
        }
      }
    }

    return 'OpenAI returned no output text.';
  }

  String _extractApiError(Map<String, dynamic> body) {
    final error = body['error'];

    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }

    return 'Unknown API error.';
  }

  void close() {
    _httpClient.close();
  }
}
