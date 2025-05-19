import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getSentimentAnalysis(String reviewText) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyCHFhGAl9JyBmXfLpaLTISNwZIxky4y4ig';
  final prompt = '''
Analyze the sentiment of the following review and classify it into one of five levels: Very Negative, Negative, Neutral, Positive, or Very Positive. Provide a brief explanation.

Review: $reviewText

Respond in this format:
**Sentiment**: [One of five]
**Explanation**: [Explanation]
''';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawText = data['candidates'][0]['content']['parts'][0]['text'];
      final sentimentMatch = RegExp(r'\*\*Sentiment\*\*:\s*(.*)').firstMatch(rawText);
      final explanationMatch = RegExp(r'\*\*Explanation\*\*:\s*(.*)').firstMatch(rawText);

      return {
        'sentiment': sentimentMatch?.group(1) ?? 'Unknown',
        'explanation': explanationMatch?.group(1)?.trim() ?? 'No explanation provided',
      };
    }
    return {'sentiment': 'Error', 'explanation': 'Failed to analyze'};
  } catch (e) {
    return {'sentiment': 'Error', 'explanation': 'Exception: $e'};
  }
}
