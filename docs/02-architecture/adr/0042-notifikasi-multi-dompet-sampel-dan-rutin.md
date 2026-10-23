# Catat dari notifikasi: banyak dompet per aplikasi, sampel notifikasi, pencatatan rutin lebih awal

## 1. Metadata

- **Decision ID:** ADR-042
- **Tanggal:** 2026-10-23
- **Fase roadmap:** Fase 23 (lihat TASK_LIST)
- **Status:** Accepted (pemilik menjawab §6 dan meminta implementasi, 23 Okt 2026)
- **Cakupan:** `features/notification_capture`, `shared/recurring`,
  `features/recurring`, Kotlin `notificationcapture/`
- **Bergantung pada:** ADR-032, ADR-035, ADR-036, ADR-037, ADR-038
- **Mengubah sebagian:** ADR-032 §3.2 (satu dompet per sumber), ADR-032 §3.6
  (retensi teks), ADR-035 §3.4 (jendela pencocokan ±3 hari)

## 2. Konteks

Permintaan pemilik 23 Okt 2026, dengan kasus Bank Jago (satu aplikasi, banyak
Kantong):

1. Satu aplikasi bisa diarahkan ke beberapa dompet, termasuk transfer antar
   dompet di aplikasi yang sama.
2. Riwayat notifikasi Jago dipakai untuk membuat pola dan filter cepat.
3. Rutin bisa dicatat sebelum tanggal yang ditentukan.
4. Kemunculan notifikasi mencatat rutin yang ada. **Pola harus jelas, tidak
   menebak** (jawaban pemilik).

## 3. Keputusan (usulan)

### 3.1 Banyak dompet per sumber (poin 1)

`NotificationSource.walletId` tetap sebagai **dompet bawaan**. Ditambah
`walletRules: List<WalletRule>`, `WalletRule { id, walletId, keywords }`:
frasa pengenal yang muncul di teks notifikasi (mis. nama Kantong:
"Kantong Liburan"). Dokumen lama tanpa field ini tetap terbaca (tanpa
migrasi).

- **Penentuan dompet:** teks dicocokkan dengan aturan dompet (tanpa beda huruf
  besar-kecil). Tepat satu dompet cocok → dompet itu. Tidak ada yang cocok →
  dompet bawaan. **Lebih dari satu dompet berbeda cocok → tidak menebak**:
  dompet dibiarkan kosong, tangkapan masuk kotak masuk dengan alasan
  `walletUnknown`.
- **Transfer antar dompet satu aplikasi** (Kantong A → Kantong B): pola
  mendapat dua penanda dompet, `{from}` dan `{to}`, yang dipetakan lewat aturan
  dompet ke dompet Tanukonomy. Pola dengan satu `transferWalletId` tetap
  berlaku. Dua sisi harus terpetakan dan berbeda; kalau tidak, ke kotak masuk.
  Transfer tidak pernah dihitung pemasukan/pengeluaran (aturan 7).
- Kini dompet sumber tidak boleh terbaca sebagai lawan transfer
  (`otherWallets`, ADR-032); aturan itu diganti: semua dompet yang terdaftar
  di aturan sumber boleh menjadi sisi transfer.
- Tingkat otomatis (§3.4 ADR-032) tidak berubah: dompet harus terisi.

### 3.2 Riwayat notifikasi: apa yang mungkin (poin 2)

**Android tidak mengizinkan membaca notifikasi lama.** `NotificationListenerService`
hanya menerima notifikasi yang diposting sesudah akses diberikan dan, lewat
`getActiveNotifications()`, yang **masih tampil** di bayangan notifikasi.
Notifikasi Jago yang sudah dihapus atau lewat sebelum akses diberikan tidak
bisa dibaca siapa pun.

Yang bisa dilakukan:

- **Sampel notifikasi** per sumber: notifikasi aplikasi terpilih yang lolos
  pemeriksaan dasar (bukan OTP, bukan *ongoing*, berisi angka) tetapi **tidak
  lolos filter**, disimpan 7 hari di perangkat (sama seperti kotak masuk) dan
  ditampilkan di halaman sumber sebagai "Notifikasi terbaru". Dari sini
  pengguna (a) menandai frasa menjadi **filter cepat** (ketuk frasa → tambah ke
  filter), dan (b) **Buat pola** (pembuat pola ADR-032 §3.9). Saat sumber
  baru ditambahkan, notifikasi yang masih tampil diambil sekali lewat
  `getActiveNotifications()`.
