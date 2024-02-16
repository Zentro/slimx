import 'dart:collection';
import 'dart:convert';
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
  }

  Future<void> setGlobalKeyValues(String email, bool generate) async {
    try {
      Directory appSupportDir = await getApplicationSupportDirectory();
      _appSupportDirectoryPath = appSupportDir.path;
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Open the keys file
      String keysFilePath = '${appSupportDir.path}/userKeys.json';
      String sharedFilePath = '${appSupportDir.path}/sharedKeys.json';

      File file = File(keysFilePath);
      File sharedFile = File(sharedFilePath);

      // Make the shared keys file if it doesn't exist
      if (!sharedFile.existsSync()) {
        sharedFile.createSync();
        await sharedFile.writeAsString(jsonEncode(<String, String>{}));
        AppLogger.instance.i('The sharedKeys.json was created.');
      }

      // Load the shared keys file
      Map<String, String> sharedKeys = Map.castFrom(jsonDecode(await sharedFile.readAsString()));
      if (!sharedKeys.containsKey(email)) {
        sharedKeys[email] = jsonEncode(<String, String>{});
        sharedFile.writeAsStringSync(jsonEncode(sharedKeys));
      }

      // Make the keys file if it doesn't exist
      if (!file.existsSync()) {
        file.createSync();
        await file.writeAsString(jsonEncode(<String, String>{}));
        AppLogger.instance.i('The userKeys.json was created.');
      }

      // Make keys and dump if they don't have keys
      Map<String, String> emailKeys = Map.castFrom(jsonDecode(await file.readAsString()));
      if (generate && !emailKeys.containsKey(email)) {
        emailKeys[email] = generateKeys();
        // dump it out again to update
        file.writeAsStringSync(jsonEncode(emailKeys));
      } else if (!emailKeys.containsKey(email)) {
        return;
      }

      // Set global values for key usage
      prefs.setString('keys', emailKeys[email]!);
      prefs.setString('filePath', keysFilePath);
      prefs.setString('secretKeys', sharedKeys[email]!);
      prefs.setString('sharedPath', sharedFilePath);
      prefs.setString('currEmail', email);

      notifyListeners();
    } catch (e) {
      AppLogger.instance.e(e);
      // Handle error
    }
  }
}
