// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/note_controller.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/note_card.dart';
import '../widgets/scanote_brand.dart';

/// Halaman utama daftar catatan pengguna dengan pencarian debounce sesuai desain Figma.
class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  late final TextEditingController _searchController;
  late final NoteController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = Get.isRegistered<NoteController>()
        ? Get.find<NoteController>()
        : Get.put<NoteController>(
            NoteController(apiService: Get.find<ApiService>()),
          );
    _searchController = TextEditingController(
      text: _noteController.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    await _noteController.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
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
                    if (_noteController.isLoading.value) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${_noteController.notes.length} dokumen',
                      style: textTheme.bodyMedium,
                    );
                  }),
                ],
              ),
            ),

            // Kolom pencarian catatan (debounce 400 ms di NoteController).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Obx(() {
                final hasQuery = _noteController.searchQuery.value.isNotEmpty;
                return TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _noteController.search,
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau isi catatan',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: hasQuery
                        ? IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                );
              }),
            ),

            // Area konten daftar catatan dengan state loading, error, kosong, dan isi.
            Expanded(
              child: Obx(() {
                if (_noteController.isLoading.value) {
                  return const LoadingView(message: 'Memuat daftar catatan...');
                }

                final error = _noteController.errorMessage.value;
                if (error != null && _noteController.notes.isEmpty) {
                  return ErrorView(
                    message: error,
                    onRetry: () => _noteController.loadNotes(),
                  );
                }

                if (_noteController.notes.isEmpty) {
                  final isSearching = _noteController.isSearching;
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: _noteController.refreshNotes,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      children: [
                        if (isSearching)
                          _EmptySearchView(
                            query: _noteController.searchQuery.value.trim(),
                            onReset: _clearSearch,
                          )
                        else
                          _EmptyNotesView(
                            onScanTap: () => Get.toNamed<void>(AppRoutes.scan),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _noteController.refreshNotes,
                  child: ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: _noteController.notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = _noteController.notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => Get.toNamed<void>(
                          AppRoutes.detail,
                          arguments: note,
                        ),
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
          onPressed: () => Get.toNamed<void>(AppRoutes.scan),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Scan'),
        ),
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
            Text('Belum ada catatan', style: textTheme.titleMedium),
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

class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView({
    required this.query,
    required this.onReset,
  });

  final String query;
  final VoidCallback onReset;

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
                Icons.search_off_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text('Catatan tidak ditemukan', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tidak ada catatan yang cocok dengan kata kunci "$query".',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(
                Icons.restart_alt_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              label: const Text('Tampilkan semua'),
            ),
          ],
        ),
      ),
    );
  }
}
