import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import 'friend_roast_screen.dart' show LevelPicker;

/// First-launch popup: "Set your goals, broo". Can't be dismissed without saving.
Future<void> showOnboarding(BuildContext context, AppState state) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OnboardingDialog(state: state),
    );

class _OnboardingDialog extends StatefulWidget {
  final AppState state;
  const _OnboardingDialog({required this.state});

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _Preset {
  final String label, emoji;
  final int times;
  const _Preset(this.label, this.emoji, this.times);
}

const _presets = [
  _Preset('Beginner', '🌱', 1),
  _Preset('Regular', '💪', 2),
  _Preset('Beast', '🦍', 3),
];

class _OnboardingDialogState extends State<_OnboardingDialog> {
  late final Map<String, int> goals = {for (final m in muscles) m.id: widget.state.goals[m.id] ?? 2};
  late RoastLevel level = widget.state.roastLevel;

  int? get _activePreset {
    final v = goals.values.toSet();
    return v.length == 1 ? v.first : null;
  }

  void _save() {
    if (goals.values.every((g) => g == 0)) {
      toast(context, 'Pick at least one muscle, broo 😅');
      return;
    }
    widget.state.completeOnboarding(goals, level);
    Navigator.pop(context);
    toast(context, "Goals set. Let's get it, broo 🔥");
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: C.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: C.accentDim),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                // ── Header ──
                const Text.rich(TextSpan(
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
                  children: [TextSpan(text: 'WELCOME TO GYM'), TextSpan(text: 'BROO', style: TextStyle(color: C.accent))],
                )),
                const SizedBox(height: 10),
                const Text('Set your goals, broo 💪',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 6),
                const Text(
                  "How many times a week do you want to hit each muscle? Skip one too long and you'll get roasted.",
                  style: TextStyle(color: C.muted, height: 1.4),
                ),

                // ── Presets ──
                const SizedBox(height: 16),
                Row(children: [
                  for (final p in _presets)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: p == _presets.last ? 0 : 6),
                        child: _presetButton(p),
                      ),
                    ),
                ]),

                // ── Per-muscle ──
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    for (final m in muscles) _muscleRow(m),
                  ]),
                ),

                // ── Roast level ──
                const SizedBox(height: 16),
                const Text('How should we roast you?', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                LevelPicker(value: level, onChanged: (l) => setState(() => level = l)),

                // ── Go ──
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _save,
                    child: const Text("Let's go, broo 🔥", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('You can change this anytime in Goals.', style: mutedStyle)),
              ]),
            ),
          ),
        ),
      );

  Widget _presetButton(_Preset p) {
    final on = _activePreset == p.times;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        for (final m in muscles) {
          goals[m.id] = p.times;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? C.accent : C.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? C.accent : C.line),
        ),
        child: Column(children: [
          Text(p.emoji, style: const TextStyle(fontSize: 20)),
          Text(p.label,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: on ? Colors.white : C.text)),
          Text('${p.times}× / week',
              style: TextStyle(fontSize: 11, color: on ? Colors.white70 : C.muted)),
        ]),
      ),
    );
  }

  Widget _muscleRow(Muscle m) {
    final g = goals[m.id] ?? 0;
    Widget btn(IconData icon, int delta) => SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(backgroundColor: C.surface, side: const BorderSide(color: C.line)),
            icon: Icon(icon, size: 16),
            onPressed: () => setState(() => goals[m.id] = (g + delta).clamp(0, 7)),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(m.icon),
        const SizedBox(width: 10),
        Expanded(child: Text(m.name, style: boldStyle)),
        btn(Icons.remove_rounded, -1),
        SizedBox(
          width: 64,
          child: Text(g == 0 ? 'skip' : '$g× / wk',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: g == 0 ? C.muted : C.text)),
        ),
        btn(Icons.add_rounded, 1),
      ]),
    );
  }
}
