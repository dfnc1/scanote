# PRD: Scanote

**Product Requirements Document**
Versi 1.0 | Tugas UAS Praktikum Mobile Programming | Tim 2 orang

## 1. Ringkasan

Scanote adalah aplikasi mobile (Flutter) untuk mendigitalkan catatan tulisan tangan.
Pengguna memotret catatan, AI membaca fotonya menjadi teks, pengguna mengecek dan
mengedit hasilnya, lalu catatan tersimpan di akun masing-masing dan bisa dicari.

**Tagline:** foto catatanmu, jadi teks yang bisa dicari.

## 2. Latar Belakang dan Masalah

- Catatan tulisan tangan (kuliah, rapat, papan tulis) mudah hilang atau rusak.
- Mengetik ulang ke bentuk digital memakan waktu, sehingga sering ditunda.
- Foto catatan di galeri tidak bisa dicari isinya dan tidak terorganisir.

## 3. Tujuan

1. Mengubah foto catatan menjadi teks yang dapat diedit dan dicari.
2. Menyimpan catatan terpisah untuk setiap akun.
3. Memenuhi ketentuan UAS: Flutter, REST API, CRUD, Model & JSON, GetX, form dan
   validasi, async dengan penanganan error, minimal satu fitur tambahan.

**Bukan tujuan (di luar lingkup):** OCR offline, kolaborasi antar pengguna, sinkronisasi
multi-perangkat real-time, folder atau tag, versi iOS, dan rilis ke Play Store.

## 4. Target Pengguna

Mahasiswa dan pelajar yang masih mencatat dengan tulisan tangan dan ingin menyimpannya
secara digital dengan cepat.

**Skenario utama:** Rani memotret catatan Basis Data dari buku, menekan "Baca Teks",
memperbaiki dua kata yang salah terbaca, lalu menyimpannya. Seminggu kemudian ia
mengetik "normalisasi" di kolom cari dan catatan itu langsung ditemukan.

## 5. User Story

| ID | Sebagai pengguna, saya ingin... | Agar... |
|---|---|---|
| US-1 | mendaftar dan masuk ke akun | catatan saya tersimpan secara pribadi |
| US-2 | memotret atau memilih foto catatan | tidak perlu mengetik ulang |
| US-3 | melihat dan mengedit hasil bacaan AI | kesalahan baca bisa diperbaiki sebelum disimpan |
| US-4 | menyimpan catatan | bisa dibuka kembali kapan saja |
| US-5 | melihat daftar catatan saya | menemukan catatan dengan mudah |
| US-6 | mencari catatan berdasarkan kata | tidak perlu membuka satu per satu |
| US-7 | mengubah dan menghapus catatan | isinya selalu rapi dan relevan |
| US-8 | mendapat pesan jelas saat terjadi masalah | tahu apa yang harus dilakukan |

## 6. Kebutuhan Fungsional

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-1 | Register dengan nama, email, password | Wajib |
| FR-2 | Login, token tersimpan, sesi bertahan setelah aplikasi ditutup | Wajib |
| FR-3 | Logout | Wajib |
| FR-4 | Ambil foto dari kamera atau galeri | Wajib |
| FR-5 | Kirim foto ke server dan terima teks hasil bacaan AI | Wajib |
| FR-6 | Preview dan edit judul serta isi sebelum disimpan | Wajib |
| FR-7 | Simpan catatan (Create) | Wajib |
| FR-8 | Lihat daftar catatan milik akun sendiri (Read) | Wajib |
| FR-9 | Lihat detail catatan | Wajib |
| FR-10 | Ubah catatan (Update) | Wajib |
| FR-11 | Hapus catatan dengan konfirmasi (Delete) | Wajib |
| FR-12 | Cari catatan berdasarkan judul dan isi | Wajib (fitur tambahan UAS) |
| FR-13 | Buat catatan manual tanpa foto | Opsional |
| FR-14 | Pull-to-refresh pada daftar catatan | Opsional |

## 7. Kebutuhan Non-Fungsional

| Aspek | Ketentuan |
|---|---|
| Keamanan | Password disimpan sebagai hash bcrypt. Token JWT kedaluwarsa 24 jam. Setiap query catatan difilter `user_id` dari token, sehingga pengguna tidak dapat membaca data akun lain. API key Gemini hanya ada di server (`.env`), tidak pernah di aplikasi. |
| Kinerja | Foto dikompres di aplikasi sebelum dikirim. Timeout API biasa 15 detik, scan 60 detik. |
| Keandalan | Setiap kegagalan jaringan, timeout, dan error server menampilkan pesan berbahasa Indonesia dengan opsi mencoba lagi. |
| Kegunaan | Tampilan konsisten, tombol utama selalu terlihat, state loading dan kosong ditampilkan jelas. |
| Platform | Android (emulator dan perangkat fisik). |
| Privasi | Foto tidak disimpan permanen di server. Foto hanya diteruskan ke Gemini lalu dibuang. |

## 8. Alur Pengguna

