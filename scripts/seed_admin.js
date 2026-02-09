// Quick script to call the seedTestAdmin Cloud Function
// Usage: node scripts/seed_admin.js

const https = require("https");

const PROJECT_ID = "mpyc-raceday";
const REGION = "us-central1";
const FUNCTION_NAME = "seedTestAdmin";

const url = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${FUNCTION_NAME}`;

const postData = JSON.stringify({ data: {} });

const options = {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(postData),
  },
};

console.log(`Calling ${url}...`);

const req = https.request(url, options, (res) => {
  let body = "";
  res.on("data", (chunk) => (body += chunk));
  res.on("end", () => {
    console.log(`Status: ${res.statusCode}`);
    try {
      const parsed = JSON.parse(body);
      console.log(JSON.stringify(parsed, null, 2));
    } catch {
      console.log(body);
    }
  });
});

req.on("error", (e) => console.error("Error:", e.message));
req.write(postData);
req.end();
