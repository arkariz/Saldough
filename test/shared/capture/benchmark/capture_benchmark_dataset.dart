import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

// Dataset benchmark Catat Cerdas (VOICE_INPUT_RESEARCH.md §10, T-11.9),
// dipakai uji aturan (`domain/capture_benchmark_test.dart`) dan benchmark
// cloud di perangkat (`integration_test/capture_cloud_benchmark_test.dart`).

/// (teks, jenis, nominal satuan utama, dompet, dompet tujuan, kategori,
/// masalah). Kategori [anyCategory] = tidak dinilai (lebih dari satu jawaban
/// wajar).
typedef BenchmarkCase = (String, DraftKind, int?, String?, String?, String?, Set<DraftIssue>);

/// Kategori yang tidak dinilai.
const anyCategory = '*';

/// Pengeluaran, disingkat supaya tabel kasus terbaca.
const DraftKind e = DraftKind.expense;

/// Pemasukan.
const DraftKind i = DraftKind.income;

/// Transfer.
const DraftKind t = DraftKind.transfer;

/// "Hari ini" seluruh kasus.
final DateTime benchmarkNow = DateTime(2026, 9, 30, 12);

/// Dompet uji: BCA, Cash, GoPay.
const benchmarkWallets = [
  Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
  Wallet(id: 'cash', name: 'Cash', iconKey: 'walletCash', initialBalance: 0, currentBalance: 0),
  Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
];

const _names = {
  'food': 'Makan & Minum',
  'groceries': 'Belanja Harian',
  'transport': 'Transportasi',
  'bills': 'Tagihan',
  'internet': 'Pulsa & Internet',
  'health': 'Kesehatan',
  'entertainment': 'Hiburan',
  'shopping': 'Belanja',
  'education': 'Pendidikan',
  'family': 'Keluarga',
  'donation': 'Donasi',
  'expenseOther': 'Lainnya',
  'salary': 'Gaji',
  'freelance': 'Freelance',
  'bonus': 'Bonus',
  'gift': 'Hadiah',
  'incomeOther': 'Lainnya',
};

/// Kategori bawaan dengan nama Indonesia.
final List<Category> benchmarkCategories = [
  for (final b in BuiltInCategories.all) Category(id: b.id, kind: b.kind, name: _names[b.key]!, builtInKey: b.key),
];

