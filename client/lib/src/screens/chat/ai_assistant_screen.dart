import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  // final String chatID;
  // final String authToken;
  final String startingPrompt;
  final String name;

  const AiAssistantScreen({Key? key, required this.startingPrompt, required this.name}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late Future<OpenAIChatCompletionModel> test;
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeModel();
  }

  void initializeModel() {
    //_messages.add(Message(text: 'You are a friendly assistant. You know lots of fun facts and are estatic to share them with the world.', sender: 'Buddy', isMe: false));
    // _handleSubmitted('Hello there! How are you Today?');
    _messages.add(Message(text: widget.startingPrompt, sender: widget.name, isMe: false));
    _messages.add(Message(text: 'Say a greeting and introduce yourself.', sender: 'User', isMe: true));
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

  String getMessageFromRequest(AsyncSnapshot<OpenAIChatCompletionModel> snapshot) {
    return snapshot.data!.choices.first.message.content!.first.text!;
  }

  @override
  Widget build(BuildContext context) {

    List<OpenAIChatCompletionChoiceMessageModel> messageHistory = convertExistingHistory();
    Future<OpenAIChatCompletionModel> chatCompletion = OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo-0125",
      // seed: 6,
      messages: messageHistory,
      temperature: 0.5,
      // toolChoice: "auto",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: FutureBuilder<OpenAIChatCompletionModel>(
              future: chatCompletion,
              builder: (BuildContext context, AsyncSnapshot<OpenAIChatCompletionModel> snapshot) {
                if(snapshot.hasData || (snapshot.hasError && snapshot.error.toString().contains("Rate limit reached"))) {
      
                  String messageText = "Woah there! Please wait a little bit before you ask me again and wait around 20 seconds. Thanks!";
                  if (snapshot.hasData) {
                    messageText = getMessageFromRequest(snapshot);
                  }

                  if (messageText != _messages[_messages.length-2].text) {
                    _messages.add(Message(
                      text: messageText,
                      sender: widget.name,
                      isMe: false,
                    ));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length-2,
                    itemBuilder: (_, int index) {
                      return ChatMessage(message: _messages[_messages.length - index - 1]);
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
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

  void _handleSubmitted(String text) async {
    _textController.clear();
    Message message = Message(text: text, sender: 'User', isMe: true);
    _messages.add(message);
    setState(() {});
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
