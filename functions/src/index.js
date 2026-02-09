const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const twilio = require("twilio");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const CLUBSPOT_BASE_URL = "https://api.theclubspot.com/api/v1";

async function clubspotRequest(path, {apiKey, method = "GET", body} = {}) {
  if (!apiKey) {
    throw new Error("Missing Clubspot API key (CLUBSPOT_API_KEY)");
  }

  const url = `${CLUBSPOT_BASE_URL}${path}`;
  let attempt = 0;

  while (attempt < 4) {
    attempt += 1;
    try {
      const response = await fetch(url, {
        method,
        headers: {
          "api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: body ? JSON.stringify(body) : undefined,
      });

      if (response.status === 429) {
        const retryAfter = Number.parseInt(response.headers.get("retry-after") || "", 10);
        const waitMs = Number.isFinite(retryAfter) ? retryAfter * 1000 : attempt * 2000;
        logger.warn("Clubspot rate limit reached; retrying", {attempt, waitMs});
        await new Promise((resolve) => setTimeout(resolve, waitMs));
        continue;
      }

      if (response.status === 401 || response.status === 403) {
        throw new Error("Invalid Clubspot API key or unauthorized request");
      }

      if (response.status >= 500 && response.status <= 599) {
        if (attempt < 4) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 2000));
          continue;
        }
        throw new Error(`Clubspot API downtime (${response.status})`);
      }

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`Clubspot API error ${response.status}: ${text}`);
      }

      return response.json();
    } catch (error) {
      if (attempt >= 4) {
        throw error;
      }
      await new Promise((resolve) => setTimeout(resolve, attempt * 2000));
    }
  }

  throw new Error("Clubspot request failed after retries");
}

async function fetchMembers(clubId, {apiKey, primaryOnly = false, skip = 0} = {}) {
  const members = [];
  let hasMore = true;
  let currentSkip = skip;

  while (hasMore) {
    const payload = await clubspotRequest(
      `/members?club_id=${encodeURIComponent(clubId)}&skip=${currentSkip}&primary_only=${primaryOnly}`,
      {apiKey},
    );

    const rows = payload.members || payload.data || [];
    members.push(...rows);
    hasMore = payload.has_more === true && rows.length > 0;
    currentSkip += rows.length;
  }

  return members;
}

function mapClubspotMember(member, existing = {}) {
  const role = existing.role || "member";
  return {
    id: String(member.id || member._id || member.membership_number || ""),
    firstName: String(member.first_name || ""),
    lastName: String(member.last_name || ""),
    email: String(member.email || ""),
    mobileNumber: String(member.mobile || member.mobile_phone || ""),
    memberNumber: String(member.membership_number || member.member_number || ""),
    membershipStatus: String(member.membership_status || ""),
    membershipCategory: String(member.membership_category || ""),
    memberTags: Array.isArray(member.tags) ? member.tags.map((t) => String(t)) : [],
    clubspotId: String(member.id || member._id || ""),
    role,
    lastSynced: admin.firestore.FieldValue.serverTimestamp(),
    profilePhotoUrl: existing.profilePhotoUrl || null,
    emergencyContact: existing.emergencyContact || {name: "Unknown", phone: ""},
  };
}

function shallowComparable(memberDoc) {
  const copy = {...memberDoc};
  delete copy.lastSynced;
  return JSON.stringify(copy);
}

