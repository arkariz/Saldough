# Rupa B-97: Investasi manual

**Tanggal:** 18 November 2026. **Status:** Usulan (T-31.1), dibuat agen
designer atas keputusan pemilik (sama dengan Fase 30, T-30.5), tanpa papan
prototipe. Layar T-31.6 dan T-31.7 menunggu rupa ini disetujui.
**Dasar:** [ADR-049](../../02-architecture/adr/0049-investasi-manual.md)
(Accepted), [ADR-050](../../02-architecture/adr/0050-total-aset-berlapis.md)
§3.2–§3.4, [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md) §3,
§5, §10, §11, design system v2 (`context.ds`, `lib/core/design_system/`),
glosarium [`writing.md`](../design-system/writing.md), rupa
[B-96](b96-tujuan-tabungan.md) dan [B-99](b99-penyesuaian-saldo.md).

**Tanpa token baru dan tanpa komponen design system baru.** Tiga perluasan
kecil pada widget yang sudah ada (§9.1) dan dua widget fitur (§9.2).

Pertanyaan tiap layar:

| Layar | Pertanyaan |
|---|---|
| Segmen Investasi | "Investasiku sekarang bernilai berapa, dan mana yang perlu diperbarui?" |
| Rincian instrumen | "Bagaimana posisi satu investasi ini?" |
| Tambah/Ubah investasi | "Apa yang sudah kupunya?" (tanpa dompet) |
| CATAT › Investasi | "Uang dompet mana yang jadi investasi, atau sebaliknya?" |
| Perbarui nilai | "Berapa harga terbaru tiap investasi?" |

## 0. Aturan rupa yang berlaku di semua layar

| Hal | Aturan |
|---|---|
| Kata | "Nilai pasar", "Nilai perolehan", "Untung/rugi belum terwujud", "Untung/rugi terwujud". **Tidak pernah "saldo"** untuk investasi. Tombol "Catat pembelian"/"Catat penjualan", tidak "Beli"/"Jual". |
| Untung | `DsPill` nada `positive`, ikon `Symbols.trending_up_rounded`, teks bertanda "+Rp750.000 · +6,8%". |
| Rugi | `DsPill` nada `danger`, ikon `Symbols.trending_down_rounded`, "−Rp120.000 · −2,1%". Untung hijau, rugi merah sebagai indikator warna (keputusan pemilik 18 Nov 2026); tanda dan ikon tren tetap ada supaya arti tidak hanya bergantung pada warna. |
| Nol, atau belum pernah diperbarui | Pil untung/rugi tidak tampil (selisihnya pasti 0). Persen tidak tampil bila nilai perolehan 0 (ADR-049 §3.5). |
| Kesegaran | < 30 hari: teks `bodySm` `textMuted` "Diperbarui 5 hari lalu" / "Diperbarui hari ini". ≥ 30 hari: `DsPill` nada `warning` ikon `Symbols.schedule_rounded` "Diperbarui 39 hari lalu". Belum pernah: `DsPill` nada `neutral` "Belum pernah diperbarui". |
| Ikon jenis | `DsIconTile` nada `neutral`, Material Symbols: Saham `candlestick_chart_rounded`, Reksa dana `pie_chart_rounded`, Obligasi `receipt_long_rounded`, Emas `toll_rounded`, Lainnya `category_rounded`. Ikon lapis dan kosong: `ClayIcons.chart` (sudah ada). Tanpa aset baru. |
| Nominal | Lewat `AppMoneyText.format`; ikut **Sembunyikan nominal** (nilai pasar, nilai perolehan, untung/rugi nominal, harga). Persen dan jumlah (lot/unit/gram) tetap tampil, sama dengan persen tujuan (B-96). Obligasi: jumlahnya uang, jadi ikut disembunyikan. |
| Jumlah dan satuan | "12 lot", "1.523,4567 unit", "5 gram", "Rp5.000.000 nominal". Desimal mengikuti locale, angka tabular, tanpa nol buntut ("5 gram", bukan "5,0000 gram"). Saham menampilkan lembar di baris kedua bila ruang ada: "12 lot · 1.200 lembar". |
| Satuan harga | "per lembar", "per unit", "per gram", obligasi "% dari nominal" (100,50%). |

Data contoh yang dipakai di seluruh spek (angka saling cocok):

| Instrumen | Jenis | Jumlah | Nilai perolehan | Harga terakhir | Nilai pasar | Belum terwujud |
|---|---|---|---|---|---|---|
| BBCA | Saham | 12 lot | Rp11.100.000 (Rp9.250/lembar) | Rp9.875/lembar, 2 Nov | Rp11.850.000 | +Rp750.000 · +6,8% |
| Reksa dana pasar uang X | Reksa dana | 1.523,4567 unit | Rp2.000.000 | Rp1.351,22/unit, 10 Okt | Rp2.058.525 | +Rp58.525 · +2,9% (kedaluwarsa, 39 hari) |
| Emas Antam | Emas | 5 gram | Rp6.250.000 | belum pernah | Rp6.250.000 | — |
| ORI023 (Selesai) | Obligasi | 0 | — | — | — | Terwujud +Rp312.500 |

Lapis Investasi = Rp20.158.525.

## 1. Tab Dompet

### 1.1 Hero dan segmen

| Bagian | Rupa |
|---|---|
| Hero | Tidak berubah dari B-96 §0b. Lapis Investasi masuk `shownLayers` sesudah nilainya ≠ 0 (kode sudah ada, warna legenda putih). Legenda "Investasi · 13%" + nominal; mengetuknya memilih segmen Investasi. |
| Catatan kedaluwarsa | Tepat di bawah hero, ikut tergulir, **sebelum** segmen yang menempel, tampil di semua segmen bila ada ≥ 1 instrumen Aktif ≥ 30 hari. Satu baris tanpa kartu: ikon `schedule_rounded` 16px `warning`, teks `bodySm` `textSecondary` "Nilai 1 investasi sudah lebih dari 30 hari.", di kanan `DsInlineAction` `dense` **Perbarui** (area sentuh 48dp) yang membuka Perbarui nilai (§5). Teks membungkus, tidak dipotong. Tidak tampil untuk "Belum pernah diperbarui" (itu bukan kedaluwarsa; penandanya di kartu). |
| Pemilih segmen | `DsSegmentedPill` **Dompet n \| Tabungan n \| Investasi n** (n = instrumen Aktif). Segmen Investasi selalu ada, juga saat kosong, supaya fiturnya bisa ditemukan. Mode Atur tetap memaksa segmen Dompet. |

