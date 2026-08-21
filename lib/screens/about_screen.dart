import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    AppVersion.get().then((value) {
      if (mounted) setState(() => _version = value);
    });
  }

  static final _website = Uri.parse('https://shahoriar.bd/');
  static final _github = Uri.parse('https://github.com/zaifears/locreminder');
  static final _email = Uri.parse('mailto:shahoriar.connect@gmail.com');
  static final _palestine =
      Uri.parse('https://revolutionarypapers.org/journal/free-palestine/');

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
                  _version == null ? 'Version…' : 'Version $_version',
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
                'It keeps watching in the background, so the alarm still fires '
                'when the app is closed, and uses OpenStreetMap for maps, so '
                'it needs no API keys or accounts.\n\n'
                'Free software with no Google services, no ads and no '
                'tracking. Your locations stay on your phone.',
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
                  leading: const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/shahoriar.png'),
                  ),
                  title: const Text('Shahoriar Hossain'),
                  subtitle: const Text('zaifears'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Website'),
                  subtitle: const Text('shahoriar.bd'),
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
                'LocReminder\'s source code is open source under the MIT '
                'licence. The app icon, logo and name remain © Shahoriar '
                'Hossain, all rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildPalestineBanner(context),
        ],
      ),
    );
  }

  /// The artwork is dark ink on a transparent background, so on a dark theme
  /// it would all but vanish against the surface behind it. Painting a light
  /// card underneath keeps it legible either way, and reads as a deliberate
  /// frame rather than an accident.
  Widget _buildPalestineBanner(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Free Palestine. Opens revolutionarypapers.org in your browser.',
      child: Material(
        color: const Color(0xFFF5F1EA),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, _palestine),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Image.asset(
              'assets/images/free_palestine.png',
              fit: BoxFit.contain,
              // Excluded from semantics because the Semantics wrapper above
              // already describes the whole tappable banner; announcing it
              // twice would just be noise for a screen reader.
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
