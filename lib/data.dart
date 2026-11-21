import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'roasts.dart';

export 'roasts.dart';

// ───────────────────────── Config ─────────────────────────

class Muscle {
  final String id, name, icon;
  const Muscle(this.id, this.name, this.icon);
}

const muscles = <Muscle>[
  Muscle('chest', 'Chest', '🛡️'),
  Muscle('back', 'Back', '🦅'),
  Muscle('legs', 'Legs', '🦵'),
  Muscle('shoulders', 'Shoulders', '🥥'),
  Muscle('arms', 'Arms', '💪'),
  Muscle('core', 'Core', '🧱'),
];

Muscle muscleById(String id) =>
    muscles.firstWhere((m) => m.id == id, orElse: () => Muscle(id, id, '🏋️'));

const exerciseLibrary = <String, List<String>>{
  'chest': ['Bench Press', 'Incline Bench Press', 'Chest Flies', 'Cable Crossover', 'Push-ups', 'Dips'],
  'back': ['Deadlift', 'Pull-ups', 'Barbell Row', 'Lat Pulldown', 'Seated Cable Row'],
  'legs': ['Squat', 'Leg Press', 'Romanian Deadlift', 'Lunges', 'Leg Curl', 'Leg Extension', 'Calf Raise'],
  'shoulders': ['Overhead Press', 'Lateral Raise', 'Arnold Press', 'Face Pull', 'Rear Delt Fly'],
  'arms': ['Bicep Curl', 'Hammer Curl', 'Preacher Curl', 'Tricep Pushdown', 'Skull Crushers'],
  'core': ['Plank', 'Hanging Leg Raise', 'Cable Crunch', 'Russian Twist'],
};

/// Movement pattern used for the muscle balance score.
enum Pattern { push, pull, legs, core }

const _pushExercises = {
  'Bench Press', 'Incline Bench Press', 'Chest Flies', 'Cable Crossover', 'Push-ups', 'Dips',
  'Overhead Press', 'Lateral Raise', 'Arnold Press', 'Tricep Pushdown', 'Skull Crushers',
};
const _pullExercises = {
  'Deadlift', 'Pull-ups', 'Barbell Row', 'Lat Pulldown', 'Seated Cable Row',
  'Face Pull', 'Rear Delt Fly', 'Bicep Curl', 'Hammer Curl', 'Preacher Curl',
};

Pattern patternOf(String exercise, String muscleId) {
  if (_pushExercises.contains(exercise)) return Pattern.push;
  if (_pullExercises.contains(exercise)) return Pattern.pull;
  switch (muscleId) {
    case 'legs':
      return Pattern.legs;
    case 'core':
      return Pattern.core;
    case 'back':
      return Pattern.pull;
    case 'arms': // custom arm exercise: curls pull, everything else pushes
      return RegExp('curl|chin', caseSensitive: false).hasMatch(exercise) ? Pattern.pull : Pattern.push;
    default: // chest, shoulders
      return Pattern.push;
  }
}

class Balance {
  final double push, pull, legs, core;
  const Balance(this.push, this.pull, this.legs, this.core);
  double get total => push + pull + legs + core;
  bool get enoughData => total >= 8;
  double get legsShare => total == 0 ? 0 : legs / total;
  int get legsPct => (legsShare * 100).round();
  double get pushPull => (push + 0.5) / (pull + 0.5); // smoothed: avoids ÷0

  String get ratioText {
    String f(double v) => v >= 10 ? v.round().toString() : fmtNum(v);
    if (pull == 0 && push == 0) return '–';
    if (pull == 0) return '${fmtNum(push)}:0';
    if (push == 0) return '0:${fmtNum(pull)}';
    final r = push / pull;
    return r >= 1 ? '${f(r)}:1' : '1:${f(1 / r)}';
  }

  /// 0–100. Starts at 100, loses points for push/pull imbalance,
  /// too few leg sets and zero core work.
  int get score {
    var s = 100.0;
    if (push + pull > 0) s -= math.min(40, math.log(pushPull).abs() / math.log(3) * 40);
    if (legsShare < 0.25) s -= (0.25 - legsShare) / 0.25 * 35;
    if (core == 0) s -= 10;
    return s.clamp(0, 100).round();
  }

