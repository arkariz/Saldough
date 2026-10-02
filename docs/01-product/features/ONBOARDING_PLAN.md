# Rencana onboarding, info, dan tutorial spotlight — Saldough 2.0

**Dibuat:** 27 September 2026
**Status:** Keputusan KO-1..KO-7 dijawab 27 Sep 2026 (bagian 7); maskot tanuki dipilih, gambar dibuat pemilik ([brief](ONBOARDING_ART_BRIEF.md)); ilustrasi diserahkan dan desain teknis diusulkan di [ADR-021](../../02-architecture/adr/0021-onboarding-dan-tur-spotlight.md) 28 Sep 2026. Teks final ada di slang (`onboarding`, `tour`, `info`); tabel §4.3 tetap draf asal, dan ADR-021 §3.4 mencatat penyesuaiannya.
**Berkaitan:** [UX-1](../../04-planning/done/UX_REVIEW_FIXES.md) (CATAT selalu melewati lembar
pilihan), [PRD §5 dan §10](../prd-saldough-2.0.md),
[ADR-015](../../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md),
[ADR-016](../../02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md)

## 1. Tujuan

Pengguna baru memahami **apa itu Saldough dan apa yang bukan** sebelum
mencatat apa pun, lalu belajar tiap layar **di layar itu sendiri**, satu kali,
tanpa dihalangi di pemakaian berikutnya.

Tiga lapis, dari yang paling jarang ke yang paling sering terlihat:

| Lapis | Kapan | Isi | Bisa dilewati |
|---|---|---|---|
| **Onboarding** | Sekali, pembukaan pertama | Nilai utama dan aturan dasar (bagian 3) | Ya, satu ketukan |
| **Spotlight** | Sekali per layar, kunjungan pertama | 2–4 sorotan elemen penting (bagian 4) | Ya, per langkah dan per tur |
| **Info** | Kapan saja, atas permintaan | Putar ulang tur, penjelasan aturan (bagian 5) | — |

Hubungan dengan **UX-1**: saat ini edukasi CATAT (alur, contoh, efek saldo)
tampil **setiap kali** CATAT dibuka. Rencana ini memindahkan edukasi itu ke
onboarding dan tur CATAT, sehingga lembar pilihan bisa dirampingkan atau
dilewati. Keputusan bentuk CATAT sendiri tetap milik UX-1 (lihat KO-5).

## 2. Prinsip

1. **Tidak menghalangi.** Setiap layar onboarding punya "Lewati"; setiap tur
   punya "Lewati tur". Tidak ada langkah wajib selain yang memang dibutuhkan
   aplikasi (membuat dompet pertama pun boleh ditunda).
2. **Satu gagasan per layar/langkah.** Kalimat pendek, satu judul, satu isi.
3. **Mengajarkan aturan, bukan tombol.** Tombol sudah berlabel; yang perlu
   diajarkan adalah aturan yang tidak terlihat: mencatat bukan memindahkan,
   anggaran bukan pemesanan, diperoleh bukan diterima, transfer tidak mengubah
   total.
4. **Kontekstual dan sekali.** Tur tampil saat layarnya pertama kali dibuka
   **dan** elemen yang disorot ada (bukan menyorot kartu yang disembunyikan).
5. **Kosakata glosarium dan NFR-UX-005.** "Catat", "tercatat", "saldo
   tercatat"; tidak ada "kirim", "bayar", "transfer sekarang".
6. **Bahasa visual ADR-015/016.** Panel pixel bergaris tepi 2px dan bayangan
   keras; warna mengikuti satu peran satu warna (hijau/merah/biru hanya untuk
   arah uang, amber untuk status, terracotta untuk aksi).
7. **Aksesibel.** Terbaca pembaca layar (urutan dan label), tidak meluap di
   360dp dan teks 2x, animasi mengikuti "kurangi gerakan" sistem.
8. **Lokal.** Status "sudah dilihat" disimpan di perangkat seperti data lain;
   tanpa analitik, tanpa jaringan.

## 3. Onboarding: key point dan konten

