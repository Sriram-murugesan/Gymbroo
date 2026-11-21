import 'package:flutter/material.dart';

/// Minimal toned black + red.
class C {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF121212);
  static const surface2 = Color(0xFF1A1A1A);
  static const line = Color(0xFF262626);
  static const text = Color(0xFFECECEC);
  static const muted = Color(0xFF8A8A8A);
  static const accent = Color(0xFFDC2F2F);
  static const accentDim = Color(0xFF3A1416);
  static const up = Color(0xFFF2F2F2);
  static const down = Color(0xFFE5484D);
  static const roast = Color(0xFFE5383B);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.accent,
      onPrimary: Colors.white,
      secondary: C.accent,
      surface: C.surface,
      onSurface: C.text,
      error: C.down,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: C.bg, surfaceTintColor: Colors.transparent, elevation: 0),
    dividerColor: C.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: C.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.accent, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        backgroundColor: C.surface2,
        side: const BorderSide(color: C.line),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.text,
      contentTextStyle: TextStyle(color: C.bg, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.accentDim,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? C.accent : C.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.accent : C.muted)),
    ),
  );
}

/// A rounded card with an uppercase section title.
class Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color borderColor;
  final Gradient? gradient;
  const Panel({super.key, this.title, required this.child, this.borderColor = C.line, this.gradient});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gradient == null ? C.surface : null,
          gradient: gradient,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!.toUpperCase(),
                  style: const TextStyle(fontSize: 12, letterSpacing: 1.1, color: C.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      );
}

const mutedStyle = TextStyle(color: C.muted, fontSize: 13);
const boldStyle = TextStyle(fontWeight: FontWeight.w600);

/// "▲ +4.7kg" / "▼ -2kg" / "＝ same"
Widget deltaText(double a, double b, String unit, String Function(double) fmt) {
  final d = b - a;
  if (d.abs() < 0.05) return const Text('= same', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700));
  return Text(d > 0 ? '▲ +${fmt(d)}$unit' : '▼ ${fmt(d)}$unit',
      style: TextStyle(color: d > 0 ? C.up : C.down, fontWeight: FontWeight.w800));
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center), duration: const Duration(milliseconds: 2400)));
}
