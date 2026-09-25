# Adopsi bahasa visual dari paket desain pemilik

## 1. Metadata

- **Decision ID:** ADR-015
- **Tanggal:** 2026-09-17
- **Fase roadmap:** Fase 2
- **Status:** Accepted (§Palet direvisi oleh [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md))
- **Cakupan:** Global

## 2. Konteks

[ADR-013](0013-bahasa-visual-dan-sistem-ikon.md) ditulis sebelum aset dari
pemilik tiba. Ia mempertahankan dasar krem `#F2E9D8` dan aksen indigo
`#3B3A8F` dari Saldough 1.0, secara eksplisit melarang bayangan keras
beroffset sebagai antipola, dan mengisi `AppIcon` dengan ikon Material sebagai
isian sementara sampai aset pixel-art tiba.

Pemilik sekarang mengirim paket desain lengkap di
`docs/stitch_pixel_finance_tracker/` (branch `main`, commit `250d7f7`),
kemungkinan besar keluaran alat desain AI (pola berkasnya — satu `code.html`
plus satu `screen.png` per unit, konfigurasi Tailwind inline, aset gambar dari
`googleusercontent.com` — khas Google Stitch). Isinya jauh lebih besar dari
yang diantisipasi ADR-013:

- **26 layar mobile utuh**, mencakup hampir seluruh layar yang direncanakan
  `UI_UX_DESIGN_TASKS.md` untuk Fase 2, 4, 5, dan 6 — Beranda, CATAT (tiga
  formulir), daftar dan rincian Transaksi, daftar dan rincian Dompet, daftar
  dan rincian Anggaran, Ikhtisar Freelance (Worklog dan Pembayaran), beserta
  keadaan kosong masing-masing.
- **67 ikon** sebagai SVG 32×32 asli (bukan sekadar pratinjau gambar) di
  `icon_*/code.html`, siap dipakai sebagai aset vektor.
- **`pixel_kas/DESIGN.md`** — dokumen filosofi merek, token warna, tipografi,
  elevasi, dan komponen, ditulis untuk produk bernama **"Pixel Kas"**.

Isi paket ini bertentangan langsung dengan tiga keputusan ADR-013: nama produk
(bukan Saldough), palet warna (perkamen hangat + emerald/terracotta, bukan
krem + indigo), dan — paling tajam — gaya elevasinya. ADR-013 secara eksplisit
melarang *"menghidupkan kembali bayangan keras... sebagai hiasan"*; paket ini
memakai bayangan keras beroffset (`3px 3px 0px`, `4px 4px 0px`) di **setiap**
kartu sebagai ciri utamanya, gaya yang penulisnya sendiri sebut **"Modern
Indie Game UI"** — perpaduan neo-brutalism dan estetika arcade 16-bit.

Diajukan ke pemilik lewat `AskUserQuestion`, dan dijawab:

1. **Nama produk tetap Saldough.** "Pixel Kas" dibaca sebagai nama sementara
   dari alat desainnya, bukan keputusan penamaan. Seluruh teks "Pixel Kas" di
   aset diganti "Saldough" saat diintegrasikan.
2. **Bahasa visualnya diadopsi penuh**, menggantikan ADR-013 sepenuhnya —
   bukan hanya ikonnya, tetapi palet, tipografi, dan sistem bayangannya
   sekaligus.

Tiga catatan tambahan dari audit paket ini, yang membentuk keputusan di
bawah:

- **Tidak ada mode gelap.** Konfigurasi Tailwind menyiapkan `darkMode:
  "class"`, tetapi tidak satu pun dari 26 layar memakai kelas `dark:`. Karena
  NFR-UX-003 mewajibkan mode gelap, nilai gelapnya diturunkan sistematis dari
  palet terang di bawah — dihitung, bukan dikarang, mengikuti metode yang
  sama dengan ADR-013.
- **Tidak ada huruf display pixel terpisah.** Wordmark "Pixel Kas" di header
  dirender dengan Space Grotesk tebal biasa, bukan huruf 8-bit khusus.
  Identitas "pixel"-nya ada di ikon (raster isometrik/voxel), bukan di
  tipografi. Ini menjawab pertanyaan terbuka ADR-013 soal huruf display pixel:
  jawabannya tidak perlu ada, Space Grotesk tebal sudah cukup.
