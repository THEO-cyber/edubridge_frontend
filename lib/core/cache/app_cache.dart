class _Entry {
  final dynamic value;
  final DateTime expiresAt;
  _Entry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Lightweight in-memory stale-while-revalidate cache.
///
/// Keys are namespaced strings (e.g. "lessons_<courseId>").
/// Data survives widget rebuilds and navigation; cleared on app restart.
class AppCache {
  AppCache._();
  static final Map<String, _Entry> _store = {};

  /// Retrieve cached value. Returns null if missing or expired.
  static T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  /// Store a value with an optional TTL (default 5 minutes).
  static void set(
    String key,
    dynamic value, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    _store[key] = _Entry(value, DateTime.now().add(ttl));
  }

  /// Remove a single key (call after mutations — create/update/delete).
  static void invalidate(String key) => _store.remove(key);

  /// Remove all keys that start with [prefix].
  static void invalidatePrefix(String prefix) =>
      _store.removeWhere((k, _) => k.startsWith(prefix));

  /// Wipe everything (e.g. on logout).
  static void clear() => _store.clear();
}
