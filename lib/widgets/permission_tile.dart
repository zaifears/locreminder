import 'package:flutter/material.dart';

class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onRequest,
    this.buttonLabel = 'Allow',
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onRequest;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: granted ? scheme.primaryContainer : scheme.surfaceContainerHighest,
              child: Icon(
                granted ? Icons.check : icon,
                color: granted ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (!granted) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: onRequest, child: Text(buttonLabel)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
