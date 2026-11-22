// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/scanote_brand.dart';

/// Halaman placeholder sementara untuk rute /notes (Irisan 2 sebelum NoteListPage di Irisan 3).
class NotesPlaceholderPage extends StatelessWidget {
  const NotesPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const ScanoteBrand(compact: true),
        actions: [
          TextButton.icon(
            onPressed: () => authController.logout(),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catatanku', style: textTheme.headlineLarge),
              const SizedBox(height: 16),
              Obx(() {
                final activeUser = authController.user.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesi Aktif',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeUser != null && activeUser.name.isNotEmpty
                              ? activeUser.name
                              : 'Pengguna Scanote',
                          style: textTheme.titleLarge,
                        ),
                        if (activeUser != null && activeUser.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(activeUser.email, style: textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          'Halaman daftar catatan (placeholder Irisan 2). Daftar kartu catatan dan tombol Scan akan hadir di Irisan 3.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
