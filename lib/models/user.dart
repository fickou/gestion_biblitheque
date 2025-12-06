// lib/models/user.dart
import 'dart:convert';
import 'role.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String matricule;
  final Role role;
  final String avatarText;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.matricule,
    required this.role,
    required this.avatarText,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extraction sécurisée
    final String id = (json['id'] ?? '').toString();
    final String name = (json['name'] ?? '').toString();
    final String email = (json['email'] ?? '').toString();
    final String matricule = (json['matricule'] ?? '').toString();
    final String avatarText = (json['avatarText'] ?? _generateAvatarText(name)).toString();
    final String status = (json['status'] ?? 'actif').toString();
    
    // Gestion du rôle
    Role role;
    try {
      if (json['role'] != null) {
        if (json['role'] is Map<String, dynamic>) {
          role = Role.fromJson(json['role'] as Map<String, dynamic>);
        } else if (json['role'] is Map) {
          role = Role.fromJson(Map<String, dynamic>.from(json['role']));
        } else {
          // Fallback
          final roleId = (json['roleId'] ?? '3').toString();
          final roleName = (json['roleName'] ?? 'Étudiant').toString();
          final permissions = _extractPermissions(json);
          
          role = Role(
            id: roleId,
            name: roleName,
            permissions: permissions,
          );
        }
      } else {
        role = Role.empty();
      }
    } catch (e) {
      print('Erreur création rôle: $e');
      role = Role.empty();
    }
    
    // Gestion des dates
    DateTime? createdAt;
    DateTime? updatedAt;
    
    try {
      if (json['createdAt'] != null) {
        final dateStr = json['createdAt'].toString();
        if (dateStr.isNotEmpty) {
          createdAt = DateTime.tryParse(dateStr);
        }
      }
      
      if (json['updatedAt'] != null) {
        final dateStr = json['updatedAt'].toString();
        if (dateStr.isNotEmpty) {
          updatedAt = DateTime.tryParse(dateStr);
        }
      }
    } catch (e) {
      print('Erreur parsing dates: $e');
    }
    
    return User(
      id: id,
      name: name,
      email: email,
      matricule: matricule,
      role: role,
      avatarText: avatarText,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'matricule': matricule,
      'role': role.toJson(),
      'avatarText': avatarText,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'matricule': matricule,
      'roleId': role.id,
      'avatarText': avatarText,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  static Map<String, dynamic> _extractPermissions(Map<String, dynamic> json) {
    try {
      if (json['permissions'] != null) {
        if (json['permissions'] is Map<String, dynamic>) {
          return json['permissions'] as Map<String, dynamic>;
        } else if (json['permissions'] is Map) {
          return Map<String, dynamic>.from(json['permissions']);
        } else if (json['permissions'] is String) {
          try {
            return Map<String, dynamic>.from(jsonDecode(json['permissions']));
          } catch (e) {
            print('Erreur parsing permissions JSON: $e');
          }
        }
      }
      
      if (json['role'] != null && json['role'] is Map) {
        final roleMap = json['role'] as Map;
        if (roleMap['permissions'] != null) {
          if (roleMap['permissions'] is Map<String, dynamic>) {
            return roleMap['permissions'] as Map<String, dynamic>;
          } else if (roleMap['permissions'] is Map) {
            return Map<String, dynamic>.from(roleMap['permissions']);
          }
        }
      }
    } catch (e) {
      print('Erreur extraction permissions: $e');
    }
    
    return {
      'borrow_books': true,
      'reserve_books': true,
      'view_own_loans': true,
    };
  }

  static String _generateAvatarText(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '${first}${second}'.toUpperCase();
    }
    final length = name.length;
    if (length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  // Méthode factory pour un utilisateur vide
  factory User.empty() {
    return User(
      id: '',
      name: '',
      email: '',
      matricule: '',
      role: Role.empty(),
      avatarText: '',
      status: 'inactif',
    );
  }

  // Getters utiles
  bool get isValid => id.isNotEmpty && name.isNotEmpty;
  String get initials => _generateAvatarText(name);
  String get displayName => name;
  String get roleName => role.name;
  bool get isAdmin => role.name == 'Administrateur';
  bool get isLibrarian => role.name == 'Bibliothécaire';
  bool get isStudent => role.name == 'Étudiant';
  bool get isProfessor => role.name == 'Professeur';
  bool get isActive => status == 'actif';
  bool hasPermission(String permission) => role.permissions[permission] == true;
  
  String? get formattedCreatedAt {
    if (createdAt == null) return null;
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: ${role.name}}';
  }
}