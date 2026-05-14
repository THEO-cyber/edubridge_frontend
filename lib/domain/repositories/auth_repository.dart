import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(
    String email,
    String password,
    String role,
    String username,
    String firstName,
    String lastName,
  );
  Future<UserEntity> getMe(String token);
  Future<String> refreshToken();
}