### 1.2 Isi segmen Investasi (urutan dari atas)

Urutan: ringkasan dulu (sebaran), tindakan, lalu daftar; yang sudah selesai di
bawah karena tidak lagi menjawab "bernilai berapa sekarang".

1. **Sebaran investasi** (`WalletSpreadCard`, sama dengan Sebaran dompet dan
   Sebaran tabungan), irisan = instrumen Aktif yang nilai pasarnya > 0, tampil
   bila irisan ≥ 2. Judul "Sebaran investasi", label total "Investasi",
   hitungan "3 investasi". Memilih irisan tidak membuka apa-apa (sama dengan
   Sebaran tabungan).
2. **Tindakan** (bila ada ≥ 1 instrumen Aktif): satu baris dua tombol sama
   lebar, jarak 8: `DsButton` **Catat pembelian** (`add_rounded`, satu-satunya
   tombol terisi di layar) dan `DsButton.secondary` **Perbarui nilai**
   (`update_rounded`). Di teks 200% keduanya menumpuk (Catat pembelian di atas).
3. **Kepala** `DsSectionHeader` "Investasi aktif" tanpa aksi.
4. **Kartu instrumen** Aktif, satu `DsCard` per instrumen, jarak 8, urutan:
   nilai pasar terbesar dulu. Isi:

   | Baris | Kiri | Kanan |
   |---|---|---|
   | 1 | `DsIconTile` jenis (md) + nama `titleMd` (maks 2 baris) | Nilai pasar `amount` `textPrimary` |
   | 2 | "12 lot · Saham" `bodySm` `textMuted` (kode bila ada: "12 lot · BBCA") | Pil untung/rugi (§0) |
   | 3 | Penanda kesegaran (§0) | — |

   Seluruh kartu satu target ketuk (`DsPressable`) → Rincian instrumen (§2).
5. **Selesai** (bila ada): subjudul `labelMd` `textMuted` "Selesai", lalu kartu
   yang sama tetapi redup (opasitas 0,6 seperti tujuan diarsipkan): baris 1
   nama dan di kanan "Terjual habis" `bodySm`; baris 2 "Untung terwujud" /
   "Rugi terwujud" + nominal bertanda (pil §0). Tanpa nilai pasar dan
   kesegaran.
6. **Tambah investasi**: `DsDashedButton` ikon `add_rounded` (sama dengan
   "Tambah dompet"), membuka formulir Tambah investasi (§3). Ini pintu
   "sudah punya"; pintu beli ada di tombol Catat pembelian.

### 1.3 Keadaan

| Keadaan | Rupa |
|---|---|
| Memuat | Hero dan segmen ikut pola tab sekarang; isi segmen 3 `DsSkeleton` setinggi kartu instrumen (88dp) berjarak 8. |
| Kosong | `DsCard`: `DsEmptyHero` kecil dengan `ClayIcons.chart` (gerak mati saat gerak dikurangi), judul `titleMd` "Catat investasimu", satu kalimat `bodySm` `textSecondary` "Saham, reksa dana, emas, atau obligasi. Nilainya kamu perbarui sendiri dan tidak dihitung sebagai pemasukan atau pengeluaran.", lalu `DsButton` **Tambah investasi** (expand) dan di bawahnya `DsButton.secondary` **Catat pembelian**. Teks bantu `bodySm` `textMuted` di bawah tombol: "Tambah investasi untuk yang sudah kamu punya; Catat pembelian bila uangnya keluar dari dompet." |
| Hanya Selesai | Kosong seperti di atas tanpa ilustrasi besar (kartu ringkas), lalu bagian Selesai. |
| Gagal | `DsErrorState` di area segmen: "Investasi tidak bisa dimuat." + **Coba lagi**. Hero tetap tampil dari data dompet; lapis Investasi tidak ditampilkan alih-alih menebak 0. |
| Nama panjang | Membungkus 2 baris lalu elipsis; nilai pasar tidak pernah terpotong (lebar intrinsik, nama yang mengalah). |
| Nominal besar | Rp1.250.000.000 muat di baris 1 pada 360dp karena nama mengalah; di teks 200% nilai pasar pindah ke baris sendiri di bawah nama. |

### 1.4 Beranda

