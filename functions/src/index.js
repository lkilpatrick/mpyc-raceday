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

// ── Crew Assignment: notifications ──

exports.sendCrewNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  const {eventId, onlyUnconfirmed} = request.data || {};
  if (!eventId) {
    throw new HttpsError("invalid-argument", "eventId is required");
  }

  const eventDoc = await db.collection("race_events").doc(eventId).get();
  if (!eventDoc.exists) {
    throw new HttpsError("not-found", "Event not found");
  }
  const eventData = eventDoc.data();
  const crewSlots = eventData.crewSlots || [];

  let notified = 0;
  for (const slot of crewSlots) {
    if (!slot.memberId) continue;
    if (onlyUnconfirmed && slot.status === "confirmed") continue;

    // Look up member to get contact info
    const memberSnap = await db.collection("members")
      .where("firebaseUid", "==", slot.memberId)
      .limit(1)
      .get();

    if (memberSnap.empty) continue;
    const member = memberSnap.docs[0].data();

    const eventDate = eventData.date?.toDate
      ? eventData.date.toDate()
      : new Date(eventData.date);
    const dateStr = eventDate.toLocaleDateString("en-US", {
      weekday: "short", month: "short", day: "numeric",
    });

    const message = `MPYC Raceday: You're assigned to ${eventData.name} on ${dateStr} as ${slot.role}. Please confirm in the app.`;

    // Send SMS if Twilio is configured and member has a mobile number
    if (process.env.TWILIO_ACCOUNT_SID && member.mobileNumber) {
      try {
        const twilioClient = twilio(
          process.env.TWILIO_ACCOUNT_SID,
          process.env.TWILIO_AUTH_TOKEN,
        );
        await twilioClient.messages.create({
          body: message,
          from: process.env.TWILIO_FROM_NUMBER,
          to: member.mobileNumber,
        });
      } catch (smsErr) {
        logger.warn("SMS send failed", {memberId: slot.memberId, error: smsErr.message});
      }
    }

    // Send push notification via FCM if member has tokens
    try {
      const tokensSnap = await db.collection("fcm_tokens")
        .where("userId", "==", slot.memberId)
        .get();
      const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);
      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: `RC Duty: ${eventData.name}`,
            body: `You're assigned as ${slot.role} on ${dateStr}`,
          },
          data: {eventId, role: slot.role || ""},
        });
      }
    } catch (pushErr) {
      logger.warn("Push notification failed", {memberId: slot.memberId, error: pushErr.message});
    }

    notified++;
  }

  logger.info("Crew notifications sent", {eventId, notified});
  return {notified};
});

exports.sendCrewReminders = onSchedule(
  {schedule: "every day 08:00", timeZone: "America/New_York"},
  async () => {
    const now = new Date();
    const oneWeekOut = new Date(now);
    oneWeekOut.setDate(oneWeekOut.getDate() + 7);
    const oneDayOut = new Date(now);
    oneDayOut.setDate(oneDayOut.getDate() + 1);

    // Query upcoming events in the next 7 days
    const eventsSnap = await db.collection("race_events")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(oneWeekOut))
      .where("status", "==", "scheduled")
      .get();

    let totalSent = 0;

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const eventDate = eventData.date?.toDate
        ? eventData.date.toDate()
        : new Date(eventData.date);
      const crewSlots = eventData.crewSlots || [];

      const daysUntil = Math.ceil((eventDate - now) / (1000 * 60 * 60 * 24));
      let reminderType;
      if (daysUntil <= 0) {
        reminderType = "morning_of";
      } else if (daysUntil <= 1) {
        reminderType = "day_before";
      } else if (daysUntil <= 7) {
        reminderType = "week_before";
      } else {
        continue;
      }

      const dateStr = eventDate.toLocaleDateString("en-US", {
        weekday: "short", month: "short", day: "numeric",
      });

      for (const slot of crewSlots) {
        if (!slot.memberId || slot.status === "declined") continue;

        const memberSnap = await db.collection("members")
          .where("firebaseUid", "==", slot.memberId)
          .limit(1)
          .get();
        if (memberSnap.empty) continue;
        const member = memberSnap.docs[0].data();

        let message;
        switch (reminderType) {
          case "morning_of":
            message = `Race day! You're on ${slot.role} for ${eventData.name}. Report time: ${eventData.startTimeHour || "TBD"}:${String(eventData.startTimeMinute || 0).padStart(2, "0")}`;
            break;
          case "day_before":
            message = `Reminder: RC duty tomorrow — ${eventData.name} as ${slot.role}`;
            break;
          case "week_before":
            message = `You're assigned to RC for ${eventData.name} on ${dateStr} as ${slot.role}`;
            break;
        }

        // Send SMS
        if (process.env.TWILIO_ACCOUNT_SID && member.mobileNumber) {
          try {
            const twilioClient = twilio(
              process.env.TWILIO_ACCOUNT_SID,
              process.env.TWILIO_AUTH_TOKEN,
            );
            await twilioClient.messages.create({
              body: message,
              from: process.env.TWILIO_FROM_NUMBER,
              to: member.mobileNumber,
            });
          } catch (err) {
            logger.warn("Reminder SMS failed", {error: err.message});
          }
        }

        // Send push
        try {
          const tokensSnap = await db.collection("fcm_tokens")
            .where("userId", "==", slot.memberId)
            .get();
          const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);
          if (tokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
              tokens,
              notification: {
                title: reminderType === "morning_of" ? "Race Day!" : "RC Duty Reminder",
                body: message,
              },
              data: {eventId: eventDoc.id, role: slot.role || ""},
            });
          }
        } catch (err) {
          logger.warn("Reminder push failed", {error: err.message});
        }

        totalSent++;
      }
    }

    logger.info("Crew reminders sent", {totalSent});
  },
);

