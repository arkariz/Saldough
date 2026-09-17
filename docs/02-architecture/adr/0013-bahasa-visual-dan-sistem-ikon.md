# Bahasa visual v2 dan sistem ikon

## 1. Metadata

- **Decision ID:** ADR-013
- **Tanggal:** 2026-09-17
- **Fase roadmap:** Fase 2
- **Status:** Accepted
- **Cakupan:** Global

> **Catatan perluasan (17 September 2026):** Versi pertama ADR ini menetapkan
> dua puluh dua kunci ikon dalam lima kelompok dan dua peran huruf. Setelah
> PRD ditulis ulang setingkat produk, dua kekurangan terlihat: tidak ada satu
> pun ikon untuk **kategori transaksi dan kategori anggaran** — padahal kategori
> muncul di tiap baris transaksi dan tiap pos anggaran — dan tidak ada ikon
> khusus freelance. Arahan visual pemilik juga menyebut **huruf display bergaya
> pixel untuk merek**, yang tidak punya tempat dalam dua peran huruf. Ketiganya
> ditambahkan di bawah. Keputusan pokok ADR ini tidak berubah.

## 2. Konteks

[ADR-0006](0006-design-token-semantic-color-mapping.md) menetapkan bahasa visual
Saldough 1.0: gaya komik pop-art dengan garis tepi tebal, bayangan keras
beroffset, tekstur halftone, badge berbentuk stiker, dan tiga peran huruf
(Archivo Black untuk angka, Space Grotesk untuk teks, Bangers untuk label
pendek). Enam slot warna semantiknya — `income`, `expense`, `overBudget`,
`investment`, `rollUp`, `needsReview` — dipetakan langsung ke konsep produk
1.0.

Pivot ke Saldough 2.0 mengubah dua hal sekaligus.

**Slot warnanya kehilangan rujukan.** `rollUp` menamai baris anggaran yang
nominalnya dihitung dari fitur lain, dan mekanisme itu dihapus.
`needsReview` menamai penanda baris salinan hasil rollover, dan rollover juga
dihapus. `investment` menamai fitur yang seluruhnya diserap primitif transfer.
Tiga dari enam slot menunjuk ke konsep yang tidak ada lagi, sementara konsep
baru — transfer, dan penghasilan freelance yang menunggu dibayar — belum punya
slot.

**Arahan visualnya berubah.** Pemilik meminta arah baru: identitas pixel-art
yang dipoles, dasar off-white hangat, tipografi gelap yang terbaca, satu aksen
utama yang kuat, dan warna pemasukan/pengeluaran/peringatan yang jelas. Yang
dihindari: biru fintech generik, gradasi berlebihan, glassmorphism, dan nuansa
perbankan korporat. Pemilik juga menyatakan akan mengirimkan **aset ikon
pixel-art** yang sudah ia siapkan, dengan instruksi tegas untuk tidak membuat
sistem ikon baru.

Dua fakta membatasi keputusan ini.

Pertama, aset ikon itu **belum ada di repositori**. Pencarian menyeluruh di
`assets/`, di `/home/user/saldough-design/`, dan di
`/home/user/saldough-comic-trial/` tidak menemukan satu pun berkas gambar; yang
ada hanya dua berkas terjemahan dan ikon peluncur bawaan `flutter create`. Fase
UI tidak boleh menunggu aset itu tiba.

Kedua, sebagian besar dasar visual 1.0 ternyata **sudah cocok** dengan arahan
baru. Latar terangnya `#F2E9D8`, yaitu krem hangat, persis yang diminta. Tinta
gelapnya `#161310` terbaca dengan rasio 15,35:1. Seluruh warna semantiknya sudah
melewati audit kontras pada September 2026 dan lolos 4,5:1. Membuang semuanya
dan mulai dari nol berarti mengulang pekerjaan yang hasilnya sudah benar.

## 3. Keputusan

Saldough 2.0 **mempertahankan dasar krem dan tipografi 1.0**, **merapikan slot
warna semantik supaya menamai konsep 2.0**, **meninggalkan motif komik**, dan
**memindahkan seluruh ikon ke lapisan `AppIcon`** yang memetakan kunci semantik
ke aset.

### Palet

Satu nilai per slot per mode. Saldough 1.0 punya dua nilai per slot — satu untuk
isian, satu lagi bervarian `…OnLight` supaya terbaca sebagai teks di atas latar
terang. Duplikasi itu dihapus: tiap slot memakai satu nilai yang sudah lolos
4,5:1 sebagai teks, dan isian memakai warna yang sama dengan transparansi atau
sebagai garis tepi.

Mode terang, diukur terhadap latar krem `#F2E9D8` dan kartu `#FFFFFF`:

