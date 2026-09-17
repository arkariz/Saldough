# Strategi pivot ke Saldough 2.0

## 1. Metadata

- **Decision ID:** ADR-014
- **Tanggal:** 2026-09-17
- **Fase roadmap:** Fase 0
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

[ADR-011](0011-model-domain-dompet-transaksi-anggaran.md) mengganti model domain
Saldough sepenuhnya. Pertanyaan yang tersisa bersifat mekanis, tetapi jawabannya
menentukan berapa lama pivot ini memakan waktu dan berapa besar risikonya: **di
mana dan dengan urutan apa penggantian itu dikerjakan.**

Keadaan kode saat keputusan ini diambil:

- 13.777 baris Dart di `lib/` tersebar di 192 berkas, dengan 31 berkas uji dan
  169 uji yang lulus.
- Enam fitur saling mengunci lewat `cycle`. Keenam port lintas fitur —
  `RollUpResolver`, `CardCatalog`, `GroceryCycleGateway`, `CycleIncomeWriter`,
  `CycleInvestmentGateway`, `IncomeWorklogGateway` — semuanya bermuara ke sana,
  dan implementasinya menyentuh tipe milik `cycle`. Akibatnya `cycle` tidak bisa
  dihapus sendirian: begitu ia hilang, keenam adapter ikut pecah, bersama
  `RootModule` dan `MainShellPage`.
- Sekitar 1.900 baris di `lib/core` beserta tema, komponen UI, pemformat uang,
  DI, dan navigasi bersifat netral produk dan bisa dipakai ulang apa adanya.
- Sekitar 9.000 baris di `cycle`, `card`, `investment`, `grocery`, dan `income`
  akan dihapus, bersama sekitar 2.900 baris ujinya.

Satu batasan datang dari pemilik dan tidak boleh diabaikan: **biaya token dan
batas laju pemakaian agen adalah pertimbangan nyata dalam proyek ini.** Pemilik
menanyakannya secara eksplisit sebelum pekerjaan dimulai. Itu mengubah
pertanyaan dari "mana yang paling rapi secara rekayasa" jadi "mana yang paling
rapi dengan biaya pengerjaan paling rendah".

Yang menentukan biaya itu bukan jumlah baris yang berubah, melainkan dua hal:
berapa banyak berkas yang harus dibaca ke dalam konteks, dan berapa ronde
verifikasi gagal yang harus dibayar. Kode yang tidak pernah dibuka biayanya nol;
`flutter analyze` yang merah memuntahkan galat berantai yang harus dibaca dan
diperbaiki.

## 3. Keputusan

Saldough 2.0 dibangun **di repositori yang sama**, sebagai **folder fitur baru
di samping yang lama**, dan peralihannya terjadi dalam **satu kali cutover** di
Fase 3. Kode lama dipulihkan lewat **riwayat git**, bukan lewat folder
`legacy/`.

Yang mengikat:

### Fitur baru tidak menyentuh fitur lama

Fitur `wallet`, `transaction`, `budget`, `record`, `freelance`, dan `home`
ditulis sebagai folder baru. Tidak satu pun namanya bentrok dengan fitur lama.
`RootModule` hanya **ditambahi** pendaftaran baru, tidak diubah. Shell lama
dibiarkan utuh, dan shell baru dicapai lewat rute tersendiri selama
pengembangan.

Konsekuensinya menjadi invarian yang diuji tiap PR: **`flutter analyze` dan
`flutter test` tetap hijau di setiap titik, dan seluruh uji lama tetap lulus
tanpa disentuh.** Di Fase 1 dan 2, `git diff --stat` tidak boleh menyebut satu
pun berkas di `lib/features/{cycle,card,investment,grocery,income}`.

### Cutover sekali, di Fase 3

Setelah dompet dan transaksi bisa dipakai dari ujung ke ujung, satu commit
menghapus `cycle`, `card`, `investment`, `grocery`, `income`, dan `shared/goal`,
menukar shell, lalu membersihkan i18n, DI, dan registri rute. Penghapusannya
`git rm`, yang tidak memerlukan pembacaan berkas sama sekali.

### Pemulihan lewat riwayat git, bukan folder

Keadaan repositori sebelum pivot adalah commit `13c7939`, yang selamanya jadi
leluhur `main`. Tidak ada folder `lib/legacy/`.

> **Catatan (17 September 2026):** Tag `pre-pivot-1.0` dibuat menunjuk commit
> itu, tetapi gagal di-push dari lingkungan agen — relay gitnya hanya
> mengizinkan pembaruan `refs/heads/*`. Pemilik mem-push tagnya sendiri dari
> mesinnya, dan tag sudah terkonfirmasi ada di remote menunjuk `13c7939`. Lihat
> [indeks arsip](../../99-archive/README.md).

### Satu branch dan satu PR per fase

