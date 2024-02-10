import 'dart:io';

import 'package:client/src/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class AppSupportDirectoryProvider extends ChangeNotifier {
  String _appSupportDirectoryPath = '';

  String get appSupportDirectoryPath => _appSupportDirectoryPath;

  AppSupportDirectoryProvider() {
    AppLogger.instance.i('AppSupportDirectoryProvider(): initialized');
    initAppSupportDirectory();
  }

  Future<void> initAppSupportDirectory() async {
    try {
      Directory appSupportDir = await getApplicationSupportDirectory();
      _appSupportDirectoryPath = appSupportDir.path;

      // http code

      // Check if keys.json exists
      String keysFilePath = '${appSupportDir.path}/keys.json';
      if (!File(keysFilePath).existsSync()) {
        // Create keys.json if it doesn't exist
        await _loadOrCreateKeysFile(keysFilePath);
        AppLogger.instance.i('The keys.json was was created.');
      } else {
        AppLogger.instance.i('The keys.json already existed, skipping...');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.instance.i(e);
      // Handle error
    }
  }

  Future<void> _loadOrCreateKeysFile(String filepath) async {
    Map<String, dynamic> defaultKeys = {
      'apiKey': 'your_api_key',
      'secretKey': 'your_secret_key',
      // Add other keys as needed
    };

    File file = File(filepath);
    await file.writeAsString(jsonEncode(defaultKeys));
  }
}