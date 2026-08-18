import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/native_bridge.dart';

/// Lets the user choose what the alarm actually sounds like — a system
/// ringtone or any audio file on the device — and whether it vibrates.
class AlarmSoundSection extends StatefulWidget {
  const AlarmSoundSection({super.key});

  @override
  State<AlarmSoundSection> createState() => _AlarmSoundSectionState();
}

class _AlarmSoundSectionState extends State<AlarmSoundSection> {
  final _nativeBridge = NativeBridge();

  String? _soundName;
  bool _vibrate = true;
  bool _loading = true;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Don't leave a preview playing after leaving the screen.
    if (_previewing) _nativeBridge.stopAlarmSoundPreview();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _nativeBridge.getAlarmSound();
    if (!mounted) return;
    setState(() {
      _soundName = settings['name'] as String?;
      _vibrate = (settings['vibrate'] as bool?) ?? true;
      _loading = false;
    });
  }

  Future<void> _pick(Future<Map<Object?, Object?>?> Function() picker) async {
    await _stopPreview();
    try {
      final picked = await picker();
      if (!mounted) return;
      // A null result means cancelled, or "Default" chosen in the system
      // picker — both leave us on the device's default alarm tone.
      setState(() => _soundName = picked?['name'] as String?);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the picker: ${e.message ?? e.code}')),
      );
    }
  }

  Future<void> _reset() async {
    await _stopPreview();
    await _nativeBridge.resetAlarmSound();
    if (!mounted) return;
    setState(() => _soundName = null);
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _stopPreview();
      return;
    }
    await _nativeBridge.previewAlarmSound();
    if (!mounted) return;
    setState(() => _previewing = true);
  }

  Future<void> _stopPreview() async {
    if (!_previewing) return;
    await _nativeBridge.stopAlarmSoundPreview();
    if (!mounted) return;
    setState(() => _previewing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.music_note, color: scheme.onPrimaryContainer),
            ),
            title: const Text('Alarm sound'),
            subtitle: Text(_soundName ?? 'Default alarm tone'),
            trailing: IconButton(
              tooltip: _previewing ? 'Stop' : 'Play',
              icon: Icon(_previewing ? Icons.stop_circle : Icons.play_circle),
              iconSize: 34,
              color: scheme.primary,
              onPressed: _togglePreview,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(_nativeBridge.pickAlarmRingtone),
                    icon: const Icon(Icons.library_music_outlined, size: 20),
                    label: const Text('Ringtones'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(_nativeBridge.pickAlarmAudioFile),
                    icon: const Icon(Icons.folder_open, size: 20),
                    label: const Text('My files'),
                  ),
                ),
              ],
            ),
          ),
          if (_soundName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Use the default alarm tone'),
              ),
            ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(Icons.vibration, color: scheme.onSurfaceVariant),
            ),
            title: const Text('Vibrate'),
            subtitle: const Text('Alongside the alarm sound'),
            value: _vibrate,
            onChanged: (value) async {
              setState(() => _vibrate = value);
              await _nativeBridge.setAlarmVibration(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plays on the alarm channel, so it sounds even when your '
                    'phone is on silent. If a chosen file is later deleted or '
                    'becomes unreadable, the default tone is used instead.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
