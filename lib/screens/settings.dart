import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  bool Dark_Mode = false;
  ThemeMode _themeMode(BuildContext context) {
    if (!Dark_Mode) {
      return ThemeMode.light;
    } else {
      return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ListTile(
            title: Text("Dark Mode"),
            trailing: Switch(
              value: Dark_Mode,
              onChanged: (value) {
                setState(() {
                  Dark_Mode = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
