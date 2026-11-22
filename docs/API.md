# API Scanote

Kontrak antara aplikasi Flutter dan backend Go. Jika ada perubahan, perbarui file ini
terlebih dahulu dan beri tahu anggota lain.

- **Base URL:** `http://localhost:8080` (emulator Android: `http://10.0.2.2:8080`)
- **Format:** JSON (UTF-8), kecuali `/api/scan` yang memakai `multipart/form-data`
- **Autentikasi:** `Authorization: Bearer <token>` pada semua endpoint kecuali register
  dan login
- **Waktu:** string ISO 8601 / RFC 3339, zona Asia/Jakarta (contoh
  `2026-11-08T10:00:00+07:00`)

## Format Error

Semua error berbentuk:

```json
{ "error": "Pesan dalam bahasa Indonesia" }
```

| Status | Arti | Contoh pesan |
|---|---|---|
| 400 | Input tidak valid | "Judul wajib diisi" |
| 401 | Token tidak ada, salah, atau kedaluwarsa | "Sesi berakhir, silakan masuk kembali" |
| 404 | Data tidak ditemukan (atau bukan milik pengguna) | "Catatan tidak ditemukan" |
| 409 | Konflik | "Email sudah terdaftar" |
| 413 | Foto terlalu besar | "Ukuran foto maksimal 5 MB" |
| 415 | Format foto tidak didukung | "Format foto harus JPEG atau PNG" |
| 429 | Kuota AI habis | "Layanan AI sedang sibuk, coba lagi nanti" |
| 500 | Kesalahan server | "Terjadi kesalahan pada server" |
| 502/504 | Gemini gagal atau timeout | "Gagal membaca foto, coba lagi" |

## Objek

**User**

```json
{ "id": 1, "name": "Rani", "email": "rani@mail.com" }
```

**Note**

```json
{
  "id": 1,
  "title": "Catatan Basis Data",
  "content": "Normalisasi bertujuan mengurangi redundansi data...",
  "created_at": "2026-11-08T10:00:00+07:00"
}
```

## Endpoint

### Kesehatan

`GET /api/health` → `200` `{"status":"ok"}` (tanpa autentikasi)

### Register

`POST /api/auth/register`

Request:

```json
{ "name": "Rani", "email": "rani@mail.com", "password": "rahasia123" }
```

Validasi: `name` tidak kosong; `email` format valid; `password` minimal 8 karakter.

Respons `201`:

```json
{ "token": "eyJhbGciOi...", "user": { "id": 1, "name": "Rani", "email": "rani@mail.com" } }
```

Error: `400` (validasi), `409` (email sudah terdaftar).

### Login

`POST /api/auth/login`

Request: `{ "email": "rani@mail.com", "password": "rahasia123" }`

Respons `200`: sama seperti register. Error: `400`, `401` ("Email atau password salah").

### Scan foto

`POST /api/scan` (butuh token)

Request: `multipart/form-data` dengan field **`image`** (JPEG atau PNG, maksimal 5 MB).

Respons `200`:

```json
{ "title": "Catatan Basis Data", "content": "Normalisasi bertujuan mengurangi..." }
```

Aturan:
- Hasil **tidak disimpan** ke database; hanya untuk preview.
- Jika tidak ada teks terbaca: `200` dengan `{"title":"","content":""}`.
- AI diminta membaca apa adanya dan tidak mengarang isi.
- Foto tidak disimpan di server.

Error: `400` (field `image` tidak ada), `413`, `415`, `429`, `502`/`504`.

### Daftar catatan

`GET /api/notes?q=<kata>` (butuh token)

- `q` opsional; mencari pada `title` dan `content` (tidak peka huruf besar/kecil).
- Hanya catatan milik pengguna dari token.
- Urutan: terbaru dahulu (`created_at` menurun).

Respons `200`:

```json
{ "notes": [ { "id": 1, "title": "...", "content": "...", "created_at": "..." } ] }
```

Jika kosong: `{ "notes": [] }`.

### Buat catatan

`POST /api/notes` (butuh token)

Request: `{ "title": "Catatan Basis Data", "content": "Isi catatan..." }`

Validasi: `title` tidak kosong, maksimal 100 karakter; `content` tidak kosong.

Respons `201`: objek **Note**. Error: `400`.

### Ambil satu catatan

`GET /api/notes/{id}` (butuh token) → `200` objek **Note**; `404` jika tidak ada atau
bukan milik pengguna.

### Ubah catatan

`PUT /api/notes/{id}` (butuh token)

Request: `{ "title": "...", "content": "..." }` (validasi sama dengan buat).

Respons `200`: objek **Note** yang sudah diperbarui. Error: `400`, `404`.

### Hapus catatan

`DELETE /api/notes/{id}` (butuh token)

Respons `200`: `{ "message": "Catatan dihapus" }`. Error: `404`.

## Skema Database (SQLite)

```sql
CREATE TABLE users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notes_user ON notes(user_id);
```

## Konfigurasi Backend (`.env`)

```
PORT=8080
JWT_SECRET=ganti-dengan-string-acak-panjang
GEMINI_API_KEY=
DB_PATH=scanote.db
```

`.env` dan `*.db` tidak boleh di-commit. Gunakan `.env.example` tanpa nilai rahasia.

## Contoh Uji dengan curl

```bash
curl -X POST localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"rani@mail.com","password":"rahasia123"}'

curl localhost:8080/api/notes?q=normalisasi \
  -H "Authorization: Bearer <token>"

curl -X POST localhost:8080/api/scan \
  -H "Authorization: Bearer <token>" \
  -F "image=@catatan.jpg"
```