| Slot | Hex | Krem | Kartu | Peran |
|---|---|---|---|---|
| `accent` | `#3B3A8F` | 7,96 | 9,60 | Tindakan utama, termasuk tombol CATAT |
| `income` | `#15702F` | 5,14 | 6,19 | Pemasukan, saldo bertambah |
| `expense` | `#B01C3A` | 5,67 | 6,83 | Pengeluaran, saldo berkurang, saldo negatif |
| `overBudget` | `#A84F05` | 4,60 | 5,55 | Pos yang lewat anggaran |
| `transfer` | `#41556B` | 6,37 | 7,67 | Transfer antar dompet |
| `pending` | `#7A5400` | 5,63 | 6,78 | Penghasilan freelance yang belum dibayar |
| `textPrimary` | `#161310` | 15,35 | 18,51 | Teks utama dan garis tepi |
| `textMuted` | `#5B5346` | 6,29 | 7,58 | Teks sekunder |
| `background` | `#F2E9D8` | — | — | Latar halaman |
| `cardBackground` | `#FFFFFF` | — | — | Permukaan kartu |

Teks putih di atas `accent` menghasilkan rasio 9,60 — cukup untuk label tombol
terisi.

Mode gelap, diukur terhadap latar `#14120F`:

| Slot | Hex | Rasio |
|---|---|---|
| `accent` | `#8B8AF5` | 6,28 |
| `income` | `#3DDC68` | 10,36 |
| `expense` | `#FF4D6A` | 5,81 |
| `overBudget` | `#FF8C3D` | 8,08 |
| `transfer` | `#9FB4CC` | 8,79 |
| `pending` | `#FFD23F` | 12,95 |

Seluruh angka di atas dihitung dengan rumus luminans relatif WCAG 2.1, bukan
diperkirakan. Slot yang dihapus: `investment`, `rollUp`, `needsReview`,
`onNeedsReview`, dan keenam varian `…OnLight`.

`transfer` sengaja **netral**, bukan biru cerah. Transfer bukan peristiwa baik
maupun buruk — ia hanya memindahkan — dan memberinya warna kuat akan
menyaingi makna `income` dan `expense`. Slate dingin juga menjauhkannya dari
`accent` indigo, supaya keduanya tidak tertukar.

### Tipografi

Dua peran wajib, satu peran opsional. Archivo Black untuk angka dan judul;
Space Grotesk untuk teks isi. **Bangers dihapus**: suara stiker komik tidak
sejalan dengan identitas pixel-art, dan label pendek kini memakai Space Grotesk
tebal berjarak huruf.

Peran ketiga adalah **huruf display bergaya pixel**, dipakai **terbatas** untuk
merek dan penekanan visual saja — nama aplikasi, layar pembuka, judul keadaan
kosong. Ia tidak pernah dipakai untuk angka maupun teks isi, sebab keterbacaan
angka adalah nilai inti proyek ini. Hurufnya belum dipilih; sampai ada,
penekanan visual memakai Archivo Black dan tidak ada yang hilang.

Keterbacaan angka tidak boleh dikorbankan demi gaya. Ketepatan angka adalah
nilai inti proyek ini, dan angka adalah isi utama hampir setiap layar.

### Motif

Motif komik ditinggalkan: tidak ada lagi bayangan keras beroffset, tekstur
halftone, badge berotasi, maupun garis tepi 2,5 piksel. Penggantinya permukaan
datar dengan garis tepi tipis dan sudut yang lembut — bahasa aplikasi mobile
modern, sesuai arahan pemilik.

Token `AppSpacing`, `AppRadius`, dan `AppDurations` dipertahankan apa adanya
karena netral terhadap gaya. `AppElevation.hardShadow` dan `AppRadius.comicCut`
dihapus bersama motifnya.

### Sistem ikon

Seluruh ikon diakses lewat `AppIcon(IconKey)` di
`lib/core/presentation/widgets/`, yang memetakan kunci semantik ke aset. Berkas
halaman tidak pernah menyebut aset maupun `Icons.*` secara langsung.

Sampai aset pixel-art dari pemilik tiba, peta itu diisi ikon Material sebagai
isian sementara. Saat aset masuk, yang berubah hanya satu berkas peta — bukan
puluhan berkas halaman. Ini alasan lapisan itu ada, dan satu-satunya cara fase
UI bisa berjalan tanpa menunggu.

Kunci yang dibutuhkan, dua puluh sembilan buah dalam enam kelompok:

| Kelompok | Kunci |
|---|---|
| Navigasi | `home`, `budget`, `record`, `transactions`, `wallets` |
| Jenis dompet | `walletBank`, `walletCash`, `walletEwallet`, `walletSavings`, `walletCard` |
| Jenis transaksi | `income`, `expense`, `transfer` |
| Kategori | `categoryFood`, `categoryTransport`, `categoryHousehold`, `categoryBills`, `categoryEntertainment`, `categoryOther` |
| Freelance | `freelance`, `worklog` |
| Status dan umpan balik | `pending`, `paid`, `overBudget`, `empty` |
| Aksi | `add`, `edit`, `delete`, `calendar`, `check`, `chevronLeft`, `chevronRight` |

Kelompok **Kategori** sengaja dibiarkan pendek dan berakhir di `categoryOther`.
Daftar kategori transaksi dan kategori anggaran belum diputuskan pemilik — itu
salah satu pertanyaan terbuka
[PRD 2.0 §13](../../01-product/prd-saldough-2.0.md#13-pertanyaan-terbuka) — dan
menambah kunci baru ke `IconKey` berbiaya satu baris, sementara menggambar aset
untuk kategori yang ternyata tidak dipakai berbiaya jauh lebih mahal.

Status dinyatakan lewat **bentuk ikon dan warna sekaligus**, tidak pernah lewat
warna saja. Ini bukan gaya melainkan syarat keterbacaan bagi mata yang sulit
membedakan warna.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Pertahankan bahasa visual komik ADR-0006 apa adanya**
- **Opsi B — Riset ulang arah visual dari nol**
- **Opsi C — Pertahankan dasar krem dan tipografi, rapikan slot warna,
  pindahkan ikon ke lapisan `AppIcon` (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Pertahankan bahasa visual komik ADR-0006

Tidak menyentuh tema sama sekali, hanya mengganti nama tiga slot yang kehilangan
rujukan. Paling murah, dan membebaskan seluruh fase pivot untuk fokus ke domain.

Yang menghalangi bukan biaya melainkan arahan. Pemilik secara eksplisit meminta
identitas pixel-art dan nuansa aplikasi mobile modern; bayangan keras beroffset,
halftone, dan huruf Bangers adalah kebalikan dari itu. Opsi ini juga
mempertahankan duplikasi `…OnLight` yang lahir dari audit kontras tambal sulam,
padahal pivot adalah kesempatan alami merapikannya.

### Opsi B — Riset ulang arah visual dari nol

Membuang ADR-0006 seluruhnya, meriset ulang arah visual aplikasi keuangan,
menyusun palet baru, dan merancang sistem ikon sendiri.

Ini yang dilakukan menjelang ADR-0006 versi pertama, dan hasilnya ditolak
pemilik. Riwayat itu relevan: arah "Ledger Tenang" yang lahir dari riset tren
fintech ditolak, dan arah komik yang dipilih pemilik sendiri menggantikannya.
Meriset ulang berarti mengulang siklus yang sudah terbukti tidak konvergen.

Opsi ini juga melanggar instruksi pemilik secara langsung — "jangan bikin sistem
ikon baru" — karena merancang ikon sendiri persis itu. Dan ia membuang dasar
yang sudah benar: krem `#F2E9D8` dan tinta `#161310` sudah sesuai arahan baru,
dan seluruh warna semantiknya sudah lolos audit kontras.

### Opsi C — Pertahankan dasar, rapikan slot, pindahkan ikon ke `AppIcon` (Dipilih)

Menyimpan yang sudah terbukti benar, mengganti yang kehilangan makna, dan
memisahkan ikon dari halaman supaya aset yang belum tiba tidak memblokir apa
pun.

Kekuatan utamanya adalah pemisahan itu. Tanpa `AppIcon`, fase UI punya dua
pilihan sama buruknya: menunggu aset tiba, atau menanam `Icons.*` di puluhan
berkas halaman lalu menyunting semuanya nanti. Dengan `AppIcon`, penggantian set
ikon jadi satu berkas.

Kelemahannya jujur. Aplikasi tidak akan benar-benar terlihat "pixel-art" sampai
aset tiba — selama fase 2 sampai 6 ia tampil dengan ikon Material di atas palet
krem, yang secara visual belum selesai. Pemilik akan melihat aplikasi setengah
jadi secara estetis selama beberapa fase, dan itu perlu disepakati di depan agar
tidak dibaca sebagai kemunduran.

Kelemahan kedua: menghapus varian `…OnLight` berarti tiap slot memakai satu
warna yang cukup gelap untuk jadi teks, sehingga isian berwarna pekat tidak lagi
tersedia langsung. Isian dibuat dari warna yang sama dengan transparansi, yang
sedikit membatasi kekayaan visual dibanding punya dua nilai terpisah. Ditukar
dengan hilangnya satu kelas kesalahan — memakai varian yang keliru sebagai teks
— yang sudah pernah terjadi di 1.0.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Mengganti seluruh set ikon jadi pekerjaan satu berkas.
- Tidak ada lagi pertanyaan "varian mana yang dipakai untuk teks", karena tiap
  slot cuma punya satu nilai yang sudah pasti terbaca.
- Setiap slot warna menamai konsep yang benar-benar ada di produk.
- Fase UI berjalan tanpa menunggu aset dari pemilik.

### Yang menjadi lebih sulit

- Isian berwarna pekat harus disusun dari warna teks dengan transparansi.
- Aplikasi tampil belum selesai secara visual sampai aset pixel-art masuk.
- Satu berkas peta ikon jadi titik yang harus dijaga; kunci yang belum
  terpetakan harus gagal secara terlihat, bukan diam-diam kosong.

### Risiko yang diterima

- **Aset pixel-art mungkin tidak pernah tiba, atau tidak mencakup seluruh 22
  kunci.** Aplikasi tetap berfungsi penuh dengan ikon sementara, jadi risikonya
  estetis, bukan fungsional.
- **Aksen indigo dipilih tanpa melihat asetnya.** Kalau aset pixel-art nanti
  membawa palet yang bertabrakan, aksennya perlu disesuaikan. Karena ia satu
  token, penyesuaiannya murah.
- **Satu nilai per slot membatasi variasi visual.** Diterima demi menghapus
  duplikasi yang pernah jadi sumber kesalahan.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Warna diakses lewat `context.appColors`, tidak pernah sebagai hex literal di
  berkas widget.
- Setiap slot warna baru wajib punya uji kontras di
  `test/core/theme/app_colors_extension_test.dart`, mengikuti pola yang sudah
  ada, dengan ambang 4,5:1.
- Ikon diakses lewat `AppIcon(IconKey.xxx)`. `Icons.*` hanya boleh muncul di
  berkas peta ikon, tidak di berkas halaman mana pun.
- `IconKey` adalah `enum`, sehingga kunci yang belum dipetakan gagal saat
  kompilasi, bukan saat dijalankan.
- Angka uang selalu memakai `AppMoneyText`, yang sudah memilih warnanya sendiri
  berdasarkan tanda nominal.

### Antipola yang harus dihindari

- Menyalin nilai hex dari ADR ini ke berkas widget. Sumbernya satu, yaitu
  `AppColorsExtension`.
- Memakai `accent` untuk menyatakan makna keuangan. Aksen menandai tindakan;
  makna keuangan memakai `income`, `expense`, `overBudget`, `transfer`, atau
  `pending`.
- Memakai emoji sebagai ikon.
- Mencampur gaya ikon: satu konsep harus memakai satu ikon yang sama di seluruh
  aplikasi, dan seluruh ikon berasal dari satu set yang sama.
- Memakai logo bank atau perusahaan sungguhan, kecuali pemilik memintanya
  secara khusus.
- Memakai huruf display pixel untuk angka atau teks isi.
- Menghidupkan kembali bayangan keras, halftone, atau rotasi sebagai hiasan.

## 8. Kriteria peninjauan ulang

- Aset pixel-art dari pemilik tiba. Palet aksen dan isian dicocokkan dengan
  aset, dan ADR ini diperbarui dengan hasilnya.
- Aset tidak tiba sampai Fase 7 selesai. Keputusan soal identitas ikon perlu
  diambil ulang, karena "sementara" yang berlangsung selamanya bukan keputusan.
- Uji kontras gagal untuk slot mana pun setelah penyesuaian palet.
- Pemilik menilai tampilan dengan ikon sementara mengganggu pemakaian
  sehari-hari, bukan sekadar belum selesai.

## 9. Artefak terkait

### Dokumentasi

- [ADR-0006](0006-design-token-semantic-color-mapping.md) — keputusan yang
  digantikan ADR ini.
- [PRD 2.0](../../01-product/prd-saldough-2.0.md) — bagian 10, prinsip
  antarmuka.
- [UI_UX_DESIGN_TASKS.md](../../04-planning/UI_UX_DESIGN_TASKS.md) — tugas
  desain yang menurunkan keputusan ini jadi layar.

### Rujukan kode

- `lib/core/theme/extensions/app_colors_extension.dart` — definisi seluruh slot.
- `lib/core/theme/app_theme.dart` — peran huruf.
- `lib/core/presentation/widgets/app_icon.dart` — `IconKey` dan petanya.
- `test/core/theme/app_colors_extension_test.dart` — uji kontras tiap slot.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-17
**Status implementasi:** Disetujui, belum diimplementasikan
