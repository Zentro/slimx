import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  late SharedPreferences _prefs;
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedThemeMode =
          ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index];
    });
  }

  void _savePreferences(ThemeMode themeMode) {
    _prefs.setInt('themeMode', themeMode.index);
    setState(() {
      _selectedThemeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              _savePreferences(value!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              _savePreferences(value!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              _savePreferences(value!);
            },
          ),
        ],
      ),
    );
  }
}
