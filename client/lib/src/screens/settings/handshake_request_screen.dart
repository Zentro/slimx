import 'dart:convert';
import 'dart:io';

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
    var currEmail = prefs.getString('currEmail') ?? "";

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
    var tup = await initHandshake(keyBundle: prekeyBundle, sIkPub: keys["ik_pub"], sIkSec: keys["ik_sec"]);
    
    String filledHandshake = tup!.$1;
    String secretKey = tup.$2;

    // Save this secret key to their email then dump the result back locally
    Map<String, String> secretKeys = Map.castFrom(jsonDecode(prefs.getString('secretKeys') ?? ""));
    secretKeys[email] = secretKey;
    print(secretKey);

    File sharedFile = File(prefs.getString('sharedPath')!);
    Map<String, String> sharedKeys = Map.castFrom(jsonDecode(sharedFile.readAsStringSync()));
    sharedKeys[currEmail] = jsonEncode(secretKeys);
    sharedFile.writeAsString(jsonEncode(sharedKeys));

    // Update our in memory prefs
    prefs.setString('secretKeys', sharedKeys[currEmail]!);

    // Send filled handshake back to the server
    final last = await AppHttpClient.put("handshakes", 
    headers: {
      "Content-Type": "application/json",
      "authorization": token,
    }, 
    body: jsonDecode(filledHandshake));

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
