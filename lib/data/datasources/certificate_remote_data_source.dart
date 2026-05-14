import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class CertificateRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchCertificates(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.certificates),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final certList = data is List ? data : (data['certificates'] ?? []);
      return List<Map<String, dynamic>>.from(certList);
    } else {
      throw ApiException('Failed to fetch certificates', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> getCertificateById(
    String certificateId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.certificates}/$certificateId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Failed to fetch certificate', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> getCertificateForCourse(
    String courseId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.certificateForCourse(courseId),
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      'Failed to fetch course certificate',
      response.statusCode,
    );
  }

  Future<String> downloadCertificate(String certificateId, String token) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.certificates}/$certificateId/download',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return response.bodyBytes.toString();
    } else {
      throw ApiException('Failed to download certificate', response.statusCode);
    }
  }

  Future<bool> verifyCertificate(String certificateNumber) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.certificates}/verify/$certificateNumber',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['valid'] ?? false;
    } else {
      throw ApiException('Failed to verify certificate', response.statusCode);
    }
  }
}
