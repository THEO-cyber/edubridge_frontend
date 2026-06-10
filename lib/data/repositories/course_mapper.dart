import '../../domain/entities/course_entity.dart';

String safeStr(dynamic v, [String fb = '']) {
  if (v == null) return fb;
  if (v is String) return v;
  if (v is Map) {
    return (v['name'] ?? v['title'] ?? v['id'] ?? v['_id'] ?? fb).toString();
  }
  return v.toString();
}

String? safeStrMaybe(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  if (v is Map) {
    return (v['url'] ?? v['imageUrl'] ?? v['thumbnail'] ?? v['original'] ??
            v['name'] ?? v['id'] ?? v['_id'])
        ?.toString();
  }
  return v.toString();
}

double safeDbl(dynamic v) =>
    double.tryParse((v ?? '0').toString()) ?? 0.0;

int safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

DateTime safeDt(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

String instructorIdFrom(Map<String, dynamic> e) {
  final flat = e['instructorId'];
  if (flat != null && flat is! Map) return flat.toString();
  final obj = e['instructor'];
  if (obj is Map) return (obj['id'] ?? obj['_id'] ?? '').toString();
  return '';
}

String? instructorNameFrom(Map<String, dynamic> e) {
  final flat = e['instructorName'];
  if (flat != null && flat is! Map) return flat.toString();
  final obj = e['instructor'];
  if (obj is Map) {
    final first = (obj['firstName'] ?? obj['first_name'] ?? '').toString().trim();
    final last = (obj['lastName'] ?? obj['last_name'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return (obj['name'] ?? obj['email'])?.toString();
  }
  return null;
}

CourseEntity courseFromMap(Map<String, dynamic> e) {
  final price = safeDbl(e['price']);
  return CourseEntity(
    id: safeStr(e['id'] ?? e['_id']),
    title: safeStr(e['title'], 'Untitled'),
    description: safeStr(e['description']),
    instructorId: instructorIdFrom(e),
    imageUrl: safeStrMaybe(e['imageUrl'] ?? e['thumbnail'] ?? e['coverImage']),
    instructorName: instructorNameFrom(e),
    price: price,
    rating: safeDbl(e['rating'] ?? e['averageRating']),
    reviewCount: safeInt(e['reviewCount'] ?? e['totalReviews']),
    studentCount: safeInt(e['studentCount'] ?? e['totalStudents'] ?? e['enrollmentCount']),
    category: safeStr(e['category'], 'General'),
    level: safeStr(e['level'], 'Beginner'),
    duration: safeStrMaybe(e['duration']),
    tags: (e['tags'] is List)
        ? List<String>.from((e['tags'] as List).map((t) => safeStr(t)))
        : [],
    isFree: price == 0,
    createdAt: safeDt(e['createdAt'] ?? e['created_at']),
  );
}
