import 'package:flutter_test/flutter_test.dart';

import 'package:scanote/models/note_model.dart';
import 'package:scanote/models/user_model.dart';
import 'package:scanote/services/api_service.dart';
import 'package:scanote/utils/date_formatter.dart';
import 'package:scanote/utils/validators.dart';

void main() {
  group('UserModel', () {
    test('fromJson memproses data valid dan string id', () {
      final user = UserModel.fromJson(const {
        'id': '42',
        'name': 'Budi Santoso',
        'email': 'budi@mail.com',
      });
      expect(user.id, 42);
      expect(user.name, 'Budi Santoso');
      expect(user.email, 'budi@mail.com');
    });

    test('fromJson aman terhadap nilai null atau kosong', () {
      final user = UserModel.fromJson(const {
        'id': null,
        'name': null,
        'email': null,
      });
      expect(user.id, 0);
      expect(user.name, '');
      expect(user.email, '');
    });

    test('toJson dan copyWith bekerja konsisten', () {
      const user = UserModel(id: 1, name: 'Rani', email: 'rani@mail.com');
      expect(user.toJson(), {
        'id': 1,
        'name': 'Rani',
        'email': 'rani@mail.com',
      });

      final updated = user.copyWith(name: 'Rani Putri');
      expect(updated.id, 1);
      expect(updated.name, 'Rani Putri');
      expect(updated.email, 'rani@mail.com');
    });
  });

  group('NoteModel', () {
    test('fromJson memparsing tanggal ISO 8601 dan toJson hanya title/content', () {
      final note = NoteModel.fromJson(const {
        'id': 10,
        'title': 'Catatan Jaringan',
        'content': 'Model OSI terdiri dari tujuh lapisan.',
        'created_at': '2026-11-08T10:30:00+07:00',
      });

      expect(note.id, 10);
      expect(note.title, 'Catatan Jaringan');
      expect(note.content, 'Model OSI terdiri dari tujuh lapisan.');
      expect(note.createdAt.year, 2026);
      expect(note.createdAt.month, 11);
      expect(note.toJson(), {
        'title': 'Catatan Jaringan',
        'content': 'Model OSI terdiri dari tujuh lapisan.',
      });
    });

    test('fromJson aman terhadap null dan format tanggal rusak', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final note = NoteModel.fromJson(const {
        'id': 'abc',
        'title': null,
        'content': null,
        'created_at': 'bukan-tanggal',
      });
      final after = DateTime.now().add(const Duration(seconds: 2));

      expect(note.id, 0);
      expect(note.title, '');
      expect(note.content, '');
      expect(note.createdAt.isAfter(before), isTrue);
      expect(note.createdAt.isBefore(after), isTrue);
    });

    test('copyWith mempertahankan field yang tidak diubah', () {
      final date = DateTime(2026, 11, 9);
      final note = NoteModel(
        id: 2,
        title: 'Awal',
        content: 'Isi awal',
        createdAt: date,
      );
      final edited = note.copyWith(title: 'Baru');
      expect(edited.id, 2);
      expect(edited.title, 'Baru');
      expect(edited.content, 'Isi awal');
      expect(edited.createdAt, date);
    });
  });

  group('Response Models', () {
    test('AuthResponse dan ScanResult aman terhadap map kosong', () {
      final auth = AuthResponse.fromJson(const {});
      expect(auth.token, '');
      expect(auth.user.id, 0);

      final scan = ScanResult.fromJson(const {
        'title': 'Judul Scan',
        'content': 'Isi hasil baca',
      });
      expect(scan.title, 'Judul Scan');
      expect(scan.content, 'Isi hasil baca');

      const ex = ApiException('Koneksi gagal', statusCode: 503);
      expect(ex.toString(), 'Koneksi gagal');
      expect(ex.statusCode, 503);
    });
  });

  group('Validators', () {
    test('validateName menolak kosong dan menerima teks valid', () {
      expect(Validators.validateName(null), 'Nama wajib diisi');
      expect(Validators.validateName(''), 'Nama wajib diisi');
      expect(Validators.validateName('   '), 'Nama wajib diisi');
      expect(Validators.validateName('Rani'), isNull);
    });

    test('validateEmail memeriksa format email', () {
      expect(Validators.validateEmail(null), 'Format email tidak valid');
      expect(Validators.validateEmail(''), 'Format email tidak valid');
      expect(Validators.validateEmail('rani'), 'Format email tidak valid');
      expect(Validators.validateEmail('rani@mail'), 'Format email tidak valid');
      expect(Validators.validateEmail('rani @mail.com'), 'Format email tidak valid');
      expect(Validators.validateEmail('rani@mail.com'), isNull);
    });

    test('validatePassword mewajibkan minimal 8 karakter', () {
      expect(Validators.validatePassword(null), 'Password minimal 8 karakter');
      expect(Validators.validatePassword('1234567'), 'Password minimal 8 karakter');
      expect(Validators.validatePassword('12345678'), isNull);
    });

    test('validateConfirmPassword memastikan kecocokan', () {
      expect(
        Validators.validateConfirmPassword(null, 'rahasia123'),
        'Password tidak cocok',
      );
      expect(
        Validators.validateConfirmPassword('berbeda123', 'rahasia123'),
        'Password tidak cocok',
      );
      expect(
        Validators.validateConfirmPassword('rahasia123', 'rahasia123'),
        isNull,
      );
    });

    test('validateNoteTitle menolak kosong dan > 100 karakter', () {
      expect(Validators.validateNoteTitle(null), 'Judul wajib diisi');
      expect(Validators.validateNoteTitle('   '), 'Judul wajib diisi');
      expect(
        Validators.validateNoteTitle('A' * 101),
        'Judul maksimal 100 karakter',
      );
      expect(Validators.validateNoteTitle('A' * 100), isNull);
      expect(Validators.validateNoteTitle('Catatan Basis Data'), isNull);
    });

    test('validateNoteContent menolak teks kosong', () {
      expect(
        Validators.validateNoteContent(null),
        'Isi catatan tidak boleh kosong',
      );
      expect(
        Validators.validateNoteContent('   \n  '),
        'Isi catatan tidak boleh kosong',
      );
      expect(Validators.validateNoteContent('Isi lengkap'), isNull);
    });
  });

  group('DateFormatter', () {
    test('formatShortDate dan formatDateTime menghasilkan format Indonesia', () {
      final date = DateTime(2026, 11, 9, 10, 5);
      expect(DateFormatter.formatShortDate(date), '9 Nov 2026');
      expect(DateFormatter.formatDateTime(date), '9 Nov 2026, 10:05');
    });
  });
}
