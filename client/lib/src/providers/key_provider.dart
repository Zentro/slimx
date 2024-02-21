import 'dart:convert';
import 'dart:io';

import 'package:client/src/app_logger.dart';
import 'package:client/src/keys.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyProvider extends ChangeNotifier {
  Keys? _userKeys;
  Map<String, String>? _sharedKeys;

  late SharedPreferences _prefs;
  late String _keysFilePath;
  late String _sharedFilePath;

  String get ikSec => _userKeys!.ikSec;
  String get ikPub => _userKeys!.ikPub;
  String get spkSec => _userKeys!.spkSec;
  String get spkPub => _userKeys!.spkPub;
  String get pqspkSec => _userKeys!.pqspkSec;
  String get pqspkPub => _userKeys!.pqspkPub;
  String get keysJson => jsonEncode(_userKeys!);

  KeyProvider() {
    AppLogger.instance.i('AppSupportDirectoryProvider(): initialized');
    initKeyProvider();
  }

  Future<void> initKeyProvider() async {
    Directory appSupportDir = await getApplicationSupportDirectory();
    var path = appSupportDir.path;
    _prefs = await SharedPreferences.getInstance();

    _keysFilePath = '$path/userKeys.json';
    File keysFile = File(_keysFilePath);
    // Make the keys file if it doesn't exist
    if (!keysFile.existsSync()) {
      keysFile.createSync();
      await keysFile.writeAsString(jsonEncode(<String, String>{}));
      AppLogger.instance.i('The userKeys.json was created.');
    }

    _sharedFilePath = '$path/sharedKeys.json';
    File sharedFile = File(_sharedFilePath);
    // Make the shared keys file if it doesn't exist
    if (!sharedFile.existsSync()) {
      sharedFile.createSync();
      await sharedFile.writeAsString(jsonEncode(<String, String>{}));
      AppLogger.instance.i('The sharedKeys.json was created.');
    }
  }

  /// Generates keys associated with this email.
  /// Also inits for it a field in the sharedKeys file.
  ///
  /// Returns false if the user already has keys generated
  Future<bool> generateKeysForEmail(String email) async {
    File keysFile = File(_keysFilePath);
    File sharedFile = File(_sharedFilePath);
    // Make keys and dump if they don't have keys
    Map<String, String> emailKeys =
        Map.castFrom(jsonDecode(await keysFile.readAsString()));
    Map<String, String> emailSharedKeys =
        Map.castFrom(jsonDecode(await sharedFile.readAsString()));
    if (emailKeys.containsKey(email) || emailSharedKeys.containsKey(email)) {
      return false;
    }

    emailKeys[email] = generateKeys();
    emailSharedKeys[email] = jsonEncode(<String, String>{});

    // dump it out again to update
    keysFile.writeAsStringSync(jsonEncode(emailKeys));
    sharedFile.writeAsStringSync(jsonEncode(emailSharedKeys));

    return true;
  }

  /// Takes in an email and tries to set the global variables for keys
  /// 
  /// Fails if the user with email has not been initialized.
  Future<bool> setGlobalKeyValues(String email) async {
    try {
      File keysFile = File(_keysFilePath);
      File sharedFile = File(_sharedFilePath);
      Map<String, String> emailKeys =
          Map.castFrom(jsonDecode(await keysFile.readAsString()));
      Map<String, String> emailSharedKeys =
          Map.castFrom(jsonDecode(await sharedFile.readAsString()));

      String? jsonUserKeys = emailKeys[email];
      String? jsonSharedKeys = emailSharedKeys[email];

      if (jsonUserKeys == null || jsonSharedKeys == null) {
        return false;
      }

      _userKeys = Keys.fromJson(jsonDecode(jsonUserKeys));
      _sharedKeys = Map.castFrom(jsonDecode(jsonSharedKeys));

      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.instance.e(e);
      return false;
    }
  }

  /// Pops the Opk pair from the user keys.
  /// 
  /// Also updates the on disk file.
  (String, String) popOpkPair(String hash) {
    var temp = _userKeys!.opkMap[hash]!;
    _userKeys!.opkMap.remove(hash);

    _dumpKeys();
    return (temp[0] as String, temp[1] as String);
  }

  /// Pops the Pqopk pair from the user keys.
  /// 
  /// Also updates the on disk file.
  (String, String) popPqopkPair(String hash) {
    var temp = _userKeys!.pqopkMap[hash]!;
    _userKeys!.pqopkMap.remove(hash);

    _dumpKeys();
    return (temp[0] as String, temp[1] as String);
  }

  String getSharedKey(String email) {
    return _sharedKeys![email]!;
  }

  /// Associate this email with this shared key.
  Future<void> setSharedKey(String email, String sk) async {
    File sharedFile = File(_sharedFilePath);
    var currEmail = _prefs.getString('currEmail')!;
    _sharedKeys![email] = sk;
    
    Map<String, String> emailSharedKeys = Map.castFrom(jsonDecode(sharedFile.readAsStringSync()));
    emailSharedKeys[currEmail] = jsonEncode(_sharedKeys);
    sharedFile.writeAsString(jsonEncode(emailSharedKeys));
  }

  /// Called on logout
  void logout() {
    _userKeys = null;
    _sharedKeys = null;
  }
  
  /// Dumps the current state of the keys in memory
  /// into the keys file.
  void _dumpKeys() {
    File keysFile = File(_keysFilePath);
    var emailKeys = jsonDecode(keysFile.readAsStringSync());
    var currEmail = _prefs.getString('currEmail')!;
    emailKeys[currEmail] = jsonEncode(_userKeys);
    keysFile.writeAsStringSync(jsonEncode(emailKeys));
  }
}
