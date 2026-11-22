# PLAN_MOBILE.md: Rencana Frontend Scanote (Flutter)

> File ini adalah acuan untuk AI agent dan developer yang mengerjakan sisi **mobile**.
> Baca seluruh file sebelum menulis kode. Kerjakan sesuai urutan di bagian 11.

## 1. Gambaran Proyek

**Scanote** adalah aplikasi mobile pencatat digital. Pengguna memotret catatan tulisan
tangan, AI (Gemini, dipanggil oleh backend) membaca fotonya menjadi teks, pengguna
mengecek dan mengedit hasilnya, lalu catatan disimpan di akunnya sendiri.

Proyek ini adalah tugas UAS Praktikum Mobile Programming (Flutter, kelompok 2 orang).
Sisi backend (Go) dikerjakan orang lain. Dokumen ini hanya membahas **Flutter**.

## 2. Aturan Wajib (dari ketentuan UAS)

1. Framework: **Flutter**.
2. **State management utama: GetX** (`GetxController`, `.obs`, `Obx`). `setState()` hanya
   boleh untuk kebutuhan kecil dan lokal (misalnya toggle visibilitas password).
   **Dilarang memakai Provider, BLoC, atau Riverpod.**
3. Semua data lewat **REST API** memakai package **`dio`**. Dilarang memakai Firebase.
4. **CRUD** lengkap lewat API: Create, Read, Update, Delete catatan.
5. **Model class** dengan `fromJson()` dan `toJson()`.
6. **Asynchronous**: `Future`, `async`, `await` untuk semua panggilan API.
7. Wajib menangani: loading, API tidak bisa diakses, data gagal diambil, request gagal.
8. **Form dengan validasi** dan pesan error.
9. Minimal **3 halaman** dengan navigasi (di proyek ini ada 6).
10. Minimal **1 fitur tambahan**: **search catatan**.
11. Setiap anggota harus paham seluruh kode, jadi tulis kode yang sederhana dan beri
    komentar singkat berbahasa Indonesia pada bagian penting.

## 3. Tech Stack Mobile

| Kebutuhan | Package |
|---|---|
| State management dan navigasi | `get` |
| HTTP client | `dio` |
| Kamera dan galeri | `image_picker` |
| Kompres foto sebelum dikirim | `flutter_image_compress` |
| Simpan token login | `get_storage` |
| Format tanggal | `intl` |

Tambahkan lewat `flutter pub add`. Jangan menambah package lain tanpa alasan kuat.

## 4. Struktur Folder

```
lib/
├── main.dart                     # GetMaterialApp, routes, cek token awal
├── models/
│   ├── note_model.dart           # NoteModel (fromJson / toJson)
│   └── user_model.dart           # UserModel (fromJson / toJson)
├── services/
│   ├── api_service.dart          # kelas abstrak + implementasi dio
│   └── fake_api_service.dart     # data dummy (dipakai sebelum backend siap)
├── controllers/
│   ├── auth_controller.dart      # login, register, logout, token
│   ├── note_controller.dart      # daftar, search, tambah, ubah, hapus
│   └── scan_controller.dart      # pilih foto, kirim ke /api/scan, hasil
├── views/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── note_list_page.dart
│   ├── scan_page.dart
│   ├── preview_page.dart         # preview dan edit hasil scan
│   └── note_detail_page.dart     # detail, edit, hapus
├── widgets/
│   ├── note_card.dart
│   ├── loading_view.dart
│   └── error_view.dart           # pesan error + tombol "Coba lagi"
└── utils/
    ├── constants.dart            # baseUrl, useFakeApi
    ├── validators.dart           # validasi form
    └── app_theme.dart            # warna dan tema
```

Aturan folder: halaman hanya berisi tampilan; logika dan state ada di controller;
panggilan jaringan hanya di `services/`.

## 5. Kontrak REST API (disediakan backend)

Base URL disimpan di `utils/constants.dart`:
- Emulator Android: `http://10.0.2.2:8080`
- Perangkat fisik: `http://<IP-laptop>:8080` (satu Wi-Fi)

Semua respons JSON. Error selalu berbentuk `{"error": "pesan bahasa Indonesia"}`.
Endpoint selain register/login memakai header `Authorization: Bearer <token>`.

| Method | Endpoint | Request | Respons sukses |
|---|---|---|---|
| POST | `/api/auth/register` | `{"name","email","password"}` | `{"token","user":{"id","name","email"}}` |
| POST | `/api/auth/login` | `{"email","password"}` | `{"token","user":{...}}` |
| POST | `/api/scan` | `multipart/form-data`, field `image` | `{"title","content"}` (belum disimpan) |
| GET | `/api/notes?q=` | none | `{"notes":[Note,...]}` |
| POST | `/api/notes` | `{"title","content"}` | `Note` |
| PUT | `/api/notes/{id}` | `{"title","content"}` | `Note` |
| DELETE | `/api/notes/{id}` | none | `{"message":"..."}` |

