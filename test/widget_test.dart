import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:scanote/main.dart';
import 'package:scanote/models/note_model.dart';
import 'package:scanote/models/user_model.dart';
import 'package:scanote/services/fake_api_service.dart';

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

  testWidgets('Halaman placeholder fondasi tampil dan tombol uji dummy bekerja',
      (WidgetTester tester) async {
    final fakeApi = FakeApiService(
      simulatedDelay: Duration.zero,
      scanDelay: Duration.zero,
    );

    await tester.pumpWidget(ScanoteApp(apiService: fakeApi));

    expect(find.text('scanote'), findsOneWidget);
    expect(find.text('Fondasi Siap.'), findsOneWidget);
    expect(find.text('Uji Muat Data Dummy'), findsOneWidget);

    await tester.tap(find.text('Uji Muat Data Dummy'));
    await tester.pumpAndSettle();

    expect(
      find.text('Berhasil memuat 5 catatan dummy dari ApiService.'),
      findsOneWidget,
    );
  });
}
