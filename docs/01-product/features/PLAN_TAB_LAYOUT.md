# Tata letak tab Rencana: Bulan ini, Anggaran, Rutin

**Tanggal:** 2 Oktober 2026.
**Status:** Diputuskan pemilik 2 Okt 2026 (§11), direvisi sesudah uji
prototipe (§4.9). Tab Anggaran menjadi **Rencana** (en: **Plan**) dengan
tiga segmen (KT-R1). Segmen Anggaran dan Rutin masuk R1a, Bulan ini R1b
([ADR-034](../../02-architecture/adr/0034-transaksi-rutin-rencana-dan-perkiraan.md)).
**Berkaitan:** [RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md)
(perilaku dan rumus; dokumen ini menggantikan wireframe §8.2 dan §8.5 di
sana), [RECURRING_COMPETITIVE_ANALYSIS.md](RECURRING_COMPETITIVE_ANALYSIS.md),
[ADR-015](../../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md),
[ADR-016](../../02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md),
[ADR-020](../../02-architecture/adr/0020-hierarki-penekanan-bahasa-visual-pixel.md).

Semua angka di wireframe memakai contoh
[RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md) §7.6 (hari ini 2 Okt
2026), jadi angka antarlayar saling cocok.

## 1. Ringkasan keputusan

1. **Tiga tingkat kontrol dengan tiga rupa.** Navigasi antarsegmen memakai
   **sub-tab** baru yang menempel di bawah app bar. Pilihan di formulir tetap
   memakai `AppSegmented`, dan penyaring memakai **chip**. Penyaring status
   Anggaran yang sekarang bergaya tab diubah jadi chip, supaya tidak ada tab
   di dalam tab (§3.2).
2. **Tanpa gestur geser antarsegmen.** Bulan ini punya grafik yang bisa
   digeser jari dan pemilih bulan, jadi segmen hanya berpindah lewat ketukan
   (§3.3).
3. **Setiap segmen dibuka oleh satu kartu utama dengan satu angka**, seperti
   pola `AppHeroCard` di tab lain. Bulan ini: *Uang nganggur*. Anggaran:
   *Sisa rencana aktif* (tetap seperti sekarang). Rutin: *Masih akan keluar
   bulan ini* (§3.4).
4. **Bulan ini tersusun seperti air terjun**: rencana (pasti) → perkiraan
   (≈) → jadwal. Peringatan risiko naik ke paling atas sebagai banner hanya
   bila ada (§4).
5. **Titik terendah ditulis, bukan disembunyikan di grafik.** Pengguna
   Simplifi meminta hal ini karena di sana titik terendah harus dicari dengan
   menyentuh grafik (§2, §4.5).
6. **Penyaring dompet hanya berlaku untuk perkiraan**, dan karena itu
   letaknya di dalam kartu perkiraan, bukan di atas layar. Rencana bulan
   selalu total (§4.4).
7. **Rutin dikelompokkan menurut apa yang perlu dilakukan**: Menunggu →
   Bulan ini → Nanti → Dijeda/Selesai, dengan chip jenis sebagai penyaring
   (§6).
8. **Anggaran berubah minimal**: penyaring status menjadi chip, lencana "↻
   Rutin" di kartu, dan tidak ada app bar sendiri. Isi lainnya tetap (§5).

## 2. Riset: pola dan pelajaran

| Pola | Bukti | Keputusan kita |
|---|---|---|
| Tab sekunder untuk sub-navigasi di bawah tujuan utama | Material: tab sekunder dipakai sebagai sub-navigasi dari tab utama; *segmented button* untuk pilihan atau mengganti tampilan, bukan pengganti tab navigasi | Sub-tab baru untuk segmen; `AppSegmented` tetap untuk pilihan di formulir |
| Kontrol bersegmen untuk menyaring sebagian isi, tab untuk isi yang benar-benar berbeda | Pedoman sistem desain (Trimble, Fluent) | Isi tiga segmen memang berbeda, jadi segmen = navigasi. Penyaring di dalamnya = chip |
| Jangan memasang tab yang bisa digeser di atas konten yang juga bisa digeser | Material tabs | Tidak ada geser antarsegmen |
| Spending plan berbentuk air terjun: Income → Bills → Planned → Other → Available | Simplifi Spending Plan | Kartu utama Bulan ini: Pemasukan − Rutin keluar − Anggaran = Uang nganggur |
| Titik terendah perkiraan sulit ditemukan di grafik | Permintaan komunitas Simplifi "Add Lowest Projected Balance" | Titik terendah ditulis sebagai teks dan ditandai di grafik |
| Rutin dikelompokkan menurut waktu dan status | Copilot: This Month (paid / left to pay), In the Future, Paused, Archived. Monarch: Upcoming / Complete | Menunggu / Bulan ini / Nanti / Dijeda / Selesai |
| Status rutin dibedakan lewat warna di kalender | Monarch: hijau + centang = sesuai, kuning = nominal beda, biru = akan datang | Lima status dengan ikon **dan** warna (§7.1), karena ADR-015 melarang status lewat warna saja |
| Kalender bulanan sebagai pilihan tampilan | Monarch (daftar/kalender), PocketSmith (kalender saldo) | Tidak di R1/R2. Di 360dp grid kalender berisi nominal terlalu sesak; fungsi "kapan" sudah dijawab grafik + jadwal (KT-L5) |
| Satu angka utama per layar | Pola `AppHeroCard` di aplikasi ini; prinsip "satu figur utama per tampilan" | Satu kartu utama per segmen, makna angkanya tetap |

## 3. Kerangka tab Rencana

### 3.1 Struktur

```
┌────────────────────────────────────┐
│ Rencana                            │  ← judul app bar, ikut tergulung saat isi digulir
├────────────────────────────────────┤
│  BULAN INI    ANGGARAN     RUTIN   │  ← sub-tab, MENEMPEL di atas
│  ▀▀▀▀▀▀▀▀▀                         │     (penanda blok 4px di bawah label aktif)
├────────────────────────────────────┤
│                                    │
│  isi segmen (masing-masing punya   │
│  posisi gulir sendiri)             │
│                                    │
│                         [suara]    │
│                         [CATAT]    │  ← FAB global, tidak berubah per segmen
├────────────────────────────────────┤
│ Beranda  Rencana  Riwayat  Dompet  │
└────────────────────────────────────┘
```

