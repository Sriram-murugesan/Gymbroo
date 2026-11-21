import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';

/// Content of a shareable card.
class CardData {
  final String kicker; // small red line at top, e.g. "LEGS · 20 DAYS SKIPPED"
  final String? stat; // optional big number, e.g. "58/100" or "20 DAYS"
  final String? statLabel; // caption under the big number
  final String text; // the roast itself
  final String shareText; // text sent along with the image
  const CardData({required this.kicker, this.stat, this.statLabel, required this.text, required this.shareText});
}

/// The card itself: 360×450 logical px, exported at 3× = 1080×1350 (Instagram 4:5).
class RoastCard extends StatelessWidget {
  final CardData data;
  const RoastCard({super.key, required this.data});

  static const size = Size(360, 450);

  @override
  Widget build(BuildContext context) {
    final long = data.text.length > 110;
    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: C.bg,
          gradient: RadialGradient(
            center: Alignment(0.9, -1.0),
            radius: 1.4,
            colors: [Color(0xFF3A1416), C.bg],
          ),
        ),
        child: Stack(children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: C.accent)),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 26, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                data.kicker.toUpperCase(),
                style: const TextStyle(color: C.accent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4),
              ),
              if (data.stat != null) ...[
                const SizedBox(height: 14),
                Text(data.stat!,
                    style: const TextStyle(color: C.text, fontSize: 54, fontWeight: FontWeight.w900, height: 1)),
                if (data.statLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data.statLabel!, style: const TextStyle(color: C.muted, fontSize: 13)),
                  ),
              ],
              const Spacer(),
              Text(
                data.text,
                style: TextStyle(
                  color: C.text,
                  fontSize: long ? 19 : (data.stat == null ? 26 : 22),
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text.rich(TextSpan(
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 18, color: C.text),
                  children: [TextSpan(text: 'GYM'), TextSpan(text: 'BROO', style: TextStyle(color: C.accent))],
                )),
                const Spacer(),
                Text('track it. or get roasted.',
                    style: TextStyle(color: C.muted.withValues(alpha: .8), fontSize: 11, fontStyle: FontStyle.italic)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Writes the card into the app's private cache, in its own folder, after
/// deleting older cards — so shares never pile up on the phone.
Future<File> _writeShareFile(Uint8List bytes) async {
  final dir = Directory('${(await getTemporaryDirectory()).path}/share_cards');
  if (await dir.exists()) {
    await for (final f in dir.list()) {
      try {
        await f.delete();
      } catch (_) {/* still open in another app — cleaned next time */}
    }
  } else {
    await dir.create(recursive: true);
  }
  final f = File('${dir.path}/gymbroo-${DateTime.now().millisecondsSinceEpoch}.png');
  return f.writeAsBytes(bytes, flush: true);
}

/// Shares the backup as a .json file through the system share sheet
/// (Drive, Files, email…) instead of the clipboard, which other apps can read.
Future<void> shareBackupFile(String json) async {
  final name = 'gymbroo-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json';
  final XFile file;
  if (kIsWeb) {
    file = XFile.fromData(utf8.encode(json), mimeType: 'application/json', name: name);
  } else {
    final dir = Directory('${(await getTemporaryDirectory()).path}/exports');
    if (await dir.exists()) await dir.delete(recursive: true); // keep only the newest
    await dir.create(recursive: true);
    final f = await File('${dir.path}/$name').writeAsString(json, flush: true);
    file = XFile(f.path, mimeType: 'application/json');
  }
  await SharePlus.instance.share(ShareParams(files: [file], subject: 'Gymbroo backup'));
}

/// Shows a preview of the card with a Share button.
Future<void> showShareCard(BuildContext context, CardData data) => showDialog(
      context: context,
      builder: (c) => _ShareDialog(data: data),
    );

class _ShareDialog extends StatefulWidget {
  final CardData data;
  const _ShareDialog({required this.data});

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3); // 1080×1350
      final Uint8List bytes;
      try {
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      } finally {
        image.dispose(); // free the ~6 MB native image right away
      }
      final XFile file;
      if (kIsWeb) {
        file = XFile.fromData(bytes, mimeType: 'image/png', name: 'gymbroo-roast.png');
      } else {
        file = XFile((await _writeShareFile(bytes)).path, mimeType: 'image/png');
      }
      await SharePlus.instance.share(ShareParams(files: [file], text: widget.data.shareText));
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) toast(context, "Couldn't share right now — try again");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() async {
    await SharePlus.instance.share(ShareParams(text: widget.data.shareText));
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: C.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RepaintBoundary(key: _key, child: RoastCard(data: widget.data)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              const Spacer(),
              OutlinedButton(onPressed: _shareText, child: const Text('Text only')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Share'),
              ),
            ]),
          ]),
        ),
      );
}
