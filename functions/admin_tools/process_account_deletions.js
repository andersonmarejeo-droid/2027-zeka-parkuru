"use strict";

const fs = require("fs");
const path = require("path");
const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const EXPECTED_PROJECT_ID = "zeka-parkuru-eu-2026";
const REQUESTS = "account_deletion_requests_v1";

function parseArgs(argv) {
  const out = {
    execute: false,
    uid: null,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || null,
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--execute") out.execute = true;
    else if (a === "--dry-run") out.execute = false;
    else if (a === "--uid") out.uid = argv[++i] || null;
    else if (a === "--service-account") out.serviceAccount = argv[++i] || null;
    else if (a === "--help" || a === "-h") out.help = true;
    else throw new Error(`Bilinmeyen argüman: ${a}`);
  }
  return out;
}

function help() {
  console.log(`
Zekâ Parkuru hesap/veri silme yönetici aracı

Varsayılan mod DRY-RUN'dır; veri değiştirmez.

Örnek:
  node process_account_deletions.js --service-account "C:\\keys\\admin.json"
  node process_account_deletions.js --service-account "C:\\keys\\admin.json" --execute
  node process_account_deletions.js --service-account "C:\\keys\\admin.json" --uid FIREBASE_UID --execute
`);
}

function loadServiceAccount(filePath) {
  if (!filePath) throw new Error("Service account JSON yolu verilmedi.");
  const absolute = path.resolve(filePath);
  if (!fs.existsSync(absolute)) throw new Error(`Dosya bulunamadı: ${absolute}`);
  const data = JSON.parse(fs.readFileSync(absolute, "utf8"));
  if (data.project_id !== EXPECTED_PROJECT_ID) {
    throw new Error(`YANLIŞ PROJE: ${data.project_id || "(yok)"}; beklenen ${EXPECTED_PROJECT_ID}`);
  }
  if (!data.client_email || !data.private_key) {
    throw new Error("Geçersiz service account JSON.");
  }
  return data;
}

async function deleteSnapshots(db, snapshot, execute, label, stats) {
  const docs = snapshot.docs || [];
  if (!docs.length) return;
  stats.matched += docs.length;
  console.log(`  ${label}: ${docs.length} belge ${execute ? "silinecek" : "bulundu"}`);
  if (!execute) return;
  for (let offset = 0; offset < docs.length; offset += 400) {
    const batch = db.batch();
    for (const doc of docs.slice(offset, offset + 400)) batch.delete(doc.ref);
    await batch.commit();
    stats.deleted += Math.min(400, docs.length - offset);
  }
}

async function deleteWhere(db, collection, field, op, value, execute, stats) {
  const snap = await db.collection(collection).where(field, op, value).get();
  await deleteSnapshots(db, snap, execute, `${collection}: ${field} ${op} ${value}`, stats);
}

async function deleteDocIfExists(ref, execute, label, stats) {
  const snap = await ref.get();
  if (!snap.exists) {
    console.log(`  ${label}: yok`);
    return;
  }
  stats.matched++;
  console.log(`  ${label}: ${execute ? "silinecek" : "bulundu"}`);
  if (execute) {
    await ref.delete();
    stats.deleted++;
  }
}