### 3.2 Tiga tingkat kontrol, tiga rupa

Satu layar di Rencana bisa memuat sekaligus navigasi segmen, penyaring, dan
pilihan. Kalau ketiganya tampil dengan rupa slab yang sama, pengguna tidak
bisa membedakan "pindah tempat" dari "menyaring di tempat ini".

| Peran | Komponen | Rupa | Contoh |
|---|---|---|---|
| Navigasi (pindah ke isi lain) | **`AppSubTabs`** (baru) | Menempel di bawah app bar, lebar penuh, label kapital 12px, label aktif bertinta `textPrimary` dengan blok `accent` 4px di bawahnya, label lain `textMuted`, tanpa slab dan tanpa bayangan | Bulan ini / Anggaran / Rutin |
| Penyaring (mempersempit isi yang sama) | Chip (`AppQuickChip` atau varian terpilih) | Berbaris, rata kiri, boleh bergulir horizontal, pilihan aktif terisi | Status anggaran, jenis rutin, dompet |
| Pilihan nilai di formulir | `AppSegmented` (sudah ada) | Slab `surfaceMid`, pilihan aktif terisi `accent` | Jenis transaksi di CATAT, periode anggaran |

**Konsekuensinya:** penyaring status di
`budget_filter_bar.dart` (slab + `_StatusTab`, rupanya hampir sama dengan
`AppSegmented`) diganti chip. Tanpa perubahan ini, segmen Anggaran
menampilkan dua baris tab bertumpuk (KT-L2).

Alternatif yang lebih murah: memakai `AppSegmented` sebagai sub-tab. Ditolak
karena `AppSegmented` sudah berarti "pilih nilai" di formulir CATAT (UX-1),
dan satu rupa dengan dua makna melanggar "satu konsep, satu tampilan"
ADR-015.

### 3.3 Perilaku

- **Pindah segmen hanya lewat ketukan.** Tidak ada geser horizontal, karena
  Bulan ini memuat grafik yang digeser jari (§4.5) dan pemilih bulan.
  Transisinya pudar cepat (≤150 ms) atau langsung, tanpa animasi meluncur.
- **Tiap segmen punya posisi gulir sendiri** dan tetap hidup selama shell
  hidup, seperti tab bawah (`IndexedStack`).
- **Segmen yang dibuka:** awal sesi selalu **Bulan ini**; sesudah itu segmen
  terakhir yang dipakai selama aplikasi hidup (KT-L4). Tidak disimpan ke
  penyimpanan.
- **Tombol kembali Android** di segmen mana pun tidak berpindah segmen. Ia
  mengikuti perilaku tab bawah yang sekarang. Segmen tidak membuat tumpukan
  riwayat.
- **Tautan dari tempat lain membuka segmen yang tepat:**

  | Dari | Ke |
  |---|---|
  | Beranda › baris Perkiraan akhir bulan | Rencana › Bulan ini |
  | Beranda › kartu Anggaran | Rencana › Anggaran |
  | Beranda › kartu Menunggu dicatat › Lihat semua | Rencana › Rutin |
  | Bulan ini › baris Rutin keluar / Pemasukan | Rencana › Rutin, chip jenis terpilih |
  | Bulan ini › baris Anggaran | Rencana › Anggaran |
  | Kartu Bulan baru dimulai › Tinjau rencana | Rencana › Bulan ini, mode tinjau |

  Secara teknis ini butuh cara bagi shell untuk menerima "tab + segmen"
  (perluasan pola kunci rute ADR-030). Detailnya masuk ADR-034.
- **FAB tidak berubah per segmen.** CATAT dan suara tetap global (ADR-020
  §6). Menambah rutin dari mana saja cukup lewat CATAT › Ulangi, jadi FAB
  kontekstual tidak dibutuhkan.

### 3.4 Satu kartu utama per segmen

| Segmen | Pertanyaan utama | Angka kartu utama | Kenapa angka ini |
|---|---|---|---|
| Bulan ini | "Berapa yang benar-benar bebas bulan ini?" | **Uang nganggur** | Pasti (hitungan rencana, bukan perkiraan), sehingga pantas tampil di kartu utama yang padat. Ini padanan "Sisa" di spreadsheet pemilik, jawaban ritual awal bulan. Perkiraan (≈) punya kartunya sendiri yang putus-putus |
| Anggaran | "Berapa sisa rencana belanja yang aktif?" | Sisa rencana aktif (`BudgetSummaryCard`, tetap) | Tidak berubah dari sekarang |
| Rutin | "Berapa lagi yang akan keluar bulan ini?" | **Masih akan keluar** (≈ bila ada nominal kira-kira) | Pola "left to pay" Copilot; langsung terkait aksi (siapkan dana) |

Makna angka kartu utama **tidak pernah berganti menurut keadaan**. Bila ada
risiko (dompet kurang, perkiraan negatif), risiko itu tampil sebagai banner di
atas kartu utama, bukan dengan menukar angkanya. Mata pengguna belajar letak
angka; menukar maknanya merusak hafalan itu.

## 4. Segmen Bulan ini

### 4.1 Urutan blok dan alasannya

| # | Blok | Menjawab | Tampil bila |
|---|---|---|---|
| 0 | Banner risiko | "Ada yang perlu kulakukan sekarang?" | Ada W1 (dompet kurang) atau perkiraan total negatif |
| 0 | Kartu tinjau awal bulan | "Bulan baru, rencanaku sudah benar?" | Awal bulan keuangan, sampai selesai atau ditutup |
| 1 | Pemilih bulan | "Bulan mana yang kulihat?" + gambaran akhir tiap bulan | Selalu |
| 2 | Kartu utama: Rencana bulan | "Berapa yang bebas?" | Ada pemasukan atau komitmen |
| 3 | Kartu perkiraan (putus-putus) | "Aman sampai gajian? Kapan paling tipis?" | Ada minimal satu rutin |
| 4 | Jadwal bulan ini | "Apa saja yang akan terjadi, kapan?" | Ada kemunculan di bulan itu |

