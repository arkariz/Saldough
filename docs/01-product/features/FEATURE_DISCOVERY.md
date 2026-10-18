# Penemuan fitur: Catat dari notifikasi, pengingat rutin, awal bulan keuangan

**Tanggal:** 18 Oktober 2026.
**Status:** Direvisi 18 Okt 2026 sesuai arahan pemilik: onboarding wajib
(§4) dan tombol permanen (§5). KT-D1 dijawab pemilik 18 Okt 2026 (§9). Tinggal
rupa dari designer (T-21.0). Tugasnya Fase 21 di TASK_LIST.
**Berkaitan:** [ADR-032](../../02-architecture/adr/0032-catat-dari-notifikasi.md)
(Catat dari notifikasi), [ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)
§3.8 (pengingat rutin), [ADR-038](../../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md)
(periode keuangan), [FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md),
[APP_UPDATE.md](APP_UPDATE.md) (slot banner Beranda yang sama),
ADR-021 (tur spotlight).

Dokumen ini merancang **kapan dan di mana pengguna ditawari** tiga fitur
yang sudah jadi tetapi sulit ditemukan: langkah wajib di onboarding, lalu
tombol yang selalu terlihat selama fitur belum menyala. Tidak ada fitur baru: perilaku
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

## 2. Keputusan pemilik (18 Okt 2026)

1. **Onboarding memuat tiga langkah wajib:** pengingat rutin, Catat dari
   notifikasi (Android), dan awal periode keuangan.
2. **Tombol Nyalakan selalu muncul** untuk pengingat rutin dan Catat dari
   notifikasi selama fiturnya tidak aktif. Tidak bisa ditutup atau ditunda.
3. Awal periode keuangan tidak mendapat tombol permanen (tidak diminta);
   pintunya tetap kepala periode dan Akun.

Tafsiran atas "mandatory" (KT-D1, **disetujui pemilik 18 Okt 2026**): **langkahnya
wajib dijawab, bukan fiturnya wajib menyala.** Langkah tidak punya tombol
Lewati, dan pengguna harus memilih **Nyalakan** atau **Tidak sekarang**.
Alasan: izin notifikasi dan akses membaca notifikasi adalah izin sistem yang
hanya bisa diberikan pengguna sendiri, dan memaksa menyala bertentangan
dengan persetujuan privasi ADR-032. Pengguna yang memilih Tidak sekarang
tetap diingatkan lewat tombol permanen (§5). Untuk awal periode keuangan,
"wajib" berarti wajib memilih tanggal (bawaan terpilih: tanggal 1, tetap
harus dikonfirmasi).

## 3. Prinsip

1. **Wajib dijawab, bebas dijawab apa.** Pengguna selalu boleh menolak,
   tetapi tidak bisa tidak melihat pilihannya.
2. **Tidak mengubah setelan tanpa ketukan eksplisit**; tanggal gajian
   hanya disarankan dan dikonfirmasi.
3. **Izin sistem hanya diminta saat pengguna mengetuk Nyalakan**, lewat alur
   yang sama dengan Akun, tidak pernah otomatis.
4. **Tanpa tekanan:** tanpa streak, tanpa hitungan hari, tanpa kata
   "ketinggalan". Teks menjelaskan manfaat dan cara kerja, bukan penafian;
   kosakata tetap "mencatat, bukan melakukan".
5. **Status selalu terlihat di Akun.**

## 4. Onboarding: tiga langkah wajib

Urutan: slide pengantar › bahasa › mata uang › **awal periode keuangan ›
Catat dari notifikasi (Android) › pengingat rutin** › penutup (tambah dompet).

**4.1 Aturan umum**
- Tanpa tombol Lewati dan tanpa tombol Kembali yang melewatkan; tombol
  Lanjut baru aktif setelah pengguna memilih. Kembali ke langkah
  sebelumnya tetap boleh.
- Tombol **Lewati** pada slide pengantar melompat ke langkah wajib pertama
  (bahasa), tidak keluar dari onboarding.
- Tidak berlaku saat onboarding dibuka ulang dari Akun (mode tinjau): semua
  langkah hanya menampilkan pilihan saat ini dan boleh ditutup.
- Pengguna yang sudah menyelesaikan onboarding sebelum fase ini **tidak**
  dipaksa mengulang; mereka dijangkau tombol permanen (§5) dan tawaran
  gajian (§6.2).
- Menekan tombol sistem Kembali di langkah wajib kembali ke langkah
  sebelumnya, bukan keluar.

