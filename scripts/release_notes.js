'use strict';

// Catatan "Apa yang baru" (ADR-039 §3.3): validasi berkas `release_notes/`,
// sinkronisasi ke Firebase Remote Config (satu parameter per entri), dan
// pembersihan saat build gagal. Pemeriksaan di sini sama dengan uji Dart
// `test/release/release_notes_files_test.dart`.
//
// Pakai:
//   node scripts/release_notes.js validate --build 7 --patch 0
//   node scripts/release_notes.js publish
//   node scripts/release_notes.js cleanup --build 7 --patch 0

const fs = require('fs');
const path = require('path');

const KEY_PREFIX = 'whats_new_';
const CATEGORIES = ['new', 'faster', 'fixed', 'security'];
const MAX_NOTES = 3;
const MAX_ATTEMPTS = 3;
const BANNED_ID = /!|\b(anda|patch|tambalan|bug)\b/i;

const paramName = (build, patch) => `${KEY_PREFIX}${build}_${patch}`;

/** Nama berkas `<build>-<patch>.json` -> {build, patch}, atau null. */
function parseFileName(name) {
  const m = /^(\d+)-(\d+)\.json$/.exec(name);
  return m ? { build: Number(m[1]), patch: Number(m[2]) } : null;
}

/** Versi dan build dari `version: 0.6.0+7` di teks pubspec. */
function readPubspec(text) {
  const m = /^version:\s*(\S+)\+(\d+)/m.exec(text);
  if (!m) throw new Error('version: tidak ditemukan di pubspec.yaml');
  return { version: m[1], build: Number(m[2]) };
}

/**
 * Memeriksa isi satu berkas catatan. Mengembalikan daftar masalah (kosong =
 * sah). `pubspecVersion` opsional: bila ada, `version` harus sama.
 */
function validateNote(raw, { pubspecVersion } = {}) {
  const problems = [];
  let note;
  try {
    note = JSON.parse(raw);
  } catch (e) {
    return ['JSON tidak sah'];
  }
  if (typeof note !== 'object' || note === null || Array.isArray(note)) return ['isi harus objek'];
  if (typeof note.version !== 'string' || note.version === '') problems.push('version wajib berupa teks');
  else if (pubspecVersion && note.version !== pubspecVersion) {
    problems.push(`version "${note.version}" tidak sama dengan pubspec.yaml "${pubspecVersion}"`);
  }
  if (!Array.isArray(note.groups)) return [...problems, 'groups wajib berupa daftar'];
  const seen = new Set();
  let count = 0;
  for (const group of note.groups) {
    if (typeof group !== 'object' || group === null || !Array.isArray(group.notes)) {
      problems.push('tiap kelompok butuh category dan notes');
      continue;
    }
    if (!CATEGORIES.includes(group.category)) problems.push(`kategori "${group.category}" tidak dikenal`);
    if (seen.has(group.category)) problems.push(`kategori "${group.category}" ganda (satu kelompok per kategori)`);
    seen.add(group.category);
    for (const item of group.notes) {
      count += 1;
      const id = item && item.id;
      const en = item && item.en;
      if (typeof id !== 'string' || id.trim() === '') problems.push('butir tanpa teks id');
      else if (BANNED_ID.test(id)) problems.push(`teks id memuat kata terlarang: "${id}"`);
      if (typeof en !== 'string' || en.trim() === '') problems.push('butir tanpa teks en');
      else if (en.includes('!')) problems.push(`teks en memuat tanda seru: "${en}"`);
    }
  }
  if (count < 1) problems.push('catatan wajib: minimal satu butir untuk setiap build yang dipublikasikan');
  if (count > MAX_NOTES) problems.push(`paling banyak ${MAX_NOTES} butir (ada ${count})`);
  return problems;
}

/** Membaca semua `release_notes/<build>-<patch>.json` menjadi {name -> json ringkas}. */
function loadEntries(dir) {
  const entries = {};
  for (const file of fs.readdirSync(dir)) {
    const key = parseFileName(file);
    if (!key) continue;
    const raw = fs.readFileSync(path.join(dir, file), 'utf8');
    entries[paramName(key.build, key.patch)] = JSON.stringify(JSON.parse(raw));
  }
  return entries;
}

