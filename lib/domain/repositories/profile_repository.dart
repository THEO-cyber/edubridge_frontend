abstract class ProfileRepository {
  Future<Map<String, dynamic>> fetchProfile(String token);
  Future<void> updateProfile(Map<String, dynamic> data, String token);
}
