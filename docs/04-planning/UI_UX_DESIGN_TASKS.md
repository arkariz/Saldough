# Tugas desain UI/UX

Dokumen ini melacak pekerjaan desain visual Saldough 2.0, terpisah dari
[TASK_LIST.md](TASK_LIST.md) yang melacak pekerjaan kode. Keduanya memetakan
ke requirement [PRD 2.0](../01-product/prd-saldough-2.0.md) yang sama, tapi
desain selesai lebih dulu — sejalan dengan preferensi pemilik "dokumentasi
dan desain lebih dulu, kode menyusul".

Setiap tugas desain diberi identitas `D-<fase>.<nomor>`, memakai nomor fase
yang sama dengan [ROADMAP.md](ROADMAP.md), supaya satu layar mudah dilacak
dari desain sampai kode. Desain tidak punya Fase 0 (dokumen) atau Fase 3
(cutover) sendiri — keduanya tidak punya permukaan visual baru, sama seperti
dokumen 1.0 melewati fase gerbang dan fase sinkronisasinya.

## Tautan Design Canvas

Belum ada Design Canvas untuk Saldough 2.0. Kanvas pertamanya dibuat di
**D-2.1**, sebagai satu kanvas tunggal yang mencakup seluruh layar inti
Fase 2 sekaligus — bukan satu kanvas per fase seperti di 1.0 — karena
Beranda, CATAT, Transaksi, Dompet, dan Anggaran memakai kartu dan baris
yang sama, dan memecahnya per fase akan mengulang pekerjaan yang sama.
Kanvas itu diperluas, bukan diganti, saat layar Anggaran (Fase 4),
Freelance (Fase 5), dan Beranda (Fase 6) ditambahkan. Tautannya diisi di
bagian ini begitu kanvas pertama diterbitkan.

## Cara memakai dokumen ini

Aturan pencentangan sama ketatnya dengan `TASK_LIST.md`: sebuah kotak hanya
dicentang kalau artboard-nya benar-benar ada di Design Canvas yang
diterbitkan, bukan baru direncanakan.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum dimulai |
| `- [~]` | Dalam Design Canvas yang sedang dikerjakan |
| `- [x]` | Selesai, ada di Design Canvas yang sudah diterbitkan |

Setiap tugas diakhiri baris `Memenuhi FR-xxx.` yang menautkannya ke
[PRD 2.0](../01-product/prd-saldough-2.0.md), dan tanda `⚠` menandai jebakan
yang sudah diketahui — baca sebelum mengerjakan, bukan sesudah.

## Ringkasan progres

Terakhir diperbarui: 17 September 2026.

| Fase | Tugas desain | Selesai | Status |
|---|---|---|---|
| 2 — Layar inti | 6 | 0 | Belum dimulai |
| 4 — Anggaran | 4 | 0 | Belum dimulai |
| 5 — Freelance | 3 | 0 | Belum dimulai |
| 6 — Beranda | 2 | 0 | Belum dimulai |
| 7 — Template dan poles | 2 | 0 | Belum dimulai |
| **Total** | **17** | **0** | |

## Fase 2: Layar inti

Satu kanvas tunggal untuk seluruh layar inti, dikerjakan di awal fase ini —
bukan satu kanvas per fase seperti di 1.0 — karena layar-layarnya saling
terkait erat dan memecahnya akan mengulang pekerjaan kartu dan baris yang
sama berkali-kali.

Pemilik sudah mengirim rujukan visual lengkap di
`docs/stitch_pixel_finance_tracker/` (lihat
[ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md)) —
26 layar dan 67 ikon. Tiap tugas D-x.x di bawah menautkan folder rujukannya.
Kanvas tetap dibangun dengan ikon Material sebagai isian sementara sampai
T-7.4 mengonversi asetnya jadi berkas Flutter; rujukan aset SVG-nya sudah
ada, hanya konversinya yang belum.

- [ ] **D-2.1** Sistem desain dan token: palet dari ADR-015 (`accent`,
      `income`, `expense`, `overBudget`, `transfer`, `pending`,
      `textPrimary`, `textMuted`, `background`, `cardBackground`) untuk
      mode terang dan gelap, tiga peran huruf (Space Grotesk judul/angka
      besar, Plus Jakarta Sans teks isi, Space Mono nominal/lencana), kartu
      bergaris tepi 2px dengan bayangan keras beroffset, dan bilah progres
      tersegmentasi.
      ⚠ Seluruh nilai warna dan tipografi diambil dari
      [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md)
      apa adanya. Jangan mengarang hex atau pasangan huruf baru. `overBudget`
      dan `transfer` sengaja berbagi hex dengan `expense`/`textMuted`.
      Rujukan: seluruh folder `pixel_kas_*` di
      `docs/stitch_pixel_finance_tracker/`, terutama `pixel_kas/DESIGN.md`.
      ⚠ **Bagian kode tugas ini sudah dikerjakan di T-2.12** (`TASK_LIST.md`)
      atas permintaan pemilik — `AppColorsExtension.pixelLight`/`pixelDark`,
      tiga peran huruf lewat `PixelTheme`, `AppHardCard`, dan
      `AppSegmentedProgressBar`. Yang masih tersisa dari D-2.1 murni
      kanvas VISUAL (mockup di alat desain) itu sendiri — belum dikerjakan.
      Memenuhi NFR-UX-003.
