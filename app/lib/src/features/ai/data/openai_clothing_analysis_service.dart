import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/models/clothing_analysis.dart';
import '../domain/clothing_analysis_service.dart';

class OpenAiClothingAnalysisService implements ClothingAnalysisService {
  OpenAiClothingAnalysisService({
    required this.client,
    required this.apiKey,
    this.model = 'gpt-4.1-mini',
  });

  final http.Client client;
  final String apiKey;
  final String model;

  @override
  Future<ClothingAnalysis> analyzeImage({
    required List<int> imageBytes,
    String? hint,
  }) async {
    final imageBase64 = base64Encode(imageBytes);
    final response = await client.post(
      Uri.https('api.openai.com', '/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': _prompt(hint),
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/jpeg;base64,$imageBase64',
              },
            ],
          }
        ],
      }),
    );

    return _parseResponse(response);
  }

  @override
  Future<ClothingAnalysis> analyzeLink({
    required Uri sourceUri,
    String? titleHint,
  }) async {
    final isImageUrl = sourceUri.scheme == 'http' ||
        sourceUri.scheme == 'https' ||
        sourceUri.scheme == 'data';

    final response = await client.post(
      Uri.https('api.openai.com', '/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': '${_prompt(titleHint)}\nsource_url: $sourceUri',
              },
              if (isImageUrl)
                {
                  'type': 'input_image',
                  'image_url': sourceUri.toString(),
                },
            ],
          }
        ],
      }),
    );

    return _parseResponse(response);
  }

  ClothingAnalysis _parseResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAiAnalysisException(
        'OpenAI request failed with ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final output = json['output'] as List<dynamic>? ?? const [];
    for (final item in output) {
      final content = (item as Map<String, dynamic>)['content'] as List<dynamic>? ?? const [];
      for (final part in content) {
        final map = part as Map<String, dynamic>;
        if (map['type'] == 'output_text') {
          final text = map['text']?.toString() ?? '{}';
          return ClothingAnalysis.fromJson(jsonDecode(text) as Map<String, dynamic>);
        }
      }
    }

    throw OpenAiAnalysisException('OpenAI response did not contain parsable JSON');
  }

  String _prompt(String? hint) {
    final hintText = (hint == null || hint.isEmpty) ? '' : 'hint: $hint\n';
    return '''
Analyze the clothing item and return only JSON.
${hintText}Required JSON fields:
{
  "category": "",
  "subcategory": "",
  "colors": [],
  "pattern": "",
  "material_guess": "",
  "style_tags": [],
  "season_tags": [],
  "warmth_score": 0.0,
  "formality_score": 0.0,
  "waterproof": false,
  "confidence": 0.0
}
Use normalized English keywords for colors and style tags.
''';
  }
}

class OpenAiAnalysisException implements Exception {
  OpenAiAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
