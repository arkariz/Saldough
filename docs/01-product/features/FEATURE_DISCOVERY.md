# Penemuan fitur: Catat dari notifikasi, pengingat rutin, awal bulan keuangan

**Tanggal:** 18 Oktober 2026.
**Status:** Direvisi 18 Okt 2026 sesuai arahan pemilik: onboarding wajib
(§4) dan tombol permanen (§5). KT-D1 dijawab pemilik 18 Okt 2026 (§9). Direvisi
19 Okt 2026: Catat dari notifikasi keluar dari onboarding dan jadi pintu yang
selalu ada (§5). Tinggal rupa dari designer (T-21.0). Tugasnya Fase 21 di TASK_LIST.
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

## 2. Keputusan pemilik (18–19 Okt 2026)

1. **Onboarding memuat dua langkah wajib:** pengingat rutin dan awal periode
   keuangan. Catat dari notifikasi **tidak** ada di onboarding (19 Okt 2026):
   penyetelannya (pilih aplikasi, akses notifikasi, pola pesan) terlalu berat
   untuk pengguna baru yang belum punya notifikasi bank untuk dicontoh.
2. **Tombol Nyalakan selalu muncul** untuk pengingat rutin selama fiturnya
   tidak aktif, dan untuk Catat dari notifikasi (lihat 3). Tidak bisa
   ditutup atau ditunda.
3. **Catat dari notifikasi selalu mudah ditemukan, juga sesudah menyala**
   (19 Okt 2026), karena pengguna akan sering kembali untuk menambah aplikasi
   atau pola pesan. Pintunya ada di Beranda dalam dua keadaan (Nyalakan saat
   mati, Kelola saat nyala), di kotak masuk tangkapan, dan di Akun (§5).
4. Awal periode keuangan tidak mendapat tombol permanen; pintunya tetap kepala
   periode dan Akun.

Tafsiran atas "mandatory" (KT-D1, **disetujui pemilik 18 Okt 2026**): **langkahnya
wajib dijawab, bukan fiturnya wajib menyala.** Langkah onboarding tidak punya tombol
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

## 4. Onboarding: dua langkah wajib

Urutan: slide pengantar › bahasa › mata uang › **awal periode keuangan ›
pengingat rutin** › penutup (tambah dompet).

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

**4.3 Catat dari notifikasi: bukan langkah.** Tidak ada langkah, pertanyaan,
atau izin untuk fitur ini di onboarding. Hanya satu baris informasi di
penutup, hanya Android: "Bisa catat otomatis dari notifikasi bank. Nyalakan
dari Beranda." Baris ini tidak dapat diketuk dan tidak meminta apa pun.

**4.4 Pengingat rutin.** Satu layar manfaat (kamu dapat pengingat sebelum
rutin jatuh tempo, sesuai setelan tiap rutin) dengan **Nyalakan** (meminta
izin notifikasi sistem lalu menyalakan sakelar global) dan **Tidak
sekarang**. Izin ditolak = lanjut, status "Izin belum diberikan" (§7).

**4.5 Penutup.** Penutup yang ada ("Mulai dari dompet pertamamu") tidak
berubah selain baris informasi 4.3 dan ringkasan satu baris dua pilihan tadi
(perlu rupa).

## 5. Pintu permanen: Catat dari notifikasi dan pengingat

**Aturan**
- **P-1** Tombol **Nyalakan pengingat rutin** muncul selama fitur tidak
  efektif dan hilang begitu efektif. Tidak ada tutup, tunda, ambang
  transaksi, atau jeda.
- **P-2** "Tidak efektif" = sakelar mati **atau** izin/akses sistem belum
  ada. Dalam keadaan izin hilang, tombol berubah menjadi **Izinkan** dan
  membuka setelan sistem yang relevan. Berlaku untuk kedua fitur.
- **P-3** Catat dari notifikasi hanya Android (tidak ada di iOS).
- **P-4** Tampil sebagai baris ringkas di Beranda, bukan kartu besar, dan
  tidak mendorong tawaran lain (perlu rupa).
- **P-5** Tombol tidak menyalakan apa pun sendiri kecuali pengingat, yang
  memakai alur Nyalakan Akun (meminta izin saat diketuk). Catat dari
  notifikasi selalu membuka alur setelannya.
- **P-6** Urutan di Beranda: banner pembaruan (Fase 20) › kartu Menunggu
  dicatat dan kotak masuk tangkapan › baris pintu permanen. Baris ini tidak
  pernah menggeser yang di atasnya.
- **P-7 (baru)** Baris **Catat dari notifikasi di Beranda tidak pernah
  hilang** (Android), dalam tiga keadaan:
  | Keadaan | Isi baris | Ketukan membuka |
  |---|---|---|
  | Belum pernah disetel (tidak ada aplikasi sumber) | **Nyalakan catat dari notifikasi** | Mulai cepat (§5.1) |
  | Sudah disetel, efektif | **Catat dari notifikasi**, status "{n} aplikasi aktif" | Layar setelan: aplikasi sumber, pola, dan sakelar |
  | Izin/akses hilang, atau sakelar mati | **Nyalakan** atau **Izinkan** | Setelan (sakelar) atau setelan sistem (izin) |
- **P-8 (baru)** Pintu lain yang selalu ada, agar pengguna menemukannya dari
  tempat ia sedang bekerja: (a) kotak masuk tangkapan memuat tautan
  **Kelola aplikasi & pola** di kepalanya, juga saat kosong; (b) bila ada
  tangkapan yang tidak dikenali/tidak terbaca, barisnya menawarkan
  **Ajari pola** yang membuka pembuat pola dengan teks itu sebagai contoh
  (jalur contoh sudah ada, ADR-032 §3.3); (c) layar Akun, dengan status dan
  jumlah aplikasi; (d) tur Beranda menyorot baris ini sekali.

