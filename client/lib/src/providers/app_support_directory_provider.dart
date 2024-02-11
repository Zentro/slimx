import 'dart:io';

import 'package:client/src/app_logger.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // greet(name: "asd");

      // Check if userKeys.json exists
      String keysFilePath = '${appSupportDir.path}/userKeys.json';
      if (!File(keysFilePath).existsSync()) {
        // Create keys.json if it doesn't exist
        await _loadOrCreateKeysFile(keysFilePath);
        AppLogger.instance.i('The userKeys.json was was created.');
      } else {
        await _loadKeysFile(keysFilePath);
        AppLogger.instance.i('The userKeys.json already exists, skipping...');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.instance.e(e);
      // Handle error
    }
  }

  Future<void> _loadKeysFile(String filepath) async {
    File file = File(filepath);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('keys', await file.readAsString());
  }

  Future<void> _loadOrCreateKeysFile(String filepath) async {
    File file = File(filepath);

    var keys = generateKeys();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('keys', keys);

    await file.writeAsString(keys);
  }
}
