import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task_model.dart';

/// Klien Todoist REST API v1 (Bearer token).
///
/// Endpoint yang dipakai:
/// - GET    /tasks          → daftar tugas
/// - POST   /tasks          → tambah tugas
/// - POST   /tasks/{id}     → ubah tugas (close = tandai selesai)
/// - DELETE /tasks/{id}     → hapus tugas
class ApiService {
  static const _base = 'https://api.todoist.com/api/v1';
  final String token;

  ApiService(this.token);

  bool get hasToken =>
      token.isNotEmpty && token != 'tempel_token_todoist_di_sini';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Ambil semua tugas aktif.
  Future<List<TaskModel>> fetchTasks() async {
    final res = await http
        .get(Uri.parse('$_base/tasks'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _messageOf(res));
    }
    final body = jsonDecode(res.body);
    // Respons v1: { "results": [...] } — beberapa instance masih mengembalikan list.
    final list = body is Map<String, dynamic>
        ? (body['results'] as List? ?? const [])
        : (body as List);
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  /// Tambah tugas baru → id tugas dari Todoist.
  Future<String> createTask(TaskModel task) async {
    final res = await http.post(
      Uri.parse('$_base/tasks'),
      headers: _headers,
      body: jsonEncode(task.toApiJson()),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _messageOf(res));
    }
    final body = jsonDecode(res.body);
    return body['id'].toString();
  }

  /// Ubah tugas (judul, prioritas, tenggat).
  Future<void> updateTask(TaskModel task) async {
    final res = await http.post(
      Uri.parse('$_base/tasks/${task.id}'),
      headers: _headers,
      body: jsonEncode(task.toApiJson()),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _messageOf(res));
    }
  }

  /// Centang / batalkan centang tugas.
  /// Todoist hanya menyediakan "close" — tugas selesai langsung hilang
  /// dari daftar aktif, jadi kita sinkronkan ulang daftar setelahnya.
  Future<void> setCompleted(TaskModel task, bool completed) async {
    if (completed) {
      final res = await http.post(
        Uri.parse('$_base/tasks/${task.id}/close'),
        headers: _headers,
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ApiException(res.statusCode, _messageOf(res));
      }
    } else {
      final res = await http.post(
        Uri.parse('$_base/tasks/${task.id}/reopen'),
        headers: _headers,
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ApiException(res.statusCode, _messageOf(res));
      }
    }
  }

  /// Hapus tugas permanen.
  Future<void> deleteTask(String id) async {
    final res = await http.delete(
      Uri.parse('$_base/tasks/$id'),
      headers: _headers,
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw ApiException(res.statusCode, _messageOf(res));
    }
  }

  static String _messageOf(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic> && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'HTTP ${res.statusCode}';
  }
}

/// Error API dengan kode status dan pesan yang bisa ditampilkan ke pengguna.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
