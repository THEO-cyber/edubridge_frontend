import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_certificates_usecase.dart';

abstract class CertificateEvent {}

class LoadCertificatesEvent extends CertificateEvent {
  final String token;
  LoadCertificatesEvent(this.token);
}

abstract class CertificateState {}

class CertificateInitial extends CertificateState {}

class CertificateLoading extends CertificateState {}

class CertificateLoaded extends CertificateState {
  final List<Map<String, dynamic>> certificates;
  CertificateLoaded(this.certificates);
}

class CertificateError extends CertificateState {
  final String message;
  CertificateError(this.message);
}

class CertificateBloc extends Bloc<CertificateEvent, CertificateState> {
  final FetchCertificatesUseCase fetchCertificatesUseCase;
  CertificateBloc({required this.fetchCertificatesUseCase})
    : super(CertificateInitial()) {
    on<LoadCertificatesEvent>((event, emit) async {
      emit(CertificateLoading());
      try {
        final certificates = await fetchCertificatesUseCase(event.token);
        emit(CertificateLoaded(certificates));
      } catch (e) {
        emit(CertificateError(e.toString()));
      }
    });
  }
}