  String get label => score >= 85
      ? 'Balanced beast'
      : score >= 65
          ? 'Slightly lopsided'
          : score >= 40
              ? 'Tilting'
              : 'Structural hazard';

  /// The single worst problem, used to pick the roast line.
  BalanceIssue get issue {
    final ppDev = math.log(pushPull).abs() / math.log(3); // 1.0 at 3:1
    final legsDev = legsShare < 0.2 ? (0.25 - legsShare) / 0.25 : 0.0;
    if (legsDev == 0 && ppDev < 0.37) return BalanceIssue.balanced; // within ~1.5:1
    if (legsDev >= ppDev) return BalanceIssue.legsLow;
    return pushPull > 1 ? BalanceIssue.pushHeavy : BalanceIssue.pullHeavy;
  }

  String roast(RoastLevel level) =>
      fillRoast(balanceRoasts[level]![issue]!, r: ratioText, p: legsPct);
}

// ───────────────────────── Dates (stored as YYYY-MM-DD) ─────────────────────────

String _p(int n) => n.toString().padLeft(2, '0');
String ymd(DateTime d) => '${d.year}-${_p(d.month)}-${_p(d.day)}';
DateTime parseYmd(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String todayStr() => ymd(DateTime.now());
String addDays(String s, int n) {
  final d = parseYmd(s);
  return ymd(DateTime(d.year, d.month, d.day + n));
}

int daysBetween(String a, String b) {
  final pa = a.split('-').map(int.parse).toList(), pb = b.split('-').map(int.parse).toList();
  return DateTime.utc(pb[0], pb[1], pb[2]).difference(DateTime.utc(pa[0], pa[1], pa[2])).inDays;
}

/// Monday of the week containing [s].
String weekStartOf(String s) {
  final d = parseYmd(s);
  return ymd(DateTime(d.year, d.month, d.day - (d.weekday - 1)));
}

bool inWeek(String date, String ws) => date.compareTo(ws) >= 0 && date.compareTo(addDays(ws, 6)) <= 0;

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String shortDate(String s) {
  final d = parseYmd(s);
  return '${d.day} ${_mo[d.month - 1]}';
}

String fmtDate(String s) => '${_wd[parseYmd(s).weekday - 1]}, ${shortDate(s)}';

// ───────────────────────── Input limits ─────────────────────────

const maxExerciseName = 40;
const maxFriendName = 24;
const maxSets = 20;
const maxWeight = 1000.0; // kg
const maxReps = 1000;

// ───────────────────────── Models ─────────────────────────

class WorkoutSet {
  final double w; // kg, 0 = bodyweight
  final int r;
  const WorkoutSet(this.w, this.r);
  Map<String, dynamic> toJson() => {'w': w, 'r': r};
  factory WorkoutSet.fromJson(Map<String, dynamic> j) =>
      WorkoutSet((j['w'] as num).toDouble(), (j['r'] as num).toInt());
}

class Workout {
  final String id, date, muscle, exercise;
  final List<WorkoutSet> sets;
  const Workout({required this.id, required this.date, required this.muscle, required this.exercise, required this.sets});
  Map<String, dynamic> toJson() =>
      {'id': id, 'date': date, 'muscle': muscle, 'exercise': exercise, 'sets': sets.map((s) => s.toJson()).toList()};
  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        id: j['id'] as String,
        date: j['date'] as String,
        muscle: j['muscle'] as String,
        exercise: j['exercise'] as String,
        sets: (j['sets'] as List).map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
      );
}

/// A session ticked done manually, without logging sets.
class Tick {
  final String date, muscle;
  const Tick(this.date, this.muscle);
  Map<String, dynamic> toJson() => {'date': date, 'muscle': muscle};
  factory Tick.fromJson(Map<String, dynamic> j) => Tick(j['date'] as String, j['muscle'] as String);
}

// ───────────────────────── Workout maths ─────────────────────────