/// Kasus aturan bahasa Indonesia: draf aturan **wajib** persis seperti
/// harapan (uji CI).
final indonesianCases = <BenchmarkCase>[
  // Sederhana
  ('makan 25 ribu', e, 25000, null, null, 'builtin.food', {}),
  ('parkir 5 ribu', e, 5000, null, null, 'builtin.transport', {}),
  ('gaji 10 juta', i, 10000000, null, null, 'builtin.salary', {}),
  // Bahasa alami
  ('tadi siang makan ayam geprek dua puluh lima ribu', e, 25000, null, null, 'builtin.food', {}),
  ('barusan beli kopi sebelum meeting', e, null, null, null, 'builtin.food', {DraftIssue.amountMissing}),
  ('makan siang tiga puluh lima ribu', e, 35000, null, null, 'builtin.food', {}),
  ('tadi beli kopi dua puluh lima ribu', e, 25000, null, null, 'builtin.food', {}),
  ('bayar listrik dua ratus lima puluh ribu', e, 250000, null, null, 'builtin.bills', {}),
  ('gaji masuk dua belas juta', i, 12000000, null, null, 'builtin.salary', {}),
  ('isi bensin seratus ribu', e, 100000, null, null, 'builtin.transport', {}),
  ('beli shampoo dan sabun total tujuh puluh dua ribu', e, 72000, null, null, null, {}),
  // Dompet
  ('Tadi makan siang 35 ribu pakai BCA', e, 35000, 'bca', null, 'builtin.food', {}),
  ('ojek 15 ribu bayarnya cash', e, 15000, 'cash', null, 'builtin.transport', {}),
  ('gaji 12 juta masuk ke GoPay', i, 12000000, 'gopay', null, 'builtin.salary', {}),
  ('Gaji bulan ini 12 juta masuk BCA', i, 12000000, 'bca', null, 'builtin.salary', {}),
  ('makan 20 ribu pakai BRI', e, 20000, null, null, 'builtin.food', {DraftIssue.walletUnknown}),
  // Transfer
  ('transfer lima ratus ribu dari BCA', t, 500000, 'bca', null, null, {DraftIssue.transferTargetMissing}),
  ('transfer 200 ribu dari BCA ke GoPay', t, 200000, 'bca', 'gopay', null, {}),
  ('top up GoPay 100k', t, 100000, null, 'gopay', null, {DraftIssue.transferSourceMissing}),
  ('top up GoPay 100 ribu dari BCA', t, 100000, 'bca', 'gopay', null, {}),
  // Ambigu
  ('tadi belanja', e, null, null, null, 'builtin.shopping', {DraftIssue.amountMissing}),
  ('bayar tagihan', e, null, null, null, 'builtin.bills', {DraftIssue.amountMissing}),
  (
    'transfer uang',
    t,
    null,
    null,
    null,
    null,
    {DraftIssue.amountMissing, DraftIssue.transferSourceMissing, DraftIssue.transferTargetMissing},
  ),
  ('beli dua kopi lima puluh ribu', e, 50000, null, null, 'builtin.food', {}),
  ('kopi 25 ribu roti 15 ribu', e, null, null, null, 'builtin.food', {DraftIssue.amountMultiple}),
  ('parkir 5', e, null, null, null, 'builtin.transport', {DraftIssue.amountWithoutUnit}),
  ('kopi 5,000', e, null, null, null, 'builtin.food', {DraftIssue.amountAmbiguous}),
  ('dapat 10 dolar', i, null, null, null, null, {DraftIssue.currencyUnsupported}),
  // Campur bahasa
  ('coffee 25 ribu pakai BCA', e, 25000, 'bca', null, 'builtin.food', {}),
  ('tadi ngopi 25k', e, 25000, null, null, 'builtin.food', {}),
  // Regresi verifikasi M1 (F2, F4, F5).
  ('bayar masuk tol 20 ribu', e, 20000, null, null, 'builtin.transport', {}),
  ('dapat diskon beli baju 100 ribu', e, 100000, null, null, 'builtin.shopping', {}),
  ('beli pulsa bonus kuota 50 ribu', e, 50000, null, null, 'builtin.internet', {}),
  ('beli air mineral 5 ribu', e, 5000, null, null, null, {}),
  ('uang masuk 500 ribu', i, 500000, null, null, null, {}),
  ('bonus 1 juta', i, 1000000, null, null, 'builtin.bonus', {}),
  ('kopi 25 ribu 2 gelas', e, 25000, null, null, 'builtin.food', {}),
  ('gaji satu setengah juta', i, 1500000, null, null, 'builtin.salary', {}),
  // Angka polos IDR dan tanggal pasti (ADR-029 §3.2–3.3).
  ('parkir 2000', e, 2000, null, null, 'builtin.transport', {}),
  ('beli 2 kopi 9000', e, 9000, null, null, 'builtin.food', {}),
  ('beli kopi 5000 tanggal 27 september', e, 5000, null, null, 'builtin.food', {}),
  ('makan 20 ribu pakai BCA tanggal 27 september 2026', e, 20000, 'bca', null, 'builtin.food', {}),
  ('makan 20 ribu tanggal 31 februari 2026', e, 20000, null, null, 'builtin.food', {DraftIssue.dateUnclear}),
];

/// Kasus aturan bahasa Inggris (ADR-029 §3.1).
final englishCases = <BenchmarkCase>[
  ('lunch 35 thousand using BCA', e, 35000, 'bca', null, 'builtin.food', {}),
  ('coffee twenty five thousand', e, 25000, null, null, 'builtin.food', {}),
  ('bought groceries two hundred and fifty thousand', e, 250000, null, null, 'builtin.groceries', {}),
  ('salary 10 million into GoPay', i, 10000000, 'gopay', null, 'builtin.salary', {}),
  ('got paid 3 million', i, 3000000, null, null, null, {}),
  ('transfer 200 thousand from BCA to GoPay', t, 200000, 'bca', 'gopay', null, {}),
  ('taxi 50k paid with cash', e, 50000, 'cash', null, 'builtin.transport', {}),
  ('parking 5000', e, 5000, null, null, 'builtin.transport', {}),
  ('coffee 25 thousand and bread 15 thousand', e, null, null, null, 'builtin.food', {DraftIssue.amountMultiple}),
];

