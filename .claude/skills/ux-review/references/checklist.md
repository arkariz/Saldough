# Checklist review UX/produk Saldough 2.0

Setiap poin menyebut DI MANA mengecek dan APA konsekuensinya kalau gagal.
Lewati poin yang tidak relevan ke layar yang sedang direview, tapi jangan
lewati kategori seluruhnya tanpa alasan.

## A. Information architecture & navigasi

- **CATAT selalu satu ketukan jauhnya** (prinsip produk #5, FR-REC-001).
  Slot tengah `AppShellPage` membuka `RecordChoiceSheet`, bukan tab. Cek
  lembar itu bisa dibuka dari tab mana pun, dan tidak ada layar yang
  menyembunyikan navigasi bawah tanpa jalan balik.
- **Tidak ada formulir pencatatan tersendiri** (aturan 8 CLAUDE.md). Setiap
  CTA "catat" di layar lain (keadaan kosong Transaksi, pintasan di rincian
  dompet) harus memanggil `openRecordSheet`, bukan membangun formulir
  sendiri. Pintasan kontekstual (FR-REC-002) cukup mengisi dompet sasaran
  lebih dulu.
- Layar sekunder (rincian transaksi, rincian dompet) dibuka lewat
  `Navigator.push` dengan `PixelTheme` dan bloc yang dipasang ulang. Cek ada
  jalan balik yang jelas (app bar back, bukan hanya gesture), dan layar
  asal ikut segar setelah kembali kalau datanya bisa berubah (sunting/hapus
  transaksi dari rincian → daftar dan saldo dompet ikut berubah).
- Aksi destruktif (hapus transaksi, hapus/nonaktifkan dompet) mudah
  ditemukan saat dibutuhkan tapi tidak gampang tersenggol, dan lewat
  `ConfirmDeleteDialog`.
- Tab yang masih `_ComingSoonTab` (Beranda, Anggaran) — pesannya jujur
  bahwa fitur belum ada, bukan tampak seperti layar rusak/kosong.

## B. Alur dan penyelesaian tugas

- **NFR-UX-001: pencatatan selesai dalam satu layar.** Ikuti alur
  pemasukan, pengeluaran, dan transfer dari `record_choice_sheet.dart` →
  `*_form_sheet.dart` → `RecordBloc` → snackbar. Ada langkah yang memaksa
  pindah halaman di tengah jalan (mis. harus membuat dompet dulu di layar
  lain tanpa kembali ke formulir)?
- Kondisi awal yang menghalangi: belum ada dompet sama sekali, atau hanya
  ada satu dompet (transfer butuh dua). Apakah formulir menjelaskan APA
  yang harus dilakukan, atau hanya tombol simpan yang mati tanpa alasan?
- Ikuti SATU alur penuh dari kode: event dari tombol → handler di
  `*_bloc.dart` → state/efek baru → apa yang berubah di layar. Ada jalan
  buntu (state berubah tapi tidak ada widget yang membaca field itu)?
- Tiap `Either` yang di-`switch` di bloc — cabang `Left` harus menghasilkan
  efek yang terlihat pemakai (`ShowSnackBarEffect` dsb). Kegagalan yang
  ditelan diam-diam wajar untuk data sekunder, tapi di jalur aksi utama
  (simpan, hapus) itu temuan: pemilik tidak tahu kalau gagal.
- Validasi formulir: nominal nol/kosong, dompet asal = tujuan pada
  transfer, tanggal di masa depan. Pesannya muncul di dekat field yang
  salah dan menjelaskan cara memperbaikinya?
- Penyaring Transaksi (jenis, dompet, kategori, pencarian, bulan) —
  kombinasinya bisa menghasilkan daftar kosong. Apakah keadaan kosong
  membedakan "memang belum ada transaksi" dari "tidak ada yang cocok dengan
  penyaring", dan menawarkan cara mengatur ulang penyaring?

## C. Cakupan state

- **Memuat** (`isLoading`) — pakai `AppSkeleton` (token `shimmerBase`/
  `shimmerHighlight`), bukan layar kosong sekilas.
- **Gagal memuat** (`loadFailed`) — ada pesan dan tombol "Coba lagi"
  (`t.common.retry`), bukan daftar kosong yang tampak seperti "belum ada
  data".
- **Kosong** (`wallet_empty_states.dart`, `transaction_empty_states.dart`)
  — mengarahkan aksi pertama (buat dompet, catat transaksi), bukan sekadar
  "tidak ada data". Bandingkan dengan rujukan `pixel_kas_dompet_belum_ada_data`
  dan `pixel_kas_riwayat_transaksi_kosong`.
- **Menyimpan** (`isSaving`, `record_saving_dialog.dart`) — tombol simpan
  tidak bisa ditekan dua kali sehingga transaksi tercatat ganda.
- **Konfirmasi hasil** — snackbar sesudah mencatat memakai kosakata
  "tercatat" (lihat D).
- **Dompet nonaktif** — tampil beda dari dompet aktif, tidak muncul
  sebagai pilihan sasaran di formulir CATAT baru, dan transaksi lamanya
  tetap terlihat.
- **Saldo negatif** boleh terjadi (DOMAIN_MODEL). Tampil dengan tanda dan
  warna yang jelas (`AppMoneyText` → `overBudget`), bukan diblokir atau
  disembunyikan.

## D. Konten/copy

- **NFR-UX-005: mencatat, bukan melakukan.** Periksa `id.i18n.json` dan
  `en.i18n.json` terhadap tabel "Bahasa yang dipakai aplikasi" di
  `PROJECT_GLOSSARY.md`: "Catat Transfer" bukan "Transfer Sekarang",
  "Transfer tercatat" bukan "Transfer berhasil", tidak ada "Kirim",
  "Bayar Sekarang", atau "berhasil" untuk operasi keuangan. Ini juga
  berlaku untuk copy bahasa Inggris ("recorded", bukan "sent"/"successful").
- **NFR-UX-002: istilah persis glosarium.** "Dompet" (bukan "akun"/
  "rekening" sebagai nama konsep), "Saldo tercatat", "Total saldo",
  "Pemasukan"/"Pengeluaran"/"Transfer", "Kategori". Istilah yang benar di
  satu layar tapi salah di layar lain adalah temuan nyata.
- **NFR-UX-004: dua bahasa lengkap.** Kunci yang ada di `id` tapi tidak di
  `en` (atau sebaliknya), atau teks harfiah di widget yang tidak lewat
  `t.xxx`.
- Pesan galat — kalau SEMUA kegagalan jatuh ke `t.common.
  genericErrorMessage`, itu temuan: `Failure.userMessage` yang spesifik
  tidak sampai ke pemakai.
- Dialog konfirmasi hapus menyebut KONSEKUENSI konkret: menghapus transaksi
  mengubah saldo dompet; menghapus dompet diblokir kalau sudah punya
  transaksi — pesan blokirnya menawarkan jalan keluar (nonaktifkan).

## E. Konsistensi bahasa visual (bisa dijawab dari kode saja)

- **Satu peran, satu warna (ADR-016).** Hijau/merah (`income`/`expense`)
  tidak pernah menandai pilihan atau tab aktif; terracotta (`accent`) tidak
  pernah menandai nominal; biru (`transfer`) hanya untuk transfer; amber
  (`pending`) untuk status, bukan jenis transaksi.
- **Teks-aman vs isian.** `…Fill` (`incomeFill`/`expenseFill`/
  `transferFill`) hanya untuk bidang besar (garis aksen, kotak ikon,
  bilah). Kalau `…Fill` dipakai untuk TEKS, kontrasnya bisa di bawah 4,5:1.
- Grep literal yang seharusnya token, di luar `lib/core/theme/`:
  `Color(0x`, `Colors.` (kecuali transparan), `EdgeInsets` dengan angka
  mentah (bukan `AppSpacing`), `BorderRadius.circular(` angka mentah (bukan
  `AppRadius`), `BoxShadow` manual (seharusnya `AppHardCard`).
- **Ikon** lewat `AppIcon(IconKey.xxx)`/`CategoryIcon`. `Icons.*` hanya boleh
  di berkas peta ikon (`AGENT_CONTEXT.md` "Tampilan").
- **Nominal uang** selalu lewat `AppMoneyText`/`AppMoneyFormatter`. Grep
  `~/ 100`, `NumberFormat`, atau `toStringAsFixed` di widget — pemformatan
  manual bisa beda pembulatan dari jalur resmi.
- Setiap layar/rute 2.0 berada di bawah `PixelTheme`. Rute yang di-push
  tanpa `PixelTheme` jatuh ke palet ADR-0006 lama. Gejalanya: warna,
  font, dan radius tiba-tiba berbeda.
- Mode gelap: kartu memakai garis tepi `edge` dan bayangan keras
  `AppHardCard` versi gelap, bukan bayangan lembut Material.

## F. Aksesibilitas & ergonomi sentuh

- Target sentuh ≥44×44 — `IconButton`/`GestureDetector` kecil, chip
  (`AppChip` sudah menjamin 44px; cek pemakaian `GestureDetector` mentah).
- Status nonaktif/terpilih dibedakan lebih dari satu sinyal (warna SAJA
  tidak terbaca buta warna) — warna + ikon/garis tepi/teks.
- Teks yang panjangnya ditentukan pemilik (nama dompet, catatan transaksi,
  nama kategori) dalam ruang sempit — ada `overflow`/`maxLines` eksplisit
  atau `FitStart`, bukan meluber. Nominal besar (miliaran rupiah) di kartu
  dompet dan kartu Dari/Ke transfer adalah kasus yang sudah pernah
  bermasalah.
- `Semantics`/label untuk ikon tanpa teks (tombol filter, pencarian,
  kalender).

## G. Konsistensi dengan aturan domain

- **Transfer tidak dihitung sebagai pemasukan/pengeluaran** (aturan 7).
  Ringkasan Masuk/Keluar/Neto (header bulan Transaksi, rincian dompet) tidak
  boleh berubah karena transfer. Pastikan juga UI tidak menyiratkan
  sebaliknya (mis. transfer ditampilkan dengan tanda +/− dan warna
  masuk/keluar di ringkasan).
- **Saldo awal bukan transaksi** — tidak muncul di riwayat sebagai
  "pemasukan", dan copy formulir dompet tidak menyebutnya "setoran".
- **Sunting transaksi** memakai formulir CATAT yang sama
  (`open_edit_transaction_sheet.dart`), bukan formulir kedua dengan field
  berbeda.
- Nama dompet tidak terhubung ke bank sungguhan — ikon/logo/copy tidak
  boleh menyiratkan koneksi ("Sinkronkan", "Hubungkan akun").

## H. Cek regresi atas keputusan yang sudah diambil

Sebelum menutup review, cek cepat keputusan yang tercatat di
`TASK_LIST.md` Fase 2 masih berlaku di kode. Jangan laporkan sebagai temuan
BARU. Kalau berubah, sebut "regresi atas T-x.y":

1. CATAT dibuka dari slot tengah navigasi dan dari CTA keadaan kosong lewat
   `openRecordSheet` yang SAMA (T-2.4, T-2.5).
2. Rincian dompet membuka CATAT dengan dompet itu sudah terisi (T-2.8,
   FR-REC-002).
3. Kartu Dari/Ke transfer tidak terpotong atau meluap, termasuk untuk
   nominal besar (commit "Perbaiki kartu Dari/Ke transfer").
4. `WalletPickerField`: nama dompet dan saldo tidak terpotong, tombol
   Ganti sebaris (commit "Rapikan WalletPickerField").
5. Penyaring Transaksi berupa dropdown berikon, sejalan dengan rujukan
   visual (T-2.5).
6. Hapus dompet yang sudah punya transaksi diblokir dengan pesan yang
   menawarkan nonaktifkan (T-2.7).
7. Ringkasan Masuk/Keluar/Neto rincian dompet tidak berubah oleh transfer
   (T-2.8, diverifikasi di T-2.10).