/** Pemeriksaan sebelum build: berkas build/patch ini wajib ada dan sah. */
function validateForRelease({ dir, build, patch, pubspecText }) {
  const pubspec = readPubspec(pubspecText);
  const problems = [];
  if (patch === 0 && build !== pubspec.build) {
    problems.push(`build ${build} tidak sama dengan pubspec.yaml (${pubspec.build})`);
  }
  const file = path.join(dir, `${build}-${patch}.json`);
  if (!fs.existsSync(file)) {
    problems.push(`${file} belum ada (catatan wajib untuk setiap build yang dipublikasikan)`);
    return problems;
  }
  return [...problems, ...validateNote(fs.readFileSync(file, 'utf8'), { pubspecVersion: pubspec.version })];
}

const isConflict = (e) => /precondition|version-mismatch|etag/i.test(`${(e && e.code) || ''} ${(e && e.message) || ''}`);

/**
 * Menyamakan parameter `whats_new_*` di Remote Config dengan `entries`
 * (menambah, menimpa, menghapus yang tanpa berkas), mengulang bila ETag
 * bentrok, lalu membaca balik dan memastikan isinya sama. Melempar bila gagal.
 */
async function syncTemplate(rc, entries, { remove = null } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    try {
      const template = await rc.getTemplate();
      template.parameters = template.parameters || {};
      const expected = remove ? null : entries;
      for (const name of Object.keys(template.parameters)) {
        const stale = remove ? remove.includes(name) : name.startsWith(KEY_PREFIX) && !(name in entries);
        if (stale) delete template.parameters[name];
      }
      if (!remove) {
        for (const [name, value] of Object.entries(entries)) {
          template.parameters[name] = { defaultValue: { value }, description: 'Catatan Apa yang baru (release_notes/)' };
        }
      }
      const validated = await rc.validateTemplate(template);
      await rc.publishTemplate(validated);
      const back = await rc.getTemplate();
      for (const [name, value] of Object.entries(expected || {})) {
        const got = back.parameters && back.parameters[name] && back.parameters[name].defaultValue;
        if (!got || got.value !== value) throw new Error(`pembacaan balik gagal untuk ${name}`);
      }
      for (const name of remove || []) {
        if (back.parameters && back.parameters[name]) throw new Error(`${name} masih ada setelah dihapus`);
      }
      return;
    } catch (e) {
      lastError = e;
      if (!isConflict(e) && !/pembacaan balik/.test(String(e && e.message))) break;
    }
  }
  throw lastError;
}

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

function remoteConfigFromEnv() {
  const admin = require('firebase-admin');
  const account = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
  if (account.private_key) account.private_key = account.private_key.replace(/\\n/g, '\n');
  admin.initializeApp({ credential: admin.credential.cert(account) });
  return admin.remoteConfig();
}

async function main() {
  const command = process.argv[2];
  const dir = path.join(__dirname, '..', 'release_notes');
  if (command === 'validate') {
    const problems = validateForRelease({
      dir,
      build: Number(arg('build')),
      patch: Number(arg('patch') || 0),
      pubspecText: fs.readFileSync(path.join(__dirname, '..', 'pubspec.yaml'), 'utf8'),
    });
    if (problems.length) {
      console.error(`Catatan rilis tidak lolos:\n- ${problems.join('\n- ')}`);
      process.exit(1);
    }
    console.log('Catatan rilis sah.');
  } else if (command === 'publish') {
    const entries = loadEntries(dir);
    await syncTemplate(remoteConfigFromEnv(), entries);
    console.log(`Remote Config disamakan: ${Object.keys(entries).length} entri.`);
  } else if (command === 'cleanup') {
    // Saat build gagal: hapus entri milik eksekusi ini, sebisanya. Gagal di
    // sini tidak boleh menimpa kegagalan aslinya; sinkronisasi berikutnya
    // membersihkan sisa entri yatim.
    try {
      await syncTemplate(remoteConfigFromEnv(), {}, { remove: [paramName(Number(arg('build')), Number(arg('patch') || 0))] });
      console.log('Entri catatan eksekusi ini dihapus.');
    } catch (e) {
      console.warn(`Pembersihan gagal (diabaikan): ${e.message}`);
    }
  } else {
    console.error('Perintah: validate | publish | cleanup');
    process.exit(2);
  }
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}

module.exports = { KEY_PREFIX, paramName, parseFileName, readPubspec, validateNote, loadEntries, validateForRelease, syncTemplate };
