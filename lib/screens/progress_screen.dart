import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets/share_card.dart';
import '../widgets/trend_chart.dart';
import 'log_screen.dart' show confirmDelete;

class ProgressScreen extends StatefulWidget {
  final AppState state;
  const ProgressScreen({super.key, required this.state});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? selected;
  bool showAllHistory = false;
  static const historyPage = 20;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final exs = s.loggedExercises;
    if (exs.isEmpty) {
      return ListView(padding: const EdgeInsets.all(16), children: const [
        Panel(title: 'Progress', child: Text('Log some workouts first — then watch the numbers climb. 📈', style: mutedStyle)),
      ]);
    }
    if (selected == null || !exs.contains(selected)) selected = exs.first;
    final ex = selected!;
    final ws = weekStartOf(todayStr()), lws = addDays(ws, -7);
    final lw = s.weekBest(ex, lws), tw = s.weekBest(ex, ws);
    final sess = s.sessionsOf(ex);
    final bw = sess.isNotEmpty && statsOf(sess.last).bodyweight;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _balancePanel(s),

        // ── All lifts ──
        Panel(
          title: 'All lifts · last session vs previous',
          child: Column(children: [
            for (final e in exs) _liftRow(s, e),
          ]),
        ),

        // ── Week vs week ──
        Panel(
          title: '$ex · last week vs this week',
          child: Column(children: [
            Row(children: [
              Expanded(child: _weekBox('Last week', lw, 'not done')),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('➜', style: TextStyle(fontSize: 20))),
              Expanded(child: _weekBox('This week', tw, 'not yet')),
            ]),
            const SizedBox(height: 12),
            _verdict(lw, tw),
            const SizedBox(height: 10),
            const Text(
              'e1RM (estimated one-rep max) lets you compare heavier-for-fewer vs lighter-for-more. '
              '15kg × 15 ≈ 22.5kg, 20kg × 10 ≈ 26.7kg.',
              style: mutedStyle,
            ),
          ]),
        ),

        // ── Trend ──
        Panel(
          title: '$ex · trend (${bw ? 'max reps' : 'e1RM kg'})',
          child: sess.length < 2
              ? const Text('Log this exercise at least twice to see your trend line.', style: mutedStyle)
              : TrendChart(points: [for (final w in sess) (date: w.date, value: statsOf(w).score)]),
        ),

        // ── History ──
        Panel(
          title: 'History',
          child: Column(children: [
            for (final w in sess.reversed.take(showAllHistory ? sess.length : historyPage))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(fmtDate(w.date), style: boldStyle)),
                        if (!statsOf(w).bodyweight) Text('vol ${fmtNum(statsOf(w).volume)}kg', style: mutedStyle),
                      ]),
                      Text(setsText(w), style: mutedStyle),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                    onPressed: () => confirmDelete(context, () => s.deleteWorkout(w.id)),
                  ),
                ]),
              ),
            if (!showAllHistory && sess.length > historyPage)
              TextButton(
                onPressed: () => setState(() => showAllHistory = true),
                child: Text('Show all ${sess.length} sessions'),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _balancePanel(AppState s) {
    final b = s.balance;
    if (!b.enoughData) {
      return Panel(
        title: '⚖️ Muscle balance · last 4 weeks',
        child: Text('Log at least 8 sets in the last 4 weeks to get your balance score. (${fmtNum(b.total)} so far)',
            style: mutedStyle),
      );
    }
    final roast = b.roast(s.roastLevel);
    final scoreColor = b.score >= 65 ? C.up : C.down;
    Widget bar(String label, double v) {
      final frac = b.total == 0 ? 0.0 : v / b.total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 44, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 10,
                backgroundColor: C.surface2,
                color: C.accent,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text('${fmtNum(v)} sets · ${(frac * 100).round()}%',
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: C.muted)),
          ),
        ]),
      );
    }

    return Panel(
      title: '⚖️ Muscle balance · last 4 weeks',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${b.score}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: scoreColor, height: 1)),
          const Text(' /100', style: TextStyle(color: C.muted, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Push : Pull  ${b.ratioText}', style: mutedStyle),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        bar('Push', b.push),
        bar('Pull', b.pull),
        bar('Legs', b.legs),
        bar('Core', b.core),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.roast.withValues(alpha: .08),
            border: Border.all(color: C.accentDim),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(roast, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(
            child: Text('Push = chest, shoulders, triceps · Pull = back, biceps', style: TextStyle(fontSize: 11, color: C.muted)),
          ),
          OutlinedButton.icon(
            onPressed: () => showShareCard(
              context,
              CardData(
                kicker: '⚖️ Muscle balance · push:pull ${b.ratioText}',
                stat: '${b.score}/100',
                statLabel: b.label,
                text: roast,
                shareText: 'My muscle balance score: ${b.score}/100 (${b.label}). $roast\n\n#Gymbroo',
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
          ),
        ]),
      ]),
    );
  }

  Widget _liftRow(AppState s, String e) {
    final sess = s.sessionsOf(e);
    final b = statsOf(sess.last);
    final a = sess.length > 1 ? statsOf(sess[sess.length - 2]) : null;
    final isSel = e == selected;
    return InkWell(
      onTap: () => setState(() {
        selected = e;
        showAllHistory = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? C.accentDim.withValues(alpha: .5) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e, style: boldStyle),
              Text.rich(TextSpan(style: mutedStyle, children: [
                if (a != null) TextSpan(text: '${fmtSet(a.top)} → '),
                TextSpan(text: fmtSet(b.top), style: const TextStyle(color: C.text, fontWeight: FontWeight.w700)),
              ])),
            ]),
          ),
          a == null
              ? const Text('new', style: mutedStyle)
              : deltaText(a.score, b.score, b.unit, fmtNum),
        ]),
      ),
    );
  }

  Widget _weekBox(String label, Stats? st, String empty) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: C.muted, letterSpacing: .6)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(st == null ? '—' : fmtSet(st.top), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          Text(
            st == null ? empty : (st.bodyweight ? '${st.maxReps} reps' : 'e1RM ${fmtNum(st.e1rm)}kg'),
            style: const TextStyle(fontSize: 12, color: C.muted),
          ),
        ]),
      );

  Widget _verdict(Stats? lw, Stats? tw) {
    const style = TextStyle(fontWeight: FontWeight.w700);
    if (lw != null && tw != null) {
      final d = tw.score - lw.score;
      final label = d > 0.05
          ? '📈 Stronger! '
          : d < -0.05
              ? '🔻 Slight dip — deload or bad sleep? '
              : '➖ Holding steady. Add a rep next time.';
      return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(label, style: style, textAlign: TextAlign.center),
        if (d.abs() >= 0.05) deltaText(lw.score, tw.score, tw.unit, fmtNum),
      ]);
    }
    if (lw != null) return Text('⏳ Not done this week yet — beat ${fmtSet(lw.top)}!', style: style, textAlign: TextAlign.center);
    if (tw != null) return const Text('🆕 No data last week — this is your new baseline.', style: style, textAlign: TextAlign.center);
    return const SizedBox.shrink();
  }
}