- **Pemakaian warna finansial sedikit tidak konsisten antar layar** — sebagian
  memakai token `secondary` (terracotta) untuk nominal pengeluaran, sebagian
  memakai `error` (crimson). Wajar untuk 26 layar yang dibuat terpisah oleh
  alat AI. Direkonsiliasi di bawah dengan memilih satu nilai kanonik per slot,
  meneruskan prinsip "satu nilai per slot" yang sudah dipegang ADR-013.

## 3. Keputusan

Saldough 2.0 **mengadopsi penuh sistem visual yang dikirim pemilik** — palet,
tipografi, sistem elevasi bayangan keras, aturan bentuk, dan ikonnya — dengan
**nama produk tetap Saldough**. ADR ini menggantikan ADR-013 seluruhnya.

**Yang diadopsi adalah bahasa visual, bukan salinan permukaan.** Istilah
gamifikasi di aset seperti "LVL 01", "INTIP", atau "STATUS: SINKRON" adalah
pilihan tekstual alat desainnya, terpisah dari token warna/tipe/ikon. Salinan
antarmuka Saldough tetap tunduk pada
[glosarium](../../00-foundation/PROJECT_GLOSSARY.md) dan lima prinsip
antarmuka [PRD §10](../../01-product/prd-saldough-2.0.md#10-prinsip-antarmuka)
— kalau pemilik memang menginginkan nuansa gamifikasi tekstual, itu keputusan
terpisah yang belum diambil.

### Palet

Diturunkan langsung dari token Tailwind yang sama di seluruh 26 layar (bukan
dari prosa deskriptif `DESIGN.md`, yang memakai nilai hex yang sedikit
berbeda dan lebih sederhana untuk penjelasan naratif). Enam slot semantik
dipertahankan dari ADR-013; nilainya diganti seluruhnya.

Mode terang, diukur terhadap latar `#FFF8F5` dan kartu `#FFFFFF`:

| Slot | Hex | Sumber token | Latar | Kartu | Peran |
|---|---|---|---|---|---|
| `accent` | `#A73A00` | `secondary` | 6,16 | 6,46 | Tindakan utama, termasuk tombol CATAT |
| `income` | `#006948` | `primary` | 6,42 | 6,74 | Pemasukan, saldo bertambah |
| `expense` | `#BA1A1A` | `error` | 6,15 | 6,46 | Pengeluaran, saldo berkurang, saldo negatif |
| `overBudget` | `#BA1A1A` | `error` | 6,15 | 6,46 | Pos yang lewat anggaran |
| `pending` | `#8D4B00` | `tertiary` | 6,37 | 6,69 | Penghasilan freelance yang belum dibayar |
| `transfer` | `#3D4A42` | `on-surface-variant` | 8,86 | 9,31 | Transfer antar dompet |
| `textPrimary` | `#1E1B19` | `on-background` | 16,31 | 17,13 | Teks utama dan garis tepi struktural |
| `textMuted` | `#3D4A42` | `on-surface-variant` | 8,86 | 9,31 | Teks sekunder dan label |
| `background` | `#FFF8F5` | `background` | — | — | Latar halaman |
| `cardBackground` | `#FFFFFF` | `surface-container-lowest` | — | — | Permukaan kartu |

Teks putih di atas `accent` menghasilkan 6,46; di atas `income` 6,74; di atas
`expense` 6,46 — ketiganya cukup untuk label tombol terisi.

Dua penggabungan disengaja, bukan kelalaian:

- **`overBudget` memakai hex yang sama dengan `expense`.** Spesifikasi bilah
  progres anggaran yang dikirim pemilik sendiri memakai warna yang sama
  (`error`) untuk pengeluaran dan untuk anggaran yang lewat 100% — keduanya
  sinyal "arah salah/bahaya". Dibedakan lewat ikon dan konteks (baris
  transaksi vs lencana status pos anggaran), bukan lewat warna, konsisten
  dengan aturan "status dinyatakan lewat bentuk **dan** warna" yang sudah
  dipegang ADR-013.
- **`transfer` memakai hex yang sama dengan `textMuted`.** Tidak ada token
  netral lain di paket yang lolos ambang kontras 4,5:1 sebagai teks tanpa
  bertabrakan dengan `textPrimary`. Ini menepati alasan asli ADR-013 untuk
  `transfer`: sengaja netral, bukan peristiwa baik atau buruk, supaya tidak
  menyaingi makna `income`/`expense`.

**Rekonsiliasi nominal pengeluaran.** Sebagian layar memakai `secondary`
(`#A73A00`, token yang sama dengan `accent`) untuk nominal pengeluaran,
sebagian memakai `error` (`#BA1A1A`). Nilai kanonik yang dipakai adalah
`error`, sesuai mayoritas layar (daftar dan rincian transaksi) dan sesuai
antipola ADR-013 yang tetap berlaku: *"jangan pakai `accent` untuk menyatakan
makna keuangan."* `accent`/`secondary` khusus untuk tombol CATAT dan tindakan
lain, tidak pernah untuk nominal.

Mode gelap, diturunkan sistematis dari mode terang terhadap latar `#14120F`
dan kartu `#1F1C18` (paket pemilik tidak menyediakan mode gelap):

| Slot | Hex | Latar | Kartu |
|---|---|---|---|
| `accent` | `#E95100` | 5,02 | 4,56 |
| `income` | `#009767` | 5,01 | 4,54 |
| `expense` | `#EA4B4B` | 4,99 | 4,53 |
| `overBudget` | `#EA4B4B` | 4,99 | 4,53 |
| `pending` | `#CA6C00` | 5,04 | 4,57 |
| `transfer` / `textMuted` | `#708A7A` | 4,99 | 4,53 |
| `textPrimary` | `#F2ECE7` | 15,96 | 14,49 |
| `background` | `#14120F` | — | — |
| `cardBackground` | `#1F1C18` | — | — |

Diturunkan lewat kenaikan lightness HSL pada hue dan saturasi yang sama
dengan mode terang sampai lolos 4,5:1 terhadap kartu — sisi yang lebih ketat,
karena kartu lebih terang dari latar di mode gelap.

### Tipografi

Tiga peran, seluruhnya diganti dari ADR-013:

- **Judul dan angka besar — Space Grotesk 700.** Judul layar, saldo utama,
  nama modul.
- **Isi — Plus Jakarta Sans 400/500.** Deskripsi transaksi, formulir, daftar
  riwayat, nama kategori.
- **Angka tabel dan lencana — Space Mono 700, huruf besar berjarak.** Nominal
  Rupiah di kolom debet/kredit (monospace menjaga digitnya rata), lencana
  status, label pendek.

Archivo Black dan Bangers (keduanya dari ADR-0006/ADR-013) dihapus seluruhnya.
Tidak ada peran huruf display pixel terpisah — lihat catatan di §2.

Keterbacaan angka tetap tidak boleh dikorbankan demi gaya. Space Mono dipilih
justru karena monospace, bukan meski monospace — proporsi tabularnya menjaga
digit tetap rata di kolom nominal.

### Elevasi dan bayangan

**Kebalikan penuh dari ADR-013.** Bayangan keras beroffset, yang ADR-013
larang sebagai antipola, sekarang jadi ciri utama:

| Level | Dipakai untuk | Garis tepi | Bayangan | Ditekan |
|---|---|---|---|---|
| 0 — Datar | Bidang isian, baris tabel | `2px solid textPrimary` | tidak ada | — |
| 1 — Kartu | Kartu dompet, anggaran, transaksi | `2px solid textPrimary` | `3px 3px 0px textPrimary` | — |
| 2 — Interaktif | Tombol terisi, FAB CATAT | `2px solid textPrimary` | `4px 4px 0px textPrimary` | Geser `3px, 3px`, bayangan jadi `0px 0px 0px` |
| 3 — Lembar bawah | Bottom sheet | `2px solid textPrimary` (atas/kiri/kanan saja) | `0px -4px 0px textPrimary` | — |

Tidak ada bayangan lembut berkabur, tidak ada glassmorphism — keduanya tetap
dihindari, hanya penggantinya yang berubah dari "permukaan datar bergaris tepi
tipis" (ADR-013) jadi "kartrid dengan bayangan keras" (ADR ini).

### Bentuk

Radius `4px` (`0.25rem`) untuk kartu dan tombol. **Pengecualian:** lencana
status dan pil kategori memakai sudut tegas `0px`, meniru kotak dialog teks
16-bit. Bilah progres anggaran memakai segmen blok `8px` berjarak `2px`,
bukan bar melengkung kontinu — warnanya mengikuti ambang yang sama dengan
warna semantik: `income` di bawah 70%, `pending` 70–90%, `overBudget`/`expense`
di atas 100%.

### Sistem ikon

`AppIcon(IconKey)` tetap arsitekturnya (lapisan pemisah antara halaman dan
aset, dari ADR-013). Isiannya diganti dari ikon Material ke 67 SVG dari
`docs/stitch_pixel_finance_tracker/icon_*/code.html` — sumber vektor asli
32×32, bukan sekadar pratinjau gambar, siap dikonversi jadi aset Flutter.

Pemetaan 29 `IconKey` yang sudah ditetapkan ke folder asetnya:

| `IconKey` | Folder aset |
|---|---|
| `home` | `icon_nav_home` |
| `budget` | `icon_nav_budget` |
| `record` | `icon_action_catat` |
| `transactions` | `icon_nav_transactions` |
| `wallets` | `icon_wallet_dompet` |
| `walletBank` | `icon_bank_bank_building` |
| `walletCash` | `icon_cash_uang_tunai` |
| `walletEwallet` | `icon_digital_wallet_dompet_digital_qr` |
| `walletSavings` | `icon_piggy_bank_celengan` |
| `walletCard` | `icon_bank_card_kartu_debit_kredit` |
| `income` | `icon_transaction_income` |
| `expense` | `icon_transaction_expense` |
| `transfer` | `icon_transaction_transfer` |
| `categoryTransport` | `icon_category_transportation_car` |
| `categoryEntertainment` | `icon_category_games_entertainment` |
| `categoryFood`, `categoryHousehold`, `categoryBills`, `categoryOther` | Lihat catatan kategori di bawah |
| `freelance` | `icon_freelance_project` |
| `worklog` | `icon_freelance_worklog` |
| `pending` | `icon_freelance_pending_payment` |
| `paid` | `icon_freelance_paid_payment` |
| `overBudget` | `icon_status_overspent` |
| `empty` | Sprite ilustrasi keadaan kosong, lihat catatan di bawah |
| `check` | `icon_interaction_selected` |
| `calendar` | `icon_action_calendar` |
| `add`, `edit`, `delete`, `chevronLeft`, `chevronRight` | Belum ada padanan — tetap ikon Material sampai tersedia |

**Kategori belum bisa dipetakan penuh.** Aset membawa 14 ikon kategori
konkret (`coffee`, `education`, `electricity`, `emergency_fund`, `fuel`,
`games_entertainment`, `groceries`, `health`, `internet`, `investment`,
`pets`, `restaurant`, `shopping`, `transportation_car`) — jauh lebih kaya
dari 4 kunci generik (`categoryFood`, `categoryTransport`, `categoryHousehold`,
`categoryBills`) yang ada sekarang. Ini bukti kuat untuk pertanyaan terbuka
[PRD §13](../../01-product/prd-saldough-2.0.md#13-pertanyaan-terbuka) soal
daftar kategori, tetapi **daftar kategori final tetap keputusan produk
tersendiri**, belum diambil di sini. `categoryFood` sementara memakai
`icon_category_restaurant` sampai daftar final ada.

**`empty` bukan ikon kecil, tetapi ilustrasi.** Asetnya adalah
`pixel_art_voxel_empty_state_illustrations_sprite_sheet_for_personal_finance_app`,
satu lembar sprite berisi ilustrasi lebih besar untuk tiap keadaan kosong
(Beranda, Dompet, Anggaran, riwayat Transaksi — masing-masing sudah ada
rujukan layarnya di §UI_UX_DESIGN_TASKS). `AppIcon` tetap dipakai untuk
merujuknya, tetapi ukuran render harus jauh lebih besar dari 24–32px ikon
lain.

**Aset cadangan, belum dipetakan ke kunci mana pun.** `icon_nav_settings`
(tidak ada tujuan Pengaturan di navigasi bawah kita), `icon_action_filter`
dan `icon_action_search` (kandidat kunci baru untuk FR-TXN-004/FR-BUD-006,
belum diputuskan), `icon_freelance_client`/`developer_coding`/`hourly_rate`/
`invoice`/`overdue_payment`/`work_completed` (lebih detail dari yang
dibutuhkan `IconKey` saat ini; `hourly_rate`, `invoice`, dan `work_completed`
sudah dipetakan ke `IconKey.hourlyRate`/`invoice`/`workCompleted` di Fase 5
untuk kartu proyek freelance — `overdue_payment` khususnya sinyal status
"lewat jatuh tempo" yang tidak ada di `PaymentStatus` sekarang, hanya
`pending`/`paid`), `icon_status_almost_empty`/`information`/`locked`/
`on_track`/`planned`/`success`/`unlocked`/`warning`, `icon_transaction_
history`/`money_movement`/`money_received`/`money_sent`/`recurring_expense`/
`recurring_income`/`refund` (transaksi berulang dan refund eksplisit di luar
MVP), dan aset dekoratif (`icon_coins_koin_emas`, `icon_money_bag_kantong_
uang`, `icon_safe_brankas_besi`, `icon_storage_chest_peti_simpanan`,
`voxel_treasure_chest_icon`). Disimpan di repositori, tidak dipetakan, tidak
dihapus.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Pertahankan ADR-013 apa adanya, abaikan paket baru**
- **Opsi B — Ambil ikonnya saja, pertahankan palet dan larangan bayangan
  keras ADR-013**
- **Opsi C — Adopsi penuh: palet, tipografi, elevasi, dan ikon dari paket
  pemilik (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Pertahankan ADR-013

Termurah dan tidak menyentuh apa pun. Tapi mengabaikan 26 layar dan 67 ikon
yang pemilik sengaja siapkan dan kirim, dan pemilik sudah menjawab tegas lewat
`AskUserQuestion` bahwa bahasa visualnya harus diadopsi. Bukan pilihan yang
tersedia lagi setelah jawaban itu.

### Opsi B — Ambil ikonnya saja

Menghormati instruksi asli ADR-013 ("pakai ikon pemilik") tanpa mengubah
palet maupun sistem bayangan. Konsekuensinya: ikon pixel-art bergaya
isometrik/voxel yang detail akan duduk di atas kartu bergaris tepi tipis
tanpa bayangan — dua bahasa visual yang tidak sinkron. 26 layar yang sudah
dirancang pemilik sebagai satu kesatuan (ikon + bayangan + palet + tipografi)
tidak bisa dipakai sebagai rujukan langsung, hanya sebagai sumber aset.
Pemilik menjawab tidak menginginkan ini.

### Opsi C — Adopsi penuh (Dipilih)

Sejalan dengan jawaban pemilik dan dengan 26 layar yang sudah dirancang utuh
sebagai satu sistem. Konsekuensinya: seluruh keputusan ADR-013 tentang motif
(§Motif) dan sebagian besar palet dibuang, bukan disunting — karena
perubahannya menyeluruh, bukan tambahan, ADR baru yang menggantikan sesuai
konvensi `docs/README.md` lebih tepat daripada menyunting ADR-013 di tempat.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Layar Fase 2, 4, 5, 6 punya rujukan visual langsung dan lengkap, bukan
  sekadar token warna — mengurangi keputusan desain ad-hoc saat menulis
  widget.
- 67 dari kebutuhan ikon sudah terisi aset asli, bukan isian Material.
- Pertanyaan terbuka ADR-013 soal huruf display pixel selesai: tidak perlu
  ada.

### Yang menjadi lebih sulit

- Bayangan keras beroffset butuh widget kustom (`BoxShadow` offset tanpa
  blur, garis tepi 2px konsisten) — tidak tersedia langsung dari widget
  Material/Cupertino standar.
- Bilah progres tersegmentasi (blok 8px berjarak 2px) adalah widget kustom
  baru, bukan `LinearProgressIndicator` bawaan.
- Mode gelap harus disusun manual dari nilai yang diturunkan, bukan
  dicontek langsung dari aset (aset hanya sediakan mode terang).
- Kategori dan beberapa status freelance (`overdue_payment`) membawa
  granularitas yang lebih tinggi dari domain model saat ini — berpotensi
  memicu perluasan `IconKey` atau bahkan `PaymentStatus` di masa depan, tapi
  itu keputusan produk terpisah, belum diambil di sini.

### Risiko yang diterima

- **Bayangan keras di setiap kartu bisa terasa ramai di layar padat data**
  (mis. daftar transaksi panjang). Belum diuji langsung di perangkat;
  ditinjau ulang setelah Fase 2 D-2.4/D-2.6 dibangun.
- **26 layar adalah rujukan visual, bukan spesifikasi piksel-sempurna.**
  Detail kecil (padding, ukuran ikon persis) disesuaikan saat implementasi
  Flutter, mengikuti token dari ADR ini, bukan menyalin CSS Tailwind
  langsung.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Warna diakses lewat `context.appColors`, tidak pernah hex literal di
  berkas widget — aturan ini diwariskan utuh dari ADR-013.
- Bayangan keras dan garis tepi 2px dibungkus jadi satu widget/dekorator
  bersama (mis. `AppHardCard`), tidak diulang manual di tiap layar.
- Bilah progres tersegmentasi jadi satu widget bersama (mis.
  `AppSegmentedProgressBar`), dipakai di Beranda, Anggaran, dan Ikhtisar
  Freelance sekaligus — tiga tempat yang sudah dikonfirmasi memakainya.
- Ikon diakses lewat `AppIcon(IconKey.xxx)`; SVG dari `icon_*/code.html`
  dikonversi jadi aset Flutter (`assets/icons/`) saat T-7.4/T-2.1
  dikerjakan, dengan nama berkas mengikuti nama `IconKey`, bukan nama
  folder aslinya.
- Setiap slot warna baru tetap wajib uji kontras di
  `test/core/theme/app_colors_extension_test.dart`, ambang 4,5:1 — aturan
  ini tidak berubah dari ADR-013.

### Antipola yang harus dihindari

- Menyalin nilai hex dari ADR ini ke berkas widget.
- Memakai `accent`/`secondary` untuk nominal keuangan — antipola ADR-013
  yang justru jadi alasan rekonsiliasi nominal pengeluaran di atas.
- Menyalin CSS Tailwind dari `code.html` langsung ke Flutter. Aset itu
  rujukan visual, bukan sumber implementasi — satuan, breakpoint, dan
  model tata letaknya untuk web, bukan Flutter.
- Memperluas `IconKey` untuk kategori atau status freelance sebelum daftar
  kategori final dan `PaymentStatus` diputuskan.

## 8. Kriteria peninjauan ulang

- Daftar kategori transaksi/anggaran final diputuskan pemilik — pemetaan
  `categoryFood`/`categoryHousehold`/`categoryBills`/`categoryOther` dan
  kemungkinan perluasan `IconKey` ditinjau ulang saat itu.
- Bayangan keras terbukti mengganggu keterbacaan di layar padat data
  setelah D-2.4/D-2.6 dibangun dan dilihat di perangkat.
- Pemilik ingin status "lewat jatuh tempo" (`icon_freelance_overdue_
  payment`) masuk `PaymentStatus` — itu perubahan domain model, bukan
  visual, dan perlu ADR tersendiri.

## 9. Artefak terkait

### Dokumentasi

- [ADR-013](0013-bahasa-visual-dan-sistem-ikon.md) — keputusan yang
  digantikan ADR ini.
- [PRD 2.0 §10](../../01-product/prd-saldough-2.0.md#10-prinsip-antarmuka) —
  prinsip antarmuka.
- [UI_UX_DESIGN_TASKS.md](../../04-planning/UI_UX_DESIGN_TASKS.md) — tugas
  desain yang memakai paket ini sebagai rujukan per layar.

### Aset

- `docs/stitch_pixel_finance_tracker/pixel_kas/DESIGN.md` — dokumen sumber,
  token mentah, dan prosa filosofi merek.
- `docs/stitch_pixel_finance_tracker/pixel_kas_*/code.html` — 26 rujukan
  layar.
- `docs/stitch_pixel_finance_tracker/icon_*/code.html` — 67 SVG ikon.

### Rujukan kode

- `lib/core/theme/extensions/app_colors_extension.dart` — definisi seluruh
  slot.
- `lib/core/theme/app_theme.dart` — peran huruf dan token elevasi.
- `lib/core/presentation/widgets/app_icon.dart` — `IconKey` dan petanya.
- `test/core/theme/app_colors_extension_test.dart` — uji kontras tiap slot.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-17
**Status implementasi:** Disetujui, belum diimplementasikan