Keterangan kartu saldo (`caption`) kini dibangun dari lapis yang berisi,
dipisah " · ": "Dompet Rp12,4 jt · Tabungan Rp8 jt · Investasi Rp20,2 jt"
(format ringkas yang sama dengan sekarang). Membungkus ke baris kedua bila
perlu; tidak ada ubin lapis baru di Beranda (ADR-050 §3.4 menyebut "deretan
lapis ringkas", dan keterangan inilah wujudnya sekarang). Tanpa investasi:
tidak berubah.

## 2. Rincian instrumen (halaman penuh)

Bar atas `DsTopBar` tombol kembali, judul nama instrumen (1 baris elipsis).
Angka utama layar: **nilai pasar**, di kartu biasa (bukan `DsHeroBalanceCard`,
karena hero berupa saldo dan nilai investasi bukan saldo).

| Bagian | Rupa |
|---|---|
| Kartu utama | `DsCard`: `DsIconTile` jenis (lg) + nama `titleLg` + `DsBadge` `category` jenis ("Saham", dan kode "BBCA" bila ada). Label `labelMd` `textMuted` "Nilai pasar", angka `headlineLg` tabular. Pil untung/rugi belum terwujud. Baris kesegaran (§0) dengan `DsInlineAction` **Perbarui nilai** di kanan (membuka §5 untuk instrumen ini saja). Selesai: label "Untung terwujud" dan angka itu sebagai angka utama, lencana `DsBadge` netral "Selesai". |
| Tindakan | `DsInlineActions`: **Catat pembelian** dan **Catat penjualan** (hanya bila Aktif dengan jumlah > 0). Keduanya membuka CATAT › Investasi dengan sisi dan instrumen terisi. |
| Posisi | `DsListCard` baris label–nilai: Jumlah "12 lot · 1.200 lembar" · Nilai perolehan "Rp11.100.000" · Harga rata-rata "Rp9.250 per lembar" · Harga terakhir "Rp9.875 per lembar · 2 Nov 2026" (atau "Belum pernah diperbarui") · Untung/rugi belum terwujud · Untung/rugi terwujud (hanya bila pernah ada penjualan). Keterangan `DsFootnote`-gaya `bodySm` `textMuted` di bawah kartu: "Nilai perolehan termasuk biaya dan pajak. Untung/rugi tidak dihitung sebagai pemasukan atau pengeluaran." |
| Catatan beli dan jual | `DsSectionHeader` "Catatan beli dan jual". `DsListCard` berisi `TransactionLedgerRow` investasi yang sudah ada (netral, ikon grafik, −/+), terbaru di atas, 20 terbaru lalu "Lihat semua di Riwayat" (membuka Riwayat dengan chip Investasi). Kepemilikan awal tampil sebagai baris terakhir: tile netral `inventory_2_rounded`, judul "Sudah punya sebelumnya", subjudul tanggal, kanan "12 lot" (bukan nominal bertanda, karena tidak menyentuh dompet); mengetuknya membuka Ubah investasi. Kosong: "Belum ada catatan beli atau jual." |
| Riwayat nilai | `DsSectionHeader` "Riwayat nilai". `DsListCard`, terbaru di atas, 10 terbaru lalu **Tampilkan semua** (meluas di tempat). Baris: tanggal `bodyMd`, "Rp9.875 per lembar" `bodySm` `textMuted`, kanan nilai pasar pada tanggal itu `pixelAmount`, lalu `DsIconButton` `delete_outline` berlabel "Hapus nilai 2 Nov 2026". Hapus langsung, snackbar "Nilai 2 Nov dihapus." dengan **Urungkan** (bisa dibalik, jadi tanpa dialog). Kosong: "Belum pernah diperbarui. Nilai pasar memakai nilai perolehan." |
| Kaki | `DsButton.secondary` **Ubah** (expand), lalu tombol teks `error` **Hapus investasi**. |

**Hapus investasi**

- Masih ada catatan beli/jual: tombol tetap aktif (alasan harus terlihat, bukan
  tombol mati tanpa penjelasan). Mengetuknya membuka dialog info satu tombol:
  judul "Investasi ini masih punya catatan", isi "Ada 3 catatan beli atau jual
  untuk BBCA. Hapus catatannya dulu di Riwayat; saldo dompetnya kembali seperti
  sebelum dicatat.", tombol **Lihat di Riwayat** (membuka Riwayat chip
  Investasi) dan **Tutup**.
- Tanpa catatan: `showConfirmDelete` judul "Hapus investasi ini?", isi
  "Investasi dan riwayat nilainya dihapus. Saldo dompet tidak berubah. Tidak
  bisa dibatalkan." Sesudahnya kembali ke tab Dompet, snackbar "Investasi
  dihapus."

**Keadaan:** memuat = `DsSkeleton` berbentuk kartu utama + 2 kartu daftar;
gagal = `DsErrorState` "Investasi ini tidak bisa dimuat." + Coba lagi; instrumen
sudah dihapus (tautan basi) = keadaan kosong "Investasi ini sudah tidak ada."
dengan tombol Kembali.

## 3. Formulir Tambah/Ubah investasi (halaman penuh)

Komponen formulir bersama, sama dengan formulir tujuan dan dompet:
`AppFormHeader`, `AppSectionLabel`, `AppFormTextField`, `AppFormMoneyField`,
`AppFormQuantityField` (diperluas, §9.1), `DsFieldRow`, `DsSwitchRow`,
`DsFilterChip`. Judul "Tambah investasi" / "Ubah investasi".

| Urutan | Isian | Rupa |
|---|---|---|
| 1 | **Nama** (wajib) | `AppFormTextField`, petunjuk "Mis. BBCA, Reksa dana pasar uang, Emas Antam". |
| 2 | **Jenis** (wajib) | Lima `DsFilterChip` pilih-satu, membungkus: Saham · Reksa dana · Obligasi · Emas · Lainnya, masing-masing dengan ikon jenis §0. Di bawahnya satu baris `bodySm` `textMuted` yang berganti mengikuti jenis: Saham "Jumlah dalam lot. 1 lot = 100 lembar." · Reksa dana "Jumlah dalam unit penyertaan." · Obligasi "Jumlah adalah nominal obligasi; harganya dalam persen dari nominal." · Emas "Jumlah dalam gram." · Lainnya "Jumlah dalam unit." **Terkunci** sesudah ada catatan atau riwayat nilai: chip nonaktif (terpilih tetap terlihat) dan baris bantu diganti "Jenis tidak bisa diubah karena sudah ada catatan atau riwayat nilai." |
| 3 | **Kode** (opsional) | `AppFormTextField` huruf kapital otomatis, petunjuk "Mis. BBCA". Label "Kode (opsional)". Tanpa janji fitur harga otomatis (B-101 belum ada). |
| 4 | **Sudah punya** | `DsSwitchRow` "Sudah punya sebelumnya", subjudul "Catat yang sudah kamu miliki tanpa mengubah saldo dompet." Menyala saat Tambah dibuka dari tombol Tambah investasi (pintu ini memang untuk itu); Ubah: menyala bila ada kepemilikan awal. Saat menyala tampil: |
| 4a | Tanggal | `DsFieldRow` ikon `event_rounded` "Sejak", bawaan hari ini, tidak bisa hari depan. |
| 4b | Jumlah | `AppFormQuantityField` desimal dengan akhiran satuan ("lot", "unit", "gram"); obligasi memakai `AppFormMoneyField` berlabel "Nominal". Saham: baris turunan "= 1.200 lembar". Desimal maks: saham 2 (0,01 lot = 1 lembar), lainnya 4. |
| 4c | Nilai perolehan | `AppFormMoneyField`, keterangan "Uang yang kamu keluarkan, termasuk biaya dan pajak." Baris turunan `bodySm` `textMuted` bila jumlah dan nilai terisi: "Harga rata-rata Rp9.250 per lembar" (obligasi "Harga rata-rata 98,40%"). |
| 5 | Tombol | `DsButton` **Simpan investasi** di `DsStickyBar`. Nonaktif selama nama atau jenis kosong, atau Sudah punya menyala tetapi jumlah/nilai kosong (keterangan nonaktif di atas tombol: "Isi jumlah dan nilai perolehan, atau matikan Sudah punya."). |

