# Satu mata uang per aplikasi, dipilih pengguna

## 1. Metadata

- **Decision ID:** ADR-025
- **Tanggal:** 2026-09-29
- **Fase roadmap:** T-8.6 (dukungan mata uang selain Rupiah)
- **Status:** Accepted
- **Cakupan:** `lib/core/currency/`, `lib/core/utils/formatters/`,
  kolom nominal di `features/record`, `features/wallet`, `features/budget`
  (dan `features/freelance` lewat `BudgetMoneyField`), layar Akun
- **Tidak mengubah:** aturan #1 CLAUDE.md (uang `int` satuan sen), skema
  penyimpanan, rumus domain.

## 2. Konteks

Sampai ADR ini, Rupiah tertanam di seluruh lapisan tampilan: formatter
`AppMoneyFormatter` selalu menulis `Rp`, kolom input hanya menerima angka
bulat berpemisah titik (`RupiahInputFormatter`), awalan `Rp` ditulis
langsung di tiga kolom nominal, dan label chip pilihan cepat memakai
`rb`/`jt`. Aplikasi akan dirilis di Play Store untuk pengguna di luar
Indonesia, jadi mereka butuh mata uangnya sendiri.

Tiga keputusan pemilik (29 September 2026):

1. **Satu mata uang untuk seluruh aplikasi**, bukan per dompet. Semua
   dompet, transaksi, anggaran, dan proyek freelance memakai mata uang yang
   sama.
2. **Mengganti mata uang tidak mengonversi angka.** Rp50.000 tampil sebagai
   $50.000,00 sesudah diganti ke USD. Aplikasi memperingatkan ini sebelum
   mengganti.
3. **Pemisah ribuan dan desimal mengikuti bahasa aplikasi**, bukan mata
   uangnya: bahasa Indonesia `1.234,56`, bahasa Inggris `1,234.56`.

## 3. Keputusan

### 3.1 Satuan simpanan tidak berubah

Nominal tetap `int` dalam **seperseratus satuan utama** mata uang aktif.
Istilah "sen" dipertahankan di kode dan dokumen: untuk Rupiah artinya sen
Rupiah seperti sebelumnya, untuk USD artinya cent, untuk yen artinya
seperseratus yen. Semua mata uang yang didukung punya paling banyak dua
angka desimal, jadi satuan ini cukup untuk semuanya.

Akibatnya **tidak ada migrasi data**, dan rumus domain (potongan per mil,
pembulatan setengah ke atas, sisa anggaran) tetap sama persis. Data lama
dibaca sebagai Rupiah karena Rupiah bawaannya.

Mata uang dengan tiga angka desimal (dinar Kuwait, Bahrain) sengaja tidak
didukung; menambahkannya berarti mengganti satuan simpanan.

### 3.2 Daftar mata uang

`AppCurrency` (enum di `lib/core/currency/app_currency.dart`) memuat kode
ISO 4217, simbol, jumlah angka desimal tampilan, dan satu **langkah** untuk
pilihan cepat:

| Kode | Simbol | Desimal | Langkah |
|---|---|---|---|
| IDR | Rp | 0 | 10.000 |
| USD | $ | 2 | 1 |
| EUR | € | 2 | 1 |
| GBP | £ | 2 | 1 |
| JPY | ¥ | 0 | 100 |
| CNY | CN¥ | 2 | 10 |
| KRW | ₩ | 0 | 1.000 |
| INR | ₹ | 2 | 100 |
| SGD | S$ | 2 | 1 |
| MYR | RM | 2 | 5 |
| THB | ฿ | 2 | 50 |
| PHP | ₱ | 2 | 50 |
| VND | ₫ | 0 | 10.000 |
| AUD | A$ | 2 | 1 |

IDR ditampilkan tanpa desimal (kebiasaan Indonesia), walau ISO 4217
mencatatnya dua desimal. Simbol dolar non-AS diberi awalan negara supaya
tidak tertukar dengan USD. Nama mata uang ada di i18n `currency.names.*`.

### 3.3 Tampilan

- `AppMoneyFormatter.format(sen)` tetap satu-satunya jalan menampilkan
  nominal. Formatnya: tanda minus U+2212 bila negatif, simbol, lalu angka.
  Simbol menempel tanpa spasi seperti `Rp` sebelumnya.
- Mata uang tanpa desimal membulatkan setengah ke atas seperti sebelumnya.
  Mata uang dua desimal **selalu** menulis dua angka desimal (`$50.00`),
  tanpa pembulatan karena satuannya sudah cent.
- Pemisah dibaca dari `LocaleSettings.currentLocale`, sama seperti
  `freelance_format.dart` dan `CycleMonthFormatter`.

### 3.4 Input

`rupiah_input.dart` diganti `money_input.dart`, dan seluruh fungsinya
bekerja dalam **sen**, bukan satuan utama:

- `formatMoneyInput(sen)` dan `parseMoneyInput(text)` untuk mengisi dan
  membaca kolom. Pemanggil tidak lagi mengalikan atau membagi 100 sendiri.
