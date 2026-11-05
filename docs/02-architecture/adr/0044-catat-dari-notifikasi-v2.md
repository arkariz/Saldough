# Catat dari notifikasi v2: penentu bersama, bentuk dipelajari, dan notifikasi yang bisa ditindak

## 1. Metadata

- **Decision ID:** ADR-044
- **Tanggal:** 2026-11-04
- **Fase roadmap:** Fase 26 (lihat TASK_LIST)
- **Status:** Proposed (arah dan keputusan #1–#6 diberikan pemilik 4 Nov 2026;
  jadi Accepted setelah spike T-26.9 menunjukkan jalur tanpa layar layak)
- **Cakupan:** `features/notification_capture`, `shared/capture`,
  `shared/recurring`, `features/recurring`, `features/budget` (hanya
  `budgetItemForOccurrence`), Kotlin `notificationcapture/`, entrypoint Dart
  baru `captureWorkerMain`
- **Bergantung pada:** ADR-032, ADR-035, ADR-037, ADR-041, ADR-042
- **Mengubah sebagian:** ADR-032 §3.1 (pemrosesan hanya saat mesin hidup),
  ADR-032 §3.3 (pola bawaan per paket), ADR-032 §3.4 (draf yang perlu ditinjau
  selalu membuka CATAT; dilonggarkan oleh §3.6), ADR-042 §3.1/§3.4 (formulir
  aturan dompet dan ikatan rutin menjadi aturan yang lahir dari kartu), ADR-032
  §11 pada branch `worktree-notif-multi-wallet-recurring` (saklar build; **tidak
  dibawa**)
- **Rancangan produk:** [NOTIFICATION_CAPTURE_V2.md](../../01-product/features/NOTIFICATION_CAPTURE_V2.md)

## 2. Konteks

Mencatat satu transaksi dari notifikasi masih butuh minimal tiga ketuk dan
membuka aplikasi (Cek → Catat → Simpan). Empat prinsip pemilik (4 Nov 2026):
kurangi aksi, kompleksitas bertahap, satu aplikasi ke banyak dompet dan aturan,
dan kenali rencana (rutin, anggaran) agar tidak ada catatan ganda. Tambahan:
tanpa daftar bank atau korpus tertanam, dan mencatat harus mungkin **tanpa
membuka aplikasi**.

## 3. Keputusan (usulan)

### 3.1 Satu penentu bersama

`CaptureResolver` (domain, Dart murni) menggantikan penyusunan draf yang
tersebar. Urutan: aturan aplikasi → rencana (kemunculan rutin, lalu pos) →
ingatan pedagang → aturan umum. Keluarannya `ResolvedCapture { draft, reasons,
planMatch, budgetItemId, cardClass }` dengan `cardClass` ∈ {`planned`,
`recognized`, `needsInput`}. Aplikasi terbuka, mesin tanpa layar, dan Mulai
cepat memakai penentu yang sama; tidak ada logika kedua di Kotlin.

### 3.2 Penutup bersama

Satu fungsi (`CaptureFinalizer`) dipanggil setiap kali transaksi dari
notifikasi disimpan, apa pun jalurnya (otomatis, kartu, jurnal):
- tautkan kemunculan rutin (`withRecurrence`) bila ada kecocokan sah;
- isi `budgetItemId` lewat `budgetItemForOccurrence` untuk transaksi tertaut
  rutin (menutup celah `transactionFromDraft`);
- kirim sinyal (`RecurringChanges`, `LedgerChanges`).
Status kemunculan dan progres anggaran **diturunkan** dari tautan dan
`budgetItemId`, jadi tidak ada langkah hitung ulang.

### 3.3 Anti-duplikat dua arah

