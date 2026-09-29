# Riset nama aplikasi dan ASO — Saldough 2.0

**Tanggal riset:** 27 September 2026
**Status:** Diputuskan 27 Sep 2026 — pemilik memilih **Tanukonomy** (maskot tanuki juru catat); eksekusi penggantian nama di T-8.3, sesudah cek merek dagang resmi
**Tujuan:** memilih nama aplikasi untuk Play Store dan App Store yang optimal
secara global (ASO), beserta arah maskot.

## 1. Metode dan batasannya

Semua data dari sumber publik, diambil otomatis lewat skrip (disimpan di
luar repositori):

| Langkah | Sumber | Yang diukur |
|---|---|---|
| Popularitas kata kunci | Saran pencarian App Store (`MZSearchHints`, storefront US dan ID) | Urutan saran = perkiraan kasar popularitas |
| Persaingan kata kunci | iTunes Search API, 10 hasil teratas per kata kunci (US dan ID) | Median dan jumlah rating 10 teratas; berapa yang memakai kata kunci di judul |
| Lanskap Play Store | Halaman pencarian Google Play (US dan ID) | Judul aplikasi teratas |
| Bentrok nama di toko | iTunes Search API (US, ID, GB, JP; 50 hasil) dan pencarian Play (US, ID) | Aplikasi yang namanya memuat kandidat, terutama kategori Finance |
| Bentrok saat mengetik | Saran pencarian App Store untuk awalan nama | Merek lain yang muncul saat nama diketik |
| Domain | RDAP Verisign (`.com`) dan Google Registry (`.app`) | Tersedia atau sudah terdaftar |
| Jejak web | Pencarian web untuk finalis | Merek, produk, atau aplikasi bernama sama/mirip |

**Batasan:**

- **Tidak ada volume pencarian absolut.** Angka sebenarnya hanya ada di
  Apple Search Ads (skor popularitas, butuh akun developer) atau alat
  berbayar (AppTweak, Sensor Tower, AppFollow, Astro). Urutan saran dan
  jumlah rating pesaing hanyalah perkiraan.
- **Belum cek merek dagang resmi.** Pencarian web bukan pengganti pencarian
  DJKI, USPTO, EUIPO, dan WIPO Global Brand Database.
- **Hasil toko berubah.** Nama yang bersih hari ini bisa dipakai orang lain
  besok — daftarkan domain dan akun toko begitu nama dipilih.

## 2. Temuan kata kunci

### Pasar global (US)

| Kata kunci | Median rating 10 teratas | Memakai kata kunci di judul | Catatan |
|---|---|---|---|
| budget app | 15.967 | 1/10 | Volume tinggi, dikuasai aplikasi besar |
| expense tracker | 15.967 | 1/10 | Volume tinggi |
| money tracker | 15.967 | 2/10 | Volume tinggi |
| budget planner | 12.905 | 5/10 | Volume tinggi, judul penuh kata ini |
| spending tracker | 12.906 | 3/10 | |
| money manager | 7.740 | 4/10 | |
| cash tracker | 3.982 | 3/10 | Menengah |
| freelance income tracker | 19 | 0/10 | **Persaingan sangat rendah** — cocok dengan fitur Freelance |
| private expense tracker | 1 | 1/10 | **Persaingan sangat rendah** |

- Saran pencarian "offline budget" dan "private budget" **dipenuhi aplikasi
  indie** yang memasang frasa itu di judul (Clink, Coinpouch, Drachma, Flux,
  Zeroed, Gilt, Jot, Trove, TallyAI, "Ledro: budget, no bank sync"). Posisi
  "offline dan privat" sendirian tidak lagi membedakan.
- Pesaing langsung berposisi sama: **Ledgio** (offline, tanpa akun, dari
  Indonesia). Pembeda Saldough yang belum dipakai pesaing: **anggaran sebagai
  rencana**, **worklog freelance (diperoleh vs diterima)**, **gaya pixel**.

### Pasar Indonesia (ID)

| Kata kunci | Median rating 10 teratas | Saran pencarian terkait |
|---|---|---|
| catatan keuangan | 1.528 | catatan keuangan harian, pribadi, rumah tangga |
| pengeluaran | 2.442 | catatan pengeluaran, pengeluaran harian, pemasukan dan pengeluaran |
| anggaran | 964 | anggaran keuangan, pelacak anggaran |
| money manager | 4.067 | — |

