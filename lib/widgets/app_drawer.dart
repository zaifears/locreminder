import 'package:flutter/material.dart';

import '../screens/about_screen.dart';
import '../screens/reliability_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LocReminder',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Never miss your stop',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Alarm reliability'),
                subtitle: const Text('Make sure it will ring'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReliabilityScreen()),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Map data © OpenStreetMap contributors',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
