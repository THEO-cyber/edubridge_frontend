import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/certificate_remote_data_source.dart';
import '../../data/repositories/certificate_repository_impl.dart';
import '../../domain/usecases/fetch_certificates_usecase.dart';
import 'certificate_bloc.dart';

class CertificateBlocProvider extends StatelessWidget {
  final Widget child;
  const CertificateBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CertificateBloc(
        fetchCertificatesUseCase: FetchCertificatesUseCase(
          CertificateRepositoryImpl(CertificateRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
