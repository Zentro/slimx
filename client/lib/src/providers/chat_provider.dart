import 'package:client/src/app_logger.dart';
import 'package:client/src/isar_models/message.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  final Isar _isar;

  int? _chatId;
  String? _currEmail;

  ChatProvider(this._isar) {
    AppLogger.instance.i("ChatProvider(): initialized");
    initChatProvider();
  }

  Future<void> initChatProvider() async {
    _chatId = null;
    _currEmail = null;
  }

  Future<List<Message>> joinChat(int chatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _chatId = chatId;
    _currEmail = prefs.getString('currEmail')!;
    // This jank is solely because the database has to deal with possible more than
    // 1 user on the same computer and they are talking to each other.
    // Will likely make it so that you can only have one account to a device.
    // Ideally chat info is also stored locally and messages are associated only with
    // chat_id rather than also with recipient.
    var messages = _isar.messages.filter()
      .chatIdEqualTo(_chatId)
      .and()
      .recipientEqualTo(_currEmail)
      .sortByCreated()
      .findAll();
    return messages;
  }

  void leaveChat() {
    _chatId = null;
    _currEmail = null;
  }

  bool addMessages(List<dynamic> messages) {
    if (_chatId == null) {
      return false;
    }
    List<Message> toAdd = [];
    for (var message in messages) {
      var newMessage = Message();
      newMessage.fromJson(message);
      newMessage.chatId = _chatId;
      newMessage.recipient = _currEmail;
      toAdd.add(newMessage);
    }

    _isar.writeTxnSync(() {
      _isar.messages.putAllSync(toAdd);
    });
    return true;
  }

  /// Clears everything in the database.
  void debugCLEAR() {
    _isar.writeTxnSync(() {
      _isar.messages.clearSync();
    });
  }
}