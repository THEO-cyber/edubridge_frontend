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
    return data
        .map(
          (e) => CertificateEntity(
            id: e['id'] ?? '',
            enrollmentId: e['enrollmentId'] ?? '',
            studentId: e['studentId'] ?? '',
            studentName: _extractStudentName(e),
            courseId: e['courseId'] ?? '',
            courseName: _extractCourseName(e),
            issuedAt: DateTime.tryParse(e['issuedAt']?.toString() ?? '') ?? DateTime.now(),
            certificateUrl: e['certificateUrl'] ?? '',
            certificateNumber: e['certificateNumber'] ?? '',
          ),
        )
        .toList();
  }

  Future<CertificateEntity> getCertificateById(
    String certificateId,
    String token,
  ) async {
    final e = await remoteDataSource.getCertificateById(certificateId, token);
    return CertificateEntity(
      id: e['id'] ?? '',
      enrollmentId: e['enrollmentId'] ?? '',
      studentId: e['studentId'] ?? '',
      studentName: _extractStudentName(e),
      courseId: e['courseId'] ?? '',
      courseName: _extractCourseName(e),
      issuedAt: DateTime.tryParse(e['issuedAt']?.toString() ?? '') ?? DateTime.now(),
      certificateUrl: e['certificateUrl'] ?? '',
      certificateNumber: e['certificateNumber'] ?? '',
    );
  }

  static String _extractStudentName(Map<String, dynamic> e) {
    if ((e['studentName'] ?? '').toString().isNotEmpty) return e['studentName'].toString();
    final student = e['student'];
    if (student is Map) {
      final name = '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
      if ((student['name'] ?? '').toString().isNotEmpty) return student['name'].toString();
    }
    return '';
  }

  static String _extractCourseName(Map<String, dynamic> e) {
    if ((e['courseName'] ?? '').toString().isNotEmpty) return e['courseName'].toString();
    final course = e['course'];
    if (course is Map && (course['title'] ?? '').toString().isNotEmpty) {
      return course['title'].toString();
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
