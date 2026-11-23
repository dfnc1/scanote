import 'dart:io';

import '../models/note_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Layanan API tiruan dengan data dummy agar pengembangan UI bisa berjalan tanpa backend.
class FakeApiService implements ApiService {
  FakeApiService({
    this.simulatedDelay = const Duration(milliseconds: 400),
    this.scanDelay = const Duration(seconds: 2),
  }) : _notes = [
          NoteModel(
            id: 1,
            title: 'Rencana Proyek Akhir',
            content:
                'Tujuan:\nMembantu mahasiswa memindai, menyimpan, dan menemukan catatan kuliah.\n\n'
                'Ruang lingkup:\n- Pindai dokumen melalui kamera\n- Ubah hasil pindai menjadi teks\n- Cari catatan berdasarkan kata kunci\n\n'
                'Target selesai: 30 November 2026.',
            createdAt: DateTime(2026, 11, 9, 10, 15),
          ),
          NoteModel(
            id: 2,
            title: 'Catatan Basis Data',
            content:
                'Normalisasi bertujuan mengurangi redundansi data dan menjaga konsistensi tabel.\n\n'
                '1NF: setiap kolom bernilai atomik.\n'
                '2NF: tidak ada ketergantungan parsial terhadap primary key.\n'
                '3NF: tidak ada ketergantungan transitif antar kolom non-kunci.',
            createdAt: DateTime(2026, 11, 8, 14, 30),
          ),
          NoteModel(
            id: 3,
            title: 'Notulen Rapat Tim',
            content:
                'Pembagian tugas dan jadwal pengerjaan minggu ini:\n'
                '1. Frontend fokus menyelesaikan alur login, daftar catatan, dan scan.\n'
                '2. Backend menyiapkan endpoint autentikasi JWT, CRUD catatan, dan Gemini.\n'
                '3. Uji integrasi dilakukan bersama di akhir pekan.',
            createdAt: DateTime(2026, 11, 7, 16, 0),
          ),
          NoteModel(
            id: 4,
            title: 'Ringkasan Pemrograman Mobile',
            content:
                'GetX memisahkan tampilan (View), logika dan state (Controller), serta akses jaringan (Service).\n'
                'Gunakan .obs dan Obx agar perubahan state langsung memperbarui widget secara efisien.',
            createdAt: DateTime(2026, 11, 6, 9, 45),
          ),
          NoteModel(
            id: 5,
            title: 'Ide untuk Minggu Ini',
            content:
                'Baca ulang bab arsitektur REST API, rapikan catatan kuliah praktikum, dan siapkan beberapa foto tulisan tangan untuk uji scan.',
            createdAt: DateTime(2026, 11, 5, 19, 20),
          ),
        ];

  final Duration simulatedDelay;
  final Duration scanDelay;
  final List<NoteModel> _notes;
  int _nextId = 6;

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    return AuthResponse(
      token: 'fake-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 1,
        name: name.trim(),
        email: email.trim(),
      ),
    );
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    final trimmedEmail = email.trim();
    final fallbackName = trimmedEmail.contains('@')
        ? trimmedEmail.split('@').first
        : 'Pengguna Scanote';
    return AuthResponse(
      token: 'fake-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 1,
        name: fallbackName,
        email: trimmedEmail,
      ),
    );
  }

  @override
  Future<ScanResult> scanImage(File imageFile) async {
    await Future<void>.delayed(scanDelay);
    return const ScanResult(
      title: 'Catatan Hasil Pindai',
      content:
          'Ini adalah contoh teks hasil pembacaan catatan tulisan tangan dalam mode data dummy.\n\n'
          'Kamu bisa memeriksa dan mengedit judul maupun isi catatan ini sebelum menyimpannya.',
    );
  }

  @override
  Future<List<NoteModel>> getNotes({String? query}) async {
    await Future<void>.delayed(simulatedDelay);
    final keyword = (query ?? '').trim().toLowerCase();

    final filtered = keyword.isEmpty
        ? List<NoteModel>.from(_notes)
        : _notes.where((note) {
            return note.title.toLowerCase().contains(keyword) ||
                note.content.toLowerCase().contains(keyword);
          }).toList();

    // Urutkan dari catatan terbaru terlebih dahulu sesuai kontrak API.
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<NoteModel> getNoteById(int id) async {
    await Future<void>.delayed(simulatedDelay);
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      throw const ApiException('Catatan tidak ditemukan', statusCode: 404);
    }
    return _notes[index];
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    required String content,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    final newNote = NoteModel(
      id: _nextId++,
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    _notes.add(newNote);
    return newNote;
  }

  @override
  Future<NoteModel> updateNote({
    required int id,
    required String title,
    required String content,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      throw const ApiException('Catatan tidak ditemukan', statusCode: 404);
    }
    final updated = _notes[index].copyWith(
      title: title.trim(),
      content: content.trim(),
    );
    _notes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteNote(int id) async {
    await Future<void>.delayed(simulatedDelay);
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      throw const ApiException('Catatan tidak ditemukan', statusCode: 404);
    }
    _notes.removeAt(index);
  }
}
