# Isian Play Console: setelan toko dan listing (ASO)

**Tanggal:** 29 September 2026
**Status:** Sudah diisi pemilik di Play Console (dilaporkan 29 Sep 2026, closed testing terbit); dokumen ini kini rujukan untuk perubahan berikutnya
**Rujukan:** [ASO_NAME_RESEARCH.md](../01-product/ASO_NAME_RESEARCH.md) §2
dan §5a (kata kunci), [PLAY_DATA_SAFETY.md](PLAY_DATA_SAFETY.md) (Keamanan
Data, App access), [ADR-022](../02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md),
[ADR-024](../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)

Semua teks di bawah sudah dihitung panjangnya dan dicocokkan dengan
aplikasi saat ini (versi `0.2.0+3`, mata uang dan label navigasi diperbarui
29 September 2026 — tangkapan layar dan deskripsi di Play Console perlu dicocokkan kalau belum, B-4). Kalau fitur berubah, cocokkan ulang
— klaim listing yang tidak sesuai aplikasi melanggar kebijakan metadata
Play.

## 1. Keputusan pemilik sebelum mengisi

1. **Negara distribusi.** ~~Aplikasi hanya memakai Rupiah~~ — **basi sejak
   29 September 2026**: aplikasi mendukung 14 mata uang, satu per aplikasi,
   dipilih pemakai saat onboarding
   ([ADR-025](../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md),
   T-8.6). Risiko "Rp di tangkapan layar" tetap ada karena tangkapan layar
   dirender dengan IDR: kalau membuka negara selain Indonesia, sertakan
   tangkapan layar bermata uang lain atau tetap mulai dari Indonesia saja.
   Keputusan §1 sudah diambil dan diisi pemilik di Play Console (29 Sep 2026); catatan hasilnya tidak ada di repo, cek langsung di Play Console.
2. **Bahasa bawaan listing.** Kalau Indonesia saja: bawaan `id-ID`,
   terjemahan `en-US` (untuk pengguna Indonesia yang HP-nya berbahasa
   Inggris). Kalau global: bawaan `en-US`, terjemahan `id-ID`.
3. **Email kontak publik.** Email ini tampil di halaman toko. Disarankan
   alamat khusus (mis. di domain `tanukonomy.app`), bukan email pribadi.

## 2. Setelan toko (Grow users → Store presence → Store settings)

| Kolom | Isi |
|---|---|
| Aplikasi atau game | Aplikasi |
| Kategori | **Keuangan** (Finance) |
| Tag (maks. 5) | Lihat §2.1 — pakai 3–4, bukan 5 |
| Email | Lihat §1 poin 3 (wajib) |
| Situs web | `https://tanukonomy.app` |
| Telepon | Kosongkan (opsional) |
| Pemasaran eksternal | Aktif — mengizinkan Google mempromosikan aplikasi di luar Play |

### 2.1 Kategori dan tag

**Kategori: Keuangan (Finance).** Di sini pengguna menjelajah aplikasi
anggaran dan pencatat pengeluaran, dan peringkat kategori dihitung
terhadap aplikasi sejenis. Produktivitas lebih sepi, tapi pengguna yang
mencari aplikasi uang tidak menjelajah ke sana.

**Tag.** Play memakai daftar tag tetap (sekitar 159 tag aplikasi). Tidak
ada tag "Budget" atau "Expense tracker" — artikel yang menyebutnya memakai
contoh rekaan. Tag keuangan yang ada hanya: *Personal finance*, *Finance*,
*Investment*, *Loan*, *Mobile banking*, *Mobile payment*,
*Cryptocurrency*. Aturan Play: tag harus jelas relevan bagi orang yang baru
melihat listing atau layar awal aplikasi, dan tidak wajib mengisi kelima
slot.

| # | Tag (nama di konsol id kira-kira) | Alasan |
|---|---|---|
| 1 | **Personal finance** (Keuangan pribadi) | Paling tepat: dompet, pengeluaran, anggaran pribadi |
| 2 | **Finance** (Keuangan) | Tag umum kategori; memperkuat penempatan di jelajah Keuangan |
| 3 | **Productivity** (Produktivitas) | Worklog jam kerja dan anggaran sebagai rencana; menjangkau pengguna di luar kategori Keuangan |
| 4 | *Business* (Bisnis) — opsional | Hanya kalau fitur Freelance (proyek, klien, pembayaran) tampil di tangkapan layar dan deskripsi; kalau tidak, lewati |

