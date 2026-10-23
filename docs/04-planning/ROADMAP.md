# Roadmap

Dokumen ini menjelaskan urutan pengerjaan Saldough 2.0 dan alasan di balik
urutannya. Untuk daftar tugas yang bisa langsung dikerjakan beserta
progresnya, lihat [TASK_LIST.md](TASK_LIST.md). Untuk pekerjaan desain
visual yang menurunkan fase-fase ini jadi layar, lihat
[UI_UX_DESIGN_TASKS.md](done/UI_UX_DESIGN_TASKS.md).

## Prinsip penyusunan fase

Empat aturan menentukan urutan di bawah ini.

**Aplikasi selalu bisa dijalankan.** `flutter analyze` dan `flutter test`
harus hijau di tiap commit. Tidak ada fase yang meninggalkan repositori
dalam keadaan rusak menunggu fase berikutnya, dan itu berlaku juga selama
dua model domain hidup berdampingan di Fase 1 dan 2.

**Fitur baru tumbuh di samping yang lama, cutover terjadi sekali.** Saldough
2.0 ditulis sebagai folder fitur baru di sebelah `cycle`, `card`,
`investment`, `grocery`, dan `income`, bukan menggantikannya sepotong demi
sepotong. Kode lama dihapus dalam satu commit di Fase 3, bukan dicicil.
Alasan lengkap strategi ini ada di
[ADR-014](../02-architecture/adr/0014-strategi-pivot-saldough-2.md).

**Urutan mengikuti loop inti produk.** Saldough 2.0 menjawab tiga pertanyaan
berurutan: di mana uang berada, apa yang terjadi padanya, dan ke mana ia
direncanakan pergi. Karena itu tempat uang — dompet — dikerjakan lebih
dulu, disusul peristiwa — transaksi lewat CATAT — dan baru rencana —
anggaran. Freelance menyusul sebagai domain pendukung yang memasok
pemasukan ke buku besar yang sama.

**Beranda dikerjakan terakhir.** Beranda hanya meringkas apa yang sudah ada
di dompet, transaksi, anggaran, dan freelance. Membangunnya lebih awal
berarti membangun ringkasan untuk data yang belum ada.

## Ringkasan fase

| Fase | Nama | Hasil |
|---|---|---|
| 0 | Dokumen Saldough 2.0 | Seluruh keputusan produk dan arsitektur tertulis |
| 1 | Domain inti dompet dan transaksi | Buku besar tercatat dan teruji, tanpa UI |
| 2 | Layar inti CATAT/Transaksi/Dompet | Aplikasi baru bisa dipakai sehari-hari |
| 3 | Cutover | Satu model domain tersisa di repositori |
| 4 | Anggaran | Rencana belanja bisa dibuat dan dipantau |
| 5 | Freelance | Penghasilan lepas tercatat sampai diterima |
| 6 | Beranda | Ringkasan keadaan keuangan dalam satu layar |
| 7 | Template dan poles | Anggaran berulang cepat dibuat, ikon final terpasang |
| 8 | Tindak lanjut pasca-MVP | Anggaran hanya membaca bulannya, pencarian lintas bulan, ganti nama Tanukonomy, akun opsional, Analytics/Crashlytics, satu mata uang per aplikasi, persiapan rilis |
| 9 | Onboarding, info, dan tur spotlight | Pengguna baru paham aplikasinya sebelum mencatat, tiap layar dijelaskan sekali di tempatnya |
| 10 | (dicadangkan: sinkronisasi, B-7) | — |
| 11 | Catat Cerdas: kategori dan suara | Transaksi berkategori tertutup; satu ucapan mengisi formulir CATAT |
| 12 | Rapikan batas arsitektur | Fitur hanya saling kenal lewat kunci rute; uji batas impor menjaga |
| 13 | Pecah fitur `record` | CATAT, suara, dan notifikasi fitur terpisah; mesin tafsir di `shared/capture` |
| 14 | Bahasa visual baru | "Buku catatan dengan aksen piksel": token, komponen, navigasi 4 tab + Catat, semua layar |
| 15 | Rencana dan rutin (R1) | Rutin tercatat satu ketuk atau tercocok sendiri; uang nganggur dan perkiraan bulan ini terlihat di tab Rencana |
| 16 | Rencana R2 | Anggaran rutin lahir sendiri, perkiraan bulan ke depan, siapkan dana, tinjau awal bulan |
| 17 | Rencana R3 | Rutin tercatat otomatis (nominal tetap), deteksi "belum terlihat", saran rutin |
| 18 | Periode keuangan | Awal bulan mengikuti gajian, periode peralihan, anggaran rutin ikut pindah (selesai 15 Okt 2026) |
| 19 | Analisis keuangan R1 | Ke mana uang pergi per kategori, dibanding biasanya, tren enam periode (selesai 18 Okt 2026) |
| 20 | Pengumuman pembaruan | Versi baru Play Store dan pembaruan kecil Shorebird diumumkan, catatan Apa yang baru (selesai 15 Okt 2026) |
| 21 | Penemuan fitur | Catat dari notifikasi, pengingat rutin, dan awal bulan keuangan dijadikan langkah wajib onboarding dan tombol permanen (draf 18 Okt 2026, KT-D1 diputuskan, menunggu rupa) |
| 22 | Ekspor dan cadangan manual | Ekspor transaksi ke xlsx/CSV, cadangkan dan pulihkan manual ke berkas, gratis tanpa akun (dari B-42, selesai 23 Okt 2026) |