Ubah: galat dari use case (mengurangi kepemilikan awal sampai posisi negatif)
tampil di bawah kolom Jumlah, `bodySm` `error` dengan ikon: "Terlalu kecil:
sudah ada penjualan 15 lot sesudah tanggal ini." Formulir tidak ditutup.

Sesudah simpan: kembali, snackbar "Investasi tersimpan." Instrumen baru tanpa
Sudah punya berstatus Aktif dengan jumlah 0 dan tampil di daftar dengan "0 lot"
dan "Belum pernah diperbarui"; kartunya menawarkan Catat pembelian lewat
tindakan di Rincian.

Draf P12: lihat §6.

## 4. CATAT jenis keempat: Investasi

### 4.1 Pengalih jenis

`DsSegmentedPill` di `RecordKindSwitcher` menjadi empat: Pengeluaran ·
Pemasukan · Transfer · **Investasi** (ikon `Symbols.monitoring_rounded`).
Di 360dp tiap segmen ±72dp isi; label "Pengeluaran" dengan ikon akan terpotong,
jadi **dengan empat segmen ikon tidak ditampilkan** (label saja, keempatnya,
supaya seragam). Lihat Pertanyaan terbuka 1 bila masih terpotong.

Jenis Investasi tidak menawarkan Jadikan rutin, pos anggaran, atau kategori
(ADR-049 §3.3). Mikrofon di bar atas tetap ada, tetapi suara tidak mengisi
jenis ini (catat lewat suara tetap membuka Pengeluaran/Pemasukan/Transfer).

### 4.2 Susunan formulir (`RecordFormFrame`, dari atas)

| # | Bagian | Rupa |
|---|---|---|
| 1 | Draf | `RecordDraftCard` bila melanjutkan draf P12 (§6). |
| 2 | Sisi | Kontrol segmen sekunder (`SegmentedButton` bergaya `segmentedButtonTheme`, bukan pil hijau, supaya tidak tampak seperti pengalih jenis kedua): **Pembelian** \| **Penjualan**. Mengganti sisi mempertahankan nominal, jumlah, dan dompet; instrumen dikosongkan bila tidak Aktif saat pindah ke Penjualan. |
| 3 | Nominal | `RecordAmountField` dengan rupa netral jenis transfer (warna `textSecondary`), ditambah keterangan di bawahnya (§9.1): Pembelian "Total dibayar, termasuk biaya dan pajak" · Penjualan "Hasil bersih, sesudah biaya dan pajak". |
| 4 | Isian | `DsFieldGroup`: **Dompet** (`WalletSelectField`, label "Dari dompet" / "Ke dompet", hanya dompet aktif bukan milik tujuan, pratinjau saldo seperti transfer) · **Instrumen** (§4.3) · **Jumlah** (§4.4) · **Tanggal** (`RecordDateField`, tanpa Ulangi) · **Catatan** (`RecordNoteField`). |
| 5 | Status bawah | `bottomStatus` (§4.5), selalu terlihat di atas papan angka. |
| 6 | Simpan | `RecordSaveButton` **Catat pembelian** / **Catat penjualan**; sunting: "Simpan perubahan". Nonaktif selama dompet, instrumen, jumlah, atau nominal kosong, atau jual melebihi (§4.5). |

Bila tidak ada dompet yang bisa dipakai (semua nonaktif atau milik tujuan),
kolom Dompet tampil nonaktif dengan alasan "Belum ada dompet aktif untuk
investasi." dan tombol simpan nonaktif.

### 4.3 Instrumen

`DsFieldRow` ikon jenis terpilih (atau `monitoring_rounded`), label
"Instrumen", isi nama + `bodySm` "12 lot dimiliki". Mengetuknya membuka
`showOptionSheet`:

- Pembelian: instrumen Aktif lalu Selesai (subjudul "Selesai"), masing-masing
  tile jenis, nama, jumlah dimiliki; pilihan terakhir **+ Instrumen baru**.
- Penjualan: hanya instrumen Aktif dengan jumlah > 0, tanpa Instrumen baru.
  Tidak ada satu pun: kolom nonaktif dengan alasan "Belum ada investasi untuk
  dicatat penjualannya." dan tautan **Ganti ke Pembelian**.

**Instrumen baru** mengganti baris Instrumen dengan dua isian di tempat
(masih di dalam `DsFieldGroup` yang sama): `AppFormTextField` **Nama
instrumen** dan baris lima `DsFilterChip` **Jenis** (§3 butir 2, dengan baris
bantu satuannya), plus tautan kecil **Pilih yang sudah ada** untuk kembali.
Saat kolom nama fokus, papan angka tersembunyi (perilaku frame sekarang).
Kode dan kepemilikan awal tidak ditanyakan di sini; bisa ditambah lewat Ubah.

### 4.4 Jumlah dan papan angka (`onKeyOverride`)

Jumlah memakai kotak isian yang diisi papan angka Catat, pola kotak persen
mode bagi (ADR-048 §9.3, `record_goal_split_field.dart`):

| Hal | Rupa |
|---|---|
| Kotak | `DsFieldRow` label "Jumlah", di kanan kotak nilai 120dp: isi `surfaceSunken`, bingkai `outlineSubtle` 1px; **aktif** `surfaceCard` dengan bingkai `actionPrimary` 2px (150ms, tanpa animasi saat gerak dikurangi). Isi "12" `titleMd` tabular + akhiran satuan `bodySm` `textMuted` "lot". Kosong: "0" `textMuted`. Baris di bawah label untuk saham: "= 1.200 lembar". Obligasi: label "Nominal", isi uang "Rp5.000.000". |
| Target bawaan | Nominal (sama dengan jenis lain). |
| Pindah ke jumlah | Ketuk kotak Jumlah → kotak aktif, nominal tidak lagi bersorot, papan angka mengisi jumlah. **Otomatis sekali**: sesudah instrumen dipilih dan jumlah masih kosong, kotak Jumlah menjadi aktif (urutan alami: instrumen → jumlah → total). |
| Pindah ke nominal | Ketuk kolom nominal (pola mode bagi: `GestureDetector` di atas `RecordAmountField`). |
| Papan angka saat jumlah aktif | Tombol `000` diganti tombol desimal (pemisah locale) untuk jenis berjumlah satuan; obligasi tetap papan uang dengan `000`. Kolom operator tetap tampil tetapi nonaktif (redup, semantik "tidak tersedia") supaya papan tidak melompat. Digit desimal melebihi batas (saham 2, lainnya 4) diabaikan. Hapus dan tekan-lama hapus bekerja seperti nominal (`frameClearKey`). |
| Pembaca layar | Kotak: tombol, `selected` saat aktif, label "Jumlah, lot", nilai "12 lot". Saat target papan angka berpindah, umumkan "Papan angka mengisi jumlah" / "Papan angka mengisi nominal" (`SemanticsService.announce`). |

