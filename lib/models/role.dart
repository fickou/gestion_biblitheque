// lib/models/role.dart

class Role {
  final String id;
  final String name;
  final Map<String, dynamic> permissions;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Inconnu').toString(),
      permissions: json['permissions'] is Map<String, dynamic>
          ? json['permissions'] as Map<String, dynamic>
          : {},
    );
  }

  factory Role.empty() {
    return Role(
      id: '',
      name: 'Inconnu',
      permissions: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
    };
  }

  bool hasPermission(String permission) {
    return permissions[permission] == true;
  }

  @override
  String toString() {
    return 'Role{id: $id, name: $name}';
  }
}