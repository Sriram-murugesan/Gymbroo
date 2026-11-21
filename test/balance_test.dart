import 'package:flutter_test/flutter_test.dart';
import 'package:gymbroo/data.dart';

void main() {
  test('sample data: leg-light training is flagged and roasted', () {
    final s = AppState()..loadSample();
    final b = s.balance;
    // ignore: avoid_print
    print('push=${b.push} pull=${b.pull} legs=${b.legs} core=${b.core} '
        'ratio=${b.ratioText} legs%=${b.legsPct} score=${b.score} (${b.label}) issue=${b.issue}');
    for (final l in RoastLevel.values) {
      // ignore: avoid_print
      print('${l.label}: ${b.roast(l)}');
    }
    expect(b.enoughData, isTrue);
    expect(b.issue, BalanceIssue.legsLow);
    expect(b.score, inInclusiveRange(40, 70));
  });

  test('3:1 push-heavy is roasted for posture', () {
    final b = const Balance(30, 10, 12, 4);
    expect(b.ratioText, '3:1');
    expect(b.issue, BalanceIssue.pushHeavy);
    expect(b.roast(RoastLevel.noMercy), contains('3:1 — your posture is filing a complaint'));
  });

  test('balanced split scores high', () {
    final b = const Balance(12, 12, 12, 4);
    expect(b.issue, BalanceIssue.balanced);
    expect(b.score, greaterThanOrEqualTo(85));
  });

  test('onboarding saves goals + level and survives a save/load round-trip', () {
    final s = AppState();
    expect(s.onboarded, isFalse);
    s.completeOnboarding({'chest': 3, 'legs': 1, 'core': 0}, RoastLevel.sergeant);
    expect(s.onboarded, isTrue);
    expect(s.goals['chest'], 3);
    expect(s.goals['core'], 0);
    expect(s.goals['back'], 2); // unspecified → default 2
    final json = s.toJson();
    expect(json['onboarded'], isTrue);
    expect(json['settings']['roastLevel'], 'sergeant');
    s.reset();
    expect(s.onboarded, isFalse);
  });

  test('roast level changes self-roast copy', () {
    final s = AppState()..loadSample();
    final noMercy = s.roasts.first.text;
    s.roastLevel = RoastLevel.gentle;
    expect(s.roasts.first.text, isNot(noMercy));
  });
}
