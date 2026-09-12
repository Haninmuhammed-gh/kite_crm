class Company {
  const Company({
    required this.id,
    required this.name,
    this.industry,
    this.website,
    this.phone,
    this.assignedTo,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? industry;
  final String? website;
  final String? phone;
  final String? assignedTo;
  final DateTime? createdAt;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'CO';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed[0].toUpperCase();
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      assignedTo: json['assigned_to']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (industry != null) 'industry': industry,
      if (website != null) 'website': website,
      if (phone != null) 'phone': phone,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name.trim(),
      if (industry != null && industry!.trim().isNotEmpty)
        'industry': industry!.trim(),
      if (website != null && website!.trim().isNotEmpty)
        'website': website!.trim(),
      if (phone != null && phone!.trim().isNotEmpty)
        'phone': phone!.trim(),
      if (assignedTo != null && assignedTo!.isNotEmpty)
        'assigned_to': assignedTo,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          industry == other.industry &&
          website == other.website &&
          phone == other.phone &&
          assignedTo == other.assignedTo;

  @override
  int get hashCode =>
      Object.hash(id, name, industry, website, phone, assignedTo);

  @override
  String toString() =>
      'Company(id: $id, name: $name, industry: $industry, website: $website, phone: $phone, assignedTo: $assignedTo)';
}
