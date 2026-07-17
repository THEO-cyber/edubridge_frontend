import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';

import '../../core/download_manager.dart';

const _navy = Color(0xFF0F172A);
const _gold = Color(0xFFF59E0B);

/// Lessons saved on this device. Everything here plays with no connection.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const DownloadsScreen());

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _dm = DownloadManager.instance;
  List<OfflineLesson> _items = [];
  int _bytes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _dm.list();
    final bytes = await _dm.totalBytes();
    if (!mounted) return;
    setState(() {
      _items = items..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      _bytes = bytes;
      _loading = false;
    });
  }

  Future<void> _remove(OfflineLesson l) async {
    await _dm.delete(l.lessonId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download removed'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _clearAll() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove all downloads?'),
        content: Text(
            'This frees ${DownloadManager.formatBytes(_bytes)} on this device. You can download the lessons again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _dm.deleteAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Downloads',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Remove all',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : _items.isEmpty
              ? _empty()
              : Column(
                  children: [
                    _storageBar(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _tile(_items[i]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _storageBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _navy.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sd_storage_rounded, color: _gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_items.length} lesson${_items.length == 1 ? '' : 's'} available offline',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _navy, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Using ${DownloadManager.formatBytes(_bytes)} of storage',
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tile(OfflineLesson l) => Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _navy.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: () => Navigator.push(context, _OfflinePlayer.route(l)),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_circle_fill_rounded, color: _navy),
          ),
          title: Text(l.lessonTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${l.courseTitle}  •  ${DownloadManager.formatBytes(l.bytes)}  •  ${l.quality}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ),
          trailing: IconButton(
            tooltip: 'Remove',
            onPressed: () => _remove(l),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
        ),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.06), shape: BoxShape.circle),
                child: const Icon(Icons.download_for_offline_rounded,
                    size: 52, color: _gold),
              ),
              const SizedBox(height: 20),
              const Text('No downloads yet',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 10),
              const Text(
                'Tap Download on any lesson to save it here.\nDownloaded lessons play without internet.',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

/// Plays a saved lesson straight from disk — no network involved.
class _OfflinePlayer extends StatefulWidget {
  final OfflineLesson lesson;
  const _OfflinePlayer({required this.lesson});

  static Route<void> route(OfflineLesson l) =>
      MaterialPageRoute(builder: (_) => _OfflinePlayer(lesson: l));

  @override
  State<_OfflinePlayer> createState() => _OfflinePlayerState();
}

class _OfflinePlayerState extends State<_OfflinePlayer> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final path = await DownloadManager.instance.localPath(widget.lesson.lessonId);
      if (path == null) {
        setState(() => _error = 'This download is no longer on the device.');
        return;
      }
      final vpc = VideoPlayerController.file(File(path));
      await vpc.initialize();
      if (!mounted) return;
      setState(() {
        _vpc = vpc;
        _chewie = ChewieController(
          videoPlayerController: vpc,
          autoPlay: true,
          looping: false,
          allowPlaybackSpeedChanging: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: _gold,
            handleColor: _gold,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not play this file.');
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.lesson.lessonTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15)),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              )
            : _chewie == null
                ? const CircularProgressIndicator(color: _gold)
                : AspectRatio(
                    aspectRatio: _vpc!.value.aspectRatio,
                    child: Chewie(controller: _chewie!),
                  ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Row(
          children: const [
            Icon(Icons.offline_pin_rounded, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text('Playing offline — no data used',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
