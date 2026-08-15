#!/usr/bin/env node
const https = require('https');
const crypto = require('crypto');
const fs = require('fs');

const PROJECT_ID = 'eventease-555';
const API_KEY = 'AIzaSyD5AZsjj9eg93EUlulXSc8yZTuNI_MBtWw';
const IT_HOST = 'identitytoolkit.googleapis.com';
const FS_HOST = 'firestore.googleapis.com';
const OAUTH_HOST = 'oauth2.googleapis.com';

const demoUsers = [
  { email: 'attendee@eventease.demo', password: 'Test123!', name: 'Alex Attendee', role: 'attendee' },
  { email: 'organizer@eventease.demo', password: 'Test123!', name: 'Olivia Organizer', role: 'organizer' },
  { email: 'admin@eventease.demo', password: 'Test123!', name: 'Adam Admin', role: 'admin' },
];

function request(host, method, path, body, headers) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: host,
      path,
      method,
      headers: { 'Content-Type': 'application/json', ...headers },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(JSON.parse(data || '{}')); } catch { resolve({}); }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function getAccessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = JSON.stringify({ alg: 'RS256', typ: 'JWT' });
  const payload = JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/datastore',
    aud: OAUTH_HOST,
    exp: now + 3600,
    iat: now,
  });
  const encoded = Buffer.from(header).toString('base64url') + '.' + Buffer.from(payload).toString('base64url');
  const signed = crypto.createSign('RSA-SHA256').update(encoded).sign(sa.private_key, 'base64');
  const assertion = encoded + '.' + signed;
  const res = await request(OAUTH_HOST, 'POST', '/token', null, {});
  // OAuth token endpoint expects form-encoded body
  return new Promise((resolve, reject) => {
    const req = https.request({ hostname: OAUTH_HOST, path: '/token', method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.write(`grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${assertion}`);
    req.end();
  });
}

async function createUser(email, password, name) {
  try {
    const res = await request(IT_HOST, 'POST', `/v1/accounts:signUp?key=${API_KEY}`, {
      email, password, displayName: name, returnSecureToken: false,
    });
    return { uid: res.localId, created: true };
  } catch (e) {
    if (e.message.includes('EMAIL_ALREADY_EXISTS')) return { uid: null, created: false };
    throw e;
  }
}

async function upsertUserDoc(token, uid, data) {
  const fields = {
    name: { stringValue: data.name },
    email: { stringValue: data.email },
    role: { stringValue: data.role },
    active: { booleanValue: true },
    organizerRequested: { booleanValue: false },
    remindersEnabled: { booleanValue: true },
  };
  try {
    await request(FS_HOST, 'POST', `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users?documentId=${uid}`, { fields }, { Authorization: `Bearer ${token}` });
  } catch {
    await request(FS_HOST, 'PATCH', `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=name&updateMask.fieldPaths=email&updateMask.fieldPaths=role&updateMask.fieldPaths=active&updateMask.fieldPaths=organizerRequested&updateMask.fieldPaths=remindersEnabled`, { fields }, { Authorization: `Bearer ${token}` });
  }
}

async function getUserUid(token, email) {
  const encoded = Buffer.from(`user:${email}`).toString('base64');
  const res = await adminSdkRequest(token, `users/${encoded}`, 'GET');
  return res?.localId;
}

function adminSdkRequest(token, path, method) {
  return request('identitytoolkit.googleapis.com', method, `/admin/v2/projects/${PROJECT_ID}/${path}`, null, { Authorization: `Bearer ${token}`, 'X-Goog-Use-CriticalIfAny': 'true' });
}

async function main() {
  const saPath = process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!saPath || !fs.existsSync(saPath)) {
    console.error('Usage: node seed.js <path-to-service-account.json>');
    console.error('Or set GOOGLE_APPLICATION_CREDENTIALS env var.');
    process.exit(1);
  }
  const sa = JSON.parse(fs.readFileSync(saPath, 'utf8'));
  const token = (await getAccessToken(sa)).access_token;

  console.log('Creating demo accounts...\n');

  for (const user of demoUsers) {
    const { uid: newUid, created } = await createUser(user.email, user.password, user.name);
    if (created) {
      await upsertUserDoc(token, newUid, user);
      console.log(`Created: ${user.email} (role: ${user.role})`);
    } else {
      const uid = await getUserUid(token, user.email);
      await upsertUserDoc(token, uid, user);
      console.log(`Updated: ${user.email} (role: ${user.role})`);
    }
  }

  console.log('\n=== Demo Credentials ===');
  console.log('  Attendee  | attendee@eventease.demo | Test123! | Alex Attendee');
  console.log('  Organizer | organizer@eventease.demo | Test123! | Olivia Organizer');
  console.log('  Admin     | admin@eventease.demo     | Test123! | Adam Admin');
  console.log('\nAdmin login: admin@eventease.demo / Test123!');
}

main().catch((e) => { console.error(e); process.exit(1); });