async function syncMembersToFirestore({clubId, apiKey}) {
  const startedAt = new Date();
  let newCount = 0;
  let updatedCount = 0;
  let unchangedCount = 0;
  const errors = [];

  const members = await fetchMembers(clubId, {apiKey});
  for (const member of members) {
    try {
      const docId = String(member.id || member._id || member.membership_number || "");
      if (!docId) {
        errors.push(`Skipping member with missing ID (${member.email || "unknown"})`);
        continue;
      }

      const ref = db.collection("members").doc(docId);
      const snap = await ref.get();
      const existing = snap.exists ? snap.data() : {};
      const mapped = mapClubspotMember(member, existing);

      const unchanged = snap.exists && shallowComparable(existing) === shallowComparable(mapped);
      if (unchanged) {
        unchangedCount += 1;
        await ref.set(
          {lastSynced: admin.firestore.FieldValue.serverTimestamp()},
          {merge: true},
        );
      } else {
        await ref.set(mapped, {merge: true});
        if (snap.exists) {
          updatedCount += 1;
        } else {
          newCount += 1;
        }
      }
    } catch (error) {
      errors.push(`Member sync failed (${member.id || member.email || "unknown"}): ${error.message || error}`);
    }
  }

  const result = {
    clubId,
    newCount,
    updatedCount,
    unchangedCount,
    errors,
    startedAt: startedAt.toISOString(),
    finishedAt: new Date().toISOString(),
  };

  await db.collection("auditLogs").add({
    userId: "system",
    action: "clubspot_member_sync",
    entityType: "member",
    entityId: clubId,
    details: result,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection("memberSyncLogs").add({
    ...result,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
}

async function createMemberPortalSession({apiKey, membershipNumber, initialView = "home"}) {
  const payload = await clubspotRequest("/member-portal/sessions", {
    apiKey,
    method: "POST",
    body: {
      membership_number: membershipNumber,
      initial_view: initialView,
    },
  });

  return payload.session_url || payload.url || "";
}

function requireAdmin(authHeader) {
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new Error("Missing Authorization Bearer token");
  }
  const token = authHeader.split("Bearer ")[1];
  return admin.auth().verifyIdToken(token);
}

async function isAdminUser(decodedToken) {
  if (decodedToken.admin === true) return true;
  const memberSnap = await db.collection("members").doc(decodedToken.uid).get();
  const role = memberSnap.data()?.role;
  return role === "admin";
}

function twilioClient() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  if (!accountSid || !authToken) {
    throw new Error("Missing Twilio configuration (TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN)");
  }
  return twilio(accountSid, authToken);
}

async function sendSmsInternal({to, message, eventId}) {
  const client = twilioClient();
  const from = process.env.TWILIO_FROM_NUMBER;
  if (!from) {
    throw new Error("Missing TWILIO_FROM_NUMBER configuration");
  }
  const sms = await client.messages.create({to, from, body: message});
  await db.collection("smsLogs").add({
    to,
    from,
    eventId: eventId || null,
    message,
    status: sms.status,
    sid: sms.sid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return sms;
}

async function sendPushInternal({token, message, title = "MPYC Raceday", data = {}}) {
  if (!token) return;
  await admin.messaging().send({
    token,
    notification: {title, body: message},
    data,
  });
}

exports.scheduledMemberSync = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Los_Angeles",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    const clubId = process.env.CLUBSPOT_CLUB_ID;
    const apiKey = process.env.CLUBSPOT_API_KEY;
    if (!clubId) {
      throw new Error("Missing CLUBSPOT_CLUB_ID environment config");
    }

    try {
      const result = await syncMembersToFirestore({clubId, apiKey});
      logger.info("scheduledMemberSync complete", result);
      return result;
    } catch (error) {
      const payload = {
        type: "member_sync_failure",
        message: `Scheduled member sync failed: ${error.message || error}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await db.collection("adminNotifications").add(payload);
      logger.error("scheduledMemberSync failed", {error: error.message || String(error)});
      throw error;
    }
  },
);

exports.manualMemberSync = onRequest({cors: true, timeoutSeconds: 540}, async (req, res) => {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const decodedToken = await requireAdmin(req.headers.authorization || "");
    if (!(await isAdminUser(decodedToken))) {
      res.status(403).json({error: "Admin privileges required"});
      return;
    }

    const clubId = req.body?.clubId || process.env.CLUBSPOT_CLUB_ID;
    const apiKey = process.env.CLUBSPOT_API_KEY;
    if (!clubId) {
      res.status(400).json({error: "Missing clubId or CLUBSPOT_CLUB_ID config"});
      return;
    }

    const result = await syncMembersToFirestore({clubId, apiKey});
    res.status(200).json(result);
  } catch (error) {
    logger.error("manualMemberSync failed", {error: error.message || String(error)});
    res.status(500).json({error: error.message || String(error)});
  }
});

exports.sendSms = onCall(async (request) => {
  const {to, message, eventId} = request.data || {};
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  if (!to || !message) {
    throw new HttpsError("invalid-argument", "to and message are required");
  }

  try {
    const result = await sendSmsInternal({to, message, eventId});
    return {sid: result.sid, status: result.status};
  } catch (error) {
    throw new HttpsError("internal", error.message || "SMS send failed");
  }
});

exports.sendFleetNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const {eventId, message, type} = request.data || {};
  if (!eventId || !message || !type) {
    throw new HttpsError("invalid-argument", "eventId, message, and type are required");
  }

  const checkinsSnap = await db
    .collection("boatCheckins")
    .where("eventId", "==", eventId)
    .get();

  const recipientMemberIds = new Set();
  const directPhones = new Set();
  for (const doc of checkinsSnap.docs) {
    const data = doc.data();
    if (Array.isArray(data.memberIds)) data.memberIds.forEach((id) => recipientMemberIds.add(String(id)));
    if (Array.isArray(data.crewMemberIds)) data.crewMemberIds.forEach((id) => recipientMemberIds.add(String(id)));
    if (data.skipperMemberId) recipientMemberIds.add(String(data.skipperMemberId));
    if (Array.isArray(data.phoneNumbers)) data.phoneNumbers.forEach((phone) => directPhones.add(String(phone)));
  }

  let deliveryCount = 0;
  const memberIds = [...recipientMemberIds];
  for (const memberId of memberIds) {
    const snap = await db.collection("members").doc(memberId).get();
    const member = snap.data() || {};
    const mobile = member.mobileNumber;
    const token = member.pushToken;

    if (mobile) {
      try {
        await sendSmsInternal({to: mobile, message, eventId});
        deliveryCount += 1;
      } catch (error) {
        logger.warn("SMS failed for member", {memberId, error: error.message || String(error)});
      }
    }

    if (token) {
      try {
        await sendPushInternal({
          token,
          message,
          title: "Fleet Notification",
          data: {eventId: String(eventId), type: String(type)},
        });
        deliveryCount += 1;
      } catch (error) {
        logger.warn("Push failed for member", {memberId, error: error.message || String(error)});
      }
    }
  }

  for (const phone of directPhones) {
    try {
      await sendSmsInternal({to: phone, message, eventId});
      deliveryCount += 1;
    } catch (error) {
      logger.warn("Direct phone SMS failed", {phone, error: error.message || String(error)});
    }
  }

  const broadcastRef = await db.collection("fleetBroadcasts").add({
    eventId,
    sentBy: request.auth.uid,
    message,
    type,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    deliveryCount,
  });

  return {deliveryCount, broadcastId: broadcastRef.id};
});

// ── Authentication: membership-number verification flow ──

function generateVerificationCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function maskEmail(email) {
  if (!email || !email.includes("@")) return "***";
  const [local, domain] = email.split("@");
  const visible = local.length <= 2 ? local[0] : local.slice(0, 2);
  return `${visible}***@${domain}`;
}

exports.sendVerificationCode = onCall(async (request) => {
  const {memberNumber} = request.data || {};
  if (!memberNumber || typeof memberNumber !== "string") {
    throw new HttpsError("invalid-argument", "memberNumber is required");
  }

  const membersSnap = await db
    .collection("members")
    .where("memberNumber", "==", memberNumber.trim())
    .limit(1)
    .get();

  if (membersSnap.empty) {
    throw new HttpsError("not-found", "No member found with that membership number");
  }

  const memberDoc = membersSnap.docs[0];
  const memberData = memberDoc.data();
  const email = memberData.email;

  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "No email on file for this member. Contact the club for assistance.",
    );
  }

  const code = generateVerificationCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await db.collection("verification_codes").doc(memberDoc.id).set({
    code,
    memberNumber: memberNumber.trim(),
    memberId: memberDoc.id,
    attempts: 0,
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send verification email via Firebase Admin SDK (using the built-in email action)
  // For production, integrate SendGrid / Mailgun / SES. For now, log and use Firestore trigger or direct send.
  // Using a simple approach: write to a mail collection that a mail-sending extension picks up,
  // or log for development.
  try {
    await db.collection("mail").add({
      to: [email],
      message: {
        subject: "MPYC Raceday - Verification Code",
        text: `Your MPYC Raceday verification code is: ${code}\n\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore this email.`,
        html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px">
          <h2 style="color:#1B3A5C">MPYC Raceday</h2>
          <p>Your verification code is:</p>
          <div style="font-size:32px;font-weight:bold;letter-spacing:8px;text-align:center;padding:16px;background:#F5F5F0;border-radius:8px;color:#1B3A5C">${code}</div>
          <p style="color:#666;font-size:14px;margin-top:16px">This code expires in 10 minutes. If you did not request this, please ignore this email.</p>
        </div>`,
      },
    });
  } catch (mailError) {
    logger.error("Failed to queue verification email", {error: mailError.message});
  }

  logger.info("Verification code sent", {memberId: memberDoc.id, maskedEmail: maskEmail(email)});

  return {
    maskedEmail: maskEmail(email),
    memberId: memberDoc.id,
  };
});

