// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/note_controller.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/note_card.dart';
import '../widgets/scanote_brand.dart';

/// Halaman utama daftar catatan pengguna sesuai desain Figma (Catatanku.png).
class NoteListPage extends StatelessWidget {
  const NoteListPage({super.key});

  NoteController _ensureNoteController() {
    if (Get.isRegistered<NoteController>()) {
      return Get.find<NoteController>();
    }
    return Get.put<NoteController>(
      NoteController(apiService: Get.find<ApiService>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final noteController = _ensureNoteController();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const ScanoteBrand(compact: true),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Hapus controller catatan agar data akun sebelumnya tidak terbawa saat ganti akun.
              if (Get.isRegistered<NoteController>()) {
                Get.delete<NoteController>();
              }
              authController.logout();
            },
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            label: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header judul halaman dan jumlah dokumen real.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text('Catatanku', style: textTheme.headlineLarge),
                  ),
                  Obx(() {
                    if (noteController.isLoading.value) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${noteController.notes.length} dokumen',
                      style: textTheme.bodyMedium,
                    );
                  }),
                ],
              ),
            ),

            // Area konten daftar catatan dengan state loading, error, kosong, dan isi.
            Expanded(
              child: Obx(() {
                if (noteController.isLoading.value) {
                  return const LoadingView(message: 'Memuat daftar catatan...');
                }

                final error = noteController.errorMessage.value;
                if (error != null && noteController.notes.isEmpty) {
                  return ErrorView(
                    message: error,
                    onRetry: () => noteController.loadNotes(),
                  );
                }

                if (noteController.notes.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: noteController.refreshNotes,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 48,
                      ),
                      children: [
                        _EmptyNotesView(
                          onScanTap: () => _openScanPlaceholder(context),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: noteController.refreshNotes,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: noteController.notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = noteController.notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          // TODO(irisan-5): arahkan ke NoteDetailPage.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Detail "${note.title}" tersedia di Irisan 5.',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton.icon(
          onPressed: () => _openScanPlaceholder(context),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Scan'),
        ),
      ),
    );
  }

  void _openScanPlaceholder(BuildContext context) {
    // TODO(irisan-4): arahkan ke ScanPage.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Halaman Scan akan tersedia di Irisan 4.'),
      ),
    );
  }
}

class _EmptyNotesView extends StatelessWidget {
  const _EmptyNotesView({required this.onScanTap});

  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.note_add_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pindai catatan tulisan tanganmu agar tersimpan rapi dan mudah dicari kapan saja.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onScanTap,
              icon: const Icon(
                Icons.document_scanner_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              label: const Text('Mulai Scan Pertama'),
            ),
          ],
        ),
      ),
    );
  }
}