/// Epley estimated one-rep max.
double e1rm(double w, int r) => w > 0 ? w * (1 + r / 30) : 0;

String fmtNum(double n) {
  final v = (n * 10).round() / 10;
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

String fmtSet(WorkoutSet s) => s.w > 0 ? '${fmtNum(s.w)}kg × ${s.r}' : 'BW × ${s.r}';
String setsText(Workout w) => w.sets.map(fmtSet).join(', ');

class Stats {
  final WorkoutSet top;
  final double e1rm, volume;
  final int maxReps;
  const Stats(this.top, this.e1rm, this.volume, this.maxReps);
  bool get bodyweight => top.w == 0;

  /// Comparable "strength" number: e1RM for weighted lifts, reps for bodyweight.
  double get score => bodyweight ? maxReps.toDouble() : e1rm;
  String get unit => bodyweight ? ' reps' : 'kg';
}

// Workouts are immutable, so their stats can be cached on the object itself.
final _statsCache = Expando<Stats>('stats');
Stats statsOf(Workout w) => _statsCache[w] ??= _computeStats(w);

Stats _computeStats(Workout w) {
  WorkoutSet? top;
  double best = 0, vol = 0;
  int maxReps = 0;
  for (final s in w.sets) {
    vol += s.w * s.r;
    maxReps = math.max(maxReps, s.r);
    best = math.max(best, e1rm(s.w, s.r));
    if (top == null || s.w > top.w || (s.w == top.w && s.r > top.r)) top = s;
  }
  return Stats(top ?? const WorkoutSet(0, 0), best, vol, maxReps);
}

String suggestionFor(Workout last) {
  final st = statsOf(last);
  final w = st.top.w, r = st.top.r;
  if (st.bodyweight) return 'BW × ${r + 2}';
  return r >= 12 ? '${fmtNum(w + 2.5)}kg × ${math.max(r - 4, 6)}' : '${fmtNum(w)}kg × ${r + 1}  or  ${fmtNum(w + 2.5)}kg × $r';
}

class MuscleWeek {
  final int logged, manual, goal;
  const MuscleWeek(this.logged, this.manual, this.goal);
  int get done => logged + manual;
}

class Roast {
  final Muscle muscle;
  final int days;
  final String? last;
  final String text;
  const Roast(this.muscle, this.days, this.last, this.text);
}

// ───────────────────────── App state ─────────────────────────

class AppState extends ChangeNotifier {
  static const _key = 'gymbroo.v1';

  String createdAt = todayStr();
  Map<String, int> goals = {for (final m in muscles) m.id: 2};
  List<Workout> workouts = [];
  List<Tick> ticks = [];
  int roastDays = 14;
  bool notify = true;
  RoastLevel roastLevel = RoastLevel.noMercy;
  List<String> friendNames = [];

  /// False until the first-launch "set your goals" popup is completed.
  bool onboarded = false;

  /// Called after every change (used to reschedule notifications).
  VoidCallback? onChanged;
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      restore(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Unreadable data: keep a copy instead of overwriting it on the next save.
      debugPrint('Gymbroo: saved data unreadable ($e); kept a backup copy');
      await _prefs!.setString('$_key.corrupt.${DateTime.now().millisecondsSinceEpoch}', raw);
    }
  }

  static final _dateRe = RegExp(r'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$');
  static bool _validDate(Object? d) => d is String && d.length == 10 && _dateRe.hasMatch(d);

  /// Single-pass, defensive parse of one stored workout. Returns null if unusable.
  static Workout? _parseWorkout(Object? raw, Set<String> okDates) {
    if (raw is! Map) return null;
    final date = raw['date'], ex = raw['exercise'], sets = raw['sets'], id = raw['id'], muscle = raw['muscle'];
    if (date is! String || ex is! String || ex.isEmpty || sets is! List) return null;
    if (!okDates.contains(date)) {
      if (!_validDate(date)) return null;
      okDates.add(date); // many workouts share a date: validate each once
    }
    final parsed = <WorkoutSet>[];
    for (final s in sets) {
      if (parsed.length >= maxSets) break;
      if (s is! Map) continue;
      final w = s['w'], r = s['r'];
      if (w is! num || r is! num) continue;
      final wd = w.toDouble();
      parsed.add(WorkoutSet(wd.isFinite ? wd.clamp(0, maxWeight).toDouble() : 0, r.toInt().clamp(0, maxReps)));
    }
    if (parsed.isEmpty) return null;
    return Workout(
      id: id is String && id.isNotEmpty ? id : _uid(),
      date: date,
      muscle: muscle is String ? muscle : 'chest',
      exercise: ex.length > maxExerciseName ? ex.substring(0, maxExerciseName) : ex,
      sets: parsed,
    );
  }

  /// Restores from JSON. Bad individual entries are skipped rather than
  /// failing the whole load, and values are clamped to sane ranges.
  void restore(Map<String, dynamic> j) {
    createdAt = _validDate(j['createdAt']) ? j['createdAt'] as String : todayStr();
    final g = j['goals'] is Map ? j['goals'] as Map : const {};
    goals = {for (final m in muscles) m.id: ((g[m.id] is num ? (g[m.id] as num).toInt() : 2)).clamp(0, 7)};
    final okDates = <String>{};
    workouts = [
      for (final raw in (j['workouts'] is List ? j['workouts'] as List : const []))
        ?_parseWorkout(raw, okDates),
    ];
    ticks = [
      for (final raw in (j['ticks'] is List ? j['ticks'] as List : const []))
        if (raw is Map && raw['date'] is String && raw['muscle'] is String && _validDate(raw['date']))
          Tick(raw['date'] as String, raw['muscle'] as String),
    ];
    final s = j['settings'] is Map ? Map<String, dynamic>.from(j['settings'] as Map) : <String, dynamic>{};
    roastDays = ((s['roastDays'] as num?)?.toInt() ?? 14).clamp(3, 60);
    notify = s['notify'] as bool? ?? true;
    roastLevel = RoastLevelX.parse(s['roastLevel'] as String?);
    friendNames = (j['friends'] as List? ?? const [])
        .whereType<String>()
        .map((f) => f.length > maxFriendName ? f.substring(0, maxFriendName) : f)
        .take(12)
        .toList();
    // Older installs have no flag: skip the popup if they already logged workouts.
    onboarded = j['onboarded'] as bool? ?? workouts.isNotEmpty;
    _idx = null;
  }

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt,
        'goals': goals,
        'workouts': workouts.map((w) => w.toJson()).toList(),
        'ticks': ticks.map((t) => t.toJson()).toList(),
        'settings': {'roastDays': roastDays, 'notify': notify, 'roastLevel': roastLevel.name},
        'friends': friendNames,
        'onboarded': onboarded,
      };

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  // ── saving: batched (taps within 400 ms = one write), JSON encoded off the
  // UI thread, and writes chained so an older save can never land last.
  Timer? _saveTimer;
  bool _dirty = false;
  Future<void> _saveChain = Future.value();

  void _changed() {
    _idx = null;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), flush);
    notifyListeners();
    onChanged?.call();
  }

  /// Writes pending changes now (also called when the app goes to background).
  Future<void> flush() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final prefs = _prefs;
    if (!_dirty || prefs == null) return _saveChain;
    _dirty = false;
    final snapshot = toJson();
    return _saveChain = _saveChain.then((_) async {
      try {
        await prefs.setString(_key, await compute(_encodeJson, snapshot));
      } catch (e) {
        _dirty = true; // try again next time
        debugPrint('Gymbroo: save failed: $e');
      }
    });
  }

  // ── queries ──

  // Lazily built lookup index; dropped on every change. Turns full-history
  // scans (O(n) per muscle per day) into map lookups and binary searches.
  _Index? _idx;
  _Index get _index => _idx ??= _Index.build(workouts, ticks);

  Iterable<Workout> _workoutsBetween(String from, String to) => _index.workoutsBetween(from, to);
  Iterable<Tick> _ticksBetween(String from, String to) => _index.ticksBetween(from, to);

  Map<String, MuscleWeek> weekStatus([String? weekStart]) {
    final ws = weekStart ?? weekStartOf(todayStr()), we = addDays(ws, 6);
    final days = {for (final m in muscles) m.id: <String>{}};
    final manual = {for (final m in muscles) m.id: 0};
    for (final w in _workoutsBetween(ws, we)) {
      days[w.muscle]?.add(w.date);
    }
    for (final t in _ticksBetween(ws, we)) {
      if (manual.containsKey(t.muscle)) manual[t.muscle] = manual[t.muscle]! + 1;
    }
    return {for (final m in muscles) m.id: MuscleWeek(days[m.id]!.length, manual[m.id]!, goals[m.id] ?? 0)};
  }

  String? lastTrained(String muscleId) => _index.lastByMuscle[muscleId];

  /// Roasts that apply on [day] (assuming nothing more is trained before then).
  List<Roast> roastsOn(String day) {
    final dayNum = daysBetween('2000-01-01', day);
    final out = <Roast>[];
    for (var i = 0; i < muscles.length; i++) {
      final m = muscles[i];
      if ((goals[m.id] ?? 0) <= 0) continue;
      final last = lastTrained(m.id);
      final d = daysBetween(last ?? createdAt, day);
      if (d >= roastDays) {
        final lines = selfRoasts[roastLevel]![m.id]!;
        out.add(Roast(m, d, last, fillRoast(lines[(dayNum + i) % lines.length], d: d)));
      }
    }
    out.sort((a, b) => b.days.compareTo(a.days));
    return out;
  }

  List<Roast> get roasts => roastsOn(todayStr());

  /// Reminder text for [day], or null if there's nothing to nag about.
  String? reminderFor(String day) {
    final rs = roastsOn(day);
    if (rs.isNotEmpty) return rs.first.text;
    final b = balanceOn(day);
    if (b.enoughData && b.score < 50) return b.roast(roastLevel);
    final ws = weekStartOf(day), st = weekStatus(ws), left = 7 - daysBetween(ws, day);
    final pend = muscles.where((m) => st[m.id]!.done < st[m.id]!.goal).toList();
    if (pend.isEmpty) return null;
    return '$left day${left > 1 ? 's' : ''} left this week. Still to hit: '
        '${pend.map((m) => '${m.name} ${st[m.id]!.done}/${st[m.id]!.goal}').join(', ')}';
  }

  /// Sets per movement pattern over the 28 days ending on [day].
  /// A manual tick counts as 3 sets (arms ticks split between push and pull).
  Balance balanceOn(String day, {int days = 28}) {
    final from = addDays(day, -(days - 1));
    final c = {for (final p in Pattern.values) p: 0.0};
    for (final w in _workoutsBetween(from, day)) {
      final p = patternOf(w.exercise, w.muscle);
      c[p] = c[p]! + w.sets.length;
    }
    for (final t in _ticksBetween(from, day)) {
      if (t.muscle == 'arms') {
        c[Pattern.push] = c[Pattern.push]! + 1.5;
        c[Pattern.pull] = c[Pattern.pull]! + 1.5;
      } else {
        final p = patternOf('', t.muscle);
        c[p] = c[p]! + 3;
      }
    }
    return Balance(c[Pattern.push]!, c[Pattern.pull]!, c[Pattern.legs]!, c[Pattern.core]!);
  }

  Balance get balance => balanceOn(todayStr());

  /// Sessions of [exercise], oldest first. Read-only view of the cached index.
  List<Workout> sessionsOf(String exercise) => UnmodifiableListView(_index.byExercise[exercise] ?? const []);

  Stats? weekBest(String exercise, String ws) {
    Stats? best;
    for (final w in sessionsOf(exercise).where((w) => inWeek(w.date, ws))) {
      final st = statsOf(w);
      if (best == null || st.score > best.score) best = st;
    }
    return best;
  }

  List<String> exerciseOptions(String muscleId) {
    final lib = exerciseLibrary[muscleId] ?? const [];
    final custom = _index.byExercise.entries
        .where((e) => e.value.first.muscle == muscleId && !lib.contains(e.key))
        .map((e) => e.key);
    return [...lib, ...custom];
  }

  /// Logged exercises, most recently trained first.
  List<String> get loggedExercises => _index.exercisesRecentFirst;

  List<Workout> recent(int n) => _index.byDate.reversed.take(n).toList();

  // ── mutations ──

  static String _uid() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${math.Random().nextInt(1 << 30).toRadixString(36)}';

  /// Returns true if this beats the previous best for the exercise.
  bool addWorkout(String date, String muscleId, String exercise, List<WorkoutSet> sets) {
    var name = exercise.trim();
    if (name.length > maxExerciseName) name = name.substring(0, maxExerciseName);
    final clean = [
      for (final s in sets.take(maxSets))
        WorkoutSet(s.w.isFinite ? s.w.clamp(0, maxWeight).toDouble() : 0, s.r.clamp(0, maxReps)),
    ];
    if (name.isEmpty || clean.isEmpty || !_validDate(date)) return false;
    final prev = sessionsOf(name);
    final prevBest = prev.isEmpty ? 0.0 : prev.map((w) => statsOf(w).score).reduce(math.max);
    final w = Workout(id: _uid(), date: date, muscle: muscleId, exercise: name, sets: clean);
    workouts.add(w);
    _changed();
    return prev.isNotEmpty && statsOf(w).score > prevBest;
  }

  void deleteWorkout(String id) {
    workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  void tick(String muscleId) {
    ticks.add(Tick(todayStr(), muscleId));
    _changed();
  }

  void untick(String muscleId) {
    final ws = weekStartOf(todayStr());
    final i = ticks.lastIndexWhere((t) => t.muscle == muscleId && inWeek(t.date, ws));
    if (i >= 0) {
      ticks.removeAt(i);
      _changed();
    }
  }

  void setGoal(String muscleId, int v) {
    goals[muscleId] = v.clamp(0, 7);
    _changed();
  }

  void setAllGoals(int v) {
    for (final m in muscles) {
      goals[m.id] = v;
    }
    _changed();
  }

  void setRoastDays(int d) {
    roastDays = d;
    _changed();
  }

  void setNotify(bool v) {
    notify = v;
    _changed();
  }

  /// Saves the choices from the first-launch popup.
  void completeOnboarding(Map<String, int> newGoals, RoastLevel level) {
    goals = {for (final m in muscles) m.id: (newGoals[m.id] ?? 2).clamp(0, 7)};
    roastLevel = level;
    onboarded = true;
    _changed();
  }

  void setRoastLevel(RoastLevel l) {
    roastLevel = l;
    _changed();
  }

  /// Remember a friend's name (most recent first, max 12).
  void rememberFriend(String name) {
    var n = name.trim();
    if (n.length > maxFriendName) n = n.substring(0, maxFriendName);
    if (n.isEmpty) return;
    friendNames = [n, ...friendNames.where((f) => f.toLowerCase() != n.toLowerCase())].take(12).toList();
    _changed();
  }

  void forgetFriend(String name) {
    friendNames = friendNames.where((f) => f != name).toList();
    _changed();
  }

  void reset() {
    createdAt = todayStr();
    goals = {for (final m in muscles) m.id: 2};
    workouts = [];
    ticks = [];
    roastDays = 14;
    onboarded = false;
    _changed();
  }

  void loadSample() {
    final t = todayStr(), ws = weekStartOf(t), ti = daysBetween(ws, t);
    String lw(int k) => addDays(ws, k - 7);
    String tw(int k) => addDays(ws, math.min(k, ti));
    String w2(int k) => addDays(ws, k - 14);
    List<WorkoutSet> s(List<List<num>> p) => p.map((x) => WorkoutSet(x[0].toDouble(), x[1].toInt())).toList();
    Workout w(String d, String m, String ex, List<List<num>> sets) =>
        Workout(id: _uid(), date: d, muscle: m, exercise: ex, sets: s(sets));
    createdAt = addDays(ws, -21);
    goals = {for (final m in muscles) m.id: 2};
    ticks = [];
    workouts = [
      w(addDays(ws, -15), 'legs', 'Squat', [[40, 10], [40, 10], [40, 8]]),
      w(w2(0), 'chest', 'Bench Press', [[12.5, 15], [12.5, 12]]),
      w(w2(0), 'chest', 'Chest Flies', [[8, 12], [8, 12]]),
      w(w2(1), 'back', 'Lat Pulldown', [[35, 12], [35, 10]]),
      w(w2(3), 'shoulders', 'Overhead Press', [[17.5, 10], [17.5, 8]]),
      w(lw(0), 'chest', 'Bench Press', [[15, 15], [15, 12]]),
      w(lw(0), 'chest', 'Chest Flies', [[10, 12], [10, 10]]),
      w(lw(1), 'back', 'Lat Pulldown', [[40, 10], [40, 9]]),
      w(lw(1), 'back', 'Pull-ups', [[0, 6], [0, 5]]),
      w(lw(3), 'chest', 'Bench Press', [[15, 14], [15, 12]]),
      w(lw(3), 'shoulders', 'Overhead Press', [[20, 10], [20, 8]]),
      w(lw(4), 'arms', 'Bicep Curl', [[10, 12], [10, 10]]),
      w(tw(0), 'chest', 'Bench Press', [[20, 10], [20, 8]]),
      w(tw(0), 'chest', 'Chest Flies', [[12, 10], [12, 9]]),
      w(tw(1), 'back', 'Lat Pulldown', [[42.5, 10], [42.5, 8]]),
      w(tw(1), 'back', 'Pull-ups', [[0, 8], [0, 6]]),
      w(tw(2), 'arms', 'Bicep Curl', [[12, 10], [12, 8]]),
    ];
    _changed();
  }
}

