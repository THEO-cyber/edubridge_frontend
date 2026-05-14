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
            courseId: e['courseId'] ?? '',
            courseName: e['courseName'] ?? '',
            issuedAt: DateTime.parse(
              e['issuedAt'] ?? DateTime.now().toString(),
            ),
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
      courseId: e['courseId'] ?? '',
      courseName: e['courseName'] ?? '',
      issuedAt: DateTime.parse(e['issuedAt'] ?? DateTime.now().toString()),
      certificateUrl: e['certificateUrl'] ?? '',
      certificateNumber: e['certificateNumber'] ?? '',
    );
  }

  Future<String> downloadCertificate(String certificateId, String token) async {
    return await remoteDataSource.downloadCertificate(certificateId, token);
  }

  Future<bool> verifyCertificate(String certificateNumber) async {
    return await remoteDataSource.verifyCertificate(certificateNumber);
  }
}
