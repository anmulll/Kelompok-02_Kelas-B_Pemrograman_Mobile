# CourtMate — Tugas Akhir Pemrograman Mobile (Kelompok 02 Kelas B)

**CourtMate** adalah aplikasi mobile Android berbasis **Flutter** untuk membantu mahasiswa menemukan fasilitas olahraga, memeriksa jadwal slot lapangan yang terverifikasi, melakukan reservasi anti-*double-booking*, membayar melalui **DOKU Checkout (Sandbox)**, serta mengundang teman bermain bersama.

---

## Teknologi Utama
- **Mobile Client**: Flutter & Dart, State Management **Provider**
- **Maps & Location**: Google Maps SDK for Android, Places API, `geolocator`
- **Auth & Database**: Firebase Authentication & Cloud Firestore
- **Trusted Backend**: Firebase Cloud Functions (TypeScript v2)
- **Payment Gateway**: DOKU Checkout Sandbox + Webhook HMAC-SHA256

---

## Struktur Direktori Proyek

```text
Tugas_Final/
├── android/                  # Konfigurasi Android (MAPS_API_KEY via local.properties)
├── docs/                     # Ringkasan PRD, SRS, & Arsitektur Database CourtMate
├── functions/                # Backend tepercaya Firebase Cloud Functions (TypeScript)
│   └── src/
│       ├── booking/          # create-booking.ts (atomic slot hold) & cancel-booking.ts
│       ├── doku/             # create-payment.ts, signature.ts, & webhook.ts (idempotent)
│       ├── courts/           # manageCourt.ts (khusus admin/pengelola)
│       └── scheduler/        # cleanup-expired-holds.ts (pelepasan hold otomatis)
├── lib/
│   ├── core/                 # Konstanta koleksi, tema Material 3, routing aplikasi
│   ├── models/               # Model data Firestore (User, Court, Slot, Booking, Payment, dll.)
│   ├── providers/            # State management Provider (Auth, Court, Booking)
│   ├── services/             # Wrapper Firebase Auth, Firestore, Booking, Payment, & Geolocator
│   ├── features/             # Modul fitur terpisah agar tim 3 orang minim konflik Git
│   │   ├── auth/             # Login & Registrasi Mahasiswa
│   │   ├── explore/          # Pencarian, filter olahraga, & integrasi Google Maps/Places
│   │   ├── courts/           # Detail lapangan & daftar slot per tanggal
│   │   ├── booking/          # Pemilihan slot & konfirmasi hold
│   │   ├── payment/          # Pemantauan status pembayaran DOKU
│   │   ├── invitation/       # Undangan teman bermain
│   │   ├── history/          # Riwayat & pengajuan pembatalan booking
│   │   ├── profile/          # Profil pengguna & sesi
│   │   └── admin/            # Dashboard pengelola lapangan, slot, & reservasi
│   └── widgets/              # Komponen UI bersama (StatusBadge, dll.)
├── test/
│   ├── unit/                 # Unit test aturan bisnis & model
│   ├── widget/               # Widget test komponen UI & navigasi
│   └── integration/          # Skenario integrasi emulator & webhook
├── firebase.json             # Konfigurasi Firebase & Emulator Suite
├── firestore.rules           # Aturan keamanan Firestore (default deny)
└── firestore.indexes.json    # Indeks komposit query Firestore
```

---

## Panduan Setup untuk Anggota Tim (Setelah `git clone` / `git pull`)

### 1. Persiapan Proyek Flutter
```bash
cd Tugas_Final
flutter pub get
```

### 2. Konfigurasi Google Maps API Key (Tanpa Commit ke Git)
Tambahkan baris berikut ke dalam file `Tugas_Final/android/local.properties`:
```properties
MAPS_API_KEY=ISI_GOOGLE_MAPS_ANDROID_API_KEY_DISINI
```

### 3. Konfigurasi Firebase (FlutterFire)
Jika proyek Firebase tim sudah dibuat di Firebase Console:
```bash
flutterfire configure
```
*(Catatan: Meskipun `flutterfire configure` belum dijalankan di laptop anggota tim, aplikasi sudah dilengkapi `FirebaseBootstrap` sehingga UI tetap bisa dijalankan untuk pengembangan tampilan tanpa crash.)*

### 4. Persiapan Cloud Functions (Backend TypeScript)
```bash
cd functions
npm install
npm run build
```
Untuk menjalankan emulator lokal, salin format variabel dari `.env.example` ke `functions/.secret.local`, lalu jalankan:
```bash
firebase emulators:start
```

### 5. Menjalankan Analisis Kode & Pengujian
```bash
flutter analyze
flutter test
```

---

## Rekomendasi Pembagian Tugas Tim (3 Orang) & Alur Git

Agar tidak terjadi konflik (*merge conflict*), setiap anggota mengerjakan folder fitur masing-masing pada branch terpisah:

| Anggota | Fokus Modul Fitur | Folder Kerja Utama |
|---|---|---|
| **Yusuf** | Auth, Profil, Otorisasi Role & Admin Management | `lib/features/auth/`, `lib/features/profile/`, `lib/features/admin/`, `functions/src/courts/`, `firestore.rules` |
| **Caca** | Discovery, Google Maps/Places, Detail Lapangan & Filter | `lib/features/explore/`, `lib/features/courts/`, `lib/providers/court_provider.dart`, `lib/services/location_service.dart` |
| **Anmul** | Booking Hold, DOKU Checkout, Webhook, Riwayat, Pembatalan & Undangan | `lib/features/booking/`, `lib/features/payment/`, `lib/features/history/`, `lib/features/invitation/`, `functions/src/booking/`, `functions/src/doku/`, `functions/src/scheduler/` |

### Konvensi Branch GitHub
1. Selalu ambil perubahan terbaru dari `main`:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Buat branch per fitur:
   ```bash
   git checkout -b feat/explore-maps
   ```
3. Pastikan `flutter analyze` dan `flutter test` lulus sebelum membuka **Pull Request** ke `main`.
