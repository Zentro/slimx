import 'dart:convert';
import 'dart:io';

import 'package:client/src/app_logger.dart';
import 'package:client/src/isar_models/keys.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyProvider extends ChangeNotifier {
  final Isar _isar;
  
  Keys? _userKeys;
  Map<String, String>? _sharedKeys;

  late SharedPreferences _prefs;
  late String _sharedFilePath;

  String get ikSec => _userKeys!.ikSec!;
  String get ikPub => _userKeys!.ikPub!;
  String get spkSec => _userKeys!.spkSec!;
  String get spkPub => _userKeys!.spkPub!;
  String get pqspkSec => _userKeys!.pqspkSec!;
  String get pqspkPub => _userKeys!.pqspkPub!;
  String get keysJson => jsonEncode(_userKeys!);

  KeyProvider(this._isar) {
    AppLogger.instance.i('KeyProvider(): initialized');
    initKeyProvider();
  }

  Future<void> initKeyProvider() async {
    Directory appSupportDir = await getApplicationSupportDirectory();
    var path = appSupportDir.path;
    _prefs = await SharedPreferences.getInstance();

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
    // Keys for this email already exists
    if (!await _isar.keys.filter().emailEqualTo(email).isEmpty()) {
      return false;
    }

    // Dump into database
    await _isar.writeTxn(() async {
      _isar.keys.put(Keys.fromJson(jsonDecode(await generateKeys()), email));
    });

    // LOCAL IMPLEMENTATION
    File sharedFile = File(_sharedFilePath);
    // Make keys and dump if they don't have keys
    Map<String, String> emailSharedKeys =
        Map.castFrom(jsonDecode(await sharedFile.readAsString()));
    if (emailSharedKeys.containsKey(email)) {
      return false;
    }

    emailSharedKeys[email] = jsonEncode(<String, String>{});

    // dump it out again to update
    sharedFile.writeAsStringSync(jsonEncode(emailSharedKeys));

    return true;
  }

  /// Takes in an email and tries to set the global variables for keys
  /// 
  /// Fails if the user with email has not been initialized.
  Future<bool> setGlobalKeyValues(String email) async {
    try {
      File sharedFile = File(_sharedFilePath);
      Map<String, String> emailSharedKeys =
          Map.castFrom(jsonDecode(await sharedFile.readAsString()));

      String? jsonSharedKeys = emailSharedKeys[email];
      Keys? userKeys = await _isar.keys.filter().emailEqualTo(email).findFirst();

      if (userKeys == null || jsonSharedKeys == null) {
        return false;
      }
      _userKeys = userKeys;
      _sharedKeys = Map.castFrom(jsonDecode(jsonSharedKeys));

      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.instance.e(e);
      return false;
    }
  }

  /// Called on logout
  void logout() {
    _userKeys = null;
    _sharedKeys = null;
  }

  /// Pops the Opk pair from the user keys. 
  /// Also updates the on disk file.
  /// 
  /// Returns a tuple (sk, pk)
  Future<(String, String)> popOpkPair(String hash) async {
    return _isar.writeTxn(() async {
      var temp = _userKeys!.opkMap[hash]!;
      _userKeys!.opkMap.remove(hash);

      _isar.keys.put(_userKeys!);
      return (temp[0] as String, temp[1] as String);
    });
  }

  /// Pops the Pqopk pair from the user keys. 
  /// Also updates the on disk file.
  /// 
  /// Returns a tuple (sk, pk)
  Future<(String, String)> popPqopkPair(String hash) async {
    return _isar.writeTxn(() async {
      var temp = _userKeys!.pqopkMap[hash]!;
      _userKeys!.pqopkMap.remove(hash);

      _isar.keys.put(_userKeys!);
      return (temp[0] as String, temp[1] as String);
    });
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

  String getSharedKey(String email) {
    return _sharedKeys![email]!;
  }

  /// A function for easy debugging. Clears all stored data regarding keys.
  void debugCLEAR() {
    File sharedFile = File(_sharedFilePath);

    _isar.writeTxnSync(() {
      _isar.keys.clearSync();
    });
    sharedFile.writeAsString(jsonEncode(<String, String>{}));
  }
}
