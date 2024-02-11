import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRequestScreen extends StatefulWidget {
  const ChatRequestScreen({Key? key}) : super(key: key);

  @override
  State<ChatRequestScreen> createState() => _ChatRequestScreen();
}

class _ChatRequestScreen extends State<ChatRequestScreen> {
  List<String> _pendingRequests = []; // List to store pending requests

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    // Load pending requests from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pendingRequests = prefs.getStringList('pendingRequests') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Requests'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_pendingRequests[index]),
                  // Additional features like cancel request can be added here
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
