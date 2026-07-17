import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import 'secure_storage.dart';

/// A lesson the learner has saved for offline study.
class OfflineLesson {
  final String lessonId;
  final String lessonTitle;
  final String courseId;
  final String courseTitle;
  final String fileName; // stored relative — absolute paths change between installs
  final int bytes;
  final String quality;
  final DateTime downloadedAt;

  const OfflineLesson({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    required this.fileName,
    required this.bytes,
    required this.quality,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'fileName': fileName,
        'bytes': bytes,
        'quality': quality,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineLesson.fromJson(Map<String, dynamic> j) => OfflineLesson(
        lessonId: j['lessonId'] as String,
        lessonTitle: (j['lessonTitle'] ?? 'Lesson') as String,
        courseId: (j['courseId'] ?? '') as String,
        courseTitle: (j['courseTitle'] ?? 'Course') as String,
        fileName: j['fileName'] as String,
        bytes: (j['bytes'] ?? 0) as int,
        quality: (j['quality'] ?? 'source') as String,
        downloadedAt:
            DateTime.tryParse((j['downloadedAt'] ?? '') as String) ?? DateTime.now(),
      );
}

/// Progress for an in-flight download. [ratio] is null while the server has not
/// told us the total size, in which case the UI shows an indeterminate bar.
class DownloadProgress {
  final String lessonId;
  final int received;
  final int? total;
  final bool done;
  final String? error;

  const DownloadProgress(this.lessonId,
      {this.received = 0, this.total, this.done = false, this.error});

  double? get ratio =>
      (total != null && total! > 0) ? (received / total!).clamp(0.0, 1.0) : null;
}

/// Downloads lessons for offline study and keeps track of what is on the device.
///
/// Deliberately dependency-free: files go in the app documents directory via
/// path_provider, and a small JSON registry beside them records what was saved.
/// The video bytes are streamed to disk so a 200 MB lesson never sits in memory.
class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  static const _registryFile = 'registry.json';
  static const _folder = 'offline_lessons';

  final _controllers = <String, StreamController<DownloadProgress>>{};
  final _cancelled = <String>{};
  List<OfflineLesson>? _cache;

  /// Emits progress for a lesson currently downloading.
  Stream<DownloadProgress> progressFor(String lessonId) =>
      _controllers.putIfAbsent(
        lessonId,
        () => StreamController<DownloadProgress>.broadcast(),
      ).stream;

  bool isDownloading(String lessonId) => _controllers.containsKey(lessonId);

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _registry() async => File('${(await _dir()).path}/$_registryFile');

  // ── registry ──────────────────────────────────────────────────────────────

  Future<List<OfflineLesson>> list() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _registry();
      if (!await f.exists()) return _cache = [];
      final raw = jsonDecode(await f.readAsString());
      final items = (raw as List)
          .map((e) => OfflineLesson.fromJson(e as Map<String, dynamic>))
          .toList();
      // Drop entries whose file was removed by the OS or a manual clear.
      final dir = await _dir();
      final alive = <OfflineLesson>[];
      for (final i in items) {
        if (await File('${dir.path}/${i.fileName}').exists()) alive.add(i);
      }
      if (alive.length != items.length) await _save(alive);
      return _cache = alive;
    } catch (e) {
      debugPrint('DownloadManager: registry unreadable ($e) — starting empty');
      return _cache = [];
    }
  }

  Future<void> _save(List<OfflineLesson> items) async {
    _cache = items;
    final f = await _registry();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<bool> isDownloaded(String lessonId) async =>
      (await list()).any((e) => e.lessonId == lessonId);

  /// Absolute path to a downloaded lesson, or null if it is not saved.
  Future<String?> localPath(String lessonId) async {
    final items = await list();
    final match = items.where((e) => e.lessonId == lessonId).firstOrNull;
    if (match == null) return null;
    final path = '${(await _dir()).path}/${match.fileName}';
    return await File(path).exists() ? path : null;
  }

  Future<int> totalBytes() async =>
      (await list()).fold<int>(0, (sum, e) => sum + e.bytes);

  // ── download ──────────────────────────────────────────────────────────────

  /// Fetches [videoId]'s file and stores it against [lessonId].
  ///
  /// Quality defaults to the smallest rendition server-side, which is what a
  /// learner on a metered bundle wants. Returns true on success.
  Future<bool> download({
    required String lessonId,
    required String videoId,
    required String lessonTitle,
    required String courseId,
    required String courseTitle,
    String? quality,
  }) async {
    if (await isDownloaded(lessonId)) return true;
    if (isDownloading(lessonId)) return false;

    final ctrl = _controllers.putIfAbsent(
        lessonId, () => StreamController<DownloadProgress>.broadcast());
    _cancelled.remove(lessonId);
    ctrl.add(DownloadProgress(lessonId));

    File? partial;
    try {
      final token = await SecureStorage.getToken() ?? '';

      // 1. Ask the API where the file is and how big it will be.
      final q = quality != null ? '?quality=$quality' : '';
      final metaRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/video-processing/download-url/$videoId$q'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (metaRes.statusCode != 200) {
        throw Exception('Could not get a download link (${metaRes.statusCode})');
      }
      final body = jsonDecode(metaRes.body);
      final data = (body is Map && body['data'] != null) ? body['data'] : body;
      final url = data['url'] as String?;
      if (url == null) throw Exception('No download URL returned');
      final serverSize = (data['sizeBytes'] as num?)?.toInt();
      final chosenQuality = (data['quality'] ?? 'source') as String;

      // 2. Stream to a .part file so an interrupted download is never mistaken
      //    for a complete one.
      final dir = await _dir();
      final fileName = '$lessonId.mp4';
      partial = File('${dir.path}/$fileName.part');
      if (await partial.exists()) await partial.delete();

      final req = http.Request('GET', Uri.parse(url));
      final resp = await http.Client().send(req).timeout(const Duration(minutes: 2));
      if (resp.statusCode != 200) {
        throw Exception('Download failed (${resp.statusCode})');
      }

      final total = resp.contentLength ?? serverSize;
      var received = 0;
      final sink = partial.openWrite();

      await for (final chunk in resp.stream) {
        if (_cancelled.contains(lessonId)) {
          await sink.close();
          if (await partial.exists()) await partial.delete();
          ctrl.add(DownloadProgress(lessonId, error: 'Cancelled'));
          return false;
        }
        sink.add(chunk);
        received += chunk.length;
        ctrl.add(DownloadProgress(lessonId, received: received, total: total));
      }
      await sink.flush();
      await sink.close();

      // 3. Only now promote it to the real filename.
      final finalFile = File('${dir.path}/$fileName');
      if (await finalFile.exists()) await finalFile.delete();
      await partial.rename(finalFile.path);

      final items = await list();
      items.removeWhere((e) => e.lessonId == lessonId);
      items.add(OfflineLesson(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        courseId: courseId,
        courseTitle: courseTitle,
        fileName: fileName,
        bytes: await finalFile.length(),
        quality: chosenQuality,
        downloadedAt: DateTime.now(),
      ));
      await _save(items);

      ctrl.add(DownloadProgress(lessonId,
          received: received, total: total, done: true));
      return true;
    } catch (e) {
      if (partial != null && await partial.exists()) {
        await partial.delete(); // never leave a half file behind
      }
      ctrl.add(DownloadProgress(lessonId, error: _friendly(e)));
      return false;
    } finally {
      await _controllers.remove(lessonId)?.close();
      _cancelled.remove(lessonId);
    }
  }

  void cancel(String lessonId) => _cancelled.add(lessonId);

  Future<void> delete(String lessonId) async {
    final items = await list();
    final match = items.where((e) => e.lessonId == lessonId).firstOrNull;
    if (match == null) return;
    final f = File('${(await _dir()).path}/${match.fileName}');
    if (await f.exists()) await f.delete();
    items.removeWhere((e) => e.lessonId == lessonId);
    await _save(items);
  }

  Future<void> deleteAll() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
    _cache = [];
  }

  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'No internet connection';
    }
    if (s.contains('TimeoutException')) return 'The connection timed out';
    return s.replaceFirst('Exception: ', '');
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    const mb = 1024 * 1024;
    if (bytes < mb) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * mb)).toStringAsFixed(2)} GB';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
