# Serah terima desain: perayaan dan Buku Stempel (T-28.4, T-28.5)

**Untuk:** `flutter-engineer`. **Dari:** `ui-ux-designer`, 14 Nov 2026. **Status:** usulan rupa, menunggu persetujuan pemilik.
**Acuan perilaku:** `docs/01-product/features/GAMIFICATION.md` (G-1–G-11, §8, §13) dan ADR-046. Bila berbeda dari dokumen ini, dokumen fitur yang benar.
**Prototipe:** `buku-stempel.html` (satu folder), juga sebagai artefak. Buka, pakai panel kontrol, dan ukur dari sana. Nilai dp pada lebar 360. Token memakai `context.ds`.

## 1. Cakupan

| Tugas | Layar di prototipe |
|---|---|
| T-28.4 Perayaan | Beranda: snackbar satu stempel, snackbar dua stempel, lembar pengenalan (stempel pertama), banner pengguna lama, keadaan menunggu |
| T-28.5 Buku Stempel dan Akun | Layar Buku Stempel (sebagian, kosong, semua, memuat), lembar detail stempel, baris Buku Stempel dan sakelar Perayaan stempel di Akun |

Tidak dirancang: analitik (T-28.6), teks (T-28.7), kartu tetap di Beranda (KT-G4 menolaknya).

## 2. Gerak: tenang (G-4)

Perayaan yang **muncul sendiri** hanya boleh bergerak kecil: snackbar naik, segel mengetuk sekali, lembar naik. **Tanpa konfeti, tanpa getar layar, tanpa suara.** Gerak ramai versi Buku Periode (`../kartu-periode/`) tidak dipakai di sini; revisi G-4 14 Nov hanya membebaskan layar Buku Periode dan Kartu Periode yang dipicu tindakan pengguna.

Semua gerak mati lewat `DsMotion.reduced(context)`: snackbar dan lembar muncul tanpa geser, segel tanpa ketukan, titik tanpa napas.

| Gerak | Spek |
|---|---|
| Snackbar masuk | geser naik dari 140% dengan opasitas, 400ms `cubic-bezier(.2,.9,.3,1)`; keluar sendiri 5,2 dtk |
| Segel mengetuk (`press`) | 550ms: skala 2,2 → .9 → 1,05 → 1, putar −30° → −4° → −8° → sudut tetap, opasitas 0 → 1 |
| Lembar pengenalan | geser naik 350ms; scrim 250ms; segel besar mengetuk sekali saat tampil |
| Cincin stempel baru | cincin emas 2 mengembang .85 → 1,18 dan memudar, 2,6 dtk, berulang, hanya pada stempel belum dilihat |
| Titik "baru" | titik 8–9 bernapas (skala 1 → 1,25, 2,4 dtk) |
| Baris Akun menutup (sakelar mati) | tinggi → 0, opasitas, 350ms |

## 3. Komponen

Sudah ada di `core/design_system`: `DsCard`/`DsListCard`, `DsButton` (utama, ghost, compact), `DsInlineBanner`, `DsIconTile`, switch Material yang digayakan `DsTheme`, `DsMotion`, ikon clay (`ClayIcons.forIcon`).

Baru (usulan; tulis di fitur `milestone` kecuali dipakai fitur lain, dan segel dipakai juga oleh sampul Buku Periode):

| Widget | Isi |
|---|---|
| `DsStampSeal` | Segel bulat. Ukuran `sm` 34, `md` 56, `lg` 120. Keadaan `earned`, `locked`; opsi `isNew` (cincin), `rotation` |
| `DsStampTile` (di fitur) | Baris stempel: segel + nama + tanggal atau cara mendapatkan + titik baru atau chevron |
| `DsSnackbar` v2 | Bila belum ada. Satu slot, aksi teks |

### `DsStampSeal`

- **Diraih:** isi gradasi radial `#1F7A43` → `#14532D` (turunkan dari `heroSurface` bila dijadikan token), cincin emas dalam 2 `#FDE68A`, cincin pudar 5 (emas 28%), bayangan `0 4 8 -2` hijau 50%. Ikon clay di tengah (30 pada `md`, 62 pada `lg`, 18 pada `sm`) dengan bayangan 1px.
- **Terkunci:** isi `surfaceSunken`, cincin 2 `outlineStrong`, ikon clay abu-abu dan opasitas 40%. **Tidak ada gembok, tidak ada hitungan.**
- **Miring:** tiap stempel punya sudut tetap antara −7° dan +6° agar terasa dicap tangan. Sudut ditetapkan per id di katalog, bukan acak tiap render.
- **Ikon per id:** `wallet_first` bank_wallet, `record_first` note_pencil, `period_tidy` check_completed, `recurring_clear` repeat_loop, `inbox_clear` tray_empty, `backup_first` box_backup, `budget_first` coins_currency, `freelance_paid` coin_paid (semua ada di `assets/icons_clay/`).
- **Semantik:** `Semantics(label: "<nama>, diraih <tanggal>")` atau `"<nama>, belum diraih"`; gambar `excludeSemantics`.