Supaya tiap ronde review tetap kecil dan bisa ditinjau utuh.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Repositori sibling baru, kode yang bisa dipakai ulang dipindahkan
  satu per satu**
- **Opsi B — Repositori sama, bongkar fitur lama lebih dulu lalu bangun yang
  baru**
- **Opsi C — Repositori sama, bangun berdampingan lalu cutover sekali
  (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Repositori sibling baru

Membuat proyek Flutter baru, menyalin infrastruktur yang bisa dipakai ulang,
lalu membangun produk baru di atasnya. Daya tariknya nyata: `docs/` dan
`.claude/` mulai bersih, tanpa satu pun jejak produk yang mati.

Biaya pemindahannya sendiri sebetulnya rendah — menyalin berkas bisa dilakukan
lewat perintah shell tanpa membacanya ke dalam konteks. Yang mahal adalah apa
yang mengikutinya. Proyek baru harus menyusun ulang scaffolding: `pubspec.yaml`,
`analysis_options.yaml`, folder Android dan iOS, `build.yaml`, bootstrap DI, dan
`main.dart`. Lalu `flutter pub get` harus menyelesaikan ulang delapan git
dependency yang dipin ke SHA mentah — dipin begitu justru karena commit tag di
hulu merujuk URL GitLab privat yang tidak bisa diakses. Kalau resolusi itu
gagal, ia jadi lubang penelusuran yang dalam dan mahal.

Frasa "satu per satu" di dalam opsi ini justru bagian termahalnya: memindahkan
sepotong demi sepotong berarti mengulang siklus salin, `analyze`, impor hilang,
perbaiki, `analyze` — dan ronde verifikasi gagal itulah penyedot biaya
sesungguhnya.

Satu keunggulannya tetap nyata dan diakui: `.claude/CLAUDE.md` dan
`AGENT_CONTEXT.md` disuntikkan ke konteks **tiap sesi, selamanya**. Isi yang
basi bukan cuma memboroskan, tapi menyesatkan. Namun itu bisa ditebus sekali
bayar dengan menulis ulang kedua berkas di Fase 0, dan setelah itu pajaknya
hilang — jauh lebih murah daripada membangun ulang seluruh proyek.

### Opsi B — Bongkar dulu, baru bangun

Menghapus `cycle`, `card`, `investment`, dan `grocery` lebih dulu, lalu
membangun model baru di atas repositori yang sudah bersih. Ini urutan yang
tampak paling jujur: tidak ada dua dunia yang hidup berdampingan, dan tidak ada
godaan mempertahankan kode lama.

Masalahnya persis pada apa yang membuat pembongkaran itu mungkin. Karena keenam
port bermuara ke `cycle`, menghapusnya meninggalkan ratusan galat berantai di
`root_module.dart`, `main_shell_page.dart`, `app_route_registry.dart`, dan
seluruh adapter. Galat itu harus dibaca dan diperbaiki **sebelum** satu baris
fitur baru sempat ditulis, dan selama itu aplikasi tidak bisa dikompilasi sama
sekali.

Opsi ini juga melanggar prinsip "selalu bisa dijalankan" yang dipegang roadmap
1.0, tanpa imbalan apa pun: hasil akhirnya identik dengan Opsi C, hanya dengan
biaya verifikasi yang dibayar di depan.

### Opsi C — Bangun berdampingan lalu cutover sekali (Dipilih)

Karena arah kunci antar fitur satu arah — semuanya mengarah ke `cycle`, dan
tidak ada yang mengarah keluar darinya — fitur baru bisa tumbuh di sampingnya
tanpa bersentuhan sama sekali. Ini pola strangler, dan di sini ia menang karena
alasan struktural, bukan karena selera.

Keuntungan terbesarnya: **tidak pernah ada keadaan rusak.** `analyze` dan `test`
hijau di setiap commit, sehingga tidak ada ronde galat berantai yang dibayar.
Penghapusan di Fase 3 adalah `git rm`, yang gratis dalam pengertian mana pun.
Kode yang dipertahankan — `lib/core`, tema, komponen, pemformat uang — tidak
pernah dibuka sekali pun, jadi biayanya nol.

Kelemahannya nyata. Selama Fase 1 dan 2, repositori memuat dua dunia sekaligus:
aplikasi membawa kode yang tidak akan dipakai, `flutter test` menjalankan uji
untuk fitur yang akan dihapus, dan pembacaan kode jadi lebih membingungkan
karena ada dua jawaban untuk "di mana transaksi dicatat". Ada juga godaan
nyata untuk membiarkan sebagian fitur lama hidup "sementara" — yang dijawab
dengan menjadikan cutover sebagai fase tersendiri yang punya kriteria selesai,
bukan pekerjaan sisa yang menempel di fase lain.

Soal folder `legacy/` versus tag: folder mati tetap wajib lolos `analyze` dan
`test` selamanya, dan itu pajak permanen untuk kode yang kemungkinan besar tidak
pernah kembali. Tag memberi pemulihan yang sama persis dengan biaya nol.
Kelemahannya, kode di balik tag tidak terlihat saat menelusuri repositori, jadi
keberadaannya harus disebut eksplisit — yang dikerjakan oleh
[indeks arsip](../../99-archive/README.md).

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Infrastruktur yang dipakai ulang tidak perlu disentuh, dipindahkan, atau
  diverifikasi ulang.
- Setiap commit bisa dijalankan dan diuji, jadi kesalahan ketahuan di ronde
  tempat ia dibuat.
- Penghapusan besar di Fase 3 jadi satu commit yang bisa ditinjau utuh.
- Riwayat git tetap menyatu, sehingga alasan sebuah pola bisa ditelusuri
  melintasi pivot.

### Yang menjadi lebih sulit

- Selama dua fase, repositori memuat dua model domain sekaligus.
- Uji lama tetap berjalan dan memakan waktu meski fiturnya akan dihapus.
- Jumlah uji akan **turun tajam** setelah Fase 3, karena sekitar 2.900 baris uji
  hilang bersama fiturnya. Angka "169 uji lulus" tidak boleh dijadikan patokan
  setelah cutover; baseline baru dicatat apa adanya.

### Risiko yang diterima

- **Cutover ditunda terus-menerus.** Dijawab dengan menjadikannya fase
  tersendiri berkriteria selesai.
- **Fitur baru tanpa sengaja menyentuh fitur lama.** Dijawab dengan pemeriksaan
  `git diff --stat` tiap PR di Fase 1 dan 2.
- **Kode 1.0 jadi tidak terlihat setelah dihapus.** Dijawab dengan tag beserta
  indeks arsip yang menyebut cara memulihkannya.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Commit terakhir sebelum penghapusan apa pun dicatat sebagai jalur pemulihan,
  dan SHA-nya disebut eksplisit di indeks arsip.
- Di Fase 1 dan 2, `RootModule` hanya ditambahi. Tidak ada baris lama yang
  diubah atau dihapus.
- Fitur baru tidak mengimpor apa pun dari `lib/features/{cycle,card,investment,
  grocery,income}` maupun `lib/shared/goal`.
- `CalculateNetPay`, `DeductionRule`, dan `NetPayBreakdown` dipindahkan dari
  `lib/shared/income/` ke `lib/features/freelance/domain/` di Fase 5. Setelah
  pivot hanya ada satu konsumen, sehingga ambang "2+ konsumen"
  [ADR-0009](0009-core-shared-features-zone-layout.md) tidak lagi terpenuhi dan
  promosinya ke `shared/` kehilangan dasar.
- Uji lama tidak disunting sampai Fase 3. Kalau sebuah uji lama gagal, itu bukti
  fitur baru menyentuh sesuatu yang seharusnya tidak.

### Antipola yang harus dihindari

- Membuat `lib/legacy/` atau folder sejenis.
- Mengubah fitur lama supaya "sejalan" dengan model baru. Ia akan dihapus.
- Menghapus fitur lama sepotong-sepotong di luar Fase 3.
- Mengejar jumlah uji lama setelah cutover dengan menulis uji yang tidak
  bermakna.

## 8. Kriteria peninjauan ulang

- Fase 2 selesai tetapi aplikasi baru ternyata belum cukup untuk dipakai
  sehari-hari. Cutover ditunda sampai layak, dan alasannya dicatat.
- Ditemukan fitur lama yang ternyata masih dibutuhkan apa adanya. Ia dipindahkan
  ke dunia baru sebagai pekerjaan tersendiri, bukan dibiarkan hidup di tempat
  lamanya.
- Invarian `git diff --stat` dilanggar lebih dari sekali. Itu tanda pemisahan
  antara dua dunia tidak sebersih yang diasumsikan.

## 9. Artefak terkait

### Dokumentasi

- [ADR-011](0011-model-domain-dompet-transaksi-anggaran.md) — model domain yang
  menggantikan model lama.
- [ADR-0009](0009-core-shared-features-zone-layout.md) — aturan zona yang tetap
  berlaku, termasuk ambang promosi ke `shared/`.
- [ROADMAP.md](../../04-planning/ROADMAP.md) — urutan fase beserta alasannya.
- [TASK_LIST.md](../../04-planning/TASK_LIST.md) — pemecahan tiap fase jadi
  tugas.
- [Indeks arsip](../../99-archive/README.md) — cara memulihkan kode 1.0.

### Rujukan kode

- Commit `13c7939` — keadaan repositori sebelum pivot.
- `lib/core/di/src/root_module.dart` — satu-satunya berkas yang melihat lebih
  dari satu fitur.
- `lib/core/presentation/shell/main_shell_page.dart` — shell yang ditukar saat
  cutover.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-17
**Status implementasi:** Fase 0 sedang dikerjakan