- **Privasi (disetujui pemilik 23 Okt 2026):** ini menyimpan teks notifikasi yang
  *tidak* dianggap transaksi, mengubah ADR-032 §3.6 dan formulir Keamanan
  Data. Pagar: hanya paket terpilih, OTP tidak pernah, maksimum 50 per sumber,
  7 hari, bisa dimatikan dengan sakelar "Simpan contoh notifikasi" (bawaan
  mati; nyala hanya setelah pengguna membuka "Notifikasi terbaru" dan
  menyetujui keterangannya), terhapus saat sumber dihapus. Tidak dikirim ke
  Gemini.
- Tidak mungkin: mengimpor riwayat sebelum akses diberikan, atau membaca
  isi aplikasi Jago.

### 3.3 Catat rutin lebih awal (poin 3)

Kemunculan berstatus `upcoming` bisa dicatat sebelum tanggalnya, **tanpa
batas hari** (keputusan pemilik 23 Okt 2026). Peringatan E11
(`isFarFromOccurrence`, > 7 hari) tetap dipakai sebagai pemberitahuan
biasa, bukan penghalang.

- Aksi **Catat sekarang** muncul di baris kemunculan akan datang (tab Rencana
  › Rutin, rincian rutin, kartu Bulan ini). Rutin nominal tetap: satu ketuk
  lewat `RecordTransaction` (pengecualian aturan 8, ADR-035 §3.3); nominal
  kira-kira: membuka CATAT.
- **Tanggal transaksi = hari ini** (uang benar-benar bergerak hari ini),
  tertaut ke `occurrenceDate`. Berbeda dari pencatatan biasa (E11, tanggal
  kemunculan) karena tanggal masa depan tidak boleh dipakai untuk saldo.
  Keanggotaan periode keuangan mengikuti `periodDateOf` (selisih ≤ 7 hari ikut
  tanggal kemunculan, ADR-038), sehingga tidak ada perubahan perhitungan
  periode.
- Kemunculan yang sudah dicatat awal berstatus `recorded`; pengingat
  kemunculan itu dibatalkan; pembatalan transaksi mengembalikan status.
- Pencocokan `occurrenceCandidates` dari transaksi sudah berlaku ±3 hari;
  jendela itu diperlebar ke 7 hari **hanya** untuk rutin yang terikat pola
  (§3.4), agar notifikasi yang datang lebih awal cocok. Pelebaran ini
  khusus penautan otomatis; pencatatan manual tidak dibatasi.

### 3.4 Notifikasi mencatat rutin yang ada, tanpa menebak (poin 4)

ADR-037 §3.3 sudah menautkan otomatis transaksi dari notifikasi ke kemunculan
rutin bernominal tetap bila kecocokannya tunggal. Kekurangannya: kecocokan
bergantung pada nominal, dompet, dan jenis saja, jadi dua langganan
bernominal sama di dompet yang sama membuat keduanya ragu (masuk kotak masuk),
dan pengguna tidak bisa menyatakan "notifikasi ini adalah rutin itu".

Ditambah **ikatan eksplisit**: `RecurringRule.notificationBinding`
`{ packageName, patternId }` (opsional). Pola menjadi kunci identitas:

- Ikatan dibuat pengguna dari rincian rutin ("Ikat ke notifikasi": pilih
  pola yang ada) atau dari kotak masuk/Tercatat otomatis ("Tautkan ke rutin"
  yang menyimpan ikatan sekaligus). Tidak pernah dibuat otomatis.
- Notifikasi yang cocok dengan pola terikat **dan** pola terverifikasi **dan**
  dompet terpetakan **dan** nominal sesuai (persis untuk tetap; ±10% hanya
  disarankan, KT-R11) **dan** tepat satu kemunculan terbuka dalam jendela 7
  hari → ditautkan otomatis, dan dicatat otomatis bila tingkat otomatis
  mengizinkan. Satu saja syarat gagal → kotak masuk dengan saran rutin itu
  (alasan ditampilkan), tidak pernah ditebak.
- Tanpa ikatan, perilaku ADR-037 §3.3 tetap (±3 hari, nominal persis, tunggal).
- **Jenis harus sama** (keputusan pemilik 24 Okt 2026, F23-6): pola pengeluaran
  hanya ke rutin pengeluaran, pemasukan ke pemasukan, `transferOut`/
  `transferIn`/`transferBetween` ke rutin transfer. Pemilih hanya menawarkan
  rutin sepadan dan bloc menolak ikatan lintas jenis; ikatan lama yang lintas
  jenis tetap tampil agar bisa dilepas. Dompet tidak disaring: dompet baru
  diketahui saat notifikasi datang.
