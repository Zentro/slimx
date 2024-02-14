import 'package:client/src/screens/auth/register_screen.dart';
import 'package:client/src/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
// import 'package:client/src/rust/api/simple.dart';
import 'package:client/src/rust/frb_generated.dart';
import 'package:client/src/app_logger.dart';
import 'package:client/src/providers/auth_provider.dart';
import 'package:client/src/providers/app_support_directory_provider.dart';
import 'package:client/src/screens/auth/login_screen.dart';
import 'package:client/src/screens/chat/inbox_screen.dart';
import 'package:platform/platform.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const LocalPlatform platform = LocalPlatform();
  AppLogger.instance.i('''


 ___      _______  _______  ___   _______  _______ 
|   |    |   _   ||       ||   | |       ||   _   |
|   |    |  |_|  ||_     _||   | |    ___||  |_|  |
|   |    |       |  |   |  |   | |   |___ |       |
|   |___ |       |  |   |  |   | |    ___||       |
|       ||   _   |  |   |  |   | |   |    |   _   |
|_______||__| |__|  |___|  |___| |___|    |__| |__|

\n\n      By Rafael Galvan, Phuc Dang, Jeff Dong
\nDart: ${platform.version} 
Platform: ${platform.operatingSystem}
Hostname: ${platform.localHostname}
  ''');

  OpenAI.apiKey = 'nuhuh';
  OpenAI.showLogs = true;

  // todo: move this later
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('apiUrl', 'http://127.0.0.1:8080'); // Hard-coded default

  await RustLib.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppSupportDirectoryProvider())
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  final bool isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/inbox': (context) => const InboxScreen(),
        //'/chat': (context) => const ChatScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      theme: ThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
      home: Consumer2<AuthProvider, AppSupportDirectoryProvider>(
        builder: (context, authProvider, appSupportDirectoryProvider, _) {
          return authProvider.getAuthState
              ? const InboxScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
