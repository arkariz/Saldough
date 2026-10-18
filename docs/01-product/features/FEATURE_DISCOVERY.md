# Penemuan fitur: Catat dari notifikasi, pengingat rutin, awal bulan keuangan

**Tanggal:** 18 Oktober 2026.
**Status:** Draf PO, menunggu jawaban KT-D1–KT-D4 (§10). Tugasnya Fase 21 di
TASK_LIST.
**Berkaitan:** [ADR-032](../../02-architecture/adr/0032-catat-dari-notifikasi.md)
(Catat dari notifikasi), [ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)
§3.8 (pengingat rutin), [ADR-038](../../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md)
(periode keuangan), [FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md),
[APP_UPDATE.md](APP_UPDATE.md) (slot banner Beranda yang sama),
ADR-021 (tur spotlight).

Dokumen ini merancang **kapan dan di mana pengguna ditawari** tiga fitur
yang sudah jadi tetapi sulit ditemukan. Tidak ada fitur baru: perilaku
ketiganya tetap seperti di dokumen masing-masing. Rupa kartu dan lembar
mengikuti komponen yang ada; yang belum ada ditandai "perlu rupa dari
ui-ux-designer".

## 1. Masalah

| Fitur | Pintu sekarang | Mengapa tersembunyi |
|---|---|---|
| Catat dari notifikasi (Android) | Akun › Pencatatan › satu baris setelan. Bawaan mati. Kartu Beranda hanya muncul **setelah** ada tangkapan yang perlu ditinjau. | Pengguna yang belum menyalakannya tidak pernah melihatnya. Onboarding dan tur tidak menyebutnya. Padahal ini pengurang kerja catat paling besar. |
| Pengingat rutin | Akun › Pencatatan › baris setelan; sakelar per rutin di rincian rutin. Bawaan mati; izin notifikasi baru diminta saat dinyalakan. | Pengguna membuat rutin lalu menunggu pengingat yang tidak pernah datang. Sakelar per rutin tidak berarti selama sakelar global mati (jebakan). |
| Awal bulan keuangan | Ketuk kepala periode di Rencana › Bulan ini (kepala itu tampak seperti label biasa), baris di Akun, dan tawaran saat membuat rutin gajian. | Pengguna yang gajian tanggal 25 hidup dengan "bulan" yang salah tanpa tahu bisa diubah. Mengubahnya kemudian membuat periode peralihan 13–46 hari; menetapkannya sejak awal tidak. |

Akar yang sama: ketiganya hanya ada sebagai **setelan pasif**, bukan
**tawaran pada saat nilainya terasa**.

## 2. Prinsip

1. **Tawarkan saat nilainya terlihat**, bukan di hari pertama. Pemicu
   mengikuti perilaku pengguna, bukan jam.
2. **Satu kartu, satu fitur, sekali tanya.** Ditutup berarti selesai;
   ditunda berarti kembali paling banyak dua kali.
3. **Tidak mengubah setelan tanpa ketukan eksplisit**, dan tidak
   menebak (tanggal gajian hanya disarankan, dikonfirmasi pengguna).
4. **Izin sistem hanya diminta lewat alur "nyalakan" yang sama dengan
   Akun**, saat pengguna menyalakan; tidak ada izin diminta di onboarding.
5. **Tanpa tekanan:** tanpa streak, tanpa hitungan hari, tanpa kata
   "ketinggalan" (sejalan KT-R13). Teks menjelaskan manfaat dan cara kerja,
   bukan penafian; kosakata tetap "mencatat, bukan melakukan".
6. **Status selalu terlihat di Akun** supaya pengguna yang menutup kartu
   tetap tahu di mana menyalakannya.

## 3. Aturan tawaran (berlaku untuk semua kartu dan lembar)

| # | Aturan |
|---|---|
| D-1 | **Satu kartu penemuan sekaligus** di Beranda, dan paling banyak satu per hari. Jeda minimal 3 hari antar kartu yang berbeda. |
| D-2 | **Urutan di Beranda:** banner pembaruan (Fase 20) › kartu Menunggu dicatat dan kotak masuk tangkapan › kartu penemuan. Kartu penemuan tidak pernah menggeser yang di atasnya. |
| D-3 | **Tidak tampil** sebelum pengguna punya minimal satu dompet dan tiga transaksi, dan tidak selama tur spotlight Beranda berjalan. |
| D-4 | **✕ (Tutup)** = tidak muncul lagi untuk fitur itu. **Nanti** = tunda 7 hari; setelah dua kali Nanti, diperlakukan sebagai Tutup. |
| D-5 | Fitur yang sudah menyala (dari mana pun jalurnya) **tidak pernah** ditawarkan. Mematikannya kembali tidak memunculkan kartu lagi. |
| D-6 | Izin sistem ditolak = kartu berhenti, status di Akun menunjukkan "Izin belum diberikan" dengan jalan ke setelan sistem. Tidak ditawari ulang. |
| D-7 | Kartu Catat dari notifikasi **hanya Android**. Di iOS tidak ada kartu, baris Akun, maupun teks onboardingnya. |
| D-8 | Semua keadaan tawaran (ditutup, ditunda, jumlah tunda, kapan terakhir tampil) disimpan di perangkat; tidak ada yang dikirim ke server selain peristiwa analitik §9. |

