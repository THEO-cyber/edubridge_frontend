import '../../domain/repositories/certificate_repository.dart';
import '../datasources/certificate_remote_data_source.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  final CertificateRemoteDataSource remoteDataSource;
  CertificateRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> fetchCertificates(String token) async {
    return await remoteDataSource.fetchCertificates(token);
  }
}
