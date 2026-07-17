import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import 'http_utils.dart';

/// A category as the learner apps need it.
class CategoryLite {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final int courseCount;

  const CategoryLite({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon,
    this.courseCount = 0,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'slug': slug, 'icon': icon, 'courseCount': courseCount};

  factory CategoryLite.fromJson(Map<String, dynamic> j) {
    // The API returns Prisma's `_count: { courses }`.
    final count = j['_count'];
    final courses =
        count is Map ? (count['courses'] as num?)?.toInt() : (j['courseCount'] as num?)?.toInt();
    return CategoryLite(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? j['title'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      icon: j['icon']?.toString(),
      courseCount: courses ?? 0,
    );
  }
}

/// Single source of categories for the app.
///
/// Categories are owned by the super-admin, so the app never invents them. The
/// last successful response is written to disk and reused when the network is
/// unavailable — showing the real catalogue as it was last seen rather than a
/// hard-coded guess that sends a learner to a category that does not exist.
class CategoryStore {
  CategoryStore._();

  static const _file = 'categories.json';
  static List<CategoryLite>? _memory;

  static Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_file');
  }

  /// Live categories, falling back to the last known good list when offline.
  /// Returns an empty list if we have never successfully fetched — callers
  /// must hide their category UI rather than substitute placeholders.
  static Future<List<CategoryLite>> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _memory != null) return _memory!;

    try {
      final res = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.searchCategories),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = (body is Map && body['data'] != null) ? body['data'] : body;
        final list = data is List ? data : (data['categories'] ?? data['items'] ?? []);
        final cats = (list as List)
            .whereType<Map>()
            .map((e) => CategoryLite.fromJson(e.cast<String, dynamic>()))
            .where((c) => c.name.isNotEmpty)
            .toList();
        if (cats.isNotEmpty) {
          _memory = cats;
          await _persist(cats);
          return cats;
        }
      }
    } catch (_) {
      // fall through to the cached copy
    }

    final cached = await _readCache();
    _memory = cached;
    return cached;
  }

  static Future<void> _persist(List<CategoryLite> cats) async {
    try {
      final f = await _cacheFile();
      await f.writeAsString(jsonEncode(cats.map((c) => c.toJson()).toList()));
    } catch (_) {
      // a cache write failure must never break the screen
    }
  }

  static Future<List<CategoryLite>> _readCache() async {
    try {
      final f = await _cacheFile();
      if (!await f.exists()) return const [];
      final raw = jsonDecode(await f.readAsString());
      return (raw as List)
          .whereType<Map>()
          .map((e) => CategoryLite.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