Pemeriksaan ledger (`AutoRecordPolicy.findInLedger`) dijalankan ulang saat
kartu ditampilkan dan saat `LedgerChanges` memberi tahu ada transaksi baru.
Kartu yang cocok **berubah** (tidak ditutup otomatis, karena dua pembelian yang
sama di hari yang sama bisa sungguhan) dan satu transaksi hanya dicocokkan ke
satu kartu. Aksi pada duplikat: **Sudah, tutup**, **Tetap catat**, atau
**Tautkan** ke kemunculan rutin yang cocok (`CaptureInboxActions.linkExisting`,
lewat `CaptureFinalizer`). Urutan
duplikat-dulu (F23-2) dan jenis harus sama (F23-6) dipertahankan. Status
kemunculan "tercatat" diperbaiki bila tampil "Later" (B-83b).

### 3.4 Bentuk dipelajari, tanpa daftar tertanam

- `builtInNotificationApps` dan pola `_cuePatterns` per paket **dihapus**.
  Penyaring awal adalah kata arah generik (paket bahasa `shared/capture`) dan
  angka, berlaku untuk aplikasi mana pun yang dipilih pengguna.
- **Bentuk** (`LearnedShape`) dibuat dari konfirmasi "Ini transaksi? Ya/Bukan":
  Ya menyimpan templat berjangkar kata arah dan nominal dengan wildcard untuk
  sisanya; Bukan menyimpan bentuk negatif. Mesin templat yang ada dipakai.
- Whitelist **aplikasi** tetap eksplisit (ADR-032 §3.2). Hanya whitelist
  **bentuk** yang dipelajari; ia menggantikan daftar kata filter.
- "Terverifikasi" berasal dari konfirmasi pengguna di perangkat, bukan korpus.
  Pola pengguna lama tetap terbaca (tanpa migrasi; lihat §3.7).
  **Direvisi 5 Nov 2026 (Revisi 11):** pola pengguna dicabut dan dibuang saat
  aplikasi dibuka; "Ya" untuk bentuk positif ditunda (Revisi 9).

### 3.5 Notifikasi bertindak dan pemrosesan tanpa layar

Latar: Dart hanya jalan saat mesin Flutter hidup; plugin native terikat
`Activity`; pengingat memakai `PendingIntent.getActivity`; Hive tidak aman
untuk dua isolate. Maka:

1. Layanan pendengar (`TransactionNotificationListener`) tetap mengantre
   notifikasi mentah ke `CaptureQueue`.
2. Bila mesin aplikasi tidak hidup, layanan menyalakan **mesin Dart tanpa
   layar** dengan entrypoint `captureWorkerMain`: `DartPluginRegistrant`,
   penyimpanan dibuka **hanya baca**, DI minimal (dompet, kategori, rutin,
   anggaran, setelan notifikasi), lalu `CaptureResolver`. Bila mesin aplikasi
   hidup (termasuk di latar), tangkapan diteruskan lewat channel yang ada;
   tidak ada mesin kedua.
3. Keluaran mesin tanpa layar ditulis ke **jurnal native** (`CaptureJournal`,
   di samping `CaptureQueue`): draf terselesaikan, keputusan (Catat/Abaikan/
   Batalkan), dan cap waktu. **Aplikasi tetap satu-satunya penulis ke Hive.**
4. Notifikasi bertindak dipasang dari layanan: tombol **Catat** dan **Abaikan**
   untuk kartu `planned`/`recognized`; badan notifikasi untuk `needsInput`
   membuka CATAT terisi. `BroadcastReceiver` menulis keputusan ke jurnal;
   notifikasi berubah menjadi hasil dengan **Batalkan** beberapa saat.
5. Saat aplikasi dibuka, jurnal diterapkan **sebelum Beranda tampil** lewat
   `RecordTransaction` dan `CaptureFinalizer`. Id transaksi diturunkan dari id
   tangkapan (idempoten). Yang gagal masuk kotak masuk dengan alasan.
6. Anti-duplikat mesin tanpa layar membaca jurnal. Pengingat rutin dijadwalkan
   ulang oleh mesin tanpa layar setiap keputusan atas tangkapan yang cocok
   dengan rutin (batal untuk yang tercatat, pulih bila dibatalkan; T-26.12).

