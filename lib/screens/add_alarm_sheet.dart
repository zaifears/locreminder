import 'package:flutter/material.dart';

class AddAlarmResult {
  const AddAlarmResult({required this.label, required this.radiusMeters});
  final String label;
  final double radiusMeters;
}

/// Bottom sheet for naming a destination and choosing its trigger radius,
/// shown after the user taps a point on the map.
class AddAlarmSheet extends StatefulWidget {
  const AddAlarmSheet({super.key});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();

  static Future<AddAlarmResult?> show(BuildContext context) {
    return showModalBottomSheet<AddAlarmResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddAlarmSheet(),
    );
  }
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  final _labelController = TextEditingController();
  double _radius = 500;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New destination alarm', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. Home, Bus stop, Office',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Alert radius', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${_radius.round()} m',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _radius,
            min: 100,
            max: 2000,
            divisions: 38,
            label: '${_radius.round()} m',
            onChanged: (value) => setState(() => _radius = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final label = _labelController.text.trim();
                Navigator.of(context).pop(
                  AddAlarmResult(
                    label: label.isEmpty ? 'Destination' : label,
                    radiusMeters: _radius,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Set alarm here'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