- `MoneyInputFormatter` menyisipkan pemisah ribuan. Untuk mata uang
  berdesimal, ia menerima satu pemisah desimal (titik atau koma yang
  diketik terakhir, dinormalkan ke pemisah desimal bahasa aktif) dengan
  paling banyak dua angka di belakangnya.
- `moneyKeyboardType` menampilkan tombol desimal hanya bila mata uangnya
  berdesimal.
- Pilihan cepat dihitung dari **kelipatan langkah** (`quickAmounts`):
  pengeluaran ×1, ×5, ×10; pemasukan dan transfer ×50, ×100, ×500; saldo
  awal dompet ×10, ×50, ×100, ×500. Untuk IDR hasilnya persis daftar lama.
  Labelnya ringkas sesuai bahasa: `+10rb`/`+5jt` (id), `+10k`/`+5M` (en).

### 3.5 Mata uang aktif dan penyimpanannya

- `ActiveCurrency` (`lib/core/currency/active_currency.dart`) memegang mata
  uang aktif sebagai `ValueNotifier`, bawaan IDR. Dibaca formatter secara
  statis, sama seperti `LocaleSettings` untuk bahasa.
- `CurrencyPreferenceRepository` menyimpan kode mata uang di
  `KeyValueStorage` (`settings/currency`) dengan `Either<Failure, T>`.
  `main.dart` memuatnya sesudah `di.run()` dan sebelum `runApp()`. Gagal
  dibaca atau kode tidak dikenal berarti IDR, bukan aplikasi gagal dibuka.
- Tidak ada deteksi otomatis dari wilayah perangkat. Pengguna lama yang
  perangkatnya berbahasa Inggris tidak boleh tiba-tiba melihat datanya
  bertanda `$`.

### 3.6 Mengganti mata uang

- Dipilih dari layar Akun, bagian "Pengaturan", baik saat sudah maupun
  belum masuk. Akun tetap opsional (ADR-024); mata uang tidak butuh akun.
- Sebelum mengganti, dialog menampilkan contoh nyata tanpa konversi
  (`Rp50.000 → $50.000,00`) dan meminta konfirmasi.
- Sesudah diganti, seluruh pohon widget dibangun ulang supaya layar yang
  sudah terbuka di bawah layar Akun ikut memakai simbol baru. Formatter
  dipanggil statis, jadi tidak ada dependensi `InheritedWidget` yang bisa
  memicu pembangunan ulang biasa.

## 4. Alternatif yang ditolak

- **Mata uang per dompet.** Butuh kurs (manual atau online) untuk total
  Beranda dan anggaran, serta transfer dua nominal. Menyentuh aturan #7 dan
  hampir semua ringkasan. Ditolak pemilik untuk sekarang; kalau kelak
  dibutuhkan, ADR ini jadi titik awalnya karena satuan simpanannya sudah
  netral terhadap mata uang.
- **Konversi otomatis saat mengganti.** Aplikasi tidak punya sumber kurs
  dan tidak boleh bergantung pada jaringan untuk pencatatan inti
  (NFR-REL-001). Angka yang dikonversi diam-diam juga tidak lagi cocok
  dengan catatan bank pengguna.
- **Mengunci mata uang sesudah ada data.** Paling aman, tapi pengguna yang
  salah pilih saat awal tidak bisa memperbaikinya tanpa menghapus data.
- **`intl` `NumberFormat.currency`.** Menambah dependensi dan data lokal
  besar hanya untuk pemisah ribuan, dan formatnya mengikuti kebiasaan mata
  uang, bukan bahasa aplikasi (bertentangan dengan keputusan 3).

## 5. Konsekuensi

- Sekitar 70 titik tampilan nominal ikut berubah tanpa disentuh, karena
  semuanya sudah lewat `AppMoneyFormatter`.
- Tiga kolom nominal (`RecordAmountField`, saldo awal dompet,
  `BudgetMoneyField`) dan pemanggilnya berpindah ke API berbasis sen.
- Kolom nominal kini bisa menerima desimal untuk mata uang berdesimal,
  jadi saldo awal atau anggaran bernilai pecahan cent bisa disunting ulang.
  Untuk mata uang tanpa desimal, nilai tersimpan yang bukan satuan utuh
  tetap tidak diisikan ke kolom (perilaku lama).
- Onboarding belum menanyakan mata uang. Pengguna baru di luar Indonesia
  harus menemukannya di layar Akun. Dicatat sebagai tindak lanjut, bukan
  bagian ADR ini.
- Situs `tanukonomy-web` belum menyebut dukungan mata uang lain.

## 6. Kriteria tinjauan

- Uji formatter: IDR tetap lolos semua kasus lama (termasuk
  `Rp3.039.563`), USD menulis `$1,234.56`/`$1.234,56` sesuai bahasa, JPY
  tanpa desimal, negatif memakai U+2212.
- Uji input: mengetik desimal, membatasi dua angka, pemisah yang diketik
  dinormalkan, IDR menolak desimal.
- Uji penyimpanan: kode tak dikenal atau dokumen rusak jatuh ke IDR.
- `flutter analyze` bersih dan seluruh uji lama lulus dengan bawaan IDR.