Keamanan: `setAuthenticationRequired(true)` pada tombol Catat (API 31+).
Nominal di notifikasi **tidak** mengikuti `AmountVisibility` (keputusan pemilik
4 Nov 2026: tidak dibuat). Pengiriman memakai tiga keadaan
(`NotificationDelivery`): bawaan otomatis (Plus dengan sumber terpilih mendapat
notifikasi bertombol; Gratis tidak), dinyalakan sendiri (Gratis ikut, tanpa
tombol: membuka CATAT terisi), dan dimatikan sendiri (juga untuk Plus). Banyak
tangkapan: tiap notifikasi bertombol mendapat tombol **Catat semua**; bukan
ringkasan grup (Android 7+ menyembunyikan tombolnya) dan bukan kartu terpisah. Status Plus disimpan (dengan kedaluwarsa) untuk mesin tanpa layar, tidak
diketahui = Gratis. Keandalan best effort per vendor; antrean mentah adalah
cadangan, diproses saat aplikasi dibuka. Catat **otomatis** tidak berjalan di
mesin tanpa layar (tetap saat aplikasi dibuka).

### 3.6 Aturan 8: pengecualian ketiga

Draf berkelas `planned` atau `recognized` (tanpa tebakan: dompet, jenis, nominal
terbaca tanpa `issues`; transfer dengan dua dompet terpetakan; kategori dari
rencana, aturan, atau ingatan) boleh dikonfirmasi satu ketuk di kartu atau
tombol notifikasi, lewat `RecordTransaction`, tanpa formulir. `needsInput`
tetap membuka CATAT. Terbuka hanya untuk Plus (§3.8). Saat Accepted, perbarui
aturan 8 di `.claude/CLAUDE.md` dan `.claude/AGENT_CONTEXT.md`.

### 3.7 Aturan dan catat otomatis per bentuk

`AppRule` (kondisi → efek) menyatukan `walletRules`, kategori per pola, dan
`notificationBinding` (**Revisi 11:** kategori per pola dan `notificationBinding`
sudah dicabut; yang tersisa untuk dipersatukan hanya `walletRules`, B-88). Dokumen lama dibaca tanpa migrasi tulis; konversi saat
pertama disimpan (E4). Aturan lahir dari kartu ("Ingat untuk yang seperti ini?")
dengan Batalkan. Catat otomatis menjadi `autoApproved` **per bentuk**,
ditawarkan setelah konfirmasi pertama yang diterima tanpa ubahan jenis/dompet/
nominal; sakelar global turun ke Lanjutan. Dua catatan otomatis pertama dari
bentuk baru bertanda "baru"; nominal jauh di atas kebiasaan bentuk (usulan
>10× median; ambang belum diputuskan, KT-N2 ditunda) masuk kotak masuk.

### 3.8 Gerbang Gratis dan Plus (disetujui pemilik 4 Nov 2026)

Gratis: pengenalan rutin dan pos, anti-duplikat, pos dari rutin, CATAT terisi,
"Ingat" dasar, bentuk dipelajari, dan "Cek" yang membuka CATAT langsung bila
hanya satu tangkapan menunggu. Plus: satu ketuk di kartu, tombol Catat di
notifikasi, Catat semua, dan otomatis per bentuk. Anti-duplikat tidak boleh
dikunci. Selaras ADR-041 §3.8 (tingkat otomatis dan pola baru sudah Plus).
Satu ketuk di kartu kotak masuk seluruhnya Plus, termasuk kartu cocok rencana
dari rutin bernominal tetap (pemilik 4 Nov 2026, supaya Plus bernilai lebih);
satu ketuk di segmen Rutin (ADR-041 §3.8) tidak berubah, itu layar lain dengan
gerbangnya sendiri.

### 3.9 Tanpa saklar build; kendali rilis lewat jalur

