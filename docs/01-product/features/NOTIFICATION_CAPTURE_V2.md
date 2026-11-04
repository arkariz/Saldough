# Catat dari notifikasi v2: dikenali, satu ketuk, tanpa membuka aplikasi

**Tanggal:** 4 November 2026.
**Status:** Rancangan (Proposed), disusun bersama pemilik 4 Nov 2026. Keputusan
arsitekturnya di [ADR-044](../../02-architecture/adr/0044-catat-dari-notifikasi-v2.md);
tugasnya Fase 26 di TASK_LIST.
**Berkaitan:** [ADR-032](../../02-architecture/adr/0032-catat-dari-notifikasi.md)
(dasar fitur), [ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)
(rutin sebagai rencana), [ADR-037](../../02-architecture/adr/0037-otomasi-rutin-r3.md),
[ADR-041](../../02-architecture/adr/0041-monetisasi-hak-plus-dan-uji-coba.md)
(gerbang Plus), [ADR-042](../../02-architecture/adr/0042-notifikasi-multi-dompet-sampel-dan-rutin.md)
(banyak dompet, contoh, ikatan rutin), [FEATURE_DISCOVERY.md](FEATURE_DISCOVERY.md)
(pintu Beranda dan Mulai cepat), [VERIFICATION_PLAN_FASE_23.md](../../04-planning/VERIFICATION_PLAN_FASE_23.md).

Dokumen ini mengganti arah "rencana sementara" 24 Okt 2026 (L0–L6): tahapnya
disusun ulang dari empat prinsip di bawah, di atas kode Fase 22–23 yang sudah
ada, bukan dari nol.

## 1. Masalah

Fitur sudah bisa menangkap notifikasi, tetapi untuk mencatat satu transaksi
pengguna Gratis masih melewati **Cek (Beranda) → Catat (kotak masuk) → Simpan
(CATAT)**: minimal 3 ketuk dan 2 pindah layar, dan aplikasi harus dibuka dulu.
Fakta kode yang menjadi dasar rancangan ini (diperiksa 4 Nov 2026):

| Fakta | Berkas |
|---|---|
| Pemroses baru jalan saat mesin Flutter hidup; layanan native hanya mengantre teks mentah | `process_captured_notifications.dart`, `TransactionNotificationListener.kt` |
| Plugin native terikat `Activity`; pengingat memakai `PendingIntent.getActivity`, jadi selalu membuka aplikasi | `NotificationCapturePlugin.kt`, `CaptureReminders.kt:55` |
| Pencocokan rutin ada, tetapi tautan otomatis hanya untuk nominal tetap persis dan kandidat tunggal | `occurrence_matching.dart` |
| `transactionFromDraft` tidak mengisi `budgetItemId`; lewat CATAT pos terisi dari kemunculan rutin (`expense_form_sheet.dart:144`), lewat jalur otomatis tidak | `transaction_from_draft.dart` |
| Anti-duplikat hanya dijalankan saat tangkapan masuk; CATAT manual sesudahnya tidak menutup kartu kotak masuk | `process_captured_notifications.dart:222` |
| Mulai cepat hanya menampilkan 12 paket bank yang tertanam (nama paket belum dicek di perangkat) dan tidak menanyakan dompet | `built_in_notification_patterns.dart`, `quick_start_apps.dart` |
| Banyak dompet per aplikasi, kategori per pola, dan ikatan rutin dibuat lewat formulir terpisah di halaman sumber | `notification_source_page.dart` |
| Penyimpanan memakai Hive; tidak aman bila dua isolate menulis ke kotak yang sama | `pubspec.yaml` (`hive_storage`) |

## 2. Empat prinsip (pemilik, 4 Nov 2026)

1. **Kurangi aksi pengguna untuk mencatat.**
2. **Jangan memperkenalkan kompleksitas** bila bisa dihindari; kompleksitas
   masuk bertahap seiring kebutuhan pengguna bertambah.
