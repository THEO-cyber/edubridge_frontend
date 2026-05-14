import '../entities/certificate_entity.dart';
import '../repositories/certificate_repository.dart';

class FetchCertificatesUseCase {
  final CertificateRepository repository;
  FetchCertificatesUseCase(this.repository);

  Future<List<CertificateEntity>> call(String token) {
    return repository.fetchCertificates(token);
  }
}
