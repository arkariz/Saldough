# Checklist review UX/produk Saldough

Setiap poin menyebut DI MANA mengecek dan APA konsekuensinya kalau gagal.
Lewati poin yang tidak relevan ke fitur yang sedang direview, tapi jangan
lewati kategori seluruhnya tanpa alasan.

## A. Information architecture & navigasi

- Apakah aksi utama tiap layar (tambah baris, tutup siklus, rollover) jelas
  posisinya tanpa perlu menjelajah? Bandingkan dengan PRD — FR mana yang
  seharusnya jadi aksi utama layar itu.
- Chevron navigasi siklus (`cycle_page.dart`, digerbang `CycleState.hasCycle`)
  — kalau dinonaktifkan (`onPressed: null`), apakah tampilannya beda dari
  yang aktif? `IconButton` bawaan Flutter meredupkan otomatis, tapi cek
  tetap — kalau warnanya dari `context.appColors` literal, peredupan bawaan
  bisa tidak kebagian efek.
- Aksi destruktif/jarang dipakai (hapus siklus, buka kembali siklus
  tertutup) — apakah cukup mudah ditemukan SAAT dibutuhkan, tapi tidak
  gampang tersenggol tidak sengaja? Cek ada dialog konfirmasi untuk yang
  destruktif (`cycle_page.dart` bagian hapus siklus).
