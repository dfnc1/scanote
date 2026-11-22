// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/note_controller.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

/// Halaman detail catatan lengkap dengan aksi Edit (memakai PreviewPage) dan Hapus.
class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({super.key});

  NoteController _ensureNoteController() {
    if (Get.isRegistered<NoteController>()) {
      return Get.find<NoteController>();
    }
    return Get.put<NoteController>(
      NoteController(apiService: Get.find<ApiService>()),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NoteController controller,
    NoteModel note,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text(
          'Catatan "${note.title}" akan dihapus secara permanen dan tidak dapat dikembalikan.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await controller.deleteNote(note.id);
    if (deleted) {
      Get.back<void>();
      if (Get.overlayContext != null) {
        Get.snackbar(
          'Dihapus',
          'Catatan dihapus.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceInput,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.border,
          borderWidth: 1,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _copyNoteContent(BuildContext context, NoteModel note) async {
    await Clipboard.setData(ClipboardData(text: note.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Isi catatan disalin ke papan klip.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteController = _ensureNoteController();
    final initialNote = Get.arguments is NoteModel ? Get.arguments as NoteModel : null;

    if (initialNote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: const Center(
          child: Text('Catatan tidak ditemukan.'),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
      ),
      body: SafeArea(
        child: Obx(() {
          final currentNote =
              noteController.findNoteById(initialNote.id) ?? initialNote;
          final isSubmitting = noteController.isSubmitting.value;
          final charCount = currentNote.content.trim().length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentNote.title, style: textTheme.headlineLarge),
                const SizedBox(height: 12),

                // Metadata tanggal dan panjang karakter real.
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormatter.formatShortDate(currentNote.createdAt)} · $charCount karakter',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tombol Edit catatan & Hapus sejajar sesuai desain Figma.
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => Get.toNamed<void>(
                                  AppRoutes.preview,
                                  arguments: {'note': currentNote},
                                ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Edit catatan',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () => _confirmDelete(
                                  context,
                                  noteController,
                                  currentNote,
                                ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Kartu isi catatan lengkap.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ISI CATATAN',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Salin isi catatan',
                              onPressed: () =>
                                  _copyNoteContent(context, currentNote),
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          currentNote.content,
                          style: textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