### 3.1 Key point (nilai utama)

Onboarding menjual **manfaat**, lalu memperkenalkan **konsep** yang
mewujudkannya — kalimat positif, bukan daftar penafian. Sumber: PRD §5
(proposisi nilai dan prinsip produk).

| # | Manfaat | Konsep | Sumber |
|---|---|---|---|
| KP-1 | Gambaran utuh keuangan pribadi | Buku kas dengan tiga pertanyaan: di mana, apa yang terjadi, ke mana direncanakan | PRD §1, §5 |
| KP-2 | Posisi uang selalu jelas | Dompet, saldo awal, saldo tercatat, total saldo | Prinsip produk 1 |
| KP-3 | Mencatat cepat dan ringan | CATAT; pemasukan, pengeluaran, transfer | Prinsip produk 2 dan 5 |
| KP-4 | Tahu masih di jalur atau tidak | Anggaran, periode, pos, terpakai, template | Prinsip produk 3 |
| KP-5 | Penghasilan kerja terpantau | Worklog, pembayaran, diperoleh vs diterima — **di tur Freelance, bukan onboarding** (KO-2) | Prinsip produk 4 |

### 3.2 Susunan layar

| Layar | KP | Judul | Aset |
|---|---|---|---|
| OB-1 | KP-1 | Semua uangmu, satu buku | `onboarding_1` |
| OB-2 | KP-2 | Tahu di mana uangmu | `onboarding_2` |
| OB-3 | KP-3 | Catat dalam hitungan detik | `onboarding_3` |
| OB-4 | KP-4 | Rencanakan, lalu pantau | `onboarding_4` |
| Akhir | — | Mulai dari dompet pertamamu (Buat Dompet Pertama · Nanti saja) | `onboarding_5` |

Isi teks, manfaat, konsep, dan isi ilustrasi tiap layar ada di
[ONBOARDING_ART_BRIEF.md](ONBOARDING_ART_BRIEF.md) bagian 3 — sumber
kebenaran konten onboarding.

Catatan:

- Teks final dan terjemahan `en` ditulis di T-9.1, lewat slang (namespace
  baru `onboarding`), paritas `id`/`en` wajib.
- Tombol "Buat Dompet Pertama" membuka formulir dompet yang sudah ada
  (`WalletFormSheet`), bukan formulir baru. "Nanti saja" masuk ke Beranda
  kosong (yang sudah punya ajakan dompet sendiri, UX-7).

### 3.3 Maskot dan ilustrasi (KO-7)

Maskot dan ilustrasi dibuat baru oleh pemilik.
Maskot dan spesifikasi konten tiap layar (pesan, informasi, teks, isi visual) ada di
[ONBOARDING_ART_BRIEF.md](ONBOARDING_ART_BRIEF.md). Diputuskan: maskot
**tanuki juru catat**, mengikuti nama aplikasi baru **Tanukonomy**
([ASO_NAME_RESEARCH.md](../../03-release/ASO_NAME_RESEARCH.md)). Draf SVG
buatan tangan 27 Sep 2026 ditolak dan sudah dihapus.

## 4. Spotlight: tur dan key spotlight

### 4.1 Perilaku

- **Pemicu:** kunjungan pertama ke layar, sesudah datanya termuat dan
  targetnya benar-benar tampil. Tur Beranda menunggu onboarding selesai.
- **Tampilan:** lapisan gelap semi-transparan dengan lubang di sekitar target
  (sudut `pixelSm`, garis tepi 2px aksen), gelembung panel pixel berisi judul,
  isi, penanda langkah "1/3", **Lanjut**, dan **Lewati tur**. Gelembung
  otomatis di atas/bawah target sesuai ruang.
- **Selesai:** menekan Lanjut di langkah terakhir, Lewati tur, atau tombol
  kembali sistem menandai tur itu selesai. Mengetuk target tidak menjalankan
  aksinya selama tur (menghindari membuka lembar di tengah tur).
