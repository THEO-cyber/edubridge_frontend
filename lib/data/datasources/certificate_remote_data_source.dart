import 'dart:convert';
import 'dart:typed_data';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class CertificateRemoteDataSource {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Map<String, dynamic>>> fetchCertificates(String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.certificates),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return extractListOf(jsonDecode(response.body), ['certificates', 'items']);
    }
    throw ApiException('Failed to fetch certificates', response.statusCode);
  }

  Future<Map<String, dynamic>> getCertificateById(
    String certificateId,
    String token,
  ) async {
    final response = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.certificates}/$certificateId'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return extractObject(jsonDecode(response.body));
    }
    throw ApiException('Failed to fetch certificate', response.statusCode);
  }

  Future<Map<String, dynamic>> getCertificateForCourse(
    String courseId,
    String token,
  ) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.certificateForCourse(courseId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return extractObject(jsonDecode(response.body));
    }
    throw ApiException('Failed to fetch course certificate', response.statusCode);
  }

  Future<Uint8List> downloadCertificate(String certificateId, String token) async {
    // Binary PDF — raw request (no JSON envelope to unwrap).
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.certificates}/$certificateId/download'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw ApiException('Failed to download certificate', response.statusCode);
  }

  Future<bool> verifyCertificate(String certificateNumber) async {
    final response = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.certificates}/verify/$certificateNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = extractObject(jsonDecode(response.body));
      return data['valid'] ?? false;
    }
    throw ApiException('Failed to verify certificate', response.statusCode);
  }
}
