// Seed test admin: creates Auth user + sets claims + writes Firestore member doc
// Usage: node scripts/seed_admin.js
//
// Uses Firebase CLI refresh token for Auth, and calls the deployed
// seedTestAdmin Cloud Function for the Firestore write.

const path = require("path");
const os = require("os");
const fs = require("fs");

const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

// Load Firebase CLI refresh token
const winPath = path.join(process.env.APPDATA || "", "configstore", "firebase-tools.json");
const nixPath = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
const configPath = fs.existsSync(winPath) ? winPath : nixPath;

if (!fs.existsSync(configPath)) {
  console.error("Firebase CLI credentials not found. Run: npx firebase-tools login");
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const refreshToken = config.tokens?.refresh_token;
if (!refreshToken) {
  console.error("No refresh token found. Run: npx firebase-tools login");
  process.exit(1);
}

const credential = admin.credential.refreshToken({
  type: "authorized_user",
  client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
  client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
  refresh_token: refreshToken,
});

admin.initializeApp({ credential, projectId: "mpyc-raceday" });

async function seed() {
  const testEmail = "admin@mpyc.org";
  const testPassword = "RaceDay2024!";

  // Step 1: Create or update Auth user
  let uid;
  try {
    const existing = await admin.auth().getUserByEmail(testEmail);
    uid = existing.uid;
    await admin.auth().updateUser(uid, { password: testPassword });
    console.log("Auth user exists, password reset. UID:", uid);
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
      throw err;
    }
  }

  // Step 2: Set custom claims
  await admin.auth().setCustomUserClaims(uid, { role: "admin", memberId: "test-admin" });
  console.log("Custom claims set (role: admin).");

  // Step 3: Write Firestore member docs via REST API using access token.
  // Write to BOTH /members/test-admin (canonical) AND /members/{uid}
  // so Firestore rules getMember() (which looks up by auth UID) works.
  const accessToken = (await credential.getAccessToken()).access_token;

  const firestoreDoc = {
    fields: {
      firstName: { stringValue: "MPYC" },
      lastName: { stringValue: "Admin" },
      email: { stringValue: testEmail },
      mobileNumber: { stringValue: "" },
      memberNumber: { stringValue: "ADMIN-001" },
      membershipStatus: { stringValue: "active" },
      membershipCategory: { stringValue: "Staff" },
      memberTags: { arrayValue: { values: [{ stringValue: "admin" }, { stringValue: "rc" }] } },
      clubspotId: { stringValue: "" },
      roles: { arrayValue: { values: [{ stringValue: "web_admin" }] } },
      firebaseUid: { stringValue: uid },
      isActive: { booleanValue: true },
      emergencyContact: { mapValue: { fields: { name: { stringValue: "" }, phone: { stringValue: "" } } } },
    },
  };

  const fieldPaths = Object.keys(firestoreDoc.fields)
    .map((f) => `updateMask.fieldPaths=${f}`)
    .join("&");

  // Write canonical doc at /members/test-admin
  const canonicalUrl = `https://firestore.googleapis.com/v1/projects/mpyc-raceday/databases/(default)/documents/members/test-admin`;
  const resp1 = await fetch(`${canonicalUrl}?${fieldPaths}`, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(firestoreDoc),
  });
  if (!resp1.ok) {
    const errBody = await resp1.text();
    throw new Error(`Firestore write (canonical) failed (${resp1.status}): ${errBody}`);
  }
  console.log("Firestore member doc written at /members/test-admin");

  // Write UID-keyed doc at /members/{uid} for Firestore rules lookup
  const uidUrl = `https://firestore.googleapis.com/v1/projects/mpyc-raceday/databases/(default)/documents/members/${uid}`;
  const resp2 = await fetch(`${uidUrl}?${fieldPaths}`, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(firestoreDoc),
  });
  if (!resp2.ok) {
    const errBody = await resp2.text();
    throw new Error(`Firestore write (UID) failed (${resp2.status}): ${errBody}`);
  }
  console.log(`Firestore member doc written at /members/${uid}`);

  console.log("\n=== Test Admin Seeded ===");
  console.log("Email:    " + testEmail);
  console.log("Password: " + testPassword);
  console.log("UID:      " + uid);
  console.log("Login at: https://mpyc-raceday.web.app");
  console.log("========================\n");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});
