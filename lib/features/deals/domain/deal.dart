import '../../companies/domain/company.dart';
import '../../contacts/domain/contact.dart';

class Deal {
  const Deal({
    required this.id,
    this.contactId,
    this.companyId,
    this.assignedTo,
    required this.title,
    required this.value,
    this.stage = 'lead',
    this.expectedCloseDate,
    this.contact,
    this.company,
  });

  final String id;
  final String? contactId;
  final String? companyId;
  final String? assignedTo;
  final String title;
  final double value;
  final String stage;
  final DateTime? expectedCloseDate;
  final Contact? contact;
  final Company? company;

  String? get contactName => contact?.fullName;
  String? get companyName => company?.name ?? contact?.companyName;

  factory Deal.fromJson(Map<String, dynamic> json) {
    Contact? parsedContact;
    final contactRaw = json['contacts'] ?? json['contact'];
    if (contactRaw is Map<String, dynamic>) {
      parsedContact = Contact.fromJson(contactRaw);
    } else if (contactRaw is List && contactRaw.isNotEmpty) {
      final first = contactRaw.first;
      if (first is Map<String, dynamic>) {
        parsedContact = Contact.fromJson(first);
      }
    }

    Company? parsedCompany;
    final companyRaw = json['companies'] ?? json['company'];
    if (companyRaw is Map<String, dynamic>) {
      parsedCompany = Company.fromJson(companyRaw);
    } else if (companyRaw is List && companyRaw.isNotEmpty) {
      final first = companyRaw.first;
      if (first is Map<String, dynamic>) {
        parsedCompany = Company.fromJson(first);
      }
    }

    DateTime? parsedDate;
    final dateRaw = json['expected_close_date'];
    if (dateRaw != null) {
      if (dateRaw is String && dateRaw.isNotEmpty) {
        parsedDate = DateTime.tryParse(dateRaw);
      } else if (dateRaw is DateTime) {
        parsedDate = dateRaw;
      }
    }

    final valRaw = json['value'];
    double parsedValue = 0.0;
    if (valRaw is num) {
      parsedValue = valRaw.toDouble();
    } else if (valRaw is String) {
      parsedValue = double.tryParse(valRaw) ?? 0.0;
    }

    return Deal(
      id: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString(),
      companyId: json['company_id']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      title: json['title'] as String? ?? '',
      value: parsedValue,
      stage: json['stage'] as String? ?? 'lead',
      expectedCloseDate: parsedDate,
      contact: parsedContact,
      company: parsedCompany,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (contactId != null) 'contact_id': contactId,
      if (companyId != null) 'company_id': companyId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'title': title,
      'value': value,
      'stage': stage,
      if (expectedCloseDate != null)
        'expected_close_date': expectedCloseDate!.toIso8601String(),
      if (contact != null) 'contacts': contact!.toJson(),
      if (company != null) 'companies': company!.toJson(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (contactId != null && contactId!.isNotEmpty) 'contact_id': contactId,
      if (companyId != null && companyId!.isNotEmpty) 'company_id': companyId,
      if (assignedTo != null && assignedTo!.isNotEmpty)
        'assigned_to': assignedTo,
      'title': title,
      'value': value,
      'stage': stage,
      if (expectedCloseDate != null)
        'expected_close_date':
            expectedCloseDate!.toIso8601String().split('T').first,
    };
  }

  Deal copyWith({
    String? id,
    String? contactId,
    String? companyId,
    String? assignedTo,
    String? title,
    double? value,
    String? stage,
    DateTime? expectedCloseDate,
    Contact? contact,
    Company? company,
  }) {
    return Deal(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      companyId: companyId ?? this.companyId,
      assignedTo: assignedTo ?? this.assignedTo,
      title: title ?? this.title,
      value: value ?? this.value,
      stage: stage ?? this.stage,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      contact: contact ?? this.contact,
      company: company ?? this.company,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contactId == other.contactId &&
          companyId == other.companyId &&
          assignedTo == other.assignedTo &&
          title == other.title &&
          value == other.value &&
          stage == other.stage &&
          expectedCloseDate == other.expectedCloseDate &&
          contact == other.contact &&
          company == other.company;

  @override
  int get hashCode => Object.hash(
        id,
        contactId,
        companyId,
        assignedTo,
        title,
        value,
        stage,
        expectedCloseDate,
        contact,
        company,
      );

  @override
  String toString() =>
      'Deal(id: $id, title: $title, value: $value, stage: $stage, contact: $contactName, company: $companyName, assignedTo: $assignedTo)';
}
