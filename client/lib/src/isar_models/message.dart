import 'package:isar/isar.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  int? chatId;
  String? recipient;

  @Index()
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