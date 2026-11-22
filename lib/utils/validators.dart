/// Kumpulan fungsi validasi form berbahasa Indonesia sesuai spesifikasi PLAN_MOBILE.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty || value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  static String? validateNoteTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Judul wajib diisi';
    }
    if (trimmed.length > 100) {
      return 'Judul maksimal 100 karakter';
    }
    return null;
  }

  static String? validateNoteContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Isi catatan tidak boleh kosong';
    }
    return null;
  }
}