**4.2 Awal periode keuangan** ("Biasanya gajian tanggal berapa?").
Pemilih tanggal 1–28 atau hari terakhir bulan, tanggal 1 terpilih sebagai
bawaan; tombol **Pakai tanggal {d}**. Teks pendek: Rencana dan Analisis
mengikuti tanggal ini; bisa diubah lagi di Akun. Menetapkan sebelum ada data
tidak membuat periode peralihan. Aturan P-1–P-11
[FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md) tidak berubah.

**4.3 Catat dari notifikasi (hanya Android; di iOS langkah ini tidak ada).**
Satu layar manfaat singkat (notifikasi dari aplikasi yang kamu pilih dibaca
di perangkat dan jadi draf catatan yang kamu tinjau dulu) dengan dua pilihan:
**Nyalakan** dan **Tidak sekarang**. Nyalakan membuka alur setelan yang sama
dengan Akun (pilih aplikasi, akses notifikasi sistem, persetujuan privasi
ADR-032), lalu kembali ke onboarding; pengguna yang kembali tanpa
menyelesaikannya dianggap sudah menjawab dan lanjut, fitur tetap mati dan
tombol permanen tetap muncul. Teks privasi mengikuti salinan setelan ADR-032;
PO tidak menambah klaim baru.

**4.4 Pengingat rutin.** Satu layar manfaat (kamu dapat pengingat sebelum
rutin jatuh tempo, sesuai setelan tiap rutin) dengan **Nyalakan** (meminta
izin notifikasi sistem lalu menyalakan sakelar global) dan **Tidak
sekarang**. Izin ditolak = lanjut, status "Izin belum diberikan" (§7).

**4.5 Penutup.** Penutup yang ada ("Mulai dari dompet pertamamu") tidak
berubah; boleh memuat ringkasan satu baris tiga pilihan tadi (perlu rupa).

## 5. Tombol permanen: Nyalakan catat dari notifikasi dan pengingat

**Aturan**
- **P-1** Setiap tombol muncul **selama fitur tidak efektif** dan hilang
  begitu efektif. Tidak ada tutup, tunda, ambang transaksi, atau jeda.
- **P-2** "Tidak efektif" = sakelar mati **atau** izin/akses sistem belum
  ada. Dalam keadaan izin hilang, tombol berubah menjadi **Izinkan** dan
  membuka setelan sistem yang relevan.
- **P-3** Catat dari notifikasi hanya Android (tidak ada di iOS).
- **P-4** Tombol tidak mendorong tawaran lain dan tidak tampil sebagai
  kartu besar: baris tombol ringkas di Beranda (perlu rupa).
- **P-5** Tombol tidak menyalakan apa pun sendiri kecuali pengingat, yang
  memakai alur Nyalakan Akun (meminta izin saat diketuk). Catat dari
  notifikasi selalu membuka alur setelannya.
- **P-6** Urutan di Beranda: banner pembaruan (Fase 20) › kartu Menunggu
  dicatat dan kotak masuk tangkapan › baris tombol permanen. Baris ini tidak
  pernah menggeser yang di atasnya.

**Tempat**
| Tombol | Tempat |
|---|---|
| Nyalakan catat dari notifikasi | Beranda (baris tombol); Akun (baris dengan status, sudah ada) |
| Nyalakan pengingat rutin | Beranda (baris tombol); segmen Rutin di Rencana; rincian rutin bila sakelar global mati (catatan satu baris di bawah sakelar per rutin, tombol **Nyalakan**) |

**Kasus tepi:** pengingat tanpa satu rutin pun tetap menampilkan tombol di
Beranda; layar nyala menjelaskan bahwa pengingat berlaku untuk rutin yang
dibuat. Akses notifikasi dicabut di sistem sesudah menyala: tombol kembali
muncul sebagai **Izinkan** (P-2). Pengguna mematikan lewat Akun: tombol
kembali (P-1), itu disengaja.

## 6. Awal bulan keuangan

**6.1 Pintu.** Kepala periode Rencana jelas dapat diketuk (ikon atau teks
"Atur" kecil, bukan sekadar label). Perlu rupa dari ui-ux-designer.