Urutannya **tetap**, tidak berubah menurut tanggal. Di awal bulan, blok 2
menjadi pusat. Di tengah bulan, blok 3 tetap terlihat tanpa menggulir (lihat
perkiraan tinggi di §4.8), dan bila ada risiko, banner 0 naik ke atas.
Keduanya tertangani tanpa tata letak yang berpindah-pindah.

### 4.2 Wireframe: keadaan normal (2 Okt)

```
 BULAN INI    ANGGARAN     RUTIN
 ▀▀▀▀▀▀▀▀▀
┌──────────┐┌┄┄┄┄┄┄┄┄┄┄┐┌┄┄┄┄┄┄┄┄┄┄┐
│ OKT      │┆ NOV      ┆┆ DES      ┆      ← pemilih bulan (§4.3)
│ ≈10,9 jt │┆ ≈13,1 jt ┆┆ ≈15,2 jt ┆
└──────────┘└┄┄┄┄┄┄┄┄┄┄┘└┄┄┄┄┄┄┄┄┄┄┘
┏ [▣] RENCANA OKTOBER ━━━━━━━━━━━━━━┓   ← AppHeroCard
┃ Uang nganggur                ┃
┃ Rp3.052.500                       ┃   ← angka utama
┃ ┌───────────────────────────────┐ ┃
┃ │ Pemasukan        Rp12.000.000 │ ┃   ← HeroInset, baris bisa diketuk
┃ │ ░░░░░░░░░░  Rp0 tercatat      │ ┃
┃ │ − Rutin keluar    Rp5.879.000 │ ┃
┃ │ ▓▓▓░░░░░░░  Rp1.900.000       │ ┃
┃ │ − Anggaran        Rp3.068.500 │ ┃
┃ │ ▓░░░░░░░░░  Rp368.500         │ ┃
┃ └───────────────────────────────┘ ┃
┃ Dipindahkan antardompet Rp1.000.000┃
┃ tidak mengurangi total uangmu     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
┌┄ PERKIRAAN SALDO ┄┄┄ Semua dompet ▾┐   ← bingkai putus-putus
┆ Akhir Oktober     ≈Rp10.921.000   ┆
┆ Titik terendah    ≈Rp561.000      ┆
┆                   24 Okt          ┆
┆  ‾‾╲___                    ╱‾‾‾   ┆   ← grafik (§4.5)
┆       ╲_ _ _ _ _ _ _ _ _ ●╱       ┆
┆  1   │hari ini        24  31      ┆
┆ Di luar rencana ≈Rp30.000/hari [●]┆
┆ Dari mana angka ini ›             ┆
└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
 JADWAL OKTOBER                         ← §4.6
 ● MENUNGGU
  1 Kam  [ikon] Netflix     −Rp65.000
         BCA                  [Catat]
 ─── hari ini, 2 Okt ───
  5 Sen  [ikon] Listrik    ≈−Rp200.000
 10 Sab  [ikon] Cicilan iPhone
         BCA · 4/12      −Rp2.914.000
 25 Min  [ikon] Gaji     +Rp12.000.000
 26 Sen  [ikon] Tabungan  ⇄Rp1.000.000
 28 Rab  [ikon] Sabil       −Rp800.000
 Sudah lewat (1) ›                      ← Kos ✓ 1 Okt, tertutup
```

### 4.3 Pemilih bulan

- **Chip bulan berderet:** bulan berjalan + horizon (bawaan 2 bulan, KT-R8).
  Setiap chip berisi nama bulan dan perkiraan saldo akhir bulan (`≈`, format
  ringkas "10,9 jt"). Chip aktif berbingkai utuh; chip bulan depan
  berbingkai putus-putus karena seluruh isinya perkiraan.
- Ini sekaligus navigasi **dan** jawaban "bagaimana beberapa bulan ke
  depan" tanpa harus berpindah (P4). Panah ‹ › tidak dipakai; deretan chip
  lebih informatif dengan lebar yang sama.
- Bila horizon lebih dari 3 bulan, deretannya bergulir horizontal. Ini
  satu-satunya gulir horizontal di segmen, terbatas pada deretan chip, dan
  aman karena antarsegmen tidak bisa digeser.
- **Hanya ke depan.** Kilas balik bulan lalu ada di langkah tinjau awal
  bulan (J4) dan di Riwayat (KT-L6).
- Bila satu bulan diperkirakan negatif, chip-nya memakai ikon peringatan
  **dan** warna peringatan.

### 4.4 Kartu utama: Rencana bulan

- **Kepala:** ikon tab Rencana + "RENCANA OKTOBER". Untuk bulan depan:
  "RENCANA NOVEMBER" dengan lencana "PERKIRAAN".
- **Angka utama:** *Uang nganggur*. Bila negatif, angkanya memakai
  tanda minus, ikon peringatan, dan satu kalimat: "Komitmen melebihi
  pemasukan terjadwal Rp…". Warna merah pengeluaran **tidak** dipakai
  (ADR-016: merah adalah warna uang keluar, bukan status).
- **Tiga baris air terjun** di `HeroInset`. Nominal rencana rata kanan dengan
  angka tabular. Di bawahnya bilah bersegmen tipis berarti tercatat terhadap
  rencana (ADR-020 §5 mengizinkan bilah hanya untuk progres terhadap
  rencana), disertai teks "Rp1.900.000 tercatat". Bulan depan tidak
  menampilkan bilah.
- **Setiap baris bisa diketuk:** Pemasukan dan Rutin keluar ke segmen Rutin
  dengan chip jenisnya terpilih; Anggaran ke segmen Anggaran.
- **Dipindahkan antardompet** tampil di luar inset dengan teks sekunder,
  karena transfer tidak ikut hitungan (aturan 7).
