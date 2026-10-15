'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { PLAY_LIMIT, formatPlayChangelog, validateNote, validateForRelease, loadEntries, syncTemplate, paramName, parseFileName } = require('./release_notes');

const good = {
  version: '0.6.0',
  groups: [
    { category: 'new', notes: [{ id: 'Satu.', en: 'One.' }, { id: 'Dua.', en: 'Two.' }] },
    { category: 'fixed', notes: [{ id: 'Tiga.', en: 'Three.' }] },
  ],
};
const json = (o) => JSON.stringify(o);

test('berkas yang sah lolos', () => {
  assert.deepEqual(validateNote(json(good), { pubspecVersion: '0.6.0' }), []);
});

test('catatan wajib: tanpa butir ditolak', () => {
  assert.match(validateNote(json({ version: '0.6.0', groups: [] })).join(), /minimal satu butir/);
});

test('lebih dari 3 butir ditolak', () => {
  const four = { version: '0.6.0', groups: [{ category: 'new', notes: Array(4).fill({ id: 'A.', en: 'A.' }) }] };
  assert.match(validateNote(json(four)).join(), /paling banyak 3/);
});

test('kategori tak dikenal dan ganda ditolak', () => {
  const bad = { version: '0.6.0', groups: [{ category: 'x', notes: [{ id: 'A.', en: 'A.' }] }] };
  assert.match(validateNote(json(bad)).join(), /tidak dikenal/);
  const dup = { version: '0.6.0', groups: [good.groups[0], good.groups[0]] };
  assert.match(validateNote(json(dup)).join(), /ganda/);
});

test('kata terlarang di teks id dan tanda seru di en ditolak', () => {
  for (const id of ['Hebat!', 'Anda bisa.', 'Ada patch baru.', 'Tambalan siap.', 'Bug hilang.']) {
    const note = { version: '0.6.0', groups: [{ category: 'fixed', notes: [{ id, en: 'Ok.' }] }] };
    assert.ok(validateNote(json(note)).length > 0, id);
  }
  const en = { version: '0.6.0', groups: [{ category: 'fixed', notes: [{ id: 'Oke.', en: 'Great!' }] }] };
  assert.match(validateNote(json(en)).join(), /tanda seru/);
});

test('versi harus sama dengan pubspec; JSON rusak ditolak', () => {
  assert.match(validateNote(json(good), { pubspecVersion: '0.7.0' }).join(), /tidak sama dengan pubspec/);
  assert.deepEqual(validateNote('bukan json'), ['JSON tidak sah']);
});

test('parseFileName', () => {
  assert.deepEqual(parseFileName('7-0.json'), { build: 7, patch: 0 });
  assert.equal(parseFileName('id.md'), null);
});

function tempDir(files) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'notes-'));
  for (const [name, content] of Object.entries(files)) fs.writeFileSync(path.join(dir, name), content);
  return dir;
}

const pubspec = 'name: x\nversion: 0.6.0+7\n';

test('validateForRelease: berkas build ini wajib ada', () => {
  const dir = tempDir({});
  assert.match(validateForRelease({ dir, build: 7, patch: 0, pubspecText: pubspec }).join(), /belum ada/);
});

test('validateForRelease: build rilis harus sama dengan pubspec', () => {
  const dir = tempDir({ '8-0.json': json(good) });
  assert.match(validateForRelease({ dir, build: 8, patch: 0, pubspecText: pubspec }).join(), /tidak sama dengan pubspec/);
});

test('validateForRelease: lolos untuk rilis dan untuk pembaruan kecil', () => {
  const dir = tempDir({ '7-0.json': json(good), '7-1.json': json(good) });
  assert.deepEqual(validateForRelease({ dir, build: 7, patch: 0, pubspecText: pubspec }), []);
  assert.deepEqual(validateForRelease({ dir, build: 7, patch: 1, pubspecText: pubspec }), []);
});

