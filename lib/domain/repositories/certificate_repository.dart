import '../entities/certificate_entity.dart';

abstract class CertificateRepository {
  Future<List<CertificateEntity>> fetchCertificates(String token);
}