3. **Satu aplikasi yang didengarkan bisa ditautkan ke beberapa dompet dan
   aturan** yang berbeda.
4. **Mengenali transaksi yang direncanakan** lewat anggaran dan rutin, supaya
   tidak ada catatan ganda.

## 3. Keputusan pemilik (4 Nov 2026)

| # | Keputusan |
|---|---|
| 1 | Konfirmasi **satu ketuk** untuk draf lengkap tanpa tebakan diizinkan, sebagai pengecualian ketiga aturan 8 (§6). |
| 2 | Catat **otomatis** tetap boleh menunggu pengguna membuka aplikasi. Mencatat dari notifikasi **tanpa membuka aplikasi** harus ada: opsi A, notifikasi yang bisa ditindak (§9). |
| 3 | **Tanpa korpus dan tanpa daftar bank tertanam.** Aplikasi mempelajari bentuk notifikasi; whitelist bentuk dikelola lewat "Ajari pola" (§7). |
| 4 | **Tanpa bank awal.** Rilis lewat jalur **internal test** Play. |
| 5 | **Saklar build T-23.6 dihilangkan** (commit `57269a79` tidak dibawa). Kendali rilis lewat branch dan jalur Play. |
| 6 | Catat otomatis tidak menunggu tiga konfirmasi: **ditawarkan setelah konfirmasi pertama** yang diterima tanpa ubahan, per bentuk (§8). |
| 7 | Konfirmasi satu ketuk dan catat otomatis menjadi nilai **Plus** (arahan pemilik). Garis tepatnya di §10, **disetujui pemilik 4 Nov 2026**. |

## 4. Model: satu penentu, tiga jenis kartu

Setiap tangkapan diselesaikan oleh **satu penentu** yang berurutan, apa pun
jalurnya (aplikasi terbuka, mesin tanpa layar, atau Mulai cepat):

1. **Aturan aplikasi**: dompet (dan kategori, rutin, pos bila ada) dari aturan
   yang dipelajari atau dibuat pengguna (§7, §8).
2. **Rencana**: kemunculan rutin yang cocok (kandidat `occurrenceCandidates`,
   pemutus seri lewat nama rutin di teks, jendela ±3 hari termasuk bayar lebih
   awal), lalu pos anggaran (§5).
3. **Ingatan pedagang**: kategori dari konfirmasi sebelumnya.
4. **Aturan umum**: nominal, arah, dan kata arah generik.

Hasilnya satu draf dengan alasan dan salah satu kelas kartu:

| Kelas | Arti | Aksi |
|---|---|---|
| **Cocok rencana** | Cocok dengan kemunculan rutin (dan/atau pos); semua bidang terisi | Satu ketuk (Plus), atau Catat → CATAT terisi (Gratis) |
| **Dikenali** | Dompet, jenis, nominal terbaca; kategori dari aturan atau ingatan | Sama |
| **Perlu diisi** | Ada bidang yang tidak terpetakan atau ambigu | Selalu membuka CATAT terisi |

**Tanpa tebakan** berarti: dompet, jenis, dan nominal terbaca tanpa `issues`;
untuk transfer kedua dompet terpetakan; kategori berasal dari rencana, aturan,
atau ingatan. Ambigu (dua dompet cocok, dua kemunculan terbuka) tetap
ditanyakan dengan chip, tidak ditebak (ADR-042 §3.1, ADR-035 §3.4).

## 5. Mengenali rencana dan mencegah catatan ganda (prinsip 4)

**Rutin.** Tautan dibuat saat transaksi disimpan, jadi status kemunculan
("tercatat") dan perkiraan Rencana langsung benar karena keduanya diturunkan
dari tautan itu. Saat pengguna mengonfirmasi, tautan juga dibuat untuk rutin
kira-kira (±10%) dan, bila ada dua kandidat, setelah memilih dengan chip.
Jalur **otomatis** tetap hanya untuk nominal tetap persis dan kandidat tunggal.

