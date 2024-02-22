import 'dart:convert';

import 'package:client/src/app_http_client.dart';
import 'package:client/src/providers/key_provider.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> _savePendingRequests(String email, KeyProvider keyProvider) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth') ?? "";

    // Save pending requests to SharedPreferences
    final response = await AppHttpClient.post(
      "handshakes",
      headers: {
        "authorization": token,
        "email": email,
      },
    );

    if (response.statusCode != 201) {
      return;
    }
    
    var prekeyBundle = response.body;
    var tup = await initHandshake(keyBundle: prekeyBundle, sIkPub: keyProvider.ikPub, sIkSec: keyProvider.ikSec);
    
    String filledHandshake = tup!.$1;
    String sk = tup.$2;

    // Save this secret key to their email
    await keyProvider.setSharedKey(email, sk);

    // Send filled handshake back to the server
    final last = await AppHttpClient.put("handshakes", 
    headers: {
      "Content-Type": "application/json",
      "authorization": token,
    }, 
    body: jsonDecode(filledHandshake));

    print(last.statusCode);
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
                    final keyProvider = Provider.of<KeyProvider>(context, listen: false);
                    _savePendingRequests(_emailController.text, keyProvider);
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