// ── Maintenance: notifications ──

exports.notifyMaintenanceAssignment = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  const {requestId, assignedTo} = request.data || {};
  if (!requestId || !assignedTo) {
    throw new HttpsError("invalid-argument", "requestId and assignedTo required");
  }

  const reqDoc = await db.collection("maintenance_requests").doc(requestId).get();
  if (!reqDoc.exists) {
    throw new HttpsError("not-found", "Maintenance request not found");
  }
  const reqData = reqDoc.data();

  // Look up assigned member
  const memberSnap = await db.collection("members")
    .where("firebaseUid", "==", assignedTo)
    .limit(1)
    .get();

  if (memberSnap.empty) {
    logger.warn("Assigned member not found", {assignedTo});
    return {notified: false};
  }
  const member = memberSnap.docs[0].data();
  const message = `MPYC Maintenance: You've been assigned to "${reqData.title}" on ${reqData.boatName}. Priority: ${(reqData.priority || "").toUpperCase()}`;

  // SMS
  if (process.env.TWILIO_ACCOUNT_SID && member.mobileNumber) {
    try {
      const twilioClient = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN,
      );
      await twilioClient.messages.create({
        body: message,
        from: process.env.TWILIO_FROM_NUMBER,
        to: member.mobileNumber,
      });
    } catch (err) {
      logger.warn("Maintenance SMS failed", {error: err.message});
    }
  }

  // Push
  try {
    const tokensSnap = await db.collection("fcm_tokens")
      .where("userId", "==", assignedTo)
      .get();
    const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);
    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: `Maintenance Assigned: ${reqData.boatName}`,
          body: reqData.title,
        },
        data: {requestId, boatName: reqData.boatName || ""},
      });
    }
  } catch (err) {
    logger.warn("Maintenance push failed", {error: err.message});
  }

  logger.info("Maintenance assignment notification sent", {requestId, assignedTo});
  return {notified: true};
});

