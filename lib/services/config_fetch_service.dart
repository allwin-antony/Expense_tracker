import 'dart:convert';
import 'package:http/http.dart' as http;

// Firebase hosting URL for UPI apps data
const String upiDataUrl = '';

class ConfigFetchService {
  static Future<List<dynamic>> fetchUPIApps() async {
    try {
      final response = await http.get(Uri.parse(upiDataUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load UPI apps data');
      }
    } catch (e) {
      print('Error fetching UPI apps: $e');
      return [];
    }
  }
}
