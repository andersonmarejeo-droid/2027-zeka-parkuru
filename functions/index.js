const { setGlobalOptions } = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = getFirestore();

async function claimEvent(eventId) {
  if (!eventId) return true;
  try {
    await db.collection("notification_events_v1").doc(eventId).create({
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (error) {
    if (error && (error.code === 6 || error.code === "already-exists")) {
      return false;
    }
    throw error;
  }
}

async function sendToUid(uid, challengeId, title, body) {
  if (!uid) return;
  const deviceRef = db.collection("player_devices_v1").doc(uid);
  const device = await deviceRef.get();
  const token = device.data() && device.data().token;
  if (!token) return;

  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: {
        type: "challenge",
        challengeId,
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
        },
      },
    });
  } catch (error) {
    const code = error && error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      await deviceRef.delete();
      return;
    }
    throw error;
  }
}

async function sendArenaToUid(uid, groupId, joinCode, title, body) {
  if (!uid || !groupId || !joinCode) return;
  const deviceRef = db.collection("player_devices_v1").doc(uid);
  const device = await deviceRef.get();
  const token = device.data() && device.data().token;
  if (!token) return;

  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: {
        type: "arena",
        groupId,
        joinCode,
      },
      android: {
        priority: "high",
        notification: { sound: "default" },
      },
    });
  } catch (error) {
    const code = error && error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      await deviceRef.delete();
      return;
    }
    throw error;
  }
}

exports.challengeCreated = onDocumentCreated(
  "challenges_v1/{challengeId}",
  async (event) => {
    if (!(await claimEvent(event.id))) return;
    const challenge = event.data && event.data.data();
    if (!challenge || !challenge.targetUid) return;
    await sendToUid(
      challenge.targetUid,
      event.params.challengeId,
      "Yeni meydan okuma! ⚔️",
      `${challenge.challengerName || "Bir oyuncu"} seni refleks düellosuna çağırdı.`,
    );
  },
);

exports.challengeUpdated = onDocumentUpdated(
  "challenges_v1/{challengeId}",
  async (event) => {
    if (!(await claimEvent(event.id))) return;
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!before || !after) return;

    const challengeId = event.params.challengeId;
    if (before.status === "pending" && after.status === "accepted") {
      await sendToUid(
        after.challengerUid,
        challengeId,
        "Davet kabul edildi! ✅",
        `${after.opponentName || "Rakibin"} düelloya katıldı. Şimdi skorunu belirle.`,
      );
      return;
    }

    if (before.status !== "completed" && after.status === "completed") {
      await Promise.all([
        sendToUid(
          after.challengerUid,
          challengeId,
          "Düello sonucu hazır 🏆",
          "İki skor da tamamlandı. Sonucu görmek için dokun.",
        ),
        sendToUid(
          after.opponentUid,
          challengeId,
          "Düello sonucu hazır 🏆",
          "İki skor da tamamlandı. Sonucu görmek için dokun.",
        ),
      ]);
      return;
    }

    const challengerJustPlayed =
      before.challengerScore == null && after.challengerScore != null;
    const opponentJustPlayed =
      before.opponentScore == null && after.opponentScore != null;
    if (after.status === "accepted" && challengerJustPlayed) {
      await sendToUid(
        after.opponentUid,
        challengeId,
        "Rakibin skorunu yaptı 🎯",
        "Sıra sende. Aynı seriyi oyna ve skorunu karşılaştır.",
      );
    } else if (after.status === "accepted" && opponentJustPlayed) {
      await sendToUid(
        after.challengerUid,
        challengeId,
        "Rakibin skorunu yaptı 🎯",
        "Sıra sende. Aynı seriyi oyna ve skorunu karşılaştır.",
      );
    }
  },
);

exports.arenaGroupUpdated = onDocumentUpdated(
  "arena_groups_v1/{groupId}",
  async (event) => {
    if (!(await claimEvent(event.id))) return;
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!before || !after) return;
    const oldMembers = new Set(before.memberIds || []);
    const joined = (after.memberIds || []).filter((uid) => !oldMembers.has(uid));
    if (!joined.length || joined.includes(after.ownerUid)) return;
    await sendArenaToUid(
      after.ownerUid,
      event.params.groupId,
      after.joinCode,
      "Grubuna yeni oyuncu katıldı 👋",
      `${after.name || "Zekâ Grubu"} artık ${after.memberIds.length}/30 kişi.`,
    );
  },
);