- **Penyaring dompet tidak ada di kartu ini.** Rencana bulan selalu total;
  pemasukan dan anggaran tidak bisa dibagi per dompet tanpa aturan baru.

### 4.5 Kartu perkiraan dan grafiknya

**Bingkai:** garis tepi putus-putus 2px, tanpa bayangan keras (bayangan
menyiratkan benda padat; perkiraan bukan benda padat). Semua nominal
berawalan `≈`.

**Penyaring dompet** di kepala kartu (`AppMenuSelectButton`, pola yang sama
dengan penyaring dompet Anggaran). Memilih satu dompet mengubah seluruh kartu
dan grafik, termasuk transfer yang masuk atau keluar dari dompet itu.

**Dua angka tertulis, bukan hanya di grafik:** akhir bulan dan titik
terendah beserta tanggalnya. Grafik adalah penjelas, bukan satu-satunya
tempat angka.

**Spesifikasi grafik** (mengikuti panduan dataviz: satu seri, garis tipis,
latar sepi):

| Unsur | Spesifikasi |
|---|---|
| Bentuk | Grafik garis saldo harian, satu seri. Tanpa legenda; judul kartu sudah menyebut isinya |
| Tinggi | 120dp untuk plot, ditambah label sumbu |
| Garis | 2px, tinta `textPrimary`. **Utuh** dari tanggal 1 sampai hari ini (saldo nyata, dihitung mundur dari saldo sekarang dan transaksi bulan ini). **Putus-putus** (4/4) dari hari ini sampai akhir bulan |
| Hari ini | Garis rambut vertikal 1px `textMuted`, label "hari ini" |
| Titik terendah | Titik 8px bercincin 2px warna permukaan, dengan label langsung "≈561 rb · 24 Okt". Warna peringatan dan ikon bila di bawah nol atau di bawah nominal kemunculan dompet itu (W1); selain itu tinta biasa |
| Garis nol | Garis rambut utuh, hanya bila rentang nilai melewati nol. Area di bawah nol diberi warna peringatan tipis (±10%) |
| Sumbu | X: tanggal 1, hari ini, tanggal titik terendah, dan akhir bulan saja. Y: 2–3 nilai bulat ringkas ("0", "5 jt", "10 jt"), garis rambut utuh, sangat redup. Tidak ada garis kisi putus-putus |
| Warna uang | **Tidak dipakai** di garis. Saldo bukan uang masuk atau keluar; hijau dan merah tetap khusus nominal (ADR-016) |
| Sentuhan | Tekan dan geser di atas grafik → garis bantu vertikal mengikuti tanggal terdekat, gelembung info: "24 Okt · ≈Rp561.000" + kejadian hari itu ("Gaji +Rp12.000.000"). Getar ringan saat melewati titik terendah |
| Aksesibilitas | Satu label semantik: "Perkiraan saldo. Akhir Oktober kira-kira Rp10.921.000. Terendah kira-kira Rp561.000 pada 24 Oktober." Daftar Jadwal dan lembar "Dari mana angka ini" adalah padanan tabelnya |

**Baris "Di luar rencana"** dengan sakelar ada di bawah grafik, bukan di
pengaturan, karena ia mengubah angka yang sedang dilihat dan pengguna perlu
melihat dampaknya seketika (KT-R3).

**"Dari mana angka ini"** membuka lembar berisi rincian §7.3 dokumen
perilaku: saldo nyata hari ini, + pemasukan terjadwal, − rutin keluar,
− porsi anggaran, − di luar rencana, = akhir bulan. Setiap baris bisa
diketuk sampai ke kemunculannya.

### 4.6 Jadwal bulan

- **Kronologis, dipotong garis "hari ini".** Kemunculan menunggu selalu di
  paling atas dalam kelompok "Menunggu", berapa pun tanggalnya. Kemunculan
  yang sudah lewat dan tercatat dilipat ke "Sudah lewat (n) ›" supaya mata
  menghadap ke depan.
- **Anatomi baris** (sama dengan baris di segmen Rutin, §6.3): kolom tanggal
  (angka hari besar, nama hari kecil) | kotak ikon kategori | nama + baris
  meta (dompet, k/N) | nominal bertanda jenis, rata kanan, tabular | aksi atau
  status.
- **Aksi di baris hanya untuk yang menunggu**: tombol tersier "Catat". Baris
  lain cukup diketuk untuk membuka rincian rutin.
- Pembayaran freelance yang diharapkan (KT-R6) tampil di sini dengan lencana
  "belum pasti".
- Anggaran **tidak** muncul sebagai baris, karena dibagi harian, bukan
  kejadian bertanggal. Ia sudah terwakili di kartu utama dan grafik.

### 4.7 Varian keadaan

**Ada risiko (banner 0):**

```
┌ ⚠ SIAPKAN DANA ─────────────────────┐   ← warna peringatan + ikon
│ Saldo BCA diperkirakan kurang       │
│ ≈Rp1.714.000 saat Cicilan iPhone,   │
│ 10 Okt.                             │
│ Lihat perkiraan BCA ›               │   ← membuka kartu perkiraan, dompet BCA
└─────────────────────────────────────┘
 (pemilih bulan, kartu utama, … seperti biasa)
```

(Saldo BCA ≈Rp1.200.000, cicilan Rp2.914.000; selisihnya Rp1.714.000.)
Paling banyak satu banner. Bila ada beberapa risiko, yang paling dekat
tanggalnya yang tampil, dengan "+1 lainnya".

**Tinjau awal bulan (J4):**

```
┌ OKTOBER DIMULAI ────────────── 1/3 ┐
│ ✓ Anggaran Belanja Bulanan sesuai   │
│ ○ Listrik ≈Rp200.000 — sesuai?      │
│   [Sesuai]  [Ubah perkiraan]        │
│ ○ Kilas balik September ›           │
│ [      SELESAI MENINJAU      ]      │   ← satu-satunya tombol primer di segmen
│ Nanti                               │
└─────────────────────────────────────┘
```

