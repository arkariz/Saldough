# Transaksi rutin, anggaran rutin, dan perkiraan arus kas

**Status:** Diputuskan pemilik 2 Oktober 2026 (§14). Keputusan domain dan
arsitekturnya di [ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)
(Accepted 2 Okt 2026). Dikerjakan di Fase 15 (TASK_LIST).
**Mengubah cakupan:** PRD 2.0 §6 "Di luar MVP" menyebut "Transaksi berulang
otomatis", dan §12 menyebut "Transaksi berulang untuk langganan bulanan".
Dokumen ini mengambil yang kedua tanpa yang pertama: rutin **dijadwalkan**,
bukan **dicatat diam-diam**.
**Revisi 2 Oktober 2026 (sesudah analisis pesaing):** menambah §3A (posisi),
§7A (penjagaan dari kesalahan manusia), §7B (katalog wawasan), dan §7C
(hemat ketukan). Pencocokan dengan catat dari notifikasi dimajukan ke R1,
cara bayar (autodebet atau bayar sendiri) ditambahkan, dan KT-R10 sampai
KT-R13 ditambahkan. Dasarnya ada di
[RECURRING_COMPETITIVE_ANALYSIS.md](RECURRING_COMPETITIVE_ANALYSIS.md).

## 1. Ringkasan

Tiga kemampuan yang saling menopang:

1. **Transaksi rutin**: pemasukan, pengeluaran, dan transfer yang terjadi
   menurut jadwal (gaji tiap tanggal 25, kos tiap tanggal 1, cicilan 12 kali).
   Aplikasi mengingatkan saat jatuh tempo dan membuat pencatatannya tinggal
   satu ketukan.
2. **Anggaran rutin**: anggaran yang lahir sendiri tiap periode dari
   rancangan tetapnya, tanpa dibuat ulang dari template.
3. **Rencana bulan dan perkiraan**: gambaran awal bulan (berapa masuk, berapa
   sudah terikat, berapa uang nganggur) dan perkiraan saldo beberapa
   bulan ke depan, termasuk **titik terendah** sebelum gajian.

Yang menyatukan ketiganya: jadwal dan anggaran adalah **rencana**. Saldo
hanya berubah oleh transaksi yang benar-benar dicatat. Perkiraan selalu
tampil sebagai perkiraan, dan setiap angkanya bisa dibongkar ke baris
asalnya.

```
            RENCANA (tidak menyentuh saldo)              KEJADIAN (menyentuh saldo)
 ┌──────────────────┐   jatuh tempo    ┌──────────────┐
 │ Transaksi rutin  │ ───────────────▶ │ Menunggu     │ ── Catat ──▶  Transaksi
 └──────────────────┘                  │ dicatat      │ ── Lewati ─▶  (tidak ada)
 ┌──────────────────┐   periode baru   └──────────────┘
 │ Anggaran rutin   │ ───────────────▶  Anggaran periode ini ◀── transaksi tertaut
 └──────────────────┘
          │                                     │
          └──────────────┬──────────────────────┘
                         ▼
              Rencana bulan + perkiraan saldo   (dihitung, tidak disimpan)
```

## 2. Masalah dan pekerjaan pengguna

Bukti dari [MANUAL_PROCESS_ANALYSIS.md](../../00-foundation/MANUAL_PROCESS_ANALYSIS.md):

- Bagian "ANGGARAN SEBULAN" di spreadsheet pemilik menghitung **sisa =
  total pemasukan − total anggaran** di awal bulan. Aplikasi belum punya
  padanannya; Beranda hanya menjawab "apa yang sudah terjadi bulan ini".
- Baris tetap (`Kos`, `listrik`, `Wifi`, `Sabil`, `tabung`, cicilan) diketik
  ulang tiap bulan, dan label lama tertinggal (`Kos agustus - september`
  tiga kali).
- Langganan muncul tiap siklus dengan nominal tetap (Netflix Rp65.000) atau
  kira-kira (Claude AI Rp337.760–Rp358.600).
- [ADR-008](../../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md)
  sudah menolak "berulang otomatis penuh tanpa peninjauan" karena nominal
  listrik dan kos berubah, dan angka lama akan diterima diam-diam.

Pekerjaan yang ingin diselesaikan pengguna:

| # | Pekerjaan | Saat ini |
|---|---|---|
| P1 | "Jangan biarkan aku lupa mencatat yang rutin, dan jangan suruh aku mengetiknya lagi." | "Catat lagi" (UX-4) membantu, tapi harus ingat sendiri. |
| P2 | "Di awal bulan, tunjukkan berapa yang masuk, berapa yang sudah terikat, dan berapa yang benar-benar bebas." | Tidak ada. |
| P3 | "Aman nggak sampai gajian? Kapan uangku paling tipis?" | Tidak ada. |
| P4 | "Bulan depan dan sesudahnya bagaimana? Kapan cicilan selesai?" | Tidak ada. |
| P5 | "Anggaran belanja bulanan siap sendiri tiap bulan." | Buat dari template, manual. |

## 3. Prinsip desain

Lima prinsip ini menjadi ukuran setiap keputusan di bawah. Semuanya turunan
dari aturan yang sudah ada, bukan aturan baru yang bertentangan.

1. **Jadwal bukan kejadian.** Membuat, mengubah, menjeda, atau menghapus
   transaksi rutin tidak pernah mengubah saldo. Hanya transaksi tercatat yang
   mengubahnya. (Sejajar aturan 5 dan 6: anggaran bukan pemesanan uang, kerja
   selesai bukan uang diterima.)
2. **Tinjau dulu, otomatis kalau diminta.** Bawaannya setiap kemunculan
   menunggu konfirmasi. Catat otomatis adalah pilihan per rutin, hanya untuk
   nominal tetap. (ADR-008 opsi C ditolak; pola tingkat otomatis ADR-032.)
3. **Satu formulir.** Rutin dibuat dan disunting di formulir CATAT yang sama,
   dengan bagian "Ulangi". Tidak ada formulir transaksi kedua. (Aturan 8.)
4. **Perkiraan tampak sebagai perkiraan.** Angka perkiraan memakai tanda
   `≈`, bingkai putus-putus, dan label "perkiraan"; tidak pernah bergaya
   sama dengan saldo nyata. Setiap angka perkiraan bisa diketuk untuk melihat
   baris-baris penyusunnya. (Prinsip antarmuka 2: uang nyata berbeda dari
   uang rencana.)
5. **Kerumitan bertingkat.** Menjadikan sesuatu rutin cukup satu sakelar
   dengan bawaan yang masuk akal. Pengaturan lanjutan (berakhir setelah N
   kali, nominal bisa berubah, catat otomatis) tersembunyi sampai dibuka.
   (Prinsip antarmuka 5.)
6. **Cegah, deteksi, pulihkan.** Setiap kesalahan yang mungkin (lupa, ganda,
   salah ketik, angka basi) punya penjagaan berlapis: dicegah lewat bawaan
   yang benar, dideteksi sebelum jadi angka salah, dan bisa dipulihkan
   dengan satu ketuk. Otomasi tidak pernah diam: setiap catatan atau
   tautan otomatis tampil di log dan bisa dibatalkan (§7A).
7. **Wawasan harus bisa ditindaklanjuti.** Setiap wawasan menjawab satu
   pertanyaan pengguna dan membawa satu tindakan. Nadanya netral, tanpa skor
   dan tanpa menggurui (§7B).

## 3A. Posisi terhadap pesaing

Ringkasan dari
[RECURRING_COMPETITIVE_ANALYSIS.md](RECURRING_COMPETITIVE_ANALYSIS.md).
Pencatat manual yang dipakai di Indonesia (Money Lover, Money Manager,
Cashew, Wallet) punya rutin, tetapi perkiraannya lemah atau tidak ada, dan
sebagian mencatat rutin diam-diam. Aplikasi perencanaan (Simplifi, Monarch,
PocketSmith) punya perkiraan yang kuat, tetapi bergantung pada koneksi bank AS,
dan perkiraan Simplifi dikeluhkan karena tidak menghitung belanja yang
direncanakan. Fitur ini mengisi tempat yang kosong di antara keduanya. Lima
pembedanya, beserta bagian yang menjawabnya:

| Pembeda | Isinya | Di dokumen ini |
|---|---|---|
| Perkiraan jujur | Anggaran + di luar rencana + bebas hitung ganda, dan setiap angka bisa dibongkar | §7.3–7.5, §8.5 |
| Rutin yang terkonfirmasi sendiri | Dicocokkan dengan catat dari notifikasi; autodebet yang tidak datang dan kenaikan harga ketahuan tanpa koneksi bank | J3, §7A |
| Pengingat yang tahu saldo | Peringatan memakai perkiraan per dompet, bukan sekadar "tagihan besok" | J3, §7B W1 |
| Konteks Indonesia | Bulan keuangan dari tanggal gajian, chip lokal, cicilan sebagai warga kelas satu | J1, J7, KT-R2 |
| Hambatan nyaris nol tanpa angka basi | Satu ketuk, cocok sendiri, suara; otomatis hanya untuk nominal tetap | J3, §7C |

Yang cukup setara dengan pesaing: pengingat, lewati, N kali dan sampai
tanggal, jeda, nominal yang bisa berubah, Jadikan Rutin, total langganan per
bulan dan per tahun, serta saran pola.

## 4. Istilah

