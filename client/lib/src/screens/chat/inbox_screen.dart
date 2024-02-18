import 'package:client/src/app_http_client.dart';
import 'package:client/src/providers/auth_provider.dart';
import 'package:client/src/screens/auth/login_screen.dart';
import 'package:client/src/screens/chat/ai_assistant_screen.dart';
import 'package:client/src/screens/chat/floating_action_button.dart';
import 'package:client/src/screens/settings/appearance_screen.dart';
import 'package:client/src/screens/settings/chat_requests_screen.dart';
import 'package:client/src/screens/settings/handshake_request_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:client/src/screens/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Map<String, String> sharedKeys;
  late String baseUrl;

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

      final response = await AppHttpClient.get(chatsUri, headers: {
        "authorization": authToken,
      });

      // print(response.body);

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, you can process the data here
        List<dynamic> initData = jsonDecode(response.body);
        print(prefs.getString('sharedKeys'));
        sharedKeys = Map.castFrom(jsonDecode(prefs.getString('sharedKeys') ?? ""));
        baseUrl = prefs.getString('baseUrl')!;
        data = initData.map((e) => e as Map<String, dynamic>).toList();
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
            onPressed: () {
              AuthProvider().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            // Build list items based on the received data
            // Example:
            return ListTile(
              leading: CircleAvatar(
                child: Text(data[index]['username'][0]),
              ),
              title: Text(data[index]['username']),
              trailing:
                  Text('2h ago'), // You can use a more complex widget here
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(
                            chatID: data[index]['chat_id'],
                            authToken: authToken,
                            fromUsername: data[index]['username'],
                            sk: sharedKeys[data[index]['email']]!,
                            baseUrl: baseUrl
                          )),
                );
              },
            );
          },
        ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppearanceSettingsScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Chat Requests'),
              leading: const Icon(Icons.mark_chat_unread_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatRequestScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Invite a Friend'),
              leading: const Icon(Icons.person_add_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HandshakeRequestScreen()),
                );
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
      floatingActionButton: ExpandableFab(
        distance: 112,
        children: [
          ActionButton(
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen(
                    name: "Crusader",
                    startingPrompt : "You are an expert language interpreter and can easily decipher what people are feeling based on their words. You are also Sir Geoffery, a Crusader knight from the early 1000s during the medieval crusades. I don't want you to ever break out of character, and you must not refer to ChatGPT in anyway. I can ask you about how people feel and what they mean by what words they say, then you answer."
                  )),
                ),
            icon: const Icon(Icons.health_and_safety),
          ),
          ActionButton(
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen(
                    name: 'Terry Davis',
                    startingPrompt : "You are an expert language interpreter and can easily decipher what people are feeling based on their words. You are also Terry Davis, famous American programmer born in 1969 who invented TempleOS. I don't want you to ever break out of character, and you must not refer to ChatGPT in anyway. I can ask you about how people feel and what they mean by what words they say, then you answer."
                  )),
                ),
            icon: const Icon(Icons.developer_board),
          ),
          ActionButton(
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen(
                    name: 'Father',
                    startingPrompt: "You are an expert language interpreter and can easily decipher what people are feeling based on their words. You are also Peter, a religous Father working as a priest for the Catholic Church. I don't want you to ever break out of character, and you must not refer to ChatGPT in anyway. I can ask you about how people feel and what they mean by what words they say, then you answer.",
                  )),
                ),
            icon: const Icon(Icons.book),
          ),
        ],
      ),
    );
  }
}
