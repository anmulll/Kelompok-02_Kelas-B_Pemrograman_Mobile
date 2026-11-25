# Integration Tests (`test/integration/`)

Folder ini disiapkan untuk skenario pengujian terintegrasi sesuai dokumen `CM-ARCH-DB-001` Bab 14:

1. **Concurrency Hold Test (`AC-04`)**: Dua request `createBooking` bersamaan ke `slotId` yang sama menggunakan Firebase Emulator Suite — memastikan hanya satu hold yang berhasil.
2. **DOKU Sandbox Webhook Flow (`AC-06` s.d. `AC-09`)**: Menguji `createDokuPayment` dan pengiriman payload ter-signature ke `dokuWebhook` (valid, signature salah, dan replay idempotent).
3. **Firestore Security Rules Test (`AC-10`)**: Memastikan mahasiswa hanya dapat membaca `bookings` miliknya dan tidak dapat mengubah `role` atau `slots` secara langsung dari klien.