## 4. Catat dari notifikasi

**Pemicu kartu Beranda:** Android, fitur mati, dan pengguna sudah mencatat
manual ≥ 5 transaksi pengeluaran/pemasukan (D-3 sudah terpenuhi).
(KT-D1: angka 5.)

**Kartu:** judul "Catat otomatis dari notifikasi bank", isi satu kalimat
manfaat ("Notifikasi dari aplikasi yang kamu pilih dibaca di perangkat dan
jadi draf catatan, kamu tinjau dulu."), tombol **Atur** dan **Nanti**, ✕.
Teks akhir mengikuti salinan setelan ADR-032 yang sudah ada; PO tidak
menambah klaim privasi baru.

**Aksi Atur:** langsung membuka layar setelan Catat dari notifikasi (rute
yang sama dengan baris Akun); kartu tidak menyalakan apa pun sendiri karena
alurnya butuh memilih aplikasi, akses notifikasi, dan persetujuan privasi.

**Kasus tepi:**
- Pengguna kembali dari setelan tanpa menyalakan: dihitung Tutup? **Tidak**,
  dihitung seperti Nanti (satu tunda).
- Menyalakan lewat Akun lebih dulu: kartu tidak pernah muncul (D-5).
- Akses notifikasi dicabut di sistem sesudah menyala: itu urusan banner
  setelan yang sudah ada, bukan kartu penemuan.

## 5. Pengingat rutin

Dua tempat, karena nilainya paling terasa tepat setelah pengguna membuat
rutin.

**5.1 Lembar sesudah rutin pertama disimpan.** Sekali seumur aplikasi,
hanya bila pengingat global mati: lembar kecil "Ingatkan kamu sebelum jatuh
tempo?" dengan **Nyalakan pengingat** (meminta izin sistem di sini, lalu
menyalakan sakelar global) dan **Nanti saja**. Lembar tidak muncul untuk
rutin kedua dan seterusnya. Isi menyebut kapan pengingat datang sesuai
setelan yang ada (H-n per rutin), tanpa janji yang tidak ada di ADR-035.

**5.2 Kartu cadangan di Beranda.** Pemicu: ≥ 1 rutin aktif dan pengingat
mati, dan lembar 5.1 sudah ditolak atau terlewat (mis. rutin dibuat lewat
saran pola). Tombol **Nyalakan** menjalankan alur yang sama dengan 5.1.

**5.3 Menutup jebakan sakelar per rutin.** Bila pengguna menyalakan
pengingat di rincian satu rutin sementara sakelar global mati, tampilkan
catatan satu baris di bawah sakelar itu: "Pengingat belum menyala untuk
semua rutin" dengan tautan **Nyalakan**. Bukan kartu, tidak ikut D-1.

**Kasus tepi:** izin ditolak (D-6); rutin dihapus semua sesudah kartu muncul
(kartu hilang); pengguna menyalakan di Akun (D-5).

## 6. Awal bulan keuangan

**6.1 Tawaran gajian.** Pemicu: pemasukan berkategori **Gaji** dicatat pada
tanggal 2–28 (bukan tanggal 1), jadwal periode masih bawaan (tanggal 1),
dan tawaran belum pernah dijawab. Kartu muncul di **kepala Rencana ›
Bulan ini** dan, lewat D-1, di Beranda: "Gajian tanggal {d}? Mulai bulan
keuangan dari {d}." Tombol **Atur** membuka lembar Awal bulan keuangan
dengan {d} sudah terisi sebagai saran (pengguna mengonfirmasi atau
mengubahnya), bukan mengubah diam-diam. Aturan P-1–P-11
[FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md) berlaku tanpa perubahan,
termasuk periode peralihan dan tawaran menyelaraskan anggaran rutin.

**6.2 Pintu di kepala periode jelas dapat diketuk.** Kepala periode
Rencana mendapat isyarat dapat diketuk (mis. ikon/teks "Atur" kecil dan
bukan sekadar label). Perlu rupa dari ui-ux-designer.

**6.3 Onboarding.** Langkah opsional "Biasanya gajian tanggal berapa?"
sesudah mata uang, bawaan **Lewati (tanggal 1)** (KT-D2). Alasan PO:
menetapkannya sebelum ada data tidak membuat periode peralihan, sedangkan
mengubahnya belakangan membuatnya.

**Kasus tepi:** pengguna menolak tawaran 6.1 = tidak muncul lagi (D-4);
jadwal sudah diubah dari jalur lain (rutin gajian, Akun) = tidak muncul
(D-5); tanggal 29–31 disarankan lewat hari terakhir bulan hanya bila pengguna
memilihnya, PO tidak menebaknya.

## 7. Akun dan onboarding

