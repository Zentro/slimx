import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/src/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppHttpClient {
  static Future<String?> _getApiUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('apiUrl');
  }

  static Future<http.Response> get(String uri, {Map<String, String>? headers}) async {
    final baseUrl = await _getApiUrl();
    final url = Uri.parse('$baseUrl/$uri');

    // Log the HTTP request
    AppLogger.instance.i('Sending HTTP GET request to: $url');

    final response = await http.get(url, headers: headers);
    return response;
  }

  static Future<http.Response> put(String uri,
    {dynamic body, Map<String, String>?headers}) async {
      final baseUrl = await _getApiUrl();
      final url = Uri.parse('$baseUrl/$uri');

      final response = await http.put(url,
      headers: headers, body: body != null ? jsonEncode(body) : null);

      return response;
    }

  static Future<http.Response> post(String uri,
      {dynamic body, Map<String, String>? headers}) async {
    final baseUrl = await _getApiUrl();
    final url = Uri.parse('$baseUrl/$uri');

    // Log the HTTP request
    AppLogger.instance.i('Sending HTTP POST request to: $url');
    AppLogger.instance.d('Request body: ${jsonEncode(body)}');

    final response = await http.post(url,
        body: body != null ? jsonEncode(body) : null, headers: headers);
    return response;
  }

  static dynamic _handleHttpResponse(http.Response response) {
    // Log the HTTP response
    AppLogger.instance.i('HTTP response: HTTP/${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception(
          'An unexpected error occured. Status code: ${response.statusCode}');
    }
  }
}