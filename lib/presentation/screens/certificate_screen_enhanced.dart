import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/certificate_entity.dart';
import '../blocs/certificate_bloc.dart';

class CertificateScreenEnhanced extends StatefulWidget {
  final String token;

  const CertificateScreenEnhanced({super.key, required this.token});

  @override
  State<CertificateScreenEnhanced> createState() =>
      _CertificateScreenEnhancedState();
}

class _CertificateScreenEnhancedState extends State<CertificateScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    context.read<CertificateBloc>().add(LoadCertificatesEvent(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: BlocBuilder<CertificateBloc, CertificateState>(
        builder: (context, state) {
          if (state is CertificateLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CertificateLoaded) {
            if (state.certificates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No certificates yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete courses to earn certificates',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.certificates.length,
              itemBuilder: (context, index) {
                final cert = state.certificates[index];
                return _buildCertificateCard(cert);
              },
            );
          } else if (state is CertificateError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCertificateCard(CertificateEntity certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.courseName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Certificate #${certificate.certificateNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Issued: ${certificate.issuedAt.toString().split(' ')[0]}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Downloading certificate...'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Certificate link copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