exports.arenaEventCreated = onDocumentCreated(
  "arena_events_v1/{eventId}",
  async (event) => {
    if (!(await claimEvent(event.id))) return;
    const competition = event.data && event.data.data();
    if (!competition) return;
    const group = await db.collection("arena_groups_v1")
      .doc(competition.groupId).get();
    const groupData = group.data();
    if (!groupData || !groupData.joinCode) return;
    const recipients = (competition.participantIds || [])
      .filter((uid) => uid && uid !== competition.ownerUid);
    await Promise.all(recipients.map((uid) => sendArenaToUid(
      uid,
      competition.groupId,
      groupData.joinCode,
      "Yeni grup yarışı başladı! 🏟️",
      `${competition.title || "Zekâ Yarışı"}: ${competition.gameIds.length} oyun seni bekliyor.`,
    )));
  },
);

exports.arenaEventUpdated = onDocumentUpdated(
  "arena_events_v1/{eventId}",
  async (event) => {
    if (!(await claimEvent(event.id))) return;
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!before || !after || before.status === "completed" || after.status !== "completed") {
      return;
    }
    const group = await db.collection("arena_groups_v1")
      .doc(after.groupId).get();
    const groupData = group.data();
    if (!groupData || !groupData.joinCode) return;
    await Promise.all((after.participantIds || []).map((uid) => sendArenaToUid(
      uid,
      after.groupId,
      groupData.joinCode,
      "Grup yarışı sonucu hazır 🏆",
      `${after.title || "Zekâ Yarışı"} sıralaması kesinleşti.`,
    )));
  },
);


async function deleteSnapshots(snapshot) {
  const docs = snapshot.docs || [];
  for (let offset = 0; offset < docs.length; offset += 400) {
    const batch = db.batch();
    for (const doc of docs.slice(offset, offset + 400)) batch.delete(doc.ref);
    await batch.commit();
  }
}

async function deleteWhere(collectionName, field, op, value) {
  const snapshot = await db.collection(collectionName).where(field, op, value).get();
  await deleteSnapshots(snapshot);
}

async function deleteArenaDataForUid(uid) {
  const eventSnapshot = await db.collection("arena_events_v1")
    .where("participantIds", "array-contains", uid).get();
  for (const eventDoc of eventSnapshot.docs) {
    const data = eventDoc.data() || {};
    if (data.ownerUid === uid) {
      await deleteWhere("arena_attempts_v1", "eventId", "==", eventDoc.id);
      await eventDoc.ref.delete();
    } else {
      await eventDoc.ref.update({
        participantIds: FieldValue.arrayRemove(uid),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  const groupSnapshot = await db.collection("arena_groups_v1")
    .where("memberIds", "array-contains", uid).get();
  for (const groupDoc of groupSnapshot.docs) {
    const data = groupDoc.data() || {};
    if (data.ownerUid === uid) {
      await deleteWhere("arena_attempts_v1", "groupId", "==", groupDoc.id);
      await deleteWhere("arena_events_v1", "groupId", "==", groupDoc.id);
      if (data.joinCode) {
        await db.collection("arena_invites_v1").doc(data.joinCode).delete();
      }
      await groupDoc.ref.delete();
    } else {
      await groupDoc.ref.update({
        memberIds: FieldValue.arrayRemove(uid),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }
}

exports.accountDeletionRequested = onDocumentCreated(
  {
    document: "account_deletion_requests_v1/{uid}",
    retry: true,
  },
  async (event) => {
    const uid = event.params.uid;
    const request = event.data && event.data.data();

    if (!uid || !request || request.uid !== uid) {
      console.error("Invalid account deletion request.", {
        uid,
        requestUid: request && request.uid,
      });
      return;
    }

    await Promise.all([
      db.collection("leaderboard_public").doc(uid).delete(),
      db.collection("leaderboard_v3_public").doc(uid).delete(),
      db.collection("player_devices_v1").doc(uid).delete(),
      deleteWhere("challenges_v1", "participantIds", "array-contains", uid),
      deleteWhere("challenge_progress_v1", "playerUid", "==", uid),
      deleteWhere("friendships_v1", "members", "array-contains", uid),
      deleteWhere("arena_attempts_v1", "uid", "==", uid),
    ]);

    await deleteArenaDataForUid(uid);

    await getAuth().deleteUser(uid).catch((error) => {
      if (error && error.code === "auth/user-not-found") {
        return;
      }
      throw error;
    });

    await event.data.ref.delete();

    console.log("Account deletion completed for uid:", uid);
  },
);