**Jangan dipakai** (tidak relevan dan bisa dianggap menyesatkan karena
aplikasi tidak memindahkan uang maupun terhubung ke bank): *Mobile
banking*, *Mobile payment*, *Loan*, *Investment*, *Cryptocurrency*. Juga
*Notebook* (pengguna mengharapkan aplikasi catatan teks) dan *Privacy &
security* (bukan aplikasi keamanan).

Daftar tag bersumber dari AppTweak (diperbarui 19 Sep 2024); cek ulang di
**Store settings → Manage tags** dan perhatikan "Suggested tags" dari
Google. Ubah tag hanya bila fungsi aplikasi berubah besar.

URL kebijakan privasi diisi di **Policy → App content → Privacy policy**,
bukan di sini. Pakai halaman kebijakan privasi `tanukonomy-web` yang sudah
menyebut Firebase (lihat syarat di PLAY_DATA_SAFETY.md) — pastikan URL-nya
bisa dibuka sebelum submit.

## 3. Listing utama (Store presence → Main store listing)

### Nama aplikasi (maks. 30)

| Bahasa | Teks | Panjang |
|---|---|---|
| `id-ID` | `Tanukonomy: Catatan Keuangan` | 28 |
| `en-US` | `Tanukonomy: Budget & Expense` | 28 |

### Deskripsi singkat (maks. 80)

| Bahasa | Teks | Panjang |
|---|---|---|
| `id-ID` | `Catat pengeluaran harian, atur anggaran bulanan & pantau pemasukan freelance.` | 77 |
| `en-US` | `Spending tracker & money manager with freelance income and monthly plans.` | 73 |

Riset dan alasannya di §3.1. Draf lama (ASO_NAME_RESEARCH §5a, lalu versi
pertama dokumen ini) diganti: "tanpa akun" dan "Private" tidak tepat sejak
ADR-023, dan klaim offline/tanpa bank dipindah ke deskripsi lengkap supaya
ke-80 karakter dipakai untuk kata kunci dan manfaat.

### 3.1 Riset deskripsi singkat (29 Sep 2026)

**Cara Play memakai kolom ini.** Deskripsi singkat tampil tepat di bawah
judul dan diindeks untuk pencarian; bobotnya kedua setelah judul, di atas
deskripsi lengkap. Kata yang sudah ada di judul sudah terindeks, jadi
mengulangnya memboroskan ruang. Kebijakan metadata Play melarang emoji,
huruf kapital semua, klaim peringkat ("#1", "terbaik") dan promosi harga,
serta deskripsi yang menyesatkan.

**Pesaing** (meta description halaman Play, diambil 29 Sep 2026):

| Toko | Aplikasi | Deskripsi singkat |
|---|---|---|
| ID | Money Lover – Catatan Keuangan | Catatan Keuangan mudah! Kelola uang dan pengeluaran cerdas - Money Manager app |
| ID | CuanKu – Catatan KeuanganKu | Kelola aktivitas pemasukan dan pengeluaran keuanganmu dengan mudah |
| ID | Pengelola Keuangan (Realbyte) | Aplikasi untuk perencanaan keuangan, ulasan, jejak pengeluaran, dan aset pribadi |
| ID | Wallet – Pelacak Anggaran | Aplikasi keuangan semua-dalam-satu. Kelola uang, catat pengeluaran & menabung. |
| US | Spendee | Money tracker & expense tracker. Plan budgets, track spending & save money! |
| US | Monefy | Expense tracker & budgeting: Money & budget planner for your personal finance. |
| US | Money Lover | Simple expense tracker, money manager app! Track spending easily, budget smartly |
| US | Goodbudget | Budget with a purpose. Plan for what's important. Spend without worry. |

Polanya: aplikasi besar menumpuk *expense tracker*, *money manager*,
*budget planner* — ruang itu padat dan dimenangkan oleh jumlah rating. Tidak
ada satu pun yang menyebut **freelance**, padahal *freelance income
tracker* adalah kata kunci berpersaingan paling rendah di riset ASO §2
(median rating pesaing 19). Itu pembeda Tanukonomy yang harus selalu ada.