`NotificationCaptureAvailability` (commit `57269a79`) tidak dibawa. Fitur
dirilis lewat jalur **internal test** dari branch sendiri sampai gerbang tiap
tahap terpenuhi; tidak digabung ke `main` yang dipakai rilis publik sebelum itu.
Sebelum produksi: perbarui pengungkapan, `PLAY_DATA_SAFETY.md`, dan tinjau
deklarasi layanan pendengar di `AndroidManifest`.

## 4. Alternatif yang ditimbang

| Alternatif | Alasan tidak dipilih |
|---|---|
| Penentu kedua di Kotlin (regex nominal, arah, dompet bawaan) | Dua logika yang menyimpang; tidak bisa rutin, pos, dan anti-duplikat |
| Mesin tanpa layar menulis Hive langsung | Hive tidak aman lintas isolate; butuh saling-eksklusif waktu. Dipertimbangkan setelah spike (KT-N3) |
| Widget layar utama | Penemuan buruk, dua permukaan data, usaha L; jadi E5 bila data mendukung |
| Quick Settings tile | Murah (S–M), tanpa pratinjau per transaksi; jadi E5 |
| Shortcut ikon | Tetap membuka aplikasi |
| Aktivitas konfirmasi cepat tanpa splash | Cadangan bila mesin tanpa layar tidak andal (M) |
| Bubble/floating | Izin overlay dan risiko kebijakan Play |
| Otomatis setelah tiga konfirmasi | Pengguna uji coba mungkin tak pernah mengalaminya; diganti syarat "diterima tanpa ubahan" |
| Korpus bank tertanam sebagai uji | Ditolak pemilik; uji memakai kasus sintetis |

## 5. Konsekuensi

- Perubahan besar di `shared/capture` dan `features/notification_capture`;
  `NotificationCaptureStore` mendapat `LearnedShape`/`AppRule` (field baru
  opsional, dokumen lama terbaca). Wajib didaftarkan di `BackupRegistry`.
- Kotlin: layanan memegang mesin tanpa layar, `CaptureJournal`, receiver, dan
  poster notifikasi. `NotificationCapturePlugin` tidak lagi terikat `Activity`
  untuk jalur ini.
- Saldo di aplikasi benar saat aplikasi dibuka berikutnya (jurnal diterapkan
  lebih dulu); pengingat rutin harus membaca jurnal.
- Aturan 8 dan dokumen PRD (FR-NOT-001) diperbarui saat Accepted.
- Risiko vendor Android diukur per perangkat di jalur internal test.

## 6. Pertanyaan terbuka

- **KT-N2** Sisa: ambang kartu dikoreksi (ditunda pemilik 4 Nov 2026). Pagar nominal
  dijawab 5 Nov 2026 (10× median).
- **KT-N3** **Diputuskan:** jurnal saja. Mesin tanpa layar tidak pernah menulis Hive;
  aplikasi satu-satunya penulis (T-26.10, dipertahankan oleh T-26.21).

## 7. Revisi

- **Revisi 11 (5 Nov 2026, T-26.23):** pola buatan pengguna ("Ajari pola"), pola
  bawaan, ikatan rutin ke pola (ADR-042 §3.4), dan transfer `{from}`/`{to}`
  dicabut penuh atas keputusan pemilik ("benar-benar v2"). Penentu v2 hanya
  memakai aturan notifikasi → Gemini, aturan dompet, rencana (rutin), ingatan
  pedagang, dan bentuk (negatif untuk menyaring, disetujui untuk catat otomatis).
  ADR-042 §3.1 (aturan dompet), §3.2 (contoh) tetap; §3.1 bagian `{from}`/`{to}` dan
  §3.4 (ikatan) tidak berlaku lagi. Data lama dibuang tanpa migrasi; kunci cadangan
  lama tetap dikenal agar `.tkbak` lama bisa dipulihkan.

- **Revisi 10 (5 Nov 2026, T-26.20):** catat otomatis per bentuk (§3.7) dibangun.
  KT-N2 dijawab: pagar nominal 10× median (min. 3 contoh, 20 terakhir). Bentuk
  disetujui lewat tawaran sesudah Simpan; templatnya menjadikan pedagang `{note}`.
  Berlaku di pemroses saat aplikasi dibuka; T-26.21 menambah jalur mesin tanpa
  layar (keputusan Catat ke jurnal, buku besar tetap diisi saat aplikasi dibuka).