Langkah-langkahnya bisa dicentang di tempat tanpa pindah layar. "Nanti"
melipatnya menjadi satu baris "Tinjau rencana Oktober (1/3) ›" di atas
pemilih bulan sampai akhir minggu pertama.

**Bulan depan (NOV):** kepala kartu utama berlencana "PERKIRAAN", bilah
tercatat hilang, grafik seluruhnya putus-putus, angka di kartu perkiraan
menjadi "Awal ≈ / Akhir ≈ / Terendah ≈", dan jadwal tanpa garis "hari ini".

**Kosong (belum ada rutin dan belum ada anggaran):** ilustrasi peti dari
set ADR-015, satu kalimat manfaat, chip pembuka lokal (J1), dan satu tombol
primer "Tambah rutin pertama". Pemilih bulan dan kartu perkiraan
disembunyikan (FR-HOME-005: jangan menampilkan angka nol berderet).

**Sebagian:**

| Keadaan | Yang tampil |
|---|---|
| Ada anggaran, belum ada rutin | Kartu utama dengan Pemasukan Rp0 dan ajakan "Tambah gaji atau pemasukan rutin"; kartu perkiraan diganti satu kalimat + chip `Gaji` |
| Ada rutin keluar, belum ada pemasukan rutin | Uang nganggur negatif + kalimat penjelas + chip `Gaji` |
| Riwayat kurang dari sebulan | Baris "Di luar rencana" disembunyikan, dengan catatan kecil "Muncul sesudah sebulan pencatatan" |

### 4.8 Perkiraan tinggi di layar 360×740dp

Ruang isi kira-kira 740 − 24 (status bar) − 56 (app bar) − 48 (sub-tab) − 80
(navigasi bawah) ≈ 530dp.

| Blok | Tinggi kira-kira |
|---|---|
| Pemilih bulan | 64 |
| Kartu utama | 250 |
| Kartu perkiraan sampai angka titik terendah | 110 |

Jumlahnya ±424dp. Artinya kedua angka perkiraan sudah terlihat tanpa
menggulir, dan grafik mulai tampil di bagian bawah. Begitu menggulir, judul
app bar ikut tergulung dan menambah ±56dp. Banner risiko menambah ±96dp dan
mendorong angka perkiraan ke bawah lipatan; ini bisa diterima karena banner
itu sendiri adalah intisari perkiraan.

### 4.9 Membedakan uang nganggur dari saldo (revisi 2 Okt 2026)

Masukan pemilik sesudah mencoba prototipe: kartu utama dan grafik
membingungkan, dan uang nganggur mudah tertukar dengan total saldo.
Penyebabnya ada tiga: istilah "Belum direncanakan" terdengar seperti tugas,
bukan uang; dua jenis angka (arus satu bulan dan isi dompet) bertumpuk tanpa
penjelasan, termasuk chip bulan yang dulu menampilkan saldo tepat di atas
angka uang nganggur; dan angkanya tidak bisa dipantau karena tidak berkurang
oleh belanja di luar rencana.

Revisi pertama menambal kebingungan itu dengan kalimat penjelas, dan
pemilik menilai hasilnya lebih buruk: terlalu banyak teks. Aturan
akhirnya:

1. **Angka dan label pendek saja di kartu.** Tidak ada kalimat. Penjelasan
   ada di tombol ⓘ dan di lembar "Rincian".
2. **Kata "saldo" khusus untuk isi dompet.** Kartu atas bernama "Uang
   nganggur · Okt", kartu bawah "Saldo dompet ≈". Dua nama yang berbeda
   dan dua bingkai yang berbeda (padat vs putus-putus) sudah cukup untuk
   membedakannya, tanpa kalimat penafian.
3. **Satu kartu, satu jenis angka.** Chip bulan hanya berisi nama bulan.
4. **Angka besar = jumlah baris di bawahnya**, sehingga tidak perlu baris
   "=": Pemasukan +12.000.000, Tagihan rutin −5.879.000, Anggaran
   −3.068.500, Di luar rencana −57.000 → **Rp2.995.500**. Baris "Di luar
   rencana" hanya muncul bila ada.
5. **Kartu saldo berisi dua ubin**: Akhir Okt ≈Rp10.921.000 dan Paling
   tipis · 24 Okt ≈Rp561.000. Grafik hanya diberi label tanggal; nilai per
   hari muncul saat grafik digeser.
6. **Lembar Rincian** berisi rumus saldo dan sakelar "Hitung jajan harian".
   Lembar ⓘ berisi rumus uang nganggur dalam empat baris (+ − − =) dan
   satu kalimat "Bukan saldo dompet."

```
 [OKT] [NOV] [DES]
┏ UANG NGANGGUR · OKT ───────── (i) ┓
┃ Rp2.995.500                       ┃
┃ ┌───────────────────────────────┐ ┃
┃ │ Pemasukan       +Rp12.000.000 │ ┃
┃ │ Tagihan rutin    −Rp5.879.000 │ ┃
┃ │ Anggaran         −Rp3.068.500 │ ┃
┃ │ Di luar rencana     −Rp57.000 │ ┃
┃ └───────────────────────────────┘ ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
┌┄ SALDO DOMPET ≈ ┄┄┄ [Semua] [BCA] ┐
┆ Akhir Okt        Paling tipis·24 Okt
┆ ≈Rp10.921.000    ≈Rp561.000       ┆
┆ ‾‾╲____ _ _ _ _ _ ●╱‾‾‾           ┆
┆ 1 Okt  hari ini            31 Okt ┆
┆ Rincian ›                         ┆
└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
```

**Diterapkan juga ke Anggaran dan Rutin (2 Okt 2026), menggantikan wireframe
§5 dan §6.1:**