**7.1 Akun › Pencatatan** mendapat **status** di tiap baris dari ketiga
fitur: "Nyala" / "Mati" / "Izin belum diberikan" (chip atau teks
sekunder), supaya pengguna yang menutup kartu bisa melihat dan menyalakan
dari sini. Urutan baris: Catat dari notifikasi (Android), Pengingat rutin,
Awal bulan keuangan. Perlu rupa dari ui-ux-designer.

**7.2 Onboarding** tidak menambah slide per fitur. Satu slide baru setelah
"Catat dalam hitungan detik": "Biar aplikasi ikut membantu" dengan tiga
baris singkat (notifikasi bank [hanya Android], pengingat tagihan, bulan
mengikuti gajian) dan **tanpa meminta izin**. Slide tidak bisa menyalakan
apa pun; kartu dan setelan yang melakukannya (KT-D3).

**7.3 Tur spotlight (ADR-021, progres per langkah).** Tambah langkah untuk
kartu penemuan pertama yang tampil di Beranda, baris status di Akun
(sekali), dan kepala periode Rencana yang kini dapat diketuk. Kunci baru
mengikuti pola `SpotlightKey` yang ada.

## 8. Teks (kunci i18n, id dan en)

Ruang nama baru `discovery.*`; teks akhir ditulis engineer dengan
persetujuan PO mengikuti glosarium `writing.md`.

| Kunci | Isi (id, draf) |
|---|---|
| `discovery.notification.title` | Catat otomatis dari notifikasi bank |
| `discovery.notification.body` | Notifikasi dari aplikasi yang kamu pilih dibaca di perangkat dan jadi draf catatan. Kamu tinjau dulu. |
| `discovery.reminder.title` | Ingatkan kamu sebelum jatuh tempo? |
| `discovery.reminder.body` | Kamu dapat pengingat sebelum rutin jatuh tempo, sesuai setelan tiap rutin. |
| `discovery.payday.title` | Gajian tanggal {d}? |
| `discovery.payday.body` | Mulai bulan keuangan dari tanggal {d}, supaya Rencana dan Analisis mengikuti gajianmu. |
| `discovery.actionSetUp` / `actionTurnOn` / `actionLater` / `actionClose` | Atur / Nyalakan / Nanti / Tutup |
| `discovery.status.on` / `off` / `permissionNeeded` | Nyala / Mati / Izin belum diberikan |
| `discovery.reminder.rowNote` | Pengingat belum menyala untuk semua rutin. |

## 9. Analitik

Mengikuti ADR-023: tanpa nominal, tanpa nama kategori buatan, tanpa isi
notifikasi.

| Peristiwa | Parameter |
|---|---|
| `discovery_shown` | `feature` (`notification`/`reminder`/`payday`), `surface` (`home`/`plan_head`/`sheet`/`onboarding`) |
| `discovery_accepted` | `feature`, `surface` |
| `discovery_snoozed` | `feature`, `count` (1–2) |
| `discovery_closed` | `feature` |
| `feature_enabled` | `feature`, `via` (`discovery`/`account`/`onboarding`) |

Ukuran keberhasilan (§11) dihitung dari peristiwa ini; tidak ada ukuran per
pengguna.

## 10. Keputusan untuk pemilik (KT-D1–KT-D4)

| # | Pertanyaan | Rekomendasi PO |
|---|---|---|
| KT-D1 | Pemicu kartu notifikasi: berapa transaksi manual sebelum ditawari? | 5 transaksi (nilai terasa, belum terlalu lambat). |
| KT-D2 | Tambah langkah opsional "tanggal gajian" di onboarding? | Ya, bawaan Lewati (tanggal 1); mencegah periode peralihan di kemudian hari. |
| KT-D3 | Tambah satu slide onboarding tentang tiga fitur ini? | Ya, satu slide, tanpa izin. |
| KT-D4 | "Nanti" menunda 7 hari, maksimal 2 kali? | Ya; sesudahnya dianggap Tutup. |

Keputusan lain yang PO ambil sendiri dan bisa dibalik: tidak ada ADR baru
untuk produk (hanya engineer bila mesin saran lintas fitur butuh, T-21.1),
kartu pembuka tidak memakai notifikasi sistem, dan tidak ada tawaran untuk
fitur lain (B-26, suara) di fase ini.

## 11. Ukuran keberhasilan (indikatif, bukan syarat rilis)

- Naiknya persentase pengguna Android aktif yang menyalakan Catat dari
  notifikasi dalam 14 hari sesudah kartu pertama.
- Pengguna dengan rutin yang menyalakan pengingat meningkat; keluhan
  "pengingat tidak datang" turun.
- Pengguna yang mengubah awal bulan keuangan dari tawaran gajian dibanding
  dari Akun.
- Tutup/Nanti tidak lebih dari separuh tampilan; bila lebih, tawaran
  dinilai terlalu dini atau terlalu sering.

## 12. Tidak dikerjakan di fase ini

- Notifikasi sistem atau email untuk mengajak menyalakan fitur.
- Gamifikasi: streak, lencana, "kamu baru menyalakan 1 dari 3 fitur".
- Hub "Fitur" sebagai layar baru; status di Akun cukup.
- Menyalakan fitur otomatis tanpa ketukan.
- Mengubah perilaku inti ketiga fitur.
