class UserEntity {
  final String id;
  final String email;
  final String role;
  final String? name;

  UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });
}
