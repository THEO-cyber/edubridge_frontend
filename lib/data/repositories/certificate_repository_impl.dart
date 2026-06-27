import 'dart:typed_data';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/repositories/certificate_repository.dart';
import '../datasources/certificate_remote_data_source.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  final CertificateRemoteDataSource remoteDataSource;
  CertificateRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CertificateEntity>> fetchCertificates(String token) async {
    final data = await remoteDataSource.fetchCertificates(token);
    return data.map((e) => _fromMap(e)).toList();
  }

  Future<CertificateEntity> getCertificateById(
    String certificateId,
    String token,
  ) async {
    final e = await remoteDataSource.getCertificateById(certificateId, token);
    return _fromMap(e);
  }

  static CertificateEntity _fromMap(Map<String, dynamic> e) => CertificateEntity(
        id: e['id']?.toString() ?? '',
        enrollmentId: e['enrollmentId']?.toString() ?? '',
        studentId: e['studentId']?.toString() ?? '',
        studentName: _extractStudentName(e),
        courseId: _extractCourseId(e),
        courseName: _extractCourseName(e),
        instructorName: _extractInstructorName(e),
        issuedBy: e['issuedBy']?.toString().isNotEmpty == true
            ? e['issuedBy'].toString()
            : 'EduBridge Academy',
        issuedAt:
            DateTime.tryParse(e['issuedAt']?.toString() ?? '') ?? DateTime.now(),
        certificateUrl: e['certificateUrl']?.toString() ??
            e['pdfUrl']?.toString() ?? '',
        certificateNumber: e['certificateNumber']?.toString() ?? '',
      );

  static String _extractStudentName(Map<String, dynamic> e) {
    // Backend now uses recipientName as the primary field
    for (final key in ['recipientName', 'studentName']) {
      final v = e[key]?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    final user = e['user'];
    if (user is Map) {
      final full = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      if (full.isNotEmpty) return full;
      if ((user['name'] ?? '').toString().isNotEmpty) return user['name'].toString();
    }
    final student = e['student'];
    if (student is Map) {
      final full = '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
      if (full.isNotEmpty) return full;
      if ((student['name'] ?? '').toString().isNotEmpty) return student['name'].toString();
    }
    return '';
  }

  static String _extractCourseName(Map<String, dynamic> e) {
    // Backend now uses courseTitle as the primary field
    for (final key in ['courseTitle', 'courseName']) {
      final v = e[key]?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    final course = e['course'];
    if (course is Map) {
      final v = (course['title'] ?? course['name'] ?? '').toString();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String _extractCourseId(Map<String, dynamic> e) {
    if ((e['courseId'] ?? '').toString().isNotEmpty) return e['courseId'].toString();
    final course = e['course'];
    if (course is Map) return course['id']?.toString() ?? '';
    return '';
  }

  static String _extractInstructorName(Map<String, dynamic> e) {
    if ((e['instructorName'] ?? '').toString().isNotEmpty) {
      return e['instructorName'].toString();
    }
    if ((e['signature'] ?? '').toString().isNotEmpty &&
        e['signature'].toString() != 'EduBridge Academy') {
      return e['signature'].toString();
    }
    final course = e['course'];
    if (course is Map) {
      final instr = course['instructor'] ?? course['tutor'];
      if (instr is Map) {
        final full = '${instr['firstName'] ?? ''} ${instr['lastName'] ?? ''}'.trim();
        if (full.isNotEmpty) return full;
        if ((instr['name'] ?? '').toString().isNotEmpty) return instr['name'].toString();
      }
    }
    return '';
  }

  Future<Uint8List> downloadCertificate(String certificateId, String token) async {
    return await remoteDataSource.downloadCertificate(certificateId, token);
  }

  Future<bool> verifyCertificate(String certificateNumber) async {
    return await remoteDataSource.verifyCertificate(certificateNumber);
  }
}
