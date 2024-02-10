// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.24.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

///
///Generates all the needed keys for first time set up.
///It will then dump all of the keys in the client folder.
///The force argument will forcefully override all currently present
///keys in the client folder. Note that this will require a complete
///reupload of all keys to the server.
String generateKeys({dynamic hint}) =>
    RustLib.instance.api.generateKeys(hint: hint);

String greet({required String name, dynamic hint}) =>
    RustLib.instance.api.greet(name: name, hint: hint);
