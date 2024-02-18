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

      File keysFile = File(keysFilePath);
      File sharedFile = File(sharedFilePath);

      // Make the shared keys file if it doesn't exist
      if (!sharedFile.existsSync()) {
        sharedFile.createSync();
        await sharedFile.writeAsString(jsonEncode(<String, String>{}));
        AppLogger.instance.i('The sharedKeys.json was created.');
      }

      // Load the shared keys file
      Map<String, String> emailSharedKeys = Map.castFrom(jsonDecode(await sharedFile.readAsString()));
      if (!emailSharedKeys.containsKey(email)) {
        emailSharedKeys[email] = jsonEncode(<String, String>{});
        sharedFile.writeAsStringSync(jsonEncode(emailSharedKeys));
      }

      // Make the keys file if it doesn't exist
      if (!keysFile.existsSync()) {
        keysFile.createSync();
        await keysFile.writeAsString(jsonEncode(<String, String>{}));
        AppLogger.instance.i('The userKeys.json was created.');
      }

      // Make keys and dump if they don't have keys
      Map<String, String> emailKeys = Map.castFrom(jsonDecode(await keysFile.readAsString()));
      if (generate && !emailKeys.containsKey(email)) {
        emailKeys[email] = generateKeys();
        // dump it out again to update
        keysFile.writeAsStringSync(jsonEncode(emailKeys));
      } else if (!emailKeys.containsKey(email)) {
        return;
      }

      // Set global values for key usage
      prefs.setString('userKeys', emailKeys[email]!);
      prefs.setString('keysFilePath', keysFilePath);
      prefs.setString('sharedKeys', emailSharedKeys[email]!);
      prefs.setString('sharedFilePath', sharedFilePath);
      prefs.setString('currEmail', email);

      notifyListeners();
    } catch (e) {
      AppLogger.instance.e(e);
      // Handle error
    }

    Future<void> unsetGlobalValues(SharedPreferences prefs) async {
      prefs.remove('userKeys');
      prefs.remove('keysFilePath');
      prefs.remove('sharedKeys');
      prefs.remove('sharedFilePath');
      prefs.remove('currEmail');
    }
  }
}
