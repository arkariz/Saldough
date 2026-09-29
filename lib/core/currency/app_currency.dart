/// Mata uang yang bisa dipilih pengguna (ADR-025 §3.2).
///
/// Nominal selalu disimpan dalam seperseratus satuan utama ("sen"), jadi
/// hanya mata uang dengan paling banyak dua angka desimal yang boleh ada di
/// sini.
enum AppCurrency {
  /// Rupiah; bawaan, dan mata uang seluruh data lama.
  idr(code: 'IDR', symbol: 'Rp', fractionDigits: 0, step: 10000),

  /// Dolar AS.
  usd(code: 'USD', symbol: r'$', fractionDigits: 2, step: 1),

  /// Euro.
  eur(code: 'EUR', symbol: '€', fractionDigits: 2, step: 1),

  /// Pound sterling.
  gbp(code: 'GBP', symbol: '£', fractionDigits: 2, step: 1),

  /// Yen Jepang.
  jpy(code: 'JPY', symbol: '¥', fractionDigits: 0, step: 100),

  /// Yuan Tiongkok.
  cny(code: 'CNY', symbol: 'CN¥', fractionDigits: 2, step: 10),

  /// Won Korea Selatan.
  krw(code: 'KRW', symbol: '₩', fractionDigits: 0, step: 1000),

  /// Rupee India.
  inr(code: 'INR', symbol: '₹', fractionDigits: 2, step: 100),

  /// Dolar Singapura.
  sgd(code: 'SGD', symbol: r'S$', fractionDigits: 2, step: 1),

  /// Ringgit Malaysia.
  myr(code: 'MYR', symbol: 'RM', fractionDigits: 2, step: 5),

  /// Baht Thailand.
  thb(code: 'THB', symbol: '฿', fractionDigits: 2, step: 50),

  /// Peso Filipina.
  php(code: 'PHP', symbol: '₱', fractionDigits: 2, step: 50),

  /// Dong Vietnam.
  vnd(code: 'VND', symbol: '₫', fractionDigits: 0, step: 10000),

  /// Dolar Australia.
  aud(code: 'AUD', symbol: r'A$', fractionDigits: 2, step: 1);

  const AppCurrency({required this.code, required this.symbol, required this.fractionDigits, required this.step});

  /// Kode ISO 4217.
  final String code;

  /// Simbol yang ditulis menempel di depan angka.
  final String symbol;

  /// Jumlah angka desimal saat ditampilkan dan diketik: 0 atau 2.
  final int fractionDigits;

  /// Satu langkah pilihan cepat dalam satuan utama; pilihan cepat adalah
  /// kelipatannya (ADR-025 §3.4). IDR 10.000 menghasilkan daftar lama.
  final int step;

  /// Pilihan cepat dalam sen untuk [multipliers] kali [step].
  List<int> quickAmounts(List<int> multipliers) => [for (final m in multipliers) m * step * 100];

  /// Mata uang dengan [code] (tak peka huruf besar), atau `null`.
  static AppCurrency? fromCode(String code) {
    final upper = code.toUpperCase();
    for (final currency in values) {
      if (currency.code == upper) return currency;
    }
    return null;
  }
}

/// Kelipatan langkah pilihan cepat per konteks (ADR-025 §3.4).
abstract final class QuickAmountMultipliers {
  QuickAmountMultipliers._();

  /// Catat pengeluaran.
  static const expense = [1, 5, 10];

  /// Catat pemasukan dan transfer.
  static const incomeOrTransfer = [50, 100, 500];

  /// Saldo awal dompet.
  static const walletBalance = [10, 50, 100, 500];
}
