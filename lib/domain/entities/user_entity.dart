class UserEntity {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? avatarUrl;
  final String? phone;
  final String? location;
  final String? expertise;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.firstName,
    this.lastName,
    this.bio,
    this.avatarUrl,
    this.phone,
    this.location,
    this.expertise,
    required this.createdAt,
  });
}