exports.verifyCodeAndCreateToken = onCall(async (request) => {
  const {memberId, code} = request.data || {};
  if (!memberId || !code) {
    throw new HttpsError("invalid-argument", "memberId and code are required");
  }

  const codeRef = db.collection("verification_codes").doc(memberId);
  const codeSnap = await codeRef.get();

  if (!codeSnap.exists) {
    throw new HttpsError("not-found", "No verification code found. Please request a new one.");
  }

  const codeData = codeSnap.data();

  if (codeData.attempts >= 5) {
    await codeRef.delete();
    throw new HttpsError("resource-exhausted", "Too many attempts. Please request a new code.");
  }

  const expiresAt = codeData.expiresAt?.toDate ? codeData.expiresAt.toDate() : new Date(codeData.expiresAt);
  if (new Date() > expiresAt) {
    await codeRef.delete();
    throw new HttpsError("deadline-exceeded", "Verification code has expired. Please request a new one.");
  }

  if (codeData.code !== code.trim()) {
    await codeRef.update({attempts: admin.firestore.FieldValue.increment(1)});
    throw new HttpsError("permission-denied", "Invalid verification code");
  }

  // Code is valid — clean up
  await codeRef.delete();

  // Look up the member document
  const memberSnap = await db.collection("members").doc(memberId).get();
  if (!memberSnap.exists) {
    throw new HttpsError("not-found", "Member record not found");
  }
  const memberData = memberSnap.data();
  const email = memberData.email;

  // Create or get Firebase Auth user
  let uid;
  try {
    const existingUser = await admin.auth().getUserByEmail(email);
    uid = existingUser.uid;
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      const newUser = await admin.auth().createUser({
        email,
        displayName: `${memberData.firstName || ""} ${memberData.lastName || ""}`.trim(),
      });
      uid = newUser.uid;
    } else {
      throw new HttpsError("internal", "Failed to resolve auth user");
    }
  }

  // Set custom claims with role
  const role = memberData.role || "member";
  await admin.auth().setCustomUserClaims(uid, {role, memberId});

  // Link Firebase Auth UID to the member document
  await db.collection("members").doc(memberId).update({
    firebaseUid: uid,
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create a custom token for the client to sign in with
  const customToken = await admin.auth().createCustomToken(uid, {role, memberId});

  logger.info("Verification successful, token created", {uid, memberId, role});

  return {customToken, role};
});

exports.createMemberPortalSession = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  const {membershipNumber, initialView} = request.data || {};
  if (!membershipNumber) {
    throw new HttpsError("invalid-argument", "membershipNumber is required");
  }

  try {
    const sessionUrl = await createMemberPortalSession({
      apiKey: process.env.CLUBSPOT_API_KEY,
      membershipNumber,
      initialView: initialView || "home",
    });
    if (!sessionUrl) {
      throw new Error("Clubspot did not return session URL");
    }
    return {sessionUrl};
  } catch (error) {
    throw new HttpsError("internal", error.message || "Failed to create Clubspot portal session");
  }
});