Persaingan di ID **jauh lebih rendah** daripada US; "catatan keuangan" dan
"anggaran" layak jadi kata kunci utama listing `id`.

**Kesimpulan kata kunci:** penemuan (discovery) datang dari **kata kunci di
judul, subtitle, dan kolom kata kunci**, bukan dari nama merek. Nama merek
cukup unik, mudah diingat, dan mudah diketik; kata kuncinya ditaruh sesudah
titik dua.

## 3. Penyaringan nama

60 kandidat dalam tiga putaran. Kriteria gugur: aplikasi bernama sama/mirip
di toko (terutama Finance), bunyi sama dengan aplikasi keuangan lain, atau
merek besar lain yang muncul saat nama diketik.

| Nama | Hasil | Alasan |
|---|---|---|
| Tallycat, Catlog, Purrse, Tabby/Tably, Pixel…, Otterly, Capybara, Owl…, Ledgo | Gugur | Sudah dipakai aplikasi/merek lain (putaran awal) |
| Mewney | Gugur | Bunyi sama dengan **Meowney: Expense Tracker** (App Store) dan meowney.app |
| Budgebee | Gugur | Terbaca "BudgetBee" — beberapa aplikasi keuangan; ceruk lebah ramai (Money Bee, Bee Budget, BalanceBee, BeeCount) |
| Cointally | Gugur | CoinTally = layanan pajak kripto |
| Nekonomi | Gugur | Saran pencarian memunculkan "finance tracker - nekonomy." |
| Noteworth | Gugur | Tertimbun "Noteworthy"; ada "Banknote Identifier: NoteWorth" |
| Tallo, Quillo, Budgeto, Cashnote, Pennote, Kept, Saldoo, Moneko, Tabulo, Ledjo, Kasly, Kaching | Gugur | Sudah ada aplikasi bernama sama, sebagian di kategori Finance |
| Pengbook, Pennook | Gugur | Terlalu mirip **Penbook** (aplikasi planner) dan PengBooks (toko buku) |
| Pocketling | Gugur | Bentrok dengan merek anak **Pocketlings** |
| Moneyling | Gugur | Saat diketik muncul "moneyline" (istilah taruhan olahraga) |
| **Tallipop** | **Lolos** | 0 aplikasi di 4 negara App Store dan Play; `.com` dan `.app` tersedia; di web hanya satu sebutan di fandom |
| **Saldough** | **Lolos** | 0 aplikasi; `.app` tersedia (`.com` terdaftar pihak lain); saat diketik muncul "sourdough" |
| Cashling, Coinook, Scrivy, Dimelog, Kasanote, Penbee | Lolos, lemah | Bersih di toko, tetapi makna/pelafalan kurang kuat secara global |

## 4. Perbandingan finalis

| Kriteria | **Tallipop** | **Saldough** (tetap) |
|---|---|---|
| Unik di toko (US/ID/GB/JP) | Ya | Ya |
| Domain | `.com` dan `.app` tersedia | `.app` tersedia, `.com` terdaftar |
| Mudah diucapkan global | Ya: TAL-i-pop | Sedang: "sal-doh", sering dikira "sourdough" |
| Mudah diketik setelah didengar | Ya | Rendah (ejaan tidak tertebak) |
| Makna | *Tally* = menghitung/mencatat + *pop* = ringan, menyenangkan | *Saldo* (ID) + *dough* (slang uang, EN) — kuat bagi penutur ID |
| Cocok dengan gaya pixel | Ya, terdengar seperti judul game | Netral |
| Biaya ganti | Nama tampilan, ID aplikasi, teks i18n, ikon, dokumen | Nol |
| Risiko | "Tally" kurang dikenal non-penutur Inggris; nuansa permen (lollipop) bisa terlalu ceria untuk aplikasi uang | Lemah untuk pasar global |

**Rekomendasi: Tallipop**, dengan catatan wajib cek merek dagang resmi sebelum
dipakai. Kalau pemilik memprioritaskan pasar Indonesia dan biaya ganti nol,
**Saldough tetap layak** — hasil penyaringan menunjukkan namanya bersih.

## 5. Contoh metadata (Tallipop)