### 4.5 Status bawah

Satu baris `bodySm` di atas papan angka (widget fitur `RecordInvestmentStatusBar`,
pola `RecordSplitTotalBar`):

| Keadaan | Teks |
|---|---|
| Pembelian, jumlah dan nominal terisi | `textSecondary`: "≈ Rp9.250 per lembar, termasuk biaya" (obligasi "≈ 98,40% dari nominal"). |
| Penjualan, instrumen dipilih | `textSecondary`: "Dimiliki 12 lot pada 18 Nov" (mengikuti tanggal formulir), lalu harga per lembar bila nominal terisi. |
| Penjualan melebihi | `errorContainer`/`onErrorContainer` dengan ikon `error_outline`: "Melebihi yang dimiliki pada 18 Nov (12 lot)." Tombol simpan nonaktif. Validasi akhir tetap di use case; bila use case menolak (mis. tanggal dimundurkan ke sebelum pembelian), teks yang sama tampil di sini, formulir tidak ditutup. |
| Kosong | Tidak tampil (tanpa ruang kosong). |

### 4.6 Sunting catatan

Dibuka dari Rincian transaksi (Riwayat) dan dari Catatan beli dan jual di
Rincian instrumen, dengan tindakan **Ubah** di detail transaksi (melengkapi
T-31.3 yang baru punya Hapus). Pengalih jenis tidak tampil; **sisi terkunci**
(kontrol tampil nonaktif dengan keterangan "Untuk mengganti pembelian menjadi
penjualan, hapus catatan ini lalu catat lagi."); Instrumen boleh diganti ke
instrumen lain yang ada (tanpa Instrumen baru). Galat posisi negatif dari use
case: kartu galat di atas isian (pola galat dompet sama di transfer): "Perubahan
ini membuat jumlah BBCA kurang dari yang sudah dijual sesudahnya."

Sesudah simpan: snackbar "Pembelian BBCA dicatat." / "Penjualan BBCA
dicatat." / "Perubahan disimpan." (pola Catat yang ada).

## 5. Perbarui nilai (massal dan tunggal, satu layar)

Halaman penuh, dibuka dari tombol Perbarui nilai segmen, baris catatan
kedaluwarsa (semua instrumen Aktif), dan Rincian instrumen (input `only:
instrumentId`, satu kartu, judul tetap "Perbarui nilai"). Layar yang sama
nanti menjadi pratinjau B-101.

| Bagian | Rupa |
|---|---|
| Kepala | `AppFormHeader` "Perbarui nilai". |
| Tanggal | `DsFieldGroup` › `DsFieldRow` ikon `event_rounded` "Tanggal nilai", bawaan hari ini, tidak bisa hari depan; berlaku untuk semua baris. |
| Keterangan | `bodySm` `textSecondary`: "Isi harga terbaru dari aplikasi sekuritas atau situs resminya. Yang dikosongkan tidak berubah." |
| Kartu per instrumen | `DsCard`, urutan: kedaluwarsa dan belum pernah dulu, lalu sisanya mengikuti urutan segmen. Baris 1: tile jenis, nama, "12 lot" di kanan. Baris 2: "Terakhir Rp9.875 per lembar · 2 Nov" atau pil "Belum pernah diperbarui". Baris 3: kolom harga (`AppFormMoneyField` dengan akhiran "per lembar"; obligasi `AppFormQuantityField` desimal 2 dengan akhiran "% dari nominal"). Baris 4 (bila terisi): pratinjau `bodySm` "Nilai pasar Rp12.150.000" + pil untung/rugi baru. |
| Isi nilai total | Tautan `DsInlineAction` `dense` di kanan baris 2 **Isi nilai total** / **Isi harga** (berganti). Mode nilai total: kolom berlabel "Nilai total", pratinjau "= Rp10.125 per lembar" (dibulatkan ke sen, sesuai §3.4). Yang disimpan tetap harga. Tidak tampil bila jumlah 0. |
| Tanggal sama | Bila instrumen sudah punya nilai di tanggal terpilih: baris 2 menjadi "Menggantikan nilai 18 Nov (Rp9.875 per lembar)". |
| Tombol | `DsStickyBar` › `DsButton` **Simpan 2 nilai** (jumlah baris terisi). Nonaktif bila 0, dengan keterangan "Isi minimal satu harga." Tunggal: **Simpan nilai**. |
| Sesudah simpan | Kembali, snackbar "2 nilai diperbarui." / "Nilai diperbarui." |

Papan ketik sistem (angka desimal), bukan papan angka Catat: ini bukan
pencatatan uang. Kolom berikutnya lewat tombol Next keyboard.

Keadaan: memuat = 3 kartu `DsSkeleton`; gagal simpan = snackbar "Nilai belum
tersimpan. Coba lagi." dan isian tetap; tidak ada instrumen Aktif = pintu
tidak ditampilkan (layar tidak pernah kosong).

## 6. Batas Gratis (P12) dan draf

| Pintu | Pemicu | Perilaku |
|---|---|---|
| Tambah investasi | Simpan saat sudah 2 Aktif | Isian disimpan ke `investment_draft` (dengan `via: existing`), formulir ditutup, paywall P12 (`premium.paywall.instrument`, teks sudah ada). |
| CATAT › Pembelian › Instrumen baru | Simpan saat sudah 2 Aktif | Draf `via: buy` berisi isian CATAT (sisi, dompet, nama dan jenis instrumen baru, jumlah, nominal, tanggal, catatan); lembar ditutup, P12. |
| CATAT › Pembelian instrumen Selesai | Simpan saat sudah 2 Aktif | Sama dengan baris di atas, instrumen yang ada. |

Melanjutkan: draf dibuka di pintu asalnya. Tambah investasi menampilkan
`DsInlineBanner` di atas formulir: eyebrow "DRAF", "Melanjutkan isian yang
belum tersimpan.", tombol ringkas **Buang draf** (pola formulir tujuan).
CATAT › Investasi menampilkan `RecordDraftCard` (pola CATAT yang ada).
Draf terbaru menimpa yang lama (satu draf). Opsi pilih instrumen di CATAT
tidak diberi gembok: batas baru terasa saat menyimpan, sama dengan tujuan.

## 7. Teks antarmuka (kunci baru)

Ruang nama `assets.invest.*` kecuali disebut lain. Kunci yang sudah ada
(`title`, `buyTitle`, `sellTitle`, `instrumentLabel`, `walletLabel`,
`detailNote`, `filterLabel`) tetap. Copy ini draf designer mengikuti
WEALTH_ASSETS §11 dan `writing.md`; `product-owner` boleh menyesuaikan.

| Kunci | id | en |
|---|---|---|
| `activeHeading` | Investasi aktif | Active investments |
| `doneHeading` | Selesai | Closed |
| `spreadTitle` | Sebaran investasi | Investment spread |
| `count` | $n investasi | $n investments |
| `add` | Tambah investasi | Add investment |
| `recordBuy` | Catat pembelian | Record purchase |
| `recordSell` | Catat penjualan | Record sale |
| `updateValues` | Perbarui nilai | Update values |
| `update` | Perbarui | Update |
| `emptyTitle` | Catat investasimu | Track your investments |
| `emptyBody` | Saham, reksa dana, emas, atau obligasi. Nilainya kamu perbarui sendiri dan tidak dihitung sebagai pemasukan atau pengeluaran. | Stocks, mutual funds, gold, or bonds. You update their value yourself, and they never count as income or expense. |
| `emptyHint` | Tambah investasi untuk yang sudah kamu punya; Catat pembelian bila uangnya keluar dari dompet. | Use Add investment for what you already own; Record purchase when the money leaves a wallet. |
| `loadError` | Investasi tidak bisa dimuat. | Investments couldn't be loaded. |
| `detailLoadError` | Investasi ini tidak bisa dimuat. | This investment couldn't be loaded. |
| `notFound` | Investasi ini sudah tidak ada. | This investment no longer exists. |
| `staleNote` | Nilai $n investasi sudah lebih dari 30 hari. | $n investment values are over 30 days old. |
| `staleValue` | Diperbarui $n hari lalu | Updated $n days ago |
| `updatedToday` | Diperbarui hari ini | Updated today |
| `neverUpdated` | Belum pernah diperbarui | Never updated |
| `marketValue` | Nilai pasar | Market value |
| `cost` | Nilai perolehan | Cost |
| `avgPrice` | Harga rata-rata | Average price |
| `lastPrice` | Harga terakhir | Last price |
| `quantity` | Jumlah | Quantity |
| `nominal` | Nominal | Face value |
| `unrealized` | Untung/rugi belum terwujud | Unrealized gain/loss |
| `realized` | Untung/rugi terwujud | Realized gain/loss |
| `realizedGain` / `realizedLoss` | Untung terwujud / Rugi terwujud | Realized gain / Realized loss |
| `soldOut` | Terjual habis | Sold out |
| `closedBadge` | Selesai | Closed |
| `positionNote` | Nilai perolehan termasuk biaya dan pajak. Untung/rugi tidak dihitung sebagai pemasukan atau pengeluaran. | Cost includes fees and taxes. Gains and losses never count as income or expense. |
| `recordsHeading` | Catatan beli dan jual | Purchases and sales |
| `recordsEmpty` | Belum ada catatan beli atau jual. | No purchases or sales yet. |
| `seeInHistory` | Lihat semua di Riwayat | See all in History |
| `openingRow` | Sudah punya sebelumnya | Owned before |
| `valuesHeading` | Riwayat nilai | Value history |
| `valuesEmpty` | Belum pernah diperbarui. Nilai pasar memakai nilai perolehan. | Never updated. Market value uses the cost. |
| `showAll` | Tampilkan semua | Show all |
| `deleteValueLabel` | Hapus nilai $date | Delete value of $date |
| `valueDeleted` | Nilai $date dihapus. | Value of $date deleted. |
| `edit` | Ubah | Edit |
| `delete` | Hapus investasi | Delete investment |
| `deleteBlockedTitle` | Investasi ini masih punya catatan | This investment still has records |
| `deleteBlockedBody` | Ada $n catatan beli atau jual untuk $name. Hapus catatannya dulu di Riwayat; saldo dompetnya kembali seperti sebelum dicatat. | $name has $n purchase or sale records. Delete them in History first; the wallet balances go back to how they were. |
| `deleteConfirmTitle` | Hapus investasi ini? | Delete this investment? |
| `deleteConfirmBody` | Investasi dan riwayat nilainya dihapus. Saldo dompet tidak berubah. Tidak bisa dibatalkan. | The investment and its value history are deleted. Wallet balances don't change. This can't be undone. |
| `deleted` | Investasi dihapus. | Investment deleted. |
| `formTitleNew` / `formTitleEdit` | Tambah investasi / Ubah investasi | Add investment / Edit investment |
| `nameLabel` / `nameHint` | Nama / Mis. BBCA, Reksa dana pasar uang, Emas Antam | Name / E.g. BBCA, Money market fund, Gold bar |
| `typeLabel` | Jenis | Type |
| `type.stock` … `type.other` | Saham · Reksa dana · Obligasi · Emas · Lainnya | Stock · Mutual fund · Bond · Gold · Other |
| `typeHelp.stock` | Jumlah dalam lot. 1 lot = 100 lembar. | Quantity in lots. 1 lot = 100 shares. |
| `typeHelp.mutualFund` | Jumlah dalam unit penyertaan. | Quantity in fund units. |
| `typeHelp.bond` | Jumlah adalah nominal obligasi; harganya dalam persen dari nominal. | Quantity is the face value; the price is a percentage of it. |
| `typeHelp.gold` | Jumlah dalam gram. | Quantity in grams. |
| `typeHelp.other` | Jumlah dalam unit. | Quantity in units. |
| `typeLocked` | Jenis tidak bisa diubah karena sudah ada catatan atau riwayat nilai. | The type can't change once there are records or values. |
| `codeLabel` / `codeHint` | Kode (opsional) / Mis. BBCA | Ticker (optional) / E.g. BBCA |
| `ownedToggle` / `ownedToggleBody` | Sudah punya sebelumnya / Catat yang sudah kamu miliki tanpa mengubah saldo dompet. | Already own it / Record what you own without changing any wallet balance. |
| `sinceLabel` | Sejak | Since |
| `costHelp` | Uang yang kamu keluarkan, termasuk biaya dan pajak. | What you paid, including fees and taxes. |
| `ownedMissing` | Isi jumlah dan nilai perolehan, atau matikan Sudah punya. | Fill in quantity and cost, or turn off Already own it. |
| `openingTooSmall` | Terlalu kecil: sudah ada penjualan $qty sesudah tanggal ini. | Too small: $qty was sold after this date. |
| `save` | Simpan investasi | Save investment |
| `saved` | Investasi tersimpan. | Investment saved. |
| `draftResumed` / `discardDraft` | Melanjutkan isian yang belum tersimpan. / Buang draf | Continuing your unsaved entry. / Discard draft |
| `unit.lot` / `unit.unit` / `unit.gram` | lot / unit / gram | lot / units / g |
| `shares` | = $n lembar | = $n shares |
| `price.perShare` / `perUnit` / `perGram` / `bondPercent` | per lembar / per unit / per gram / % dari nominal | per share / per unit / per gram / % of face value |
| `sideBuy` / `sideSell` | Pembelian / Penjualan | Purchase / Sale |
| `amountSellCaption` | Hasil bersih, sesudah biaya dan pajak | Net proceeds, after fees and taxes |
| `fromWallet` / `toWallet` | Dari dompet / Ke dompet | From wallet / To wallet |
| `noWallet` | Belum ada dompet aktif untuk investasi. | No active wallet for investments yet. |
| `ownedHint` | $qty dimiliki | $qty owned |
| `newInstrument` / `pickExisting` | Instrumen baru / Pilih yang sudah ada | New instrument / Pick an existing one |
| `newNameLabel` | Nama instrumen | Instrument name |
| `noneToSell` / `switchToBuy` | Belum ada investasi untuk dicatat penjualannya. / Ganti ke Pembelian | No investment to record a sale for yet. / Switch to Purchase |
| `statusBuyPrice` | ≈ $price, termasuk biaya | ≈ $price, fees included |
| `statusOwned` | Dimiliki $qty pada $date | $qty owned on $date |
| `statusOverSell` | Melebihi yang dimiliki pada $date ($qty). | More than you owned on $date ($qty). |
| `sideLocked` | Untuk mengganti pembelian menjadi penjualan, hapus catatan ini lalu catat lagi. | To turn a purchase into a sale, delete this record and record it again. |
| `editNegative` | Perubahan ini membuat jumlah $name kurang dari yang sudah dijual sesudahnya. | This change leaves $name with less than was sold afterwards. |
| `buyRecorded` / `sellRecorded` | Pembelian $name dicatat. / Penjualan $name dicatat. | Purchase of $name recorded. / Sale of $name recorded. |
| `qtyActive` / `amountActive` | Papan angka mengisi jumlah / Papan angka mengisi nominal | Keypad fills the quantity / Keypad fills the amount |
| `bulk.title` | Perbarui nilai | Update values |
| `bulk.dateLabel` | Tanggal nilai | Value date |
| `bulk.intro` | Isi harga terbaru dari aplikasi sekuritas atau situs resminya. Yang dikosongkan tidak berubah. | Enter the latest prices from your broker app or official site. Empty rows stay the same. |
| `bulk.last` | Terakhir $price · $date | Last $price · $date |
| `bulk.replaces` | Menggantikan nilai $date ($price) | Replaces the value of $date ($price) |
| `bulk.fillTotal` / `bulk.fillPrice` | Isi nilai total / Isi harga | Enter total value / Enter price |
| `bulk.totalLabel` | Nilai total | Total value |
| `bulk.preview` | Nilai pasar $amount | Market value $amount |
| `bulk.pricePreview` | = $price | = $price |
| `bulk.save` / `bulk.saveOne` | Simpan $n nilai / Simpan nilai | Save $n values / Save value |
| `bulk.needOne` | Isi minimal satu harga. | Enter at least one price. |
| `bulk.saved` / `bulk.savedOne` | $n nilai diperbarui. / Nilai diperbarui. | $n values updated. / Value updated. |
| `bulk.saveError` | Nilai belum tersimpan. Coba lagi. | Values weren't saved. Try again. |
| `record.kindInvestment` | Investasi | Investment |
| `assets.layerAmount` | $label $amount | $label $amount |

`assets.homeLayers` diganti susunan `layerAmount` yang dipisah " · " (§1.4).
Kalimat bilangan (`count`, `staleNote`, `staleValue`) memakai bentuk jamak
slang untuk `en`.

## 8. Analitik (ADR-049 §3.13, tanpa nama, kode, jumlah, atau nominal)

| Layar / tindakan | Peristiwa |
|---|---|
| Simpan Tambah investasi (instrumen baru) | `instrument_added` (`type`, `via: existing`) |
| Catat pembelian dengan Instrumen baru | `instrument_added` (`type`, `via: buy`) lalu `investment_recorded` (`side: buy`) |
| Catat pembelian/penjualan instrumen yang ada | `investment_recorded` (`side`) |
| Sunting catatan investasi | tidak ada peristiwa baru (pola sunting transaksi) |
| Simpan Perbarui nilai dari segmen/baris kedaluwarsa | `valuation_updated` (`count_bucket`, `via: bulk`) |
| Simpan Perbarui nilai dari Rincian | `valuation_updated` (`count_bucket: 1`, `via: single`) |
| Paywall dari salah satu pintu §6 | `paywall_shown` (trigger `instrument_limit`) |
| Membuka segmen Investasi | `wealth_overview_viewed` yang sudah ada tetap; tanpa peristiwa baru |

## 9. Komponen

### 9.1 Perluasan widget yang ada (bukan komponen baru)

| Widget | Perluasan | Alasan |
|---|---|---|
| `AppFormQuantityField` | `decimals` (bawaan 0) dan `unit` (akhiran teks); pengurai locale yang sama dengan `money_input` | Jumlah investasi pecahan (0,01 lot, 0,5 gram, 1.523,4567 unit) dan harga obligasi persen. Kolom bilangan bulat tidak cukup. |
| `RecordFormFrame` | `keypadDecimal` (bool): saat `true`, tombol `000` diganti tombol desimal dan kolom operator dinonaktifkan | Papan angka mengisi jumlah (§4.4) tanpa melompat tata letaknya. |
| `RecordAmountField` | `caption` opsional di bawah angka | "Total dibayar, termasuk biaya dan pajak" / "Hasil bersih …". |
| `RecordKindSwitcher` | segmen keempat, ikon disembunyikan saat empat segmen | §4.1. |

### 9.2 Widget fitur (bukan design system)

- `RecordInvestmentStatusBar` (`features/record`): §4.5, pola `RecordSplitTotalBar`.
- `InvestmentQuantityBox` (`features/record`): kotak Jumlah §4.4, pola kotak
  persen `record_goal_split_field.dart` (`_PercentBox`). Bila kotak persen dan
  kotak jumlah kelak dipakai di tempat ketiga, keduanya kandidat dipindah ke
  design system sebagai satu `DsKeypadTargetBox`.

Tampilan bersama instrumen (tile jenis, format jumlah dan satuan, pil
untung/rugi, penanda kesegaran) sebaiknya di
`shared/investment/presentation/` lewat `investment_presentation.dart`
(ADR-030), supaya tab Dompet, Rincian, CATAT, dan Perbarui nilai memakai satu
sumber.

## 10. Pemeriksaan

- 360dp terang/gelap, id/en; teks 200%: tombol §1.2 menumpuk, nilai pasar
  turun ke baris sendiri, kotak Jumlah tidak terpotong.
- Satu angka utama per layar: Total aset (tab), nilai pasar (Rincian), nominal
  (CATAT). Satu tombol terisi per layar.
- Untung/rugi tidak pernah hanya warna: tanda, ikon tren, dan teks.
  Pil `positive`/`danger`/`warning` lolos kontras 4,5:1 di kedua tema (token yang ada).
- Target sentuh 48dp: kotak Jumlah, tombol hapus nilai, aksi Perbarui di
  baris kedaluwarsa, chip jenis.
- Sembunyikan nominal: semua uang termasuk harga dan nominal obligasi; persen
  dan jumlah tetap.
- Gerak dikurangi: pil segmen tanpa luncur, kotak aktif tanpa transisi,
  `DsEmptyHero` diam.
- Pembaca layar: kartu instrumen dibaca "BBCA, saham, 12 lot, nilai pasar
  11 juta 850 ribu rupiah, untung belum terwujud 750 ribu rupiah, naik 6,8
  persen, diperbarui 16 hari lalu" (satu `Semantics` gabungan, nominal lewat
  `formatRevealed` hanya bila tidak disembunyikan; tersembunyi dibaca
  "nominal disembunyikan").

