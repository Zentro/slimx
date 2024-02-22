import 'package:client/src/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'chat_provider.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  int? chatId;
  String? recipient;

  int? created;
  String? sender;
  bool? isMe;
  List<int>? msg;

  void fromJson(Map<String, dynamic> json) {
    created = json['created'] as int;
    sender = json['sender'] as String;
    isMe = json['isMe'] as bool;
    msg = json['msg'].cast<int>();
  }
}

class ChatProvider extends ChangeNotifier {
  int? _chatId;
  String? _currEmail;

  late Isar _isar;

  ChatProvider() {
    AppLogger.instance.i("ChatProvider(): initialized");
    initChatProvider();
  }

  Future<void> initChatProvider() async {
    _chatId = null;
    _currEmail = null;
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open(
      [MessageSchema],
      directory: dir.path,
    );
  }

  Future<List<Message>> joinChat(int chatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _chatId = chatId;
    _currEmail = prefs.getString('currEmail')!;
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
}