| Kolom | Batas | `en` | `id` |
|---|---|---|---|
| Nama/Judul | 30 | `Tallipop: Budget & Expense Log` (30) | `Tallipop: Catatan Keuangan` (26) |
| Subtitle (iOS) | 30 | `Private money tracker, no bank` (30) | `Anggaran & pengeluaran harian` (29) |
| Kolom kata kunci (iOS) | 100 | `offline,freelance,income,spending,planner,wallet,cash,manager,ledger,worklog,hours,finance` | `pemasukan,dompet,kas,harian,pribadi,rumah tangga,freelance,offline,budget,tabungan` |
| Short description (Play) | 80 | `Private expense & budget tracker. Offline, no bank link, freelance hours too.` | `Catat pemasukan, pengeluaran & anggaran. Offline, tanpa akun, tanpa bank.` |

## 5a. Contoh metadata (Tanukonomy, nama terpilih 27 Sep 2026)

Tabel §5 di atas dibuat untuk **Tallipop** sebelum pemilik memilih
**Tanukonomy** (§8, putaran 4) — tabel ini menggantikannya untuk nama yang
sungguhan dipakai. Metode pemilihan kata sama: kata kunci bervolume tinggi
(*budget*, *expense*, *catatan keuangan*) di judul karena ruangnya paling
sempit dan paling sering dibaca; kata kunci berpersaingan rendah
(*freelance income tracker*) dan pembeda produk (worklog, dompet) di
subtitle dan kolom kata kunci, yang ruangnya lebih longgar.

| Kolom | Batas | `en` | `id` |
|---|---|---|---|
| Nama/Judul | 30 | `Tanukonomy: Budget & Expense` (28) | `Tanukonomy: Catatan Keuangan` (28) |
| Subtitle (iOS) | 30 | `Freelance income & budget log` (29) | `Dompet, anggaran & freelance` (28) |
| Kolom kata kunci (iOS) | 100 | `offline,freelance,income,spending,planner,wallet,cash,manager,ledger,worklog,hours,finance` | `pemasukan,dompet,kas,harian,pribadi,rumah tangga,freelance,offline,budget,tabungan` |
| Short description (Play) | 80 | `Private expense & budget tracker. Offline, no bank link, freelance hours too.` | `Catat pemasukan, pengeluaran & anggaran. Offline, tanpa akun, tanpa bank.` |

Alasan tiap pilihan:

- **Judul EN "Budget & Expense"** (bukan "...Log"/"...Tracker") — dua kata
  kunci bervolume tertinggi di riset §2 (*budget app*, *expense tracker*),
  muat 28/30 karakter tanpa kata pengisi.
- **Judul ID "Catatan Keuangan"** — frasa dengan median rating pesaing
  paling rendah di antara kata kunci ID bervolume besar (§2), dan paling
  umum diketik dibanding "anggaran" atau "pengeluaran" sendirian.
- **Subtitle EN "Freelance income & budget log"** — memuat *freelance
  income tracker*, kata kunci dengan median rating pesaing **19** (paling
  rendah di seluruh riset §2) DAN pembeda produk sungguhan (worklog
  freelance). "log" menutup pola *tally* yang identitas maskotnya sudah
  memegang buku catatan (§8).
- **Subtitle ID "Dompet, anggaran & freelance"** — tiga pilar produk
  (Dompet, Anggaran, Freelance) sekaligus, bukan sinonim "catatan
  keuangan" dari judul (menghindari pemborosan ruang mengulang kata kunci
  yang sama).
- Kolom kata kunci dan short description dipakai APA ADANYA dari §5 --
  keduanya generik terhadap fitur (offline, freelance, worklog, tanpa
  bank), tidak menyebut nama merek, jadi tidak perlu diubah untuk nama
  baru.

➜ Isian Play Console final (setelan toko, listing id/en, grafis) ada di
[PLAY_STORE_LISTING.md](../04-planning/PLAY_STORE_LISTING.md). Deskripsi
singkat di sana **mengganti** draf di atas: "tanpa akun" dan "Private" tidak
lagi tepat sejak ADR-023 (akun opsional, Analytics, Crashlytics).

⚠ Ini tetap contoh, bukan keputusan final — belum melewati cek skor
popularitas Apple Search Ads (§7 langkah 4) maupun cek merek dagang resmi
(§7 langkah 2, prasyarat [ADR-022](../02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md)
sebelum rilis pertama).

