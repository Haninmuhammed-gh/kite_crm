class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    required this.role,
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String role;
  final String status;
  final DateTime? createdAt;

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isMember => role.toLowerCase() == 'member';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isActive => status.toLowerCase() == 'active';

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'User (${id.substring(0, 8)})';
  }

  String get initials {
    final name = (fullName != null && fullName!.trim().isNotEmpty)
        ? fullName!.trim()
        : (email != null && email!.isNotEmpty ? email!.split('@').first : '');
    final parts =
        name.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final single = parts[0];
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt =
          DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'active',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      'role': role,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? status,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, fullName, email, role, status);

  @override
  String toString() =>
      'UserProfile(id: $id, name: $displayName, role: $role, status: $status)';
}
