import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:client/src/screens/auth/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:client/src/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String email = '';
  late String password = '';
  String err = '';

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (context, sizingInformation) {
      return Scaffold(body: Center(child: _build(sizingInformation)));
    });
  }

  Future<void> _login(AuthProvider authProvider) async {
    try {
      await authProvider.login(email, password);
      // Navigate to the next screen upon successful login
      // For example:
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextScreen()));
    } catch (e) {
      setState(() {
        err = e.toString();
        _showError(err);
      });
    }
  }

  void _showError(String err) {
    final snackBar = SnackBar(
      content: Text(err),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _build(SizingInformation sizingInformation) {
    if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
      return _buildDesktopScreen();
    } else if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
      return _buildTabletScreen();
    } else {
      return _buildMobileScreen();
    }
  }

  Widget _buildDesktopScreen() {
    return Container(
      child: Text('Desktop'),
    );
  }

  Widget _buildTabletScreen() {
    return Container(
      child: Text('Tablet'),
    );
  }

  Widget _buildMobileScreen() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoginForm(onFormSubmitted: (formEmail, formPassword) {
              setState(() {
                email = formEmail;
                password = formPassword;
              });
              // Safely access AuthProvider using Provider.of
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              // TODO: return user and notify changes
              _login(authProvider);
            })
          ]),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();

  final void Function(String, String) onFormSubmitted;
  const LoginForm({super.key, required this.onFormSubmitted});
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: [
          const SizedBox(
            height: 30,
          ),
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Email",
            ),
            controller: emailController,
            validator: (value) {
              // Do not allow an empty field or permit anything less than 3 characters
              if (value == null || value.isEmpty || value.length < 3) {
                return 'Enter an email or phone number';
              }
              // Regex validate if the email is real or not
              if (!_isValidEmail(value)) {
                return 'Enter a valid email or phone number';
              }
              // Passes validation
              return null;
            },
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Password",
            ),
            controller: passwordController,
            obscureText: true, // :3
            validator: (value) {
              if (value == null || value.isEmpty || value.length < 3) {
                return 'Enter a password';
              }
              return null;
            },
          ),
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Return email and password to the parent widget
                widget.onFormSubmitted(
                    emailController.text, passwordController.text);
              }
            },
            child: const Text("Login"),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // Handle "Forgot password" button press
                  print('Forgot password button pressed');
                },
                child: const Text('Forgot password'),
              ),
              const SizedBox(width: 16.0),
              TextButton(
                onPressed: () {
                  // Handle "Create account" button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Create account'),
              ),
            ],
          ),
        ]));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }
}