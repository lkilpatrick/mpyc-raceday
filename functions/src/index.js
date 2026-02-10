const admin = require("firebase-admin");

const logger = require("firebase-functions/logger");

const {onSchedule} = require("firebase-functions/v2/scheduler");

const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");

const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");



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

  // Preserve roles — never overwrite from Clubspot

  // If existing has 'roles' array, keep it; else migrate legacy 'role' to roles array

  let roles = existing.roles;

  if (!Array.isArray(roles) || roles.length === 0) {

    const legacyRole = existing.role;

    const legacyMap = {admin: "web_admin", pro: "rc_chair", rc_crew: "crew", member: "crew"};

    roles = legacyRole ? [legacyMap[legacyRole] || "crew"] : ["crew"];

  }



  // membership is a nested object: { id, status, category }

  const membership = member.membership || {};

  return {

    id: String(member.id || member._id || member.membership_number || ""),

    firstName: String(member.first_name || ""),

    lastName: String(member.last_name || ""),

    email: String(member.email || ""),

    mobileNumber: String(member.mobile_number || member.mobile || member.mobile_phone || ""),

    memberNumber: String(member.membership_number || member.member_number || ""),

    membershipId: String(membership.id || ""),

    membershipStatus: String(membership.status || member.membership_status || ""),

    membershipCategory: String(membership.category || member.membership_category || ""),

    memberTags: Array.isArray(member.member_tags) ? member.member_tags.map((t) => String(t)) : [],

    dob: member.dob ? String(member.dob) : null,

    clubspotId: String(member.id || member._id || ""),

    clubspotCreated: member.created || null,

    roles,

    lastSynced: admin.firestore.FieldValue.serverTimestamp(),

    // Preserve fields that are managed locally, never overwritten by Clubspot

    signalNumber: existing.signalNumber || null,

    boatName: existing.boatName || null,

    sailNumber: existing.sailNumber || null,

    boatClass: existing.boatClass || null,

    phrfRating: existing.phrfRating || null,

    firebaseUid: existing.firebaseUid || null,

    lastLogin: existing.lastLogin || null,

    isActive: existing.isActive !== undefined ? existing.isActive : true,

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



async function sendEmailInternal({to, subject, message, eventId}) {

  if (!to) return null;

  const ref = await db.collection("mail").add({

    to: Array.isArray(to) ? to : [to],

    message: {

      subject: subject || "MPYC Raceday Notification",

      text: message,

      html: `<div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:24px">

        <h2 style="color:#1B3A5C">MPYC Raceday</h2>

        <p>${message.replace(/\n/g, "<br>")}</p>

        <p style="color:#666;font-size:12px;margin-top:24px">This is an automated notification from MPYC Raceday.</p>

      </div>`,

    },

  });

  await db.collection("notificationLogs").add({

    to: Array.isArray(to) ? to : [to],

    channel: "email",

    eventId: eventId || null,

    subject: subject || "MPYC Raceday Notification",

    message,

    mailDocId: ref.id,

    createdAt: admin.firestore.FieldValue.serverTimestamp(),

  });

  return ref;

}



// ── SMS via Firestore sms collection ──

// Writes to the "sms" collection. A Firestore-triggered extension or

// Cloud Function (e.g. Twilio, Vonage, MessageBird) picks up new docs

// and delivers the SMS. Configure the provider in Firebase console.

async function sendSmsInternal({to, message, eventId}) {

  if (!to) return null;

  const ref = await db.collection("sms").add({

    to,

    body: message,

    status: "pending",

    createdAt: admin.firestore.FieldValue.serverTimestamp(),

  });

  await db.collection("notificationLogs").add({

    to: [to],

    channel: "sms",

    eventId: eventId || null,

    message,

    smsDocId: ref.id,

    createdAt: admin.firestore.FieldValue.serverTimestamp(),

  });

  return ref;

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



exports.sendNotification = onCall(async (request) => {

  const {to, message, subject, eventId, channel} = request.data || {};

  if (!request.auth) {

    throw new HttpsError("unauthenticated", "Authentication required");

  }

  if (!to || !message) {

    throw new HttpsError("invalid-argument", "to and message are required");

  }



  try {

    if (channel === "sms") {

      const result = await sendSmsInternal({to, message, eventId});

      return {id: result?.id, channel: "sms", status: "queued"};

    } else {

      const result = await sendEmailInternal({to, subject, message, eventId});

      return {id: result?.id, channel: "email", status: "queued"};

    }

  } catch (error) {

    throw new HttpsError("internal", error.message || "Notification send failed");

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

    .collection("boat_checkins")

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



    // SMS for race-day ops

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



  // Also SMS any direct phone numbers from check-ins

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



    // Send email notification

    if (member.email) {

      try {

        await sendEmailInternal({

          to: member.email,

          subject: `RC Duty Assignment: ${eventData.name}`,

          message,

          eventId,

        });

      } catch (emailErr) {

        logger.warn("Email send failed", {memberId: slot.memberId, error: emailErr.message});

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



        // Send email reminder

        if (member.email) {

          try {

            const subjectMap = {

              morning_of: `Race Day! ${eventData.name}`,

              day_before: `Tomorrow: RC Duty — ${eventData.name}`,

              week_before: `Upcoming RC Duty: ${eventData.name}`,

            };

            await sendEmailInternal({

              to: member.email,

              subject: subjectMap[reminderType] || "RC Duty Reminder",

              message,

              eventId: eventDoc.id,

            });

          } catch (err) {

            logger.warn("Reminder email failed", {error: err.message});

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



  // Email

  if (member.email) {

    try {

      await sendEmailInternal({

        to: member.email,

        subject: `Maintenance Assigned: ${reqData.boatName} — ${reqData.title}`,

        message,

      });

    } catch (err) {

      logger.warn("Maintenance email failed", {error: err.message});

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

      if (adminData.email) {

        try {

          await sendEmailInternal({

            to: adminData.email,

            subject: `MPYC Weekly Maintenance Summary — ${now.toLocaleDateString("en-US", {month: "short", day: "numeric"})}`,

            message: summaryText,

          });

          sent++;

        } catch (err) {

          logger.warn("Weekly summary email failed", {error: err.message});

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



  // ── Shared base items (all power boats) ──

  const baseSafetyItems = [

    {id: "s1", title: "VHF radio check", description: "Test transmit/receive on Ch 16 and race channel", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "s2", title: "First aid kit", description: "Verify kit is stocked and accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "s3", title: "Fire extinguisher", description: "Check gauge is in green zone, pin intact", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "s4", title: "Flares — check expiry", description: "Verify flares are within expiration date", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "s5", title: "Life jackets — count and condition", description: "Count PFDs, inspect for damage", category: "Safety Equipment", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "s6", title: "Throwable PFD", description: "Verify throwable device is accessible", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "s7", title: "Sound signal device", description: "Test horn/whistle", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "s8", title: "Navigation lights test", description: "Test all nav lights (red, green, white stern, masthead)", category: "Safety Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  const baseVesselItems = [

    {id: "v1", title: "Fuel level", description: "Check fuel gauge/dipstick, note level", category: "Vessel Systems", isCritical: false, requiresPhoto: true, requiresNote: true},

    {id: "v2", title: "Engine oil level", description: "Check dipstick, top off if below min line", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "v3", title: "Engine coolant level", description: "Check coolant reservoir, verify level between min/max", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v4", title: "Engine start and run check", description: "Start engine, let idle 2 min, check gauges (oil pressure, temp, voltage)", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "v5", title: "Raw water flow / tell-tale", description: "Verify cooling water discharge from exhaust", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "v6", title: "Steering check", description: "Turn wheel/tiller full lock to lock, check for binding", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "v7", title: "Throttle and shift check", description: "Verify smooth forward/neutral/reverse shifting at dock", category: "Vessel Systems", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "v8", title: "Bilge pump test", description: "Test bilge pump operation (auto and manual switch)", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v9", title: "Battery voltage check", description: "Check battery voltage (should be 12.6V+ at rest, 13.5V+ charging)", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "v10", title: "Electrical panel check", description: "Verify all circuits functioning, no tripped breakers", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v11", title: "Through-hulls — verify position", description: "Check all through-hull fittings are open/closed as needed", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v12", title: "Anchor and rode", description: "Check anchor, shackle pin wired, rode flaked and ready", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v13", title: "Mooring lines", description: "Inspect dock lines for chafe and wear", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "v14", title: "Prop check (visual)", description: "Look over the side — no lines/debris on prop", category: "Vessel Systems", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  const baseCommsItems = [

    {id: "c1", title: "VHF Ch 16 test call", description: "Radio check on Ch 16 with another station", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "c2", title: "Race committee channel test", description: "Radio check on race channel (Ch 72 or club-specific)", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "c3", title: "Cell phone backup charged", description: "Verify backup phone is charged and in waterproof case", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "c4", title: "Contact list aboard", description: "PRO, harbormaster, Coast Guard, club office contacts available", category: "Communications", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  const baseNavItems = [

    {id: "n1", title: "GPS/chartplotter operational", description: "Power on, verify GPS fix and chart display", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "n2", title: "Compass check", description: "Verify compass is functional and reads correctly", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "n3", title: "Depth sounder", description: "Verify depth sounder reading", category: "Navigation", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  // ── Signal Boat (RC / Committee Boat) specific items ──

  const signalBoatRaceItems = [

    {id: "r1", title: "Signal flags — full set inventory", description: "Verify all required flags: AP, N, 1st Sub, class flags, P, I, Z, Black, S, L, M, Y, X", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "r2", title: "Starting horn / sound signal", description: "Test starting horn — verify audible at 200m+", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "r3", title: "Course board/display", description: "Verify course board is clean, dry-erase markers available", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r4", title: "Binoculars", description: "Clean lenses, verify working — need 2 pairs minimum", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r5", title: "Stopwatches/timing equipment", description: "Test timing equipment, fresh batteries, sync all clocks", category: "Race Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "r6", title: "Finish line transit poles", description: "Check finish line transit poles/sighting equipment", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r7", title: "Race instructions copies aboard", description: "Current Sailing Instructions copies available for crew", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r8", title: "Protest flags (red) available", description: "Verify spare protest flags available for competitors", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r9", title: "Wind indicator / Windex", description: "Verify wind indicator at masthead is functional", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "r10", title: "Scoring sheets / clipboard", description: "Blank scoring sheets, pencils, clipboard ready", category: "Race Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  // ── Mark Boat specific items ──

  const markBoatItems = [

    {id: "mb1", title: "Race marks aboard — count", description: "Verify all required marks are aboard (windward, leeward, gate, offset)", category: "Mark Setting", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "mb2", title: "Mark anchors and rode", description: "Check all mark anchors, shackles, and rode — no tangles", category: "Mark Setting", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "mb3", title: "Mark lights (if applicable)", description: "Test mark lights for dusk racing", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "mb4", title: "Inflatable marks — check inflation", description: "Verify inflatable marks are fully inflated, no leaks", category: "Mark Setting", isCritical: false, requiresPhoto: true, requiresNote: false},

    {id: "mb5", title: "Spare marks and anchors", description: "Verify spare mark and anchor aboard", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "mb6", title: "Mark retrieval gaff/hook", description: "Gaff or hook for mark retrieval is aboard", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "mb7", title: "GPS waypoints loaded", description: "Verify course mark GPS waypoints are loaded in chartplotter", category: "Mark Setting", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  // ── Safety Boat specific items ──

  const safetyBoatItems = [

    {id: "sb1", title: "Tow line — 50ft minimum", description: "Verify tow line is aboard, no chafe, proper length", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "sb2", title: "Rescue knife", description: "Sharp rescue knife accessible to helmsman", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "sb3", title: "Throw bag", description: "Throw bag accessible and line flaked", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sb4", title: "Swim ladder / boarding aid", description: "Verify swim ladder deploys properly for MOB recovery", category: "Rescue Equipment", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "sb5", title: "Thermal blankets", description: "Thermal/emergency blankets aboard for hypothermia", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sb6", title: "Paddle / oar", description: "Emergency paddle aboard", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sb7", title: "Bolt cutters (for rigging)", description: "Bolt cutters aboard for rigging emergencies", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sb8", title: "Extra PFDs for rescued sailors", description: "Minimum 4 extra PFDs for rescued crew", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "sb9", title: "Pump for swamped dinghies", description: "Manual or electric pump for bailing swamped boats", category: "Rescue Equipment", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  // ── Post-race items (shared) ──

  const postRaceSecureItems = [

    {id: "sv1", title: "Engine off / fuel valve closed", description: "Shut down engine, close fuel valve if equipped", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv2", title: "Lines secured — bow, stern, spring", description: "Secure all dock lines with proper cleating", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv3", title: "Fenders positioned", description: "Position fenders for overnight/weather", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv4", title: "Bilge check — pump if needed", description: "Check bilge, pump if water present, note amount", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv5", title: "Electrical panel — non-essential circuits off", description: "Turn off all non-essential electrical circuits, leave bilge pump on", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv6", title: "Battery switch position", description: "Set battery switch to correct position (off or charge)", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv7", title: "Cabin/console locked", description: "Lock cabin, console, and hatches", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv8", title: "Canvas/covers on", description: "Install canvas covers, snap all fasteners", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sv9", title: "Wash down hull and deck", description: "Rinse salt water from hull, deck, and hardware", category: "Secure Vessel", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  const postRaceStowageItems = [

    {id: "es1", title: "Signal flags folded and stowed", description: "Fold and stow all signal flags in dry bag", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "es2", title: "Timing equipment secured", description: "Store timing equipment in dry, locked storage", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "es3", title: "Binoculars in case", description: "Return binoculars to padded case", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "es4", title: "Race documents collected", description: "Collect and file all race documents, scoring sheets", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "es5", title: "Course board cleared", description: "Clear and stow course board", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "es6", title: "Electronics powered down", description: "GPS, radio, instruments powered down", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

  ];



  const postRaceReportItems = [

    {id: "rh1", title: "Race results recorded/submitted", description: "Ensure race results are recorded and submitted to scoring", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "rh2", title: "Incidents documented", description: "Document any incidents, protests, or injuries", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "rh3", title: "Maintenance issues reported", description: "Report any maintenance issues found during use", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "rh4", title: "Fuel level noted", description: "Record current fuel level for next crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "rh5", title: "Engine hours noted", description: "Record engine hour meter reading", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "rh6", title: "Next crew notified of issues", description: "Communicate any issues to next event's crew", category: "Reporting & Handoff", isCritical: false, requiresPhoto: false, requiresNote: true},

  ];



  // ── Safety inspection checklist ──

  const safetyInspectionItems = [

    {id: "si1", title: "Hull integrity — below waterline", description: "Inspect hull for cracks, blisters, osmosis, damage below waterline", category: "Hull & Structure", isCritical: true, requiresPhoto: true, requiresNote: true},

    {id: "si2", title: "Hull integrity — above waterline", description: "Inspect topsides for cracks, gelcoat damage, impact marks", category: "Hull & Structure", isCritical: false, requiresPhoto: true, requiresNote: true},

    {id: "si3", title: "Transom condition", description: "Check transom for soft spots, delamination near engine mount", category: "Hull & Structure", isCritical: true, requiresPhoto: true, requiresNote: false},

    {id: "si4", title: "Deck hardware secure", description: "Check all cleats, chocks, stanchions, rails for looseness", category: "Hull & Structure", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "si5", title: "Non-skid deck condition", description: "Inspect non-skid surfaces for wear", category: "Hull & Structure", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "si6", title: "Fire extinguisher — current inspection", description: "Verify inspection tag is current, gauge in green", category: "USCG Requirements", isCritical: true, requiresPhoto: true, requiresNote: true},

    {id: "si7", title: "PFDs — USCG approved, correct count", description: "Verify correct number of USCG-approved PFDs for vessel capacity", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "si8", title: "Visual distress signals current", description: "Verify flares/signals are not expired", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "si9", title: "Sound producing device", description: "Horn or whistle functional", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "si10", title: "Navigation lights functional", description: "Test all required navigation lights", category: "USCG Requirements", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "si11", title: "Registration/documentation current", description: "Verify vessel registration or documentation is current and aboard", category: "USCG Requirements", isCritical: true, requiresPhoto: true, requiresNote: true},

    {id: "si12", title: "Engine mounts secure", description: "Check engine mount bolts for tightness", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "si13", title: "Fuel system — no leaks", description: "Inspect fuel lines, connections, tank for leaks or corrosion", category: "Engine & Mechanical", isCritical: true, requiresPhoto: true, requiresNote: true},

    {id: "si14", title: "Exhaust system", description: "Inspect exhaust hose, clamps, and riser for leaks or deterioration", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "si15", title: "Battery secured and terminals clean", description: "Verify battery is secured, terminals clean and tight, no corrosion", category: "Electrical", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "si16", title: "Wiring — no chafe or exposed conductors", description: "Inspect visible wiring for chafe, corrosion, loose connections", category: "Electrical", isCritical: false, requiresPhoto: true, requiresNote: true},

    {id: "si17", title: "Bilge pump operational", description: "Test bilge pump — auto float switch and manual", category: "Electrical", isCritical: true, requiresPhoto: false, requiresNote: false},

    {id: "si18", title: "Through-hulls — condition and operation", description: "Inspect all through-hulls, exercise seacocks, check for weeping", category: "Hull & Structure", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "si19", title: "Steering system", description: "Inspect steering cables/hydraulics for wear, leaks, play", category: "Engine & Mechanical", isCritical: true, requiresPhoto: false, requiresNote: true},

    {id: "si20", title: "Propeller condition", description: "Inspect prop for dings, bent blades, fishing line wrap", category: "Engine & Mechanical", isCritical: false, requiresPhoto: true, requiresNote: true},

  ];



  // ── Helper: add order field to items ──

  function addOrder(items) {

    return items.map((item, i) => ({...item, order: i + 1}));

  }



  const now = admin.firestore.FieldValue.serverTimestamp();

  const uid = request.auth.uid;

  const batch = db.batch();



  // ── Duncan's Watch (Signal/Committee Boat) ──

  const dwPreItems = addOrder([...baseSafetyItems, ...signalBoatRaceItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]);

  const dwPostItems = addOrder([...postRaceSecureItems, ...postRaceStowageItems, ...postRaceReportItems]);

  batch.set(db.collection("checklists").doc("pre_race_duncans_watch"), {

    name: "Duncan's Watch — Pre-Race Checkout",

    type: "preRace",

    items: dwPreItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});

  batch.set(db.collection("checklists").doc("post_race_duncans_watch"), {

    name: "Duncan's Watch — Post-Race Securing",

    type: "postRace",

    items: dwPostItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});



  // ── Signal Boat ──

  const sbPreItems = addOrder([...baseSafetyItems, ...signalBoatRaceItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]);

  const sbPostItems = addOrder([...postRaceSecureItems, ...postRaceStowageItems, ...postRaceReportItems]);

  batch.set(db.collection("checklists").doc("pre_race_signal_boat"), {

    name: "Signal Boat — Pre-Race Checkout",

    type: "preRace",

    items: sbPreItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});

  batch.set(db.collection("checklists").doc("post_race_signal_boat"), {

    name: "Signal Boat — Post-Race Securing",

    type: "postRace",

    items: sbPostItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});



  // ── Mark Boat ──

  const mbPreItems = addOrder([...baseSafetyItems, ...markBoatItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]);

  const mbPostItems = addOrder([

    ...postRaceSecureItems,

    {id: "mb_es1", title: "Marks retrieved and stowed", description: "All race marks retrieved, dried, and stowed", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: true},

    {id: "mb_es2", title: "Mark anchors and rode coiled", description: "Coil and stow all mark anchor rode — no tangles", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "mb_es3", title: "Inflatable marks deflated/stowed", description: "Deflate and stow inflatable marks if applicable", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    ...postRaceReportItems,

  ]);

  batch.set(db.collection("checklists").doc("pre_race_mark_boat"), {

    name: "Mark Boat — Pre-Race Checkout",

    type: "preRace",

    items: mbPreItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});

  batch.set(db.collection("checklists").doc("post_race_mark_boat"), {

    name: "Mark Boat — Post-Race Securing",

    type: "postRace",

    items: addOrder(mbPostItems),

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});



  // ── Safety Boat ──

  const safPreItems = addOrder([...baseSafetyItems, ...safetyBoatItems, ...baseVesselItems, ...baseCommsItems, ...baseNavItems]);

  const safPostItems = addOrder([

    ...postRaceSecureItems,

    {id: "sb_es1", title: "Tow line inspected and coiled", description: "Inspect tow line for chafe, coil and stow", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    {id: "sb_es2", title: "Rescue equipment stowed", description: "Stow throw bag, knife, blankets, extra PFDs", category: "Equipment Stowage", isCritical: false, requiresPhoto: false, requiresNote: false},

    ...postRaceReportItems,

  ]);

  batch.set(db.collection("checklists").doc("pre_race_safety_boat"), {

    name: "Safety Boat — Pre-Race Checkout",

    type: "preRace",

    items: safPreItems,

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});

  batch.set(db.collection("checklists").doc("post_race_safety_boat"), {

    name: "Safety Boat — Post-Race Securing",

    type: "postRace",

    items: addOrder(safPostItems),

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});



  // ── Safety Inspection (annual/seasonal — all boats) ──

  batch.set(db.collection("checklists").doc("safety_inspection"), {

    name: "Annual Safety Inspection",

    type: "safety",

    items: addOrder(safetyInspectionItems),

    version: 1,

    lastModifiedBy: uid,

    lastModifiedAt: now,

    isActive: true,

  }, {merge: true});



  await batch.commit();

  logger.info("Checklist templates seeded", {count: 9});

  return {seeded: 9};

});



// ── Seed scheduled maintenance (typical power boat intervals) ──



exports.seedScheduledMaintenance = onCall(async (request) => {

  if (!request.auth) {

    throw new HttpsError("unauthenticated", "Authentication required");

  }



  const boats = ["Duncan's Watch", "Signal Boat", "Mark Boat", "Safety Boat"];

  const now = new Date();



  // Typical power boat maintenance schedule items

  const scheduleTemplates = [

    // Engine

    {title: "Engine oil & filter change", description: "Change engine oil and replace oil filter. Use manufacturer-recommended oil weight. Record engine hours.", intervalDays: 50, category: "engine"},

    {title: "Fuel filter / water separator", description: "Replace fuel filter and drain water separator. Check for contamination.", intervalDays: 100, category: "engine"},

    {title: "Raw water impeller replacement", description: "Replace raw water cooling impeller. Inspect housing for scoring. Carry spare aboard.", intervalDays: 180, category: "engine"},

    {title: "Spark plugs (gas) / injectors (diesel)", description: "Inspect and replace spark plugs or clean/test fuel injectors per manufacturer schedule.", intervalDays: 200, category: "engine"},

    {title: "Drive belt inspection", description: "Inspect alternator and water pump drive belts for cracks, glazing, tension. Replace if worn.", intervalDays: 90, category: "engine"},

    {title: "Thermostat inspection", description: "Test thermostat operation, replace if engine runs hot or cold.", intervalDays: 365, category: "engine"},

    {title: "Lower unit gear oil change", description: "Drain and replace lower unit gear oil. Check for water intrusion (milky oil = seal failure).", intervalDays: 100, category: "engine"},

    {title: "Engine zincs / anodes", description: "Inspect and replace sacrificial zinc anodes on engine, outdrive, and hull.", intervalDays: 90, category: "engine"},



    // Electrical

    {title: "Battery load test", description: "Load test all batteries. Check terminal connections, clean corrosion. Verify charging voltage.", intervalDays: 90, category: "electrical"},

    {title: "Navigation light check", description: "Test all navigation lights. Replace bulbs/LEDs as needed. Check wiring connections.", intervalDays: 30, category: "electrical"},

    {title: "Bilge pump test & clean", description: "Test bilge pump auto float switch and manual override. Clean strainer. Check wiring.", intervalDays: 30, category: "electrical"},

    {title: "VHF radio inspection", description: "Test VHF radio transmit/receive. Check antenna connections. Verify DSC registration.", intervalDays: 90, category: "electronics"},

    {title: "GPS / chartplotter update", description: "Update chart data if available. Check GPS antenna. Verify waypoints.", intervalDays: 180, category: "electronics"},



    // Hull

    {title: "Bottom paint / antifouling", description: "Haul out, clean, and apply antifouling bottom paint. Inspect running gear.", intervalDays: 365, category: "hull"},

    {title: "Hull cleaning (in-water)", description: "Dive or hire diver to clean hull bottom, prop, and running gear of growth.", intervalDays: 60, category: "hull"},

    {title: "Through-hull inspection", description: "Inspect all through-hull fittings, seacocks, and hose clamps. Exercise seacocks.", intervalDays: 90, category: "hull"},

    {title: "Gelcoat inspection & repair", description: "Inspect gelcoat for cracks, chips, crazing. Repair as needed to prevent water intrusion.", intervalDays: 180, category: "hull"},

    {title: "Trailer inspection (if applicable)", description: "Inspect trailer bearings, tires, lights, winch, bunks/rollers. Grease bearings.", intervalDays: 90, category: "hull"},



    // Safety

    {title: "Fire extinguisher inspection", description: "Check gauge, inspection tag, pin, and tamper seal. Replace if expired or discharged.", intervalDays: 365, category: "safety"},

    {title: "Flare expiration check", description: "Check all visual distress signals for expiration dates. Replace expired flares.", intervalDays: 180, category: "safety"},

    {title: "PFD inspection", description: "Inspect all PFDs for tears, fading, buckle function. Test inflatable PFD cartridges.", intervalDays: 180, category: "safety"},

    {title: "First aid kit restock", description: "Check first aid kit contents, replace used or expired items.", intervalDays: 90, category: "safety"},

    {title: "Safety equipment inventory", description: "Full inventory: throw ring, paddle, anchor, whistle, mirror, flashlight, knife.", intervalDays: 90, category: "safety"},



    // General

    {title: "Canvas & cover inspection", description: "Inspect canvas covers, bimini, enclosures for tears, UV damage, zipper function.", intervalDays: 180, category: "general"},

    {title: "Dock line replacement", description: "Inspect all dock lines for chafe, UV damage, stiffness. Replace as needed.", intervalDays: 180, category: "general"},

    {title: "Steering system service", description: "Inspect steering cables/hydraulic lines. Check for play, leaks. Lubricate as needed.", intervalDays: 180, category: "general"},

    {title: "Anchor rode inspection", description: "Inspect anchor chain and rode for wear, corrosion, chafe. Check shackle and swivel.", intervalDays: 180, category: "general"},

  ];



  const batch = db.batch();

  let count = 0;



  for (const boat of boats) {

    for (const template of scheduleTemplates) {

      const docId = `${boat.replace(/[^a-zA-Z0-9]/g, "_").toLowerCase()}_${template.title.replace(/[^a-zA-Z0-9]/g, "_").toLowerCase()}`;

      const nextDue = new Date(now.getTime() + template.intervalDays * 24 * 60 * 60 * 1000);



      batch.set(db.collection("scheduled_maintenance").doc(docId), {

        boatName: boat,

        title: template.title,

        description: template.description,

        intervalDays: template.intervalDays,

        lastCompletedAt: null,

        nextDueAt: admin.firestore.Timestamp.fromDate(nextDue),

      }, {merge: true});

      count++;

    }

  }



  await batch.commit();

  logger.info("Scheduled maintenance seeded", {count});

  return {seeded: count};

});



// ── Seed test admin (development only) ──



exports.seedTestAdmin = onCall(async (request) => {

  const testEmail = "admin@mpyc.org";

  const testPassword = "RaceDay2024!";



  // Check if admin already exists in Auth

  let uid;

  try {

    const existing = await admin.auth().getUserByEmail(testEmail);

    uid = existing.uid;

    // Update password in case it changed

    await admin.auth().updateUser(uid, {password: testPassword});

    logger.info("Test admin auth user already exists", {uid});

  } catch (err) {

    if (err.code === "auth/user-not-found") {

      const newUser = await admin.auth().createUser({

        email: testEmail,

        password: testPassword,

        displayName: "MPYC Admin",

      });

      uid = newUser.uid;

      logger.info("Test admin auth user created", {uid});

    } else {

      throw new HttpsError("internal", "Failed to create auth user: " + err.message);

    }

  }



  // Set custom claims

  await admin.auth().setCustomUserClaims(uid, {roles: ["web_admin"], memberId: "test-admin"});



  // Create or update member document

  await db.collection("members").doc("test-admin").set({

    firstName: "MPYC",

    lastName: "Admin",

    email: testEmail,

    mobileNumber: "",

    memberNumber: "ADMIN-001",

    signalNumber: "001",

    membershipStatus: "active",

    membershipCategory: "Staff",

    memberTags: ["admin", "rc"],

    clubspotId: "",

    roles: ["web_admin"],

    firebaseUid: uid,

    lastSynced: admin.firestore.FieldValue.serverTimestamp(),

    lastLogin: admin.firestore.FieldValue.serverTimestamp(),

    emergencyContact: {name: "", phone: ""},

    isActive: true,

  }, {merge: true});



  logger.info("Test admin seeded", {uid, email: testEmail});

  return {

    email: testEmail,

    password: testPassword,

    uid,

    message: "Test admin created. Sign in at the web dashboard.",

  };

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



  const input = memberNumber.trim();



  // Try to find member by: signal number, membership number, or email

  let membersSnap;



  // 1. Try signal number first (pure digits, short)

  membersSnap = await db

    .collection("members")

    .where("signalNumber", "==", input)

    .limit(1)

    .get();



  // 2. Try membership number

  if (membersSnap.empty) {

    membersSnap = await db

      .collection("members")

      .where("memberNumber", "==", input)

      .limit(1)

      .get();

  }



  // 3. Try email

  if (membersSnap.empty && input.includes("@")) {

    membersSnap = await db

      .collection("members")

      .where("email", "==", input.toLowerCase())

      .limit(1)

      .get();

  }



  if (membersSnap.empty) {

    throw new HttpsError("not-found", "No member found. Try your signal #, membership #, or email.");

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



      // SMS for race-day course selection

      if (member.mobileNumber || member.phone) {

        try {

          await sendSmsInternal({

            to: member.mobileNumber || member.phone,

            message: smsMsg,

            eventId,

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



      // SMS for race-day fleet broadcast

      if (member.mobileNumber || member.phone) {

        try {

          await sendSmsInternal({

            to: member.mobileNumber || member.phone,

            message,

            eventId,

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



// ══════════════════════════════════════════════════════

// Incident & Protest Notifications

// ══════════════════════════════════════════════════════



// notifyIncidentReported — Firestore trigger when new incident is created

exports.notifyIncidentReported = onDocumentCreated("incidents/{incidentId}", async (event) => {

  const incidentId = event.params.incidentId;

  const data = event.data.data();

  if (!data) return;



  const eventId = data.eventId || "";

  const raceNumber = data.raceNumber || 0;

  const description = data.description || "";

  const boats = (data.involvedBoats || []).map(b => `${b.sailNumber} (${b.boatName})`).join(" vs ");

  const rules = (data.rulesAlleged || []).map(r => r.split(" – ")[0]).join(", ");



  logger.info("Incident reported", { incidentId, eventId, boats });



  try {

    // Notify all admins/PRO

    const adminsSnap = await db.collection("members")

      .where("role", "in", ["admin", "pro", "rc"])

      .get();



    let pushSent = 0;

    let smsSent = 0;



    const pushTitle = `Incident: ${boats}`;

    const pushBody = `Race ${raceNumber} — ${description.substring(0, 100)}${description.length > 100 ? "..." : ""}`;

    const smsMsg = `MPYC RC: Incident reported — ${boats}. Race ${raceNumber}. ${rules ? "Rules: " + rules + ". " : ""}${description.substring(0, 120)}`;



    for (const adminDoc of adminsSnap.docs) {

      const adminData = adminDoc.data();



      // FCM push

      if (adminData.fcmToken) {

        try {

          await admin.messaging().send({

            token: adminData.fcmToken,

            notification: { title: pushTitle, body: pushBody },

            data: {

              type: "incident_reported",

              incidentId,

              eventId,

              screen: `/incidents/detail/${incidentId}`,

            },

          });

          pushSent++;

        } catch (pushErr) {

          logger.error("Incident push failed", { adminId: adminDoc.id, error: pushErr.message });

        }

      }



      // Email

      if (adminData.email) {

        try {

          await sendEmailInternal({

            to: adminData.email,

            subject: `Incident Reported: ${boats}`,

            message: smsMsg,

            eventId,

          });

          smsSent++;

        } catch (emailErr) {

          logger.error("Incident email failed", { adminId: adminDoc.id, error: emailErr.message });

        }

      }

    }



    logger.info("Incident notification sent", { incidentId, pushSent, emailSent: smsSent });

  } catch (err) {

    logger.error("notifyIncidentReported error", { error: err.message });

  }

});



// notifyHearingScheduled — triggered when incident hearing is updated

exports.notifyHearingScheduled = onDocumentUpdated("incidents/{incidentId}", async (event) => {

  const before = event.data.before.data();

  const after = event.data.after.data();



  // Only fire if hearing was just scheduled (scheduledAt changed)

  const beforeScheduled = before.hearing?.scheduledAt;

  const afterScheduled = after.hearing?.scheduledAt;



  if (!afterScheduled) return;

  if (beforeScheduled && beforeScheduled.toMillis() === afterScheduled.toMillis()) return;



  const incidentId = event.params.incidentId;

  const involvedBoats = after.involvedBoats || [];

  const raceNumber = after.raceNumber || 0;



  // Format hearing date

  const hearingDate = afterScheduled.toDate();

  const dateStr = hearingDate.toLocaleDateString("en-US", {

    weekday: "short", month: "short", day: "numeric",

    hour: "2-digit", minute: "2-digit",

  });

  const location = after.hearing?.location || "TBD";



  logger.info("Hearing scheduled", { incidentId, hearingDate: dateStr });



  try {

    // Notify all involved boats' skippers

    for (const boat of involvedBoats) {

      const boatId = boat.boatId;

      if (!boatId) continue;



      // Look up skipper from boats collection

      const boatDoc = await db.collection("boats").doc(boatId).get();

      if (!boatDoc.exists) continue;

      const boatData = boatDoc.data();

      const ownerName = boatData.ownerName || boat.skipperName;



      // Find member by name match (best effort)

      const membersSnap = await db.collection("members")

        .where("displayName", "==", ownerName)

        .limit(1)

        .get();



      if (membersSnap.empty) continue;

      const member = membersSnap.docs[0].data();



      const roleLabel = boat.role === "protesting" ? "Protesting Party" :

                         boat.role === "protested" ? "Protested Party" : "Witness";



      const smsMsg = `MPYC Protest Hearing: ${roleLabel} — Race ${raceNumber}, ${boat.sailNumber} (${boat.boatName}). Hearing: ${dateStr} at ${location}. Please attend.`;



      // FCM

      if (member.fcmToken) {

        try {

          await admin.messaging().send({

            token: member.fcmToken,

            notification: {

              title: "Protest Hearing Scheduled",

              body: `${dateStr} at ${location} — Race ${raceNumber}`,

            },

            data: {

              type: "hearing_scheduled",

              incidentId,

              screen: `/incidents/detail/${incidentId}`,

            },

          });

        } catch (e) {

          logger.error("Hearing push failed", { boatId, error: e.message });

        }

      }



      // Email

      if (member.email) {

        try {

          await sendEmailInternal({

            to: member.email,

            subject: `Protest Hearing Scheduled — Race ${raceNumber}`,

            message: smsMsg,

          });

        } catch (e) {

          logger.error("Hearing email failed", { boatId, error: e.message });

        }

      }

    }



    logger.info("Hearing notifications sent", { incidentId, boatCount: involvedBoats.length });

  } catch (err) {

    logger.error("notifyHearingScheduled error", { error: err.message });

  }

});



// ══════════════════════════════════════════════════════

// Clubspot Scores Integration

// ══════════════════════════════════════════════════════



// submitScore — push a finish time to Clubspot for a regatta

exports.submitClubspotScore = onCall(async (request) => {

  if (!request.auth) {

    throw new HttpsError("unauthenticated", "Authentication required");

  }



  const { finishTime, registrationId, raceNumber, eventId } = request.data || {};

  if (!finishTime || !registrationId || !raceNumber) {

    throw new HttpsError(

      "invalid-argument",

      "finishTime, registrationId, and raceNumber are required",

    );

  }



  const apiKey = process.env.CLUBSPOT_API_KEY;

  if (!apiKey) {

    throw new HttpsError("failed-precondition", "CLUBSPOT_API_KEY not configured");

  }



  try {

    const result = await clubspotRequest("/scores", {

      apiKey,

      method: "POST",

      body: {

        finish_time: finishTime,

        registration_id: registrationId,

        race_number: raceNumber,

      },

    });



    // Log the score submission

    await db.collection("clubspot_score_logs").add({

      finishTime,

      registrationId,

      raceNumber,

      eventId: eventId || null,

      submittedBy: request.auth.uid,

      clubspotResponse: result,

      createdAt: admin.firestore.FieldValue.serverTimestamp(),

    });



    logger.info("Clubspot score submitted", { registrationId, raceNumber });

    return { success: true, data: result };

  } catch (error) {

    logger.error("Clubspot score submission failed", { error: error.message });

    throw new HttpsError("internal", error.message || "Score submission failed");

  }

});



// submitBatchScores — push multiple finish times at once

exports.submitClubspotBatchScores = onCall(async (request) => {

  if (!request.auth) {

    throw new HttpsError("unauthenticated", "Authentication required");

  }



  const { scores, eventId } = request.data || {};

  if (!Array.isArray(scores) || scores.length === 0) {

    throw new HttpsError("invalid-argument", "scores array is required");

  }



  const apiKey = process.env.CLUBSPOT_API_KEY;

  if (!apiKey) {

    throw new HttpsError("failed-precondition", "CLUBSPOT_API_KEY not configured");

  }



  let submitted = 0;

  const errors = [];



  for (const score of scores) {

    const { finishTime, registrationId, raceNumber } = score;

    if (!finishTime || !registrationId || !raceNumber) {

      errors.push(`Missing fields for registration ${registrationId || "unknown"}`);

      continue;

    }



    try {

      await clubspotRequest("/scores", {

        apiKey,

        method: "POST",

        body: {

          finish_time: finishTime,

          registration_id: registrationId,

          race_number: raceNumber,

        },

      });

      submitted++;

    } catch (error) {

      errors.push(`${registrationId} R${raceNumber}: ${error.message}`);

    }

  }



  // Log batch submission

  await db.collection("clubspot_score_logs").add({

    batchSize: scores.length,

    submitted,

    errors,

    eventId: eventId || null,

    submittedBy: request.auth.uid,

    createdAt: admin.firestore.FieldValue.serverTimestamp(),

  });



  logger.info("Clubspot batch scores submitted", { submitted, errors: errors.length });

  return { submitted, errors };

});



// ══════════════════════════════════════════════════════

// Clubspot Line Items (billing activity)

// ══════════════════════════════════════════════════════



exports.syncClubspotLineItems = onCall(async (request) => {

  if (!request.auth) {

    throw new HttpsError("unauthenticated", "Authentication required");

  }



  const { startDate, endDate } = request.data || {};

  if (!startDate || !endDate) {

    throw new HttpsError("invalid-argument", "startDate and endDate are required (ISO format)");

  }



  const apiKey = process.env.CLUBSPOT_API_KEY;

  const clubId = process.env.CLUBSPOT_CLUB_ID;

  if (!apiKey) {

    throw new HttpsError("failed-precondition", "CLUBSPOT_API_KEY not configured");

  }



  try {

    const items = [];

    let hasMore = true;

    let skip = 0;



    while (hasMore) {

      const result = await clubspotRequest(

        `/line-items?start_date=${encodeURIComponent(startDate)}&end_date=${encodeURIComponent(endDate)}&club_id=${encodeURIComponent(clubId || "")}&skip=${skip}`,

        { apiKey },

      );



      const rows = result.line_items || result.data?.line_items || [];

      items.push(...rows);

      hasMore = result.has_more === true || (result.data?.has_more === true);

      skip += rows.length;

      if (rows.length === 0) hasMore = false;

    }



    // Store in Firestore

    const batch = db.batch();

    for (const item of items) {

      const docId = item.id || `li_${Date.now()}_${Math.random().toString(36).slice(2)}`;

      const ref = db.collection("clubspot_line_items").doc(docId);

      batch.set(ref, {

        ...item,

        syncedAt: admin.firestore.FieldValue.serverTimestamp(),

      }, { merge: true });

    }

    await batch.commit();



    logger.info("Clubspot line items synced", { count: items.length });

    return { synced: items.length };

  } catch (error) {

    logger.error("Clubspot line items sync failed", { error: error.message });

    throw new HttpsError("internal", error.message || "Line items sync failed");

  }

});



// ══════════════════════════════════════════════════════════════════
// NOAA Weather — Live Wind Data (free, no API key required)
// ══════════════════════════════════════════════════════════════════

const NOAA_BASE_URL = "https://api.weather.gov";
const NOAA_USER_AGENT = "MPYCRaceDay/1.0 (contact@mpyc.org)";
const WEATHER_DOC_PATH = "weather/mpyc_station";
const MS_TO_KTS = 1.94384;
const MIN_FETCH_INTERVAL_MS = 30000; // 30 seconds rate limit

// Monterey Bay area
const STATION_LAT = 36.6002;
const STATION_LON = -121.8947;

const noaaHeaders = {
  "User-Agent": NOAA_USER_AGENT,
  "Accept": "application/geo+json",
};

async function fetchNoaaData() {
  // Step 1: Get nearest observation stations for this point
  const pointUrl = `${NOAA_BASE_URL}/points/${STATION_LAT},${STATION_LON}`;
  const pointResp = await fetch(pointUrl, { headers: noaaHeaders });
  if (!pointResp.ok) {
    throw new Error(`NOAA points API error ${pointResp.status}`);
  }
  const pointData = await pointResp.json();
  const stationsUrl = pointData?.properties?.observationStations;
  if (!stationsUrl) throw new Error("No observation stations URL from NOAA");

  // Step 2: Get station list
  const stationsResp = await fetch(stationsUrl, { headers: noaaHeaders });
  if (!stationsResp.ok) {
    throw new Error(`NOAA stations API error ${stationsResp.status}`);
  }
  const stationsData = await stationsResp.json();
  const features = stationsData?.features;
  if (!features || features.length === 0) {
    throw new Error("No NOAA observation stations found");
  }
  const stationId = features[0]?.properties?.stationIdentifier;
  const stationName = features[0]?.properties?.name || "NOAA Station";
  if (!stationId) throw new Error("No station identifier from NOAA");

  // Step 3: Get latest observation
  const obsUrl = `${NOAA_BASE_URL}/stations/${stationId}/observations/latest`;
  const obsResp = await fetch(obsUrl, { headers: noaaHeaders });
  if (!obsResp.ok) {
    throw new Error(`NOAA observation API error ${obsResp.status}`);
  }
  const obsData = await obsResp.json();
  const obs = obsData?.properties;
  if (!obs) throw new Error("No observation properties from NOAA");

  return { obs, stationId, stationName };
}

function normalizeNoaaObservation({ obs, stationName }) {
  // NOAA returns SI units: wind in m/s (km/h for some), temp in °C, pressure in Pa
  const windSpeedMs = obs.windSpeed?.value ?? 0;
  const windGustMs = obs.windGust?.value ?? null;
  const dirDeg = obs.windDirection?.value ?? 0;
  const tempC = obs.temperature?.value ?? null;
  const humidity = obs.relativeHumidity?.value ?? null;
  const pressurePa = obs.barometricPressure?.value ?? null;

  const speedKts = Math.round(windSpeedMs * MS_TO_KTS * 100) / 100;
  const speedMph = Math.round(speedKts / 0.868976 * 100) / 100;
  const gustKts = windGustMs !== null ? Math.round(windGustMs * MS_TO_KTS * 100) / 100 : null;
  const gustMph = gustKts !== null ? Math.round(gustKts / 0.868976 * 100) / 100 : null;
  const tempF = tempC !== null ? Math.round((tempC * 9 / 5 + 32) * 10) / 10 : null;
  const pressureInHg = pressurePa !== null ? Math.round(pressurePa / 100 * 0.02953 * 100) / 100 : null;

  // Parse observation timestamp
  let observedAt = admin.firestore.Timestamp.now();
  if (obs.timestamp) {
    const dt = new Date(obs.timestamp);
    if (!isNaN(dt.getTime())) {
      observedAt = admin.firestore.Timestamp.fromDate(dt);
    }
  }

  return {
    dirDeg: Math.round(dirDeg),
    speedMph,
    speedKts,
    gustMph,
    gustKts,
    tempF,
    humidity: humidity !== null ? Math.round(humidity) : null,
    pressureInHg,
    observedAt,
    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    source: "noaa",
    station: {
      name: stationName,
      lat: STATION_LAT,
      lon: STATION_LON,
    },
    error: null,
  };
}

async function doWeatherFetch() {
  // Rate limit: check last fetch time
  const docRef = db.doc(WEATHER_DOC_PATH);
  const existing = await docRef.get();

  if (existing.exists) {
    const lastFetched = existing.data()?.fetchedAt?.toMillis?.();
    if (lastFetched && Date.now() - lastFetched < MIN_FETCH_INTERVAL_MS) {
      logger.info("Weather fetch skipped — too recent", {
        lastFetched: new Date(lastFetched).toISOString(),
      });
      return { skipped: true, data: existing.data() };
    }
  }

  try {
    const noaaResult = await fetchNoaaData();
    const normalized = normalizeNoaaObservation(noaaResult);
    await docRef.set(normalized, { merge: true });
    logger.info("Weather updated from NOAA", { speedKts: normalized.speedKts, dirDeg: normalized.dirDeg });
    return { skipped: false, data: normalized };
  } catch (error) {
    // On error, keep last known data but record the error
    logger.error("NOAA weather fetch failed", { error: error.message });
    await docRef.set(
      {
        error: error.message || "Unknown fetch error",
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { skipped: false, error: error.message };
  }
}

// Scheduled: runs every 1 minute
exports.scheduledWeatherFetch = onSchedule(
  {
    schedule: "* * * * *",
    timeZone: "America/Los_Angeles",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async () => {
    const result = await doWeatherFetch();
    logger.info("scheduledWeatherFetch complete", result);
  },
);

// Callable: on-demand refresh (rate-limited server-side)
exports.refreshWeather = onCall(async (request) => {
  // Auth optional — allow unauthenticated for public weather display
  const result = await doWeatherFetch();
  if (result.skipped && result.data) {
    const d = result.data;
    return {
      dirDeg: d.dirDeg,
      speedMph: d.speedMph,
      speedKts: d.speedKts,
      gustMph: d.gustMph,
      gustKts: d.gustKts,
      observedAt: d.observedAt?.toMillis?.() || null,
      fetchedAt: d.fetchedAt?.toMillis?.() || null,
      cached: true,
    };
  }
  return { refreshed: !result.error, error: result.error || null };
});

