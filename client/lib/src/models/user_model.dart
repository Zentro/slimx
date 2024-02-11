import 'package:flutter/material.dart';
import 'package:client/src/user.dart';

class UserModel extends ChangeNotifier {
  User? _user;

  User get user => _user!;

  set user(User value) {
    _user = value;

    // Notify 'Consumer<UserModel>'
    notifyListeners();
  }
}