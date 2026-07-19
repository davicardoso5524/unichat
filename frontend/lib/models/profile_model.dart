/// Model de perfil do usuário (tabela profiles do Supabase).
class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String course;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Role dentro de um grupo (owner/member). Preenchido em contextos de grupo.
  final String? groupRole;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.course,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.groupRole,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Usuário',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      course: json['course'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  ProfileModel copyWith({String? role, String? course, String? groupRole}) {
    return ProfileModel(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      course: course ?? this.course,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      groupRole: groupRole ?? this.groupRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'course': course,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get ehProfessor => role == 'professor';
  bool get ehDonoDoGrupo => groupRole == 'owner';
}
