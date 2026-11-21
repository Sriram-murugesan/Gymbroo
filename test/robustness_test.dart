// Tester checks: hostile / corrupted saved data and oversized input
// must never crash the app or wipe good data.
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbroo/data.dart';

void main() {
  test('corrupted entries are skipped, good ones survive', () {
    final s = AppState()
      ..restore({
        'createdAt': 'not-a-date',
        'goals': {'chest': 99, 'legs': -5, 'back': 'two'},
        'workouts': [
          {'id': 'ok', 'date': '2026-11-01', 'muscle': 'chest', 'exercise': 'Bench Press', 'sets': [{'w': 20, 'r': 10}]},
          {'date': '2026-13-45', 'exercise': 'Bad date', 'sets': [{'w': 1, 'r': 1}]},
          {'date': '2026-11-02', 'exercise': '', 'sets': [{'w': 1, 'r': 1}]},
          {'date': '2026-11-02', 'exercise': 'No sets', 'sets': []},
          {'date': '2026-11-02', 'exercise': 'Junk sets', 'sets': ['x', null, {'w': 'heavy', 'r': 5}]},
          'garbage',
          null,
          {'date': '2026-11-03', 'exercise': 'X' * 500, 'muscle': 'arms',
            'sets': [for (var i = 0; i < 100; i++) {'w': 1e9, 'r': -3}]},
        ],
        'ticks': [{'date': '2026-11-01', 'muscle': 'legs'}, {'date': 42}, 'nope'],
        'settings': {'roastDays': 100000, 'roastLevel': 'nuclear'},
        'friends': ['Rahul', 7, 'Y' * 200],
      });

    expect(s.createdAt, todayStr());
    expect(s.goals['chest'], 7);
    expect(s.goals['legs'], 0);
    expect(s.goals['back'], 2);
    expect(s.workouts.map((w) => w.exercise), ['Bench Press', 'X' * maxExerciseName]);
    final big = s.workouts.last;
    expect(big.sets.length, maxSets);
    expect(big.sets.first.w, maxWeight);
    expect(big.sets.first.r, 0);
    expect(s.ticks.length, 1);
    expect(s.roastDays, 60);
    expect(s.roastLevel, RoastLevel.noMercy);
    expect(s.friendNames, ['Rahul', 'Y' * maxFriendName]);

    // Everything still works on the cleaned data.
    expect(() => s.roasts, returnsNormally);
    expect(() => s.balance, returnsNormally);
    expect(() => s.reminderFor(todayStr()), returnsNormally);
  });

  test('addWorkout enforces limits and rejects junk', () {
    final s = AppState();
    expect(s.addWorkout('2026-11-01', 'chest', '   ', [const WorkoutSet(10, 5)]), isFalse);
    expect(s.addWorkout('bad', 'chest', 'Bench', [const WorkoutSet(10, 5)]), isFalse);
    expect(s.workouts, isEmpty);
    s.addWorkout('2026-11-01', 'chest', 'Z' * 100, [for (var i = 0; i < 50; i++) const WorkoutSet(double.infinity, 99999)]);
    final w = s.workouts.single;
    expect(w.exercise.length, maxExerciseName);
    expect(w.sets.length, maxSets);
    expect(w.sets.first.w, 0);
    expect(w.sets.first.r, maxReps);
  });

  test('cache stays correct after changes', () {
    final s = AppState();
    s.addWorkout('2026-11-01', 'legs', 'Squat', [const WorkoutSet(40, 10)]);
    expect(s.lastTrained('legs'), '2026-11-01');
    s.addWorkout('2026-11-05', 'legs', 'Squat', [const WorkoutSet(45, 10)]);
    expect(s.lastTrained('legs'), '2026-11-05');
    expect(s.sessionsOf('Squat').length, 2);
    s.deleteWorkout(s.sessionsOf('Squat').last.id);
    expect(s.lastTrained('legs'), '2026-11-01');
    expect(s.loggedExercises, ['Squat']);
  });
}
