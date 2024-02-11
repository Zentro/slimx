import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HandshakeRequestScreen extends StatefulWidget {
  const HandshakeRequestScreen({Key? key}) : super(key: key);

  @override
  State<HandshakeRequestScreen> createState() =>
      _HandshakeRequestScreenState();
}

class _HandshakeRequestScreenState extends State<HandshakeRequestScreen> {
  late TextEditingController _emailController;
  List<String> _pendingRequests = []; // List to store pending requests

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    // Load pending requests from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pendingRequests = prefs.getStringList('pendingRequests') ?? [];
    });
  }

  Future<void> _savePendingRequests() async {
    // Save pending requests to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pendingRequests', _pendingRequests);
  }

  void _addRequest(String email) {
    setState(() {
      _pendingRequests.add(email);
    });
    _savePendingRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite a Friend'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Enter Email',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _addRequest(_emailController.text);
                  _emailController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pending Requests:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
