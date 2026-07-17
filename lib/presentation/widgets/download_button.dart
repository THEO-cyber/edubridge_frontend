import 'package:flutter/material.dart';

import '../../core/download_manager.dart';

const _navy = Color(0xFF0F172A);
const _gold = Color(0xFFF59E0B);

/// Download / downloaded / in-progress control for a single lesson.
///
/// Keeps its own state rather than depending on a bloc so it can be dropped into
/// the player, the lesson list or the course page without extra wiring.
class DownloadButton extends StatefulWidget {
  final String lessonId;
  final String? videoId;
  final String lessonTitle;
  final String courseId;
  final String courseTitle;
  final bool compact;

  const DownloadButton({
    super.key,
    required this.lessonId,
    required this.videoId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    this.compact = false,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  final _dm = DownloadManager.instance;
  bool _downloaded = false;
  bool _busy = false;
  double? _ratio;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final d = await _dm.isDownloaded(widget.lessonId);
    if (mounted) setState(() => _downloaded = d);
  }

  Future<void> _start() async {
    if (widget.videoId == null || widget.videoId!.isEmpty) {
      _toast('This lesson has no video to download yet.');
      return;
    }
    setState(() {
      _busy = true;
      _ratio = null;
    });

    final sub = _dm.progressFor(widget.lessonId).listen((p) {
      if (!mounted) return;
      setState(() => _ratio = p.ratio);
      if (p.error != null) _toast(p.error!);
    });

    final ok = await _dm.download(
      lessonId: widget.lessonId,
      videoId: widget.videoId!,
      lessonTitle: widget.lessonTitle,
      courseId: widget.courseId,
      courseTitle: widget.courseTitle,
    );

    await sub.cancel();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _downloaded = ok;
    });
    if (ok) _toast('Saved for offline study');
  }

  Future<void> _remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove download?'),
        content: const Text(
            'The lesson will be deleted from this device. You can download it again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _dm.delete(widget.lessonId);
    if (mounted) setState(() => _downloaded = false);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return _shell(
        icon: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: _ratio, // null → indeterminate until the size is known
            color: _gold,
          ),
        ),
        label: _ratio == null ? 'Starting…' : '${((_ratio ?? 0) * 100).round()}%',
        onTap: () => _dm.cancel(widget.lessonId),
      );
    }

    if (_downloaded) {
      return _shell(
        icon: const Icon(Icons.download_done_rounded, size: 20, color: Colors.green),
        label: 'Downloaded',
        onTap: _remove,
      );
    }

    return _shell(
      icon: const Icon(Icons.download_rounded, size: 20, color: _navy),
      label: 'Download',
      onTap: _start,
    );
  }

  Widget _shell({required Widget icon, required String label, VoidCallback? onTap}) {
    if (widget.compact) {
      return IconButton(onPressed: onTap, icon: icon, tooltip: label);
    }
    return TextButton.icon(
      onPressed: onTap,
      icon: icon,
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
