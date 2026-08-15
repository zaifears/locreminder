import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final _website = Uri.parse('https://shahoriar.me');
  static final _github = Uri.parse('https://github.com/zaifears/locreminder');
  static final _email = Uri.parse('mailto:shahoriar.connect@gmail.com');

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 52,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text('LocReminder', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Version 1.1.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'A location-based alarm that wakes you when you approach your '
                'destination — so you can sleep on the bus without missing '
                'your stop.\n\n'
                'It uses Android\'s built-in geofencing, so the alarm still '
                'fires when the app is closed, and OpenStreetMap for maps, so '
                'it needs no API keys or accounts. Your locations stay on your '
                'phone.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DEVELOPER',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person, color: scheme.onPrimaryContainer),
                  ),
                  title: const Text('Shahoriar'),
                  subtitle: const Text('zaifears'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Website'),
                  subtitle: const Text('shahoriar.me'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(context, _website),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: const Text('github.com/zaifears/locreminder'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(context, _github),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Contact'),
                  subtitle: const Text('shahoriar.connect@gmail.com'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(context, _email),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CREDITS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Map data and search © OpenStreetMap contributors, available '
                'under the Open Database License.\n\n'
                'This project is released into the public domain — free to '
                'use, modify and share.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