**5.1 Mulai cepat (penyetelan pertama).** Tombol saat belum disetel membuka
layar ringan, bukan penyetelan lengkap:
1. Daftar pendek aplikasi **terpasang yang punya pola bawaan** (pemilih
   aplikasi sudah menandainya dan menampilkannya lebih dulu), sudah
   tercentang; pengguna mencentang atau menghapus. Tanpa pembuat pola.
2. Satu langkah izin akses notifikasi dan persetujuan privasi ADR-032, lewat
   alur yang sudah ada.
3. Selesai: baris Beranda berubah ke keadaan "{n} aplikasi aktif".
Aplikasi tanpa pola bawaan ada di **Aplikasi lain**, yang membuka pemilih dan
pembuat pola seperti sekarang. Bila tidak ada aplikasi bawaan terpasang,
Mulai cepat langsung menampilkan Aplikasi lain. Mulai cepat hanya muncul
sekali (saat belum ada aplikasi sumber); sesudahnya baris Beranda membuka
layar setelan penuh.

**Tempat**
| Pintu | Tempat |
|---|---|
| Catat dari notifikasi (selalu) | Beranda (baris, P-7); kotak masuk tangkapan (P-8a, P-8b); Akun (baris dengan status dan jumlah aplikasi) |
| Nyalakan pengingat rutin | Beranda (baris tombol, hilang saat efektif); segmen Rutin di Rencana; rincian rutin bila sakelar global mati (catatan satu baris di bawah sakelar per rutin, tombol **Nyalakan**) |

**Kasus tepi:** pengingat tanpa satu rutin pun tetap menampilkan tombol di
Beranda; layar nyala menjelaskan bahwa pengingat berlaku untuk rutin yang
dibuat. Akses notifikasi dicabut di sistem sesudah menyala: baris kembali
**Izinkan** (P-2). Pengguna mematikan sakelar lewat Akun: baris menjadi
**Nyalakan** (P-1/P-7), itu disengaja. Semua aplikasi sumber dihapus: baris
kembali ke keadaan belum disetel dan Mulai cepat muncul lagi.

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
"Mati" / "Izin belum diberikan". Urutan: Catat dari notifikasi (Android, dengan
jumlah aplikasi aktif), Pengingat rutin, Awal bulan keuangan. Perlu rupa dari ui-ux-designer.

**7.2 Tur spotlight (ADR-021, per langkah).** Langkah baru untuk baris
pintu Catat dari notifikasi dan tombol pengingat di Beranda (sekali, saat pertama tampil), baris status di
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
| `onboarding.notification.info` | Bisa catat otomatis dari notifikasi bank. Nyalakan dari Beranda. |
| `onboarding.reminder.title` | Ingatkan kamu sebelum jatuh tempo? |
| `onboarding.reminder.body` | Kamu dapat pengingat sebelum rutin jatuh tempo, sesuai setelan tiap rutin. |
| `onboarding.turnOn` / `onboarding.notNow` | Nyalakan / Tidak sekarang |
| `discovery.notification.button` | Nyalakan catat dari notifikasi |
| `discovery.notification.manage` | Catat dari notifikasi |
| `discovery.notification.activeApps` | {n} aplikasi aktif |
| `discovery.notification.manageSources` | Kelola aplikasi & pola |
| `discovery.notification.teachPattern` | Ajari pola |
| `discovery.quickStart.title` / `body` | Pilih aplikasi bank atau dompet digitalmu / Notifikasi dari aplikasi yang kamu pilih dibaca di perangkat dan jadi draf catatan. Kamu tinjau dulu. |
| `discovery.quickStart.other` | Aplikasi lain |
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
| `onboarding_step_answered` | `step` (`period`/`reminder`), `choice` (`turned_on`/`not_now`/`confirmed`) |
| `feature_enabled` | `feature` (`notification`/`reminder`), `via` (`onboarding`/`home_row`/`quick_start`/`account`/`rutin`) |
| `notification_row_tapped` | `state` (`unset`/`active`/`permission`/`off`), `surface` (`home`/`inbox`/`account`), `action` (`quick_start`/`manage`/`teach_pattern`) |
| `quick_start_completed` | `apps_count` (angka), tanpa nama aplikasi |
| `discovery_button_tapped` | `feature`, `surface` (`home`/`rutin_segment`/`rutin_detail`), `state` (`off`/`permission`) |
| `discovery_payday_card` | `action` (`shown`/`accepted`/`closed`) |

## 10. Ukuran keberhasilan (indikatif)

- Persentase pengguna Android yang menyelesaikan Mulai cepat dalam 14 hari
  sesudah onboarding, dan pengguna aktif yang membuka Kelola sesudahnya.
- Persentase pengguna baru yang menyalakan pengingat saat onboarding
  (`turned_on` vs `not_now`).
- Pengguna yang memilih Tidak sekarang lalu menyalakan lewat tombol
  permanen dalam 14 hari.
- Tidak ada kenaikan berhenti di langkah wajib (jumlah pengguna yang
  memulai vs menyelesaikan onboarding), diperiksa sebelum rilis publik.

## 11. Tidak dikerjakan di fase ini

- Memaksa fitur menyala atau melewati izin sistem.
- Notifikasi sistem atau email untuk mengajak menyalakan fitur.
- Gamifikasi: streak, lencana, hitungan fitur yang belum dinyalakan.
- Hub "Fitur" sebagai layar baru; status di Akun dan baris permanen cukup.
- Pembuat pola di jalur Mulai cepat, dan pola otomatis dari riwayat.
- Memaksa pengguna lama mengulang onboarding.
- Mengubah perilaku inti ketiga fitur.