## 4. Spek per layar

### 4.1 Snackbar perayaan (T-28.4)

- **Letak:** mengambang 16 dari tepi kiri dan kanan, 14 di atas navigasi bawah (74 dari dasar layar). Satu slot.
- **Bentuk:** radius 12, tinggi min 52, padding 8×8×8×12, latar `inverseSurface`, teks `inverseOnSurface` 13/18 w600, bayangan `0 10 24 -6` hitam 35%.
- **Isi:** segel `sm` (satu) atau dua segel bertumpuk dengan tumpang −12 (dua), teks, aksi "Lihat" (Space Mono kapital 11, `inversePrimary`, area sentuh 44).
- **Teks:** satu: "Stempel baru: $name"; dua atau lebih: "$count stempel baru" (G-4: digabung, bukan dua snackbar).
- **Perilaku:** hilang sendiri 5,2 dtk; menutup tidak mengubah apa pun (stempel tetap diraih). "Lihat" membuka Buku Stempel dan menggulir ke stempel baru yang disorot.
- **Tidak muncul** di Catat, di dalam lembar lain, saat onboarding atau tur. Banner pembaruan dan lembar Apa yang baru didahulukan; perayaan menunggu (lihat 4.4).

### 4.2 Lembar pengenalan, stempel pertama sepanjang masa

- **Lembar bawah:** radius atas 20, padding 10×20×20, pegangan 36×4, scrim `scrim` token.
- **Isi, tengah:** segel `lg` (stempel yang baru diraih, mengetuk sekali), judul "Buku Stempel" 20/26 w800, dua kalimat manfaat 14/20 `textSecondary` (teks `stamps.firstSheet.body`), tombol utama "Oke", tombol ghost "Atur di Akun" (membuka Akun dan menyorot baris sakelar).
- **Sekali saja** (`introShown`, ADR-046 §3.6). Menutup lembar tidak mengubah stempel.

### 4.3 Banner pengguna lama

- **Slot:** di Beranda di bawah kartu saldo hero, sekali. Bentuk `DsInlineBanner`: tile solid `sm` (ikon `verified`), eyebrow "Buku Stempel" Space Mono, teks `stamps.legacyBanner` ("Buku Stempel baru. Yang sudah kamu capai sudah ada di sini."), tombol compact "Lihat", tombol tutup 32 (area 44).
- **Perilaku (G-6):** stempel yang sudah memenuhi syarat masuk **diam-diam**; hanya banner ini. Menutup atau "Lihat" menandai `introShown`. Tidak ada perayaan satu per satu.

### 4.4 Perayaan menunggu

Bila banner pembaruan atau lembar Apa yang baru aktif, perayaan tidak tampil. Tandanya hanya **titik kecil** (9, `actionPrimary`, bercincin kanvas 2) di pojok ikon Akun pada app bar Beranda, dan titik di baris Buku Stempel di Akun, serta titik di stempel yang belum dilihat. Semua hilang begitu Buku Stempel dibuka. Tidak ada snackbar yang tertunda lalu keluar belakangan.

### 4.5 Buku Stempel

- **Rute:** Akun › Buku Stempel (bukan tab, bukan kartu Beranda). Keluar kembali ke Akun. Top bar sub-layar "Buku Stempel".
- **Kepala:** kartu `DsCard` padding 14: Tanuki 60 + kalimat `stamps.intro` ("Stempel kecil untuk hal yang berhasil kamu lakukan. Tidak ada yang hilang.") 13/18 `textSecondary`.
- **Kelompok:** Mulai, Rapi, Aman, Rencana. Judul kelompok Space Mono 11 kapital `textMuted`, margin kiri 4. Tiap kelompok satu `DsListCard`; pemisah 1px `outlineSubtle`. Kelompok kosong disembunyikan.
- **Baris stempel** (`DsStampTile`, padding 12×14, jarak 14, tinggi ≥ 66): segel `md` 56 | nama 14/20 w700 + baris kedua 12/16 `textMuted` | titik baru (8, kanan) atau chevron 18 `textTertiary`.
  - Diraih: baris kedua "Diraih 25 Okt" (`stamps.earnedOn`). Stempel baru: cincin emas berdenyut dan titik.
  - Belum diraih: nama `textSecondary` w600, segel terkunci, baris kedua = cara mendapatkan (`stamps.<id>.how`), boleh 3 baris. **Tanpa hitungan, tanpa "tinggal sekian", tanpa bilah progres, tanpa "n dari N", tanpa urutan peringkat** (KT-G1).
