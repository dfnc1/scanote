// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/note_controller.dart';
import '../controllers/scan_controller.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// Halaman Preview & Edit: dipakai untuk menyimpan hasil scan maupun mengedit catatan.
class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  NoteModel? _existingNote;
  String? _emptyWarning;
  int _charCount = 0;

  NoteController get _noteController {
    if (Get.isRegistered<NoteController>()) {
      return Get.find<NoteController>();
    }
    return Get.put<NoteController>(
      NoteController(apiService: Get.find<ApiService>()),
    );
  }

  bool get _isEditMode => _existingNote != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    String initialTitle = '';
    String initialContent = '';

    if (args is Map) {
      final rawNote = args['note'];
      if (rawNote is NoteModel) {
        _existingNote = rawNote;
        initialTitle = rawNote.title;
        initialContent = rawNote.content;
      } else {
        initialTitle = (args['title'] ?? '').toString();
        initialContent = (args['content'] ?? '').toString();
      }
      final warning = args['emptyWarning'];
      if (warning is String && warning.isNotEmpty) {
        _emptyWarning = warning;
      }
    }

    _titleController = TextEditingController(text: initialTitle);
    _contentController = TextEditingController(text: initialContent);
    _charCount = initialContent.length;
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final len = _contentController.text.length;
    if (len != _charCount) {
      setState(() {
        _charCount = len;
      });
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _copyContent() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada teks untuk disalin.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Isi catatan disalin ke papan klip.')),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isEditMode) {
      final updated = await _noteController.updateNote(
        id: _existingNote!.id,
        title: _titleController.text,
        content: _contentController.text,
      );
      if (updated != null) {
        Get.back<NoteModel>(result: updated);
        _showSuccessSnackbar('Catatan berhasil diperbarui.');
      }
    } else {
      final created = await _noteController.addNote(
        title: _titleController.text,
        content: _contentController.text,
      );
      if (created != null) {
        if (Get.isRegistered<ScanController>()) {
          Get.find<ScanController>().clearScan();
        }
        // Kembali langsung ke halaman Daftar Catatan (/notes).
        Get.until((route) => route.settings.name == AppRoutes.notes);
        _showSuccessSnackbar('Catatan berhasil disimpan.');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    if (Get.overlayContext == null) return;
    Get.snackbar(
      'Berhasil',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceInput,
      colorText: AppColors.primary,
      borderColor: AppColors.border,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Preview & Edit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_emptyWarning != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$_emptyWarning Kamu tetap dapat menulis judul dan isi catatan secara manual di bawah.',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Field Judul Catatan
                Text('Judul catatan', style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.validateNoteTitle,
                  style: textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan judul catatan',
                    suffixIcon: Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Header kolom isi dengan jumlah karakter dan tombol Salin.
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode ? 'Isi catatan' : 'Hasil ekstraksi',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_charCount karakter',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _copyContent,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Salin'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Field Isi Catatan multiline.
                TextFormField(
                  controller: _contentController,
                  minLines: 10,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: Validators.validateNoteContent,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Tulis atau perbaiki isi catatan di sini...',
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? 'Perubahan akan langsung tersimpan ke akunmu.'
                            : 'Ketuk teks untuk mengoreksi hasil pindai.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Obx(() {
          final saving = _noteController.isSubmitting.value;
          return ElevatedButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Simpan'),
                    ],
                  ),
          );
        }),
      ),
    );
  }
}
