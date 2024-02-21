import 'dart:convert';
import 'dart:io';

import 'package:client/src/app_http_client.dart';
import 'package:client/src/keys.dart';
import 'package:client/src/providers/key_provider.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRequestScreen extends StatefulWidget {
  const ChatRequestScreen({Key? key}) : super(key: key);

  @override
  State<ChatRequestScreen> createState() => _ChatRequestScreen();
}

class _ChatRequestScreen extends State<ChatRequestScreen> {
  List<Map<String, dynamic>> _pendingRequests =
      []; // List to store pending requests

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth') ?? "";
    final response = await AppHttpClient.get(
      'pending',
      headers: {
        "authorization": token,
        //"email": email,
      },
    );

    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> initData = jsonDecode(response.body);
      // For example, you can print the data to the console
      // print(initData);
      setState(() {
        _pendingRequests =
            initData.map((e) => e as Map<String, dynamic>).toList();
      });
    } else {
      print(response.statusCode);
      print("^^^^^^^^FAILED TO FETCH PENDING REQUESTS");
    }
  }

  Future<void> _acceptRequest(String email, int handshake_id, KeyProvider keyProvider) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth') ?? "";
    print(handshake_id);
    final response = await AppHttpClient.post(
      'complete',
      headers: {
        "authorization": token,
        "handshake_id": "$handshake_id",
      }
    );
    if (response.statusCode != 200) {
      print(response.statusCode);
      print("^^^^^^^^^ FAILED TO APPROVE REQUEST");
    }

    var handshake = jsonDecode(response.body);
    String? pqpkHash = handshake['pqpk_hash'];
    String? opkHash = handshake['opk_hash'];

    String sIkPub = keyProvider.ikPub;
    String sIkSec = keyProvider.ikSec;
    String sSpkSec = keyProvider.spkSec;
    String sPqpkSec;
    String sOpkSec;
    
    if (pqpkHash == null) {
      sPqpkSec = keyProvider.pqspkSec;
    } else {
      // They used a key from you, need to delete it after using
      var pqopkPair = await keyProvider.popPqopkPair(pqpkHash);
      sPqpkSec = pqopkPair.$1;
    }

    if (opkHash == null) {
      sOpkSec = "";
    } else {
      var opkPair = await keyProvider.popOpkPair(opkHash);
      sOpkSec = opkPair.$1;
    }
    
    var sk = await completeHandshake(
      handshake: response.body,
      sIkPub: sIkPub,
      sIkSec: sIkSec, 
      sSpkSec: sSpkSec, 
      sPqpkSec: sPqpkSec, 
      sOpkSec: sOpkSec
    );

    keyProvider.setSharedKey(email, sk);

    setState(() {
      _pendingRequests.removeWhere((request) => request['email'] == email);
    });
  }

  Future<void> _denyRequest() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Requests'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingRequests,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_pendingRequests[index]["email"]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            // Handle accepting the chat request
                            final keyProvider = Provider.of<KeyProvider>(context, listen: false);
                            _acceptRequest(
                              _pendingRequests[index]["email"], 
                              _pendingRequests[index]["handshake_id"],
                              keyProvider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            // Handle denying the chat request
                            _denyRequest();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
