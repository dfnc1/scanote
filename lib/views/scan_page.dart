import 'dart:io';

// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/scan_controller.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_view.dart';

/// Halaman ambil foto catatan (kamera/galeri) dan kirim ke backend untuk dibaca AI.
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  ScanController _ensureScanController() {
    if (Get.isRegistered<ScanController>()) {
      return Get.find<ScanController>();
    }
    return Get.put<ScanController>(
      ScanController(apiService: Get.find<ApiService>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _ensureScanController();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Catatan'),
      ),
      body: Obx(() {
        final isScanning = controller.isScanning.value;
        final pickedFile = controller.pickedImage.value;
        final error = controller.errorMessage.value;
        final activeSource = controller.activeSource.value;

        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posisikan catatan di dalam bingkai.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Bingkai viewfinder dengan 4 sudut siku hijau lime sesuai Figma.
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            if (pickedFile != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Foto siap dipindai',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: CustomPaint(
                                foregroundPainter: const _CornerBracketPainter(),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: pickedFile != null
                                        ? _PickedImagePreview(file: pickedFile)
                                        : _EmptyFramePrompt(textTheme: textTheme),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Pastikan tulisan terlihat jelas',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Pemilih sumber foto Kamera / Galeri bergaya segmented control Figma.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SourceButton(
                              icon: Icons.camera_alt_outlined,
                              label: 'Kamera',
                              isSelected: activeSource == ImageSource.camera,
                              onTap: isScanning
                                  ? null
                                  : controller.pickFromCamera,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _SourceButton(
                              icon: Icons.photo_outlined,
                              label: 'Galeri',
                              isSelected: activeSource == ImageSource.gallery,
                              onTap: isScanning
                                  ? null
                                  : controller.pickFromGallery,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tombol Baca Teks nonaktif sebelum ada foto.
                    ElevatedButton.icon(
                      onPressed: (pickedFile == null || isScanning)
                          ? null
                          : controller.scan,
                      icon: const Icon(Icons.document_scanner_outlined, size: 20),
                      label: const Text('Baca Teks'),
                    ),
                  ],
                ),
              ),
            ),

            // Overlay loading penuh saat proses pembacaan AI berlangsung.
            if (isScanning)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background.withValues(alpha: 0.88),
                  child: const LoadingView(
                    message: 'Membaca teks dari foto...',
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.paperSurface,
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  color: AppColors.paperInk,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Pratinjau foto siap dipindai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.paperInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFramePrompt extends StatelessWidget {
  const _EmptyFramePrompt({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            color: AppColors.textSecondary,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada foto catatan',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Ambil foto lewat Kamera atau pilih gambar dari Galeri di bawah.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: isSelected ? AppColors.surfaceInput : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menggambar 4 siku sudut hijau lime pada bingkai pratinjau scan.
class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 24.0;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Kiri atas
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, 0)
        ..lineTo(cornerLen, 0),
      paint,
    );
    // Kanan atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLen),
      paint,
    );
    // Kiri bawah
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height)
        ..lineTo(cornerLen, size.height),
      paint,
    );
    // Kanan bawah
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
