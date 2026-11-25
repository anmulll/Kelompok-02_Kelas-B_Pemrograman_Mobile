import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

/**
 * CM-ARCH-DB-001 Bab 5 (`manageCourt`) & FR-020 / FR-021:
 * Pengelolaan lapangan dan slot oleh admin/pengelola yang berwenang.
 */
export const manageCourt = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const userSnap = await db.collection("users").doc(uid).get();
  const isAdmin =
    request.auth.token.role === "admin" || userSnap.data()?.role === "admin";

  if (!isAdmin) {
    throw new HttpsError("permission-denied", "Hanya admin/pengelola yang diizinkan.");
  }

  const action = String(request.data?.action ?? "");
  const nowTs = Timestamp.now();

  if (action === "upsertCourt") {
    const courtId = request.data?.courtId as string | undefined;
    const courtRef = courtId
      ? db.collection("courts").doc(courtId)
      : db.collection("courts").doc();

    if (courtId) {
      const existing = await courtRef.get();
      if (existing.exists && existing.data()?.ownerId !== uid) {
        throw new HttpsError("permission-denied", "Bukan pemilik lapangan ini.");
      }
    }

    await courtRef.set(
      {
        name: String(request.data?.name ?? ""),
        placeId: request.data?.placeId ?? null,
        sportTypes: Array.isArray(request.data?.sportTypes) ? request.data.sportTypes : [],
        addressDisplay: String(request.data?.addressDisplay ?? ""),
        latitude: Number(request.data?.latitude ?? 0),
        longitude: Number(request.data?.longitude ?? 0),
        priceRules: request.data?.priceRules ?? {},
        facilities: Array.isArray(request.data?.facilities) ? request.data.facilities : [],
        openingHours: request.data?.openingHours ?? {},
        ownerId: uid,
        verificationStatus: request.data?.verificationStatus ?? "verified",
        isActive: Boolean(request.data?.isActive ?? true),
        updatedAt: nowTs,
        ...(courtId ? {} : { createdAt: nowTs }),
      },
      { merge: true }
    );

    return { courtId: courtRef.id };
  }

  throw new HttpsError("invalid-argument", `Action '${action}' belum didukung.`);
});
