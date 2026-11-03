// Tags medicine documents in Firestore with general search terms.
// Run with: node tag-symptoms.js --dry-run
// Requires firebase-service-account.json in this folder.
const admin = require('firebase-admin');
const fs = require('fs');
const dryRun = process.argv.includes('--dry-run');
const key = JSON.parse(fs.readFileSync('firebase-service-account.json', 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(key), storageBucket: 'reliefroute-90279.firebasestorage.app' });
const db = admin.firestore();
const tags = {
  'Paracetamol 500mg': ['headache', 'pain', 'fever'],
  'Allergy Relief': ['allergy', 'sneezing', 'itchy eyes'],
  'Cough Calm Syrup': ['cough', 'cold', 'flu'],
  'Vitamin C 1000mg': ['vitamins', 'immune support']
};
(async () => {
  const snapshot = await db.collection('medications').get();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const symptoms = tags[data.name] || [];
    console.log(`${dryRun ? '[dry-run] ' : ''}${doc.id}: ${symptoms.join(', ')}`);
    if (!dryRun) await doc.ref.set({ symptoms }, { merge: true });
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