**Pos anggaran.** Transaksi yang tertaut ke kemunculan rutin memakai
`budgetItemForOccurrence` di **semua jalur**, termasuk otomatis dan penutup
mesin tanpa layar. Ini menutup celah `transactionFromDraft`. Progres anggaran
diturunkan dari `budgetItemId` (`calculate_budget_progress`), jadi tidak ada
langkah hitung ulang. Pengeluaran bebas ke pos tanpa rutin hanya **disarankan**
(E2), tidak diisi diam-diam: pos tidak punya kategori, jadi kandidatnya anggaran
aktif berdompet sama dalam periode itu yang namanya muncul di teks atau pernah
dipilih untuk pedagang itu.

**Anti-duplikat dua arah** (urutan duplikat-dulu dipertahankan, keputusan F23-2):
- Saat kartu ditampilkan, tangkapan dicek ulang terhadap buku besar.
- Saat CATAT manual cocok dengan kartu yang menunggu (lewat `LedgerChanges`),
  kartu **berubah**, tidak ditutup sendiri: dua pembelian yang sama di hari yang
  sama bisa sungguhan, dan menutup diam-diam bisa membuang transaksi yang nyata
  (keputusan implementasi 4 Nov 2026, menggantikan rancangan "ditutup otomatis").
  Satu catatan hanya dicocokkan ke satu kartu (yang tertua).
- Kartu duplikat menampilkan "Sama dengan catatan …" dengan aksi **Sudah, tutup**
  (utama), **Tetap catat** (membuka CATAT), dan **Tautkan ke {rutin}** bila
  catatan itu belum tertaut dan ada kemunculan rutin yang cocok: catatan manual
  ditautkan ke kemunculan dan pos periodenya (saldo tidak berubah).
- Jenis harus sama antara pola dan rutin (keputusan F23-6).
- Status kemunculan "tercatat" harus andal (B-83b).

## 6. Aturan 8: pengecualian ketiga

Aturan 8 menyatakan CATAT satu-satunya jalur pembuatan transaksi manual.
Pengecualian pertama ADR-032 (otomatis memakai `RecordTransaction`) dan kedua
ADR-035 §3.3 (kemunculan rutin bernominal tetap, satu ketuk) sudah ada.
**Pengecualian ketiga:** draf berkelas **Cocok rencana** atau **Dikenali**
(§4, tanpa tebakan) boleh dikonfirmasi satu ketuk di kartu atau di tombol
notifikasi, lewat `RecordTransaction`, tanpa formulir. Kelas **Perlu diisi**
tetap membuka CATAT. Pengecualian ini hanya terbuka bila pengguna Plus (§10).

## 7. Mempelajari bentuk notifikasi (prinsip 2)

Dua whitelist berbeda:
- **Whitelist aplikasi** (mana yang didengarkan) tetap pilihan eksplisit. Layanan
  native hanya menyimpan notifikasi dari aplikasi pilihan (ADR-032); "belajar"
  aplikasi mana yang relevan berarti membaca semua notifikasi.
- **Whitelist bentuk** (notifikasi mana yang berarti transaksi) **dipelajari**,
  dan menggantikan daftar kata filter.

Cara belajar:
- Penyaring awal: kata arah generik dan angka (bukan daftar bank). Daftar
  `builtInNotificationApps` dan pola per paket **dihapus**.
- Notifikasi pertama dari bentuk baru tampil sebagai kartu yang bertanya
  sekali: **Ini transaksi? Ya / Bukan**.
- **Ya** membuat bentuk positif dari contoh itu: penjangkar kata arah dan
  nominal, sisanya wildcard (nomor referensi, nama pedagang). Mesin templat
  `NotificationTemplate` yang ada dipakai.
- **Bukan** membuat bentuk negatif, jadi promosi ("Diskon Rp50.000") tidak
  muncul lagi.