test('loadEntries: satu parameter per berkas, JSON ringkas; berkas lain diabaikan', () => {
  const dir = tempDir({ '7-0.json': JSON.stringify(good, null, 2), 'id.md': 'abaikan' });
  const entries = loadEntries(dir);
  assert.deepEqual(Object.keys(entries), ['whats_new_7_0']);
  assert.equal(entries.whats_new_7_0, json(good));
});

/** Remote Config palsu di memori. */
function fakeRc(initial = {}, { conflicts = 0, dropWrites = false } = {}) {
  let remaining = conflicts;
  let published = { parameters: structuredClone(initial) };
  return {
    published: () => published,
    async getTemplate() {
      return structuredClone(published);
    },
    async validateTemplate(t) {
      return t;
    },
    async publishTemplate(t) {
      if (remaining > 0) {
        remaining -= 1;
        const e = new Error('ETag mismatch');
        e.code = 'remote-config/failed-precondition';
        throw e;
      }
      if (!dropWrites) published = structuredClone(t);
      return t;
    },
  };
}

const p = (value) => ({ defaultValue: { value } });

test('syncTemplate: menambah, menimpa, dan menghapus entri tanpa berkas; parameter lain utuh', async () => {
  const rc = fakeRc({
    other_flag: p('x'),
    whats_new_6_0: p('lama'),
    whats_new_9_0: p('yatim'),
  });
  await syncTemplate(rc, { whats_new_6_0: 'baru6', whats_new_7_0: 'baru7' });
  const params = rc.published().parameters;
  assert.equal(params.whats_new_6_0.defaultValue.value, 'baru6');
  assert.equal(params.whats_new_7_0.defaultValue.value, 'baru7');
  assert.equal(params.whats_new_9_0, undefined, 'entri yatim dihapus');
  assert.equal(params.other_flag.defaultValue.value, 'x');
});

test('syncTemplate: mengulang saat ETag bentrok (maksimal 3 percobaan)', async () => {
  const rc = fakeRc({}, { conflicts: 2 });
  await syncTemplate(rc, { whats_new_7_0: 'a' });
  assert.equal(rc.published().parameters.whats_new_7_0.defaultValue.value, 'a');
  await assert.rejects(syncTemplate(fakeRc({}, { conflicts: 3 }), { whats_new_7_0: 'a' }), /ETag/);
});

test('syncTemplate: pembacaan balik yang tidak cocok membuat pipeline berhenti', async () => {
  await assert.rejects(syncTemplate(fakeRc({}, { dropWrites: true }), { whats_new_7_0: 'a' }), /pembacaan balik/);
});

test('syncTemplate remove: hanya entri yang disebut yang dihapus', async () => {
  const rc = fakeRc({ whats_new_7_0: p('a'), whats_new_6_0: p('b') });
  await syncTemplate(rc, {}, { remove: [paramName(7, 0)] });
  assert.deepEqual(Object.keys(rc.published().parameters), ['whats_new_6_0']);
});

test('formatPlayChangelog: judul, kategori beremoji, butir bertanda •', () => {
  const text = formatPlayChangelog(good, 'id');
  assert.equal(
    text,
    ['🚀 Apa yang baru di versi 0.6.0', '', '✨ Baru', '• Satu.', '• Dua.', '', '🛠️ Perbaikan', '• Tiga.'].join('\n'),
  );
  assert.match(formatPlayChangelog(good, 'en'), /^🚀 What's new in version 0\.6\.0\n\n✨ New\n• One\./);
});

test('formatPlayChangelog: lewat 500 karakter, butir terbawah dibuang dan kategori kosong hilang', () => {
  const long = 'x'.repeat(190);
  const note = {
    version: '0.6.0',
    groups: [
      { category: 'new', notes: [{ id: long, en: long }, { id: long, en: long }] },
      { category: 'fixed', notes: [{ id: long, en: long }] },
    ],
  };
  const text = formatPlayChangelog(note, 'id');
  assert.ok([...text].length <= PLAY_LIMIT, `${[...text].length} karakter`);
  assert.ok(!text.includes('Perbaikan'), 'kategori yang butirnya terbuang ikut hilang');
  assert.ok(text.includes('✨ Baru'));
});
