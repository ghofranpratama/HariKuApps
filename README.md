# HariKu – Aplikasi Manajemen Tugas Harian

UTS Pemrograman Mobile (Kelas C) – Flutter (Material 3) & Dart.

> Manage tasks, set priorities, track progress, and stay organized every day.

Data tugas diambil dari **Todoist REST API v1** (`https://api.todoist.com/api/v1/tasks`)
memakai personal API token (Bearer).

## Menyiapkan token
1. Buka Todoist → Settings → Integrations → Developer → salin **API token**.
2. Salin `env.example.json` menjadi `env.json`, isi tokennya.
3. Tambahkan `env.json` ke `.gitignore` (**jangan** di-commit ke repo publik).

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
flutter test
```

Izin internet di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Fitur
- GET tugas dari API dengan `FutureBuilder` (Loading / Success / Error)
- Tambah, ubah, hapus, dan centang selesai — tersinkron ke Todoist
- Kelompok tanggal (Terlambat, Hari Ini, Besok, Mendatang, Tanpa Tanggal)
- Cari tugas real-time + filter chip
- Ringkasan progres dan sorotan prioritas
- Mode Terang / Gelap

## Pemetaan data (Todoist → TaskModel)
| JSON | Atribut Dart | Aturan |
|---|---|---|
| `id` | `id` | String |
| `content` | `title` | – |
| `checked` | `completed` | – |
| `priority` | `priority` | 4,3 → Penting · 2 → Normal · 1 → Bisa Nanti |
| `due.date` / `due.datetime` | `dueDay`, `dueTime` | dibandingkan dengan hari ini → kelompok tanggal |

## Struktur
```
lib/
├── models/task_model.dart
├── services/api_service.dart
├── pages/home_page.dart
├── widgets/ (task_tile.dart, task_dialog.dart)
├── theme/app_theme.dart
├── utils/id_date.dart
└── main.dart
```
