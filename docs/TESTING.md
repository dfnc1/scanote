# Pengujian Scanote

Isi kolom **Hasil Aktual** dan **Status** (✅ Berhasil / ❌ Gagal) saat menguji.
Tabel ini bisa langsung dipakai untuk BAB IV laporan. Simpan screenshot bukti tiap
kasus penting di folder `docs/screenshots/`.

**Lingkungan uji:** perangkat/emulator: ______ | versi Android: ______ | tanggal: ______

## A. Autentikasi

| ID | Skenario | Langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| T-01 | Daftar berhasil | Isi nama, email baru, password 8+ karakter, tekan Daftar | Akun dibuat, masuk ke Daftar Catatan | | |
| T-02 | Daftar dengan email sudah terpakai | Daftar dengan email yang sama | Pesan "Email sudah terdaftar" | | |
| T-03 | Validasi form daftar | Kosongkan nama / email salah format / password < 8 | Pesan error tiap field, tidak mengirim request | | |
| T-04 | Login berhasil | Masukkan email dan password benar | Masuk ke Daftar Catatan | | |
| T-05 | Login salah password | Masukkan password salah | Pesan "Email atau password salah" | | |
| T-06 | Sesi bertahan | Login, tutup aplikasi, buka lagi | Langsung ke Daftar Catatan | | |
| T-07 | Logout | Tekan Keluar | Kembali ke Login, token terhapus | | |

## B. Scan

| ID | Skenario | Langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| T-08 | Scan dari kamera | Scan → Kamera → ambil foto → Baca Teks | Loading tampil, lalu Preview berisi teks | | |
| T-09 | Scan dari galeri | Scan → Galeri → pilih foto → Baca Teks | Preview berisi teks | | |
| T-10 | Tombol Baca Teks sebelum ada foto | Buka Scan tanpa memilih foto | Tombol nonaktif | | |
| T-11 | Tulisan tangan rapi | Foto catatan rapi | Teks terbaca benar atau hanya sedikit salah | | |
| T-12 | Tulisan berantakan atau foto gelap | Foto catatan sulit dibaca | Hasil tidak sempurna, tetap bisa diedit | | |
| T-13 | Foto tanpa tulisan | Foto objek tanpa teks | Pesan "Teks tidak terbaca", bisa isi manual | | |
| T-14 | Foto terlalu besar | Kirim foto > 5 MB (tanpa kompres, uji lewat API) | Error 413 dengan pesan jelas | | |

## C. CRUD Catatan

| ID | Skenario | Langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| T-15 | Simpan catatan (Create) | Preview → isi judul → Simpan | Kembali ke daftar, catatan muncul | | |
| T-16 | Validasi judul kosong | Kosongkan judul → Simpan | Pesan "Judul wajib diisi" | | |
| T-17 | Lihat daftar (Read) | Buka Daftar Catatan | Semua catatan akun tampil, terbaru di atas | | |
| T-18 | Daftar kosong | Akun baru tanpa catatan | Tampil "Belum ada catatan" | | |
| T-19 | Lihat detail | Ketuk salah satu catatan | Judul, tanggal, dan isi lengkap tampil | | |
| T-20 | Ubah catatan (Update) | Detail → edit → ubah isi → Simpan | Perubahan tersimpan dan tampil | | |
| T-21 | Hapus dibatalkan | Detail → hapus → pilih Batal | Catatan tetap ada | | |
| T-22 | Hapus catatan (Delete) | Detail → hapus → Konfirmasi | Catatan hilang dari daftar | | |

## D. Pencarian

| ID | Skenario | Langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| T-23 | Cari ada hasil | Ketik kata yang ada di judul atau isi | Hanya catatan yang cocok tampil | | |
| T-24 | Cari tanpa hasil | Ketik kata yang tidak ada | Tampil pesan hasil tidak ditemukan | | |
| T-25 | Hapus kata pencarian | Kosongkan kolom cari | Semua catatan tampil kembali | | |

## E. Penanganan Error dan Keamanan

| ID | Skenario | Langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| T-26 | Server mati | Matikan backend, buka Daftar Catatan | Pesan "Tidak dapat terhubung ke server" + tombol Coba lagi | | |
| T-27 | Coba lagi setelah server hidup | Nyalakan backend, tekan Coba lagi | Data berhasil dimuat | | |
| T-28 | Token tidak valid | Ubah token atau tunggu kedaluwarsa, buka daftar | Logout otomatis ke Login | | |
| T-29 | Isolasi data antar akun | Akun A membuat catatan; login sebagai akun B | Akun B tidak melihat catatan A | | |
| T-30 | Akses catatan akun lain lewat API | Dengan token B, `GET /api/notes/{id milik A}` | Status 404 | | |
| T-31 | Tanpa token | Panggil `/api/notes` tanpa header Authorization | Status 401 | | |
| T-32 | Kuota Gemini habis | (Jika terjadi) scan saat limit | Pesan "Layanan AI sedang sibuk" | | |

## F. Rekap

| Kategori | Jumlah kasus | Berhasil | Gagal |
|---|---|---|---|
| Autentikasi | 7 | | |
| Scan | 7 | | |
| CRUD | 8 | | |
| Pencarian | 3 | | |
| Error dan keamanan | 7 | | |
| **Total** | **32** | | |

## G. Daftar Bug dan Perbaikan

| ID | Deskripsi bug | Ditemukan di | Status perbaikan |
|---|---|---|---|
| | | | |
