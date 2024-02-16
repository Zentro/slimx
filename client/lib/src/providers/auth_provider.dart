import 'package:client/src/rust/api/simple.dart';
import 'package:client/src/rust/api/xeddsa.dart';
import 'package:client/src/user.dart';
import 'package:flutter/material.dart';
import 'package:client/src/app_http_client.dart';
// import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:background_fetch/background_fetch.dart';
import 'package:client/src/app_logger.dart';
import 'dart:convert';

import 'app_support_directory_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false; // The no-no variable
  late String apiUrl;
  final String loginUriPath = 'login';
  final String registerUriPath = 'register';
  final String logoutUriPath = 'logout';
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
  Future<User> login(String email, String password, AppSupportDirectoryProvider supportProvider) async {
    // The 'async' keyword allows for asynchronous operations within the
    // function body
    try {
      final Map<String, String> requestBody = {
        'email': email,
        'password': password,
      };

      final loginResponse = await AppHttpClient.post(
        loginUriPath,
        body: requestBody,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (loginResponse.statusCode == 200 || loginResponse.statusCode == 418) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = loginResponse.headers['authorization'] ?? "null";

        // TEST CODE FOR ALLOWING 2 USERS ON ONE DEVICE
        await supportProvider.setGlobalKeyValues(email);

        if (loginResponse.statusCode == 418) {
          var keys = prefs.getString('keys');
          var requestForm = await signAndPublish(keyJson: keys ?? "");
          
          final keyUploadResponse = await AppHttpClient.post(
            'keys',
            body: jsonDecode(requestForm),
            headers: {
              'Content-Type': 'application/json',
              "authorization": token,
            },
          );
          print(keyUploadResponse.statusCode);
        }

        if (loginResponse.statusCode == 200) {
          // Complete the challenge
          var keys = jsonDecode(prefs.getString('keys')!);
          var ik_sec = keys['ik_sec'];
          final String challenge = loginResponse.headers['challenge'] ?? "";
          final String signature = signChallenge(sIkSec: ik_sec, chal: challenge);

          final challengeResponse = await AppHttpClient.put(
            'login',
            body: "",
            headers: {
              'challenge': challenge,
              'signature': signature
            }
          );
          print(challengeResponse.statusCode);
          token = challengeResponse.headers['authorization'] ?? "null";
        }

        prefs.setString('auth', token);
        final Map<String, dynamic> responseData = json.decode(loginResponse.body);
        final User user = User.fromJson(responseData);

        notifyListeners();

        return user;
      } else {
        throw Exception(
            'Failed to log in. Please check your credentials and try again.');
      }
    } catch (e) {
      AppLogger.instance.t(e);
      // You can throw an exception here and catch it in the UI layer to
      // display a generic error message.
      throw Exception(
          'There was an issue while trying to log you in. Please try again.');
    }
  }

  Future<void> register(
      String email, String password, String username, String phone) async {
    try {
      final Map<String, String> registerData = {
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
      };

      final response = await AppHttpClient.post(
        registerUriPath,
        headers: {
          'Content-Type': 'application/json',
        },
        body: registerData,
      );

      if (response.statusCode == 200) {
        notifyListeners();
        //return user;
      } else {
        throw Exception(
            'Failed to register. Please check your credentials and try again.');
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authHeaderValue = prefs.getString('auth');

    // will log you out regardless
    final _ = await AppHttpClient.post(
      logoutUriPath,
      headers: {
        'Authorization': authHeaderValue ?? '',
      },
    );
    prefs.setString('auth', '');
    notifyListeners();
  }
}
