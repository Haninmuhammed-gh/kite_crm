import 'company.dart';

class Contact {
  const Contact({
    required this.id,
    this.companyId,
    this.assignedTo,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.status = 'new',
    this.company,
    this.notes,
  });

  final String id;
  final String? companyId;
  final String? assignedTo;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String status;
  final Company? company;
  final String? notes;

  String get fullName => '$firstName $lastName'.trim();

  String? get companyName => company?.name;

  factory Contact.fromJson(Map<String, dynamic> json) {
    Company? parsedCompany;
    final companiesRaw = json['companies'] ?? json['company'];
    if (companiesRaw is Map<String, dynamic>) {
      parsedCompany = Company.fromJson(companiesRaw);
    } else if (companiesRaw is List && companiesRaw.isNotEmpty) {
      final first = companiesRaw.first;
      if (first is Map<String, dynamic>) {
        parsedCompany = Company.fromJson(first);
      }
    }

    return Contact(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'new',
      company: parsedCompany,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (companyId != null) 'company_id': companyId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'first_name': firstName,
      'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'status': status,
      if (company != null) 'companies': company!.toJson(),
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (companyId != null && companyId!.isNotEmpty) 'company_id': companyId,
      if (assignedTo != null && assignedTo!.isNotEmpty) 'assigned_to': assignedTo,
      'first_name': firstName,
      'last_name': lastName,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  Contact copyWith({
    String? id,
    String? companyId,
    String? assignedTo,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? status,
    Company? company,
    String? notes,
  }) {
    return Contact(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      assignedTo: assignedTo ?? this.assignedTo,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      company: company ?? this.company,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          companyId == other.companyId &&
          assignedTo == other.assignedTo &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          email == other.email &&
          phone == other.phone &&
          status == other.status &&
          company == other.company &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        id,
        companyId,
        assignedTo,
        firstName,
        lastName,
        email,
        phone,
        status,
        company,
        notes,
      );

  @override
  String toString() =>
      'Contact(id: $id, name: $fullName, email: $email, status: $status, company: $companyName, notes: $notes)';
}
