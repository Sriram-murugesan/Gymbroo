// Stress test: ~3 years of heavy training, timed against the operations
// the app runs on every tap (save + reschedule + screen rebuild).
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymbroo/data.dart';

AppState bigState() {
  final s = AppState();
  final start = parseYmd(addDays(todayStr(), -3 * 365));
  final plan = {
    0: ['chest', 'Bench Press', 'Incline Bench Press', 'Chest Flies', 'Tricep Pushdown'],
    1: ['back', 'Deadlift', 'Lat Pulldown', 'Barbell Row', 'Bicep Curl'],
    2: ['legs', 'Squat', 'Leg Press', 'Leg Curl', 'Calf Raise'],
    3: ['shoulders', 'Overhead Press', 'Lateral Raise', 'Face Pull', 'Skull Crushers'],
    4: ['arms', 'Hammer Curl', 'Preacher Curl', 'Dips', 'Plank'],
  };
  var id = 0;
  for (var day = 0; day < 3 * 365; day++) {
    final d = DateTime(start.year, start.month, start.day + day);
    final p = plan[d.weekday - 1];
    if (p == null) continue;
    for (final ex in p.skip(1)) {
      s.workouts.add(Workout(
        id: 'w${id++}',
        date: ymd(d),
        muscle: p[0],
        exercise: ex,
        sets: [for (var k = 0; k < 4; k++) WorkoutSet(20 + (day / 20).floorToDouble(), 12 - k)],
      ));
    }
  }
  for (var i = 0; i < 200; i++) {
    s.ticks.add(Tick(addDays(todayStr(), -i * 5), muscles[i % 6].id));
  }
  return s;
}

double timeMs(void Function() f, {int runs = 5}) {
  f(); // warm-up
  final sw = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    f();
  }
  return sw.elapsedMicroseconds / runs / 1000;
}

void main() {
  test('perf: 3 years of data', () {
    final s = bigState();
    final t = todayStr(), ws = weekStartOf(t);
    print('workouts=${s.workouts.length} sets=${s.workouts.fold<int>(0, (a, w) => a + w.sets.length)}');

    late String encoded;
    final save = timeMs(() => encoded = jsonEncode(s.toJson()));
    print('save (toJson+encode): ${save.toStringAsFixed(1)} ms, ${(encoded.length / 1024).toStringAsFixed(0)} KB');

    final load = timeMs(() => AppState().restore(jsonDecode(encoded) as Map<String, dynamic>));
    print('load (decode+parse): ${load.toStringAsFixed(1)} ms');

    final home = timeMs(() {
      s.roasts;
      s.weekStatus(ws);
      s.recent(6);
    });
    print('home screen data: ${home.toStringAsFixed(2)} ms');

    final reminders = timeMs(() {
      for (var i = 0; i < 14; i++) {
        s.reminderFor(addDays(t, i));
      }
    });
    print('reschedule data (14 days): ${reminders.toStringAsFixed(2)} ms');

    final progress = timeMs(() {
      s.balance;
      final exs = s.loggedExercises;
      for (final e in exs) {
        final sess = s.sessionsOf(e);
        statsOf(sess.last);
        if (sess.length > 1) statsOf(sess[sess.length - 2]);
      }
      final ex = exs.first;
      s.weekBest(ex, ws);
      s.weekBest(ex, addDays(ws, -7));
      for (final w in s.sessionsOf(ex)) {
        statsOf(w);
        statsOf(w);
        statsOf(w);
      }
    });
    print('progress screen data: ${progress.toStringAsFixed(2)} ms');

    final perTap = save + reminders + home;
    print('≈ work per tap (save + reschedule + home rebuild): ${perTap.toStringAsFixed(1)} ms');
  });
}
