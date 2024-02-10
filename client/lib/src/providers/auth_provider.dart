import 'package:flutter/material.dart';
import 'package:client/src/app_http_client.dart';
// import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:background_fetch/background_fetch.dart';
import 'package:client/src/app_logger.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false; // The no-no variable
  late String apiUrl;
  final String loginUriPath = '/login';
  final String registerUriPath = '/register';
  final String logoutUriPath = '/logout';
  late String _err;
  String get error => _err;

  bool get getAuthState => _isLoggedIn;

  AuthProvider() {
    AppLogger.instance.i('AuthProvider(): initialized with prefs');
    // This needs to load before everything else!
    _loadApiUrlPrefs();
  }

  // Load the API url first before everything else, then notify all listeners
  // that there are asynchronous changes have been made.
  Future<void> _loadApiUrlPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    apiUrl = prefs.getString('apiUrl') ?? '';
    notifyListeners();
  }

  // Provide an asynchronous function to handle user login
  Future<void> login(String email, String password) async {
    // The 'async' keyword allows for asynchronous operations within the
    // function body
    try {
      final Map<String, String> requestBody = {
        'email': email,
        'password': password,
      };

      final response = await AppHttpClient.post(
        loginUriPath,
        body: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // store login token
    } catch (e) {
      AppLogger.instance.e(e);
      // You can throw an exception here and catch it in the UI layer to
      // display a generic error message.
      throw Exception(
          'There was an issue while trying to log you in. Please try again.');
    }
  }

  Future<void> register(
      String email, String password, String username, String phone) async {
    try {
      final Map<String, dynamic> registerData = {
        'email': email,
        'password': password,
        'username': username,
        'phone': phone,
      };

      final response = await http.post(
        Uri.parse(apiUrl).resolve(registerUriPath),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(registerData),
      );

      // check if the HTTP response code is 200
      if (response.statusCode == 200) {
        AppLogger.instance
            .i("AuthProvider()._login: HTTP/${response.statusCode}");
        // login was successful
        final Map<String, dynamic> responseData = json.decode(response.body);

        // store the JWT localled with shared_preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('login_token', responseData['login_token']);
        notifyListeners();
      } else {
        AppLogger.instance
            .w("AuthProvider().login: HTTP/${response.statusCode}");
        // login failed
        throw Exception(
            'You failed to do something in registration or whatever');
      }
    } catch (e) {
      AppLogger.instance.e(e);
      throw Exception(
          'An error occurred during registration. Please try again.');
    }
  }

  // Provide an asynchronous function to handle user logout
  Future<void> logout() async {
    _isLoggedIn = false;
    // TODO: clear token
    notifyListeners();
  }
}