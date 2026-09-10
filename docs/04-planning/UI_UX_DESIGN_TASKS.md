# Tugas desain UI/UX

Dokumen ini melacak pekerjaan desain visual Saldough, terpisah dari
[TASK_LIST.md](TASK_LIST.md) yang melacak pekerjaan kode. Keduanya memetakan
ke requirement PRD yang sama, tapi desain selesai lebih dulu — sejalan
dengan preferensi pemilik "dokumentasi dan desain lebih dulu, kode menyusul".

Setiap tugas desain diberi identitas `D-<fase>.<nomor>`, memakai nomor fase
yang sama dengan [ROADMAP.md](ROADMAP.md), supaya satu fitur mudah dilacak
dari desain sampai kode. Desain tidak punya Fase 0 (gerbang dependensi) atau
Fase 7 (sinkronisasi) sendiri — keduanya tidak punya permukaan visual baru
di MVP.

## Tautan Design Canvas

**Prototipe komik/meme terhubung — seluruh layar MVP** (D-2.1–2.4,
D-3.1–3.3, D-4.1–4.3, D-5.1–5.2, D-6.1):
[Saldough — Prototipe Komik](https://claude.ai/code/artifact/acace93a-af43-462b-a752-3dc5d8e758e3) —
2 artboard **interaktif** (gelap+terang), bukan lagi 26 layar statis
berdampingan. Satu artboard = satu aplikasi utuh: layar "Menyiapkan
Saldough!" di awal → tekan tombolnya → masuk ke shell aplikasi dengan
**bottom navigation bar nyata** (4 tab: Siklus/Pemasukan/Belanja/Investasi,
ikon+label, tab aktif disorot — meniru pola aplikasi sungguhan). Baris,
tombol, dan ikon di tiap layar bisa benar-benar ditekan dan berpindah ke
layar lain (dashboard → tap baris → sunting baris; tap ikon siklus baru →
rollover → "Kelola Template"; Pemasukan → tombol jam → Catat Jam Kerja;
Belanja → ikon kartu → Kartu Kredit → tap kartu → rincian tagihan;
Investasi → "Catat Pinjaman" → Pinjaman Antar Pos). Rencana Belanja kini
punya **tabel detail item** (kolom Item/Jumlah/Harga/Subtotal) untuk
Minggu 1 dan untuk belanja bulanan sekali, bukan cuma total agregat.
Ini adalah bahasa visual yang **aktif dipakai sekarang**, dipilih langsung
oleh pemilik (lihat "Catatan pengerjaan" untuk alasan pivotnya).

**Lembar token/komponen (D-1.1) dan Inti Siklus Bulanan, versi lama**
(gaya lama, **digantikan**):
[Saldough — Siklus Bulanan](https://claude.ai/code/artifact/0c0d80a5-90a5-4f02-b5e6-bf8fa76d07d6) —
7 artboard dengan palet "sports-tech" dari `new-health-duel` (termasuk
lembar token ADR-0006 versi lama). Disimpan sebagai arsip — **bukan acuan
visual** lagi. D-1.1 (lembar token) belum punya pengganti gaya komik;
ADR-0006 juga belum ditulis ulang untuk palet komik — lihat catatan di
bawah.

## Cara memakai dokumen ini

Aturan pencentangan sama ketatnya dengan `TASK_LIST.md`: sebuah kotak hanya
dicentang kalau artboard-nya benar-benar ada di Design Canvas yang
diterbitkan, bukan baru direncanakan.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum dimulai |
| `- [~]` | Dalam Design Canvas yang sedang dikerjakan |
| `- [x]` | Selesai, ada di Design Canvas yang sudah diterbitkan |

Setiap tugas desain wajib bisa dilacak balik ke requirement PRD. Elemen
visual yang tidak punya rujukan requirement berarti desainnya mengarang
fitur yang belum diputuskan — itu masalah, bukan kreativitas yang sah di
dokumen ini.

## Ringkasan progres

Terakhir diperbarui: 10 September 2026.

| Fase | Tugas desain | Selesai | Status |
|---|---|---|---|
| 1 — Sistem desain | 1 | 0 | Versi lama digantikan, belum ada pengganti gaya komik |
| 2 — Siklus bulanan | 4 | 4 | Selesai, gaya komik |
| 3 — Pemasukan dan timesheet | 3 | 3 | Selesai, gaya komik |
| 4 — Roll-up | 3 | 3 | Selesai, gaya komik |
| 5 — Investasi | 2 | 2 | Selesai, gaya komik |
| 6 — Seed | 1 | 1 | Selesai, gaya komik |
| **Total** | **14** | **13** | |

## Fase 1: Sistem desain

- [ ] **D-1.1** Lembar token dan komponen gaya komik: palet pop-art
      (latar kertas koran/panel hitam, garis tepi tebal, bayangan keras
      offset), pasangan huruf Archivo Black (angka)/Space Grotesk
      (body)/Bangers (label-label pendek), skala jarak dan sudut, contoh
      komponen kartu/tombol/badge. Belum digambar sebagai artboard
      tersendiri — palet dan tipografinya sudah terpakai konsisten di
      seluruh 13 layar Fase 2–6, tapi belum diringkas jadi satu lembar
      rujukan, dan belum dituliskan formal di ADR-0006 (masih berisi
      palet lama). Lihat "Catatan pengerjaan".
      Target: [ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md)
      (perlu ditulis ulang).

## Fase 2: Siklus bulanan

- [x] **D-2.1** Dashboard siklus bulanan, gaya komik: daftar baris
      pemasukan dengan total, daftar baris anggaran dengan total, sisa
      (varian positif ditunjukkan dengan data nyata September 2026; varian
      `overBudget` negatif belum digambar terpisah — lihat catatan di
      bawah), badge tetap/insidental, badge `rollUp` dengan asal angkanya,
      badge `needsReview`, plus banner ringkasan "N baris perlu ditinjau"
      (FR-TPL-002).
      Memenuhi FR-CYCLE-001.
      ⚠ Varian sisa negatif (`overBudget`) masih belum digambar sebagai
      artboard terpisah. Susulkan di ronde berikutnya kalau diperlukan
      sebelum implementasi.
- [x] **D-2.2** Tambah/sunting baris, gaya komik: bottom sheet dengan
      balon-kata komik untuk baris roll-up yang tidak bisa disunting
      langsung, toggle tetap/insidental.
      Memenuhi FR-CYCLE-002.
- [x] **D-2.3** Alur rollover, gaya komik: konfirmasi membuat bulan baru
      dari template, ringkasan "N baris perlu ditinjau", checklist
      menandai baris selesai ditinjau.
      Memenuhi FR-TPL-001, FR-TPL-002, FR-TPL-003.
- [x] **D-2.4** Kelola template, gaya komik: daftar 12 baris tetap yang
      dipakai rollover (toggle aktif/nonaktif per baris), alokasi
      investasi bawaan dengan validator total persentase.
      Memenuhi FR-TPL-004.
      ⚠ Nama dan persentase pos investasi ("Pos Darurat" dll.) bersifat
      **contoh ilustrasi** — belum dikonfirmasi sebagai nama pos asli
      pemilik.

## Fase 3: Pemasukan dan timesheet

- [x] **D-3.1** Kelola sumber pemasukan, gaya komik: Gaji Menul
      (freelance per jam, tarif Rp72.500/jam bisa diubah, potongan pajak
      2,5%) dan Gaji Koko (gaji tetap) sebagai data nyata. **Sumber
      freelance punya layar detail/flow sendiri** (buku berjalan, riwayat
      catatan jam) karena butuh pencatatan harian — beda dari sumber gaji
      tetap yang cuma perlu layar detail sederhana dengan opsi hapus.
      Memenuhi FR-INC-001, FR-INC-002, FR-INC-003.
- [x] **D-3.2** Catat jam kerja, gaya komik: satu langkah (sumber,
      tanggal, jam), toggle "mulai buku baru", pratinjau kotor langsung.
      Memenuhi FR-TIME-001, FR-TIME-002.
- [x] **D-3.3** Tutup buku jam, gaya komik: rincian kotor→potongan→bersih
      (Rp3.117.500 → −Rp77.937 → Rp3.039.563, konsisten dengan Gaji Menul
      di dashboard), riwayat buku terdahulu.
      Memenuhi FR-TIME-003, FR-TIME-004.

## Fase 4: Roll-up

- [x] **D-4.1** Rencana Belanja, gaya komik: formula roll-up
      576.600×4 minggu+762.100=Rp3.068.500 (sama dengan baris "Bulanan" di
      dashboard), **tabel detail item** (Item/Jumlah/Harga/Subtotal) untuk
      Minggu 1 (13 item) dan belanja bulanan sekali (8 item, 2 ditandai
      "harga ditimpa"), Minggu 2–4 memakai daftar template yang sama.
      Memenuhi FR-GROC-001, FR-GROC-002, FR-GROC-003.
      ⚠ Rincian per-item (nama, harga satuan) bersifat **contoh
      ilustrasi** yang disusun supaya totalnya pas dengan angka roll-up
      nyata (Rp576.600/minggu, Rp762.100 bulanan) — bukan daftar belanja
      asli dari spreadsheet pemilik, karena data per-item tidak tercatat
      di dokumen yang ada.
- [x] **D-4.2** Kartu Kredit, gaya komik: CC TOKPED (Rp1.386.516, sama
      dengan dashboard) dan CC BRI TOUCH, form catat transaksi satu
      langkah.
      Memenuhi FR-CARD-001, FR-CARD-002.
- [x] **D-4.3** Siklus Tagihan Kartu, gaya komik: total tagihan, catatan
      tanggal cetak 15 (nilai seed terkonfirmasi, bisa diubah), alur
      konfirmasi langganan berulang.
      Memenuhi FR-CARD-003, FR-CARD-004, FR-CARD-005.
      ⚠ Baris "Langganan Streaming Rp54.000" bersifat **contoh
      ilustrasi**, bukan data asli dari spreadsheet pemilik.

## Fase 5: Investasi

- [x] **D-5.1** Pos Tujuan, gaya komik: **CRUD penuh** (tambah/sunting/
      hapus pos lewat pilihan chip nama+persentase), kartu **Total
      Portofolio** yang ikut berubah, validator total 100%, saldo awal
      Rp0 (nilai seed terkonfirmasi), plus layar **Alokasi Bulan Ini**
      (FR-INV baru yang tersirat dari "alokasi dana investasi tiap
      bulan") — pilih jumlah, pecahan per pos dihitung otomatis dari
      persentase, menambah saldo sungguhan saat dikonfirmasi.
      Memenuhi FR-INV-001, FR-INV-002, FR-INV-003.
      ⚠ Nama dan persentase pos ("Pos Darurat" dll.) bersifat **contoh
      ilustrasi**, belum dikonfirmasi sebagai nama pos asli. Form
      tambah/sunting memakai chip pilihan cepat, bukan ketik bebas —
      lihat catatan fidelitas di "Catatan pengerjaan".
- [x] **D-5.2** Pinjaman Antar Pos, gaya komik: form pinjaman dari→ke pos
      yang **benar-benar memindahkan saldo** (pos asal berkurang, pos
      tujuan bertambah, total portofolio tetap), saldo negatif tampil
      merah kalau pos asal kekurangan dana, riwayat pergerakan saldo.
      Memenuhi FR-INV-004, FR-INV-005.

## Fase 6: Seed

- [x] **D-6.1** Impor Seed, gaya komik: progres pemuatan dengan checklist
      (2 sumber pemasukan, 12 baris template, pos tujuan).
      Memenuhi FR-SEED-001.

## Catatan pengerjaan

**10 September 2026** — Dokumen dibuat mencakup seluruh cakupan desain MVP,
atas permintaan pemilik. Eksekusi dimulai dari inti Siklus Bulanan
(D-1.1, D-2.1, D-2.2, D-2.3) sebagai satu Design Canvas, gelap dan terang
berdampingan, diterbitkan dan bisa disimpan (tautan di atas). Sisanya
sengaja belum dikerjakan — menunggu ronde berikutnya.

Data pada mockup memakai angka nyata siklus September 2026 dari
[MANUAL_PROCESS_ANALYSIS.md](../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
(pemasukan Rp15.839.563, anggaran Rp13.382.490, sisa Rp2.457.073, roll-up
belanja 576.600×4+762.100=3.068.500), bukan data contoh yang dikarang.
Baris "Kos agustus - september" sengaja ditandai `needsReview` di dashboard
dan muncul lagi sebagai "Kos oktober - november" yang sudah ditinjau di
alur rollover — mendramatisasi langsung nyeri utama produk (label stale
yang terbawa tiga bulan di data historis).

Mockup bersifat statis (belum interaktif/clickable) — asumsi yang diambil
karena cakupan permintaan tidak menyebutkan prototipe berfungsi. Dua
catatan untuk ronde berikutnya tercantum di D-1.1 dan D-2.1 di atas
(derivasi `muted` terang, dan varian sisa negatif yang belum digambar).

**10 September 2026 (lanjutan)** — Pemeriksaan berkas kerja sebelum
penerbitan menemukan beberapa berkas tema terang memakai warna yang
tidak cocok dengan tabel hex ADR-0006 (token `--surface`/`--card`
tertukar di `EditRowLight.dc.html` dan `RolloverLight.dc.html`; teks
badge `needsReview`/`investment` memakai hex literal yang lebih gelap
dari token aslinya di beberapa tempat, termasuk di lembar token
`TokenSheet.dc.html` sendiri). Semua sudah diperbaiki agar memakai hex
ADR-0006 apa adanya, canvas diseed ulang dan diterbitkan ulang ke
tautan yang sama (Version 2).

⚠ Catatan untuk ronde implementasi: hex `needsReview` (`#F59E0B`) dan
`investment` (`#D4A020`) di tema terang kemungkinan kontrasnya tipis
untuk teks kecil di atas kartu putih/hampir putih (ditemukan saat
pemeriksaan, belum divalidasi dengan alat kontras). Draf sebelumnya
memakai hex lebih gelap yang tidak ada di ADR-0006 sebagai perbaikan
sementara — itu dibalik ke hex asli supaya token tetap sama persis
dengan ADR-0006, tapi keputusan akhir (tambah varian teks khusus di
ADR-0006, atau terima kontrasnya) perlu keputusan pemilik saat
implementasi.

**10 September 2026 (pivot gaya visual)** — Pemilik menilai hasil gaya
"sports-tech" (ADR-0006 lama) jelek untuk aplikasi keuangan, dan secara
eksplisit meminta: (1) hanya pola teknis Flutter theming dari
`new-health-duel` yang dipakai (struktur `ThemeExtension`/`AppTheme`,
bukan warnanya), (2) riset ulang desain aplikasi keuangan dari nol. Riset
awal (tren fintech 2026: satu warna aksen kuat, nada tenang-dipercaya)
disampaikan ke pemilik, tapi pemilik memilih arah sendiri yang berbeda
dari rekomendasi riset itu: **gaya komik/meme** — garis tepi tebal, bayangan
keras offset, tipografi Archivo Black (angka)/Space Grotesk (body)/Bangers
(label pendek), warna pop-art datar. Ini dihormati sebagai keputusan rasa
pemilik untuk aplikasi pribadinya, bukan diperdebatkan lebih lanjut.

Dikerjakan bertahap sesuai permintaan pemilik sendiri: (1) satu canvas
percobaan (dashboard saja) untuk konfirmasi gaya, (2) setelah dikonfirmasi
cocok, Fase 4 langsung di gaya komik, (3) permintaan "buat semua desain
yang tersisa" memicu penyelesaian seluruh sisa cakupan MVP gaya komik
sekaligus — termasuk D-2.2 dan D-2.3 yang sebelumnya sempat terlewat dari
cakupan "tersisa" karena sudah "selesai" di gaya lama, lalu disusulkan
begitu disadari. Hasil akhir: 13 dari 14 tugas desain selesai gaya komik,
satu canvas tunggal. Satu-satunya yang belum: **D-1.1** (lembar token
formal) dan **ADR-0006** (masih berisi palet "sports-tech" lama) — palet
dan tipografi komik sudah konsisten dipakai di 13 layar, tapi belum
diringkas jadi satu lembar rujukan atau dituliskan resmi di ADR. Begitu
juga dokumen lain yang masih merujuk palet/tipografi lama
(`ARCHITECTURE_OVERVIEW.md` §10, `prd-saldough-1.0.md` §10, `TASK_LIST.md`
T-1.3, peran `new-health-duel` di `CLAUDE.md`/`AGENT_CONTEXT.md`) — belum
disentuh ronde ini karena permintaan pemilik secara spesifik soal "desain",
bukan dokumen arsitektur; ditunda sampai diminta terpisah.

Nama pos investasi ("Pos Darurat", "Pos Liburan", "Pos Belajar") dan satu
baris langganan berulang ("Langganan Streaming") di D-2.4/D-5.1/D-4.3
bersifat **contoh ilustrasi** buatan sendiri untuk menunjukkan mekanisme
UI — bukan dikutip dari spreadsheet asli pemilik, karena nama pos/pos
pinjaman yang sesungguhnya tidak tercantum di dokumen yang sudah ada.
Semua nominal lain (Rp15.839.563, Rp13.382.490, Rp3.068.500, Rp1.386.516,
Rp3.039.563/Rp3.117.500/Rp77.937, tanggal cetak 15, tarif Rp72.500/jam)
tetap data/nilai seed nyata yang sudah terkonfirmasi sebelumnya.

**10 September 2026 (prototipe terhubung)** — Pemilik meminta tiga hal:
(1) dashboard memakai bottom navigation bar nyata seperti aplikasi
sungguhan, (2) desain punya flow yang benar-benar terhubung antar layar,
(3) Rencana Belanja belum punya tabel detail item. Ketiganya ditangani
sekaligus dengan mengganti 26 artboard statis (13 layar × gelap+terang)
menjadi **2 artboard interaktif** (gelap+terang) — satu file per tema,
berisi seluruh 13 layar sebagai "view" yang disembunyikan/ditampilkan
lewat JavaScript, plus bottom nav bar 4 tab (Siklus/Pemasukan/Belanja/
Investasi) yang sebelumnya hanya pernah dijelaskan di wireframe terpisah,
sekarang benar-benar ada dan berfungsi di desainnya sendiri. Alur yang
bisa dicoba: Impor Seed → Dashboard, tap baris → Sunting Baris, ikon
siklus baru → Rollover → Kelola Template, tab Pemasukan → Catat Jam
Kerja/Tutup Buku, tab Belanja → Kartu Kredit → rincian Tagihan, tab
Investasi → Pinjaman Antar Pos.

Navigasi diverifikasi otomatis (skrip Playwright menekan tiap tombol dan
mengecek layar tujuan muncul) sebelum diterbitkan — bukan hanya dicek
visual. Tabel item Rencana Belanja: lihat catatan ⚠ di D-4.1 di atas
soal rincian per-item yang ilustratif.

Yang belum: D-1.1 dan ADR-0006 (lihat catatan pivot gaya visual di atas)
masih tertunda dengan alasan yang sama.

**10 September 2026 (lanjutan — pemisahan flow & CRUD investasi)** —
Setelah dicoba, pemilik minta tiga penyesuaian lagi:

1. **Sumber pemasukan freelance dipisah jadi flow sendiri.** Sebelumnya
   "Catat Jam Kerja" cuma tombol FAB lepas di layar Sumber Pemasukan,
   tidak terkait sumber mana. Sekarang tap baris "Gaji Menul" (freelance)
   masuk ke layar detail sendiri (buku berjalan, riwayat catatan jam,
   tombol catat jam hari ini, tombol tutup buku) — baru dari sana link ke
   Catat Jam Kerja/Tutup Buku. Tap "Gaji Koko" (gaji tetap, tidak perlu
   pencatatan harian) masuk ke layar detail sederhana dengan opsi hapus.
2. **CRUD pos investasi.** Kartu pos di Pos Tujuan sekarang bisa ditekan
   untuk sunting (ganti persentase lewat pilihan chip) atau hapus; ada
   tombol tambah pos baru (pilih nama & persentase contoh, bukan ketik
   bebas — lihat catatan fidelitas di bawah). Kartu portofolio total di
   atas ikut berubah otomatis.
3. **Flow investasi/nabung masuk**, sekaligus menutupi dua permintaan
   "detail fitur" terakhir (menampilkan portofolio, alokasi dana tiap
   bulan): layar "Alokasi Bulan Ini" — pilih jumlah (chip Rp200rb/500rb/1jt/
   semua sisa), pecahannya ke tiap pos dihitung otomatis dari persentase
   masing-masing pos saat itu (bukan angka tetap), tombol "Catat Alokasi"
   benar-benar menambah saldo tiap pos dan memperbarui Total Portofolio.
   Pinjaman Antar Pos juga diperbarui jadi sungguhan: saldo pos asal
   berkurang, pos tujuan bertambah, total portofolio tidak berubah (uang
   cuma pindah, bukan bertambah) — termasuk saldo negatif ditampilkan
   merah kalau pos asal kekurangan dana.

Semua perhitungan (pecahan alokasi, update saldo, update total) diuji
otomatis dengan skrip Playwright yang menekan tombol-tombol sungguhan dan
mengecek angka hasilnya cocok secara matematis (bukan cuma dicek visual)
di kedua tema, sebelum diterbitkan.

⚠ Catatan fidelitas: form "Tambah Pos" dan "Sunting Pos" memakai pilihan
cepat (chip nama/persentase contoh), bukan ketik teks bebas — konsisten
dengan seluruh field lain di prototipe ini yang memang bergaya tampilan,
bukan form HTML sungguhan. Ini cukup untuk menunjukkan alur CRUD-nya,
tapi implementasi Flutter nanti tetap perlu form input teks/angka yang
sesungguhnya.
