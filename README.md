# Scanote

**Foto catatanmu, jadi teks yang bisa dicari.**

Scanote adalah aplikasi mobile (Flutter) yang mengubah foto catatan tulisan tangan
menjadi teks digital menggunakan AI, lalu menyimpannya di akun pengguna.

> 🚧 **Status:** dalam pengembangan (tugas UAS Praktikum Mobile Programming)

## 📌 Latar Belakang

Catatan tulisan tangan mudah hilang, sulit dicari, dan merepotkan jika harus diketik
ulang. Foto catatan di galeri pun tidak bisa dicari isinya. Scanote menyelesaikannya:
**foto catatan, AI membaca, pengguna mengecek, lalu tersimpan dan bisa dicari.**

## 🚀 Fitur

- 🔐 Register dan login (JWT), catatan terpisah per akun
- 📷 Scan catatan dari kamera atau galeri
- 🤖 Pembacaan tulisan tangan dengan Google Gemini (lewat backend)
- ✏️ Preview dan edit hasil sebelum disimpan
- 📝 CRUD catatan: simpan, lihat, ubah, hapus
- 🔍 Pencarian catatan

## 🔄 Alur Penggunaan

```
Login → Scan (kamera/galeri) → Baca Teks → Preview & Edit → Simpan → Daftar Catatan → Cari
```

## 🛠️ Tech Stack

| Lapisan | Teknologi |
|---|---|
| Mobile | Flutter (Dart), GetX, dio |
| Backend | Go (`net/http`), SQLite, JWT, bcrypt |
| AI | Google Gemini API (dipanggil dari backend) |

```
Flutter (GetX, dio) ──REST/JSON──> Backend Go ──> Gemini API
```

## 📚 Dokumentasi

| File | Isi |
|---|---|
| [PRD.md](PRD.md) | Kebutuhan produk, lingkup, risiko |
| [docs/API.md](docs/API.md) | Spesifikasi REST API |
| [PLAN_MOBILE.md](PLAN_MOBILE.md) | Rencana pengerjaan sisi Flutter |
| [docs/TESTING.md](docs/TESTING.md) | Kasus uji |
| [AGENTS.md](AGENTS.md) | Aturan kerja AI agent |

## 👥 Tim

| Peran | Anggota | Fokus |
|---|---|---|
| Frontend | @TODO | Seluruh aplikasi Flutter |
| Backend + AI | [@dfnc1](https://github.com/dfnc1) | Server Go, database, autentikasi, integrasi Gemini |

## 💻 Menjalankan Proyek

### Prasyarat

- Flutter SDK 3.x, Android Studio atau VS Code, emulator atau perangkat Android
- Go 1.22 atau lebih baru
- API key Gemini dari [Google AI Studio](https://aistudio.google.com)
- Git

### 1. Clone

```bash
git clone https://github.com/dfnc1/Scanote.git
cd Scanote
```

### 2. Jalankan backend

```bash
cd backend
cp .env.example .env     # lalu isi JWT_SECRET dan GEMINI_API_KEY
go run .
```

Cek: `curl localhost:8080/api/health` harus membalas `{"status":"ok"}`.

> ⚠️ Jangan pernah meng-commit file `.env` atau API key.

### 3. Jalankan aplikasi

```bash
flutter pub get
flutter run
```

Alamat server diatur di `lib/utils/constants.dart`:

- Emulator Android: `http://10.0.2.2:8080`
- Perangkat fisik: `http://<IP-laptop>:8080` (satu Wi-Fi dengan laptop)

Selama backend belum siap, setel `useFakeApi = true` untuk memakai data dummy.

## 🔌 Endpoint Utama

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/api/auth/register` | Daftar |
| POST | `/api/auth/login` | Login |
| POST | `/api/scan` | Foto jadi teks |
| GET | `/api/notes?q=` | Daftar dan cari catatan |
| POST | `/api/notes` | Simpan catatan |
| PUT | `/api/notes/{id}` | Ubah catatan |
| DELETE | `/api/notes/{id}` | Hapus catatan |

Detail lengkap ada di [docs/API.md](docs/API.md).

## 🗺️ Roadmap

- [ ] Backend: server, database, autentikasi
- [ ] Backend: CRUD catatan dan pencarian
- [ ] Backend: endpoint scan dengan Gemini
- [ ] Mobile: login dan daftar
- [ ] Mobile: daftar catatan dan search
- [ ] Mobile: scan, preview, detail, edit, hapus
- [ ] Integrasi, pengujian, dan laporan

## 🤝 Kontribusi

Tim memakai **Conventional Commits** dan bekerja di branch `feature/ui` dan
`feature/backend` yang digabung ke `main` lewat pull request.

## 📄 Lisensi

TODO: pilih lisensi (misalnya MIT) atau hapus bagian ini.