exports.weeklyMaintenanceSummary = onSchedule(
  {schedule: "every monday 09:00", timeZone: "America/New_York"},
  async () => {
    const now = new Date();
    const thirtyDaysAgo = new Date(now);
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Open critical/high
    const openSnap = await db.collection("maintenance_requests")
      .where("status", "in", ["reported", "acknowledged", "inProgress", "awaitingParts"])
      .get();
    const openRequests = openSnap.docs.map((d) => ({id: d.id, ...d.data()}));
    const criticalHigh = openRequests.filter(
      (r) => r.priority === "critical" || r.priority === "high",
    );

    // Older than 30 days
    const stale = openRequests.filter((r) => {
      const reported = r.reportedAt?.toDate ? r.reportedAt.toDate() : new Date(r.reportedAt);
      return reported < thirtyDaysAgo;
    });

    // Completed this week
    const completedSnap = await db.collection("maintenance_requests")
      .where("status", "==", "completed")
      .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();
    const completedThisWeek = completedSnap.docs.length;

    // Upcoming scheduled maintenance
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    const schedSnap = await db.collection("scheduled_maintenance")
      .where("nextDueAt", "<=", admin.firestore.Timestamp.fromDate(nextWeek))
      .get();
    const upcomingSched = schedSnap.docs.map((d) => d.data());

    // Build summary
    const lines = [
      `MPYC Weekly Maintenance Summary — ${now.toLocaleDateString("en-US", {weekday: "long", month: "short", day: "numeric"})}`,
      "",
      `Open Critical/High: ${criticalHigh.length}`,
      ...criticalHigh.slice(0, 5).map((r) => `  • [${r.priority.toUpperCase()}] ${r.boatName}: ${r.title}`),
      "",
      `Requests older than 30 days: ${stale.length}`,
      ...stale.slice(0, 5).map((r) => `  • ${r.boatName}: ${r.title}`),
      "",
      `Completed this week: ${completedThisWeek}`,
      "",
      `Upcoming scheduled maintenance: ${upcomingSched.length}`,
      ...upcomingSched.slice(0, 5).map((s) => `  • ${s.boatName}: ${s.title} (due ${s.nextDueAt?.toDate ? s.nextDueAt.toDate().toLocaleDateString() : "TBD"})`),
    ];
    const summaryText = lines.join("\n");

    // Get admin members
    const adminsSnap = await db.collection("members")
      .where("role", "in", ["admin", "rc_chair"])
      .get();

    let sent = 0;
    for (const adminDoc of adminsSnap.docs) {
      const adminData = adminDoc.data();
      if (process.env.TWILIO_ACCOUNT_SID && adminData.mobileNumber) {
        try {
          const twilioClient = twilio(
            process.env.TWILIO_ACCOUNT_SID,
            process.env.TWILIO_AUTH_TOKEN,
          );
          await twilioClient.messages.create({
            body: summaryText,
            from: process.env.TWILIO_FROM_NUMBER,
            to: adminData.mobileNumber,
          });
          sent++;
        } catch (err) {
          logger.warn("Weekly summary SMS failed", {error: err.message});
        }
      }
    }

    logger.info("Weekly maintenance summary sent", {
      criticalHigh: criticalHigh.length,
      stale: stale.length,
      completedThisWeek,
      upcomingSched: upcomingSched.length,
      adminsSent: sent,
    });
  },
);

// ── Checklist: seed default templates ──