- **Langkah bersyarat:** langkah yang targetnya tidak ada dilewati diam-diam
  (mis. kartu anggaran Beranda saat belum ada anggaran aktif), lalu disorot
  sendiri saat targetnya pertama kali tampil. Progres dicatat per langkah
  ([ADR-021](../../02-architecture/adr/0021-onboarding-dan-tur-spotlight.md) §3.1).
- **Pembaca layar:** gelembung diumumkan sebagai dialog dengan label
  "Langkah 1 dari 3: <judul>. <isi>"; fokus pindah ke gelembung.

### 4.2 Daftar tur

| Tur | Layar | Pemicu | Langkah | Prioritas |
|---|---|---|---|---|
| TR-HOME | Beranda | Pertama dibuka sesudah onboarding **dan** ada ≥1 dompet | 4 | Wajib |
| TR-CATAT | Alur CATAT | Pertama kali CATAT dibuka | 3–4 (bergantung UX-1) | Wajib |
| TR-WALLET | Dompet | Pertama dibuka | 3 | Wajib |
| TR-TXN | Transaksi | Pertama dibuka dengan ≥1 transaksi | 3 | Wajib |
| TR-PLAN-MONTH | Rencana › Bulan ini | Pertama dibuka dengan rencana berisi *(T-14.13)* | 3 | Wajib |
| TR-RECURRING | Rencana › Rutin | Pertama dibuka *(2 Okt 2026)* | 2–5 | Wajib |
| TR-BUDGET | Rencana › Anggaran | Pertama dibuka | 3–4 | Wajib |
| TR-BUDGET-DETAIL | Rincian anggaran | Pertama dibuka | 2 | Sebaiknya |
| TR-FREELANCE | Ikhtisar Freelance + rincian proyek | Pertama dibuka | 3 | Sebaiknya |

### 4.3 Key spotlight

Setiap target diberi kunci stabil (`SpotlightKey`) yang dipasang di widget
targetnya. Nama kunci = `<tur>.<elemen>`. Teks adalah draf `id`.

**TR-HOME — Beranda**

| Key | Target (widget/berkas) | Judul | Isi | Syarat |
|---|---|---|---|---|
| `home.balance` | `HomeBalanceCard` (`home_cards.dart`) | Total saldo tercatat | Jumlah saldo semua dompet aktif. Ini catatanmu, bukan saldo bank yang disinkron. | Selalu |
| `home.record` | Slot CATAT navigasi bawah (`_RecordNavIcon`, `app_shell_page.dart`) | Satu pintu mencatat | Semua uang masuk, keluar, dan pindah dompet dicatat dari sini. | Selalu |
| `home.cashFlow` | `HomeCashFlowRow` | Arus bulan ini | Pemasukan dan pengeluaran bulan berjalan. Transfer antar dompet tidak dihitung. | Ada transaksi |
| `home.budget` | `HomeBudgetCard` | Sisa anggaran aktif | Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya. | Ada anggaran aktif |
| `home.freelance` | `HomeFreelanceCard` | Ringkasan freelance | Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat pembayaran dicatat diterima. | Ada data freelance *(ditambah 28 Sep 2026)* |
| `home.forecast` | Baris perkiraan saldo (`PlanForecastRow`) | Perkiraan saldo | Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana. | Ada rutin *(2 Okt 2026)* |
| `home.pending` | Kartu Menunggu dicatat (`RecurringPendingCard`) | Menunggu dicatat | Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati. | Ada kemunculan menunggu *(2 Okt 2026)* |
| `home.recent` | Kepala "Transaksi terbaru" | Transaksi terbaru | Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan. | Ada transaksi *(ditambah 28 Sep 2026)* |

