import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AutocompleteService {
  static final String _apiKey = dotenv.env['AUTOCOMPLETE_API_KEY'] ?? '';

  static Future<List<String>> fetchSuggestions(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?'
        'text=${Uri.encodeComponent(query)}'
        '&apiKey=$_apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      final data = json.decode(response.body);

      if (data['features'] != null) {
        return (data['features'] as List)
            .map((feature) => feature['properties']['formatted'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching autocomplete: $e');
      return [];
    }
  }
}
