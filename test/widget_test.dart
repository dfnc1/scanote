import 'dart:io';

// GetX 4.7 masih memakai widget dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:scanote/controllers/auth_controller.dart';
import 'package:scanote/controllers/scan_controller.dart';
import 'package:scanote/main.dart';
import 'package:scanote/models/note_model.dart';
import 'package:scanote/models/user_model.dart';
import 'package:scanote/services/api_service.dart';
import 'package:scanote/services/fake_api_service.dart';

/// Penyimpanan sesi di memori khusus pengujian agar tidak bergantung pada disk.
class _InMemoryAuthStorage implements AuthStorage {
  String? _token;
  Map<String, dynamic>? _user;

  @override
  String? readToken() => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Map<String, dynamic>? readUser() => _user;

  @override
  Future<void> writeUser(Map<String, dynamic> userJson) async => _user = userJson;

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}

/// Fake API khusus untuk mensimulasikan kegagalan server lalu pemulihan saat Coba lagi.
class _FlakyNotesApiService extends FakeApiService {
  _FlakyNotesApiService({this.failOnce = false, this.emptyList = false})
      : super(simulatedDelay: Duration.zero, scanDelay: Duration.zero);

  bool failOnce;
  final bool emptyList;

  @override
  Future<List<NoteModel>> getNotes({String? query}) async {
    if (failOnce) {
      failOnce = false;
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi.',
      );
    }
    if (emptyList) {
      return const [];
    }
    return super.getNotes(query: query);
  }
}