| Istilah (id) | Istilah (en) | Arti |
|---|---|---|
| Transaksi rutin | Recurring transaction | Aturan: jenis, nominal, dompet, kategori, catatan, jadwal. Bukan transaksi. |
| Jadwal | Schedule | Tiap minggu / bulan / tahun, berselang N, dengan tanggal patokan. |
| Kemunculan | Occurrence | Satu tanggal dari jadwal, misalnya "Kos, 1 Nov". |
| Menunggu dicatat | Waiting to record | Kemunculan yang tanggalnya sudah tiba dan belum dicatat atau dilewati. |
| Tercatat | Recorded | Kemunculan yang sudah punya transaksi tertaut. |
| Dilewati | Skipped | Kemunculan yang sengaja ditandai tidak terjadi. |
| Terlewat | Missed | Kemunculan lama yang belum diurus, sementara kemunculan sesudahnya sudah tiba. |
| Nominal tetap / kira-kira | Fixed / estimated amount | Kira-kira berarti nominal dikonfirmasi tiap kali dicatat; perkiraannya memakai nominal terakhir yang dicatat. |
| Anggaran rutin | Recurring budget | Template anggaran yang punya jadwal, sehingga anggaran periode baru lahir sendiri. |
| Rencana bulan | Monthly plan | Pemasukan, rutin keluar, dan anggaran satu bulan, beserta yang uang nganggur. |
| Uang nganggur | Unassigned money | Pemasukan terencana bulan itu dikurangi semua pengeluaran terencana (rutin keluar + anggaran), lalu dikurangi belanja di luar rencana yang sudah tercatat. Padanan "Sisa" di spreadsheet. **Bukan saldo**: ia arus satu bulan, bukan isi dompet (§7.2a). |
| Perkiraan saldo | Projected balance | Saldo nyata hari ini ditambah semua yang diperkirakan masuk dan keluar sampai tanggal tertentu. |
| Titik terendah | Lowest point | Perkiraan saldo paling kecil dalam rentang yang dilihat, beserta tanggalnya. |
| Cara bayar | Payment method | Untuk pengeluaran dan transfer rutin: **autodebet** (terjadi sendiri di bank) atau **bayar sendiri** (pengguna yang melakukannya). Menentukan jenis pengingat (J3). |
| Tercocok | Matched | Kemunculan yang ditautkan ke transaksi dari jalur lain (notifikasi, suara, manual), bukan dicatat dari kartu. |
| Belum terlihat | Not seen yet | Kemunculan autodebet yang sudah lewat beberapa hari tanpa transaksi tercocok, padahal notifikasi dompetnya tertangkap. |

## 5. Arsitektur informasi

**Diputuskan pemilik 2 Okt 2026 (KT-R1): tab Anggaran menjadi tab Rencana**
(id "Rencana", en "Plan") dengan tiga segmen di atasnya. Tata letak dan
UI/UX tiap segmen diuraikan di [PLAN_TAB_LAYOUT.md](PLAN_TAB_LAYOUT.md).

```
Beranda | Rencana | Riwayat | Dompet            [suara]
            │                                   [CATAT]
            ├── Bulan ini   ← rencana bulan + perkiraan (bawaan saat dibuka)
            ├── Anggaran    ← isi tab Anggaran yang sekarang, tanpa perubahan
            └── Rutin       ← daftar transaksi rutin
```

Alasannya:

- Ketiganya menjawab prinsip produk 3, "ke mana uang direncanakan pergi".
  Di model domain, `Budget`, `BudgetItem`, dan `BudgetTemplate` sudah
  berada di lingkaran "Rencana"; transaksi rutin masuk ke lingkaran yang
  sama.
- Tab kelima tidak muat di 360dp (alasan yang sama dengan penggantian nama
  Transaksi menjadi Riwayat, T-8.8). "Rencana" dan "Plan" juga lebih pendek
  daripada "Anggaran" dan "Budget".
- Riwayat tetap untuk masa lalu dan Rencana untuk masa depan. Pemisahan waktu
  ini mudah ditebak.

Alternatif yang ditolak: tab Anggaran tetap, dengan segmen "Rutin" dan
"Bulan ini" ditambahkan di dalamnya.

**Titik masuk lain:**

| Tempat | Apa | Kapan tampil |
|---|---|---|
| Beranda | Kartu **Menunggu dicatat** | Ada kemunculan menunggu |
| Beranda | Baris **Perkiraan akhir bulan** di kartu arus bulan ini | Ada minimal satu rutin atau anggaran aktif |
| Beranda | Kartu **Bulan baru dimulai** | Sekali, saat pertama dibuka di awal bulan keuangan |
| CATAT | Baris **Ulangi** di bawah formulir | Selalu, tertutup |
| Rincian transaksi | Tombol **Jadikan Rutin** di samping "Catat lagi" | Transaksi yang belum tertaut ke rutin dan bukan milik pembayaran freelance |
| Formulir anggaran | Sakelar **Ulangi tiap periode** | Selalu |

## 6. Perjalanan pengguna

### J1. Pertama kali: dari kosong ke rencana bulan pertama

Pengguna membuka Rencana › Bulan ini dan belum punya rutin.

