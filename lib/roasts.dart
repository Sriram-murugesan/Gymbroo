/// All roast copy lives here, split by intensity level.
/// Placeholders: {d} days, {name}/{NAME} friend name, {muscle} muscle name,
/// {burn} muscle-specific burn, {r} push:pull ratio, {p} legs percentage.
library;

enum RoastLevel { gentle, sergeant, noMercy }

extension RoastLevelX on RoastLevel {
  String get label => switch (this) {
        RoastLevel.gentle => 'Gentle bro',
        RoastLevel.sergeant => 'Drill sergeant',
        RoastLevel.noMercy => 'No mercy',
      };
  String get emoji => switch (this) {
        RoastLevel.gentle => '🙂',
        RoastLevel.sergeant => '🪖',
        RoastLevel.noMercy => '💀',
      };
  String get blurb => switch (this) {
        RoastLevel.gentle => 'Kind nudges. Your mum would approve.',
        RoastLevel.sergeant => 'Loud orders. Drop and give me twenty.',
        RoastLevel.noMercy => 'Full roast. Feelings not included.',
      };
  String get notificationTitle => 'Gymbroo $emoji';

  static RoastLevel parse(String? s) =>
      RoastLevel.values.firstWhere((l) => l.name == s, orElse: () => RoastLevel.noMercy);
}

/// Roasts for YOU skipping a muscle. Keyed by level → muscle id.
const selfRoasts = <RoastLevel, Map<String, List<String>>>{
  RoastLevel.gentle: {
    'legs': [
      "🦵 Your legs have been resting for {d} days. They'd love a squat or two — no pressure, bro.",
      '🌱 {d} days since leg day. Small steps (literally) — maybe some lunges today?',
    ],
    'chest': [
      '🛡️ Chest hasn\'t seen action in {d} days. A few push-ups would make it smile.',
      "🙂 {d} days off chest. It's okay — the bench is still waiting for you.",
    ],
    'back': [
      "🦅 Your back's been off for {d} days. Some rows would feel great.",
      '🙂 {d} days since back day. Your posture will thank you for a few pull-ups.',
    ],
    'shoulders': [
      '🥥 Shoulders have been chilling for {d} days. A few presses would perk them up.',
      '🙂 {d} days without shoulders — some lateral raises today?',
    ],
    'arms': [
      '💪 Arms have had {d} days off. A few curls and pushdowns would be nice.',
      '🙂 {d} days since arm day. Your sleeves miss being filled.',
    ],
    'core': [
      "🧱 Core's been resting {d} days. A quick plank counts!",
      '🙂 {d} days without core. Even 5 minutes of planks would help.',
    ],
  },
  RoastLevel.sergeant: {
    'legs': [
      "🪖 {d} DAYS WITHOUT LEGS, RECRUIT! Get under that bar and SQUAT. That's an order!",
      '📣 Leg day is not optional, soldier! {d} days AWOL. Report to the squat rack at once!',
    ],
    'chest': [
      '🪖 {d} days no chest?! Hit the deck and give me fifty push-ups, NOW!',
      '📣 Your bench is collecting dust, recruit! {d} days! Press something heavy TODAY!',
    ],
    'back': [
      '🪖 {d} days of no back work! Stand up straight and PULL, recruit!',
      '📣 Rows, pull-ups, deadlifts — PICK ONE. {d} days is unacceptable, soldier!',
    ],
    'shoulders': [
      '🪖 {d} days and no presses?! Get that bar overhead, recruit!',
      "📣 Boulder shoulders aren't issued, soldier — they're EARNED. {d} days off. MOVE!",
    ],
    'arms': [
      '🪖 {d} days no arms?! Curl till it burns, recruit!',
      "📣 Those guns won't load themselves, soldier! {d} days! Biceps and triceps — NOW!",
    ],
    'core': [
      '🪖 {d} days no core?! Plank position, recruit — and HOLD IT!',
      '📣 A soldier with no core is a soldier who tips over! {d} days! Crunches, NOW!',
    ],
  },
  RoastLevel.noMercy: {
    'legs': [
      "🍗 Chicken legs detected! {d} days since leg day. Your torso is writing cheques your legs can't cash.",
      '🦩 {d} days without legs. The flamingos called — they want their silhouette back.',
      "💀 {d} days skipping legs. At this point you're a bobblehead on toothpicks.",
    ],
    'chest': [
      "📉 {d} days no chest. It's getting flatter than your excuses.",
      '🥞 Pancake chest loading… {d} days and counting.',
    ],
    'back': [
      "🐢 {d} days no back work. You're one slouch away from becoming a question mark.",
      "🙈 Your back has been ghosted for {d} days. It's the side everyone else sees, you know.",
    ],
    'shoulders': [
      '🪨 Boulder shoulders? More like pebble shoulders. {d} days skipped.',
      '🧥 {d} days no shoulders — your t-shirts hang like the coat hanger gave up.',
    ],
    'arms': [
      "🍝 {d} days no arms. Those noodles won't fill a sleeve.",
      '🤏 {d} days since you curled anything heavier than your phone.',
    ],
    'core': [
      '🍩 {d} days no core. The six-pack is on permanent backorder.',
      "🫠 Core's been on vacation for {d} days. The planks don't even miss you anymore.",
    ],
  },
};