## 11. Serah terima engineer (urutan yang disarankan)

1. `shared/investment/presentation/`: `investment_presentation.dart` berisi
   `instrumentTypeIcon`, `instrumentTypeLabel`, `formatQuantity` (satuan,
   desimal locale, lembar), `formatUnitPrice` (termasuk persen obligasi),
   `InvestmentGainPill`, `InvestmentFreshness`. Uji widget format dan
   Sembunyikan nominal.
2. Kunci i18n §7 (id dan en) + `translations_test`.
3. Perluasan §9.1: `AppFormQuantityField` (`decimals`, `unit`),
   `RecordAmountField.caption`, `RecordFormFrame.keypadDecimal`.
4. **T-31.7a** `features/investment`: bloc daftar (instrumen + ringkasan +
   jumlah kedaluwarsa), `InvestmentSegment` (§1.2–§1.3) disisipkan ke
   `wallet_list_page.dart` (segmen ketiga, catatan kedaluwarsa di bawah hero)
   tanpa fitur Dompet mengimpor fitur Investasi: lewat akar komposisi atau
   `shared/investment/presentation`, mengikuti pola `SavingsGoalSection`.
   Caption Beranda §1.4.
5. **T-31.7b** Rincian instrumen (§2) dan formulir Tambah/Ubah (§3) beserta
   draf dan P12 (§6), rute lewat `InvestmentRouteKeys`.
