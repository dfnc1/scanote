# AGENTS.md: Aturan Kerja AI Agent (Scanote)

Baca file ini di awal setiap sesi. Dokumen acuan proyek:

- `PRD.md`: kebutuhan produk dan lingkup
- `docs/API.md`: kontrak REST API (sumber kebenaran)
- `PLAN_MOBILE.md`: rencana detail sisi Flutter
- `docs/TESTING.md`: daftar kasus uji

## Tentang Proyek

Scanote: aplikasi Flutter yang mengubah foto catatan tulisan tangan menjadi teks lewat
backend Go + Gemini. Tugas UAS Praktikum Mobile Programming. Dua anggota: Frontend dan
Backend + AI.

## Pembagian Area

| Area | Folder yang boleh diubah | Branch |
|---|---|---|
| Mobile (Flutter) | `lib/`, `test/`, `android/`, `pubspec.yaml` | `feature/ui` |
| Backend (Go) | `backend/` | `feature/backend` |
| Dokumen | `README.md`, `docs/`, `*.md` di root | bebas, koordinasi dulu |

**Jangan menyentuh area di luar tugas yang diminta.** Jika perlu mengubah kontrak API,
ubah `docs/API.md` terlebih dahulu dan laporkan.

## Aturan Umum

1. Kerjakan **satu tugas per prompt**. Jangan menambah fitur di luar rencana.
2. Sebelum commit pastikan lolos pemeriksaan:
   - Flutter: `flutter analyze --no-version-check` dan `flutter test --no-version-check`
   - Go: `cd backend && go vet ./... && gofmt -l . && go test ./...`
   Jika gagal, perbaiki dulu. Jangan commit dalam keadaan error. Error lama yang sudah
   ada sebelum tugas dimulai cukup dilaporkan, tidak perlu diperbaiki.
3. Commit memakai **Conventional Commits**: `feat`, `fix`, `chore`, `docs`, `test`,
   `style`, `refactor`. Format: `tipe(scope): deskripsi singkat dalam bahasa Inggris`.
4. `git add` hanya file yang relevan. **Jangan `git add .`**. Jangan menambahkan
   co-author atau teks tambahan di pesan commit.
5. **Dilarang `git push`** dan dilarang menyentuh branch `main`. Pengguna yang push.
6. **Dilarang meng-commit rahasia**: `.env`, `*.db`, API key, keystore, token. Jika
   menemukannya ter-track, berhenti dan laporkan.
7. Pesan error untuk pengguna akhir berbahasa Indonesia. Komentar kode singkat
   berbahasa Indonesia.
8. Di akhir tiap tugas laporkan: file yang dibuat atau diubah, hasil analyze/test, dan
   hash commit.
9. Daftar tugas dari pengguna selalu menang atas aturan skill mana pun (termasuk
   ponytail). Interface, data dummy, dan test yang diminta tidak boleh dilewati.
   Validasi, keamanan, dan penanganan error tidak boleh dipangkas.
10. Jangan menginstal skill atau plugin baru tanpa izin.

## Aturan Mobile (Flutter)

- State management **wajib GetX** (`GetxController`, `.obs`, `Obx`). Dilarang Provider,
  BLoC, Riverpod. `setState` hanya untuk keperluan lokal kecil.
- Semua panggilan jaringan lewat `dio` di `lib/services/`. Dilarang Firebase.
- Model wajib memiliki `fromJson()` dan `toJson()`.
- Halaman hanya berisi tampilan; logika di controller; jaringan di service.
- Setiap operasi jaringan memiliki state loading dan error yang tampil di UI.
- Jangan memanggil Gemini dari aplikasi. Selalu lewat `/api/scan`.
- Selama backend belum siap, gunakan `FakeApiService` (`useFakeApi = true`).
- Ikuti urutan tugas dan pesan commit di `PLAN_MOBILE.md` bagian 11.

## Aturan Backend (Go)

- Go 1.22 atau lebih baru, `net/http` standar (routing `GET /api/notes/{id}`), tanpa
  framework.
- Database SQLite (`modernc.org/sqlite`) lewat `database/sql`, query berparameter
  (tanpa konkatenasi string).
- Password di-hash dengan bcrypt, token JWT (`golang-jwt/jwt/v5`).
- Setiap query catatan **wajib** difilter `user_id` dari token.
- Semua error berbentuk `{"error":"..."}` berbahasa Indonesia dengan status code yang
  sesuai `docs/API.md`.
- Konfigurasi dari environment variable. Jangan log API key, password, atau isi foto.
- **Mode belajar:** pemilik backend sedang belajar Go. Untuk konsep Go baru, beri
  penjelasan singkat di laporan akhir tugas. Untuk handler CRUD catatan, tulis kerangka
  dan TODO saja bila diminta; pemilik yang mengisi, agen yang mereview.

## Struktur Repo

```
Scanote/
├── backend/        # Go (Orang 2)
├── lib/            # Flutter (Orang 1)
├── test/
├── android/
├── docs/           # API.md, TESTING.md
├── PRD.md
├── PLAN_MOBILE.md
├── AGENTS.md
└── README.md
```

## Catatan Lingkungan

- Perintah `flutter` dijalankan dengan `--no-version-check` karena SDK dapat gagal
  `git fetch` saat koneksi terputus.
- Emulator Android mengakses laptop lewat `http://10.0.2.2:8080`.