**6.2 Tawaran gajian untuk pengguna lama.** Pemasukan berkategori **Gaji**
dicatat pada tanggal 2–28, jadwal masih bawaan, dan tawaran belum dijawab:
kartu di kepala Rencana › Bulan ini ("Gajian tanggal {d}? Mulai bulan
keuangan dari {d}."). **Atur** membuka lembar Awal bulan keuangan dengan
{d} terisi sebagai saran. Kartu ini boleh ditutup dan tidak muncul lagi
(satu-satunya tawaran yang bisa ditutup di fase ini). Pengguna baru sudah
memilih tanggal di onboarding, jadi tidak melihatnya.

## 7. Akun dan tur

**7.1 Akun › Pencatatan** menampilkan status di tiga baris: "Nyala" /
"Mati" / "Izin belum diberikan". Urutan: Catat dari notifikasi (Android),
Pengingat rutin, Awal bulan keuangan. Perlu rupa dari ui-ux-designer.

**7.2 Tur spotlight (ADR-021, per langkah).** Langkah baru untuk baris
tombol permanen di Beranda (sekali, saat pertama tampil), baris status di
Akun, dan kepala periode Rencana yang kini dapat diketuk. Kunci baru
mengikuti pola `SpotlightKey`.

## 8. Teks (kunci i18n, id dan en)

Ruang nama `discovery.*` dan `onboarding.*`; teks akhir ditulis engineer
dengan persetujuan PO mengikuti glosarium `writing.md`.

| Kunci | Isi (id, draf) |
|---|---|
| `onboarding.period.title` | Biasanya gajian tanggal berapa? |
| `onboarding.period.body` | Rencana dan Analisis mengikuti tanggal ini. Bisa diubah lagi di Akun. |
| `onboarding.period.confirm` | Pakai tanggal {d} |
| `onboarding.notification.title` | Catat otomatis dari notifikasi bank |
| `onboarding.notification.body` | Notifikasi dari aplikasi yang kamu pilih dibaca di perangkat dan jadi draf catatan. Kamu tinjau dulu. |
| `onboarding.reminder.title` | Ingatkan kamu sebelum jatuh tempo? |
| `onboarding.reminder.body` | Kamu dapat pengingat sebelum rutin jatuh tempo, sesuai setelan tiap rutin. |
| `onboarding.turnOn` / `onboarding.notNow` | Nyalakan / Tidak sekarang |
| `discovery.notification.button` | Nyalakan catat dari notifikasi |
| `discovery.reminder.button` | Nyalakan pengingat rutin |
| `discovery.allowAccess` | Izinkan |
| `discovery.reminder.rowNote` | Pengingat belum menyala untuk semua rutin. |
| `discovery.payday.title` / `body` | Gajian tanggal {d}? / Mulai bulan keuangan dari tanggal {d}, supaya Rencana dan Analisis mengikuti gajianmu. |
| `discovery.status.on` / `off` / `permissionNeeded` | Nyala / Mati / Izin belum diberikan |

## 9. Keputusan dan analitik

**KT-D1** (diputuskan pemilik 18 Okt 2026): "wajib" berarti **wajib dijawab**
(Nyalakan atau Tidak sekarang), bukan wajib menyala. Tidak ada keputusan
terbuka yang tersisa untuk fase ini.

**Analitik** (ADR-023, tanpa nominal, nama kategori buatan, atau isi
notifikasi):
| Peristiwa | Parameter |
|---|---|
| `onboarding_step_answered` | `step` (`period`/`notification`/`reminder`), `choice` (`turned_on`/`not_now`/`confirmed`) |
| `feature_enabled` | `feature` (`notification`/`reminder`), `via` (`onboarding`/`home_button`/`account`/`rutin`) |
| `discovery_button_tapped` | `feature`, `surface` (`home`/`rutin_segment`/`rutin_detail`), `state` (`off`/`permission`) |
| `discovery_payday_card` | `action` (`shown`/`accepted`/`closed`) |

## 10. Ukuran keberhasilan (indikatif)

- Persentase pengguna baru Android yang menyalakan Catat dari notifikasi
  dan pengingat saat onboarding (`turned_on` vs `not_now`).
- Pengguna yang memilih Tidak sekarang lalu menyalakan lewat tombol
  permanen dalam 14 hari.
- Tidak ada kenaikan berhenti di langkah wajib (jumlah pengguna yang
  memulai vs menyelesaikan onboarding), diperiksa sebelum rilis publik.

## 11. Tidak dikerjakan di fase ini

- Memaksa fitur menyala atau melewati izin sistem.
- Notifikasi sistem atau email untuk mengajak menyalakan fitur.
- Gamifikasi: streak, lencana, hitungan fitur yang belum dinyalakan.
- Hub "Fitur" sebagai layar baru; status di Akun dan tombol permanen cukup.
- Memaksa pengguna lama mengulang onboarding.
- Mengubah perilaku inti ketiga fitur.
