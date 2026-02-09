// Seed test admin using Firebase Admin SDK directly
// Usage: node scripts/seed_admin_local.js
//
// Requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account key,
// or run after: npx firebase-tools login

const admin = require("firebase-admin");

// Initialize with project ID — will use Application Default Credentials
admin.initializeApp({ projectId: "mpyc-raceday" });

const db = admin.firestore();

async function seedAdmin() {
  const testEmail = "admin@mpyc.org";
  const testPassword = "RaceDay2024!";

  let uid;
  try {
    const existing = await admin.auth().getUserByEmail(testEmail);
    uid = existing.uid;
    await admin.auth().updateUser(uid, { password: testPassword });
    console.log("Auth user already exists, password updated. UID:", uid);
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      const newUser = await admin.auth().createUser({
        email: testEmail,
        password: testPassword,
        displayName: "MPYC Admin",
      });
      uid = newUser.uid;
      console.log("Auth user created. UID:", uid);
    } else {
      console.error("Auth error:", err.message);
      process.exit(1);
    }
  }

  // Set custom claims
  await admin.auth().setCustomUserClaims(uid, { role: "admin", memberId: "test-admin" });
  console.log("Custom claims set.");

  // Create member document
  await db.collection("members").doc("test-admin").set({
    firstName: "MPYC",
    lastName: "Admin",
    email: testEmail,
    mobileNumber: "",
    memberNumber: "ADMIN-001",
    membershipStatus: "active",
    membershipCategory: "Staff",
    memberTags: ["admin", "rc"],
    clubspotId: "",
    role: "admin",
    firebaseUid: uid,
    lastSynced: admin.firestore.FieldValue.serverTimestamp(),
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    emergencyContact: { name: "", phone: "" },
  }, { merge: true });

  console.log("Member document created/updated.");
  console.log("");
  console.log("=== Test Admin Credentials ===");
  console.log("Email:    " + testEmail);
  console.log("Password: " + testPassword);
  console.log("==============================");

  process.exit(0);
}

seedAdmin().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