- Sebelum disimpan, kartu menampilkan "Seperti: …".
- "Ajari pola" menjadi permukaan **pengelolaan dan koreksi** di Lanjutan:
  daftar bentuk (contoh, jenis, dompet, kategori) yang bisa dimatikan atau
  dihapus. Jalur manual (tandai nominal) hanya muncul di kartu yang gagal dibaca.
- "Terverifikasi" berasal dari **konfirmasi di perangkat**, bukan dari korpus
  tertanam.

## 8. Aturan, banyak dompet, dan kompleksitas bertahap (prinsip 2 dan 3)

Satu konsep **aturan aplikasi** (kondisi → efek) menyatukan `walletRules`,
kategori per pola, dan ikatan rutin (data lama dipetakan, tanpa kehilangan):
- Kondisi: kata pengenal (akhir rekening, nama kantong), arah, rentang nominal.
- Efek: dompet, kategori, rutin atau pos, tingkat otomatis.
- Urut dari atas, yang pertama cocok menang, baris terakhir "Lainnya → dompet utama".

Aturan **lahir dari kartu**, bukan formulir: saat pengguna mengubah dompet atau
kategori, atau memilih dompet pada kartu yang ambigu, muncul "Ingat untuk yang
seperti ini?" dengan Batalkan di snackbar.

| Tingkat | Yang terlihat | Muncul saat |
|---|---|---|
| T0 | Pilih aplikasi dan dompetnya, satu sakelar | Mulai cepat |
| T1 | "Ingat untuk yang seperti ini?" | Pengguna mengubah dompet/kategori di kartu |
| T2 | "Catat otomatis yang seperti ini?" | Tepat setelah konfirmasi pertama yang diterima tanpa ubahan |
| T3 | Daftar aturan, bentuk, filter, contoh notifikasi | Hanya di Lanjutan |

