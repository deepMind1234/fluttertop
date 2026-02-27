import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_manager.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeManager.themeMode == ThemeMode.dark,
            onChanged: (val) {
              themeManager.toggleTheme();
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Dashboard Preset',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('SysAdmin / Minimal'),
            subtitle: const Text('Focus on core metrics and raw process list.'),
            trailing: const Icon(Icons.check_circle, color: Colors.blue),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Gamer / GPU Mode (Coming Soon)'),
            subtitle: const Text(
              'Heavy focus on thermal, GPU, and per-core CPU usage.',
            ),
            trailing: const Icon(Icons.radio_button_unchecked),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