**TR-CATAT — Alur CATAT** *(bergantung bentuk UX-1, KO-5)*

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `record.kind` | Pilihan jenis (lembar pilihan, atau pengalih tiga segmen kalau UX-1 diterapkan) | Pilih jenisnya | Pemasukan menambah saldo, pengeluaran mengurangi, transfer hanya memindahkan antar dompetmu. | Selalu |
| `record.freelance` | Kartu "Honor freelance?" formulir Pemasukan (dipindah ke atas nominal) | Honor freelance lewat jalur sendiri | Uang dari proyek freelance dicatat sebagai pembayaran diterima di Freelance, bukan pemasukan biasa. Jam kerja dan tagihannya tetap nyambung. | Formulir Pemasukan *(ditambah 28 Sep 2026)* |
| `record.amount` | `RecordAmountField` | Nominal | Ketik nominalnya, atau pakai tombol cepat. | Selalu |
| `record.wallet` | `WalletSelectField` | Dompet terisi otomatis | Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu. | ≥2 dompet aktif |
| `record.budgetItem` | `RecordBudgetItemField` | Tautkan ke anggaran | Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran. | Ada pos yang ditawarkan |
| `record.repeat` | `RecordRepeatField` | Ulangi | Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam. | Transaksi baru, bukan dari kemunculan *(2 Okt 2026)* |

**TR-WALLET — Dompet**

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `wallet.summary` | `WalletSummaryCard` | Total semua dompet | Jumlah saldo tercatat dompet aktif. | Ada dompet |
| `wallet.card` | `WalletCard` pertama | Rincian dompet | Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana. | Ada dompet |
| `wallet.add` | Tombol tambah dompet | Tambah dompet | Rekening, e-wallet, atau tunai. Saldo awal bisa diubah nanti; saldo tercatat dihitung ulang. | Selalu |

**TR-TXN — Transaksi**

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `txn.month` | Konsol bulan (`TransactionMonthHeader`) | Satu bulan per tampilan | Geser bulan untuk melihat riwayat lain. Pencarian dan filter hanya mencakup bulan ini. | Selalu |
| `txn.filter` | `TransactionFilterBar` | Cari dan saring | Cari catatan atau kategori, saring per dompet dan jenis. | Selalu |
| `txn.row` | `TransactionRow` pertama | Sunting atau hapus | Ketuk transaksi untuk rinciannya; dari sana bisa disunting atau dihapus, dan saldo dihitung ulang. | Ada transaksi |

Kartu Beranda yang dimuat sendiri (`home.forecast`, `home.pending`) memasang
`TourTrigger` TR-HOME-nya sendiri, supaya disorot saat pertama tampil tanpa
menunggu Beranda dibangun ulang. `RecurringPendingCard` juga dipakai di
Rencana › Bulan ini, jadi sorotannya opsional (`spotlight:`) dan hanya diisi di
slot Beranda: satu kunci spotlight hanya boleh punya satu target.

**TR-PLAN-MONTH — Rencana › Bulan ini** dan **TR-RECURRING — Rencana › Rutin**
*(ditambah 2 Okt 2026, Fase 14)*

Langkah `plan.tabs` (sub-tab Rencana) ada di ketiga tur segmen; karena progres
per langkah, ia hanya disorot di segmen yang pertama dibuka.

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `plan.tabs` | `AppSubTabs` di `PlanPage` | Rencana | Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah. | Selalu |
| `plan.unplanned` | `UnplannedCard` | Uang nganggur | Pemasukan bulan ini dikurangi semua yang sudah terikat. | Ada rencana |
| `plan.forecast` | `BalanceForecastCard` | Saldo dompet ≈ | Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya. | Ada rencana |
| `recurring.starters` | `RecurringStarterChips` | Mulai cepat | Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan. | Belum ada rutin |
| `recurring.summary` | `RecurringSummaryCard` | Sisa rutin keluar | Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya. | Ada rutin |
| `recurring.pending` | `RecurringPendingTile` pertama | Menunggu dicatat | Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini. | Ada kemunculan menunggu |
| `recurring.add` | Tombol Tambah rutin | Tambah rutin | Bisa juga dari CATAT lewat Ulangi, atau Jadikan Rutin di rincian transaksi. | Selalu |

