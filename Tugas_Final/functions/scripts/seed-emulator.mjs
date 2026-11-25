import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore");

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

admin.initializeApp({ projectId: "demo-courtmate" });

const db = admin.firestore();
const auth = admin.auth();

const SEED_COURTS = [
  {
    id: "court-futsal-merdeka",
    name: "Arena Futsal Kampus Merdeka",
    placeId: "ChIJ_demo_futsal_merdeka",
    sportTypes: ["Futsal"],
    addressDisplay: "Jl. Telekomunikasi No. 12, Sukapura, Kec. Dayeuhkolot, Bandung",
    latitude: -6.9735,
    longitude: 107.6309,
    priceRules: { hourly: 120000 },
    facilities: ["Parkir", "Mushola", "Toilet", "Kantin", "Wi-Fi"],
    openingHours: { open: "07:00", close: "23:00", days: "Senin – Minggu" },
    ownerId: "admin-demo-1",
    hourlyPrice: 120000,
  },
  {
    id: "court-badminton-nusantara",
    name: "GOR Badminton Nusantara",
    placeId: "ChIJ_demo_badminton_nusantara",
    sportTypes: ["Badminton"],
    addressDisplay: "Jl. Bojongsoang Raya No. 45, Bandung",
    latitude: -6.9810,
    longitude: 107.6375,
    priceRules: { hourly: 65000 },
    facilities: ["Parkir", "Toilet", "Kantin", "Sewa Raket"],
    openingHours: { open: "06:00", close: "22:00", days: "Senin – Minggu" },
    ownerId: "admin-demo-2",
    hourlyPrice: 65000,
  },
  {
    id: "court-tenis-senayan",
    name: "Tenis Club Kampus",
    placeId: "ChIJ_demo_tenis_senayan",
    sportTypes: ["Tenis"],
    addressDisplay: "Jl. Buah Batu No. 118, Bandung",
    latitude: -6.9552,
    longitude: 107.6412,
    priceRules: { hourly: 150000 },
    facilities: ["Parkir", "Toilet", "Ruang Ganti", "Lampu Malam"],
    openingHours: { open: "06:00", close: "21:00", days: "Senin – Minggu" },
    ownerId: "admin-demo-3",
    hourlyPrice: 150000,
  },
];

async function seed() {
  const email = "anmul@kampus.ac.id";
  const password = "password123";
  let userRecord;

  try {
    userRecord = await auth.getUserByEmail(email);
  } catch {
    userRecord = await auth.createUser({
      uid: "mhs_anmul",
      email,
      password,
      displayName: "Anmul Mahasiswa",
    });
  }

  const now = Timestamp.now();

  await db.collection("users").doc(userRecord.uid).set({
    uid: userRecord.uid,
    name: "Anmul Mahasiswa",
    email,
    phone: "081234567890",
    role: "student",
    photoUrl: null,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  });

  const today = new Date();
  const baseDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const hours = [8, 9, 10, 11, 16, 17, 19, 20];

  let slotCount = 0;
  for (const court of SEED_COURTS) {
    await db.collection("courts").doc(court.id).set({
      name: court.name,
      placeId: court.placeId,
      sportTypes: court.sportTypes,
      addressDisplay: court.addressDisplay,
      latitude: court.latitude,
      longitude: court.longitude,
      priceRules: court.priceRules,
      facilities: court.facilities,
      openingHours: court.openingHours,
      ownerId: court.ownerId,
      verificationStatus: "verified",
      isActive: true,
      createdAt: now,
      updatedAt: now,
    });

    for (let dayOffset = 0; dayOffset <= 2; dayOffset++) {
      const d = new Date(baseDay.getTime() + dayOffset * 86_400_000);
      for (const hour of hours) {
        const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), hour, 0);
        const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), hour + 1, 0);
        const slotId = `${court.id}_${d.getFullYear()}${d.getMonth() + 1}${d.getDate()}_${hour}`;
        await db.collection("slots").doc(slotId).set({
          courtId: court.id,
          startAt: Timestamp.fromDate(start),
          endAt: Timestamp.fromDate(end),
          price: court.hourlyPrice,
          currency: "IDR",
          status: "available",
          bookingId: null,
          holdExpiresAt: null,
          updatedAt: now,
        });
        slotCount += 1;
      }
    }
  }

  console.log("Seed Firebase Emulator selesai!");
  console.log("Akun Login Demo :", `${email} / ${password}`);
  console.log("Lapangan Aktif  :", `${SEED_COURTS.length} lapangan terverifikasi (${slotCount} slot tersedia)`);
}

seed().catch((err) => {
  console.error("Gagal seed emulator:", err);
  process.exit(1);
});
