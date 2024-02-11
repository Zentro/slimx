import 'package:client/src/app_http_client.dart';
import 'package:client/src/screens/chat/ai_assistant_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:fmr/src/screens/appearance_settings_screen.dart';
// import 'package:fmr/src/screens/privacy_settings_screen.dart';
import 'package:client/src/screens/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreen();
}

class _InboxScreen extends State<InboxScreen> {
  late String authToken;
  bool isLoading = true; // always true
  final String chatsUri = 'inbox';
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth') ?? '';
    try {
      setState(() {
        isLoading = true; // Set loading state to true
      });

      final response = await AppHttpClient.get(
        chatsUri,
        headers: {
          "authorization": authToken,
        } // add headers
      );

      print(response.body);

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, you can process the data here
        final data = jsonDecode(response.body);
        // For example, you can print the data to the console
        print(data);
      } else {
        print("NOT WORKING");
        // If the server returns an error response, throw an exception
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // Catch any errors that occur during the process
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading state to false when request completes
      });
    }
  }

  final List<String> emails = [
    'Ai Buddy',
    'John Doe',
    'Jane Smith',
    'Alice Johnson',
  ];

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help'),
          content: const Text('Powered by SlimX.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Copy to clipboard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  bool isChatAiAssistant(String name) {
    return name == 'Ai Buddy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log out',
            onPressed: () {},
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (BuildContext context, int index) {
          // Build list items based on the received data
          // Example:
          return ListTile(
            title: Text(data[index]['username']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => isChatAiAssistant(emails[index])
                        ? const AiAssistantScreen()
                        : ChatScreen(
                            chatID: data[index]['chat_id'],
                            authToken: authToken,
                          )),
              );
            },
          );
        },
      ),
      // move this to a widget
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    child: Text('J'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Hello, John', // Replace 'John' with the actual username
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Privacy'),
              leading: const Icon(Icons.shield_outlined),
              onTap: () {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
                );*/
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              leading: const Icon(Icons.notifications_outlined),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Appearance'),
              leading: const Icon(Icons.palette_outlined),
              onTap: () {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppearanceSettingsScreen()),
                );*/
              },
            ),
            ListTile(
              title: const Text('Chat Requests'),
              leading: const Icon(Icons.mark_chat_unread_outlined),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Invite a Friend'),
              leading: const Icon(Icons.person_add_outlined),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Help'),
              leading: const Icon(Icons.info_outlined),
              onTap: () {
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
