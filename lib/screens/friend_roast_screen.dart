import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets/share_card.dart';

/// Build a roast for a friend and share it to WhatsApp / Instagram.
class FriendRoastScreen extends StatefulWidget {
  final AppState state;
  const FriendRoastScreen({super.key, required this.state});

  @override
  State<FriendRoastScreen> createState() => _FriendRoastScreenState();
}

class _FriendRoastScreenState extends State<FriendRoastScreen> {
  final nameCtrl = TextEditingController();
  String muscle = 'legs';
  int days = 14;
  late RoastLevel level = widget.state.roastLevel;
  int variant = 0;

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    if (s.friendNames.isNotEmpty) nameCtrl.text = s.friendNames.first;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  String get name => nameCtrl.text.trim().isEmpty ? 'Your friend' : nameCtrl.text.trim();

  String get roastText {
    final lines = friendRoasts[level]!;
    return fillRoast(
      lines[variant % lines.length],
      name: name,
      muscle: muscleById(muscle).name.toLowerCase(),
      d: days,
      burn: muscleBurns[muscle],
    );
  }

  Future<void> _share() async {
    if (nameCtrl.text.trim().isEmpty) return toast(context, "Who are we roasting? Add your friend's name");
    s.rememberFriend(nameCtrl.text);
    final m = muscleById(muscle);
    await showShareCard(
      context,
      CardData(
        kicker: '${m.icon} ${name.toUpperCase()} · ${m.name.toUpperCase()} · $days DAYS SKIPPED',
        stat: '$days DAYS',
        statLabel: 'without ${m.name.toLowerCase()} ${level.emoji}',
        text: roastText,
        shareText: '$roastText\n\n— roasted with Gymbroo 🔥',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Roast a friend 🔥', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListenableBuilder(
          listenable: s,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                title: 'Who skipped?',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: nameCtrl,
                    maxLength: maxFriendName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: "Friend's name, e.g. Rahul", counterText: ''),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (s.friendNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final f in s.friendNames)
                        InputChip(
                          label: Text(f),
                          backgroundColor: C.surface2,
                          side: const BorderSide(color: C.line),
                          onPressed: () => setState(() => nameCtrl.text = f),
                          onDeleted: () => s.forgetFriend(f),
                        ),
                    ]),
                  ],
                ]),
              ),
              Panel(
                title: 'What did they skip?',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final m in muscles)
                      ChoiceChip(
                        label: Text('${m.icon} ${m.name}'),
                        selected: m.id == muscle,
                        showCheckmark: false,
                        selectedColor: C.accent,
                        backgroundColor: C.surface2,
                        side: BorderSide(color: m.id == muscle ? C.accent : C.line),
                        labelStyle: TextStyle(color: m.id == muscle ? Colors.white : C.text, fontSize: 13),
                        shape: const StadiumBorder(),
                        onSelected: (_) => setState(() => muscle = m.id),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Text('For', style: boldStyle),
                    Expanded(
                      child: Slider(
                        value: days.toDouble(),
                        min: 3,
                        max: 60,
                        divisions: 57,
                        activeColor: C.accent,
                        label: '$days days',
                        onChanged: (v) => setState(() => days = v.round()),
                      ),
                    ),
                    SizedBox(width: 64, child: Text('$days days', textAlign: TextAlign.right, style: boldStyle)),
                  ]),
                ]),
              ),
              Panel(
                title: 'How hard?',
                child: LevelPicker(value: level, onChanged: (l) => setState(() => level = l)),
              ),
              Panel(
                title: 'Preview',
                borderColor: C.roast,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(roastText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => variant++),
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Another one'),
                  ),
                ]),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _share,
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Make roast card'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Share the card to WhatsApp, Instagram or anywhere. Friends are saved on this phone only.',
                style: mutedStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

/// Three-way Gentle / Sergeant / No mercy selector.
class LevelPicker extends StatelessWidget {
  final RoastLevel value;
  final ValueChanged<RoastLevel> onChanged;
  const LevelPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (final l in RoastLevel.values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: l == RoastLevel.values.last ? 0 : 6),
                child: InkWell(
                  onTap: () => onChanged(l),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: l == value ? C.accent : C.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: l == value ? C.accent : C.line),
                    ),
                    child: Column(children: [
                      Text(l.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                        l.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: l == value ? Colors.white : C.text,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Text(value.blurb, style: mutedStyle),
      ]);
}
