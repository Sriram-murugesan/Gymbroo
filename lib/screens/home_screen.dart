import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets/share_card.dart';
import 'friend_roast_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final void Function(String muscleId) onQuickLog;
  final VoidCallback onEnableNotifications;
  const HomeScreen({super.key, required this.state, required this.onQuickLog, required this.onEnableNotifications});

  @override
  Widget build(BuildContext context) {
    final t = todayStr(), ws = weekStartOf(t), st = state.weekStatus(ws);
    final left = 7 - daysBetween(ws, t);
    final pend = muscles.where((m) => st[m.id]!.done < st[m.id]!.goal).toList();
    final recent = state.recent(6);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Roasts ──
        for (final r in state.roasts)
          Panel(
            borderColor: C.roast,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [C.roast.withValues(alpha: .14), C.roast.withValues(alpha: .02)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${r.muscle.icon} ${r.muscle.name} · ${r.last != null ? 'last trained ${r.days} days ago' : 'not trained since you started'}'
                    .toUpperCase(),
                style: const TextStyle(color: C.roast, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6),
              ),
              const SizedBox(height: 6),
              Text(r.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => onQuickLog(r.muscle.id),
                    child: Text("Fine, I'll train ${r.muscle.name.toLowerCase()} 😤", overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Share this roast',
                  style: IconButton.styleFrom(side: const BorderSide(color: C.line), backgroundColor: C.surface2),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  onPressed: () => showShareCard(
                    context,
                    CardData(
                      kicker: '${r.muscle.icon} ${r.muscle.name} · ${r.days} days skipped',
                      stat: '${r.days} DAYS',
                      statLabel: 'without ${r.muscle.name.toLowerCase()} ${state.roastLevel.emoji}',
                      text: r.text,
                      shareText: '${r.text}\n\n— my gym app is roasting me 💀 #Gymbroo',
                    ),
                  ),
                ),
              ]),
            ]),
          ),

        // ── Roast a friend ──
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendRoastScreen(state: state))),
          child: const Panel(
            child: Row(children: [
              Text('🔥', style: TextStyle(fontSize: 26)),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Roast a friend', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('Someone skipping leg day? Make a roast card and send it to the group chat.', style: mutedStyle),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
        ),

        // ── Reminder ──
        if (pend.isNotEmpty)
          Panel(
            title: '⏰ Reminder',
            borderColor: C.accentDim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '$left day${left > 1 ? 's' : ''} left', style: const TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(text: ' this week. Still incomplete:'),
              ])),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final m in pend)
                  _chip(m, st[m.id]!, left, () => onQuickLog(m.id)),
              ]),
              if (!state.notify) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onEnableNotifications, child: const Text('🔔 Also remind me with notifications')),
              ],
            ]),
          )
        else
          const Panel(title: '✅ This week', child: Text('Every weekly goal smashed. Absolute unit. 🦍')),

        // ── Weekly goal ticks ──
        Panel(
          title: 'Weekly goals',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final m in muscles)
              if (st[m.id]!.goal > 0) _goalRow(m, st[m.id]!),
            const SizedBox(height: 10),
            const Text('Logged workouts tick automatically. Tap an empty box to tick a session without logging sets.',
                style: mutedStyle),
          ]),
        ),

        // ── Recent ──
        Panel(
          title: 'Recent',
          child: recent.isEmpty
              ? const Text('Nothing logged yet. Hit Log to add your first workout, or load sample data in Goals.',
                  style: mutedStyle)
              : Column(children: [
                  for (final w in recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${muscleById(w.muscle).icon} ${w.exercise}', style: boldStyle),
                            Text(setsText(w), style: mutedStyle),
                          ]),
                        ),
                        Text(fmtDate(w.date), style: mutedStyle),
                      ]),
                    ),
                ]),
        ),
      ],
    );
  }

  Widget _chip(Muscle m, MuscleWeek s, int left, VoidCallback onTap) {
    final need = s.goal - s.done;
    final late = need > left;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: C.surface2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: late ? C.down : C.line),
        ),
        child: Text('${m.icon} ${m.name} ${s.done}/${s.goal}${late ? ' · too late 😬' : ''}',
            style: TextStyle(fontSize: 13, color: late ? C.down : C.text)),
      ),
    );
  }

  Widget _goalRow(Muscle m, MuscleWeek s) {
    final boxes = <Widget>[];
    final total = s.goal > s.done ? s.goal : s.done;
    for (var i = 0; i < total; i++) {
      if (i < s.logged) {
        boxes.add(_tickBox(filled: true, checked: true));
      } else if (i < s.done) {
        boxes.add(_tickBox(filled: false, checked: true, onTap: () => state.untick(m.id)));
      } else {
        boxes.add(_tickBox(filled: false, checked: false, onTap: () => state.tick(m.id)));
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
      child: Row(children: [
        Text(m.icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: m.name, style: boldStyle),
            TextSpan(text: '  ${s.done}/${s.goal}', style: mutedStyle),
          ])),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: boxes),
      ]),
    );
  }

  Widget _tickBox({required bool filled, required bool checked, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? C.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: checked ? C.accent : C.line, width: 2),
          ),
          child: checked ? Icon(Icons.check_rounded, size: 20, color: filled ? Colors.white : C.accent) : null,
        ),
      );
}