- **Tonggak tersembunyi (KT-G3):** `inbox_clear` (hanya Android) dan `freelance_paid` tidak tampil sampai fiturnya dipakai sekali; bila sudah diraih, tampil.
- **Ketuk stempel:** lembar detail (radius atas 20): segel `lg` (stempel baru mengetuk sekali), nama 20/26 w800, kalimat "Diraih 25 Okt. Syaratnya: …" atau cara mendapatkan + "Stempelnya masuk sendiri begitu syaratnya terpenuhi.", tombol "Tutup". Membuka stempel baru menghapus titiknya.
- **Keadaan:**
  - Sebagian: contoh Rani, empat diraih.
  - Kosong: Tanuki tidur 110, "Belum ada stempel", "Buat dompet pertamamu dan stempel pertama akan masuk ke sini." Tanpa tombol.
  - Semua: bar `alldone` di bawah daftar: "Semua stempel yang ada sudah kamu raih. Yang baru datang bersama fitur baru." (`stamps.allDone`). Tanpa konfeti.
  - Memuat: empat blok skeleton 66 tinggi, kilap menyapu 1,4 dtk, kepala tetap tampil.
  - Galat baca: anggap kosong dan evaluasi mengisi ulang diam-diam (kasus tepi §14); tidak ada layar galat.
- **Segel dan sampul:** segel yang sama dipakai di sampul Buku Periode (`../kartu-periode/`), jadi satu widget.

### 4.6 Akun

- **Grup "Aplikasi"** (di dekat Versi aplikasi), satu `DsListCard` tiga baris, tinggi min 56:
  1. **Buku Stempel:** tile ikon 36 `verified` | judul "Buku Stempel", subjudul "Stempel yang sudah kamu raih" | chevron. Titik 9 di pojok ikon bila ada stempel belum dilihat.
  2. **Perayaan stempel:** tile ikon `eco` | judul, subjudul `stamps.setting.hint` ("Tampilkan kabar kecil saat kamu meraih stempel.") | switch 44×26 (`DsTheme`). Seluruh baris bisa diketuk.
  3. Versi aplikasi (sudah ada).
- **Sakelar mati (G-8):** baris Buku Stempel menutup (tinggi → 0, 350ms) dan tidak tampil; catatan di bawah kartu berubah menjadi "Perayaan mati. Stempel tetap diraih diam-diam; nyalakan lagi untuk melihat semuanya, tanpa perayaan ulang." Menyalakan lagi membuka baris dan **tidak** memicu perayaan untuk stempel lama.
- Catatan bawah kartu (saat menyala): "Mematikan perayaan menyembunyikan Buku Stempel. Stempel tetap diraih diam-diam dan semuanya muncul lagi saat kamu menyalakannya." (usulan teks; pindahkan ke i18n).

## 5. Token

Hanya token `design-system-v2`: `surfaceCanvas/Card/Sunken`, `textPrimary/Secondary/Muted/Tertiary`, `outlineSubtle/Strong/Focus`, `actionPrimary`, `inverseSurface`, `inverseOnSurface`, `inversePrimary`, `infoContainer`, `scrim`, `ds.elevation.*`. Belum token: emas segel `#FDE68A`/`#F59E0B` dan hijau segel `#1F7A43`/`#14532D`; tambahkan ke preset bila disetujui (preset Pink: periksa kontras ikon clay di atas segel).

## 6. Aksesibilitas

Target sentuh ≥ 44 (baris, aksi snackbar, tutup banner, switch). Snackbar `Semantics(liveRegion: true)`. Warna bukan satu-satunya pembawa arti: terkunci = ikon abu-abu + teks cara mendapatkan; baru = titik + cincin. Teks 200%: baris stempel dan kartu tumbuh (tidak ada tinggi tetap kecuali segel). 360dp, id dan en, terang dan gelap, preset warna. Pembaca layar membaca nama dan keadaan stempel, bukan gambar.

## 7. Keadaan yang diuji

Satu stempel; dua stempel digabung; stempel pertama (lembar sekali); pengguna lama (banner sekali, tanpa perayaan); perayaan menunggu karena banner pembaruan; sakelar mati lalu menyala; buku kosong, sebagian, semua, memuat; tonggak tersembunyi tampil setelah dipakai; mode gelap; gerak dikurangi; bahasa en (nama stempel lebih panjang: "Pembayaran pertama diterima" memerlukan dua baris).

## 8. Pertanyaan terbuka

1. Stempel yang diraih juga menempel ke sampul Buku Periode (Plus), atau hanya Periode rapi dan Rutin tak terlewat?
2. Subjudul baris Akun "Stempel yang sudah kamu raih" tanpa hitungan. Kalau hitungan sederhana ("4 stempel") boleh, itu satu baris.
3. Warna segel (hijau dan emas) belum token; setuju ditambah ke preset?