/// Kasus sulit (T-11.9): ucapan sehari-hari, slang, dan susunan yang tidak
/// diajarkan ke aturan. Tidak diuji di CI; benchmark cloud mengukur seberapa
/// jauh aturan dan Gemini benar di sini.
final hardIndonesianCases = <BenchmarkCase>[
  ('tadi bayar parkir sama titip beli bensin totalnya dua puluh lima ribu', e, 25000, null, null, 'builtin.transport', {}),
  ('abis jajan cilok goceng', e, 5000, null, null, 'builtin.food', {}),
  ('nonton bioskop berdua habis seratus dua puluh ribu', e, 120000, null, null, 'builtin.entertainment', {}),
  ('barusan dibayarin klien proyek website tiga juta setengah', i, 3500000, null, null, 'builtin.freelance', {}),
  ('kirim duit ke ibu lima ratus ribu lewat BCA', e, 500000, 'bca', null, 'builtin.family', {}),
  ('pindahin sejuta dari BCA ke cash', t, 1000000, 'bca', 'cash', null, {}),
  ('gopay aku isi lima puluh ribu pakai BCA', t, 50000, 'bca', 'gopay', null, {}),
  ('langganan netflix bulanan seratus lima puluh enam ribu', e, 156000, null, null, 'builtin.entertainment', {}),
  ('beli obat di apotek tiga puluh dua ribu lima ratus', e, 32500, null, null, 'builtin.health', {}),
  ('bayar spp anak satu juta dua ratus ribu', e, 1200000, null, null, 'builtin.education', {}),
  ('dapet transferan bonus dari kantor dua juta ke GoPay', i, 2000000, 'gopay', null, 'builtin.bonus', {}),
  ('ceban buat parkir', e, 10000, null, null, 'builtin.transport', {}),
  ('isi token listrik dua ratus ribu pakai GoPay', e, 200000, 'gopay', null, 'builtin.bills', {}),
  ('makan bareng temen, aku bayar empat puluh lima ribu', e, 45000, null, null, 'builtin.food', {}),
  ('sedekah jumat dua puluh ribu', e, 20000, null, null, 'builtin.donation', {}),
  ('beli kuota internet 75 ribu via gopay', e, 75000, 'gopay', null, 'builtin.internet', {}),
  ('gajian masuk rekening BCA delapan juta', i, 8000000, 'bca', null, 'builtin.salary', {}),
  ('narik tunai dari BCA tiga ratus ribu', t, 300000, 'bca', 'cash', null, {}),
  ('belanja bulanan di supermarket empat ratus ribu', e, 400000, null, null, 'builtin.groceries', {}),
  ('hadiah ulang tahun dari tante seratus ribu', i, 100000, null, null, 'builtin.gift', {}),
  ('grab ke kantor dua puluh tiga ribu bayar pakai gopay', e, 23000, 'gopay', null, 'builtin.transport', {}),
  ('beli baju lebaran tiga ratus lima puluh ribu', e, 350000, null, null, 'builtin.shopping', {}),
  ('bayar wifi indihome tiga ratus tiga puluh ribu', e, 330000, null, null, anyCategory, {}),
  ('patungan kado temen lima puluh ribu', e, 50000, null, null, anyCategory, {}),
  ('jual sepatu bekas laku dua ratus ribu', i, 200000, null, null, anyCategory, {}),
  ('cicilan motor bulan ini satu koma dua juta', e, 1200000, null, null, anyCategory, {}),
  ('tadi pagi sarapan bubur ayam 12rb', e, 12000, null, null, 'builtin.food', {}),
  ('servis motor 150rb cash', e, 150000, 'cash', null, 'builtin.transport', {}),
  ('uang saku dari ortu 1 jt masuk gopay', i, 1000000, 'gopay', null, anyCategory, {}),
  ('kemarin malam makan sate tiga puluh ribu bayar tunai', e, 30000, 'cash', null, 'builtin.food', {}),
];

/// Kasus sulit bahasa Inggris.
final hardEnglishCases = <BenchmarkCase>[
  ('grabbed lunch for 45k with my BCA card', e, 45000, 'bca', null, 'builtin.food', {}),
  ('moved 1 million from BCA to GoPay', t, 1000000, 'bca', 'gopay', null, {}),
  ('client paid me 2.5 million for the logo', i, 2500000, null, null, 'builtin.freelance', {}),
  ('topped up my GoPay with 100 thousand from BCA', t, 100000, 'bca', 'gopay', null, {}),
  ('spent eighty thousand on groceries this morning', e, 80000, null, null, 'builtin.groceries', {}),
];
