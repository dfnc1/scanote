// GetX 4.7 masih memakai widget dan ThemeData dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'services/api_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put<ApiService>(createApiService());
  runApp(const ScanoteApp());
}

/// Root aplikasi Scanote menggunakan GetMaterialApp dan tema gelap Figma.
class ScanoteApp extends StatelessWidget {
  const ScanoteApp({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    if (apiService != null && !Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(apiService!);
    } else if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(createApiService());
    }

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const FoundationPlaceholderPage(),
    );
  }
}

/// Controller sederhana sementara untuk menguji koneksi ApiService di irisan 1.
class _FoundationCheckController extends GetxController {
  _FoundationCheckController(this._apiService);

  final ApiService _apiService;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final loadedNotesCount = RxnInt();

  Future<void> testLoadDummyNotes() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final notes = await _apiService.getNotes();
      loadedNotesCount.value = notes.length;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Gagal memuat data percobaan.';
    } finally {
      isLoading.value = false;
    }
  }
}

/// Halaman placeholder sementara untuk memverifikasi fondasi aplikasi (Irisan 1).
class FoundationPlaceholderPage extends StatelessWidget {
  const FoundationPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      _FoundationCheckController(Get.find<ApiService>()),
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identitas brand Scanote sesuai desain Figma.
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'scanote',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pindai cepat. Catat lebih rapi.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              // Garis aksen lime khas header Scanote.
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fondasi Siap.',
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Halaman sementara (Irisan 1). Tema, model data, dan layanan API dummy sudah terpasang. Halaman Login dan Daftar akan hadir pada irisan berikutnya.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Kartu informasi status konfigurasi aktif.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status Konfigurasi', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Mode API',
                        value: AppConstants.useFakeApi
                            ? 'FakeApiService (data dummy)'
                            : 'DioApiService (backend)',
                      ),
                      const SizedBox(height: 8),
                      const _StatusRow(
                        label: 'Base URL',
                        value: AppConstants.baseUrl,
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Memuat data dummy...',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          );
                        }
                        if (controller.errorMessage.value != null) {
                          return Text(
                            controller.errorMessage.value!,
                            style: const TextStyle(color: AppColors.error),
                          );
                        }
                        if (controller.loadedNotesCount.value != null) {
                          return Text(
                            'Berhasil memuat ${controller.loadedNotesCount.value} catatan dummy dari ApiService.',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return Text(
                          'Tekan tombol di bawah untuk menguji FakeApiService.',
                          style: textTheme.bodyMedium,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol aksi nyata untuk menguji layanan API dummy.
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.testLoadDummyNotes,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    controller.isLoading.value
                        ? 'Memeriksa...'
                        : 'Uji Muat Data Dummy',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