**Kata kunci per bahasa** (tidak mengulang judul):

- `id` — judul sudah memuat *catatan keuangan*. Deskripsi singkat memuat
  *pengeluaran harian* (saran pencarian "catatan pengeluaran harian"),
  *anggaran bulanan* ("anggaran keuangan"), *pemasukan* ("pemasukan dan
  pengeluaran"), dan *freelance*.
- `en` — judul sudah memuat *budget* dan *expense*. Deskripsi singkat
  menambah dua frasa bervolume tinggi yang belum ada, *spending tracker* dan
  *money manager*, plus *freelance income*.

**Kandidat yang ditimbang:**

| Bahasa | Kandidat | Panjang | Catatan |
|---|---|---|---|
| id | **Catat pengeluaran harian, atur anggaran bulanan & pantau pemasukan freelance.** | 77 | Dipilih: empat kata kunci, dibuka kata kerja |
| id | Tahu ke mana uangmu pergi: catat pengeluaran harian, anggaran & uang freelance. | 79 | Lebih emosional; varian uji A/B |
| id | Catat pengeluaran & pemasukan harian, atur anggaran, pantau pendapatan freelance. | 81 | Gugur: lewat batas |
| en | **Spending tracker & money manager with freelance income and monthly plans.** | 73 | Dipilih: dua frasa bervolume tinggi di luar judul |
| en | Track daily spending across wallets, plan your month & log freelance income. | 76 | Lebih enak dibaca; varian uji A/B |
| en | Money tracker for daily spending, wallets & freelance income. Plan every month. | 79 | Cadangan |

Varian kedua tiap bahasa diuji lewat **Store listing experiments** setelah
pemasangan cukup; pemenangnya diukur dari konversi, bukan selera.

**Fitur mendatang (PRD §12).** Fitur yang belum ada **tidak boleh** masuk
listing — kebijakan metadata Play melarang klaim yang tidak sesuai
aplikasi. Siapkan versi berikut dan ganti tepat saat fiturnya rilis:

| Saat rilis | `id` | `en` |
|---|---|---|
| Tujuan menabung | `Catat pengeluaran harian, atur anggaran, capai target tabungan & uang freelance.` (80) | `Track daily spending, plan your month, hit savings goals & log freelance income.` (80) |
| Sinkronisasi/cadangan | `Catat pengeluaran harian, atur anggaran & uang freelance. Cadangan otomatis.` (76) | `Track daily spending, plan your month & log freelance income. Synced backup.` (76) |

Laporan/grafik, transaksi berulang, kartu kredit, dan impor mutasi lebih
cocok masuk deskripsi lengkap dan tangkapan layar daripada deskripsi
singkat. Kalau beberapa fitur rilis bersamaan, prioritaskan yang punya kata
kunci bervolume tinggi (*tabungan*/*savings*) atau yang menjawab keberatan
terbesar (cadangan data).

### Deskripsi lengkap `id-ID` (2532/4000)

```
Tanukonomy adalah aplikasi catatan keuangan pribadi yang bekerja seperti buku kas. Lihat di mana uangmu berada, apa yang terjadi padanya, dan ke mana ia direncanakan pergi. Seekor tanuki juru catat menemanimu di setiap layar.

Catat pemasukan, pengeluaran, dan transfer antardompet dalam hitungan detik. Susun anggaran bulanan atau mingguan sebagai rencana, lalu pantau berapa yang sudah terpakai. Untuk freelancer, catat jam kerja per proyek dan bedakan uang yang sudah kamu hasilkan dari uang yang benar-benar sudah diterima.

DOMPET
• Rekening bank, e-wallet, dan uang tunai jadi dompet masing-masing
• Saldo tiap dompet dan total saldo selalu terlihat
• Transfer antardompet tidak dihitung sebagai pemasukan atau pengeluaran

CATAT
• Satu tombol untuk mencatat pemasukan, pengeluaran, atau transfer
• Catat pakai suara: ucapkan satu transaksi, periksa formulir yang sudah terisi, lalu simpan
• Dompet dan kategori yang sering dipakai sudah siap dipilih
• Tautkan pengeluaran ke pos anggaran supaya progres anggaran ikut bergerak
• Salah catat? Hapus langsung dan urungkan kalau berubah pikiran

ANGGARAN
• Anggaran mingguan atau bulanan dengan pos-pos belanja
• Anggaran adalah rencana: membuatnya tidak mengubah saldo dompet
• Lihat sisa dan pemakaian tiap pos, tandai pos yang melewati rencana
• Simpan anggaran rutin sebagai template dan pakai lagi tiap periode

FREELANCE
• Kelola proyek dan klien dengan tarif per jam
• Catat worklog: jam kerja × tarif menjadi pendapatan yang diperoleh
• Catat pembayaran yang diterima langsung ke dompet tujuan
• Pisahkan "sudah dikerjakan" dan "sudah dibayar" supaya piutang terlihat jelas

BERANDA
• Total saldo, arus kas bulan berjalan, ringkasan anggaran dan freelance
• Transaksi terbaru dan riwayat lengkap dengan filter

DATAMU DI PERANGKATMU
• Semua catatan tersimpan di HP-mu; mencatat, dompet, dan anggaran berjalan penuh tanpa internet
• Catat pakai suara memakai pengenal ucapan Google/Apple dan bisa butuh internet
• Tidak terhubung ke rekening bank mana pun dan tidak memindahkan uang
• Akun Google opsional, tidak dibutuhkan untuk mencatat
• Statistik pemakaian dan laporan crash dikumpulkan secara anonim untuk memperbaiki aplikasi

TAMPILAN
• Gaya pixel yang hangat dengan maskot tanuki
• Mode gelap mengikuti setelan HP
• Tur singkat di setiap layar saat pertama kali dibuka
• Bahasa Indonesia dan Inggris, dengan pilihan mata uang (Rupiah bawaan)

Tanukonomy mencatat, bukan melakukan: aplikasi ini membantumu memahami dan merencanakan uang, tanpa menyentuh rekeningmu.
```

### Deskripsi lengkap `en-US` (2349/4000)

```
Tanukonomy is a personal expense tracker and budget planner that works like a cash book. See where your money is, what happens to it, and where you plan for it to go. A note-taking tanuki keeps you company on every screen.

Record income, expenses, and transfers between wallets in seconds. Build a weekly or monthly budget as a plan, then see how much of it you've used. Freelancers can log hours per project and keep money earned separate from money actually received.

WALLETS
• Bank accounts, e-wallets, and cash each become a wallet
• See every wallet balance and your total at a glance
• Transfers between wallets never count as income or expense

RECORD
• One button to record income, expenses, or transfers
• Record by voice: say one transaction, check the filled-in form, then save
• Your usual wallets and favorite categories are ready to pick
• Link an expense to a budget item and the budget updates instantly
• Recorded something by mistake? Delete it right away, with undo

BUDGETS
• Weekly or monthly budgets with spending items
• A budget is a plan: creating one never changes your wallet balances
• See what's left in each item and spot items over plan
• Save recurring budgets as templates and reuse them every period

FREELANCE
• Manage projects and clients with hourly rates
• Log work: hours × rate becomes income earned
• Record payments received straight into the right wallet
• Keep "work done" and "paid" apart, so unpaid invoices stay visible

HOME
• Total balance, this month's cash flow, budget and freelance summaries
• Recent transactions plus full history with filters

YOUR DATA STAYS ON YOUR PHONE
• Everything is stored on your device; recording, wallets, and budgets work fully offline
• Record by voice uses Google/Apple speech recognition and may need internet
• No bank connection, and it never moves money
• Google account is optional and not needed to record anything
• Anonymous usage statistics and crash reports help us improve the app

LOOK AND FEEL
• Warm pixel-art style with a tanuki mascot
• Dark mode follows your phone's setting
• A short guided tour on each screen the first time you open it
• Available in English and Indonesian, with a choice of currency (Rupiah by default)

Tanukonomy records, it doesn't transact: it helps you understand and plan your money without touching your bank account.
```

**Alasan susunannya:** Play mengindeks deskripsi lengkap untuk pencarian,
tapi menghukum penumpukan kata kunci. Kata kunci utama dari riset §2
(*catatan keuangan*, *anggaran*, *pengeluaran*, *pemasukan*, *freelance*;
*expense tracker*, *budget planner*, *freelance income*) muncul di kalimat
pembuka lalu diulang wajar di judul bagian dan poin fitur, tidak dalam
daftar kata. Kalimat "Tanukonomy mencatat, bukan melakukan" menjaga
definisi produk (CLAUDE.md) dan mencegah salah harap.

## 4. Grafis

| Aset | Syarat Play | Sumber / catatan |
|---|---|---|
| Ikon aplikasi | PNG 512×512, maks. 1 MB | Turunkan dari `assets/icon/legacy.png` (1024×1024) |
| Grafis fitur | JPG/PNG 1024×500, tanpa transparansi | Belum ada — maskot tanuki + judul, teks tetap terbaca kalau dipotong |
| Tangkapan layar ponsel | 2–8 gambar, sisi 320–3840 px, sisi panjang **maks. 2× sisi pendek** | Minimal 4 gambar ≥1080 px supaya bisa masuk rekomendasi Play |

⚠ **Tangkapan layar Pixel 9 Pro (1280×2856) ditolak Play** — rasionya 2,23,
melewati batas 2:1. Ambil di resolusi 1080×2160 (mis. `adb shell wm size
1080x2160` sementara, kembalikan dengan `adb shell wm size reset`) atau
render lewat `tools/screenshots/` di repo `tanukonomy-web`.

Urutan dan teks judul tangkapan layar (dua gambar pertama paling sering
dilihat, jadi dua pilar utama di depan):

| # | Layar | Teks `id` | Teks `en` |
|---|---|---|---|
| 1 | Beranda berisi data | Semua uangmu, satu buku | All your money, one book |
| 2 | CATAT pengeluaran | Catat dalam hitungan detik | Record in seconds |
| 3 | Anggaran dengan pos | Anggaran sebagai rencana | Budgets as a plan |
| 4 | Freelance (worklog) | Jam kerja jadi pendapatan | Hours become income |
| 5 | Daftar dompet | Bank, e-wallet & tunai | Bank, e-wallet & cash |
| 6 | Riwayat transaksi (mode gelap) | Riwayat lengkap, mode gelap | Full history, dark mode |

Isi datanya dengan contoh yang realistis (nominal Rupiah wajar), bukan
data pribadi pemilik. Pakai nama dompet generik ("Bank", "E-wallet") —
merek bank/dompet digital sungguhan di aset toko rawan dianggap
menyiratkan afiliasi.

### 4.1 Grafis fitur lewat Gemini

**Bahan** (render aplikasi sungguhan, data contoh, 1080×2160 — sekaligus
lolos syarat tangkapan layar Play): `01-beranda`, `02-catat`,
`03-anggaran-rincian`, `04-freelance`, `05-dompet`, `06-transaksi`,
`07-anggaran`; referensi maskot dari `assets/illustration/`
(`onboarding_1.png`, `onboarding_5.png`, `mascot_head.png`, `app_icon.png`).
Dibuat 29 Sep 2026 dengan entry point sementara berbasis
`tanukonomy-web/tools/screenshots/main_screenshot.dart`, ditambah
inisialisasi Firebase dan nama dompet generik.

**Aturan grafis fitur Play:** 1024×500, JPG atau PNG 24-bit tanpa
transparansi. Elemen penting di tengah (tepi bisa terpotong di beberapa
tampilan), teks sedikit dan besar, tanpa klaim peringkat/harga, tanpa
tombol "Download".

**Rekomendasi alur:** Gemini sering menggambar ulang isi tangkapan layar
(angka dan teks berubah). Karena grafis fitur harus mewakili aplikasi
sungguhan, pakai **Prompt C**: Gemini membuat latar dan maskot saja, lalu
tangkapan layar asli ditempel di atasnya (manual di Canva/Figma, atau
skrip). Prompt A/B untuk eksplorasi gaya.

Prompt ditulis dalam bahasa Inggris karena hasil model gambar lebih
konsisten; teks yang tampil di gambar tetap bahasa Indonesia.

**Prompt A — komposisi lengkap dengan judul** (lampirkan `01-beranda`,
`03-anggaran-rincian`, `ref-maskot-buku`, `ref-maskot-kepala`):

```
Create a Google Play feature graphic banner, wide 2:1 aspect ratio (final size 1024x500).

Style: cozy pixel-art, warm and friendly, crisp 1-2px dark outlines (#1E1B19) and hard offset drop shadows like a retro RPG UI. Background warm cream (#FFF8F5) with a very subtle pixel dot grid and a few small floating pixel icons (coins, a tiny notebook, a leaf) in muted terracotta and mustard. Accent color burnt orange (#C2410C). No gradients, no photorealism, no 3D.

Left third: the mascot from the attached reference images, exactly the same character: a brown tanuki (raccoon dog) with a mustard-yellow safari hat and a red scarf, holding an open ledger book and a pencil, smiling. Keep its proportions, colors and pixel style identical to the reference.

Right two thirds: two smartphones with simple flat dark frames, slightly overlapping and tilted a few degrees, showing the two attached app screenshots. Use the screenshots as-is; do not redraw, translate or change any text or numbers on the screens.

Headline text, top-center or beside the mascot, in a bold geometric sans-serif: "Semua uangmu, satu buku". Only this one line of text, large and legible, spelled exactly as written.

Keep all important elements inside the central safe area, at least 60px away from every edge. No logos of banks or payment brands, no ranking badges, no price tags, no "download" buttons.
```

**Prompt B — sama tanpa judul:** pakai Prompt A, hapus paragraf
"Headline text", dan ganti dengan: `No text anywhere in the image.`

**Prompt C — latar dan maskot saja (disarankan)** (lampirkan
`ref-maskot-buku`, `ref-maskot-kepala`):

```
Create a Google Play feature graphic background, wide 2:1 aspect ratio (final size 1024x500).

Style: cozy pixel-art, warm and friendly, crisp dark outlines (#1E1B19) and hard offset shadows like a retro RPG UI. Background warm cream (#FFF8F5) with a very subtle pixel dot grid and a few small floating pixel icons (coins, a tiny notebook, a leaf) in muted terracotta (#C2410C) and mustard.

Left 40%: the mascot from the attached references, exactly the same character: a brown tanuki with a mustard-yellow safari hat and a red scarf, holding an open ledger book and a pencil, smiling and looking toward the right. Keep proportions, colors and pixel style identical to the references.

Right 60%: leave calm, mostly empty cream space with only the faint dot grid. Two phones with app screenshots will be placed there later, so do not draw phones, screens, UI, or any text there.

No text anywhere in the image. Keep the mascot at least 60px from the edges.
```

Hasil Gemini jarang pas 1024×500. Potong/ubah ukuran ke 1024×500,
simpan PNG tanpa transparansi, lalu tempel `01-beranda` dan
`03-anggaran-rincian` (dalam bingkai ponsel sederhana) di area kanan.

## 5. Yang dihindari (kebijakan metadata Play)

- Kata "terbaik", "#1", "gratis", "diskon", atau emoji di nama aplikasi.
- Nama aplikasi pesaing, atau daftar kata kunci tanpa kalimat.
- Klaim yang tidak didukung aplikasi: "100% privat", "tanpa pelacakan",
  "sinkronisasi"/"cadangan" (belum ada), "tanpa akun" atau "offline
  sepenuhnya" (akun opsional dan analitik sudah ada, ADR-023; Catat pakai
  suara bisa butuh internet, ADR-027 §3.5 butir 7 — klaim offline hanya
  untuk pencatatan inti), dan jumlah
  mata uang yang tidak sesuai kenyataan (sekarang 14).
- Testimoni atau rating buatan.

## 6. Sesudah rilis

- Pantau **Statistik → Akuisisi → istilah penelusuran** di Play Console
  selama 4–6 minggu; kata yang mendatangkan pemasangan naikkan ke deskripsi
  singkat.
- Setelah pemasangan cukup, uji varian deskripsi singkat dan ikon lewat
  **Store listing experiments**.
- Mata uang lain sudah didukung (T-8.6): kalau membuka negara baru,
  putuskan §1 dan sesuaikan tangkapan layar serta teks "Rupiah" di deskripsi.
