import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'notifications.dart';
import 'screens/goals_screen.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/onboarding.dart';
import 'screens/progress_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: C.bg,
    systemNavigationBarColor: C.surface,
    statusBarIconBrightness: Brightness.light,
  ));
  final state = AppState();
  await state.load();
  await Notifier.init();
  state.onChanged = () => Notifier.requestReschedule(state);
  runApp(GymbrooApp(state: state));
  // Schedule reminders after the first frame so start-up isn't delayed.
  WidgetsBinding.instance.addPostFrameCallback((_) => Notifier.reschedule(state));
}

class GymbrooApp extends StatelessWidget {
  final AppState state;
  const GymbrooApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Gymbroo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Shell(state: state),
      );
}

class Shell extends StatefulWidget {
  final AppState state;
  const Shell({super.key, required this.state});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int tab = 0;
  String logMuscle = 'chest';
  int logNonce = 0;

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First launch: "Set your goals, broo" popup.
      if (!s.onboarded) await showOnboarding(context, s);
      // Then ask for notification permission (Android 13+).
      if (Notifier.supported && s.notify && mounted) {
        final ok = await Notifier.requestPermission();
        if (!ok && mounted) s.setNotify(false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    switch (st) {
      case AppLifecycleState.resumed:
        // Maybe a new day while in the background → refresh roasts/reminders.
        Notifier.requestReschedule(s);
        setState(() {});
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        s.flush(); // never lose the last few taps when the app is closed
    }
  }

  void _quickLog(String muscleId) => setState(() {
        logMuscle = muscleId;
        logNonce++;
        tab = 1;
      });

  Future<void> _enableNotifications() async {
    if (!Notifier.supported) {
      s.setNotify(true);
      if (mounted) toast(context, 'Notifications work in the Android app');
      return;
    }
    final ok = await Notifier.requestPermission();
    if (!mounted) return;
    if (ok) {
      s.setNotify(true);
      toast(context, '🔔 Daily 7 PM reminders on');
    } else {
      toast(context, 'Permission blocked — enable notifications for Gymbroo in Android settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = weekStartOf(todayStr());
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final body = switch (tab) {
          0 => HomeScreen(state: s, onQuickLog: _quickLog, onEnableNotifications: _enableNotifications),
          1 => LogScreen(key: ValueKey(logNonce), state: s, initialMuscle: logMuscle),
          2 => ProgressScreen(state: s),
          _ => GoalsScreen(
              state: s,
              onEnableNotifications: _enableNotifications,
              onTestNotification: () => Notifier.supported
                  ? Notifier.showNow(s)
                  : toast(context, 'Notifications work in the Android app'),
              onSampleLoaded: () {
                setState(() => tab = 0);
                toast(context, 'Sample data loaded — check the roasts 🔥');
              },
            ),
        };
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: const Text.rich(TextSpan(
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
              children: [TextSpan(text: 'GYM'), TextSpan(text: 'BROO', style: TextStyle(color: C.accent))],
            )),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Text('${shortDate(ws)} – ${shortDate(addDays(ws, 6))}', style: mutedStyle)),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: C.line),
            ),
          ),
          body: SafeArea(child: body),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            height: 66,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Log'),
              NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Progress'),
              NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag_rounded), label: 'Goals'),
            ],
          ),
        );
      },
    );
  }
}
