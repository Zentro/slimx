import 'dart:convert';

import 'package:client/src/app_http_client.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HandshakeRequestScreen extends StatefulWidget {
  const HandshakeRequestScreen({Key? key}) : super(key: key);

  @override
  State<HandshakeRequestScreen> createState() => _HandshakeRequestScreenState();
}

class _HandshakeRequestScreenState extends State<HandshakeRequestScreen> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    //_loadPendingRequests();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Future<void> _loadPendingRequests() async {
  //   // Load pending requests from SharedPreferences
  // }

  Future<void> _savePendingRequests(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth') ?? "";
    var keys = jsonDecode(prefs.getString('keys') ?? "");
    // Save pending requests to SharedPreferences
    final response = await AppHttpClient.post(
      "handshakes",
      headers: {
        "authorization": token,
        "email": email,
      },
    );

    print(response.statusCode);

    var prekey_bundle = response.body;

    var filled_handshake = await initHandshake(keyBundle: prekey_bundle, sIkPub: keys["ik_pub"], sIkSec: keys["ik_sec"]);
    
    final last = await AppHttpClient.put("handshakes", 
    headers: {
      "Content-Type": "application/json",
      "authorization": token,
    }, 
    body: jsonDecode(filled_handshake!));

    print(last.statusCode);
  }

  void _addRequest(String email) {
    _savePendingRequests(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite a Friend'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
