import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/companies/data/company_repository.dart';
import 'package:kite_crm/features/companies/domain/company.dart';
import 'package:kite_crm/features/companies/presentation/controllers/companies_controller.dart';
import 'package:kite_crm/features/contacts/data/contact_repository.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:kite_crm/features/deals/data/deal_repository.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';
import 'package:kite_crm/features/tasks/data/task_repository.dart';
import 'package:kite_crm/features/tasks/domain/task.dart';
import 'package:kite_crm/features/tasks/presentation/controllers/tasks_controller.dart';

class _FakeCompanyRepository implements CompanyRepository {
  int fetchCount = 0;
  final List<Company> companies = [
    const Company(id: 'comp-1', name: 'Initial Corp'),
  ];

  @override
  Future<List<Company>> fetchCompanies() async {
    fetchCount++;
    return List.from(companies);
  }

  @override
  Future<Company?> fetchCompanyById(String companyId) async {
    return companies.where((c) => c.id == companyId).firstOrNull;
  }

  @override
  Future<Company> addCompany({
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    final newComp = Company(
      id: 'comp-${companies.length + 1}',
      name: name,
      industry: industry,
      website: website,
      phone: phone,
      assignedTo: assignedTo,
    );
    companies.add(newComp);
    return newComp;
  }

  @override
  Future<Company> updateCompany({
    required String companyId,
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    final updated = Company(
      id: companyId,
      name: name,
      industry: industry,
      website: website,
      phone: phone,
      assignedTo: assignedTo,
    );
    final idx = companies.indexWhere((c) => c.id == companyId);
    if (idx != -1) companies[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCompany({required String companyId}) async {
    companies.removeWhere((c) => c.id == companyId);
  }
}

class _FakeContactRepository implements ContactRepository {
  int fetchCount = 0;
  int fetchCompaniesCount = 0;
  final List<Contact> contacts = [
    const Contact(
      id: 'contact-1',
      firstName: 'Bruce',
      lastName: 'Wayne',
      status: 'new',
    ),
  ];
  final List<Company> dropdownCompanies = [
    const Company(id: 'comp-1', name: 'Initial Corp'),
  ];

  @override
  Future<List<Contact>> fetchContacts() async {
    fetchCount++;
    return List.from(contacts);
  }

  @override
  Future<Contact?> fetchContactById(String contactId) async {
    return contacts.where((c) => c.id == contactId).firstOrNull;
  }

  @override
  Future<List<Company>> fetchCompanies() async {
    fetchCompaniesCount++;
    return List.from(dropdownCompanies);
  }

  @override
  Future<List<Contact>> fetchContactsByCompany(String companyId) async {
    return contacts.where((c) => c.companyId == companyId).toList();
  }

  @override
  Future<Contact> addContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    final newContact = Contact(
      id: 'contact-${contacts.length + 1}',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      companyId: companyId,
      status: status,
      assignedTo: assignedTo,
      notes: notes,
    );
    contacts.add(newContact);
    return newContact;
  }

  @override
  Future<Contact> updateContact({
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
    final updated = Contact(
      id: contactId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      companyId: companyId,
      status: status,
      assignedTo: assignedTo,
      notes: notes,
    );
    final idx = contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) contacts[idx] = updated;
    return updated;
  }

  @override
  Future<void> updateContactStatus({
    required String contactId,
    required String status,
  }) async {
    final idx = contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) contacts[idx] = contacts[idx].copyWith(status: status);
  }

  @override
  Future<void> deleteContact({required String contactId}) async {
    contacts.removeWhere((c) => c.id == contactId);
  }
}

class _FakeDealRepository implements DealRepository {
  int fetchCount = 0;
  final List<Deal> deals = [
    const Deal(id: 'deal-1', title: 'Deal A', value: 5000, stage: 'lead'),
  ];

  @override
  Future<List<Deal>> fetchDeals() async {
    fetchCount++;
    return List.from(deals);
  }

  @override
  Future<Deal> addDeal({
    required String title,
    required double value,
    String? contactId,
    String? companyId,
    String stage = 'lead',
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    final d = Deal(
      id: 'deal-${deals.length + 1}',
      title: title,
      value: value,
      contactId: contactId,
      companyId: companyId,
      stage: stage,
    );
    deals.add(d);
    return d;
  }

  @override
  Future<Deal> updateDeal({
    required String dealId,
    required String title,
    required double value,
    required String stage,
    String? contactId,
    String? companyId,
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    final d = Deal(
      id: dealId,
      title: title,
      value: value,
      stage: stage,
      contactId: contactId,
      companyId: companyId,
    );
    final idx = deals.indexWhere((item) => item.id == dealId);
    if (idx != -1) deals[idx] = d;
    return d;
  }

  @override
  Future<void> updateDealStage({
    required String dealId,
    required String stage,
  }) async {
    final idx = deals.indexWhere((item) => item.id == dealId);
    if (idx != -1) deals[idx] = deals[idx].copyWith(stage: stage);
  }

  @override
  Future<void> deleteDeal({required String dealId}) async {
    deals.removeWhere((item) => item.id == dealId);
  }
}

class _FakeTaskRepository implements TaskRepository {
  int fetchCount = 0;
  final List<Task> tasks = [
    Task(
      id: 'task-1',
      title: 'Task A',
      contactId: 'contact-1',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Task>> fetchTasks() async {
    fetchCount++;
    return List.from(tasks);
  }

  @override
  Future<Task?> fetchTaskById(String taskId) async {
    return tasks.where((t) => t.id == taskId).firstOrNull;
  }

  @override
  Future<Task> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    final t = Task(
      id: 'task-${tasks.length + 1}',
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      contactId: contactId,
      assignedTo: assignedTo,
      createdAt: DateTime.now(),
    );
    tasks.add(t);
    return t;
  }

  @override
  Future<Task> updateTask({
    required String taskId,
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    final t = Task(
      id: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      contactId: contactId,
      assignedTo: assignedTo,
      createdAt: DateTime.now(),
    );
    final idx = tasks.indexWhere((item) => item.id == taskId);
    if (idx != -1) tasks[idx] = t;
    return t;
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    final idx = tasks.indexWhere((item) => item.id == taskId);
    if (idx != -1) tasks[idx] = tasks[idx].copyWith(status: status);
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    tasks.removeWhere((item) => item.id == taskId);
  }
}

void main() {
  group('Global state invalidation tests', () {
    late _FakeCompanyRepository fakeCompaniesRepo;
    late _FakeContactRepository fakeContactsRepo;
    late _FakeDealRepository fakeDealsRepo;
    late _FakeTaskRepository fakeTasksRepo;
    late ProviderContainer container;

    setUp(() {
      fakeCompaniesRepo = _FakeCompanyRepository();
      fakeContactsRepo = _FakeContactRepository();
      fakeDealsRepo = _FakeDealRepository();
      fakeTasksRepo = _FakeTaskRepository();

      container = ProviderContainer(
        overrides: [
          companyRepositoryProvider.overrideWithValue(fakeCompaniesRepo),
          contactRepositoryProvider.overrideWithValue(fakeContactsRepo),
          dealRepositoryProvider.overrideWithValue(fakeDealsRepo),
          taskRepositoryProvider.overrideWithValue(fakeTasksRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addCompany invalidates self and companiesProvider dropdown cache', () async {
      final companySub = container.listen(companiesControllerProvider, (_, _) {});
      final dropdownSub = container.listen(companiesProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeCompaniesRepo.fetchCount, 1);
      expect(fakeContactsRepo.fetchCompaniesCount, 1);

      fakeContactsRepo.dropdownCompanies.add(const Company(id: 'comp-2', name: 'Wayne Corp'));
      final success = await container.read(companiesControllerProvider.notifier).addCompany(
            name: 'Wayne Corp',
          );
      expect(success, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeCompaniesRepo.fetchCount, 2);
      expect(fakeContactsRepo.fetchCompaniesCount, 2);

      companySub.close();
      dropdownSub.close();
    });

    test('deleteCompany invalidates self, companiesProvider, contacts, and deals', () async {
      final compSub = container.listen(companiesControllerProvider, (_, _) {});
      final dropdownSub = container.listen(companiesProvider, (_, _) {});
      final contactSub = container.listen(contactsControllerProvider, (_, _) {});
      final dealSub = container.listen(dealsControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeCompaniesRepo.fetchCount, 1);
      expect(fakeContactsRepo.fetchCompaniesCount, 1);
      expect(fakeContactsRepo.fetchCount, 1);
      expect(fakeDealsRepo.fetchCount, 1);

      await container.read(companiesControllerProvider.notifier).deleteCompany('comp-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeCompaniesRepo.fetchCount, 2);
      expect(fakeContactsRepo.fetchCompaniesCount, 2);
      expect(fakeContactsRepo.fetchCount, 2);
      expect(fakeDealsRepo.fetchCount, 2);

      compSub.close();
      dropdownSub.close();
      contactSub.close();
      dealSub.close();
    });

    test('addContact invalidates self and auto-updates qualified leads', () async {
      final contactSub = container.listen(contactsControllerProvider, (_, _) {});
      final leadsSub = container.listen(qualifiedLeadsProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeContactsRepo.fetchCount, 1);

      final success = await container.read(contactsControllerProvider.notifier).addContact(
            firstName: 'Clark',
            lastName: 'Kent',
            status: 'qualified',
          );
      expect(success, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeContactsRepo.fetchCount, 2);
      final leads = container.read(qualifiedLeadsProvider).value;
      expect(leads?.any((c) => c.fullName == 'Clark Kent'), isTrue);

      contactSub.close();
      leadsSub.close();
    });

    test('updateContact invalidates self, deals, and tasks', () async {
      final contactSub = container.listen(contactsControllerProvider, (_, _) {});
      final dealSub = container.listen(dealsControllerProvider, (_, _) {});
      final taskSub = container.listen(tasksControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeContactsRepo.fetchCount, 1);
      expect(fakeDealsRepo.fetchCount, 1);
      expect(fakeTasksRepo.fetchCount, 1);

      await container.read(contactsControllerProvider.notifier).updateContact(
            contactId: 'contact-1',
            firstName: 'Batman',
            lastName: 'Wayne',
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeContactsRepo.fetchCount, 2);
      expect(fakeDealsRepo.fetchCount, 2);
      expect(fakeTasksRepo.fetchCount, 2);

      contactSub.close();
      dealSub.close();
      taskSub.close();
    });

    test('DealsController mutations trigger refetch', () async {
      final dealSub = container.listen(dealsControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeDealsRepo.fetchCount, 1);

      await container.read(dealsControllerProvider.notifier).addDeal(
            title: 'Stark Energy Deal',
            value: 50000,
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeDealsRepo.fetchCount, 2);

      await container.read(dealsControllerProvider.notifier).updateStage(
            dealId: 'deal-1',
            newStage: 'won',
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeDealsRepo.fetchCount, 3);

      await container.read(dealsControllerProvider.notifier).deleteDeal('deal-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeDealsRepo.fetchCount, 4);

      dealSub.close();
    });

    test('TasksController mutations trigger refetch', () async {
      final taskSub = container.listen(tasksControllerProvider, (_, _) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeTasksRepo.fetchCount, 1);

      await container.read(tasksControllerProvider.notifier).addTask(
            title: 'Follow up with Stark',
            contactId: 'contact-1',
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeTasksRepo.fetchCount, 2);

      await container.read(tasksControllerProvider.notifier).updateStatus(
            taskId: 'task-1',
            newStatus: 'completed',
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeTasksRepo.fetchCount, 3);

      await container.read(tasksControllerProvider.notifier).deleteTask('task-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeTasksRepo.fetchCount, 4);

      taskSub.close();
    });
  });
}