exports.seedChecklistTemplates = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const preRaceItems = [
    // Safety Equipment
    {id: "s1", title: "VHF radio check", description: "Test transmit/receive on Ch 16 and race channel", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: false, order: 1},
    {id: "s2", title: "First aid kit", description: "Verify kit is stocked and accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 2},
    {id: "s3", title: "Fire extinguisher", description: "Check gauge is in green zone, pin intact", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 3},
    {id: "s4", title: "Flares — check expiry", description: "Verify flares are within expiration date", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: true, order: 4},
    {id: "s5", title: "Life jackets — count and condition", description: "Count PFDs, inspect for damage", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: true, order: 5},
    {id: "s6", title: "Throwable PFD", description: "Verify throwable device is accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 6},
    {id: "s7", title: "Sound signal device", description: "Test horn/whistle", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 7},
    {id: "s8", title: "Navigation lights test", description: "Test all nav lights", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 8},
    // Race Equipment
    {id: "r1", title: "Signal flags — full set inventory", description: "Verify all required flags present and in good condition", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false, order: 9},
    {id: "r2", title: "Starting horn / sound signal", description: "Test starting horn", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 10},
    {id: "r3", title: "Course board/display", description: "Verify course board is clean and markers available", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 11},
    {id: "r4", title: "Binoculars", description: "Clean lenses, verify working", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 12},
    {id: "r5", title: "Stopwatches/timing equipment", description: "Test timing equipment, fresh batteries", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 13},
    {id: "r6", title: "Protest flags (red)", description: "Verify protest flags available", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 14},
    {id: "r7", title: "Finish line markers/transit poles", description: "Check finish line equipment", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 15},
    {id: "r8", title: "Race instructions copies aboard", description: "Current SI copies available for crew", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false, order: 16},
    // Vessel Systems
    {id: "v1", title: "Fuel level", description: "Check fuel gauge/dipstick, note level", category: "Vessel Systems", isCritical: false, requiresPhoto: true, requiresNote: true, order: 17},
    {id: "v2", title: "Engine start and run check", description: "Start engine, verify smooth operation, check gauges", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false, order: 18},
    {id: "v3", title: "Bilge pump test", description: "Test bilge pump operation", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false, order: 19},
    {id: "v4", title: "Anchor and rode — inspect condition", description: "Check anchor, shackle, and rode for wear", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false, order: 20},
    {id: "v5", title: "Mooring lines", description: "Inspect lines for chafe and wear", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false, order: 21},
    {id: "v6", title: "Battery voltage check", description: "Check battery voltage", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: true, order: 22},
    {id: "v7", title: "Electrical panel check", description: "Verify all circuits functioning", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false, order: 23},
    {id: "v8", title: "Through-hulls — verify closed/open as needed", description: "Check all through-hull fittings", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false, order: 24},
    // Communications
    {id: "c1", title: "VHF Ch 16 test call", description: "Radio check on Ch 16", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false, order: 25},
    {id: "c2", title: "Race committee channel test", description: "Radio check on race channel (Ch 72 or club-specific)", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false, order: 26},
    {id: "c3", title: "Cell phone backup charged", description: "Verify backup phone is charged", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false, order: 27},
    {id: "c4", title: "Contact list aboard", description: "PRO, harbormaster, Coast Guard contacts available", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false, order: 28},
    {id: "c5", title: "Weather radio check", description: "Verify NOAA weather radio reception", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false, order: 29},
    // Navigation
    {id: "n1", title: "GPS/chartplotter operational", description: "Power on and verify GPS fix", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false, order: 30},
    {id: "n2", title: "Compass check", description: "Verify compass is functional", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false, order: 31},
    {id: "n3", title: "Horn/bell operational", description: "Test horn and bell", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false, order: 32},
  ];

  const postRaceItems = [
    // Secure Vessel
    {id: "sv1", title: "Engine off / fuel valve closed", description: "Shut down engine, close fuel valve", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 1},
    {id: "sv2", title: "Lines secured — bow, stern, spring", description: "Secure all dock lines", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 2},
    {id: "sv3", title: "Fenders positioned", description: "Position fenders for overnight", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 3},
    {id: "sv4", title: "Bilge check — pump if needed", description: "Check bilge, pump if water present", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 4},
    {id: "sv5", title: "Electrical panel — non-essential circuits off", description: "Turn off non-essential electrical circuits", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 5},
    {id: "sv6", title: "Cabin locked", description: "Lock cabin and hatches", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 6},
    {id: "sv7", title: "Canvas/covers on", description: "Install canvas covers", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false, order: 7},
    // Equipment Stowage
    {id: "es1", title: "Signal flags folded and stowed", description: "Fold and stow all signal flags", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 8},
    {id: "es2", title: "Timing equipment secured in dry storage", description: "Store timing equipment in dry location", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 9},
    {id: "es3", title: "Binoculars in case", description: "Return binoculars to case", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 10},
    {id: "es4", title: "Race documents collected and filed", description: "Collect and file all race documents", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 11},
    {id: "es5", title: "Course board cleared/stowed", description: "Clear and stow course board", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 12},
    {id: "es6", title: "Protest flags collected", description: "Collect all protest flags", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false, order: 13},
    // Reporting & Handoff
    {id: "rh1", title: "Race results recorded/submitted", description: "Ensure race results are recorded and submitted", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: false, order: 14},
    {id: "rh2", title: "Any incidents documented", description: "Document any incidents that occurred", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: false, order: 15},
    {id: "rh3", title: "Maintenance issues reported", description: "Report any maintenance issues found (link to maintenance request)", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: false, order: 16},
    {id: "rh4", title: "Fuel level noted for next use", description: "Record current fuel level for next crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true, order: 17},
    {id: "rh5", title: "Next event crew notified of any issues", description: "Communicate any issues to next event's crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true, order: 18},
  ];

  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.collection("checklists").doc("pre_race_duncans_watch").set({
    name: "Duncan's Watch Pre-Race Checkout",
    type: "preRace",
    items: preRaceItems,
    version: 1,
    lastModifiedBy: request.auth.uid,
    lastModifiedAt: now,
    isActive: true,
  }, {merge: true});

  await db.collection("checklists").doc("post_race_duncans_watch").set({
    name: "Duncan's Watch Post-Race Securing",
    type: "postRace",
    items: postRaceItems,
    version: 1,
    lastModifiedBy: request.auth.uid,
    lastModifiedAt: now,
    isActive: true,
  }, {merge: true});

  logger.info("Checklist templates seeded");
  return {seeded: 2};
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

// ══════════════════════════════════════════════════════
// Course Selection & Fleet Notification
// ══════════════════════════════════════════════════════

// onCourseSelected — Firestore trigger when RaceEvent.courseId is updated
exports.onCourseSelected = onDocumentUpdated("race_events/{eventId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Only fire if courseId changed
  if (before.courseId === after.courseId) return;

  const eventId = event.params.eventId;
  const courseId = after.courseId;
  if (!courseId) return;

  logger.info("Course selected", { eventId, courseId });

  try {
    // Fetch course config
    const courseDoc = await db.collection("courses").doc(courseId).get();
    if (!courseDoc.exists) {
      logger.error("Course not found", { courseId });
      return;
    }
    const course = courseDoc.data();
    const courseNum = course.courseNumber || "";
    const markSeq = course.courseName || "";
    const distance = course.distanceNm || 0;
    const finishAt = course.finishLocation === "mark_x" ? "Mark X" : "Committee Boat";
    const requiresInflatable = course.requiresInflatable || false;
    const inflatableType = course.inflatableType || "";

    // Build message
    let smsMsg = `MPYC RC: Course ${courseNum} selected. ${markSeq}. ${distance}nm. Finish at ${finishAt}.`;
    if (requiresInflatable && inflatableType) {
      smsMsg += ` RC will set ${inflatableType} mark(s) before start.`;
    }
    if (course.finishLocation === "mark_x") {
      smsMsg += " Finish at Mark X.";
    }
    if (before.courseId) {
      smsMsg += ` Course CHANGED from ${before.courseId} to ${courseNum}.`;
    }
    smsMsg += " Good sailing!";

    // Fetch checked-in boats for this event
    const checkinsSnap = await db.collection("boat_checkins")
      .where("eventId", "==", eventId)
      .get();

    let smsSent = 0;
    let pushSent = 0;

    for (const checkinDoc of checkinsSnap.docs) {
      const checkin = checkinDoc.data();
      const skipperId = checkin.skipperId;
      if (!skipperId) continue;

      // Look up member contact info
      const memberDoc = await db.collection("members").doc(skipperId).get();
      if (!memberDoc.exists) continue;
      const member = memberDoc.data();

      // Send SMS via Twilio
      if (member.phone && twilioClient) {
        try {
          await twilioClient.messages.create({
            body: smsMsg,
            from: process.env.TWILIO_FROM_NUMBER,
            to: member.phone,
          });
          smsSent++;
        } catch (smsErr) {
          logger.error("SMS send failed", { skipperId, error: smsErr.message });
        }
      }

      // Send FCM push notification
      if (member.fcmToken) {
        try {
          await admin.messaging().send({
            token: member.fcmToken,
            notification: {
              title: `Course ${courseNum} Selected`,
              body: `${markSeq} — ${distance}nm`,
            },
            data: {
              type: "course_selected",
              eventId,
              courseId,
              screen: `/courses/display/${courseId}`,
            },
          });
          pushSent++;
        } catch (pushErr) {
          logger.error("Push send failed", { skipperId, error: pushErr.message });
        }
      }
    }

    // Create FleetBroadcast record
    await db.collection("fleet_broadcasts").add({
      eventId,
      sentBy: "system",
      message: smsMsg,
      type: "courseSelection",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      deliveryCount: smsSent + pushSent,
    });

    logger.info("Course notification sent", { courseNum, smsSent, pushSent });
  } catch (err) {
    logger.error("onCourseSelected error", { error: err.message });
  }
});

// sendFleetBroadcast — callable Cloud Function for custom/template messages
exports.sendFleetBroadcast = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { eventId, message, type } = request.data;
  if (!eventId || !message) {
    throw new HttpsError("invalid-argument", "eventId and message are required");
  }

  try {
    // Fetch checked-in boats
    const checkinsSnap = await db.collection("boat_checkins")
      .where("eventId", "==", eventId)
      .get();

    let smsSent = 0;
    let pushSent = 0;

    for (const checkinDoc of checkinsSnap.docs) {
      const checkin = checkinDoc.data();
      const skipperId = checkin.skipperId;
      if (!skipperId) continue;

      const memberDoc = await db.collection("members").doc(skipperId).get();
      if (!memberDoc.exists) continue;
      const member = memberDoc.data();

      // SMS
      if (member.phone && twilioClient) {
        try {
          await twilioClient.messages.create({
            body: message,
            from: process.env.TWILIO_FROM_NUMBER,
            to: member.phone,
          });
          smsSent++;
        } catch (smsErr) {
          logger.error("Fleet broadcast SMS failed", { skipperId, error: smsErr.message });
        }
      }

      // FCM
      if (member.fcmToken) {
        try {
          await admin.messaging().send({
            token: member.fcmToken,
            notification: {
              title: "MPYC Race Committee",
              body: message,
            },
            data: {
              type: "fleet_broadcast",
              eventId,
            },
          });
          pushSent++;
        } catch (pushErr) {
          logger.error("Fleet broadcast push failed", { skipperId, error: pushErr.message });
        }
      }
    }

    // Log broadcast
    await db.collection("fleet_broadcasts").add({
      eventId,
      sentBy: request.auth.uid,
      message,
      type: type || "general",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      deliveryCount: smsSent + pushSent,
    });

    return { smsSent, pushSent, total: smsSent + pushSent };
  } catch (err) {
    throw new HttpsError("internal", err.message || "Failed to send fleet broadcast");
  }
});