async function deleteArenaDataForUid(db, uid, execute, stats) {
  const events = await db.collection("arena_events_v1")
    .where("participantIds", "array-contains", uid).get();

  for (const eventDoc of events.docs) {
    const data = eventDoc.data() || {};
    if (data.ownerUid === uid) {
      await deleteWhere(db, "arena_attempts_v1", "eventId", "==", eventDoc.id, execute, stats);
      stats.matched++;
      console.log(`  arena_events_v1/${eventDoc.id}: owner etkinliği ${execute ? "silinecek" : "bulundu"}`);
      if (execute) {
        await eventDoc.ref.delete();
        stats.deleted++;
      }
    } else {
      stats.updated++;
      console.log(`  arena_events_v1/${eventDoc.id}: participantIds içinden UID ${execute ? "çıkarılacak" : "çıkarılabilir"}`);
      if (execute) {
        await eventDoc.ref.update({
          participantIds: FieldValue.arrayRemove(uid),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
  }

  const groups = await db.collection("arena_groups_v1")
    .where("memberIds", "array-contains", uid).get();

  for (const groupDoc of groups.docs) {
    const data = groupDoc.data() || {};
    if (data.ownerUid === uid) {
      await deleteWhere(db, "arena_attempts_v1", "groupId", "==", groupDoc.id, execute, stats);
      await deleteWhere(db, "arena_events_v1", "groupId", "==", groupDoc.id, execute, stats);

      if (data.joinCode) {
        await deleteDocIfExists(
          db.collection("arena_invites_v1").doc(data.joinCode),
          execute,
          `arena_invites_v1/${data.joinCode}`,
          stats
        );
      }

      stats.matched++;
      console.log(`  arena_groups_v1/${groupDoc.id}: owner grubu ${execute ? "silinecek" : "bulundu"}`);
      if (execute) {
        await groupDoc.ref.delete();
        stats.deleted++;
      }
    } else {
      stats.updated++;
      console.log(`  arena_groups_v1/${groupDoc.id}: memberIds içinden UID ${execute ? "çıkarılacak" : "çıkarılabilir"}`);
      if (execute) {
        await groupDoc.ref.update({
          memberIds: FieldValue.arrayRemove(uid),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
  }
}

async function processRequest(db, auth, requestDoc, execute) {
  const uid = requestDoc.id;
  const request = requestDoc.data() || {};
  const stats = { matched: 0, deleted: 0, updated: 0 };

  console.log("\n============================================================");
  console.log(`UID: ${uid}`);
  console.log(`Mod: ${execute ? "EXECUTE - GERÇEK SİLME" : "DRY-RUN - DEĞİŞİKLİK YOK"}`);

  if (!uid || request.uid !== uid) {
    console.error("  GEÇERSİZ TALEP: belge id ile request.uid eşleşmiyor.");
    return { ok: false, uid, reason: "uid-mismatch", stats };
  }

  await deleteDocIfExists(db.collection("leaderboard_public").doc(uid), execute, `leaderboard_public/${uid}`, stats);
  await deleteDocIfExists(db.collection("leaderboard_v3_public").doc(uid), execute, `leaderboard_v3_public/${uid}`, stats);
  await deleteDocIfExists(db.collection("player_devices_v1").doc(uid), execute, `player_devices_v1/${uid}`, stats);

  await deleteWhere(db, "challenges_v1", "participantIds", "array-contains", uid, execute, stats);
  await deleteWhere(db, "challenge_progress_v1", "playerUid", "==", uid, execute, stats);
  await deleteWhere(db, "friendships_v1", "members", "array-contains", uid, execute, stats);
  await deleteWhere(db, "arena_attempts_v1", "uid", "==", uid, execute, stats);
  await deleteArenaDataForUid(db, uid, execute, stats);

  if (!execute) {
    console.log("  Firebase Auth: DRY-RUN, silinmedi");
    console.log("  Talep belgesi: DRY-RUN, korunuyor");
    return { ok: true, uid, dryRun: true, stats };
  }

  try {
    await auth.deleteUser(uid);
    console.log("  Firebase Auth: kullanıcı silindi");
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      console.log("  Firebase Auth: kullanıcı zaten yok");
    } else {
      throw error;
    }
  }

  await requestDoc.ref.delete();
  console.log("  Talep belgesi: işlem tamamlandıktan sonra kaldırıldı");
  return { ok: true, uid, dryRun: false, stats };
}

async function main() {
  const args = parseArgs(process.argv);
  if (args.help) return help();

  const serviceAccount = loadServiceAccount(args.serviceAccount);
  if (!getApps().length) {
    initializeApp({ credential: cert(serviceAccount), projectId: EXPECTED_PROJECT_ID });
  }

  const db = getFirestore();
  const auth = getAuth();

  console.log("Zekâ Parkuru - Hesap/Veri Silme Yönetici Aracı");
  console.log(`Proje: ${EXPECTED_PROJECT_ID}`);
  console.log(`Mod: ${args.execute ? "EXECUTE - GERÇEK SİLME" : "DRY-RUN - DEĞİŞİKLİK YOK"}`);

  let docs;
  if (args.uid) {
    const doc = await db.collection(REQUESTS).doc(args.uid).get();
    if (!doc.exists) {
      console.log(`Bekleyen talep bulunamadı: ${args.uid}`);
      return;
    }
    docs = [doc];
  } else {
    const snap = await db.collection(REQUESTS).get();
    docs = snap.docs || [];
  }

  console.log(`Bekleyen talep sayısı: ${docs.length}`);
  if (!docs.length) return;

  let failed = 0;
  for (const doc of docs) {
    try {
      const result = await processRequest(db, auth, doc, args.execute);
      if (!result.ok) failed++;
    } catch (error) {
      failed++;
      console.error(`HATA - UID ${doc.id}:`, error && error.stack ? error.stack : error);
      console.error("Talep belgesi korunuyor; daha sonra yeniden denenebilir.");
    }
  }

  console.log("\n============================================================");
  console.log(`Bitti. Başarılı: ${docs.length - failed}, Hatalı/Atlanan: ${failed}`);
  if (!args.execute) console.log("DRY-RUN tamamlandı. Hiçbir veri değiştirilmedi.");
  if (failed) process.exitCode = 2;
}

main().catch((error) => {
  console.error("KRİTİK HATA:", error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
