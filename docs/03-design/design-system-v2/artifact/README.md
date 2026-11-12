# Tanukonomy Design System v2 (Matcha)

Design system untuk aplikasi Tanukonomy: pencatat keuangan pribadi yang **mencatat, bukan melakukan**. Menggantikan design system lama "buku catatan piksel" (ADR-034) per 12 Nov 2026. Keputusan di ADR-043; sumber kode `lib/core/design_system/`; salinan dokumen di `docs/03-design/design-system-v2/`.

## Gagasan

Ruang kosong ala Jepang (Ma) bertemu presisi fintech: kanvas kabut hangat, garis rambut 1px, satu titik fokus hijau matcha `#1F4B2C`, huruf Plus Jakarta Sans, dan label kecil bergaya Space Mono. Sentuhan dibuat lembut dan cepat (150ms). Ikon benda memakai ilustrasi **clay** (tanah liat 3D) berwarna penuh; ikon tindakan memakai Material Symbols Outlined.

## Tema dan preset

Preset hanya membawa **warna**; huruf, sudut, jarak, dan elevasi berlaku global. Empat tema di tokens.json:

| id | Isi |
|---|---|
| `light`, `dark` | Matcha (bawaan), terang dan gelap |
| `pink`, `pink-dark` | Preset Pink: peran hijau diganti pink, pemasukan tetap hijau |

Mode gelap diturunkan dari spek (spek hanya terang): kanvas arang kehijauan, tombol utama matcha muda `#A2D2A9`, kartu hero tetap hijau hutan. Menambah preset: salin satu tema warna, isi semua token (kompilator Flutter menolak yang bolong), jalankan uji kontras.

## Prinsip

1. **Hanya token.** Warna lewat `--nama-token` (Flutter: `context.ds.colors`), tidak pernah heksadesimal di komponen. Jangan mencampur token lama dan baru di satu widget.
2. **Tiga tingkat permukaan:** kanvas, kartu (garis rambut + bayangan sangat tipis), overlay. Ditekan tidak menaikkan elevasi.
3. **Huruf piksel (Space Mono Bold) hanya** untuk label kapital, badge, nominal baris, saldo hero, label navigasi, logo kata. Sisanya Plus Jakarta Sans. Terkecil 11px (KT-DS3).
4. **Target sentuh minimal 44px**, tekan = skala 0,98 selama 150ms.
5. **Gerak dikurangi dihormati:** animasi berulang berhenti, hitung naik langsung ke nilai akhir.
6. **Mencatat, bukan melakukan:** "Catat transfer", bukan "Kirim". Teks mengikuti `writing.md`.

## Warna: peran yang paling sering dipakai

| Token | Peran |
|---|---|
| `surface-canvas` / `surface-card` / `surface-overlay` | Tingkat 0 / 1 / 2 |
| `surface-sunken` | Track segmen, tile netral, tag |
| `text-primary` / `-secondary` / `-muted` / `-tertiary` | Teks utama / pendukung / keterangan kartu / placeholder |
| `outline-subtle` / `-strong` / `-focus` | Garis rambut / checkbox / fokus |
| `action-primary` (+ `-pressed`, `on-`) | Tombol utama, tombol Catat, teks merek |
| `hero-*`, `on-hero*` | Kartu saldo hijau hutan |
| `income*`, `warning*`, `info*`, `error*` | Status dan nominal |
| `cat-<warna>` + `cat-<warna>-bg` | 10 warna kategori (ikon, latar) |

Keputusan pemilik: **KT-DS1** bingkai input/checkbox ikut spek walau di bawah 3:1 (jangan digelapkan tanpa keputusan baru); **KT-DS2** keterangan dan jam memakai `text-muted` (4,8:1), di wadah cekung pakai `text-secondary`; **KT-DS3** label piksel terkecil 11px; **KT-DS4** badge dan tag bersudut 6px, bukan pil; **KT-DS5** clay menggantikan semua ikon piksel; **KT-DS6** tile datar, hanya tombol Catat bertimbul; **KT-DS7** ikon tetap, tile ikut tema; **KT-DS8** Scan Struk tetap, "Kirim Daun" menjadi Catat Transfer.

## Bentuk

Sudut: `sm` 4 (checkbox, segmen meter), `badge` 6, `base` 8 (input, tombol), `md` 12 (tile, tombol di hero), `lg` 16 (kartu), `sheet` 20, `xl` 24 (dialog, hero), `full` (chip, pill, avatar). Margin ponsel 20, gutter 16; breakpoint tablet 32/20.

## Ikon

Grup `Ikon clay` di Aset: 61 SVG berwarna penuh (tidak bisa diwarnai ulang) di kanvas 32×32: dompet, jenis transaksi, kategori, freelance dan status, maskot, aksi cepat. Tampilkan 28–32px di tile `ds-tile--clay`. Resep gaya: bentuk gemuk bersudut bulat tanpa garis tepi, gradasi atas terang bawah jenuh, 1–3 kilap putih, satu koin emas kecil sebagai tanda tangan. Ikon baru dibuat mengikuti resep ini; gambar tambahan masih draf sampai ditinjau perancang. Ikon tindakan: Material Symbols Outlined (daftar `icon_names` di bundle.css harus tetap alfabetis).

## Komponen

Kelas berprefiks `ds-` di `components/bundle.css` (prototipe memuatnya setelah tokens.css). Di Flutter tiap komponen punya padanan berprefiks `Ds` (lihat Flutter.md). Kelompok: **Aksi** (Button), **Dasar** (IconTile, Badge, Avatar), **Data** (SegmentMeter), **Permukaan** (Card), **Daftar** (LedgerRow), **Isian** (TextField, Checkbox, SegmentedControl), **Kepala** (TopBar), **Kartu** (MascotCard, HeroCard, BudgetMeterCard, QuickAction, Banner), **Navigasi** (NavBar), **Gerak** (Motion).

## Prototipe

Prototipe 12 layar dan prototipe Rencana masih berwajah ADR-034 dan memuat salinan CSS lama sendiri; keduanya **usang** sampai dirombak per kelompok layar. Rupa baru dibuat di atas komponen di sini.

## Selisih dari acuan yang disengaja

Bayangan kartu tipis ikut acuan (spek: tanpa bayangan). Sudut tombol di hero 12 (spek 8). Margin ponsel 20 (spek) bukan 16 (acuan). Warna Tailwind di acuan dipetakan ke peran semantik. Tombol "Kirim Daun", "Isi Saldo", gamifikasi (LVL, Misi, Poin), dan istilah "Daun" untuk uang **tidak** dipakai: bertentangan dengan produk atau belum ada di PRD.
