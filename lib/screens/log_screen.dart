import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets/share_card.dart';

const _custom = '__custom';

class _SetRow {
  final w = TextEditingController();
  final r = TextEditingController();
  void dispose() {
    w.dispose();
    r.dispose();
  }
}

class LogScreen extends StatefulWidget {
  final AppState state;
  final String initialMuscle;
  const LogScreen({super.key, required this.state, required this.initialMuscle});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late String date = todayStr();
  late String muscle = widget.initialMuscle;
  late String exercise = exerciseLibrary[muscle]!.first;
  final customCtrl = TextEditingController();
  List<_SetRow> rows = List.generate(3, (_) => _SetRow());

  AppState get s => widget.state;

  @override
  void dispose() {
    customCtrl.dispose();
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  String get exName => exercise == _custom ? customCtrl.text.trim() : exercise;

  void _resetRows([int n = 3]) {
    for (final r in rows) {
      r.dispose();
    }
    rows = List.generate(n, (_) => _SetRow());
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: parseYmd(date),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (d != null) setState(() => date = ymd(d));
  }

  void _copyLast(Workout last) {
    setState(() {
      _resetRows(last.sets.length);
      for (var i = 0; i < last.sets.length; i++) {
        rows[i].w.text = last.sets[i].w > 0 ? fmtNum(last.sets[i].w) : '';
        rows[i].r.text = '${last.sets[i].r}';
      }
    });
  }

  void _save() {
    final ex = exName;
    if (ex.isEmpty) return toast(context, 'Give your exercise a name first');
    final sets = rows
        .map((r) => WorkoutSet(
              (double.tryParse(r.w.text.replaceAll(',', '.')) ?? 0).clamp(0, 1000).toDouble(),
              (int.tryParse(r.r.text) ?? 0).clamp(0, 1000),
            ))
        .where((x) => x.r > 0)
        .toList();
    if (sets.isEmpty) return toast(context, 'Add at least one set with reps');
    final pr = s.addWorkout(date, muscle, ex, sets);
    FocusScope.of(context).unfocus();
    setState(() {
      exercise = ex;
      customCtrl.clear();
      _resetRows();
    });
    if (!pr) return toast(context, 'Logged $ex 💪');
    final st = statsOf(Workout(id: '', date: date, muscle: muscle, exercise: ex, sets: sets));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('🏆 New PR on $ex!'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'SHARE',
          textColor: C.accent,
          onPressed: () => showShareCard(
            context,
            CardData(
              kicker: '🏆 New personal record · ${fmtDate(date)}',
              stat: fmtSet(st.top),
              statLabel: st.bodyweight ? ex : '$ex · est. 1RM ${fmtNum(st.e1rm)}kg',
              text: 'New PR unlocked. The gains are real and the roasts are cancelled. For now. 💪',
              shareText: '🏆 New $ex PR: ${fmtSet(st.top)}! #Gymbroo',
            ),
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final opts = s.exerciseOptions(muscle);
    if (exercise != _custom && !opts.contains(exercise)) exercise = opts.first;
    final ex = exName;
    final prev = ex.isEmpty ? <Workout>[] : s.sessionsOf(ex);
    final last = prev.isEmpty ? null : prev.last;
    final dayList = s.workouts.where((w) => w.date == date).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          title: 'Log a workout',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Date'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
                child: Text(date == todayStr() ? 'Today · ${fmtDate(date)}' : fmtDate(date)),
              ),
            ),
            _label('Muscle group'),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final m in muscles)
                ChoiceChip(
                  label: Text('${m.icon} ${m.name}'),
                  selected: m.id == muscle,
                  showCheckmark: false,
                  selectedColor: C.accent,
                  backgroundColor: C.surface2,
                  side: BorderSide(color: m.id == muscle ? C.accent : C.line),
                  labelStyle: TextStyle(
                      color: m.id == muscle ? Colors.white : C.text,
                      fontWeight: m.id == muscle ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13),
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() {
                    muscle = m.id;
                    exercise = s.exerciseOptions(m.id).first;
                  }),
                ),
            ]),
            _label('Exercise'),
            DropdownButtonHideUnderline(
              child: InputDecorator(
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                child: DropdownButton<String>(
                  value: exercise,
                  isExpanded: true,
                  dropdownColor: C.surface2,
                  items: [
                    for (final o in opts) DropdownMenuItem(value: o, child: Text(o)),
                    const DropdownMenuItem(value: _custom, child: Text('+ Custom exercise…')),
                  ],
                  onChanged: (v) => setState(() => exercise = v ?? exercise),
                ),
              ),
            ),
            if (exercise == _custom) ...[
              const SizedBox(height: 8),
              TextField(
                controller: customCtrl,
                maxLength: maxExerciseName,
                decoration: const InputDecoration(hintText: 'e.g. Pec Deck', counterText: ''),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (last != null)
              _hint(Text.rich(TextSpan(style: const TextStyle(fontSize: 13, height: 1.5), children: [
                TextSpan(text: 'Last time (${fmtDate(last.date)}): '),
                TextSpan(text: setsText(last), style: const TextStyle(color: C.accent, fontWeight: FontWeight.w700)),
                const TextSpan(text: '\nBeat it 👉 try '),
                TextSpan(text: suggestionFor(last), style: const TextStyle(color: C.accent, fontWeight: FontWeight.w700)),
              ])))
            else if (ex.isNotEmpty)
              _hint(Text('First time logging $ex — set the baseline. 💪', style: const TextStyle(fontSize: 13))),
            _label('Sets (kg × reps — leave kg empty for bodyweight)'),
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center, style: mutedStyle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: rows[i].w,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(hintText: 'kg'),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('×', style: mutedStyle)),
                  Expanded(
                    child: TextField(
                      controller: rows[i].r,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      decoration: const InputDecoration(hintText: 'reps'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: C.muted),
                    tooltip: 'Remove set',
                    onPressed: () => setState(() {
                      rows.removeAt(i).dispose();
                      if (rows.isEmpty) rows.add(_SetRow());
                    }),
                  ),
                ]),
              ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: rows.length >= maxSets
                    ? null
                    : () => setState(() {
                          final r = _SetRow();
                          r.w.text = rows.isNotEmpty ? rows.last.w.text : '';
                          rows.add(r);
                        }),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add set'),
              ),
              if (last != null)
                OutlinedButton.icon(
                  onPressed: () => _copyLast(last),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Copy last session'),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _save,
                child: const Text('Save workout'),
              ),
            ),
          ]),
        ),
        if (dayList.isNotEmpty)
          Panel(
            title: 'Logged on ${fmtDate(date)}',
            child: Column(children: [
              for (final w in dayList)
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${muscleById(w.muscle).icon} ${w.exercise}', style: boldStyle),
                      Text(setsText(w), style: mutedStyle),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                    onPressed: () => confirmDelete(context, () => s.deleteWorkout(w.id)),
                  ),
                ]),
            ]),
          ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600)),
      );

  Widget _hint(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(10)),
        child: child,
      );
}

Future<void> confirmDelete(BuildContext context, VoidCallback onYes) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: C.surface,
      title: const Text('Delete this entry?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: C.down))),
      ],
    ),
  );
  if (ok == true) onYes();
}