- **Urutan alasan kotak masuk** (keputusan pemilik 24 Okt 2026, F23-2): deteksi
  duplikat didahulukan. Pola terikat tanpa kemunculan terbuka karena kemunculan
  itu sudah tercatat di hari yang sama berbadge "mungkin sudah tercatat";
  "Rutin belum pasti" untuk kasus lain (dilewati, di luar 7 hari, nominal beda).
- Satu pola hanya boleh terikat ke satu rutin; mengikat ulang meminta
  konfirmasi. Menghapus pola atau rutin melepas ikatan.
- Rutin dibuat dari notifikasi (mis. "Jadikan rutin") **tidak** dalam cakupan.

## 4. Opsi yang dipertimbangkan

- **Poin 1 — Pilih dompet manual saat dicek:** ditolak pemilik; aturan per
  dompet dipilih.
- **Poin 3 — Tanggal transaksi = tanggal kemunculan:** ditolak, tanggal
  masa depan merusak saldo hari ini.
- **Poin 4 — Menebak dari nominal saja:** sudah ada, kurang aman; ikatan
  eksplisit dipilih.

## 5. Konsekuensi

- Skema: `NotificationSource.walletRules`, `NotificationPattern` penanda
  `{from}`/`{to}` (jenis `transferBetween`), `RecurringRule.notificationBinding`,
  `NotificationCaptureSettings.saveSamples`. Semua field baru opsional dan
  berada di dokumen yang sudah ada; tanpa migrasi dan tanpa kunci Hive baru,
  jadi `BackupRegistry` tidak berubah. Contoh notifikasi disimpan native
  (SharedPreferences), bukan Hive, dan tidak ikut cadangan.
- Formulir Keamanan Data dan kebijakan privasi perlu diperbarui sebelum
  sampel notifikasi dirilis (§3.2).
- Kotlin: antrean sampel terpisah dari antrean transaksi; OTP daftar kata
  tetap dijaga uji kesamaan.

## 6. Keputusan pemilik (23 Okt 2026)

1. Penyimpanan sampel notifikasi (§3.2) **disetujui**.
2. Pencatatan awal rutin **tanpa batas hari** (§3.3).
3. Pola terikat **mencatat tanpa ketukan sesuai tingkat otomatis** (§3.4):
   tingkat 1 tetap masuk kotak masuk dengan tautan rutin; tingkat 2/3
   langsung tercatat lewat `RecordTransaction` dan tertaut.

## 7. Revisi

- **Revisi 1 (23 Okt 2026):** §6 dijawab pemilik; batas awal 7 hari dicabut.
- **Revisi 2 (24 Okt 2026, hasil QA `c83f3602`):** F23-6 dan F23-2 diputuskan
  (§3.4). Transfer antar dompet yang sisinya tak terpetakan kini bermasalah
  `walletUnknown` (F23-1). Kode Kotlin sudah terkompilasi dan teruji QA;
  catatan "belum dikompilasi" di bawah dicabut.
- **Catatan implementasi (23 Okt 2026):**
  - Contoh notifikasi menyimpan semua notifikasi bermuatan angka dari sumber
    terdaftar (bukan hanya yang tidak lolos filter), supaya daftar berguna
    untuk pola dan filter. Dimuat di halaman sumber bila sakelar menyala.
  - Ikatan pola ke rutin dipilih dari halaman sumber (bagian *Ikat ke rutin*),
    untuk pola pengguna dan pola bawaan terverifikasi. Tangkapan dari pola
    terikat yang kemunculannya tidak jelas masuk kotak masuk dengan alasan
    `recurringUnclear`; rutin kira-kira terikat selalu ke kotak masuk.
  - Rutin tidak menampilkan ikatannya di rincian (hanya di halaman sumber).
  - Kode Kotlin (contoh notifikasi) terkompilasi dan lulus uji emulator QA
    (24 Okt 2026).

---

**Penulis keputusan:** Claude (agen), atas permintaan pemilik
**Ditinjau oleh:** (menunggu pemilik)
**Status implementasi:** kode selesai di branch `worktree-notif-multi-wallet-recurring` (T-23.1–T-23.4); verifikasi perangkat belum
