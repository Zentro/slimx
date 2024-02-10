import 'package:client/src/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:client/src/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String email = '';
  String password = '';
  String username = '';
  String phone = '';

  // Super global errors
  String err = '';
  String sysErr = '';

  Future<void> _register(AuthProvider authProvider) async {
    try {
      await authProvider.register(email, password, username, phone);
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (context, sizingInformation) {
      return Scaffold(body: Center(child: _build(sizingInformation)));
    });
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
    return const Text('Desktop');
  }

  Widget _buildTabletScreen() {
    return const Text('Tablet');
  }

  Widget _buildMobileScreen() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RegisterForm(onFormSubmitted:
                (formEmail, formPassword, formPhone, formUsername) {
              setState(() {
                email = formEmail;
                password = formPassword;
                phone = formPhone;
                username = formUsername;
              });
              // Safely access AuthProvider using Provider.of
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              _register(authProvider);
            })
          ]),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  State<RegisterForm> createState() => _RegisterFormState();

  final void Function(String, String, String, String) onFormSubmitted;
  const RegisterForm({super.key, required this.onFormSubmitted});
}

class _RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
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
              labelText: "Username",
            ),
            validator: (value) {
              // Do not allow an empty field or permit anything less than 3 characters
              if (value == null || value.isEmpty || value.length < 3) {
                return 'Enter a username';
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
              labelText: "Phone",
            ),
            validator: (value) {
              // Do not allow an empty field or permit anything less than 3 characters
              if (value == null || value.isEmpty || value.length < 3) {
                return 'Enter a phone number';
              }
              if (!_isValidPhoneNumber(value)) {
                return 'Enter a valid phone numnber';
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
              labelText: "Email",
            ),
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
                    emailController.text,
                    passwordController.text,
                    phoneController.text,
                    usernameController.text);
              }
            },
            child: const Text("Register"),
          ),
          const SizedBox(
            height: 10,
          ),
          TextButton(
            onPressed: () {
              // Handle "Create account" button press
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('I already have an account'),
          ),
        ]));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    // A typical North American phone number regex pattern
    // Will accept patterns such as "123-456-7890", "(123) 456-7890",
    // "123.456.7890", or "1234567890".
    final RegExp phoneRegex = RegExp(
      r'^\D?(\d{3})\D?\D?(\d{3})\D?(\d{4})$',
    );
    return phoneRegex.hasMatch(phoneNumber);
  }
}