void main() {
  tearDown(Get.reset);

  group('Model JSON serialization', () {
    test('UserModel.fromJson aman terhadap null dan toJson sesuai kontrak', () {
      final user = UserModel.fromJson(const {
        'id': 7,
        'name': 'Rani',
        'email': 'rani@mail.com',
      });
      expect(user.id, 7);
      expect(user.name, 'Rani');
      expect(user.email, 'rani@mail.com');
      expect(user.toJson(), {
        'id': 7,
        'name': 'Rani',
        'email': 'rani@mail.com',
      });

      final emptyUser = UserModel.fromJson(const {});
      expect(emptyUser.id, 0);
      expect(emptyUser.name, '');
      expect(emptyUser.email, '');
    });

    test('NoteModel.fromJson parsing ISO 8601 dan toJson hanya title & content', () {
      final note = NoteModel.fromJson(const {
        'id': 1,
        'title': 'Catatan Basis Data',
        'content': 'Normalisasi bertujuan mengurangi redundansi.',
        'created_at': '2026-11-08T10:00:00+07:00',
      });
      expect(note.id, 1);
      expect(note.title, 'Catatan Basis Data');
      expect(note.content, 'Normalisasi bertujuan mengurangi redundansi.');
      expect(note.createdAt.year, 2026);
      expect(note.toJson(), {
        'title': 'Catatan Basis Data',
        'content': 'Normalisasi bertujuan mengurangi redundansi.',
      });

      final safeNote = NoteModel.fromJson(const {'id': null});
      expect(safeNote.id, 0);
      expect(safeNote.title, '');
      expect(safeNote.content, '');
    });
  });

  group('FakeApiService', () {
    test('menyediakan 5 catatan dummy, mendukung CRUD, search, dan scan', () async {
      final api = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );

      final initialNotes = await api.getNotes();
      expect(initialNotes.length, 5);

      final searched = await api.getNotes(query: 'normalisasi');
      expect(searched.length, 1);
      expect(searched.first.title, 'Catatan Basis Data');

      final created = await api.createNote(
        title: 'Catatan Baru',
        content: 'Isi catatan baru',
      );
      expect((await api.getNotes()).length, 6);

      final updated = await api.updateNote(
        id: created.id,
        title: 'Catatan Diubah',
        content: 'Isi diubah',
      );
      expect(updated.title, 'Catatan Diubah');

      await api.deleteNote(created.id);
      expect((await api.getNotes()).length, 5);

      final scan = await api.scanImage(File('dummy.jpg'));
      expect(scan.title.isNotEmpty, isTrue);
      expect(scan.content.isNotEmpty, isTrue);
    });
  });

  group('Alur Autentikasi (Irisan 2)', () {
    testWidgets('Validasi login tampil dan login sukses menuju /notes lalu logout',
        (WidgetTester tester) async {
      final fakeApi = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();

      await tester.pumpWidget(
        ScanoteApp(apiService: fakeApi, authStorage: storage),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatanmu,\nselalu dekat.'), findsOneWidget);

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Password minimal 8 karakter'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'rani@mail.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'rahasia123',
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Catatanku'), findsOneWidget);
      expect(find.text('5 dokumen'), findsOneWidget);
      expect(storage.readToken(), isNotNull);

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.text('Catatanmu,\nselalu dekat.'), findsOneWidget);
      expect(storage.readToken(), isNull);
    });

    testWidgets('Navigasi ke Daftar, cek konfirmasi password, dan daftar berhasil ke /notes',
        (WidgetTester tester) async {
      final fakeApi = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();

      await tester.pumpWidget(
        ScanoteApp(apiService: fakeApi, authStorage: storage),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Buat Akun'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Rani Putri');
      await tester.enterText(find.byType(TextFormField).at(1), 'rani@mail.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
      await tester.enterText(find.byType(TextFormField).at(3), 'berbeda123');

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Password tidak cocok'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Catatanku'), findsOneWidget);
      expect(find.text('Rencana Proyek Akhir'), findsOneWidget);
    });

    testWidgets('Sesi tersimpan langsung membuka rute /notes saat aplikasi dibuka ulang',
        (WidgetTester tester) async {
      final fakeApi = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');
      await storage.writeUser({
        'id': 1,
        'name': 'Rani',
        'email': 'rani@mail.com',
      });

      await tester.pumpWidget(
        ScanoteApp(apiService: fakeApi, authStorage: storage),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatanku'), findsOneWidget);
      expect(find.text('Rencana Proyek Akhir'), findsOneWidget);
    });
  });

  group('Daftar Catatan (Irisan 3)', () {
    testWidgets('State kosong menampilkan "Belum ada catatan"',
        (WidgetTester tester) async {
      final api = _FlakyNotesApiService(emptyList: true);
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');

      await tester.pumpWidget(ScanoteApp(apiService: api, authStorage: storage));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada catatan'), findsOneWidget);
      expect(find.text('0 dokumen'), findsOneWidget);
    });

    testWidgets('State error menampilkan pesan dan tombol Coba lagi memulihkan data',
        (WidgetTester tester) async {
      final api = _FlakyNotesApiService(failOnce: true);
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');

      await tester.pumpWidget(ScanoteApp(apiService: api, authStorage: storage));
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak dapat terhubung ke server. Periksa koneksi.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Rencana Proyek Akhir'), findsOneWidget);
      expect(find.text('5 dokumen'), findsOneWidget);
    });
  });

  group('Alur Scan sampai Simpan (Irisan 4)', () {
    testWidgets('Tombol Baca Teks nonaktif sebelum ada foto, lalu scan -> preview -> simpan',
        (WidgetTester tester) async {
      final api = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');

      Get.put<ScanController>(
        ScanController(
          apiService: api,
          imagePicker: (_) async => File('catatan_uji.jpg'),
          imageCompressor: (file) async => file,
        ),
      );

      await tester.pumpWidget(ScanoteApp(apiService: api, authStorage: storage));
      await tester.pumpAndSettle();

      // Buka halaman Scan dari tombol + Scan.
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Catatan'), findsOneWidget);

      // Pastikan tombol Baca Teks nonaktif sebelum foto dipilih (T-10).
      final bacaButtonBefore = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Baca Teks'),
      );
      expect(bacaButtonBefore.onPressed, isNull);

      // Pilih foto dari Galeri -> tombol Baca Teks aktif.
      await tester.tap(find.text('Galeri'));
      await tester.pumpAndSettle();
      expect(find.text('Foto siap dipindai'), findsOneWidget);

      final bacaButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Baca Teks'),
      );
      expect(bacaButtonAfter.onPressed, isNotNull);

      // Baca teks -> masuk ke Preview & Edit.
      await tester.tap(find.text('Baca Teks'));
      await tester.pumpAndSettle();
      expect(find.text('Preview & Edit'), findsOneWidget);

      // Kosongkan judul -> validasi "Judul wajib diisi" (T-16).
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Judul wajib diisi'), findsOneWidget);

      // Isi judul baru -> simpan -> kembali ke /notes dengan jumlah catatan bertambah.
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Catatan Fisika Dasar',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Catatanku'), findsOneWidget);
      expect(find.text('Catatan Fisika Dasar'), findsOneWidget);
      expect(find.text('6 dokumen'), findsOneWidget);

      // Tunggu timer snackbar GetX selesai agar tidak menyisakan pending timer di test.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });

  group('Detail, Ubah, dan Hapus Catatan (Irisan 5)', () {
    testWidgets('Buka detail, edit catatan via PreviewPage, batal hapus, lalu konfirmasi hapus',
        (WidgetTester tester) async {
      final api = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');

      await tester.pumpWidget(ScanoteApp(apiService: api, authStorage: storage));
      await tester.pumpAndSettle();

      // Buka detail catatan pertama (T-19).
      await tester.tap(find.text('Rencana Proyek Akhir'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('Edit catatan'), findsOneWidget);

      // Edit catatan menggunakan PreviewPage mode edit (T-20).
      await tester.tap(find.text('Edit catatan'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Catatan'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Rencana Proyek Akhir Revisi',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('Rencana Proyek Akhir Revisi'), findsOneWidget);

      // Hapus dibatalkan -> catatan tetap ada (T-21).
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus catatan?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Rencana Proyek Akhir Revisi'), findsOneWidget);

      // Hapus dikonfirmasi -> kembali ke daftar dan jumlah berkurang (T-22).
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hapus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatanku'), findsOneWidget);
      expect(find.text('Rencana Proyek Akhir Revisi'), findsNothing);
      expect(find.text('4 dokumen'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });

  group('Pencarian Catatan dengan Debounce (Irisan 6)', () {
    testWidgets('Cari ada hasil, cari tanpa hasil, lalu hapus pencarian menampilkan semua',
        (WidgetTester tester) async {
      final api = FakeApiService(
        simulatedDelay: Duration.zero,
        scanDelay: Duration.zero,
      );
      final storage = _InMemoryAuthStorage();
      await storage.writeToken('saved-token');

      await tester.pumpWidget(ScanoteApp(apiService: api, authStorage: storage));
      await tester.pumpAndSettle();
      expect(find.text('5 dokumen'), findsOneWidget);

      // Cari kata yang ada di isi catatan (T-23).
      await tester.enterText(find.byType(TextField), 'normalisasi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Catatan Basis Data'), findsOneWidget);
      expect(find.text('1 dokumen'), findsOneWidget);

      // Cari kata yang tidak ada -> tampil pesan hasil kosong (T-24).
      await tester.enterText(find.byType(TextField), 'katatidakada999');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Catatan tidak ditemukan'), findsOneWidget);
      expect(find.text('0 dokumen'), findsOneWidget);

      // Hapus kata pencarian -> semua catatan tampil kembali (T-25).
      await tester.tap(find.text('Tampilkan semua'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('5 dokumen'), findsOneWidget);
      expect(find.text('Rencana Proyek Akhir'), findsOneWidget);
    });
  });
}