Kata kunci berpersaingan rendah (*freelance income tracker*, *private expense
tracker*) dan pembeda (*budget planner* sebagai rencana, *worklog*) ditaruh
di subtitle dan kolom kata kunci; kata kunci bervolume tinggi (*budget*,
*expense*) di judul.

## 6. Maskot (bukan kucing)

Nama Tallipop tidak mengikat maskot pada hewan tertentu, jadi maskot bisa
dipilih bebas:

- **Buku kas hidup** — makhluk kecil RPG berupa buku bermata dan berkaki,
  membawa pensil; paling harfiah untuk "mencatat, bukan memindahkan", dan
  belum dipakai di kategori ini. Coretan *tally* (||||) bisa jadi motif di
  sampulnya.
- **Penguin juru catat** — "jas" hitam-putih = pencatat rapi; tenang dan
  mudah dikenali global.

Brief konten onboarding ([ONBOARDING_ART_BRIEF.md](../04-planning/ONBOARDING_ART_BRIEF.md))
diperbarui setelah nama dan maskot dipilih.

## 7. Langkah berikutnya

1. Pemilik memilih nama (Tallipop / tetap Saldough / lainnya).
2. Cek merek dagang resmi: DJKI (pdki-indonesia.dgip.go.id), USPTO, EUIPO,
   WIPO Global Brand Database — kelas 9 (perangkat lunak) dan 36 (keuangan).
3. Daftarkan domain dan akun media sosial, pesan nama di Play Console dan
   App Store Connect.
4. Cek skor popularitas kata kunci di Apple Search Ads untuk menyusun kolom
   kata kunci final.
5. ADR penggantian nama dan rencana eksekusi (nama tampilan, ID aplikasi
   sebelum rilis pertama, i18n, ikon, dokumen).

## 8. Putaran 4: pola "Nekonomi" dengan hewan lain

Pola: nama hewan (sering bahasa Jepang) dilebur dengan *economy*. Dua puluh
gabungan diperiksa dengan cara yang sama; **semuanya 0 aplikasi** di App
Store (US/ID/GB/JP) dan Play (US/ID), dan hampir semua `.com`/`.app`
tersedia (kecuali `beeconomy.com`). Pembedanya jadi makna dan pelafalan.

**Risiko bahasa:** dalam bahasa Jepang **"nomi" (蚤) berarti kutu** —
"Nekonomi" bisa terbaca *neko-nomi* ("kutu kucing"), "Inunomi" "kutu
anjing". Akhiran **"-nomy"** menghindarinya dan lebih jelas terbaca
*economy* oleh penutur Inggris.

| Nama | Hewan | Kelebihan | Risiko | Jejak web |
|---|---|---|---|---|
| **Pengonomy** | Penguin | Paling mudah dibaca global (*peng* + *economy*); penguin dikenal di mana pun; "jas" hitam-putih = pencatat rapi; tema penguin belum dipakai aplikasi keuangan yang ditemukan | Makna "uang" bergantung pada akhiran | Tidak ditemukan |
| **Tanukonomy** | Tanuki (anjing rakun Jepang) | Cerita terkuat: patung tanuki Shigaraki membawa **buku catatan utang-piutang** (通い帳) yang melambangkan kepercayaan — maskot yang harfiah memegang buku kas; akrab lewat Animal Crossing | Dalam cerita rakyat tanuki suka menipu dengan uang daun; Tom Nook (Animal Crossing) identik dengan meme utang; 10 huruf | Tidak ditemukan |
| Owlconomy | Burung hantu | Paling cepat ditangkap (*owl* + *economy*) | Tema burung hantu sudah ada (Owl Budget); sudah dipakai akun ekonomi di Threads | Akun Threads |
| Kitsunomy | Rubah (kitsune) | Cerdas, estetis | Kitsune juga penipu dalam cerita rakyat; "kitsu" sulit dieja | Tidak ditemukan |
| Fukuronomi | Burung hantu (fukurō) | Di Jepang *fukurō* = "tanpa kesulitan", jimat keberuntungan | Sulit diucapkan global; akhiran "-nomi" | — |
| Otternomi, Capynomi | Berang-berang, kapibara | Lucu | Tema sudah dipakai (Otterly Money, dua aplikasi Capybara) | — |

**Rekomendasi putaran 4: Pengonomy** (penguin juru catat); alternatif
berkarakter kuat: **Tanukonomy**.