1. Keadaan kosong menjelaskan manfaatnya dalam satu kalimat ("Tambahkan yang
   pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas") dan
   menawarkan **chip pembuka** yang lokal: `Gaji`, `Kos/Sewa`, `Listrik`,
   `Internet`, `BPJS`, `Cicilan`, `Paylater`, `Langganan`, `Kirim ke orang
   tua`, `Arisan`, `Tabungan`. Ini kebutuhan rutin orang Indonesia;
   template pesaing AS berpusat pada gaji dua mingguan dan tagihan kartu.
2. Ketuk chip → CATAT terbuka dalam **mode jadwal**, jenis dan kategori
   sudah terisi, "Ulangi: Tiap bulan" sudah nyala, dan tanggal bawaan masuk
   akal bila ada (`BPJS` tanggal 10, `Gaji` tanggal 25, `Kos` tanggal 1).
   `Cicilan` dan `Paylater` langsung membuka "Berakhir setelah N kali".
   Pengguna cukup mengisi nominal, dompet, dan tanggal.
   Bila riwayat sudah punya transaksi yang cocok dengan chip itu (misalnya
   catatan "kos" bulan lalu), CATAT terisi dari transaksi tersebut.
3. Simpan → kembali ke Bulan ini; chip yang sudah dipakai berubah jadi
   centang, dan rencana bulan langsung terisi angka pertamanya.
4. Setelah ada pemasukan dan minimal satu pengeluaran rutin, kartu perkiraan
   muncul di Bulan ini dan di Beranda.

Waktu yang ditargetkan: tiga rutin pertama di bawah dua menit.

### J2. Menjadikan rutin saat mencatat

1. Pengguna mencatat "Netflix Rp65.000" seperti biasa di CATAT.
2. Di bawah formulir ada baris tertutup **Ulangi: Tidak**. Ketuk → terbuka:
   frekuensi (chip `Tiap bulan` / `Tiap minggu` / `Tiap tahun` / `Lainnya`),
   kalimat jadwal yang dibentuk dari tanggal formulir ("tiap tanggal 1"),
   dan tautan **Atur lebih lanjut** (berakhir, nominal kira-kira).
3. Tombol simpan berubah sesuai tanggal:
   - Tanggal hari ini atau lampau → **Catat & Jadwalkan**: transaksi ini
     tercatat **dan** menjadi kemunculan pertama rutinnya.
   - Tanggal di masa depan → **Simpan Jadwal**: tidak ada transaksi yang
     dibuat; yang tersimpan hanya rutinnya.
4. Konfirmasi: "Netflix tercatat. Berikutnya 1 Nov." dengan aksi **Lihat
   rutin**.

Jalan lain ke hasil yang sama: **Jadikan Rutin** di rincian transaksi
membuka CATAT mode jadwal yang terisi dari transaksi itu. Transaksi asalnya
ditautkan sebagai kemunculan pertama, sehingga tidak ada yang tercatat dua
kali.

### J3. Hari jatuh tempo

Aplikasi dibuka pada atau sesudah tanggal kemunculan. Kartu **Menunggu
dicatat** ada di Beranda, tepat di bawah kartu saldo.

- **Nominal tetap** (Netflix): ketuk **Catat** → langsung tercatat dengan
  tanggal kemunculannya, lalu snackbar "Netflix Rp65.000 tercatat ·
  Batalkan". Tanpa membuka formulir. Untuk mengubah sesuatu dulu, ketuk
  **Ubah dulu**, yang membuka CATAT terisi. (KT-R5)
- **Nominal kira-kira** (Listrik): **Catat** selalu membuka CATAT dengan
  kolom nominal terfokus dan terisi perkiraan. Kartu menampilkan "≈" di
  depan nominal.
- **Sudah tercatat dari jalur lain** (notifikasi BRImo, suara, atau manual)
  tetapi belum tercocok sendiri (lihat "Cocok sendiri dari notifikasi" di
  bawah): bila ada transaksi berjenis dan berdompet sama, nominalnya sama (atau
  dalam ±10% untuk nominal kira-kira), tanggalnya ±3 hari, dan belum
  tertaut ke rutin mana pun, kartu menawarkan **"Sudah tercatat? Tautkan ke
  Netflix · 1 Okt"**. Menautkan tidak membuat transaksi baru. Ini penting
  karena catat dari notifikasi (ADR-032) bisa sudah mencatatnya lebih dulu.
- **Tidak terjadi bulan ini** (libur langganan, kos dibayar di muka):
  **Lewati** → "Dilewati · Batalkan". Kemunculan berikutnya tidak berubah.
- **Catat semua (3)**: hanya muncul bila ada lebih dari satu kemunculan
  bernominal tetap yang menunggu. Yang kira-kira tidak ikut.

Tanggal transaksi bawaan adalah **tanggal kemunculan**, bukan hari ini,
karena tanggal transaksi berarti kapan peristiwanya terjadi. Pengguna bisa
mengubahnya di CATAT.

**Cocok sendiri dari notifikasi (R1, KT-R11).** Ini jalur terbaik: nol
ketukan. Bila catat dari notifikasi (ADR-032) menghasilkan transaksi
**atau** draf yang cocok dengan satu kemunculan (jenis dan dompet sama,
nominal persis untuk rutin tetap atau ±10% untuk rutin kira-kira, tanggal
±3 hari), maka:

- Transaksi yang sudah tercatat otomatis langsung **ditautkan** ke
  kemunculannya. Menautkan tidak mengubah saldo, jadi aman dilakukan tanpa
  bertanya. Tautan ini tampil di log "Tercocok otomatis" dengan aksi
  **Lepaskan**.
- Draf di kotak masuk notifikasi diberi label "Cocok dengan rutin Netflix".
  Kategori, catatan, dan pos anggarannya diisi dari rutin, sehingga draf
  yang tadinya kurang lengkap menjadi lengkap dan bisa dicatat satu ketuk.
- Bila nominal notifikasi berbeda dari rutin tetap, pencocokan otomatis
  tidak terjadi. Pengguna ditanya, dan selisihnya menjadi wawasan kenaikan
  harga (§7B W3).
- Bila ada dua kandidat, tidak ada yang ditautkan otomatis. Pengguna
  memilih.

**Sebelum jatuh tempo (cara bayar, KT-R10).**

- **Bayar sendiri** (kos ke pemilik, BPJS lewat aplikasi): pengingat
  H−1 secara bawaan ("Kos Rp1.900.000 jatuh tempo besok"), lewat kartu
  "Akan datang" di Beranda **dan notifikasi lokal sejak R1a** (KT-R9).
  Pada hari jatuh tempo menyusul satu notifikasi lagi untuk semua rutin yang
  menunggu. Untuk nominal tetap, notifikasi punya aksi **Catat**. Aksi itu
  membuka aplikasi lalu mencatat satu ketuk dengan snackbar Batalkan; tidak
  ada pencatatan di latar belakang ([ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md) §3.8).
- **Autodebet** (cicilan, langganan kartu): tidak ada pengingat rutin,
  karena pengguna tidak perlu berbuat apa-apa. Pengingat hanya muncul bila
  perkiraan saldo dompetnya **kurang** pada tanggal itu ("Saldo BCA
  diperkirakan ≈Rp1.200.000 saat Cicilan iPhone Rp2.914.000 besok. Siapkan
  dana di BCA."). Pengingat yang tahu saldo ini tidak dimiliki pesaing
  manual.

**Sesudah jatuh tempo, tidak terlihat (R3).** Untuk rutin autodebet yang
dompetnya tertangkap lewat catat dari notifikasi: bila sampai H+2 belum ada
transaksi yang tercocok, kartu bertanya "Cicilan iPhone belum terlihat di
notifikasi BCA. Sudah terjadi?" dengan pilihan **Catat**, **Belum terjadi**,
dan **Lewati bulan ini**. Ini menangkap autodebet yang gagal karena saldo
kurang sebelum denda menumpuk. Kalimatnya pertanyaan, bukan vonis, karena
notifikasi bisa saja tidak tertangkap.

### J4. Awal bulan: membuka bulan baru

Pertama kali aplikasi dibuka pada atau sesudah awal bulan keuangan. Awal
bulan keuangan **bisa diatur** (KT-R2): tanggal 1 sampai 28, bawaannya
tanggal 1, misalnya tanggal 25 untuk yang gajian tanggal 25. Tanggal 29–31
tidak ditawarkan supaya setiap bulan punya tanggal mulai. Pengaturan ini
berlaku untuk Rencana (uang nganggur, perkiraan, pemilih bulan), kartu bulan
baru, dan kelahiran anggaran rutin. Arus bulan berjalan di Beranda tetap
memakai bulan kalender (FR-HOME-001).

1. Anggaran rutin melahirkan anggaran periode baru (§6 J6, §11).
2. Beranda menampilkan kartu sekali tampil **Oktober dimulai**: pemasukan
   terjadwal, total yang terikat, dan yang uang nganggur, plus satu
   baris peringatan bila ada rutin bernominal kira-kira. Aksi: **Tinjau
   rencana** dan **Nanti**.
3. **Tinjau rencana** membuka Bulan ini dalam mode tinjau, berupa daftar
   periksa tiga langkah yang semuanya bisa dilewati:
   1. *Anggaran yang baru lahir.* "Belanja Bulanan Rp3.068.500, sama dengan
      September." [Sesuai] [Ubah]
   2. *Rutin yang nominalnya bisa berubah.* "Listrik ≈Rp200.000." [Sesuai]
      [Ubah perkiraan]
   3. *Kilas balik bulan lalu.* Rencana vs nyata untuk pemasukan, rutin, dan
      anggaran, plus pos yang lewat rencana. [Lihat]
4. Selesai → "Rencana Oktober siap." Kartu di Beranda hilang.

Ini momen yang menggantikan ritual menyalin blok bulan di spreadsheet.
Lamanya harus di bawah satu menit, dan tidak pernah memblokir pencatatan.

### J5. Melihat ke depan

Pengguna bertanya "aman nggak sampai gajian?" atau "bulan depan
bagaimana?".

1. Beranda menampilkan **Perkiraan akhir bulan ≈ Rp10.921.000** dan
   **Titik terendah ≈ Rp561.000 · 24 Okt**. Ketuk → Rencana › Bulan ini.
2. Bulan ini: grafik perkiraan saldo harian (garis utuh sampai hari ini,
   putus-putus sesudahnya), rencana bulan, dan jadwal bulan ini.
3. Geser atau ketuk `›` → November (perkiraan). Semua angka berawalan `≈`.
   Di atas, strip tiga bulan: `Okt ≈10,9 jt · Nov ≈13,1 jt · Des ≈15,2 jt`.
4. Penyaring dompet: "Semua dompet" atau satu dompet. Perkiraan per dompet
   ikut menghitung transfer, sehingga peringatan seperti "Saldo BCA
   diperkirakan minus saat Cicilan iPhone, 10 Okt. Siapkan dana di BCA
   sebelum tanggal itu" bisa muncul. Kalimatnya menyarankan tindakan
   pengguna di luar aplikasi, tidak pernah menawarkan "transfer sekarang".

### J6. Anggaran rutin

1. Di formulir anggaran ada sakelar **Ulangi tiap periode** (mati secara
   bawaan). Nyala → di bawahnya tertulis "Anggaran ini lahir lagi tiap
   bulan mulai 1 Nov, dengan pos yang sama".
2. Saat periode berakhir, anggaran periode berikutnya lahir sendiri dengan
   dompet, periode, nama, dan pos yang sama (setiap pos dengan id baru,
   seperti template sekarang).
3. Menyunting anggaran rutin memakai pola kalender yang sudah dikenal:
   - Menambah pos → "Tambahkan juga ke periode berikutnya?" Bawaannya
     **Hanya periode ini**, karena pos baru biasanya insidental (Kulkas,
     Barber). Ini meneruskan keputusan ADR-008: baris baru insidental secara
     bawaan.
   - Mengubah nominal atau menghapus pos → **Hanya periode ini** /
     **Periode ini dan berikutnya**.
   - Mematikan sakelar → periode berjalan tetap ada, periode berikutnya
     tidak lahir lagi.
4. Anggaran periode lalu tidak pernah ikut berubah.

### J7. Mengubah, menjeda, dan menyelesaikan rutin

- **Harga naik** (kos naik jadi Rp2.100.000): ubah nominal di rincian rutin.
  Berlaku untuk kemunculan yang belum tercatat; transaksi lama tidak
  berubah. Kalimat di layar: "Berlaku mulai kemunculan berikutnya, 1 Nov."
- **Pindah dompet** (gaji pindah ke Jago): sama, berlaku ke depan.
- **Jeda** (berhenti langganan sementara): tidak ada kemunculan yang
  menunggu atau diperkirakan sampai dilanjutkan.
- **Selesai sendiri** (cicilan 12/12 tercatat): rutin pindah ke kelompok
  Selesai, dan kartu Beranda menampilkan sekali "Cicilan iPhone selesai,
  12 dari 12 tercatat." Momen kecil yang memuaskan.
- **Hapus**: transaksi yang sudah tercatat tetap ada dan tetap di Riwayat;
  hanya tautannya yang menjadi rutin terhapus. Dialog menyatakannya.

### J8. Lama tidak membuka aplikasi

Pengguna kembali sesudah tiga minggu.

- Tiap rutin hanya menampilkan **satu** kemunculan menunggu, yaitu yang
  terbaru. Kemunculan yang lebih lama digabung jadi "2 terlewat" yang bisa
  dibuka untuk dicatat atau dilewati satu per satu. Kartu Beranda tidak
  berubah jadi tembok berisi 15 baris.
- Anggaran rutin hanya melahirkan periode **yang sedang berjalan**, bukan
  periode kosong yang terlewat.
- Perkiraan hanya menghitung kemunculan menunggu milik bulan berjalan
  (§7.3); yang terlewat tidak.

## 7. Aturan perhitungan

Semua di bawah ini fungsi murni yang dihitung saat dibaca, tidak disimpan,
dan tunduk pada aturan 1 (`int` sen). Pembagian selalu membuang sisa ke hari
terakhir supaya jumlahnya persis.

### 7.1 Kemunculan

- Patokan bulanan disimpan sebagai **hari patokan**, bukan tanggal terakhir
  yang dipakai. Patokan 31 menjadi 30 Nov, 28/29 Feb, lalu kembali 31 Des.
  Tanpa aturan ini, jadwal bergeser permanen ke tanggal 28 sesudah Februari.
  Penjepitannya sama dengan `BudgetPeriod.endFrom`.
- "Berakhir setelah N kali" menghitung kemunculan di jadwal, apa pun
  statusnya. Kemunculan ke-k ditampilkan "k/N".
- Status diturunkan, tidak disimpan, kecuali penanda dilewati:
  tercatat ⇔ ada transaksi bertaut `(ruleId, tanggal)`; dilewati ⇔ tanggal
  ada di daftar lewati; menunggu ⇔ tanggal ≤ hari ini, bukan keduanya, dan
  merupakan kemunculan terbaru yang sudah tiba; terlewat ⇔ seperti menunggu
  tetapi bukan yang terbaru. Menghapus transaksinya mengembalikan
  kemunculan ke menunggu.

### 7.2 Rencana bulan

Untuk satu bulan keuangan M (mulai tanggal awal bulan keuangan, KT-R2):

```
pemasukan        = Σ pemasukan tercatat di M
                 + Σ kemunculan pemasukan rutin di M yang belum tercatat/dilewati
rutin keluar     = Σ kemunculan pengeluaran rutin di M (tercatat + belum,
                   tanpa yang dilewati), kecuali yang tertaut ke pos anggaran
                   (sudah terhitung di baris anggaran)
anggaran         = Σ rencana anggaran yang periodenya jatuh di M
                   (untuk bulan depan: anggaran rutin yang akan lahir)
uang nganggur = pemasukan − rutin keluar − anggaran
dipindahkan      = Σ transfer rutin di M   (ditampilkan terpisah, tidak
                                            mengurangi apa pun)
```

Setiap baris tampil sebagai `tercatat / rencana` dengan bilah progres yang
sama dengan bilah anggaran. Pengeluaran di luar rutin dan anggaran **tidak**
masuk rencana bulan; ia hanya masuk perkiraan saldo (§7.3).

### 7.2a Uang nganggur yang dipantau (revisi 2 Okt 2026)

Permintaan pemilik: memantau berapa **uang nganggur** yang tersisa dari
semua pemasukan terencana dikurangi semua pengeluaran terencana. Angka
rencana di §7.2 hanya menjawab "berapa di awal bulan". Supaya bisa dipantau,
angka itu harus ikut berkurang oleh kejadian yang **tidak** ada di rencana:

```
uang nganggur rencana = pemasukan terencana − rutin keluar − anggaran   (§7.2)
sisa uang nganggur    = uang nganggur rencana
                      − belanja di luar rencana yang sudah tercatat bulan ini
                      − kelebihan pos anggaran (terpakai di atas rencana)
                      + pemasukan di luar rencana yang sudah tercatat (bonus, refund)
                      ± selisih nominal rutin yang tercatat beda dari rencananya
```

Transfer tetap tidak dihitung (aturan 7). Transfer rutin ke Tabungan
ditampilkan sebagai keterangan "rencananya dipindah ke Tabungan, tetap
uangmu" (KT-R14).

**Hubungannya dengan saldo** (dipakai sebagai kalimat penghubung di kartu
saldo, seluruh dompet):

```
perkiraan saldo akhir bulan = saldo awal bulan + sisa uang nganggur
                            − perkiraan belanja di luar rencana sisa bulan
```

Contoh §7.6, ditambah Rp57.000 belanja di luar rencana yang sudah tercatat 1–2
Okt (sudah tercermin di saldo nyata Rp6.500.000):

```
saldo awal Okt        = 6.500.000 + 1.900.000 + 368.500 + 57.000 = 8.825.500
sisa uang nganggur    = 3.052.500 − 57.000                        = 2.995.500
akhir Okt             = 8.825.500 + 2.995.500 − 900.000            = 10.921.000
```

Hasilnya sama dengan §7.6, jadi kedua kartu memakai satu hitungan yang sama
dan bisa saling dicek.

### 7.3 Perkiraan saldo harian

Dari hari ini `t0` sampai tanggal akhir `T`, untuk satu dompet atau seluruh
dompet aktif:

```
saldo(t0)   = saldo tercatat sekarang (nyata)
lalu, untuk setiap hari d dari t0 sampai T:
  + kemunculan pemasukan rutin bertanggal d
  + pembayaran freelance belum dibayar dengan tanggal d          (KT-R6)
  − kemunculan pengeluaran rutin bertanggal d (tidak tertaut pos)
  − porsi harian anggaran                                        (§7.4)
  − porsi harian "di luar rencana"                               (§7.5)
  ± transfer rutin bertanggal d       (hanya untuk per dompet; total = 0)
pada t0 juga dikurangi/ditambah kemunculan menunggu bulan berjalan
  (dianggap sudah terjadi tetapi belum dicatat)
titik terendah = min saldo(d) beserta d-nya
```

### 7.4 Anggaran tanpa hitung ganda

Untuk setiap pos dalam periode yang tersisa:

```
keluar_pos = max(sisa_pos, Σ kemunculan rutin tertaut pos yang belum tercatat)
```

Kemunculan tertaut diletakkan di tanggalnya. Selisih `keluar_pos − tertaut`
dibagi rata ke hari yang tersisa di periode itu (hari ini sampai akhir
periode). Bila tertaut melebihi sisa pos, perkiraan mencatat lewat rencana
dan pos itu diberi tanda peringatan.

Contoh: pos `Kos` sisa Rp2.000.000 dengan rutin Kos tertaut Rp1.900.000
→ keluar Rp2.000.000, bukan Rp3.900.000.

Anggaran bulan-bulan depan memakai rancangan anggaran rutin dengan sisa =
rencana penuh. Anggaran yang tidak rutin hanya terhitung sampai periodenya
berakhir.

### 7.5 Di luar rencana

Tanpa baris ini, perkiraan selalu terlalu optimistis, karena tidak semua
belanja ada di rutin atau anggaran. Rumusnya:

```
rata-rata harian = Σ pengeluaran 3 bulan penuh terakhir yang tidak tertaut pos
                   dan tidak berasal dari rutin ÷ jumlah hari 3 bulan itu
```

Baris ini tampil terang-terangan sebagai "Di luar rencana (rata-rata 3
bulan) ≈Rp30.000/hari" dan bisa dimatikan. Baris ini disembunyikan bila
riwayat belum punya satu bulan penuh. Bawaannya nyala atau mati: KT-R3.

### 7.6 Contoh lengkap

Hari ini 2 Okt 2026. Total saldo nyata Rp6.500.000. Anggaran Belanja
Bulanan (rutin, 1–31 Okt) Rp3.068.500, terpakai Rp368.500. Di luar rencana
Rp30.000/hari.

| Rutin | Jadwal | Nominal | Status Okt |
|---|---|---|---|
| Kos | tiap tgl 1 | Rp1.900.000 | tercatat 1 Okt |
| Netflix | tiap tgl 1 | Rp65.000 | menunggu |
| Listrik | tiap tgl 5, kira-kira | ≈Rp200.000 | terjadwal |
| Cicilan iPhone | tiap tgl 10, 12 kali | Rp2.914.000 | terjadwal, 4/12 |
| Gaji | tiap tgl 25 | +Rp12.000.000 | terjadwal |
| Tabungan (BCA → Tabungan) | tiap tgl 26 | Rp1.000.000 | terjadwal |
| Sabil | tiap tgl 28 | Rp800.000 | terjadwal |

Rencana Oktober:

```
pemasukan          = 12.000.000
rutin keluar       = 1.900.000 + 65.000 + 200.000 + 2.914.000 + 800.000 = 5.879.000
anggaran           = 3.068.500
uang nganggur = 12.000.000 − 5.879.000 − 3.068.500 = 3.052.500
dipindahkan        = 1.000.000 (tidak mengurangi total)
```

Perkiraan saldo total:

```
porsi harian anggaran   = 2.700.000 ÷ 30 hari (2–31 Okt) = 90.000
porsi harian di luar    = 30.000
akhir 24 Okt = 6.500.000 − 65.000 (Netflix menunggu)
             − 23 × 120.000 (2–24 Okt) − 200.000 − 2.914.000
             = 561.000                       ← titik terendah
akhir Okt    = 6.500.000 + 12.000.000
             − (65.000 + 200.000 + 2.914.000 + 800.000)
             − 30 × 120.000
             = 10.921.000
akhir Nov    = 10.921.000 + 12.000.000 − 5.879.000 − 3.068.500 − 30 × 30.000
             = 13.073.500
akhir Des    = 13.073.500 + 12.000.000 − 5.879.000 − 3.068.500 − 31 × 30.000
             = 15.196.000
```

Transfer Tabungan tidak muncul di perkiraan total, tetapi muncul di
perkiraan per dompet: BCA turun Rp1.000.000 dan Tabungan naik Rp1.000.000
pada 26 Okt.

### 7.7 Kasus uji wajib (usulan)

| Rumus | Masukan | Keluaran yang benar |
|---|---|---|
| Perkiraan total dengan transfer rutin | transfer 1.000.000 A → B | total tidak berubah; A −1.000.000, B +1.000.000 |
| Pos dengan rutin tertaut | sisa 2.000.000, tertaut 1.900.000 | keluar 2.000.000 |
| Pos dengan rutin tertaut melebihi | sisa 2.000.000, tertaut 2.500.000 | keluar 2.500.000, pos bertanda peringatan |
| Pembagian harian persis | 100.000.001 sen ÷ 3 hari | 33.333.333, 33.333.333, 33.333.335 |
| Patokan tanggal 31 | mulai 31 Jan, bulanan | 28 Feb (2027), 31 Mar, 30 Apr |
| Berakhir setelah N | 12 kali, mulai 10 Jul 2026 | terakhir 10 Jun 2027 |
| Contoh §7.6 | data §7.6 | titik terendah 561.000 pada 24 Okt; akhir Okt 10.921.000 |
| Pencocokan rutin tetap | rutin 65.000 tgl 1; notifikasi 65.000 tgl 3, dompet sama | tertaut otomatis |
| Pencocokan ditolak | rutin tetap 65.000; notifikasi 79.000 | tidak tertaut; muncul pertanyaan + W3 |
| Dua kandidat | dua transaksi 65.000 dalam ±3 hari | tidak tertaut otomatis |
| Ambang kenaikan harga | 65.000 → 67.000 / 65.000 → 79.000 | tidak ada wawasan (naik 3%) / W3 (naik 21,5%, Rp14.000) |
| Nominal tidak wajar | biasa 65.000, diketik 650.000 | peringatan (10×) |

## 7A. Penjagaan dari kesalahan manusia

Urutannya **cegah → deteksi → pulihkan**. Kesalahan dibagi dua seperti
kebiasaan desain interaksi: *slip* (niatnya benar, tindakannya meleset,
misalnya salah ketik) dan *mistake* (pemahamannya keliru, misalnya mengira
perkiraan adalah uang nyata). Slip dicegah lewat bawaan dan dideteksi lewat
pemeriksaan. Mistake dicegah lewat tampilan yang jujur.

| # | Kesalahan | Jenis | Cegah | Deteksi | Pulihkan | Rilis |
|---|---|---|---|---|---|---|
| E1 | Lupa mencatat kemunculan rutin | Lupa | Kartu Menunggu dicatat; cocok sendiri dari notifikasi; catat otomatis bila diminta | Kemunculan menunggu dan terlewat tampil di Beranda dan Bulan ini | Catat dengan tanggal kemunculan, bukan hari ini | R1 |
| E2 | Lupa membayar sungguhan (cara bayar: bayar sendiri) | Lupa | Pengingat H−1 | — | Di luar aplikasi | R1 kartu, R3 notifikasi |
| E3 | Autodebet gagal karena saldo kurang | Tidak terlihat | Peringatan "siapkan dana" dari perkiraan per dompet | "Belum terlihat di notifikasi" pada H+2 | Catat / Belum terjadi / Lewati | R2, R3 |
| E4 | Tercatat ganda (rutin + notifikasi + manual) | Slip | Satu kemunculan untuk paling banyak satu transaksi; cocok sendiri bila persis | CATAT memperingatkan "Mirip Netflix Rp65.000 · 1 Okt yang sudah tercatat" | Batalkan dari snackbar; Lepaskan tautan | R1 |
| E5 | Salah ketik nominal (nol kebanyakan atau kurang) | Slip | Nominal terisi dari rutin | Peringatan bila nominal ≥5× atau ≤⅕ dari nominal biasanya (KT-R12) | Ubah sebelum simpan | R1 untuk rutin |
| E6 | Nominal basi (listrik naik, langganan naik) | Mistake | Nominal kira-kira selalu dikonfirmasi; perkiraannya memakai nominal terakhir | Kenaikan harga ≥5% **dan** ≥Rp5.000 dari nominal rutin (W3) | "Perbarui rutin" berlaku ke depan | R1 manual, R3 dari notifikasi |
| E7 | Dompet salah | Slip | Dompet terisi dari rutin; dari notifikasi, dompet mengikuti aplikasi sumbernya | Notifikasi dari dompet lain tidak dicocokkan otomatis, melainkan ditanyakan | Ubah transaksi | R1 |
| E8 | Rutin usang (langganan sudah berhenti) | Lupa memperbarui | — | Dilewati 2× berturut-turut, atau tidak terlihat 2×: "Masih berlangganan Spotify?" (W6) | Akhiri atau jeda | R3 |
| E9 | Rencana terhitung ganda (rutin Kos + pos Kos) | Mistake | Saat membuat rutin, tawarkan tautan ke pos yang nama atau nominalnya mirip | Rumus §7.4 tetap aman walau tidak ditautkan | Tautkan belakangan dari rincian rutin | R2 |
| E10 | Perkiraan dibaca sebagai uang nyata | Mistake | `≈`, bingkai putus-putus, label "perkiraan" | — | "Dari mana angka ini" | R1 |
| E11 | Tanggal salah (dicatat terlambat jadi tanggal hari ini) | Slip | Tanggal bawaan = tanggal kemunculan | Tanggal lebih dari 7 hari dari kemunculan → konfirmasi ringan | Ubah | R1 |
| E12 | Lupa mencatat belanja harian (bukan rutin) | Lupa | — | Sesudah 3 hari tanpa catatan apa pun, satu kartu lembut "Ada yang belum dicatat sejak Senin?", tanpa streak dan tanpa angka hari terputus | CATAT | Di luar fitur ini (KT-R13) |

Aturan otomasi yang berlaku untuk semua baris di atas:

- Otomasi **menautkan** lebih bebas daripada **mencatat**. Menautkan tidak
  mengubah saldo; mencatat mengubahnya. Karena itu tautan persis boleh
  otomatis di R1, sedangkan catat otomatis tetap pilihan per rutin dan
  hanya untuk nominal tetap.
- Setiap tindakan otomatis masuk log (Tercatat otomatis / Tercocok otomatis,
  mengikuti pola kotak masuk ADR-032 §3.6) dan bisa dibatalkan.
- Saat ragu (dua kandidat, nominal beda, dompet beda), aplikasi bertanya.
  Jangan menebak.

## 7B. Katalog wawasan

Aturan tampil:

1. Setiap wawasan menjawab **satu pertanyaan** pengguna dan membawa **satu
   tindakan**. Wawasan tanpa tindakan cukup jadi teks di Bulan ini, bukan
   kartu.
2. **Beranda hanya menyorot satu wawasan** sekaligus, yang prioritasnya
   tertinggi. Sisanya ada di Rencana › Bulan ini.
3. **Nadanya netral.** Tidak ada skor kesehatan keuangan, label "boros", atau
   warna merah untuk hal yang bukan peringatan. Rasa bersalah termasuk
   alasan orang berhenti mencatat.
4. Hanya tampil bila datanya cukup (misalnya W9 sesudah satu bulan penuh).
5. Setiap angka bisa dibongkar ("Dari mana angka ini").

| # | Wawasan | Pertanyaan pengguna | Muncul bila | Tindakan | Prioritas Beranda | Rilis |
|---|---|---|---|---|---|---|
| W1 | Dompet diperkirakan kurang sebelum autodebet | "Autodebet besok aman?" | Perkiraan saldo dompet < nominal kemunculan, H−3 sampai H0 | Lihat perkiraan dompet | 1 | R2 |
| W2 | Titik terendah | "Aman sampai gajian?" | Ada rutin. Disorot hanya bila negatif | Buka Bulan ini | 2 bila negatif, selain itu baris biasa | R1 |
| W3 | Kenaikan harga | "Ada yang diam-diam naik?" | Nominal tercatat ≥5% **dan** ≥Rp5.000 di atas rutin | Perbarui rutin / Biarkan | 3 | R1 manual, R3 notifikasi |
| W4 | Uang nganggur | "Berapa yang benar-benar bebas bulan ini?" | Awal bulan, dan selalu di Bulan ini | Tinjau rencana | 4 (awal bulan) | R1 |
| W5 | Total langganan | "Berapa habis untuk langganan?" | ≥2 rutin berkategori langganan | Lihat daftar | — (kepala segmen Rutin: "Rp430.000/bln · Rp5,16 jt/thn") | R1 |
| W6 | Rutin menganggur | "Masih kupakai?" | Dilewati atau tidak terlihat 2× berturut-turut | Akhiri / Jeda / Biarkan | 5 | R3 |
| W7 | Bebas cicilan | "Kapan cicilan selesai, dan sesudahnya bagaimana?" | Ada rutin N kali | Teks di rincian rutin dan Bulan ini: "Mulai Jul 2027 ruang bebas +Rp2.914.000/bln" | — | R2 |
| W8 | Porsi yang sudah terikat | "Berapa yang sudah terpakai sebelum bulan dimulai?" | Ada pemasukan rutin | Teks netral di Bulan ini: "75% pemasukan Oktober sudah terikat (rutin + anggaran)", dibandingkan bulan lalu | — | R2 |
| W9 | Akurasi perkiraan bulan lalu | "Bisa kupercaya angkanya?" | Awal bulan, sesudah satu bulan penuh perkiraan | Langkah kilas balik di tinjau rencana: "Perkiraan September meleset Rp312.000, terbesar dari Belanja" | — | R2 |
| W10 | Rencana vs nyata bulan lalu | "Bulan lalu sesuai rencana?" | Awal bulan | Kilas balik J4 | — | R2 |

**Catatan angka.** W3/E6 memakai **dua ambang sekaligus** (persen dan
nominal), meniru Rocket Money ($1,99 dan 5%), supaya selisih receh tidak
memicu peringatan. Nilai Rp5.000 adalah usulan. W8 di contoh §7.6:
(5.879.000 + 3.068.500) ÷ 12.000.000 = 74,56%, ditampilkan 75%. W5 di atas
hanya contoh tampilan; Rp430.000 × 12 = Rp5.160.000. W9 memakai angka
ilustrasi.

W9 adalah pembeda kecil yang mahal ditiru: aplikasi yang berani menunjukkan
seberapa meleset perkiraannya sendiri membangun kepercayaan, dan pengguna
belajar pos mana yang perlu direvisi.

## 7C. Hemat ketukan

Target efisiensi per tindakan yang paling sering. "Tanpa fitur ini" berarti
keadaan aplikasi sekarang.

| Tindakan | Tanpa fitur ini | Dengan fitur ini |
|---|---|---|
| Mencatat kemunculan rutin bernominal tetap | Buka CATAT, isi formulir (atau "Catat lagi" dari transaksi lama) | **0 ketuk** bila tercocok dari notifikasi; **1 ketuk** dari kartu |
| Mencatat tagihan bernominal berubah | Isi formulir lengkap | 1 ketuk + ketik nominal |
| Mencatat beberapa yang menunggu sekaligus | Satu per satu | **Catat semua (n)** untuk yang bernominal tetap |
| Menjadikan transaksi kemarin rutin | Tidak bisa | Jadikan Rutin: 2 ketuk (tombol, lalu simpan) |
| Menyiapkan 5 rutin pertama | Tidak bisa | Chip lokal terisi; R3: "Saran dari riwayat" bisa memilih banyak sekaligus |
| Membuat rutin lewat suara | Tidak bisa | "Gaji dua belas juta tiap tanggal 25" → CATAT mode jadwal terisi (R3, memperluas paket bahasa ADR-029 dengan frasa jadwal) |
| Menyiapkan anggaran bulan baru | Buat dari template | 0 (lahir sendiri) + tinjau di bawah 1 menit |
| Mencatat dari pengingat (R3) | — | Aksi **Catat** di notifikasi untuk nominal tetap, tanpa membuka aplikasi |

## 8. Layar

> **Diperbarui 2 Okt 2026:** tata letak final tab Rencana ada di
> [PLAN_TAB_LAYOUT.md](PLAN_TAB_LAYOUT.md). Wireframe §8.2 (Rutin) dan §8.5
> (Bulan ini) di bawah adalah draf awal yang **sudah digantikan**; §8.1,
> §8.3, §8.4, dan §8.6 tetap berlaku.

Gambar di bawah adalah wireframe tata letak, bukan desain visual. Gaya
mengikuti ADR-015/016/020: kartu bergaris tepi tegas, bayangan keras,
nominal tabular. **Perkiraan memakai bingkai putus-putus** (pola
`_DashedDivider` di Beranda) dan tanda `≈`. Ikon rutin memakai
`icon_transaction_recurring_expense` dan `_income` dari rujukan pemilik
yang belum dikonversi (T-7.4 mencatat keduanya belum punya kunci).

### 8.1 CATAT dengan bagian Ulangi

```
┌ CATAT PENGELUARAN ──────────────────┐
│ Nominal        Rp 65.000            │
│ Dompet         BCA                ▾ │
│ Kategori       Langganan          ▾ │
│ Tanggal        1 Okt 2026           │
│ Catatan        Netflix              │
│ Pos anggaran   —                  ▾ │
│ ┌─────────────────────────────────┐ │
│ │ ↻ Ulangi      [Tiap bulan    ●] │ │   ← tertutup: "↻ Ulangi: Tidak"
│ │   tiap tanggal 1                │ │
│ │   [Tiap minggu][Tiap bulan]     │ │
│ │   [Tiap tahun][Lainnya…]        │ │
│ │   Atur lebih lanjut ›           │ │   ← berakhir, nominal kira-kira,
│ └─────────────────────────────────┘ │     catat otomatis (R3)
│ [      CATAT & JADWALKAN          ] │   ← "SIMPAN JADWAL" bila tanggal > hari ini
└─────────────────────────────────────┘
```

### 8.2 Rencana › Rutin

```
 [Bulan ini] [Anggaran] [Rutin]
┌─────────────────────────────────────┐
│ Bulan ini  masuk ≈12,0 jt           │
│            keluar ≈5,88 jt          │
└─────────────────────────────────────┘
 [Semua] [Masuk] [Keluar] [Transfer]
 MENUNGGU DICATAT
 ⟳− Netflix          Rp65.000   [Catat]
    BCA · 1 Okt · kemarin
 AKAN DATANG
 ⟳− Listrik         ≈Rp200.000
    BCA · 5 Okt
 ⟳− Cicilan iPhone  Rp2.914.000
    BCA · 10 Okt · 4/12   ▓▓▓░░░░░░░░░
 ⟳+ Gaji           +Rp12.000.000
    BCA · 25 Okt
 ⇄  Tabungan        Rp1.000.000
    BCA → Tabungan · 26 Okt
 DIJEDA (1) ›   SELESAI (2) ›
                                  [ + ]
```

Diurutkan menurut kemunculan berikutnya. Rutin tanpa kemunculan menunggu
tidak punya tombol di baris; ketuk baris untuk rincian.

### 8.3 Rincian rutin

```
 ← Cicilan iPhone                    ⋮   (Ubah · Jeda · Hapus)
┌─────────────────────────────────────┐
│ Rp2.914.000        Pengeluaran      │
│ Tiap tanggal 10 · BCA · Cicilan     │
│ 12 kali, berakhir 10 Jun 2027       │
│ ▓▓▓░░░░░░░░░  3 dari 12 tercatat    │
└─────────────────────────────────────┘
 BERIKUTNYA
 10 Okt  Rp2.914.000            [Lewati]
 10 Nov  Rp2.914.000            [Lewati]
 10 Des  Rp2.914.000            [Lewati]
 TERCATAT
 10 Sep  Rp2.914.000  ›   (ke rincian transaksi)
 10 Agu  Rp2.914.000  ›
 10 Jul  Rp2.914.000  ›
```

### 8.4 Beranda

```
┌ SALDO TOTAL ────────────────────────┐
│ Rp6.500.000                         │
└─────────────────────────────────────┘
┌ MENUNGGU DICATAT (2) ───────────────┐   ← hanya bila ada
│ Netflix        Rp65.000    [Catat]  │
│ BCA · 1 Okt          Ubah dulu · Lewati
│ Listrik       ≈Rp200.000   [Catat]  │
│ BCA · 5 Okt                 Lewati  │
│ Sudah tercatat? Tautkan ke          │   ← hanya bila ada kandidat
│ "Netflix · 1 Okt (notifikasi)"  ›   │
└─────────────────────────────────────┘
┌ ARUS OKTOBER ───────────────────────┐
│ Masuk Rp0        Keluar Rp2.268.500 │
│ ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │
│ Perkiraan akhir bulan ≈Rp10.921.000 │   ← putus-putus, berlabel
│ Titik terendah ≈Rp561.000 · 24 Okt ›│
└─────────────────────────────────────┘
 (anggaran, freelance, transaksi terbaru seperti sekarang)
```

`Keluar Rp2.268.500` adalah pengeluaran nyata yang sudah tercatat (Kos
Rp1.900.000 + belanja Rp368.500), bukan perkiraan.

Kartu **Menunggu dicatat** memakai pola yang sama dengan kotak masuk catat
dari notifikasi (ADR-032 §3.6), supaya dua sumber "menunggu konfirmasi"
terasa satu sistem. Apakah keduanya digabung jadi satu kartu: KT-R7.

### 8.5 Rencana › Bulan ini

```
 [Bulan ini] [Anggaran] [Rutin]
 ‹  OKTOBER 2026  ›           Semua dompet ▾
┌┄ PERKIRAAN ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
┆ Akhir bulan        ≈Rp10.921.000    ┆
┆ Titik terendah     ≈Rp561.000 · 24 Okt
┆  ▁▂▃▃▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▇▇▇▇▇▆      ┆   ← utuh s.d. hari ini, putus-putus sesudahnya
┆ Okt ≈10,9 jt · Nov ≈13,1 jt · Des ≈15,2 jt
└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
 RENCANA OKTOBER               tercatat / rencana
 Pemasukan          Rp0 / Rp12.000.000        ░░░░░░░░
 Rutin keluar   Rp1.900.000 / Rp5.879.000     ▓▓▓░░░░░
 Anggaran         Rp368.500 / Rp3.068.500     ▓░░░░░░░
 ─────────────────────────────────────
 Uang nganggur           Rp3.052.500
 Dipindahkan antardompet      Rp1.000.000
   (tidak mengurangi total uangmu)
 Di luar rencana  ≈Rp30.000/hari     [●]   ← sakelar, hanya memengaruhi perkiraan
 JADWAL OKTOBER
  1 Okt  Kos             −Rp1.900.000   ✓ tercatat
  1 Okt  Netflix            −Rp65.000   ● menunggu
  5 Okt  Listrik          ≈−Rp200.000
 10 Okt  Cicilan iPhone  −Rp2.914.000   4/12
 25 Okt  Gaji           +Rp12.000.000
 26 Okt  Tabungan        ⇄Rp1.000.000
 28 Okt  Sabil             −Rp800.000
```

Bulan depan memakai tata letak yang sama. Semua nominal berawalan `≈`,
judulnya "NOVEMBER 2026 · PERKIRAAN", dan kolom tercatat hilang.

Ketuk angka perkiraan mana pun → lembar "Dari mana angka ini" yang
menjabarkan baris rumus §7.3 dengan nominalnya. Ini yang membuat pengguna
percaya pada angkanya.

### 8.6 Formulir anggaran

```
 ...pos-pos...
 Total rencana anggaran       Rp3.068.500
┌─────────────────────────────────────┐
│ ↻ Ulangi tiap periode          [●]  │
│   Lahir lagi tiap bulan mulai 1 Nov │
│   dengan pos yang sama.             │
└─────────────────────────────────────┘
```

Dialog saat menyunting anggaran rutin:

```
┌ UBAH POS "SAYUR" ───────────────────┐
│ Berlaku untuk:                      │
│ ( ) Hanya Oktober                   │
│ (●) Oktober dan berikutnya          │
│              [Batal]  [Simpan]      │
└─────────────────────────────────────┘
```

## 9. Keadaan dan kasus tepi

| Keadaan | Perilaku |
|---|---|
| Belum ada rutin | Bulan ini: penjelasan satu kalimat + chip pembuka (J1). Beranda: baris perkiraan disembunyikan (FR-HOME-005: sembunyikan kartu tanpa isi). |
| Hanya ada pengeluaran rutin, belum ada pemasukan rutin | Rencana bulan tetap tampil; "Uang nganggur" negatif dengan catatan "Belum ada pemasukan terjadwal. Tambahkan gaji?" |
| Perkiraan saldo negatif | Warna peringatan **dan** ikon peringatan (status lewat bentuk dan warna, ADR-015). Kalimatnya netral: "Diperkirakan kurang ≈Rp400.000 pada 24 Okt." Saldo boleh negatif (invarian 12), jadi ini informasi, bukan galat. |
| Dompet rutin diarsipkan | Rutin otomatis dijeda dengan lencana "Dompet diarsipkan", tidak masuk perkiraan. |
| Kategori rutin diarsipkan | Tetap bisa dicatat (CATAT sudah menangani kategori terarsip). |
| Pos tertaut tidak ada di periode kemunculan | Dicatat tanpa pos, sesuai KT-1 (tautan hanya ke pos yang periodenya mencakup tanggal). |
| Tanggal 29–31 | Dijepit ke akhir bulan, patokan tetap (§7.1). |
| Transaksi kemunculan dihapus | Kemunculan kembali menunggu. |
| Transaksi kemunculan disunting (nominal/tanggal) | Tetap tertaut. Untuk nominal kira-kira, nominal barunya menjadi perkiraan berikutnya. |
| Rutin pemasukan mirip freelance | Tidak diblokir. Pembayaran freelance tetap jalur yang benar untuk pemasukan freelance (aturan 6); perkiraan mengambil pembayaran freelance dari datanya sendiri (KT-R6). |
| Memuat / gagal | Pola yang sama dengan layar lain: kerangka, lalu pesan galat dengan "Coba lagi" (`Either` ke state). |

## 10. Kata dan kalimat

Mengikuti "mencatat, bukan melakukan".

| Pakai | Hindari | Alasan |
|---|---|---|
| Catat | Bayar, Proses, Bayar sekarang | Aplikasi tidak memindahkan uang. |
| Tercatat otomatis sesuai jadwal | Dibayar otomatis, Auto-debit | Sama. |
| Menunggu dicatat | Tagihan belum dibayar | Kemunculan bisa pemasukan atau transfer, dan statusnya soal pencatatan. |
| Perkiraan saldo, ≈ | Saldo November | Saldo di masa depan belum ada. |
| Uang nganggur (selalu disertai "bulan ini" dan kalimat "bukan saldo") | Sisa saldo, Uang bebas di dompet | Kata "saldo" khusus untuk isi dompet. Uang nganggur adalah arus satu bulan. |
| Siapkan dana di BCA sebelum 10 Okt | Transfer sekarang | Tindakan ada di luar aplikasi. |
| Dipindahkan antardompet | Pengeluaran tabungan | Transfer tidak pernah pengeluaran (aturan 7). |
| Lewati | Hapus (untuk satu kemunculan) | Melewati tidak menghapus rutinnya. |
| Jatuh tempo besok | Bayar sekarang / Bayar tagihan | Pengingat menyebut kejadiannya, bukan menyuruh membayar lewat aplikasi. |
| Belum terlihat di notifikasi BCA. Sudah terjadi? | Autodebet gagal | Notifikasi bisa saja tidak tertangkap; jangan memvonis. |
| Masih berlangganan Spotify? | Kamu boros langganan | Wawasan netral, tanpa menghakimi. |
| Tercocok dari notifikasi | Dicatat otomatis | Menautkan berbeda dari mencatat. |

Kalimat utama (id / en):

| Kunci | id | en |
|---|---|---|
| Ulangi tertutup | Ulangi: Tidak | Repeat: Off |
| Tombol simpan | Catat & Jadwalkan / Simpan Jadwal | Record & Schedule / Save Schedule |
| Konfirmasi | Netflix tercatat. Berikutnya 1 Nov. | Netflix recorded. Next on Nov 1. |
| Kartu Beranda | Menunggu dicatat | Waiting to record |
| Tautkan | Sudah tercatat? Tautkan ke … | Already recorded? Link to … |
| Bulan baru | Oktober dimulai. Rencanamu sudah tersusun dari rutin. | October has started. Your plan is built from your recurring items. |
| Perkiraan kosong | Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas. | Add what comes every month, then see what's truly free. |
| Selesai | Cicilan iPhone selesai, 12 dari 12 tercatat. | iPhone installment complete — 12 of 12 recorded. |
| Siapkan dana | Saldo BCA diperkirakan kurang untuk Cicilan iPhone besok. Siapkan dana di BCA. | BCA is projected to be short for the iPhone installment tomorrow. Top up BCA beforehand. |
| Kenaikan harga | Netflix tercatat Rp79.000, biasanya Rp65.000. Perbarui rutin? | Netflix was recorded at Rp79,000, usually Rp65,000. Update recurring? |
| Tercocok | Netflix tercocok dari notifikasi BCA · Lepaskan | Netflix matched from a BCA notification · Unlink |

## 11. Dampak domain (bahan ADR-035)

Bahan asal. Keputusan yang mengikat ada di
[ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md);
bila berbeda, ADR yang berlaku.

- **Entitas baru `RecurringRule`** (lingkaran Rencana): `id`, `kind`
  (`income`/`expense`/`transfer`), `amount` (`int` sen), `amountMode`
  (`fixed`/`estimated`), `walletId` atau `fromWalletId`/`toWalletId`,
  `categoryId?`, `note`, `budgetLink?`, `schedule` (`frequency`,
  `interval`, `anchorDate`, hari patokan), `end` (`none`/`untilDate`/
  `count`), `skippedDates`, `autoRecord`, `isPaused`, `paymentMode?`
  (`autoDebit`/`manual`, hanya untuk pengeluaran dan transfer; kosong
  diperlakukan seperti `manual`), `remindDaysBefore` (bawaan 1).
- **Pencocokan adalah fungsi murni**, misalnya `matchOccurrences(rules,
  transactions)` dengan aturan J3 (jenis, dompet, nominal persis atau ±10%,
  tanggal ±3 hari, satu kandidat). Hasil tautannya ditulis ke
  `Transaction.recurrence` dengan penanda asal (`linkedBy: user|auto`), supaya
  log "Tercocok otomatis" dan aksi Lepaskan bisa dibuat. Log mengikuti
  retensi 7 hari kotak masuk ADR-032 §3.6.
- **Wawasan adalah fungsi murni** (`insightsFor(today, …)` → daftar W1–W10
  beserta prioritas). Tidak ada wawasan yang disimpan; yang disimpan hanya
  penanda "sudah ditutup" per wawasan dan per periode, supaya tidak muncul
  berulang.
- **`Transaction` mendapat `recurrence?: (ruleId, occurrenceDate)`**,
  mirip `freelancePaymentId`. Unik per pasangan. Status kemunculan
  diturunkan dari sini (§7.1), sehingga tidak ada status kedua yang bisa
  menyimpang.
- **Anggaran rutin = `BudgetTemplate` yang punya jadwal**: `schedule?`
  berisi `walletId`, `period`, `anchorDate`, dan `isActive`. `Budget`
  mendapat `templateId?`, dan `BudgetItem` mendapat `templateItemId?` (kunci
  pos yang stabil antarperiode). Tautan rutin ke pos memakai
  `templateItemId`, lalu diselesaikan ke pos periode yang mencakup tanggal
  kemunculan. Dengan begini konsep "template" tetap satu (KT-R4).
- **Kelahiran periode dan catat otomatis berjalan saat aplikasi dibuka**,
  bukan di latar belakang. Tidak ada pekerjaan terjadwal, sesuai pola
  ADR-032 (Dart memproses saat aplikasi hidup).
- **Satu jalur tulis**: Catat satu ketuk, Catat semua, dan catat otomatis
  memanggil `RecordTransaction` (ADR-032 §3.5), memancarkan `LedgerChanges`.
- **Perkiraan adalah fungsi murni** di `shared/` (dipakai Beranda dan
  Rencana), misalnya `projectCashflow(today, wallets, rules, budgets,
  templates, freelancePayments, history)`. Tidak ada entitas tersimpan.
- **Invarian baru**:
  - Transaksi rutin dan anggaran rutin tidak menyentuh saldo.
  - Satu kemunculan menghasilkan paling banyak satu transaksi.
  - Perkiraan total tidak berubah oleh transfer rutin.
  - Pos dengan rutin tertaut tidak dihitung ganda (§7.4).
- **Analitik** (ADR-023): peristiwa tanpa nominal, misalnya
  `recurring_created{source}`, `occurrence_recorded{method:
  one_tap|form|auto|linked}`, `occurrence_skipped`, `plan_viewed{month_offset}`,
  `month_review_completed`.
- **Tur** (ADR-021): kunci spotlight baru untuk baris Ulangi di CATAT,
  segmen Rutin, dan kartu perkiraan.

## 12. Rilis bertahap

Setiap rilis menutup satu lingkaran yang terasa utuh bagi pengguna.

Diputuskan 2 Okt 2026: R1 dibagi dua. Masing-masing bisa dirilis sendiri. Di bagian lain dokumen ini, "R1" berarti R1a + R1b.

| Rilis | Isi | Lingkaran yang tertutup | Belum |
|---|---|---|---|
| **R1a: Rutin** | `RecurringRule`, Ulangi di CATAT (Atur lebih lanjut: berakhir, nominal kira-kira, cara bayar), Jadikan Rutin, chip pembuka lokal, **tab Rencana dengan segmen Anggaran dan Rutin**, rincian rutin, total langganan (W5), kenaikan harga dari nominal tercatat (W3), kartu Menunggu dicatat (catat satu ketuk, ubah dulu, lewati, catat semua), kartu "Akan datang" H−1, **cocok sendiri dari notifikasi** (tautan persis + label draf + log Tercocok), penjagaan E4/E5/E7/E11, **notifikasi lokal** (H−1 bayar sendiri, jatuh tempo, aksi Catat). | P1 | Bulan ini, perkiraan |
| **R1b: Bulan ini** | Bulan keuangan bisa diatur, uang nganggur yang dipantau (§7.2a), perkiraan saldo bulan berjalan dan paling tipis, segmen Bulan ini (§PLAN_TAB_LAYOUT 4.9), baris perkiraan di Beranda. | P2, P3 | Bulan depan, anggaran rutin |
| **R2: Anggaran rutin + ke depan** | Sakelar Ulangi di anggaran, kelahiran periode, dialog "hanya periode ini / dan berikutnya", tautan rutin ke pos (+ saran E9), bulan depan (horizon KT-R8), penyaring dompet di perkiraan, **siapkan dana** (W1, termasuk notifikasinya), bebas cicilan (W7), porsi terikat (W8), kartu Bulan baru dan tinjau rencana (J4) dengan akurasi perkiraan (W9) dan kilas balik (W10). | P4, P5 | Otomasi |
| **R3: Otomasi** | Catat otomatis per rutin (nominal tetap saja), **belum terlihat** H+2 (E3), kenaikan harga dari notifikasi, rutin menganggur (W6), saran "sepertinya rutin" dari riwayat dan dari notifikasi (nominal dan catatan sama, 2–3 bulan berturut-turut), rutin lewat suara, kartu menunggu digabung dengan kotak masuk notifikasi (KT-R7). | Hambatan nyaris nol | — |

Pencocokan dengan notifikasi masuk R1a karena dua alasan. Ini pembeda
terkuat (§3A), dan tanpa pencocokan, pengguna catat dari notifikasi akan
langsung mengalami E4: kemunculan rutin dan transaksi dari notifikasi
tercatat ganda.

Perkiraan bulan depan sengaja menunggu R2. Tanpa anggaran rutin, bulan depan
akan tampak tanpa belanja sama sekali, dan angka yang terlalu bagus lebih
merusak kepercayaan daripada angka yang belum ada.

Di luar ketiganya, untuk nanti: "Coba rencana" (tambahkan pengeluaran
khayalan, misalnya laptop Rp15 jt di Desember, untuk melihat dampaknya pada
titik terendah tanpa menyimpan apa pun).

## 13. Ukuran keberhasilan

| Ukuran | Target awal | Kenapa |
|---|---|---|
| Pengguna aktif dengan ≥3 rutin | 40% dalam 2 minggu sesudah R1 | Perkiraan baru berguna dengan beberapa rutin. |
| Kemunculan yang diurus (dicatat, ditautkan, atau dilewati) dalam 3 hari | ≥80% | Mengukur P1 dan seberapa ringan alurnya. |
| Bagian pencatatan lewat satu ketuk atau tautan | naik dari waktu ke waktu | Hambatan turun. |
| Tinjau rencana awal bulan diselesaikan | ≥50% pengguna rutin | Mengukur ritual J4. |
| Selisih perkiraan akhir bulan vs saldo nyata akhir bulan | mengecil bulan ke bulan | Akurasi; dihitung di perangkat, tidak dikirim. |
| Retensi minggu ke-4 pengguna dengan rutin vs tanpa | lebih tinggi | Bukti fitur membuat pengguna kembali (PRD §3). |
| Bagian kemunculan yang tercocok sendiri (pengguna catat dari notifikasi) | ≥50% | Mengukur pembeda "terkonfirmasi sendiri". |
| Tautan otomatis yang dilepas pengguna | <5% | Pencocokan yang sering salah merusak kepercayaan; di atas ambang ini, perketat aturannya. |
| Transaksi ganda yang dihapus pengguna dalam 7 hari (rutin vs jalur lain) | turun sesudah R1 | Mengukur E4. |
| Peringatan nominal tidak wajar yang berujung "Ubah" | dipantau | Bila hampir selalu diabaikan, ambangnya terlalu sensitif. |
| Wawasan yang ditindaklanjuti (ketuk tindakan) vs ditutup | dipantau per W | Wawasan yang selalu ditutup diturunkan prioritasnya atau dihapus. |

## 14. Keputusan

Seluruhnya diputuskan pemilik 2 Okt 2026: **setuju semua rekomendasi,
kecuali KT-R2 dan KT-R9**.

| KT | Pertanyaan | Keputusan |
|---|---|---|
| KT-R1 | Tempat fitur | Tab Anggaran → **Rencana** dengan segmen Bulan ini / Anggaran / Rutin ([PLAN_TAB_LAYOUT.md](PLAN_TAB_LAYOUT.md)) |
| KT-R2 | Awal bulan keuangan | **Bisa diatur** (tanggal 1–28, bawaan 1), masuk R1b. *Berbeda dari rekomendasi (tanggal 1 dulu).* Arus bulan berjalan di Beranda tetap bulan kalender |
| KT-R3 | "Di luar rencana" di perkiraan | Nyala secara bawaan bila riwayat ≥1 bulan penuh |
| KT-R4 | Template vs anggaran rutin | Satu konsep: anggaran rutin = template berjadwal |
| KT-R5 | Catat satu ketuk | Ya, lewat `RecordTransaction` dengan Batalkan, untuk nominal tetap |
| KT-R6 | Freelance belum dibayar di perkiraan | Masuk dengan label "belum pasti"; tidak dihitung bila tanggalnya lewat |
| KT-R7 | Satu kartu "menunggu" di Beranda | Digabung sesudah R1 stabil (R3) |
| KT-R8 | Horizon perkiraan | Bulan berjalan + 2 bulan, maksimum 12 |
| KT-R9 | Notifikasi lokal | **Masuk R1a.** *Berbeda dari rekomendasi (R3).* "Siapkan dana" tetap R2 karena butuh perkiraan per dompet |
| KT-R10 | Cara bayar | Ditanyakan lewat chip `Autodebet` / `Bayar sendiri`, boleh kosong |
| KT-R11 | Tautan otomatis untuk cocok persis | Ya sejak R1a, dengan log dan Lepaskan |
| KT-R12 | Peringatan nominal tidak wajar di seluruh CATAT | Ya, tugas terpisah (B-25) |
| KT-R13 | Kartu "belum ada catatan 3 hari" | Ya, tugas terpisah tanpa streak (B-26) |
| KT-R14 | Transfer ke Tabungan dan uang nganggur | Tidak mengurangi; tampil sebagai keterangan |

## 15. Yang sengaja tidak dikerjakan

- Pembayaran atau transfer sungguhan, auto-debit, atau koneksi bank.
- Catat otomatis bernominal kira-kira.
- Melahirkan periode anggaran yang terlewat saat aplikasi lama tidak dibuka.
- Saran investasi atau nasihat keuangan pribadi. Perkiraan hanya
  menjumlahkan apa yang dicatat dan direncanakan pengguna.
- Perkiraan berbasis AI. Rumusnya harus bisa dijelaskan baris per baris
  (§8.5 "Dari mana angka ini").
- Streak harian, skor kesehatan keuangan, atau label "boros". Rasa bersalah
  termasuk alasan utama orang berhenti mencatat
  ([analisis pesaing](RECURRING_COMPETITIVE_ANALYSIS.md) §6 O7).
- Perkiraan puluhan tahun, bunga majemuk, dan skenario berlapis ala
  PocketSmith. "Coba rencana" (§12) sudah cukup untuk pertanyaan "bisa
  beli?".
- Mencatat otomatis saat ragu. Dua kandidat, nominal beda, atau dompet beda
  selalu ditanyakan (§7A).
