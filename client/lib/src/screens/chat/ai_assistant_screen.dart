import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';

// todo: implement in rust to cache messages in memory
class Message {
  final String text;
  final String sender;
  final bool isMe;

  Message({required this.text, required this.sender, required this.isMe});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreen ();
}

class _AiAssistantScreen extends State<AiAssistantScreen> {
  final List<Message> _messages = [
    Message(text: 'hi', sender: 'Jane Doe', isMe: true),
    Message(text: 'please stop texting me....', sender: 'John Doe', isMe: false),
  ];
  final TextEditingController _textController = TextEditingController();
  late final String chatRoom;
  // final WebSocketChannel channel = IOWebSocketChannel.connect('ws://localhost:9000/ws');

  @override
  void initState() {
    super.initState();

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

  void _handleSubmitted(String text) {
    _textController.clear();
    Message message = Message(text: text, sender: 'User', isMe: true);
    List<OpenAIChatCompletionChoiceMessageModel> messageHistory = convertExistingHistory();
    messageHistory.add(formatMessage(message.isMe, message.text));

    // OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
    //   model: "gpt-3.5-turbo",
    //   seed: 6,
    //   messages: messageHistory,
    //   temperature: 0.2,
    // );

    setState(() {
      _messages.insert(0, message);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (_, int index) => ChatMessage(message: _messages[index]),
              itemCount: _messages.length,
            ),
          ),
          const Divider(height: 1.0),
          _buildTextComposer(),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final Message message;

  const ChatMessage({super.key, required this.message});

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