/// One-liner burns used in no-mercy friend roasts.
const muscleBurns = <String, String>{
  'legs': 'Built like a lollipop 🍭',
  'chest': 'Flatter than week-old soda 🥤',
  'back': 'One slouch away from becoming a question mark ❓',
  'shoulders': 'Coat hanger energy 🧥',
  'arms': 'Noodle arms confirmed 🍝',
  'core': 'Six-pack still in the shrink wrap 🍩',
};

/// Roasts you send to a FRIEND.
const friendRoasts = <RoastLevel, List<String>>{
  RoastLevel.gentle: [
    'Hey {name} 👋 {muscle} day misses you — {d} days and counting. Gym together?',
    "{name}, it's been {d} days since {muscle} day. Just saying 🥺",
    'Friendly reminder, {name}: {muscle} day has been on holiday for {d} days 🏖️',
  ],
  RoastLevel.sergeant: [
    '🪖 ATTENTION {NAME}! {d} days without {muscle}?! Report to the gym, recruit!',
    '📣 {name}, {d} days AWOL from {muscle} day. Drop and give me twenty!',
    '🪖 {NAME}! {d} DAYS! Your {muscle} gains are filing for desertion. MOVE!',
  ],
  RoastLevel.noMercy: [
    "💀 {name} hasn't trained {muscle} in {d} days. {burn}",
    '🔥 Breaking news: {name} skipped {muscle} for {d} days straight. {burn}',
    "🚨 Missing person report: {name}'s {muscle} gains. Last seen {d} days ago. {burn}",
  ],
};

/// Muscle-balance roasts.
enum BalanceIssue { pushHeavy, pullHeavy, legsLow, balanced }

const balanceRoasts = <RoastLevel, Map<BalanceIssue, String>>{
  RoastLevel.gentle: {
    BalanceIssue.pushHeavy: 'Your push:pull ratio is {r}. Add a few rows or pull-ups to balance things out 🙂',
    BalanceIssue.pullHeavy: 'Push:pull is {r}. Some bench or overhead press would round you out 🙂',
    BalanceIssue.legsLow: 'Only {p}% of your sets are legs. A leg day this week would balance things 🙂',
    BalanceIssue.balanced: 'Nicely balanced training. Keep it up! 💪',
  },
  RoastLevel.sergeant: {
    BalanceIssue.pushHeavy: 'Push:pull is {r}, recruit! You PULL until that evens out. Rows. NOW. 🪖',
    BalanceIssue.pullHeavy: 'Push:pull is {r}! Get on that bench and PRESS, soldier! 🪖',
    BalanceIssue.legsLow: "{p}% legs?! That's not a training split, recruit, that's DESERTION! 🪖",
    BalanceIssue.balanced: "Balanced. Acceptable, recruit. Don't get comfortable. 🪖",
  },
  RoastLevel.noMercy: {
    BalanceIssue.pushHeavy: 'Your push:pull ratio is {r} — your posture is filing a complaint 🦐',
    BalanceIssue.pullHeavy: "Push:pull {r}. All pull, no push — you're a human grappling hook 🪝",
    BalanceIssue.legsLow: '{p}% of your sets are legs. Upper body of a Greek god, legs of a Greek salad 🥗',
    BalanceIssue.balanced: 'Balanced. Annoyingly. Nothing to roast… yet 😒',
  },
};

String fillRoast(String template, {int? d, String? name, String? muscle, String? burn, String? r, int? p}) {
  var s = template;
  if (d != null) s = s.replaceAll('{d}', '$d');
  if (name != null) {
    s = s.replaceAll('{NAME}', name.toUpperCase()).replaceAll('{name}', name);
  }
  if (muscle != null) s = s.replaceAll('{muscle}', muscle);
  if (burn != null) s = s.replaceAll('{burn}', burn);
  if (r != null) s = s.replaceAll('{r}', r);
  if (p != null) s = s.replaceAll('{p}', '$p');
  return s;
}
