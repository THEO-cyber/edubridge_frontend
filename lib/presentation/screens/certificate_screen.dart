import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/certificate_bloc.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data!;
          context.read<CertificateBloc>().add(LoadCertificatesEvent(token));
          return BlocBuilder<CertificateBloc, CertificateState>(
            builder: (context, state) {
              if (state is CertificateLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CertificateLoaded) {
                final certificates = state.certificates;
                if (certificates.isEmpty) {
                  return const Center(child: Text('No certificates found.'));
                }
                return ListView.builder(
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    return ListTile(
                      title: Text(cert.courseName),
                      subtitle: Text(
                        cert.issuedAt.toLocal().toString().split(' ')[0],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Implement download/view
                        },
                      ),
                    );
                  },
                );
              }
              if (state is CertificateError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