| | Anggaran | Rutin |
|---|---|---|
| Kartu utama | "Sisa anggaran · Okt" Rp2.700.000 = Rencana Rp3.068.500 − Terpakai Rp368.500 | "Sisa rutin keluar · Okt" ≈Rp3.979.000 = Rencana Rp5.879.000 − Sudah keluar Rp1.900.000. "Masuk terjadwal" dibuang karena sudah ada di Bulan ini |
| Chip | Aktif · Selesai · Semua, tanpa angka hitungan. Penyaring dompet hanya tampil bila anggaran memakai lebih dari satu dompet | Semua · Masuk · Keluar · Transfer, tanpa angka hitungan |
| Baris | Nama + ↻ (rutin), meta "BCA · Okt", bilah, satu angka: sisa (atau "Lewat Rp…" berwarna peringatan) | Kolom tanggal di kiri (seperti jadwal), nama, nominal. Meta hanya bila bermakna ("4 dari 12", "ke Tabungan"). Dompet, cara bayar, dan kata "tercatat" pindah ke rincian rutin; ✓ sudah cukup |
| Menunggu | — | Satu baris + **Lewati** dan **Catat**. "Ubah dulu" = ketuk barisnya |
| Bawah | "Buat anggaran" (primer) + tautan "Template anggaran ›" | "Selesai (1) ›" (kelompok kosong disembunyikan) + "Tambah rutin" |

Bulan ini tidak lagi menampilkan jadwal sebulan penuh: cukup **Menunggu** dan
**3 berikutnya**, lalu "Semua di Rutin ›". Daftar lengkap hanya ada di satu
tempat.


## 5. Segmen Anggaran

Isinya adalah layar Anggaran sekarang (`budget_list_page.dart`) dengan
perubahan minimal:

| Perubahan | Alasan |
|---|---|
| App bar sendiri dihapus; judulnya mengikuti app bar Rencana | Satu app bar per tab |
| Penyaring status: slab bergaya tab → chip "Semua (n) · Aktif (n) · Selesai (n) · Nonaktif (n)" | §3.2, tidak ada tab di dalam tab |
| Penyaring dompet tetap (`AppMenuSelectButton`), sebaris dengan chip bila muat | Sudah benar |
| Kartu anggaran rutin mendapat lencana "↻ Rutin" di samping periode, dan baris meta "Lahir lagi 1 Nov" | Membedakan anggaran yang akan lahir lagi |
| Pos yang tertaut rutin menampilkan ikon ↻ kecil di rincian anggaran | Menjelaskan kenapa pos itu terisi sendiri |
| "Template Anggaran" tetap tombol sekunder di bawah; daftar template menandai template yang berjadwal ("↻ Rutin · BCA · bulanan") | KT-R4: anggaran rutin = template berjadwal |
| Kartu ringkasan, kartu anggaran, "Buat anggaran", keadaan kosong | Tetap |

```
 BULAN INI    ANGGARAN     RUTIN
              ▀▀▀▀▀▀▀▀
┏ [▣] ANGGARAN AKTIF ━━━━━━━━━━━━━━━┓
┃ Sisa Rp2.700.000                  ┃   ← BudgetSummaryCard (tetap)
┃ ▓░░░░░░░░░ Rp368.500 dari 3.068.500┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 (Semua 1) (Aktif 1) (Selesai 0) (Nonaktif 0)   [BCA ▾]
┌─────────────────────────────────────┐
│ Belanja Bulanan          ↻ Rutin    │
│ BCA · Bulanan (Okt) · lahir lagi 1 Nov
│ ▓░░░░░░░░░  Rp368.500 / Rp3.068.500  │
└─────────────────────────────────────┘
[         BUAT ANGGARAN          ]
[       Template Anggaran        ]
```

Tur ADR-021 (`TourId.budget` dengan kunci `budgetSummary`, `budgetFilter`,
`budgetTemplates`) tetap dipicu saat segmen Anggaran pertama kali dibuka,
bukan saat tab Rencana dibuka.

## 6. Segmen Rutin

### 6.1 Wireframe

```
 BULAN INI    ANGGARAN     RUTIN
                           ▀▀▀▀▀
┏ [↻] RUTIN OKTOBER ━━━━━━━━━━━━━━━━┓
┃ Masih akan keluar                 ┃
┃ ≈Rp3.979.000                      ┃   ← angka utama
┃ ▓▓▓░░░░░░░  Rp1.900.000 dari       ┃
┃             Rp5.879.000 tercatat  ┃
┃ Masuk terjadwal   Rp12.000.000    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 (Semua 8) (Masuk 1) (Keluar 6) (Transfer 1)
 ● MENUNGGU DICATAT (1)
 ┌───────────────────────────────────┐
 │[ikon] Netflix          −Rp65.000  │
 │       BCA · 1 Okt · kemarin       │
 │       Lewati   Ubah dulu  [Catat] │
 └───────────────────────────────────┘
 BULAN INI
 [ikon] Kos ✓            −Rp1.900.000
        BCA · 1 Okt · tercatat
 [ikon] Listrik           ≈−Rp200.000
        BCA · 5 Okt · bayar sendiri
 [ikon] Cicilan iPhone   −Rp2.914.000
        BCA · 10 Okt · autodebet · 4/12
 [ikon] Gaji            +Rp12.000.000
        BCA · 25 Okt
 [ikon] Tabungan         ⇄Rp1.000.000
        BCA → Tabungan · 26 Okt
 [ikon] Sabil              −Rp800.000
        BCA · 28 Okt
 NANTI
 [ikon] Asuransi motor   −Rp1.250.000
        BCA · 12 Mar 2027 · tahunan
 Dijeda (0)   Selesai (1) ›
[         TAMBAH RUTIN           ]
```

(Hitungan kartu utama: 5.879.000 − 1.900.000 = 3.979.000. Nilainya berawalan
`≈` karena Listrik bernominal kira-kira. Baris Asuransi motor hanya contoh
kelompok "Nanti"; ia tidak termasuk hitungan Oktober, tetapi ikut di hitungan chip.)

### 6.2 Pengelompokan dan urutan