**TR-BUDGET — Anggaran**

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `budget.summary` | `BudgetSummaryCard` | Sisa semua anggaran aktif | Rencana dikurangi terpakai. Membuat anggaran tidak mengurangi saldo dompet. | Selalu |
| `budget.filter` | `BudgetFilterBar` | Aktif lebih dulu | Daftar menampilkan anggaran aktif. Pilih Selesai atau Semua untuk melihat yang lama. | Ada anggaran |
| `budget.templates` | Tombol Template Anggaran | Pakai template | Simpan susunan pos yang berulang, lalu buat anggaran baru darinya. | Selalu |

**TR-BUDGET-DETAIL — Rincian anggaran**

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `budgetDetail.item` | Kartu pos pertama (`_ItemCard`) | Pos anggaran | Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran. | Ada pos |
| `budgetDetail.recordFromItem` | Tombol catat di kartu pos | Catat dari pos | Membuka CATAT dengan pos ini sudah terpilih. | Anggaran tidak diarsipkan |

**TR-FREELANCE — Freelance**

| Key | Target | Judul | Isi | Syarat |
|---|---|---|---|---|
| `freelance.project` | `ProjectCard` pertama / tombol tambah proyek | Proyek dan tarif | Setiap proyek punya tarif per jam dan potongan. | Selalu |
| `freelance.worklog` | Tab/entri worklog di rincian proyek | Jam kerja | Mencatat jam kerja tidak menambah saldo. | Di rincian proyek |
| `freelance.receive` | Aksi "catat diterima" pembayaran | Uang benar-benar masuk | Saldo dompet baru bertambah saat pembayaran dicatat diterima. | Ada pembayaran tertunda |

## 5. Info: putar ulang dan bantuan

- **Putar ulang tur** per layar dan **lihat lagi pengenalan** — tempatnya
  menunggu KO-4 (saat ini aplikasi belum punya layar Pengaturan).
- **Setel ulang semua tutorial** untuk pengujian dan pemilik.
- Penjelasan aturan yang sekarang tersebar (penafian, kartu aturan) tetap di
  tempatnya sesuai UX-9; lapis info tidak menduplikasinya.

## 6. Teknis (ringkas, detailnya ADR-021)

- **Penyimpanan:** satu dokumen `KeyValueStorage`, mis.
  `onboarding/progress` = `{ schemaVersion, onboardingDone, completedTours:
  [...] }`, lewat repositori kecil di `core` atau `shared`, dengan
  `Either<Failure, T>` seperti repositori lain. Tidak memengaruhi data
  keuangan.
- **Kunci target:** `SpotlightKey` (enum) → `GlobalKey` yang dipasang lewat
  widget pembungkus `SpotlightTarget(key: SpotlightKey.homeBalance, child: …)`
  supaya layar tidak tahu detail tur.
- **Komponen:** `SpotlightOverlay` sendiri (tanpa dependensi baru) atau paket
  pihak ketiga — KO-3.
- **Pemicu:** tiap layar memanggil `SpotlightController.maybeStart(tour)`
  sesudah frame pertama dengan data termuat; controller mengecek progres,
  menyaring langkah yang targetnya tidak ada, lalu menampilkan.
- **Uji:** uji widget per tur (tampil sekali, bisa dilewati, langkah bersyarat
  dilewati, tidak tampil lagi), uji onboarding (lewati, ajakan dompet), uji
  semantik, render 360dp/390dp terang-gelap dan teks 2x di emulator.

## 7. Keputusan pemilik

Dijawab 27 Sep 2026: seluruh usulan disetujui, kecuali KO-1 dan KO-7 yang
diputuskan berbeda (tertulis di barisnya).