6. **T-31.7c** Perbarui nilai (§5), input `only`.
7. **T-31.6** CATAT: `RecordChoice.investment`, `RecordKindSwitcher` empat
   segmen, `investment_form_sheet.dart` (§4) dengan `InvestmentQuantityBox`
   dan `RecordInvestmentStatusBar`, sunting dari detail transaksi (tambah
   **Ubah**), draf P12.
8. Analitik §8.
9. Render 360dp terang/gelap untuk pemeriksaan rupa sebelum QA (T-31.11).

Selisih yang disengaja dari ADR/WEALTH_ASSETS:

- Ubin lapis Investasi di Beranda berwujud bagian keterangan kartu, bukan
  `DsHeroStatTile` baru (ADR-050 §3.4 mengatakan "deretan lapis ringkas";
  kode Beranda sekarang sudah memakai keterangan).
- Tautan **Lihat di Riwayat** membuka chip Investasi, bukan saringan per
  instrumen (saringan itu belum ada; jumlah catatan per instrumen kecil).

## 12. Pertanyaan terbuka (dijawab pemilik 18 Nov 2026: ketiganya mengikuti rekomendasi; rugi memakai pil merah, §0)

1. **Label pengalih jenis di 360dp.** Rekomendasi: empat segmen tanpa ikon
   dengan label yang ada. Bila "Pengeluaran" masih terpotong di 360dp teks
   100% (perlu dirender), pakai label pendek **Keluar · Masuk · Transfer ·
   Investasi** hanya di pengalih (label semantik tetap penuh). Ini perubahan
   copy di layar inti, jadi butuh persetujuan pemilik/`product-owner`.
2. **Jumlah tampil saat Sembunyikan nominal.** Rekomendasi: tetap tampil
   (bukan uang, pola persen tujuan). Bila pemilik menganggap "12 lot BBCA"
   sama sensitifnya dengan nominal, jumlah ikut disamarkan.
3. **Tur spotlight segmen Investasi** (ADR-021). Rekomendasi: tanpa langkah
   tur baru; segmen dan keadaan kosongnya sudah menjelaskan diri. Dikerjakan
   bila pemilik meminta.
