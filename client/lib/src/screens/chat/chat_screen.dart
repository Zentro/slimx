import 'dart:convert';

import 'package:client/src/providers/chat_provider.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final int chatID;
  final String authToken;
  final String fromUsername;
  final String sk;
  final String baseUrl;
  final ChatProvider chatProvider;

  const ChatScreen(
      {Key? key,
      required this.chatID,
      required this.authToken,
      required this.fromUsername,
      required this.sk,
      required this.baseUrl,
      required this.chatProvider})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel _channel;
  late Stream<dynamic> _stream;
  final List<RawMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stream = _joinChat().asStream();
  }

  Future<void> _joinChat() async {
    List<Message> messages = await widget.chatProvider.joinChat(widget.chatID);
    for (var messageDetails in messages) {
      _messages.insert(
          0,
          RawMessage(
            text: decryptMessage(sSk: widget.sk, combined: messageDetails.msg!),
            sender: messageDetails.sender!,
            isMe: messageDetails.isMe!,
          ));
    }
    setState(() {
      _connectToWebSocket();
    });
  }

  void _connectToWebSocket() {
    Map<String, dynamic> headers = {
      'authorization': widget.authToken,
    };
    _channel = IOWebSocketChannel.connect(
      'ws://${widget.baseUrl}:8080/chat/${widget.chatID}',
      headers: headers,
    );
    _stream = _channel.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromUsername),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: _stream,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  // Handle case where there's no data yet
                  return const Center(
                    child: Text('No data available yet'),
                  );
                }

                List<dynamic> messages = List.castFrom(jsonDecode(snapshot.data.toString()));
                widget.chatProvider.addMessages(messages);
                for (var messageDetails in messages) {
                  _messages.insert(
                      0,
                      RawMessage(
                        text: decryptMessage(sSk: widget.sk, combined: messageDetails['msg'].cast<int>()),
                        sender: messageDetails['sender'],
                        isMe: messageDetails['isMe'],
                      ));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (_, int index) {
                    return ChatMessage(message: _messages[index]);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    var ct = encryptMessage(sSk: widget.sk, msg: text);
    Map<String, dynamic> message = {"text": ct, "sender": 'Me', "isMe": true};
    _channel.sink.add(jsonEncode(message));
  }

  @override
  void dispose() {
    // Close WebSocket connection when disposing the widget
    _channel.sink.close();
    widget.chatProvider.leaveChat();
    super.dispose();
  }
}

class RawMessage {
  final String text;
  final String sender;
  final bool isMe;

  RawMessage({required this.text, required this.sender, required this.isMe});

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender,
      'isMe': isMe,
    };
  }
}

class ChatMessage extends StatelessWidget {
  final RawMessage message;

  const ChatMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);
    final bool isMe = message.isMe;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.sender, style: const TextStyle(fontSize: 10)),
                Container(
                  margin: const EdgeInsets.only(top: 2.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isMe ? evenItemColor : oddItemColor,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Text(
                    message.text,
                    //style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