- Rute yang dicapai lewat `context.push` (bukan tab) — `/income/list`,
  `/worklog`, layar kartu dari grocery, dst. Pastikan ada jalan balik yang
  jelas (app bar back, bukan cuma gesture), dan state di layar asal
  tersegarkan setelah balik kalau memang ada datanya yang bisa berubah
  (lihat Fix #8 di TASK_LIST.md — ini sudah pernah jadi masalah nyata).

## B. Alur dan penyelesaian tugas

- Ikuti SATU alur penuh dari kode (bukan cuma satu widget): event dari
  tombol → handler di `*_bloc.dart` → state baru → apa yang berubah di
  `*_page.dart`. Ada jalan buntu? (Misalnya state berubah tapi tidak ada
  widget yang membaca field itu.)
- Tiap `Either` yang di-`switch` di bloc — cabang `Left` menghasilkan efek
  yang terlihat pemakai (`ShowSnackBarEffect` dsb)? Cabang yang memakai
  `.getOrElse((_) => const [])` MENELAN kegagalan secara diam — itu wajar
  untuk data sekunder (daftar sumber/kartu saat memuat layar), tapi kalau
  dipakai di jalur yang pemilik anggap aksi utama (menyimpan, menghapus),
  itu temuan: pemilik tidak akan tahu kalau gagal.
- Pilihan yang tampil tapi tidak bisa dipilih (contoh: chip Rencana
  Belanja/kartu yang sudah terpakai, `line_edit_sheet.dart`
  `_budgetSourceChip`) — apakah ada tanda VISUAL kenapa tidak bisa
  dipilih, atau cuma diam tidak merespons ketukan?
- Alur yang butuh >1 layar (tambah sumber pemasukan dari tengah-tengah
  tambah baris pemasukan) — apakah pemilik tahu dia akan balik ke tempat
  semula, atau terasa seperti "nyasar"?

## C. Cakupan state

- Kosong (`emptyIncome`, `emptyBudget`, dst di i18n) — teksnya cuma bilang
  "tidak ada data" atau mengarahkan aksi (mis. "tambah baris pertama")?
- Memuat (`isLoading`) — ada layar yang kosong total sekilas sebelum data
  datang (flash putih/kosong), padahal bisa pakai skeleton/shimmer token
  yang sudah ada (`shimmerBase`/`shimmerHighlight` di `AppColorsExtension`)?
- `needsReview` — baris yang ditandai ini maknanya "hasil rollover, belum
  dikonfirmasi" (ADR-0008). Apakah makna itu tersampaikan ke pemilik tanpa
  harus baca dokumentasi (badge + aksi konfirmasi cukup jelas), atau cuma
  warna tanpa keterangan?
- `rollUpSourceUnavailable` (baris `rollUp` yang sumbernya belum ada,
  misal kartu belum dibuat) — apakah pemilik diberi tahu APA yang harus
  dilakukan (buat dulu sumbernya), atau cuma lihat nominal 0 tanpa
  penjelasan?
- Siklus tertutup (`isClosed`, ADR-0008 freeze-on-close) — saat pemilik
  mencoba menyunting dan ditolak (`_effectCycleClosed`), apakah pesannya
  menjelaskan KENAPA (tertutup) dan APA solusinya (buka kembali), atau
  cuma "tidak bisa"?

## D. Konten/copy (bahasa Indonesia)

- Istilah yang dipakai di `id.i18n.json` cocok dengan `PROJECT_GLOSSARY.md`?
  Istilah yang SERING salah kalau ditulis bebas: "siklus" (bukan "bulan"
  atau "periode"), "baris" (bukan "item" atau "entri"), "rencana belanja"
  (bukan "grocery plan" dicampur Indonesia-Inggris).
  Istilah yang salah di satu tempat tapi benar di tempat lain itu temuan
  nyata (inkonsistensi ternama pemakai paling sering diperhatikan).
- Pesan galat (`t.common.genericErrorMessage` sebagai fallback) — kalau
  SEMUA kegagalan jatuh ke pesan generik ini, itu temuan: `Failure.
  userMessage` yang spesifik ada di domain tapi tidak sampai ke pemakai.
  Cek apakah `userMessage` tiap `Failure` subclass benar-benar dipakai.
- Dialog konfirmasi (hapus siklus, dst) — apakah kalimatnya menyebut
  KONSEKUENSI konkret (baris apa yang hilang), bukan cuma "yakin?".

## E. Konsistensi token visual (bisa dijawab dari kode saja)

- Grep literal yang seharusnya token: `Color(0x`, `EdgeInsets.all(` atau
  `EdgeInsets.symmetric(` dengan angka mentah (bukan `AppSpacing.xx`),
  `BorderRadius.circular(` dengan angka mentah (bukan `AppRadius.xx`), di
  luar `lib/core/theme/`. Tiap hit adalah pelanggaran aturan "Tampilan"
  di `AGENT_CONTEXT.md` — dan risikonya nyata: nilai itu tidak ikut
  berubah kalau token direvisi nanti.
- Grep nominal uang yang diformat manual (`~/ 100`, `NumberFormat`
  langsung di widget) di luar `AppMoneyText`/`AppMoneyFormatter` — ADR
  soal ketepatan angka berarti SATU jalur format, bukan reimplementasi
  per layar yang bisa beda pembulatan.
- Slot warna semantik (`income`/`expense`/`overBudget`/`investment`/
  `rollUp`/`needsReview`) dipakai sesuai maknanya? Pakai `expense` untuk
  menampilkan sesuatu yang bukan pengeluaran (mis. tombol hapus netral)
  adalah penyalahgunaan slot, bukan cuma soal warna.
- Mode gelap: kartu/panel pakai batas rambut (`colors.edge`/`divider`),
  bukan `BoxShadow` — cek widget yang dipakai di kedua tema, bukan cuma
  terang.

## F. Aksesibilitas & ergonomi sentuh (cek dari kode)

- `IconButton`/`GestureDetector` kecil (ikon saja, tanpa label) — ukuran
  area ketuk efektif kira-kira ≥44×44 — kalau ada `SizedBox`/`padding`
  yang memperkecil area di bawah itu, itu temuan (lihat `mobile-design`
  skill untuk acuan ukuran).
- Status nonaktif (`onPressed: null`, `Opacity` di `_budgetSourceChip`)
  — bedanya dengan status aktif harus lebih dari satu sinyal (warna SAJA
  gampang tidak kebaca orang buta warna) — idealnya warna + opacity/ikon.
- Teks yang panjangnya tidak dibatasi pemilik (nama kartu, label sumber
  pemasukan custom) dalam `Chip`/judul sempit — ada `overflow`/`maxLines`
  eksplisit, atau berpotensi meluber/terpotong aneh?

## G. Konsistensi dengan aturan domain (UX yang bersinggungan dengan korektnes)

- Baris `rollUp`/field nominal yang dibekukan (ADR-0008) — apakah UI
  secara visual membedakan baris yang BISA disunting (`kind == .manual`)
  dari yang TIDAK BISA, SEBELUM pemakai mencoba mengetuknya dan ditolak?
  Kalau tampilannya identik dan baru ditolak setelah tap, itu friksi nyata
  meski secara teknis "benar" (backend-nya sudah menolak dengan benar).
- Fix #9 (cegah duplikat sumber roll-up) — chip yang dinonaktifkan harus
  tetap MENYEBUT kenapa (misal lewat tooltip/teks), bukan cuma warna pudar
  yang mudah disangka "belum dipilih saja".

## H. Cek regresi atas perbaikan yang sudah ada

Sebelum menutup review, grep cepat tiap item di bawah masih benar di kode
saat ini (daftar ini dari `docs/04-planning/TASK_LIST.md`, jangan laporkan
ulang sebagai temuan BARU — kalau salah satunya ternyata sudah berubah,
sebut eksplisit "regresi atas Fix #N"):

1. Format bulan app bar ikut locale (`CycleMonthFormatter`).
2. Tidak ada icon button Income/Worklog redundan di app bar cycle.
3. Hint + tombol tambah sumber pemasukan saat `sources` kosong.
4. Baris pemasukan bertaut sumber ikut berubah kalau sumbernya disunting
   (selama siklus belum ditutup).
5. Chevron navigasi dibatasi ke siklus yang benar-benar ada
   (`existingCycleIds`).
6. Ada aksi hapus siklus (hanya siklus terakhir, belum ditutup).
7. Baris anggaran baru bisa ditautkan ke Rencana Belanja/kartu dari UI.
8. Sumber pemasukan baru tersegarkan tanpa pindah tab
   (`CycleIncomeSourcesRefreshRequested`).
9. Tidak bisa menautkan dua baris anggaran ke sumber roll-up yang sama.
