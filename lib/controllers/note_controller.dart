// GetX 4.7 masih memakai snackbar warna dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/note_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

/// Controller GetX untuk mengelola daftar catatan, pencarian, serta operasi CRUD.
class NoteController extends GetxController {
  NoteController({required this.apiService});

  final ApiService apiService;

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  /// Memuat daftar catatan milik pengguna aktif dari API.
  Future<void> loadNotes({String? query}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final activeQuery = query ?? searchQuery.value;
      final fetched = await apiService.getNotes(query: activeQuery);
      notes.assignAll(fetched);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Gagal memuat daftar catatan. Silakan coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Memperbarui catatan saat pengguna melakukan pull-to-refresh.
  Future<void> refreshNotes() async {
    errorMessage.value = null;
    try {
      final fetched = await apiService.getNotes(query: searchQuery.value);
      notes.assignAll(fetched);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      _showSnackbar(title: 'Gagal Memuat', message: e.message, isError: true);
    } catch (_) {
      const msg = 'Gagal memuat ulang catatan. Periksa koneksi.';
      errorMessage.value = msg;
      _showSnackbar(title: 'Gagal Memuat', message: msg, isError: true);
    }
  }

  /// Menyimpan catatan baru lalu memuat ulang daftar catatan.
  Future<NoteModel?> addNote({
    required String title,
    required String content,
  }) async {
    isSubmitting.value = true;
    try {
      final created = await apiService.createNote(
        title: title.trim(),
        content: content.trim(),
      );
      await loadNotes();
      return created;
    } on ApiException catch (e) {
      _showSnackbar(title: 'Gagal Menyimpan', message: e.message, isError: true);
      return null;
    } catch (_) {
      _showSnackbar(
        title: 'Gagal Menyimpan',
        message: 'Tidak dapat menyimpan catatan. Silakan coba lagi.',
        isError: true,
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Memperbarui judul dan isi catatan yang sudah ada.
  Future<NoteModel?> updateNote({
    required int id,
    required String title,
    required String content,
  }) async {
    isSubmitting.value = true;
    try {
      final updated = await apiService.updateNote(
        id: id,
        title: title.trim(),
        content: content.trim(),
      );
      final index = notes.indexWhere((item) => item.id == id);
      if (index != -1) {
        notes[index] = updated;
      } else {
        await loadNotes();
      }
      return updated;
    } on ApiException catch (e) {
      _showSnackbar(title: 'Gagal Memperbarui', message: e.message, isError: true);
      return null;
    } catch (_) {
      _showSnackbar(
        title: 'Gagal Memperbarui',
        message: 'Tidak dapat mengubah catatan. Silakan coba lagi.',
        isError: true,
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Menghapus catatan dari server dan daftar lokal.
  Future<bool> deleteNote(int id) async {
    isSubmitting.value = true;
    try {
      await apiService.deleteNote(id);
      notes.removeWhere((item) => item.id == id);
      return true;
    } on ApiException catch (e) {
      _showSnackbar(title: 'Gagal Menghapus', message: e.message, isError: true);
      return false;
    } catch (_) {
      _showSnackbar(
        title: 'Gagal Menghapus',
        message: 'Tidak dapat menghapus catatan. Silakan coba lagi.',
        isError: true,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Mencari catatan berdasarkan ID di daftar lokal untuk tampilan detail reaktif.
  NoteModel? findNoteById(int id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  void _showSnackbar({
    required String title,
    required String message,
    required bool isError,
  }) {
    if (Get.overlayContext == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceInput,
      colorText: isError ? AppColors.error : AppColors.textPrimary,
      borderColor: isError ? AppColors.error : AppColors.border,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
