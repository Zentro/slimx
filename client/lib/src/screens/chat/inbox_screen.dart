import 'package:flutter/material.dart';
// import 'package:fmr/src/screens/appearance_settings_screen.dart';
// import 'package:fmr/src/screens/privacy_settings_screen.dart';
import 'package:client/src/screens/chat/chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreen();
}

class _InboxScreen extends State<InboxScreen> {

  final List<String> emails = [
    'John Doe',
    'Jane Smith',
    'Alice Johnson',
    'Brotha #1',
    'Brotha #2',
    'Brotha #3',
    'crack dealer',
    'sidehoe 1',
    'sidehoe 2',
    'sidehoe 3',
    'secret sidehide',
    // Add more emails as needed
  ];

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Help'),
          content: Text('This is a small dialog.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Copy to clipboard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar (
        title: Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log out',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: emails.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(emails[index][0]),
            ),
            title: Text(emails[index]),
            subtitle: Text('Subject of the email'),
            trailing: Text('2h ago'), // You can use a more complex widget here
            onTap: () {
              // Handle tap on the email ROUTE TO IT
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
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