- [ ] **D-2.2** Shell navigasi: lima tujuan `Beranda | Anggaran | CATAT |
      Transaksi | Dompet` dengan CATAT di tengah, dibedakan secara visual
      dari empat tujuan lainnya.
      ⚠ CATAT bukan tujuan navigasi biasa — ia membuka lembar pilihan,
      bukan mengganti isi layar yang sedang aktif.
      Rujukan: bilah navigasi di tiap layar `pixel_kas_*`, mis.
      `pixel_kas_beranda`.
      Memenuhi FR-REC-001.
- [ ] **D-2.3** Layar CATAT beserta tiga formulirnya: catat pemasukan,
      catat pengeluaran, dan catat transfer.
      ⚠ Kosakata tombol dan pesan menyatakan pencatatan, bukan tindakan
      keuangan — "Catat Transfer", bukan "Transfer Sekarang".
      Rujukan: `pixel_kas_catat_transaksi`, `pixel_kas_catat_pemasukan`,
      `pixel_kas_catat_pengeluaran`, `pixel_kas_catat_transfer_antar_dompet`.
      Memenuhi FR-REC-001, FR-TXN-001, FR-TXN-002, FR-TXN-003, NFR-UX-001,
      dan NFR-UX-005.
- [ ] **D-2.4** Layar Transaksi: riwayat dikelompokkan per tanggal dengan
      penyaring jenis, dompet, dan kategori, dan pembedaan visual antara
      pemasukan, pengeluaran, dan transfer.
      Rujukan: `pixel_kas_daftar_transaksi`, keadaan kosongnya
      `pixel_kas_riwayat_transaksi_kosong`.
      Memenuhi FR-TXN-004.
- [ ] **D-2.5** Layar Dompet dan rincian dompet: daftar dompet aktif
      beserta total saldo, tambah dan sunting dompet, serta layar rincian
      satu dompet dengan riwayat tersaring dan pintasan ke CATAT dengan
      dompet itu sudah terpilih.
      Rujukan: `pixel_kas_daftar_dompet`, `pixel_kas_detail_dompet_bca`,
      `pixel_kas_tambah_dompet`, `pixel_kas_ubah_dompet`, keadaan kosongnya
      `pixel_kas_dompet_belum_ada_data`.
      Memenuhi FR-WAL-001, FR-WAL-002, FR-WAL-003, FR-WAL-004, dan
      FR-REC-002.

- [ ] **D-2.6** Layar rincian satu transaksi: jenis, nominal, kategori, dompet,
      tanggal, catatan, anggaran tertaut, beserta aksi sunting dan hapus.
      ⚠ Transfer memakai judul **Transfer tercatat** dan tata letak "Dari / Ke /
      Jumlah". Kosakata yang menyiratkan aplikasi menjalankan transaksi dilarang
      muncul di kanvas — termasuk dalam teks contoh.
      Rujukan: `pixel_kas_detail_transaksi_1`, `pixel_kas_detail_transaksi_2`.
      Memenuhi FR-TXN-006.

## Fase 4: Anggaran

- [ ] **D-4.1** Layar Anggaran: ringkasan lintas anggaran di puncak (total
      rencana, terpakai, sisa), lalu daftar kartu anggaran, lalu penyaring
      status dan dompet.
      ⚠ **Ini layar daftar, bukan papan satu anggaran.** Rancang untuk
      beberapa anggaran aktif sekaligus yang berbagi dompet dan berbeda
      periode.
      ⚠ Tiap kartu wajib memuat delapan hal: nama, dompet, periode, nominal
      rencana, terpakai, sisa, progres, dan status. Nama dompet harus terbaca
      tanpa membuka anggarannya.
      Rujukan: `pixel_kas_daftar_anggaran`, keadaan kosongnya
      `pixel_kas_anggaran_belum_ada_data`.
      Memenuhi FR-BUD-001, FR-BUD-004, dan FR-BUD-006.
- [ ] **D-4.2** Layar rincian satu anggaran: pos-posnya beserta status
      masing-masing (belum terpakai, terpakai sebagian, selesai, lewat
      anggaran), dan aksi kontekstual "Catat Pengeluaran" atau "Catat
      Transfer" pada tiap pos.
      ⚠ Aksi kontekstual membuka CATAT dengan field terisi, bukan formulir
      pencatatan tersendiri.
      Rujukan: `pixel_kas_detail_anggaran_rumah_tangga`.
      Memenuhi FR-BUD-003, FR-BUD-004, dan FR-REC-002.
- [ ] **D-4.3** Layar sunting anggaran dan pos anggaran, termasuk jumlah
      dan harga satuan opsional untuk pos berupa daftar belanja, serta aksi
      arsipkan dan aktifkan kembali.
      Rujukan: `pixel_kas_tambah_anggaran`.
      Memenuhi FR-BUD-001 dan FR-BUD-002.