Objek `Note`:

```json
{
  "id": 1,
  "title": "Catatan Basis Data",
  "content": "Normalisasi bertujuan mengurangi redundansi data...",
  "created_at": "2026-11-08T10:00:00+07:00"
}
```

Kode status yang perlu ditangani: `400` (input salah), `401` (token tidak valid atau
kedaluwarsa, lalu logout otomatis dan kembali ke Login), `404`, `409` (email sudah
terdaftar), `5xx`, serta kegagalan jaringan (timeout, tidak ada koneksi).

## 6. Model

**`NoteModel`**: `id` (int), `title` (String), `content` (String), `createdAt` (DateTime).
- `factory NoteModel.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()` (hanya `title` dan `content`, untuk create/update)
- `copyWith()`

**`UserModel`**: `id`, `name`, `email`, dengan `fromJson()` dan `toJson()`.

`fromJson` harus aman terhadap field `null` (beri nilai default) dan `created_at`
bertipe string ISO 8601.

## 7. ApiService

- Buat `abstract class ApiService` dengan method: `register`, `login`, `scanImage(File)`,
  `getNotes({String? query})`, `createNote`, `updateNote`, `deleteNote`.
- `DioApiService` mengimplementasikannya: `baseUrl` dari constants, timeout 15 detik
  (scan 60 detik), interceptor menambahkan header Bearer dari token tersimpan.
- Terjemahkan `DioException` menjadi `ApiException(message)` berbahasa Indonesia:
  - tidak ada koneksi atau timeout: "Tidak dapat terhubung ke server. Periksa koneksi."
  - 401: "Sesi berakhir, silakan masuk kembali."
  - 409: "Email sudah terdaftar."
  - 5xx: "Server sedang bermasalah. Coba lagi nanti."
  - lainnya: pakai field `error` dari respons bila ada.
- `FakeApiService` mengimplementasikan interface yang sama dengan data dummy
  (5 catatan, scan mengembalikan teks contoh setelah jeda 2 detik, login menerima
  email dan password apa saja). Dipilih lewat `useFakeApi` di `constants.dart`.

## 8. Controller (GetX)

**`AuthController`**
- State: `user` (`Rxn<UserModel>`), `isLoading` (`RxBool`), `errorMessage` (`RxnString`).
- Method: `login`, `register`, `logout`, `checkSession` (baca token dari `get_storage`).
- Token disimpan di `get_storage`. Setelah login sukses: `Get.offAllNamed('/notes')`.

**`NoteController`**
- State: `notes` (`RxList<NoteModel>`), `isLoading`, `errorMessage`, `searchQuery`.
- Method: `loadNotes()`, `search(String q)` (debounce 400 ms, memanggil API dengan `?q=`),
  `addNote`, `updateNote`, `deleteNote`. Setelah create/update/delete, muat ulang daftar
  atau perbarui `notes` secara lokal.

**`ScanController`**
- State: `pickedImage` (`Rxn<File>`), `isScanning`, `errorMessage`,
  `resultTitle`, `resultContent`.
- Method: `pickFromCamera()`, `pickFromGallery()`, `scan()` (kompres foto ke lebar
  sekitar 1280 px dan kualitas 80, lalu kirim ke `/api/scan`).
- Jika hasil kosong, tampilkan pesan "Teks tidak terbaca. Coba foto ulang dengan
  pencahayaan lebih baik." dan tetap izinkan lanjut ke Preview untuk isi manual.

Semua controller memakai `.obs`, dan UI memakai `Obx`. Dependency didaftarkan dengan
`Get.put` / `Get.lazyPut` (boleh lewat `Bindings`).

## 9. Halaman dan Perilaku

Rute (`GetMaterialApp` + `getPages`): `/login`, `/register`, `/notes`, `/scan`,
`/preview`, `/detail`.