Fase 0 sampai 6 membentuk MVP. Fase 7 dikerjakan setelahnya. Fase 8 dan 9
lahir dari pemakaian nyata dan persiapan rilis, bukan dari rencana awal.

**Status per 18 Oktober 2026:** semua fase di tabel sudah selesai kodenya
(kecuali sisa kecil di Fase 8, 11, dan 15 yang tercatat di
[TASK_LIST.md](TASK_LIST.md)). Arah berikutnya ada di
[Now / Next / Later](#now--next--later) di bawah.

## Now / Next / Later

Arah ke depan, diambil dari antrean `B-n` dan tugas terbuka di
[TASK_LIST.md](TASK_LIST.md). Ini peta prioritas, bukan jadwal: tidak ada
tanggal, dan pemilik yang menentukan kapan sebuah butir naik kolom. Butir
yang naik ke **Now** dijadwalkan sebagai fase dengan tugas `T-n.n` mengikuti
"Menambah tugas baru" di TASK_LIST. Diperbarui 18 Okt 2026.

Tujuan produk yang dipakai menilai (PRD §3): pengguna **kembali mencatat
secara rutin**, angka selalu tepat, dan inti aplikasi tetap jalan tanpa akun
dan tanpa koneksi.

### Now: menuju rilis publik

Closed testing sudah berjalan. Yang menghalangi rilis publik, bukan fitur
baru:

| Butir | Isi | Siapa |
|---|---|---|
| T-11.8 | Pindah Firebase ke tier berbayar (Blaze) sebelum rilis publik | pemilik |
| T-11.6, T-11.21, B-20 | Formulir Keamanan Data dan kebijakan privasi untuk catat dari notifikasi dan suara | agen + pemilik |
| B-4 | Selaraskan klaim situs `tanukonomy-web` dengan aplikasi (akun opsional, analitik, mata uang) | agen |
| B-1 | Sapuan nama "Saldough" → "Tanukonomy" di dokumen | agen |
| B-5, B-35, B-40 | Verifikasi perangkat yang tertunda: Akun, mata uang, Freelance, suara, lebar 360dp, keadaan kosong Analisis | pemilik |
| Audit TASK_LIST | Kotak lama yang kemungkinan sudah selesai di kode tapi belum dicentang (T-11.17–11.20, T-15.9, T-15.14, T-15.19, dan B-13/B-14 yang usang) | agen |
| B-43 | Kunci aplikasi sidik jari/PIN (gratis); prasyarat Plus. Pasangannya, ekspor dan cadangan/pulihkan manual (Fase 22, dari B-42), **selesai 23 Okt 2026**; sisa uji perangkatnya di B-67 | agen, pemilik (B-67) |

**Satu fitur yang ikut di Now:** **B-26**, kartu lembut "Ada yang belum dicatat
sejak …?" (tanpa streak, KT-R13). Paling langsung menjawab ukuran keberhasilan
"kembali mencatat", kecil, dan tidak menambah data keluar perangkat.

### Next: sesudah rilis publik stabil

| Butir | Isi | Syarat naik ke Now |
|---|---|---|
| B-25 | Peringatan nominal tidak wajar di seluruh CATAT (KT-R12): cegah salah ketik uang | Sesudah B-26; desain sudah ada (RECURRING_AND_FORECAST §7A E5) |
| B-38 | Analisis R2: tampilan tahun, tren total saldo (`Wallet.createdAt`, ADR baru), porsi rutin, Di luar rencana | Data pemakaian Analisis R1 menunjukkan layar dipakai (`analysis_viewed`) |
| B-32 | Rutin lewat suara dan kartu menunggu gabungan (KT-R7) | Rupa dari designer |
| B-12 | Ikon peluncur dan splash iOS | Pemilik menyerahkan artwork, dan keputusan merilis iOS |
| B-39 | Pengumuman pembaruan R2: pembaruan wajib untuk perbaikan kritis, iOS | Butuh KT-U1 dan iOS |
| B-29 | Penyamaran notifikasi Android 15 | Uji di perangkat Android 15 dengan notifikasi bank nyata |
| B-41 + B-44 | Fondasi Plus (billing, hak, paywall, gerbang fitur lama) dan **Penjaga + Ringkasan Senin**, Plus hanya untuk penguji | ADR monetisasi (semua KT-P diputuskan 18 Okt 2026) |
| B-45, B-46, B-41 | Catat dari foto, Bagaimana kalau, reverse trial: **Plus mulai dijual** | B-44 selesai; Blaze (T-11.8) dan Keamanan Data untuk B-45 |

### Later: butuh keputusan atau bukti dulu

| Butir | Isi | Kenapa menunggu |
|---|---|---|
| B-7 | Sinkronisasi data keuangan ke server | Proyek paling besar; butuh keputusan produk, ADR, dan jawaban KT-2; wajib mematuhi ADR-024 §3.3 |
| B-15 | Gemma lokal untuk Catat lewat Suara | Ditunda 30 Sep 2026; pemilik menentukan kapan |
| B-28 | Sisa R3 otomasi (kenaikan harga dari notifikasi, rutin menganggur) | Tunggu pemakaian R3 nyata |
| B-30 | Horizon perkiraan sampai 12 bulan (KT-R8) | R2 memakai +2 tetap; tunggu kebutuhan nyata |
| B-11, B-21 | Indeks pencarian riwayat panjang; satu sinyal per putaran notifikasi | Tunggu keluhan atau data nyata, jangan dikerjakan spekulatif |
| B-16, B-19 | Temuan kecil verifikasi M1; `dismissKeyboardOnTapOutside` di formulir lain | Poles; kerjakan bersama tugas yang menyentuh berkasnya |
| B-47, B-48 | **Target** dan **utang-piutang** (masuk produk, KT-P10) | ADR domain masing-masing; sesudah Plus dijual |
| B-49, B-50, B-51 | Rapor bulanan bercerita + ekspor PDF, Freelance Pro, cadangan otomatis Drive | Sesudah Plus dijual; B-51 sesudah B-42 |
| B-52 | Tanya Tanuki R1 | Sesudah B-47/B-48 supaya bisa menjawab tentang target dan utang; mutu diuji dengan katalog kueri sempit |
| B-53, B-54 | Rapor Tahunan (Des 2027) dan Rekap SPT (Jan 2028) | Tahun data penuh pertama; B-49, B-50, B-48 |
| B-55, B-56 | Widget (Catat gratis, ringkasan Plus); kosmetik Plus | Kapan saja; B-56 menunggu aset pemilik |
| B-57–B-62 | Patungan dari struk, kartu kredit/paylater sebagai dompet tagihan, kekayaan bersih, Dompet Bersama/Plus Keluarga (butuh B-7), rapor kuartal freelance dan Tanya Tanuki R2, catat dari email | Sesudah pilar Plus terukur; urutan di FREEMIUM_PAYWALL §13.5 |

### Jalur Plus (urutan disetujui pemilik 18 Okt 2026, KT-P9)

Freemium dan paywall dirancang di [FREEMIUM_PAYWALL.md](../01-product/features/FREEMIUM_PAYWALL.md) (B-41). Urutan usulannya,
dengan alasan lengkap di §13 dokumen itu:

```
A. Kepercayaan (gratis)   B-42 ekspor/cadangan manual (selesai, Fase 22), B-43 kunci aplikasi
        │
B. Fondasi Plus           B-41 billing, hak, paywall, gerbang fitur lama
        │
C. Tiga pilar → dijual    B-44 Penjaga ─► B-45 Catat dari foto ─► B-46 Bagaimana kalau
        │                 ─► B-41 reverse trial (Plus mulai dijual)
D. Domain baru            B-47 Target, B-48 utang-piutang (ADR dulu)
        │
E. Melengkapi pilar       B-49 rapor + PDF ─► B-50 Freelance Pro, B-51 cadangan Drive,
        │                 B-52 Tanya Tanuki
F. Musiman                B-53 Rapor Tahunan (Des 2027), B-54 Rekap SPT (Jan 2028)

Kapan saja: B-55 widget, B-56 kosmetik. Sesudahnya: B-57–B-62, B-7, B-15.
```

Prinsipnya: kepercayaan sebelum menagih; Plus baru dijual bila tiga pilar
terasa di uji coba; mesin yang sudah ada dan fitur tanpa data keluar lebih
dulu; aturan uang baru (Target, utang) lewat ADR; fitur AI paling berisiko
paling akhir. Nomor fase usulan (21–26) ada di FREEMIUM_PAYWALL §13.4 dan
baru dipakai saat pemilik menaikkan butirnya ke Now.

### Tidak dikerjakan

Daftar lengkapnya ada di PRD §6 "Di luar MVP" dan tiap dokumen fitur bagian
"Yang sengaja tidak dikerjakan": koneksi bank, pembayaran atau transfer
sungguhan, saran investasi, perkiraan berbasis AI, skor kesehatan keuangan,
streak harian, dan periode mingguan. (Tanya Tanuki, B-52, bukan perkiraan
berbasis AI: Gemini hanya memahami pertanyaan, angkanya dihitung aplikasi.)

### Aturan memakai peta ini

- Satu butir di satu kolom. Naik kolom hanya atas keputusan pemilik.
- Butir baru masuk antrean `B-n` di TASK_LIST lebih dulu, lalu ditaruh di
  kolom yang sesuai di sini.
- Butir yang selesai dihapus dari sini; riwayatnya ada di fase masing-masing.

## Fase 0: Dokumen Saldough 2.0

Menulis ulang seluruh dokumen produk dan arsitektur sebelum satu baris kode
baru ditulis, sejalan dengan preferensi pemilik "dokumentasi lebih dulu,
kode menyusul". Tidak ada kode aplikasi di fase ini.

Urutan penulisannya meniru urutan Saldough 1.0: istilah dulu lewat
glosarium, lalu produk lewat PRD dan user stories, lalu domain lewat
`DOMAIN_MODEL.md`, lalu keputusan arsitektur lewat ADR-011 sampai ADR-014,
dan baru rencana kerja lewat roadmap dan daftar tugas. Urutan ini penting
karena setiap dokumen belakangan merujuk istilah dan keputusan yang sudah
ditetapkan di dokumen sebelumnya.

**Selesai kalau:** seluruh dokumen di `docs/` konsisten dengan model Dompet
+ Transaksi + Anggaran, tautan relatifnya hidup, dan `.claude/CLAUDE.md`
beserta `AGENT_CONTEXT.md` tidak lagi menyuntikkan konteks yang basi ke
sesi berikutnya.

## Fase 1: Domain inti — dompet dan transaksi

Membangun buku besar yang belum pernah ada di Saldough 1.0: entitas
`Wallet` dan `Transaction`, penyimpanan berpartisi per bulan, dan
pemeliharaan saldo tercatat. Fase ini tanpa UI sama sekali, sehingga
kebenarannya dibuktikan lewat uji unit dengan angka nyata, bukan lewat
layar.

⚠ Fase ini dan Fase 2 terikat invarian yang sama: tidak satu pun berkas di
`lib/features/{cycle,card,investment,grocery,income}` atau
`lib/shared/goal` boleh disentuh, dan seluruh uji lama wajib tetap lulus
tanpa disunting. Kalau ada uji lama gagal, itu bukti fitur baru menyentuh
sesuatu yang seharusnya tidak.

**Selesai kalau:** saldo dompet yang tersimpan identik dengan hasil
penghitungan ulang dari seluruh transaksi, dibuktikan lewat uji, dan
`WalletRepository` beserta `TransactionRepository` terdaftar di
`RootModule` tanpa mengubah satu baris pun kode lama.

## Fase 2: Layar inti — CATAT, Transaksi, Dompet

Menyalakan aplikasi baru sampai bisa dipakai sehari-hari: mencatat
pemasukan, pengeluaran, dan transfer lewat alur CATAT, melihat riwayatnya,
dan melihat saldo tiap dompet.

Fase ini selesai **sebelum** cutover karena aplikasi baru harus sudah
layak dipakai sehari-hari sebelum yang lama dibuang. Menghapus fitur lama
lebih dulu tanpa pengganti yang berfungsi berarti pemilik kehilangan
alat pencatatan di tengah pivot.

Satu kanvas desain tunggal untuk seluruh layar inti dikerjakan di awal
fase ini, bukan satu kanvas per fase. Rinciannya ada di
[UI_UX_DESIGN_TASKS.md](done/UI_UX_DESIGN_TASKS.md).

**Selesai kalau:** pemilik bisa membuat dompet, mencatat pemasukan,
pengeluaran, dan transfer, lalu melihat saldo bergerak persis seperti
yang dijanjikan model — seluruhnya lewat aplikasi baru, tanpa menyentuh
fitur lama.

## Fase 3: Cutover

Menghapus seluruh fitur Saldough 1.0 dalam satu commit: `cycle`, `card`,
`investment`, `grocery`, `income`, dan `shared/goal`, beserta shell lama
dan seluruh adapter lintas fitur yang menghubungkannya.

Fase ini adalah **gerbang**, bukan pekerjaan yang bisa dicicil ke fase
lain. Keenam port lintas fitur — `RollUpResolver`, `CardCatalog`,
`GroceryCycleGateway`, `CycleIncomeWriter`, `CycleInvestmentGateway`, dan
`IncomeWorklogGateway` — semuanya bermuara ke `cycle`. Menghapus sebagian
darinya lebih awal meninggalkan galat berantai di `RootModule` dan
`MainShellPage` tanpa menyelesaikan apa pun, karena adapter yang tersisa
tetap menunjuk ke tipe yang sudah hilang. Satu-satunya cara aman adalah
menghapus keenamnya sekaligus, di satu commit, setelah penggantinya
terbukti berfungsi di Fase 2. Alasan lengkapnya ada di
[ADR-014](../02-architecture/adr/0014-strategi-pivot-saldough-2.md).

**Selesai kalau:** `flutter analyze` bersih, `flutter test` hijau dengan
baseline uji baru yang dicatat apa adanya, dan tidak ada satu pun rujukan
tersisa ke fitur yang dihapus.

## Fase 4: Anggaran

Membangun rencana belanja: anggaran dengan pos-posnya, progres yang
dihitung langsung dari transaksi tertaut, dan status tiap pos.

Anggaran menyusul transaksi karena progresnya diturunkan dari transaksi
yang sudah tercatat di Fase 1 dan 2 — tidak ada rumus anggaran yang bisa
diuji sebelum ada pengeluaran sungguhan untuk dihitung.

**Selesai kalau:** membuat anggaran tidak pernah mengubah saldo dompet
mana pun, dan progres pos anggaran berubah seketika saat pengeluaran
tertaut dicatat, disunting, atau dihapus.

## Fase 5: Freelance

Membangun domain pendukung yang memasok pemasukan ke buku besar: proyek
freelance, worklog, pengelompokan jadi pembayaran, dan pencatatan
pembayaran diterima.

Freelance menyusul anggaran karena keduanya independen satu sama lain,
tetapi sama-sama bergantung pada `Wallet` dan `Transaction` dari Fase 1.
Pencatatan pembayaran diterima di fase ini adalah satu-satunya titik yang
mengubah saldo dompet — worklog dan pengelompokan pembayaran murni
pencatatan tanpa efek finansial.

**Selesai kalau:** mencatat worklog dan mengelompokkannya jadi pembayaran
tidak pernah mengubah saldo dompet, dan mencatat pembayaran diterima
menambah saldo tepat satu kali lewat tepat satu `IncomeTransaction`.

## Fase 6: Beranda

Merangkai ringkasan saldo, arus bulan berjalan, progres anggaran, dan
penghasilan freelance yang belum dibayar ke dalam satu layar.

Beranda dikerjakan terakhir di antara layar karena ia hanya bermakna
setelah dompet, transaksi, anggaran, dan freelance sudah menghasilkan
data sungguhan untuk diringkas. Membangunnya lebih awal berarti menguji
ringkasan terhadap data kosong atau karangan.

**Selesai kalau:** Beranda tampil penuh di bawah satu detik pada
perangkat kelas menengah, dan loop inti penuh — dari mencatat transaksi
sampai pencatatan pembayaran freelance — bisa ditelusuri dari layar ini.

## Fase 7: Template dan poles

Menambahkan template anggaran untuk pos yang berulang tiap periode,
memasukkan aset ikon pixel-art dari pemilik ke `AppIcon`, dan memoles
keadaan pemuatan, kosong, serta konfirmasi tindakan merusak di seluruh
layar.

Fase ini terakhir karena template mengandaikan anggaran biasa sudah
berjalan, dan pemasangan aset ikon mengandaikan seluruh layar yang
memakainya sudah ada lewat lapisan `AppIcon` yang dipasang di Fase 2.

**Selesai kalau:** anggaran baru bisa dibuat dari template tanpa menyunting
templatenya, dan seluruh layar memakai aset ikon final dari
`docs/stitch_pixel_finance_tracker/` alih-alih ikon Material sementara.

> **Catatan (17 September 2026):** Aset ikon sudah tiba di repositori jauh
> lebih awal dari perkiraan — sebelum Fase 1 pun dimulai, bukan menjelang
> Fase 7. Urutan fase di sini tidak diubah karena mengintegrasikannya lebih
> awal berarti menulis widget `AppHardCard`/`AppSegmentedProgressBar` (lihat
> [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md))
> sebelum satu pun layar domain ada untuk mengujinya. Tapi ini keputusan yang
> layak ditinjau ulang pemilik, bukan diasumsikan tetap di Fase 7 selamanya.

## Fase 8: Tindak lanjut pasca-MVP

Kumpulan pekerjaan yang muncul setelah MVP dipakai dan disiapkan untuk
rilis. Berbeda dari fase-fase awal, isinya tidak berurutan ketat: tiap
tugas berdiri sendiri dan boleh dikerjakan kapan pun. Di sinilah tugas
kecil baru ditambahkan (lihat "Menambah tugas baru" di TASK_LIST).

Isinya: batas bulan periode anggaran (KT-1), pencarian Transaksi lintas
bulan, ganti nama menjadi Tanukonomy
([ADR-022](../02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md)),
identitas opsional beserta Analytics dan Crashlytics
([ADR-023](../02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md)),
kepemilikan data dan akun
([ADR-024](../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)),
satu mata uang per aplikasi
([ADR-025](../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md)),
persiapan rilis Android, dan polish label layar sempit.

**Selesai kalau:** aplikasi diunggah ke jalur uji Play Console dengan
formulir Keamanan Data dan listing yang cocok dengan isi build, dan
prasyarat ganti nama (merek dagang, domain, nama toko) sudah dipenuhi.

**Batas yang dijaga:** akun tetap opsional dan pencatatan inti tidak boleh
bergantung pada jaringan (NFR-REL-001 yang direvisi 28 Sep 2026).
Sinkronisasi data keuangan ke server **bukan** bagian fase ini — proyek
terpisah yang butuh ADR sendiri (B-7 di antrean TASK_LIST).

## Fase 9: Onboarding, info, dan tur spotlight

Pengenalan sekali di pembukaan pertama, tur spotlight per layar, dan lapis
info untuk memutar ulang keduanya. Dikerjakan setelah tab-tabnya stabil
karena tur menyorot elemen nyata. Desainnya di
[ONBOARDING_PLAN.md](../01-product/features/ONBOARDING_PLAN.md) dan
[ADR-021](../02-architecture/adr/0021-onboarding-dan-tur-spotlight.md);
langkah mata uang ditambahkan sebagai gerbang di
[ADR-025](../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md) §3.7.

**Selesai kalau:** pengguna lama melihat pengenalan sekali dengan data
utuh, pengguna baru dituntun sampai transaksi pertama, dan semuanya bisa
diputar ulang dari menu info. (Tercapai 28 Sep 2026, T-9.10.)

## Fase 11: Catat Cerdas — kategori dan suara

Sistem kategori bawaan yang bisa diubah
([ADR-026](../02-architecture/adr/0026-sistem-kategori.md)), lalu pencatatan
dari suara yang mengisi formulir CATAT; notifikasi dan foto menyusul lewat
kontrak yang sama ([ADR-027](../02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md)).
Rincian di [VOICE_INPUT_RESEARCH.md](../01-product/features/VOICE_INPUT_RESEARCH.md).

**Selesai kalau:** transaksi berkategori tertutup, dan pengguna bisa
mengucapkan satu transaksi lalu meninjaunya di formulir CATAT yang sudah
terisi; hasil suara tidak pernah tersimpan tanpa konfirmasi.

## Fase 12: Rapikan batas arsitektur

Hasil review arsitektur 30 Sep 2026: lapisan di dalam modul sehat, tetapi
batas antarfitur tidak mengikuti dokumen. Akar komposisi keluar dari
`core/`, sinyal buku besar menggantikan pemuatan ulang manual di shell,
dan kunci rute ADR-0004 ditegakkan ulang
([ADR-030](../02-architecture/adr/0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md)).
Tanpa perubahan perilaku yang terlihat pengguna.

**Selesai kalau:** tidak ada impor antarfitur selain `*_route_keys.dart`,
`core/` tidak mengimpor `shared/`/`features/`, shell tidak memuat ulang bloc
fitur lain, dan uji batas impor menjaga semuanya.

## Fase 13: Pecah fitur `record`

Audit 1 Okt 2026: `features/record` memegang CATAT, mesin tafsir Catat
Cerdas, suara, dan catat dari notifikasi sekaligus (sepertiga `lib/`).
Mesin tafsir pindah ke `shared/capture`, suara dan notifikasi jadi fitur
sendiri yang membuka CATAT lewat kunci rute
([ADR-033](../02-architecture/adr/0033-pecah-fitur-record.md)). Didahului
perbaikan penangkap notifikasi (ADR-032 §10).

**Selesai kalau:** `features/record` hanya berisi CATAT, `RecordBloc` tidak
memegang dependensi suara, dan uji batas impor menjaga ketiga fitur.

## Fase 14: Bahasa visual baru

Pemilik menilai tampilan berantakan dan sulit dibaca (3 Okt 2026). Bahasa
visual "buku catatan dengan aksen piksel" menggantikan ADR-015/016/020
([ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md));
desainnya di artefak design system dan prototipe, salinannya di
`docs/03-design/`. Urutan: token dan tema → komponen → navigasi dan Catat →
layar → teks.

**Selesai kalau:** setiap layar cocok dengan prototipe padanannya, tidak ada
lagi bingkai tebal, monospace, atau Space Grotesk/Space Mono, kontras teks
lolos di kedua tema, dan seluruh uji lulus.
## Fase 15: Rencana dan rutin (R1)

Permintaan pemilik 2 Okt 2026: transaksi rutin, uang nganggur, dan perkiraan
arus kas. Tab Anggaran menjadi **Rencana** dengan segmen Bulan ini, Anggaran,
dan Rutin ([ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md);
desain di [docs/01-product/features/](../01-product/features/RECURRING_AND_FORECAST.md)).
Dibagi dua rilis yang berdiri sendiri: **R1a** (rutin: CATAT Ulangi, segmen
Rutin, kartu Menunggu, pencocokan dengan catat dari notifikasi, pengingat)
dan **R1b** (Bulan ini: bulan keuangan, uang nganggur, perkiraan bulan
berjalan). R2 (anggaran rutin, bulan depan) dan R3 (otomasi) menunggu R1
dipakai.

**Selesai kalau:** rutin bisa dibuat dari CATAT dan tercatat satu ketuk
atau tercocok sendiri dari notifikasi tanpa catatan ganda; pengingat muncul
di Android dan iOS; segmen Bulan ini menampilkan uang nganggur dan perkiraan
saldo yang angkanya cocok dengan kasus uji wajib; tidak ada jalur rutin yang
mengubah saldo selain `RecordTransaction`.

## Fase 16: Rencana R2 (anggaran rutin dan ke depan)

Permintaan pemilik 4 Okt 2026, sebelum R1 dirilis. Anggaran rutin lahir
sendiri tiap periode (template berjadwal), rutin bisa ditautkan ke pos
tanpa hitung ganda, perkiraan menjangkau dua bulan ke depan dengan
peringatan "siapkan dana", dan awal bulan punya tinjau rencana dengan kilas
balik ([ADR-036](../02-architecture/adr/0036-anggaran-rutin-dan-perkiraan-ke-depan.md)). Layar memakai bahasa visual
yang ada dan ikut disapu Fase 14.

**Selesai kalau:** anggaran rutin lahir sekali per periode tanpa periode
terlewat; menyunting anggaran periode lalu tidak mengubah template;
perkiraan bulan depan berantai persis dalam sen; siapkan dana muncul untuk
autodebet yang kurang; tinjau awal bulan bisa diselesaikan di bawah satu
menit tanpa memblokir pencatatan.

## Fase 18: Periode keuangan

Keputusan pemilik 10 Okt 2026. Awal bulan keuangan mudah ditemukan dan
mengikuti gajian (termasuk hari terakhir bulan), mengubahnya tidak pernah
memotong ulang bulan-bulan lalu, periode berjalan menjadi satu periode
peralihan, anggaran rutin bisa ikut pindah tanpa celah, dan gajian yang maju
tetap masuk periodenya. Kartu Arus Beranda ikut periode keuangan
([ADR-038](../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md),
[FINANCIAL_PERIOD.md](../01-product/features/FINANCIAL_PERIOD.md)).

**Selesai kalau:** contoh A–D FINANCIAL_PERIOD §5 lulus persis; tidak ada
celah atau tumpang-tindih anggaran rutin sesudah dipindah; saldo tidak
berubah oleh perubahan apa pun; Beranda dan Rencana menyebut angka periode
yang sama.

**Selesai 15 Okt 2026** (rilis `0.7.0+13`): 19 tugas, termasuk lima tindak
lanjut QA (T-18.15–T-18.19); verifikasi perangkat T-18.9 lulus.

## Fase 19: Analisis keuangan (R1)

Keputusan pemilik 10 Okt 2026. Segmen Analisis di Riwayat: ke mana uang
pergi per kategori, dibanding biasanya, tren enam periode, rincian kategori
sampai transaksinya, dan jalan membetulkan Tanpa kategori
([FINANCIAL_ANALYSIS.md](../01-product/features/FINANCIAL_ANALYSIS.md)).
Bergantung pada Fase 18 karena membaca periode yang sama.

**Selesai kalau:** contoh §10 FINANCIAL_ANALYSIS lulus persis dalam sen;
total Analisis sama dengan kartu Arus Beranda dan cocok dengan Rencana
(B-15); tidak ada nada menghakimi; Beranda tidak melambat.

**Selesai 18 Okt 2026** (PR #51, rebase ke `main`): 12 tugas, termasuk
T-19.10 (Daftar Riwayat berbagi periode), T-19.11 (kilas balik bisa dibuka
lagi), dan T-19.12 (pencarian lintas periode) dari tindak lanjut QA; verifikasi
emulator T-19.7 tanpa Gagal S1/S2. Sisa: B-40 (tindak lanjut kecil) dan R2
(B-38).

## Fase 20: Pengumuman pembaruan

Permintaan pemilik 11 Okt 2026. Pengguna tahu ada versi baru dari Play Store
(dan bisa memasangnya dari dalam aplikasi) dan pembaruan kecil Shorebird, lalu
melihat Apa yang baru sekali; Akun menampilkan versi dan pembaruan kecil
yang berjalan
([APP_UPDATE.md](../01-product/features/APP_UPDATE.md)). Mekanisme
teknisnya di
[ADR-039](../02-architecture/adr/0039-pengumuman-pembaruan-play-shorebird-dan-catatan.md)
(Accepted 15 Okt 2026). Tidak bergantung pada Fase 18/19. **Status:**
selesai 15 Okt 2026. Kode T-20.1–T-20.7 di `main` (ada di build `0.6.0+12`
dan `0.7.0+13`); verifikasi perangkat T-20.8 lulus semua.

**Selesai kalau:** alur F1–F4 APP_UPDATE lulus di perangkat lewat jalur tes
Play dan pembaruan kecil Shorebird sungguhan; data keuangan utuh sesudah
pemasangan; luring diam; Keamanan Data mencatat Shorebird.

## Fase 21: Penemuan fitur

Permintaan pemilik 18 Okt 2026. Tiga fitur yang sudah jadi (Catat dari
notifikasi, pengingat rutin, awal bulan keuangan) hanya ada sebagai setelan
di Akun sehingga jarang dinyalakan. Fase ini menjadikan pengingat dan awal
periode langkah wajib di onboarding (wajib dijawab), menjadikan Catat dari
notifikasi pintu yang selalu ada di Beranda (Nyalakan, Kelola, Izinkan) dengan
Mulai cepat, menambah tombol Nyalakan pengingat, status di Akun, dan tur
([FEATURE_DISCOVERY.md](../01-product/features/FEATURE_DISCOVERY.md)).
Bukan fitur baru; bergantung pada slot Beranda Fase 20 dan onboarding Fase
9. **Status:** KT-D1 diputuskan 18 Okt 2026; menunggu rupa dari designer, lalu kode.

**Selesai kalau:** akun baru tidak bisa melewati dua langkah tanpa
menjawab, baris Catat dari notifikasi di Beranda tidak pernah hilang dan tombol
pengingat hilang saat efektif,
pengguna lama tidak dipaksa mengulang onboarding, semuanya terverifikasi di
perangkat.

## Fase 22: Ekspor dan cadangan manual

Dari B-42, permintaan pemilik 22 Okt 2026, prasyarat rilis publik dan Plus
(FREEMIUM_PAYWALL KT-P7). Transaksi bisa diekspor ke xlsx/CSV, seluruh data
bisa dicadangkan ke berkas dan dipulihkan di ponsel lain, gratis dan tanpa
akun ([EXPORT_BACKUP.md](../01-product/features/EXPORT_BACKUP.md)). Format
cadangan dipakai ulang cadangan otomatis Drive (B-51). Keputusan teknis di
ADR engineer (T-22.1). **Status:** selesai 23 Okt 2026. Kode T-22.0–T-22.7 di `main` (ADR-040 Accepted); QA emulator Android tanpa temuan S1/S2; sisa uji perangkat (iOS, Excel/Sheets) di B-67.

**Selesai kalau:** cadangan dari satu ponsel dipulihkan di ponsel lain dan
seluruh layar identik, pemulihan gagal tidak pernah merusak data, dan total
di spreadsheet sama dengan aplikasi, terverifikasi di perangkat.

## Ketergantungan antar fase

```
Fase 0 ──► Fase 1 ──► Fase 2 ──► Fase 3 ──┬──► Fase 4 ──┐
                                           ├──► Fase 5 ──┼──► Fase 6 ──► Fase 7
                                           └─────────────┘
```

Fase 4 dan Fase 5 tidak saling bergantung dan bisa dikerjakan dalam
urutan mana pun setelah Fase 3 selesai. Keduanya harus selesai sebelum
Fase 6, karena Beranda meringkas hasil keduanya.

## Yang bisa dikerjakan lebih awal

Dua pekerjaan tidak terikat urutan fase di atas dan bisa berjalan paralel
dengan fase manapun yang sedang dikerjakan.

Desain kanvas untuk layar inti dan struktur `AppIcon` bisa dikerjakan
sejak awal Fase 2 tanpa menunggu domain anggaran maupun freelance selesai,
karena keduanya hanya bergantung pada dompet dan transaksi yang sudah ada
sejak Fase 1.

Aset ikon pixel-art dari pemilik bisa datang kapan saja tanpa memblokir
fase manapun. Lapisan `AppIcon` yang dipasang di Fase 2 memakai ikon
Material sebagai isian sementara sampai asetnya tiba, sehingga
kedatangannya tidak pernah jadi gerbang bagi fase lain — pemasangannya
sendiri baru terjadi di Fase 7.
