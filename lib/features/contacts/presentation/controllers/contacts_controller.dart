import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../data/contact_repository.dart';
import '../../domain/company.dart';
import '../../domain/contact.dart';

final contactsControllerProvider =
    NotifierProvider<ContactsController, AsyncValue<List<Contact>>>(
  ContactsController.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final filteredContactsProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final contactsAsync = ref.watch(contactsControllerProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return contactsAsync.whenData((contacts) {
    if (query.isEmpty) return contacts;
    return contacts.where((contact) {
      final name = contact.fullName.toLowerCase();
      final email = (contact.email ?? '').toLowerCase();
      final phone = (contact.phone ?? '').toLowerCase();
      final company = (contact.companyName ?? '').toLowerCase();
      final status = contact.status.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          company.contains(query) ||
          status.contains(query);
    }).toList();
  });
});

final contactsByCompanyProvider =
    Provider.family<AsyncValue<List<Contact>>, String>((ref, companyId) {
  final contactsAsync = ref.watch(contactsControllerProvider);
  return contactsAsync.whenData((contacts) {
    return contacts.where((contact) => contact.companyId == companyId).toList();
  });
});

final qualifiedLeadsProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final contactsAsync = ref.watch(filteredContactsProvider);
  return contactsAsync.whenData((contacts) {
    return contacts
        .where((contact) =>
            contact.status.toLowerCase() == 'qualified' ||
            contact.status == 'Qualified')
        .toList();
  });
});

final companiesProvider = FutureProvider<List<Company>>((ref) async {
  return await ref.read(contactRepositoryProvider).fetchCompanies();
});

final contactDetailProvider =
    FutureProvider.family<Contact?, String>((ref, contactId) async {
  // Check memory cache first
  final cached = ref
      .watch(contactsControllerProvider)
      .value
      ?.where((c) => c.id == contactId)
      .firstOrNull;
  if (cached != null) return cached;

  // Fallback to direct fetch
  return await ref.read(contactRepositoryProvider).fetchContactById(contactId);
});

class ContactsController extends Notifier<AsyncValue<List<Contact>>> {
  @override
  AsyncValue<List<Contact>> build() {
    _fetchContacts();
    return const AsyncValue.loading();
  }

  Future<void> _fetchContacts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(contactRepositoryProvider).fetchContacts();
    });
  }

  Future<void> refresh() async {
    await _fetchContacts();
  }

  void filterByQuery(String query) {
    ref.read(searchQueryProvider.notifier).setQuery(query);
  }

  Future<bool> addContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    try {
      await ref.read(contactRepositoryProvider).addContact(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            companyId: companyId,
            status: status,
            assignedTo: assignedTo,
            notes: notes,
          );

      ref.invalidateSelf();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateContact({
    required String contactId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    try {
      await ref.read(contactRepositoryProvider).updateContact(
            contactId: contactId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            companyId: companyId,
            status: status,
            assignedTo: assignedTo,
            notes: notes,
          );

      ref.invalidateSelf();
      ref.invalidate(contactDetailProvider(contactId));
      ref.invalidate(dealsControllerProvider);
      ref.invalidate(tasksControllerProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> updateStatus({
    required String contactId,
    required String newStatus,
  }) async {
    final previousState = state;

    // Optimistically update local state
    state = state.whenData((list) {
      return list.map((contact) {
        if (contact.id == contactId) {
          return contact.copyWith(status: newStatus);
        }
        return contact;
      }).toList();
    });

    try {
      await ref.read(contactRepositoryProvider).updateContactStatus(
            contactId: contactId,
            status: newStatus,
          );
      ref.invalidateSelf();
      ref.invalidate(contactDetailProvider(contactId));
      ref.invalidate(dealsControllerProvider);
    } catch (error, stackTrace) {
      // Revert to previous state upon failure
      state = previousState;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteContact(String contactId) async {
    final previousState = state;

    // Optimistically remove
    state = state.whenData((list) {
      return list.where((c) => c.id != contactId).toList();
    });

    try {
      await ref.read(contactRepositoryProvider).deleteContact(
            contactId: contactId,
          );
      ref.invalidateSelf();
      ref.invalidate(contactDetailProvider(contactId));
      ref.invalidate(dealsControllerProvider);
      ref.invalidate(tasksControllerProvider);
    } catch (error, stackTrace) {
      state = previousState;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
