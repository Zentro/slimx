import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  // final String chatID;
  // final String authToken;

  const AiAssistantScreen({Key? key, /*required this.chatID, required this.authToken*/}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late Stream<OpenAIStreamChatCompletionModel> chatStream;
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _connectToWebSocket();
  }

  OpenAIChatCompletionChoiceMessageModel formatMessage(bool isMe, String text) {
    return OpenAIChatCompletionChoiceMessageModel(
      role: isMe ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
      content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(text)]
    );
  }

  List<OpenAIChatCompletionChoiceMessageModel> convertExistingHistory(){
    List<OpenAIChatCompletionChoiceMessageModel> messageHistory = [];

    for (Message message in _messages) {
      messageHistory.add(formatMessage(message.isMe, message.text));
    }

    return messageHistory;
  }

  String extractMessage(String mess) {
    RegExp exp = RegExp(r'.*message": "(.*)".*');
    String result = exp.firstMatch(mess)![1]!;
    return result;
  }

  String getMessageFromRequest(AsyncSnapshot<OpenAIStreamChatCompletionModel> snapshot) {
    return snapshot.data!.choices.first.delta.content!.first.text!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: chatStream,
              builder: (BuildContext context, AsyncSnapshot<OpenAIStreamChatCompletionModel> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                String messageText = extractMessage(getMessageFromRequest(snapshot));

                _messages.add(Message(
                  text: messageText,
                  sender: "Buddy",
                  isMe: false,
                ));

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
    Message message = Message(text: text, sender: 'User', isMe: true);

    List<OpenAIChatCompletionChoiceMessageModel> messageHistory = convertExistingHistory();
    messageHistory.add(formatMessage(message.isMe, message.text));

    chatStream = OpenAI.instance.chat.createStream(
      model: "gpt-3.5-turbo",
      messages: messageHistory,
      seed: 423,
      n: 2,
    );

    _messages.insert(0, message);
  }
}

class Message {
  final String text;
  final String sender;
  final bool isMe;

  Message({required this.text, required this.sender, required this.isMe});

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender,
      'isMe': isMe,
    };
  }
}

class ChatMessage extends StatelessWidget {
  final Message message;

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
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.sender, style: const TextStyle(fontSize: 10)),
                Container(
                  margin: const EdgeInsets.only(top: 2.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isMe ? oddItemColor : evenItemColor,
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