```
Buka aplikasi
  ├─ belum login → Login ⇄ Daftar
  └─ sudah login → Daftar Catatan
                     ├─ cari catatan (search)
                     ├─ ketuk catatan → Detail → edit / hapus
                     └─ [+ Scan] → Scan (kamera/galeri) → "Baca Teks"
                                    → Preview & Edit → Simpan → Daftar Catatan
```

## 9. Halaman

| Halaman | Fungsi |
|---|---|
| Login | Masuk dengan email dan password |
| Daftar | Membuat akun |
| Daftar Catatan | Daftar kartu catatan, kolom cari, tombol + Scan |
| Scan | Ambil foto dan kirim untuk dibaca |
| Preview & Edit | Mengecek dan mengedit hasil, lalu menyimpan (juga dipakai untuk mode edit) |
| Detail Catatan | Membaca isi lengkap, tombol edit dan hapus |

Rincian perilaku tiap halaman ada di `PLAN_MOBILE.md`.

## 10. Arsitektur

```
Flutter (GetX, dio)  ──REST/JSON──>  Backend Go (net/http, SQLite, JWT)  ──>  Gemini API
```

- **Mobile:** `views` → `controllers` (GetX) → `services` (dio) → `models`
- **Backend:** `handler` → `database` (SQLite); `gemini.go` memanggil Gemini
- Spesifikasi endpoint ada di `docs/API.md`.

## 11. Model Data

**User:** id, name, email, password_hash, created_at
**Note:** id, user_id, title, content, created_at

## 12. Penanganan Kasus Khusus

| Kasus | Perilaku |
|---|---|
| Teks tidak terbaca AI | Pesan "Teks tidak terbaca, coba foto ulang"; pengguna tetap bisa mengisi manual di Preview |
| Foto terlalu besar atau format salah | Ditolak server dengan pesan jelas (maks 5 MB, JPEG atau PNG) |
| Token kedaluwarsa | Logout otomatis, kembali ke Login |
| Server tidak dapat dijangkau | Pesan "Tidak dapat terhubung ke server" dan tombol Coba lagi |
| Kuota Gemini habis (429) | Pesan "Layanan AI sedang sibuk, coba beberapa saat lagi" |
| Email sudah terdaftar | Pesan "Email sudah terdaftar" |

## 13. Metrik Keberhasilan

- Seluruh operasi CRUD dapat didemokan tanpa error.
- Tulisan tangan yang jelas terbaca dengan benar pada sebagian besar contoh uji.
- Pengguna A tidak dapat melihat atau mengubah catatan pengguna B (diuji).
- Semua kondisi error pada ketentuan UAS tertangani (loading, server mati, request gagal).

## 14. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Tulisan tangan berantakan terbaca salah | Layar preview dan edit wajib sebelum simpan |
| Limit gratis Gemini habis saat demo | Siapkan foto uji, hindari uji berlebihan sebelum presentasi, tangani error 429 |
| Backend mati atau jaringan bermasalah saat demo | Jalankan backend di laptop, uji koneksi sebelum presentasi, siapkan mode data dummy |
| API key bocor | `.env` masuk `.gitignore`, `.env.example` tanpa nilai asli |
| Anggota tidak paham kode buatan AI | Baca dan jelaskan hasil tiap tugas, gunakan kode sederhana dengan komentar |

## 15. Pembagian Tugas

| Anggota | Peran | Tanggung jawab |
|---|---|---|
| Orang 1 (@TODO) | Frontend | Seluruh halaman Flutter, GetX, model, ApiService, validasi form, penanganan loading dan error |
| Orang 2 ([@dfnc1](https://github.com/dfnc1)) | Backend + AI | Server Go, SQLite, autentikasi JWT, endpoint CRUD, integrasi Gemini |
| Bersama | | Kontrak API, pengujian, laporan, presentasi |

## 16. Pemetaan ke Ketentuan UAS

| Ketentuan | Pemenuhan di Scanote |
|---|---|
| Minimal 3 halaman + navigasi | 6 halaman dengan named routes GetX |
| UI (Row, Column, Card, TextField) | `NoteCard`, form, daftar, dialog |
| REST API | Backend Go milik sendiri + Gemini API |
| CRUD | Catatan: simpan, daftar, ubah, hapus |
| Model & JSON | `NoteModel` dan `UserModel` dengan `fromJson()` / `toJson()` |
| GetX | `AuthController`, `NoteController`, `ScanController`, `.obs`, `Obx` |
| Asynchronous | `Future`/`async`/`await` + loading dan error |
| Form dan validasi | Login, daftar, catatan |
| Fitur tambahan | Search catatan |

## 17. Jadwal

| Fase | Isi | Target selesai |
|---|---|---|
| 1 | Kontrak API disepakati, repo dan struktur folder rapi | TODO |
| 2 | Frontend dengan data dummy dan backend CRUD berjalan paralel | TODO |
| 3 | Integrasi, scan dengan Gemini, uji alur lengkap | TODO |
| 4 | Pengujian, perbaikan, screenshot | TODO |
| 5 | Laporan dan latihan presentasi | TODO |