- **Revisi 9 (5 Nov 2026):** bentuk positif "Ya" (§3.4) ditunda. Kartu hanya ada bila
  teksnya sudah lolos filter frasa, jadi mempelajarinya dari kartu tidak menambah
  jangkauan; menangkap yang terlewat butuh daftar "Tidak dikenali" yang menyimpan
  teks tersaring (perubahan privasi), dibuka bila data nyata membenarkan.

- **Revisi 8 (5 Nov 2026, T-26.17):** dompet diingat dari pengenal rekening
  bertopeng di teks (tepat satu), menjadi `WalletRule` tanpa formulir.

- **Revisi 7 (4 Nov 2026, T-26.15):** bentuk negatif ("Bukan transaksi") dipelajari
  dari kartu dan menyaring notifikasi berikutnya (§3.4); bentuk positif tetap
  lewat Ajari pola.

- **Revisi 6 (4 Nov 2026, T-26.14):** ingatan pedagang (`MerchantMemory`) kini
  punya implementasi: kategori yang dikonfirmasi lewat CATAT dari kartu diingat
  per (aplikasi, catatan) dan dipakai penentu bersama (§3.1).

- **Revisi 5 (4 Nov 2026, T-26.12):** pengingat rutin mengikuti jurnal lewat
  penyesuaian jadwal oleh mesin tanpa layar (§3.5 butir 6).

- **Revisi 4 (4 Nov 2026, T-26.11):** kunci produksi dibuka (tanpa berkas
  penanda atau syarat build debug); tiga keadaan pengiriman, Gratis ikut mesin
  tanpa layar tanpa tombol, Catat semua mandiri, teks lewat i18n, tanpa
  `AmountVisibility`. Terbukti di emulator yang sama (H13–H18). Status tetap
  Proposed: perangkat nyata dan vendor lain belum.

- **Revisi 0 (4 Nov 2026):** rancangan awal bersama pemilik.
- **Revisi 3 (4 Nov 2026, T-26.10):** jurnal native, penerapan di
  `bootstrapApp()` sebelum layar pertama, id transaksi `cap_<idTangkapan>`
  (idempoten), salinan status Plus, dan penguras antrean selesai dan terbukti di
  emulator (§3.5). Penerapan memakai urutan idempoten (catat → kotak masuk →
  terproses → ack antrean → ack jurnal), jadi proses yang dimatikan di tengah
  jalan aman diulang. Status tetap Proposed (perangkat nyata, vendor lain).
- **Revisi 2 (4 Nov 2026, hasil spike T-26.9):** §3.5 terbukti berjalan di satu
  emulator (Android 17, arm64): layanan menyalakan `FlutterEngine` dengan
  entrypoint Dart, mesin membaca Hive dan menjalankan `CaptureResolver` yang
  sama, memasang notifikasi dengan tombol Catat/Abaikan, dan tombolnya ditangani
  `BroadcastReceiver` tanpa membuka aplikasi. AOT ±0,6 dtk dan +69 MB sementara;
  UI yang dibuka bersamaan tidak bentrok. Tambahan syarat: perpustakaan titik
  masuk diimpor dari `main.dart`, watchdog per-jalan, dan antrean dikuras sampai
  kosong. **Status tetap Proposed**: belum diuji di perangkat nyata lain vendor
  (hasil dan daftar yang belum di `VERIFICATION_PLAN_FASE_26.md` bagian H).
- **Revisi 1 (4 Nov 2026):** garis Gratis/Plus (§3.8) disetujui pemilik (KT-N1
  ditutup); ambang otomatis dan kartu dikoreksi (KT-N2) ditunda. Kesamaan satu
  ketuk kartu dengan segmen Rutin diperiksa di T-26.7.