| Kelompok | Isi | Urutan | Bawaan |
|---|---|---|---|
| Menunggu dicatat | Kemunculan menunggu (dan "n terlewat" per rutin, J8) | Tanggal terlama dulu | Terbuka; disembunyikan bila kosong |
| Bulan ini | Semua rutin aktif yang punya kemunculan di bulan berjalan, termasuk yang sudah tercatat (✓, teks redup) | Tanggal | Terbuka |
| Nanti | Rutin aktif yang kemunculan berikutnya sesudah bulan ini (tahunan, per 3 bulan) | Tanggal | Terbuka; disembunyikan bila kosong |
| Dijeda / Selesai | Rutin dijeda; rutin berakhir (cicilan lunas) | Nama | Terlipat, cukup satu baris |

Alasannya: mengurutkan menurut **apa yang perlu dilakukan** (Copilot,
Monarch) lebih berguna daripada menurut abjad atau jenis. Jenis cukup jadi
chip penyaring. Rutin tercatat tetap tampil di "Bulan ini" supaya pengguna
melihat kelengkapan ("sudah 1 dari 6"), mirip "paid and left to pay" di
Copilot.

### 6.3 Anatomi baris

```
[ikon 44] Nama rutin               ±Rp nominal
          meta: dompet · tanggal · cara bayar · k/N
```

- **Satu penanda warna per baris** (ADR-020 §3): kotak ikon kategori. Warna
  jenis hanya di nominal (`+` hijau, `−` merah, `⇄` netral).
- **Meta paling banyak empat butir**, dipisah titik tengah. Urutannya
  dompet → tanggal → cara bayar (hanya bila diisi) → k/N (hanya untuk N
  kali).
- **Nominal kira-kira** berawalan `≈`, tanpa ikon tambahan.
- **Status** memakai glyph §7.1 di ujung nama (✓ tercatat, ! nominal beda),
  bukan lencana besar.
- **Tidak ada geser-untuk-aksi.** Aksi Menunggu tampil sebagai tombol di
  dalam kartu (Lewati dan Ubah dulu tersier, Catat sekunder). Ini sesuai
  §3.3 dan juga lebih mudah ditemukan daripada gestur tersembunyi.
- Target sentuh seluruh baris minimal 48dp tingginya.

### 6.4 Keadaan

| Keadaan | Yang tampil |
|---|---|
| Kosong | Kartu utama disembunyikan; ilustrasi + chip pembuka lokal (sama dengan Bulan ini kosong) + "Tambah rutin" |
| Penyaring menghasilkan kosong | "Belum ada rutin transfer." + tautan "Tampilkan semua" (pola `BudgetFilteredEmptyState`) |
| Hanya pemasukan rutin | Angka utama "Rp0 lagi", baris Masuk terjadwal tetap |
| ≥2 rutin berkategori langganan | Baris tambahan di kartu utama: "Langganan Rp…/bln · Rp…/thn ›" (W5), ketuk → chip kategori Langganan |

### 6.5 Rincian rutin

Halaman penuh (bukan lembar), sejajar `BudgetDetailPage` dan
`TransactionDetailPage`. Tata letaknya mengikuti
[RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md) §8.3, ditambah:

- Baris cara bayar dan pengingat ("Bayar sendiri · diingatkan H−1").
- Untuk N kali: bilah progres k/N dan W7 ("Selesai Jun 2027, sesudah itu
  ruang bebas +Rp2.914.000/bln").
- Riwayat nominal 6 kemunculan terakhir untuk nominal kira-kira, sebagai
  deretan angka, bukan grafik. Enam angka lebih cepat dibaca dari angka
  daripada dari garis.
- Satu tombol primer saja: **Ubah** (membuka CATAT mode jadwal). Jeda,
  Akhiri, dan Hapus ada di menu ⋮.

## 7. Bahasa visual bersama

### 7.1 Status kemunculan

| Status | Glyph | Warna | Teks | Dipakai di |
|---|---|---|---|---|
| Tercatat | ✓ | tinta redup | "tercatat" | Rutin, Jadwal |
| Menunggu | ● | aksen | "menunggu" | Rutin, Jadwal, Beranda |
| Terjadwal | (tanpa glyph) | tinta biasa | tanggal | Rutin, Jadwal |
| Dilewati | – | tinta redup, nama dicoret | "dilewati" | Rincian rutin, Jadwal |
| Nominal beda (W3) | ! | peringatan | "Rp79.000, biasanya Rp65.000" | Rutin, Jadwal |

Glyph pixel diambil dari set ikon status ADR-015 bila padanannya ada
(`icon_status_*`, `icon_interaction_selected`). Bila tidak ada, pakai isian
Material sementara dan catat sebagai kebutuhan aset, sesuai AGENT_CONTEXT
"Kapan harus berhenti".

### 7.2 Nyata vs perkiraan

| | Nyata | Rencana (pasti) | Perkiraan |
|---|---|---|---|
| Contoh | Saldo, tercatat | Uang nganggur, rencana anggaran | Akhir bulan, titik terendah |
| Bingkai | Kartu biasa atau kartu utama | Kartu utama | **Putus-putus**, tanpa bayangan keras |
| Nominal | `Rp` | `Rp` | **`≈Rp`** |
| Garis grafik | Utuh | — | Putus-putus |

Tiga lapis ini menjaga prinsip antarmuka 2 (uang nyata berbeda dari uang
rencana) sampai ke tingkat piksel.

### 7.3 Ikon

- Tab Rencana memakai `icon_nav_budget` yang sudah ada, supaya tidak menunggu
  aset baru (KT-L3).
- Kartu utama Rutin dan glyph ↻ memakai `icon_transaction_recurring_expense`
  / `_income` dari rujukan pemilik (belum dikonversi; T-7.4 mencatat
  keduanya belum punya kunci).
- Di **Riwayat**, transaksi yang tertaut rutin mendapat ↻ kecil di baris
  meta. Ini satu-satunya perubahan di tab Riwayat, supaya pengguna bisa
  menelusuri asal transaksi.

## 8. Aksesibilitas, layar sempit, dan mode gelap

- **Sub-tab** memakai semantik tab (`Semantics(selected: …)` dengan peran
  tab), target sentuh minimal 48dp, dan label minimal 12px (ADR-020 §2
  menetapkan minimal 11px).
- **Label en** ("THIS MONTH / BUDGETS / RECURRING") muat di 360dp
  (±100dp per kolom). Uji widget wajib di 360dp dengan skala teks 1,3. Bila
  meluap, label en "THIS MONTH" disingkat "MONTH". Jangan memperkecil huruf
  di bawah 11px.
- **`≈`** dibacakan pembaca layar sebagai "kira-kira". Label semantik nominal
  tidak boleh berbunyi "approximately equal".
- **Status** selalu glyph + teks atau warna + ikon, tidak pernah warna saja
  (ADR-015).
- **Mode gelap** memakai token yang sama (`PixelTheme.dark`, ADR-031).
  Bingkai putus-putus dan garis rambut grafik memakai token tepi, bukan warna
  tetap. Area di bawah nol memakai token peringatan dengan opasitas yang
  diuji kontrasnya di kedua mode.
- **Gerak:** pindah segmen tanpa animasi meluncur. Getar di titik terendah
  hanya bila setelan getar sistem aktif.

## 9. Tur spotlight (ADR-021)

| Kunci baru | Target | Teks (draf) | Kapan |
|---|---|---|---|
| `planTabs` | Sub-tab | "Bulan ini untuk gambaran, Anggaran untuk belanja, Rutin untuk yang datang tiap bulan." | Pertama kali membuka tab Rencana |
| `planUnplanned` | Angka Uang nganggur | "Pemasukan bulan ini dikurangi semua yang sudah terikat." | Pertama kali kartu utama berisi |
| `planForecast` | Kartu perkiraan | "Perkiraan saldo sampai akhir bulan, termasuk titik terendahnya." | Pertama kali kartu perkiraan tampil |
| `recurringPending` | Kartu Menunggu di Rutin | "Yang sudah jatuh tempo. Catat atau lewati." | Pertama kali ada kemunculan menunggu |
| `recordRepeat` | Baris Ulangi di CATAT | "Nyalakan supaya transaksi ini diingat tiap bulan." | Pertama kali CATAT dibuka sesudah fitur rilis |

Tur Anggaran yang sudah ada tetap (§5).

## 10. Dampak ke dokumen dan kode lain

Dikerjakan bersama ADR-034, bukan sekarang:

- PRD 2.0 §10: diagram navigasi `Beranda | Rencana | Riwayat | Dompet`.
- i18n: label tab baru (`appShell.planTabLabel`). Kunci lama
  `budgetTabLabel` tetap dipakai sebagai label segmen Anggaran, mengikuti
  kebiasaan T-8.8 (kunci tidak diganti nama).
- `AppShellPage`: tab ke-2 menjadi `PlanPage` yang membungkus
  `BudgetListPage` tanpa app bar-nya, ditambah dua segmen baru.
- `budget_filter_bar.dart`: penyaring status menjadi chip (KT-L2).
- Komponen baru `AppSubTabs` di `core/presentation/widgets/`.
- Uji `app_shell_page_test.dart` dan uji tur yang menyebut label Anggaran.
- CLAUDE.md "Status" dan glosarium: istilah Rencana.
- Situs `tanukonomy-web`: tangkapan layar tab bawah perlu dirender ulang
  (seperti B-4).

## 11. Keputusan

Diputuskan pemilik 2 Okt 2026, semuanya sesuai rekomendasi.

| KT | Keputusan |
|---|---|
| KT-L1 | Angka kartu utama Bulan ini = **uang nganggur** |
| KT-L2 | Penyaring status Anggaran menjadi chip |
| KT-L3 | Ikon tab Rencana memakai `icon_nav_budget` yang ada |
| KT-L4 | Awal sesi selalu Bulan ini, sesudah itu segmen terakhir (tidak disimpan) |
| KT-L5 | Tanpa tampilan kalender bulanan di R1/R2 |
| KT-L6 | Pemilih bulan hanya ke depan; kilas balik lewat tinjau awal bulan |
| KT-L7 | Komponen sub-tab baru `AppSubTabs` |

Catatan R1a: segmen Bulan ini baru hadir di R1b, jadi di R1a tab Rencana
berisi dua segmen (Anggaran, Rutin) dan awal sesi membuka Anggaran.

## 12. Sumber

Diakses 2 Oktober 2026.

- Material Design 3, tab dan segmented button: [SAP Fiori untuk Android, M3 Tabs usage](https://www.sap.com/design-system/fiori-design-android/v25-4/components/m3-standard-components/tabs/usage), [eBay Playbook, segmented button](https://playbook.ebay.com/design-system/components/segmented-button)
- Tab dan konten yang bisa digeser: [Material Design 2, Tabs](https://m2.material.io/go/design-tabs), [Android Developers, swipe views](https://developer.android.com/guide/navigation/advanced/swipe-view?hl=en)
- Kontrol bersegmen vs tab: [Trimble Modus, segmented controls](https://modus.trimble.com/components/mobile/segmented-controls/), [Fluent 2, segmented control](https://fluent2.microsoft.design/components/ios/segmentedcontrol/usage)
- Simplifi: [Using the Spending Plan](https://help.simplifimoney.com/en/articles/4212702-using-the-simplifi-spending-plan), [Add "Lowest Projected Balance" to Projected Cash Flow graph](https://community.simplifimoney.com/discussion/3389/add-lowest-projected-balance-to-projected-cash-flow-graph-edited)
- Monarch: [Recurring, daftar dan kalender](https://www.monarchmoney.com/whats-new/track-recurring-bills-and-subscriptions), [Recurring di mobile](https://monarchmoney.com/features/recurring)
- Copilot: [Recurrings tab overview](https://help.copilot.money/en/articles/9778259-recurrings-tab-overview), [Pause or archive recurrings](https://help.copilot.money/en/articles/3983286-pause-or-archive-recurrings)
- YNAB: [Underfunded: A Guide](https://support.ynab.com/en_us/underfunded-a-guide-BJwPhQO09), [Release notes](https://www.ynab.com/release-notes)
- PocketSmith: [Budgets and planning](https://www.pocketsmith.com/features/budgets-and-planning)
