import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets/share_card.dart' show shareBackupFile;
import 'friend_roast_screen.dart' show LevelPicker;
import 'onboarding.dart';

class GoalsScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onEnableNotifications;
  final VoidCallback onTestNotification;
  final VoidCallback onSampleLoaded;
  const GoalsScreen({
    super.key,
    required this.state,
    required this.onEnableNotifications,
    required this.onTestNotification,
    required this.onSampleLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: '🎯 Times per week, per muscle',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final m in muscles)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
                child: Row(children: [
                  Text(m.icon),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m.name, style: boldStyle)),
                  _stepBtn(Icons.remove_rounded, () => s.setGoal(m.id, (s.goals[m.id] ?? 0) - 1)),
                  SizedBox(
                    width: 72,
                    child: Text(
                      (s.goals[m.id] ?? 0) == 0 ? 'off' : '${s.goals[m.id]}× / wk',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _stepBtn(Icons.add_rounded, () => s.setGoal(m.id, (s.goals[m.id] ?? 0) + 1)),
                ]),
              ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => s.setAllGoals(2), child: const Text('Set all to 2× / week')),
          ]),
        ),
        Panel(
          title: '🔥 Reminders & roasts',
          child: Column(children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Roast intensity', style: boldStyle)),
            const SizedBox(height: 8),
            LevelPicker(value: s.roastLevel, onChanged: s.setRoastLevel),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Text('Roast me after skipping a muscle for', style: boldStyle)),
              DropdownButton<int>(
                value: s.roastDays,
                dropdownColor: C.surface2,
                underline: const SizedBox.shrink(),
                items: [for (final d in [7, 10, 14, 21]) DropdownMenuItem(value: d, child: Text('$d days'))],
                onChanged: (v) => v == null ? null : s.setRoastDays(v),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Daily reminder at 7 PM', style: boldStyle),
                  Text('Nags you about incomplete muscles and roasts skipped ones — even when the app is closed.',
                      style: mutedStyle),
                ]),
              ),
              Switch(
                value: s.notify,
                activeTrackColor: C.accent,
                onChanged: (v) => v ? onEnableNotifications() : s.setNotify(false),
              ),
            ]),
            if (s.notify)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: onTestNotification, child: const Text('Send a test notification')),
              ),
          ]),
        ),
        Panel(
          title: 'Data',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                onPressed: () async {
                  if (s.workouts.isEmpty || await _confirm(context, 'Replace your data with sample data?')) {
                    s.loadSample();
                    onSampleLoaded();
                  }
                },
                child: const Text('Load sample data'),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await shareBackupFile(s.exportJson());
                  } catch (e) {
                    if (context.mounted) toast(context, "Couldn't export right now — try again");
                  }
                },
                child: const Text('Export backup'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: C.down, backgroundColor: Colors.transparent),
                onPressed: () async {
                  if (await _confirm(context, 'Delete ALL workouts and goals? This cannot be undone.')) {
                    s.reset();
                    if (context.mounted) await showOnboarding(context, s);
                  }
                },
                child: const Text('Reset everything'),
              ),
            ]),
            const SizedBox(height: 10),
            const Text('Everything is stored on this phone only.', style: mutedStyle),
          ]),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton.outlined(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(side: const BorderSide(color: C.line), backgroundColor: C.surface2),
          icon: Icon(icon, size: 18),
          onPressed: onTap,
        ),
      );

  Future<bool> _confirm(BuildContext context, String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: C.surface,
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
          ],
        ),
      ) ==
      true;
}
