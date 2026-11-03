// Adds "symptoms" (array) and "category" (text) to every medication in Firestore.
//
// Usage (run in this folder):
//   node tag-symptoms.js --dry-run      -> shows what WOULD change, writes nothing
//   node tag-symptoms.js                -> writes the changes (skips medicines that already have symptoms)
//   node tag-symptoms.js --overwrite    -> writes the changes even if symptoms already exist
//
// Needs firebase-service-account.json in this same folder (never share or commit it).

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const DRY_RUN = process.argv.includes("--dry-run");
const OVERWRITE = process.argv.includes("--overwrite");

const keyPath = path.join(__dirname, "firebase-service-account.json");
if (!fs.existsSync(keyPath)) {
  console.error("Missing firebase-service-account.json - put your key in this folder.");
  process.exit(1);
}

const { allowedSymptoms, rules } = JSON.parse(
  fs.readFileSync(path.join(__dirname, "symptoms-data.json"), "utf8")
);

// Catch typos in the data file so spelling stays consistent in the database.
const allowed = new Set(allowedSymptoms);
for (const rule of rules) {
  for (const s of rule.symptoms) {
    if (!allowed.has(s)) {
      console.error(`Rule "${rule.match}" uses "${s}" which is not in allowedSymptoms. Fix symptoms-data.json first.`);
      process.exit(1);
    }
  }
}

admin.initializeApp({ credential: admin.credential.cert(require(keyPath)) });
const db = admin.firestore();

// Uses "medications"; falls back to the old " medications" (leading space) if that's where the data still is.
async function medicationsCollection() {
  const main = await db.collection("medications").limit(1).get();
  if (!main.empty) return db.collection("medications");
  const old = await db.collection(" medications").limit(1).get();
  if (!old.empty) {
    console.log('Note: using the old collection " medications" (leading space).');
    return db.collection(" medications");
  }
  return db.collection("medications");
}

async function main() {
  const col = await medicationsCollection();
  const snapshot = await col.get();
  if (snapshot.empty) {
    console.log("No medications found.");
    return;
  }

  let tagged = 0;
  let skipped = 0;
  const noRule = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const name = String(data.name || "").toLowerCase();

    if (!OVERWRITE && Array.isArray(data.symptoms) && data.symptoms.length > 0) {
      skipped++;
      continue;
    }

    const rule = rules.find((r) => name.includes(r.match));
    if (!rule) {
      noRule.push(data.name || doc.id);
      continue;
    }

    const update = { symptoms: rule.symptoms, category: rule.category };
    if (rule.prescription_required) update.prescription_required = true;

    console.log(`${DRY_RUN ? "[dry run] " : ""}${data.name || doc.id} -> ${rule.category}: ${rule.symptoms.join(", ")}`);
    if (!DRY_RUN) await doc.ref.update(update);
    tagged++;
  }

  console.log(`\nDone. ${DRY_RUN ? "Would tag" : "Tagged"}: ${tagged}, skipped (already tagged): ${skipped}`);
  if (noRule.length > 0) {
    console.log("No rule for these - add one to symptoms-data.json or tag by hand in the console:");
    noRule.forEach((n) => console.log("  - " + n));
  }
}

main().catch((err) => {
  console.error("Something went wrong:", err.message);
  process.exit(1);
});