**Catat otomatis per bentuk** (keputusan #6). Syarat tawaran: kartu disimpan
tanpa mengubah jenis, dompet, atau nominal (kategori boleh); semua sisi
terpetakan. Tawaran muncul tepat setelah Simpan dengan pratinjau "Seperti: …".
Bagi pengguna Gratis tombol Ya membuka pratinjau Plus. Pagar pengganti hitungan:
sakelar global turun ke Lanjutan; dua catatan otomatis pertama dari bentuk baru
bertanda "baru" dengan Batalkan terlihat; nominal jauh di atas kebiasaan bentuk
itu (usulan >10× median) masuk kotak masuk. Pencatatan otomatis berjalan saat
aplikasi dibuka.

## 9. Mencatat tanpa membuka aplikasi: notifikasi yang bisa ditindak

Tanukonomy memunculkan notifikasi sendiri dengan tombol **Catat** dan
**Abaikan** (isi mis. "Rp25.000 · KOPI · BCA"). Satu ketukan mencatat tanpa
membuka aplikasi. Kartu **Perlu diisi** tetap: ketuk badan notifikasi membuka
CATAT terisi.

**Arsitektur** (rinci di ADR-044 §3.5):
1. Layanan pendengar mengantre notifikasi (sudah ada).
2. Bila mesin aplikasi tidak hidup, layanan menyalakan **mesin Dart tanpa layar**
   dengan entrypoint `captureWorkerMain` yang hanya merakit modul yang
   dibutuhkan (dompet, kategori, rutin, anggaran, setelan notifikasi) dan
   menjalankan penentu yang sama. Tidak ada logika kedua di Kotlin.
3. Mesin tanpa layar **hanya membaca Hive**. Hasilnya (draf terselesaikan,
   keputusan pengguna) ditulis ke **jurnal native**. Aplikasi tetap satu-satunya
   penulis ke Hive.
4. Notifikasi bertindak dipasang dari layanan (bukan Activity). Tombol Catat
   ditangani `BroadcastReceiver` yang menulis keputusan ke jurnal; notifikasi
   berubah menjadi "Tercatat Rp25.000 · BCA" dengan Batalkan beberapa saat.
5. Saat aplikasi dibuka, jurnal diterapkan **sebelum Beranda tampil** lewat
   `RecordTransaction`, lengkap dengan tautan rutin dan pos. Id transaksi
   diturunkan dari id tangkapan sehingga percobaan ulang tidak menggandakan.
   Yang gagal diterapkan (mis. dompet sudah dihapus) masuk kotak masuk dengan alasan.
6. Bila mesin aplikasi hidup di latar, jalur yang ada dipakai.

**Konsekuensi.** Saldo di aplikasi benar saat aplikasi dibuka berikutnya;
pengingat rutin dan anti-duplikat mesin tanpa layar harus membaca jurnal.
Keandalan layanan bergantung vendor Android (antrean mentah tetap cadangan).
Status Plus disimpan agar dibaca mesin tanpa layar; bila tidak diketahui,
perlakukan sebagai Gratis. Penulisan langsung ke buku besar dari mesin tanpa
layar adalah peningkatan sesudah spike, bukan bagian MVP (KT-N3).

**Keamanan dan privasi.** Tombol Catat meminta pembukaan kunci perangkat
(`setAuthenticationRequired`, API 31+). Nominal mengikuti `AmountVisibility`;
versi publik layar kunci tanpa angka. Banyak tangkapan digabung dengan "Catat
semua" (Plus).

## 10. Gerbang Gratis dan Plus

Disetujui pemilik 4 Nov 2026, sejalan dengan ADR-041 yang sudah mengunci
tingkat otomatis dan pola baru ke Plus:

| Gratis (kebenaran dan kepercayaan) | Plus (kenyamanan) |
|---|---|
| Pengenalan rutin dan pos, anti-duplikat dua arah, pos dari rutin | Konfirmasi satu ketuk di kartu |
| CATAT terisi lengkap dari kartu | Tombol Catat di notifikasi (§9) |
| "Ingat" dasar (dompet dan kategori), bentuk dipelajari | Catat semua yang cocok |
| "Cek" di Beranda membuka CATAT langsung bila hanya satu tangkapan menunggu (2 ketuk) | Catat otomatis per bentuk |

Anti-duplikat tidak boleh dikunci: tanpanya pengguna Gratis mencatat ganda.
Satu pengecualian atas "satu ketuk = Plus" (keputusan implementasi T-26.7, 4 Nov
2026): kartu cocok rencana dari **rutin bernominal tetap yang persis** tetap
satu ketuk di Gratis, karena aksi yang sama sudah gratis di segmen Rutin
(ADR-041 §3.8); kartu dikenali dan rutin kira-kira tetap Plus.
Jalan terpendek Gratis tetap membuka aplikasi (tombol Catat di notifikasi Plus).
Satu ketuk untuk rutin bernominal tetap di segmen Rutin sudah ada; garis di
kartu kotak masuk mengikuti segmen itu supaya tidak ada dua perilaku untuk
tindakan yang sama (kesamaan itu diperiksa terhadap ADR-041 saat T-26.7 dikerjakan).

## 11. Tahap dan usaha

Ukuran usaha: **S** (sehari), **M** (beberapa hari), **L** (lebih dari seminggu,
ada ketidakpastian). Tahap bisa dirilis sendiri; tiap tahap punya gerbang keluar.

| Tahap | Isi | Usaha | Gerbang keluar |
|---|---|---|---|
| **0 Fondasi** | Penentu bersama; penutup bersama (pos dari rutin di semua jalur, tautan, sinyal); anti-duplikat dua arah; status "tercatat" andal; kata arah generik lintas aplikasi, hapus daftar putih paket; uji sintetis | L | Uji domain lulus, tanpa kasus S1 (uang atau duplikat salah) |
| **1a MVP, dalam aplikasi** | Mulai cepat tanpa daftar putih + dompet per aplikasi; kartu tiga jenis; satu ketuk dan "Catat semua" (Plus); "Cek" langsung ke CATAT; galat terlihat; banner izin di kotak masuk; petunjuk setelah dialog izin; judul slide Beranda sesuai tujuan; hapus ikon filter ganda | M–L | Median ketuk per transaksi ≤1 untuk kartu dikenali |
| **1b MVP, notifikasi bertindak** | Spike latar; mesin tanpa layar + jurnal; receiver dan notifikasi bertindak; pengingat rutin dan anti-duplikat membaca jurnal | L (spike dulu) | Berjalan di ≥3 perangkat/vendor; tidak ada transaksi ganda |
| **E1 "Ingat" dan bentuk dipelajari** | Aturan dari kartu; tanya "Ini transaksi?"; banyak dompet tanpa formulir | M–L | Kartu yang dikoreksi <20% (usulan) |
| **E2 Anggaran** | Saran pos tanpa rutin | M | — |
| **E3 Otomatis per bentuk** | Tawaran setelah konfirmasi pertama; pagar nominal | M | Pembatalan otomatis rendah |
| **E4 Lanjutan** | Daftar aturan, Ajari pola yang disederhanakan, filter, contoh; migrasi `walletRules`/pola/ikatan | M–L | Data lama utuh |
| **E5 Permukaan lain** | Quick Settings tile "Catat n transaksi" (S–M); widget layar utama bila data menunjukkan perlu (L) | S–L | Dari data pemakaian |

Alternatif yang ditimbang untuk "tanpa membuka aplikasi" dan tidak dipilih
sebagai jalur utama: widget layar utama (L, penemuan buruk dan dua permukaan
data), Quick Settings tile (murah; jadi E5), shortcut ikon (S, tetap membuka
aplikasi), aktivitas konfirmasi cepat tanpa splash (M; cadangan bila mesin tanpa
layar tidak andal), bubble (L, izin overlay dan risiko kebijakan Play).

## 12. Ukuran keberhasilan (usulan, bukan data)

- Median ketuk per transaksi ≤1 untuk kartu yang dikenali (Plus); 2 untuk Gratis.
- Kartu yang dikoreksi pengguna <20%; nominal terbaca benar >80%.
- Transaksi ganda lolos = 0; transaksi dari notifikasi tertaut ke rutin/pos
  bila ada rencananya.
- Pengguna lolos izin >60%.
- Keberhasilan notifikasi bertindak per vendor (1b): persen tangkapan yang
  berakhir sebagai notifikasi bertindak tanpa membuka aplikasi.

## 13. Risiko

| Risiko | Mitigasi |
|---|---|
| Bentuk dipelajari dari satu contoh terlalu luas atau sempit | Pratinjau "Seperti: …", bentuk bisa dimatikan/dihapus, otomatis hanya setelah konfirmasi tanpa ubahan, pagar nominal |
| Layanan dimatikan vendor Android | Antrean mentah tetap cadangan; fitur dinyatakan best effort; ukur per vendor |
| Dua mesin menulis Hive | Mesin tanpa layar hanya membaca; jurnal native; penulis tunggal |
| Pengingat rutin berbunyi untuk yang sudah dicatat dari notifikasi | Pengingat dan anti-duplikat membaca jurnal |
| "Ingat" membuat aturan keliru diam-diam | Snackbar Batalkan, terlihat di Lanjutan |
| Tanpa saklar, rilis publik ikut menyalakan fitur | Branch sendiri dan jalur internal sampai gerbang tahap terpenuhi |
| Izin pendengar notifikasi perlu ditinjau Play sebelum produksi | Perbarui pengungkapan dan Keamanan Data; tinjau deklarasi layanan di `AndroidManifest` (tidak menghalangi internal test) |

## 14. Keputusan terbuka

- **KT-N2** (ditunda pemilik 4 Nov 2026) Ambang kartu yang dikoreksi (usulan
  <20%) dan pagar nominal besar (usulan >10× median). Dijawab sebelum T-26.8
  (ukuran keberhasilan) dan sebelum E3 dikerjakan.
- **KT-N3** Penulisan langsung ke buku besar dari mesin tanpa layar (sesudah
  spike) dibanding jurnal saja.
