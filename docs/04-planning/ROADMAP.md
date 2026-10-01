# Roadmap

Dokumen ini menjelaskan urutan pengerjaan Saldough 2.0 dan alasan di balik
urutannya. Untuk daftar tugas yang bisa langsung dikerjakan beserta
progresnya, lihat [TASK_LIST.md](TASK_LIST.md). Untuk pekerjaan desain
visual yang menurunkan fase-fase ini jadi layar, lihat
[UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md).

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

Fase 0 sampai 6 membentuk MVP. Fase 7 dikerjakan setelahnya. Fase 8 dan 9
lahir dari pemakaian nyata dan persiapan rilis, bukan dari rencana awal.

**Status per 1 Oktober 2026:** Fase 0–7, 9, dan 12 selesai; Fase 8 dan 11
berjalan (sisa Fase 8: sapuan nama dan ikon iOS T-8.3; sisa Fase 11: ucapan
nyata T-11.5, Keamanan Data T-11.6, Firebase AI T-11.7–11.9). Rincian dan
antrean di [TASK_LIST.md](TASK_LIST.md).

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
[UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md).

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
[ONBOARDING_PLAN.md](ONBOARDING_PLAN.md) dan
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
Rincian di [VOICE_INPUT_RESEARCH.md](VOICE_INPUT_RESEARCH.md).

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