| Kode | Pertanyaan | Usulan |
|---|---|---|
| **KO-1** | Pengguna lama (sudah punya dompet/transaksi) saat versi ini terpasang: tampilkan onboarding? | **Diputuskan (berbeda dari usulan):** onboarding selalu tampil untuk fresh install. Pemicunya status "onboarding selesai" di perangkat, bukan ada-tidaknya dompet — jadi pengguna lama juga melihatnya sekali pada pembaruan pertama, dan bisa melewatinya. |
| **KO-2** | OB-5 (Freelance) masuk onboarding, atau cukup di tur Freelance? | **Disetujui:** Cukup di tur Freelance — onboarding 4 layar, fitur khusus tidak membebani semua orang. |
| **KO-3** | Spotlight dibuat sendiri atau pakai paket (mis. `showcaseview`, `tutorial_coach_mark`)? | **Disetujui:** Buat sendiri: bentuk pixel ADR-015 sulit ditiru lewat paket, kebutuhannya kecil, dan tanpa dependensi baru. |
| **KO-4** | Di mana tempat "putar ulang tur" dan "lihat pengenalan lagi"? | **Disetujui:** Ikon info kecil di kepala kartu utama tiap tab (`AppHeroCard.trailing`), membuka menu: "Tur layar ini" dan "Pengenalan Saldough". Alternatif: layar Pengaturan baru. |
| **KO-5** | Bentuk CATAT sesudah edukasi pindah ke onboarding (UX-1)? | **Disetujui:** CATAT langsung ke formulir Pengeluaran dengan pengalih tiga segmen; lembar pilihan dihapus; TR-CATAT menyorot pengalihnya. |
| **KO-6** | Onboarding menuntut dompet pertama sebelum masuk aplikasi? | **Disetujui:** Tidak — ajakan kuat di layar akhir, tetapi "Nanti saja" tetap ada. |
| **KO-7** | Visual onboarding: ikon pixel yang sudah ada, atau pemilik menyediakan rujukan Stitch baru? | **Diputuskan (berbeda dari usulan):** buat ilustrasi dan maskot baru — [ONBOARDING_ART_BRIEF.md](ONBOARDING_ART_BRIEF.md). |

## 8. Pecahan tugas (usulan Fase 9)

Dicatat juga di [TASK_LIST](../../04-planning/TASK_LIST.md) bagian Fase 9. Urutan =
urutan kerja; T-9.1 dikerjakan sesudah KO-1..KO-7 dijawab.

| Tugas | Isi | Bergantung | Verifikasi |
|---|---|---|---|
| **T-9.1** | ADR-021 (onboarding dan spotlight: penyimpanan, pemicu, komponen) + teks final `id`/`en` dari bagian 3–4 | KO-1..7 | Tinjauan pemilik |
| **T-9.1a** | Maskot dan ilustrasi onboarding: pemilik memilih maskot dan membuat gambar dari [brief konten](ONBOARDING_ART_BRIEF.md) | KO-7 | Pemeriksaan di brief bagian 5 |
| **T-9.2** | Repositori progres onboarding/tur di atas `KeyValueStorage` | T-9.1 | Uji unit repositori, termasuk data rusak → anggap belum dilihat |
| **T-9.3** | Layar onboarding (4–5 layar, lewati, indikator, ajakan dompet) + gerbang saat aplikasi dibuka | T-9.2 | Uji widget alur lewati/selesai/ajakan; render 360dp teks 2x |
| **T-9.4** | Komponen `SpotlightOverlay` + `SpotlightController` + `SpotlightTarget` | T-9.1 | Uji widget: posisi gelembung, lewati, kembali sistem, semantik, kurangi gerakan |
| **T-9.5** | TR-HOME | T-9.3, T-9.4 | Uji widget langkah bersyarat; render terang-gelap |
| **T-9.6** | TR-CATAT, dikerjakan bersama UX-1 | T-9.4, KO-5 | Uji alur CATAT pertama vs berikutnya |
| **T-9.7** | TR-WALLET, TR-TXN, TR-BUDGET | T-9.4 | Uji widget per tur |
| **T-9.8** | TR-BUDGET-DETAIL, TR-FREELANCE | T-9.4 | Uji widget per tur |
| **T-9.9** | Lapis info: putar ulang tur, lihat pengenalan, setel ulang | T-9.5..9.8, KO-4 | Uji widget putar ulang |
| **T-9.10** | Verifikasi menyeluruh di emulator (pengguna baru dari nol, pengguna lama) | Semua | Rekaman langkah + tangkapan layar |
