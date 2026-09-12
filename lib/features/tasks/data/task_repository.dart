import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(Supabase.instance.client);
});

class TaskRepository {
  TaskRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Task>> fetchTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*, contacts(*, companies(id, name, industry, website, phone))')
          .order('due_date', ascending: true, nullsFirst: false);
      return (response as List)
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final response = await _supabase
            .from('tasks')
            .select('*, contacts(*)')
            .order('due_date', ascending: true, nullsFirst: false);
        return (response as List)
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final basic = await _supabase
            .from('tasks')
            .select('*')
            .order('due_date', ascending: true, nullsFirst: false);
        return (basic as List)
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
  }

  Future<Task?> fetchTaskById(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*, contacts(*, companies(id, name, industry, website, phone))')
          .eq('id', taskId)
          .maybeSingle();
      if (response == null) return null;
      return Task.fromJson(response);
    } catch (_) {
      try {
        final fallback = await _supabase
            .from('tasks')
            .select('*, contacts(*)')
            .eq('id', taskId)
            .maybeSingle();
        if (fallback == null) return null;
        return Task.fromJson(fallback);
      } catch (_) {
        final basic = await _supabase
            .from('tasks')
            .select('*')
            .eq('id', taskId)
            .maybeSingle();
        if (basic == null) return null;
        return Task.fromJson(basic);
      }
    }
  }

  Future<Task> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    final currentUserId = assignedTo ?? _supabase.auth.currentUser?.id;
    final insertData = <String, dynamic>{
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (dueDate != null) 'due_date': dueDate.toUtc().toIso8601String(),
      'status': status,
      'contact_id': contactId,
      if (currentUserId != null && currentUserId.isNotEmpty)
        'assigned_to': currentUserId,
    };

    try {
      final response = await _supabase
          .from('tasks')
          .insert(insertData)
          .select('*, contacts(id, first_name, last_name, email)')
          .single();
      return Task.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('tasks')
          .insert(insertData)
          .select('*')
          .single();
      return Task.fromJson(fallback);
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    await _supabase
        .from('tasks')
        .update({'status': status})
        .eq('id', taskId);
  }

  Future<Task> updateTask({
    required String taskId,
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    final updateData = <String, dynamic>{
      'title': title.trim(),
      'description': (description != null && description.trim().isNotEmpty)
          ? description.trim()
          : null,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'status': status,
      'contact_id': contactId,
      if (assignedTo != null && assignedTo.isNotEmpty)
        'assigned_to': assignedTo,
    };

    try {
      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .select('*, contacts(id, first_name, last_name, email)')
          .single();
      return Task.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .select('*')
          .single();
      return Task.fromJson(fallback);
    }
  }

  Future<void> deleteTask({
    required String taskId,
  }) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