| Halaman | Isi | Perilaku |
|---|---|---|
| **Login** | Logo/nama Scanote, field email dan password, tombol Masuk, tautan ke Daftar | Validasi, loading di tombol, error via snackbar |
| **Daftar** | Nama, email, password, konfirmasi password | Validasi, sukses lalu langsung masuk |
| **Daftar Catatan** | AppBar (judul, tombol Keluar), kolom search, `ListView` berisi `NoteCard`, FAB "+ Scan" | Pull-to-refresh, state kosong ("Belum ada catatan"), state loading, state error dengan tombol "Coba lagi" |
| **Scan** | Pratinjau foto, tombol Kamera dan Galeri, tombol "Baca Teks" | Tombol nonaktif sebelum ada foto, loading penuh saat scan |
| **Preview & Edit** | Field judul, kolom isi (multiline, bisa diedit), tombol Simpan | Validasi judul wajib diisi, sukses lalu kembali ke Daftar Catatan dan tampilkan snackbar |
| **Detail Catatan** | Judul, tanggal (format `intl`), isi lengkap, ikon edit dan hapus | Edit memakai form yang sama dengan Preview; hapus meminta konfirmasi dialog |

Catatan: halaman Preview dipakai ulang untuk mode **edit** (field sudah terisi, tombol
memanggil `updateNote`). Jangan membuat dua form berbeda.

## 10. Validasi Form

| Field | Aturan | Pesan |
|---|---|---|
| Nama | tidak kosong | "Nama wajib diisi" |
| Email | tidak kosong, format valid | "Format email tidak valid" |
| Password | minimal 8 karakter | "Password minimal 8 karakter" |
| Konfirmasi password | sama dengan password | "Password tidak cocok" |
| Judul catatan | tidak kosong, maksimal 100 karakter | "Judul wajib diisi" |
| Isi catatan | tidak kosong | "Isi catatan tidak boleh kosong" |

Gunakan `Form` + `TextFormField` + `validator`. Fungsi validator ada di
`utils/validators.dart`.

## 11. Urutan Pengerjaan dan Commit

Kerjakan **satu tugas per prompt** di branch `feature/ui`. Sebelum commit jalankan
`flutter analyze --no-version-check` sampai bersih. Jangan `git push`. Jangan menyentuh
folder `backend/`.

| # | Tugas | Commit |
|---|---|---|
| 1 | Tambah dependency (`get`, `dio`, `image_picker`, `flutter_image_compress`, `get_storage`, `intl`), izin kamera di `AndroidManifest.xml`, `constants.dart`, `app_theme.dart` | `chore(mobile): add dependencies, camera permission, and theme` |
| 2 | `NoteModel`, `UserModel` | `feat(model): add NoteModel and UserModel with fromJson/toJson` |
| 3 | `ApiService`, `FakeApiService`, `ApiException` | `feat(service): add API service with fake data mode` |
| 4 | `validators.dart`, widget `LoadingView`, `ErrorView`, `NoteCard` | `feat(widgets): add shared widgets and validators` |
| 5 | `AuthController`, halaman Login dan Daftar, rute, `main.dart` | `feat(auth): add login and register pages with GetX` |
| 6 | `NoteController`, halaman Daftar Catatan (list, search, refresh, state kosong/error) | `feat(note): add note list with search` |
| 7 | `ScanController`, halaman Scan | `feat(scan): add scan page with camera and gallery` |
| 8 | Halaman Preview & Edit dan Detail, lengkap dengan hapus dan konfirmasi | `feat(note): add preview, detail, edit, and delete` |
| 9 | Sambungkan ke backend sungguhan (`useFakeApi = false`), uji alur lengkap, perbaiki bug | `fix(mobile): integrate with backend API` |
| 10 | Rapikan UI, tangani semua kondisi error, ambil screenshot untuk laporan | `style(mobile): polish UI and error states` |

Selama backend belum siap, tetap `useFakeApi = true` sehingga seluruh UI bisa dibangun
dan diuji tanpa server.

## 12. Definition of Done

- [ ] Alur lengkap berjalan: daftar, masuk, scan, preview, simpan, lihat, edit, hapus
- [ ] Setiap operasi CRUD bisa didemokan
- [ ] State loading, error server tidak bisa diakses, dan data kosong ditangani di semua halaman
- [ ] Semua form memiliki validasi dan pesan error
- [ ] Search catatan berfungsi
- [ ] Token tersimpan, aplikasi langsung masuk ke Daftar Catatan jika sudah login
- [ ] Tidak ada `setState` untuk state utama, semua lewat GetX
- [ ] `flutter analyze` bersih
- [ ] Screenshot tiap halaman sudah diambil untuk laporan

## 13. Larangan

- Jangan memakai Firebase, Provider, BLoC, atau Riverpod.
- Jangan memanggil Gemini langsung dari aplikasi. Selalu lewat `/api/scan`.
- Jangan meng-hardcode API key atau token.
- Jangan mengubah folder `backend/`.
- Jangan menambah fitur di luar rencana ini tanpa persetujuan.
