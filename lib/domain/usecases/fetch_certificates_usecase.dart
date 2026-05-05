import '../repositories/certificate_repository.dart';

class FetchCertificatesUseCase {
  final CertificateRepository repository;
  FetchCertificatesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String token) {
    return repository.fetchCertificates(token);
  }
}
