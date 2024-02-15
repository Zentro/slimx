import 'dart:convert';
import 'dart:io';

import 'package:client/src/app_http_client.dart';
import 'package:client/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
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

  Future<void> _acceptRequest(String email, int handshake_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth') ?? "";
    var currEmail = prefs.getString('currEmail') ?? "";
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

    Map<String, dynamic> keys = Map.castFrom(jsonDecode(prefs.getString('keys')!));
    String sIkPub = keys['ik_pub'];
    String sIkSec = keys['ik_sec']!;
    String sSpkSec = keys['spk_sec']!;
    String sPqpkSec;
    String sOpkSec;

    if (pqpkHash == null) {
      sPqpkSec = keys['pqspk_sec']!;
    } else {
      // They used a key from you, need to delete it after using
      keys['pqopk_map'] = Map.castFrom<String, dynamic, String, dynamic>(keys['pqopk_map']!);
      sPqpkSec = keys['pqopk_map'][pqpkHash][0];

      keys['pqopk_map'].remove(pqpkHash);
    }

    if (opkHash == null) {
      sOpkSec = "";
    } else {
      keys['opk_map'] = Map.castFrom<String, dynamic, String, dynamic>(keys['opk_map']!);
      sOpkSec = keys['opk_map'][opkHash][0];

      keys['opk_map'].remove(opkHash);
    }

    if (opkHash != null || pqpkHash != null) {
      var encodedKeys = jsonEncode(keys);
      prefs.setString('keys', encodedKeys);
      
      // Dump it back into the system
      File file = File(prefs.getString("filePath")!);
      
      var emailKeys = jsonDecode(file.readAsStringSync());
      var currEmail = prefs.getString('currEmail');
      emailKeys[currEmail!] = encodedKeys;
      file.writeAsStringSync(jsonEncode(emailKeys));
      print("Dump complete");
    }

    var secretKey = completeHandshake(
      handshake: response.body,
      sIkPub: sIkPub,
      sIkSec: sIkSec, 
      sSpkSec: sSpkSec, 
      sPqpkSec: sPqpkSec, 
      sOpkSec: sOpkSec
    );

    Map<String, String> secretKeys = Map.castFrom(jsonDecode(prefs.getString('secretKeys') ?? ""));
    secretKeys[email] = await secretKey;

    File sharedFile = File(prefs.getString('sharedPath')!);
    Map<String, String> sharedKeys = Map.castFrom(jsonDecode(sharedFile.readAsStringSync()));
    sharedKeys[currEmail] = jsonEncode(secretKeys);
    sharedFile.writeAsString(jsonEncode(sharedKeys));

    // Update our in memory prefs
    prefs.setString('secretKeys', sharedKeys[currEmail]!);

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
                            _acceptRequest(_pendingRequests[index]["email"], _pendingRequests[index]["handshake_id"]);
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
