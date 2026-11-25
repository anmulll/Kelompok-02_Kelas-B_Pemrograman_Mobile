# Ringkasan Dokumen Spesifikasi CourtMate

Dokumen ini merangkum tiga dokumen acuan tim **Kelompok 02 (Kelas B — Pemrograman Mobile)**:
- **PRD (`CM-PRD-001`)** — Product Requirements Document
- **SRS (`CM-SRS-001`)** — Software Requirements Specification
- **Architecture & DB (`CM-ARCH-DB-001`)** — System Architecture & Database Design

## 1. Prinsip Keamanan & Arsitektur Wajib
1. **Trusted Backend Boundary**: Flutter hanya menangani UI & state (`Provider`). Operasi sensitif (`createBooking`, `createDokuPayment`, `dokuWebhook`, `cancelBooking`, `manageCourt`, `cleanupExpiredHolds`) wajib dijalankan di **Firebase Cloud Functions**.
2. **Sumber Kebenaran Harga & Ketersediaan**: Google Maps/Places hanya dipakai untuk *discovery* lokasi. Ketersediaan slot dan harga berasal dari koleksi `courts` dan `slots` di Cloud Firestore (`BR-006`, `BR-011`).
3. **Anti Double-Booking Atomik**: Pemilihan slot mengunci dokumen `slots/{slotId}` menjadi `held` dengan `holdExpiresAt` (baseline 10 menit) di dalam transaksi Firestore (`FR-010`, `AC-04`).
4. **Konfirmasi Pembayaran Terverifikasi**: Kembalinya pengguna dari browser/webview DOKU Checkout **bukan** bukti lunas (`BR-008`). Status `confirmed` hanya ditetapkan oleh `dokuWebhook` setelah verifikasi HMAC-SHA256 signature & pencatatan idempoten di `payment_events` (`BR-007`, `BR-009`).
5. **Pengelolaan Secret**: `DOKU_CLIENT_ID` dan `DOKU_SECRET_KEY` disimpan di **Firebase Secret Manager** (atau `functions/.secret.local` saat memakai emulator), sedangkan `MAPS_API_KEY` diletakkan di `android/local.properties` (tidak pernah di-commit ke Git).

## 2. Koleksi Cloud Firestore
| Koleksi | Dokumen ID | Akses Klien | Catatan |
|---|---|---|---|
| `users` | `uid` | Baca sendiri; buat hanya `role: student` | Role `admin` hanya ditetapkan dari backend |
| `courts` | `courtId` | Baca lapangan `verified` & `isActive` | Tulis melalui Cloud Function `manageCourt` |
| `slots` | `slotId` | Baca terautentikasi | Mutasi `available`/`held`/`booked` khusus backend |
| `bookings` | `bookingId` | Baca milik sendiri (`userId == uid`) | Dibuat & diperbarui oleh Cloud Functions |
| `payments` | `paymentId` | Baca milik sendiri | Berisi `providerOrderId` & `checkoutUrl` DOKU |
| `invitations` | `invitationId` | Pengirim & penerima | Undangan teman bermain terkait booking |
| `notifications` | `notificationId` | Baca & tandai `isRead` milik sendiri | Notifikasi dalam aplikasi |
| `payment_events` | `eventId` | Ditolak penuh (`false`) | Audit & deduplikasi webhook DOKU di backend |