// ───────────────────────── Index (cache) ─────────────────────────

class _Index {
  final List<Workout> byDate; // oldest first
  final List<Tick> ticksByDate; // oldest first
  final Map<String, List<Workout>> byExercise; // each oldest first
  final Map<String, String> lastByMuscle;
  final List<String> exercisesRecentFirst;

  _Index(this.byDate, this.ticksByDate, this.byExercise, this.lastByMuscle, this.exercisesRecentFirst);

  factory _Index.build(List<Workout> workouts, List<Tick> ticks) {
    final byDate = [...workouts]..sort((a, b) => a.date.compareTo(b.date));
    final ticksByDate = [...ticks]..sort((a, b) => a.date.compareTo(b.date));
    final byExercise = <String, List<Workout>>{};
    final last = <String, String>{};
    for (final w in byDate) {
      (byExercise[w.exercise] ??= []).add(w);
      last[w.muscle] = w.date; // ascending, so the final write is the latest
    }
    for (final t in ticksByDate) {
      final cur = last[t.muscle];
      if (cur == null || t.date.compareTo(cur) > 0) last[t.muscle] = t.date;
    }
    final seen = <String>{}, recentFirst = <String>[];
    for (final w in byDate.reversed) {
      if (seen.add(w.exercise)) recentFirst.add(w.exercise);
    }
    return _Index(byDate, ticksByDate, byExercise, last, List.unmodifiable(recentFirst));
  }

  /// First index whose date is >= [key] (binary search).
  static int _lowerBound<T>(List<T> list, String key, String Function(T) dateOf) {
    var lo = 0, hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (dateOf(list[mid]).compareTo(key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Iterable<Workout> workoutsBetween(String from, String to) sync* {
    for (var i = _lowerBound<Workout>(byDate, from, (w) => w.date);
        i < byDate.length && byDate[i].date.compareTo(to) <= 0;
        i++) {
      yield byDate[i];
    }
  }

  Iterable<Tick> ticksBetween(String from, String to) sync* {
    for (var i = _lowerBound<Tick>(ticksByDate, from, (t) => t.date);
        i < ticksByDate.length && ticksByDate[i].date.compareTo(to) <= 0;
        i++) {
      yield ticksByDate[i];
    }
  }
}

String _encodeJson(Map<String, dynamic> m) => jsonEncode(m);
