# Saldough

Aplikasi Flutter untuk Android dan iOS yang menggantikan sistem pencatatan
keuangan pribadi berbasis empat Google Spreadsheet yang dikelola manual.

Saldough tidak memperkenalkan cara menganggar yang baru. Struktur, istilah, dan
alurnya sengaja dibuat sama dengan spreadsheet yang sudah dipakai. Yang dihapus
hanya pekerjaan tangannya: menyalin angka antar dokumen, menjumlah jam kerja,
menghitung potongan pajak, dan menyalin ulang struktur bulan.

**Status:** dokumentasi selesai, implementasi belum dimulai.

## Yang dikerjakan aplikasi ini

Sistem manual yang digantikan terdiri dari empat spreadsheet dengan tiga titik
salin manual setiap bulan.

| Sumber | Menghasilkan | Sebelumnya disalin tangan ke |
|---|---|---|
| Timesheet jam kerja | Total jam per periode | Gaji kotor di buku utama |
| Daftar belanja | Total belanja sebulan | Baris `Bulanan` di anggaran |
| Transaksi kartu kredit | Total per siklus tagihan | Baris `CC` di anggaran |

Saldough menghitung ketiganya otomatis, membuat bulan baru dari template tanpa
membawa baris insidental, dan membagi sisa ke pos investasi berdasarkan
persentase.

## Mulai dari mana

Baca [dokumentasi](docs/README.md). Halaman itu memuat jalur baca sesuai peran.

Kalau akan langsung menulis kode, mulai dari
[aturan arsitektur](.claude/AGENT_CONTEXT.md) lalu
[daftar tugas](docs/04-planning/TASK_LIST.md).

## Tumpukan teknologi

| Bagian | Pilihan |
|---|---|
| Kerangka | Flutter 3.47.2, Dart 3.13.2 |
| Arsitektur | Clean Architecture berbasis fitur, tiga lapisan |
| State | Bloc dengan efek terdaftar, dari `package:state_management` |
| Navigasi | Registri rute bertipe dari `package:navigation`, di atas `go_router` |
| Penyimpanan | Hive lewat `package:api_storage` dan `package:hive_storage` |
| Kesalahan | `package:failures`, konvensi lempar dan tangkap |
| Injeksi dependensi | `package:di`, GetIt dengan lingkup per fitur |
| Terjemahan | slang, bahasa dasar Indonesia dan tambahan Inggris |

Paket internal berasal dari
[`arkariz/advance-mobile-platform`](https://github.com/arkariz/advance-mobile-platform),
dikonsumsi sebagai git dependency yang dipin per tag.

## Ketepatan angka

Seluruh nominal disimpan sebagai bilangan bulat dalam satuan sen, dan pembulatan
hanya dilakukan saat menampilkan. Aturan ini bukan pilihan gaya: pajak 2,5% pada
penghasilan freelance menghasilkan pecahan setengah rupiah, dan pembulatan yang
terlalu dini membuat hasilnya meleset satu rupiah dari catatan asli.

Setiap rumus domain diuji memakai angka nyata dari spreadsheet sebagai kasus
uji. Rinciannya di [model domain](docs/02-architecture/DOMAIN_MODEL.md).

## Struktur repositori

```
Saldough/
├── .claude/          # konteks dan aturan untuk agent
├── docs/             # PRD, arsitektur, ADR, dan rencana
└── README.md
```

Kode aplikasi akan menempati `lib/` setelah Fase 0 selesai.
