const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

const db = admin.firestore();

async function sendPushToMember({memberId, title, body, deepLink}) {
  const memberSnap = await db.collection("members").doc(memberId).get();
  const token = memberSnap.data()?.pushToken;
  if (!token) return;

  await admin.messaging().send({
    token,
    notification: {title, body},
    data: {deepLink},
  });
}

async function sendSmsToMember({memberId, message}) {
  logger.info("SMS placeholder", {memberId, message});
}

exports.sendCrewNotification = onDocumentWritten(
  "raceEvents/{eventId}",
  async (event) => {
    const after = event.data.after?.data();
    if (!after) return;

    const crewSlots = after.crewSlots || [];
    const eventName = after.name || "Race Event";
    const eventDate = after.date?.toDate ? after.date.toDate() : new Date(after.date);
    const dateText = eventDate.toLocaleDateString("en-US");

    await Promise.all(
      crewSlots
        .filter((slot) => !!slot.memberId)
        .map(async (slot) => {
          const role = slot.role || "crew";
          const deepLink = `mpycraceday://schedule/event/${event.params.eventId}`;
          const body = `${eventName} on ${dateText} as ${role}. Tap to confirm.`;

          await sendPushToMember({
            memberId: slot.memberId,
            title: "RC Assignment Updated",
            body,
            deepLink,
          });
          await sendSmsToMember({memberId: slot.memberId, message: body});
        }),
    );
  },
);

exports.sendCrewReminders = onSchedule("every day 08:00", async () => {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const end = new Date(start);
  end.setDate(end.getDate() + 8);

  const eventsSnap = await db
    .collection("raceEvents")
    .where("date", ">=", start)
    .where("date", "<=", end)
    .get();

  await Promise.all(
    eventsSnap.docs.map(async (doc) => {
      const data = doc.data();
      const eventDate = data.date?.toDate ? data.date.toDate() : new Date(data.date);
      const diffDays = Math.floor((eventDate - start) / (1000 * 60 * 60 * 24));

      let prefix = "";
      if (diffDays === 7) {
        prefix = "You're assigned to RC in one week";
      } else if (diffDays === 1) {
        prefix = "Reminder: RC duty tomorrow";
      } else if (diffDays === 0) {
        prefix = "Race day!";
      } else {
        return;
      }

      const crewSlots = data.crewSlots || [];
      await Promise.all(
        crewSlots
          .filter((slot) => !!slot.memberId)
          .map(async (slot) => {
            const role = slot.role || "crew";
            const deepLink = `mpycraceday://schedule/event/${doc.id}`;
            const message = `${prefix} ${data.name} on ${eventDate.toLocaleDateString("en-US")} as ${role}.`;

            await sendPushToMember({
              memberId: slot.memberId,
              title: "RC Reminder",
              body: message,
              deepLink,
            });
            await sendSmsToMember({memberId: slot.memberId, message});
          }),
      );
    }),
  );
});