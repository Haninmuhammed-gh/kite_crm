import '../../contacts/domain/contact.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = 'pending',
    required this.contactId,
    this.assignedTo,
    this.createdAt,
    this.contactName,
    this.contactEmail,
    this.contact,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String status;
  final String contactId;
  final String? assignedTo;
  final DateTime? createdAt;
  final String? contactName;
  final String? contactEmail;
  final Contact? contact;

  String? get displayContactName => contactName ?? contact?.fullName;
  String? get displayContactEmail => contactEmail ?? contact?.email;
  String? get companyName => contact?.companyName;

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isPending => status.toLowerCase() == 'pending';

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    String? contactName;
    String? contactEmail;
    Contact? parsedContact;

    final contactsRaw = json['contacts'] ?? json['contact'];
    if (contactsRaw is Map<String, dynamic>) {
      parsedContact = Contact.fromJson(contactsRaw);
      final first = contactsRaw['first_name'] as String? ?? '';
      final last = contactsRaw['last_name'] as String? ?? '';
      contactName = '$first $last'.trim();
      contactEmail = contactsRaw['email'] as String?;
    } else if (contactsRaw is List && contactsRaw.isNotEmpty) {
      final firstMap = contactsRaw.first;
      if (firstMap is Map<String, dynamic>) {
        parsedContact = Contact.fromJson(firstMap);
        final first = firstMap['first_name'] as String? ?? '';
        final last = firstMap['last_name'] as String? ?? '';
        contactName = '$first $last'.trim();
        contactEmail = firstMap['email'] as String?;
      }
    }

    DateTime? parsedDueDate;
    if (json['due_date'] != null) {
      parsedDueDate = DateTime.tryParse(json['due_date'].toString())?.toLocal();
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt =
          DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: parsedDueDate,
      status: json['status'] as String? ?? 'pending',
      contactId: json['contact_id']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString(),
      createdAt: parsedCreatedAt,
      contactName: (contactName != null && contactName.isNotEmpty)
          ? contactName
          : parsedContact?.fullName,
      contactEmail: contactEmail ?? parsedContact?.email,
      contact: parsedContact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate!.toUtc().toIso8601String(),
      'status': status,
      'contact_id': contactId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (contact != null) 'contacts': contact!.toJson(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (dueDate != null) 'due_date': dueDate!.toUtc().toIso8601String(),
      'status': status,
      'contact_id': contactId,
      if (assignedTo != null && assignedTo!.isNotEmpty)
        'assigned_to': assignedTo,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? contactId,
    String? assignedTo,
    DateTime? createdAt,
    String? contactName,
    String? contactEmail,
    Contact? contact,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      contactId: contactId ?? this.contactId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contact: contact ?? this.contact,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          dueDate == other.dueDate &&
          status == other.status &&
          contactId == other.contactId &&
          assignedTo == other.assignedTo &&
          contact == other.contact;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        dueDate,
        status,
        contactId,
        assignedTo,
        contact,
      );

  @override
  String toString() =>
      'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, contact: $contactName, assignedTo: $assignedTo)';
}