- [ ] **D-4.4** Layar template anggaran: buat, sunting, gandakan, aktifkan,
      nonaktifkan, dan membuat anggaran baru dari template.
      ⚠ Tugas ini luput dari daftar semula — rujukan visualnya
      (`pixel_kas_template_anggaran`) sudah ada meski implementasinya di
      T-7.1–T-7.3 (Fase 7).
      Memenuhi FR-BUD-005.

## Fase 5: Freelance

- [ ] **D-5.1** Layar **Ikhtisar Freelance**: ringkasan di puncak (total jam,
      diperoleh, sudah dibayar, belum dibayar) lalu dua tab di MVP — Worklog
      sebagai tab bawaan, dan Pembayaran. Tab ketiga menyusul di D-7.2.
      ⚠ Ini **satu** layar, dan kedua titik masuk mendarat di sini: ringkasan
      Beranda, dan CATAT → Catat Pemasukan → Freelance.
      ⚠ Freelance bukan tujuan navigasi bawah, jadi layar ini tidak punya tab
      di bilah navigasi.
      Rujukan: `pixel_kas_freelance_overview_worklog`,
      `pixel_kas_freelance_pembayaran`.
      Memenuhi FR-FRL-005.
- [ ] **D-5.2** Tab Worklog beserta pengelolaan proyek: tarif per jam, aturan
      potongan, dan pencatatan entri kerja harian.
      ⚠ Layar ini tidak pernah menampilkan perubahan saldo dompet — kerja
      selesai bukan uang diterima.
      Rujukan: `pixel_kas_freelance_overview_worklog`,
      `pixel_kas_tambah_worklog`.
      Memenuhi FR-FRL-001 dan FR-FRL-002.
- [ ] **D-5.3** Tab Pembayaran: pengelompokan worklog jadi pembayaran dengan
      rincian gaji kotor, potongan, dan gaji bersih, serta pencatatan
      pembayaran diterima.
      ⚠ Kosakata pencatatan pembayaran diterima menyatakan pencatatan,
      bukan pembayaran yang dijalankan aplikasi.
      Rujukan: `pixel_kas_freelance_pembayaran`,
      `pixel_kas_catat_pembayaran_freelance`.
      Memenuhi FR-FRL-003 dan FR-FRL-004.

## Fase 6: Beranda

- [ ] **D-6.1** Layar Beranda: total saldo dan arus bulan berjalan, ringkasan
      anggaran (rencana, terpakai, sisa), ringkasan freelance, dan transaksi
      terbaru.
      ⚠ Kartu freelance memuat total jam, diperoleh, sudah dibayar, belum
      dibayar, dan tanggal pembayaran terdekat — lalu satu jalan ke Ikhtisar
      Freelance. Ia disembunyikan sepenuhnya kalau tidak ada pembayaran
      tertunda.
      ⚠ **Jangan menaruh daftar worklog di Beranda.** Beranda memuat
      ringkasan, bukan daftar kerja.
      Rujukan: `pixel_kas_beranda`.
      Memenuhi FR-HOME-001, FR-HOME-002, FR-HOME-003, dan FR-HOME-004.
- [ ] **D-6.2** Keadaan kosong Beranda dan langkah pertama: layar tanpa dompet,
      layar tanpa transaksi, dan ajakan **Catat Transaksi**.
      ⚠ Ini kanvas yang paling menentukan apakah aplikasi dipakai lagi besok,
      dan justru yang paling sering dilewati. Gambar keduanya, bukan salah satu.
      ⚠ Kartu ringkasan yang belum punya isi disembunyikan, bukan digambar
      sebagai deretan angka nol.
      Rujukan: `pixel_kas_beranda_belum_ada_data`.
      Memenuhi FR-HOME-005.

## Fase 7: Template dan poles

- [ ] **D-7.2** Tab Template pada Ikhtisar Freelance beserta layar sunting
      templatenya: tarif, potongan, dompet bawaan, jadwal pembayaran, dan
      penanda aktif atau nonaktif.
      ⚠ Bentuknya mengikuti layar template anggaran, bukan pola baru.
      ⚠ Tab ini membuat Ikhtisar Freelance punya tiga tab. Periksa ulang
      kanvas D-5.1 supaya lebarnya masih muat di layar ponsel tersempit.
      Rujukan: `pixel_kas_template_status_freelance_1`,
      `pixel_kas_template_status_freelance_2`.
      Memenuhi FR-FRL-006.
- [ ] **D-7.1** Penerapan 67 ikon SVG dari `docs/stitch_pixel_finance_tracker/
      icon_*/` ke peta `AppIcon`, menggantikan ikon Material sementara di
      seluruh layar yang sudah ada. Padanan kuncinya sudah ditetapkan di
      [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md).
      ⚠ Asetnya sudah tersedia sejak sebelum Fase 1 — bukan lagi menunggu.
      Kanvas layar tidak digambar ulang untuk perubahan ini, hanya peta
      ikonnya yang berubah.
      Memenuhi NFR-UX-002.
