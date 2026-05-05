abstract class CertificateRepository {
  Future<List<Map<String, dynamic>>> fetchCertificates(String token);
}
