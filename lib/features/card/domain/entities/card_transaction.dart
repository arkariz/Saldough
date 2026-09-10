import 'package:dependencies/dependencies.dart';

/// Satu transaksi pada `CardStatement`. Lihat DOMAIN_MODEL.md bagian "Kartu
/// kredit".
final class CardTransaction extends Equatable {
  /// Membuat [CardTransaction].
  const CardTransaction({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    this.note = '',
    this.isConfirmed = true,
  });

  /// Identitas transaksi.
  final String id;

  /// Tanggal transaksi.
  final DateTime date;

  /// Nama merchant — field bersih, terpisah dari [note]. Di spreadsheet
  /// keduanya tercampur sehingga tidak bisa dicocokkan dengan
  /// `RecurringSubscription`; di sini dipisah supaya bisa.
  final String merchant;

  /// Nominal dalam sen.
  final int amount;

  /// Catatan bebas, misalnya `"cicilan 1"` atau `"canceled?"`.
  final String note;

  /// False untuk transaksi hasil penyiapan otomatis dari
  /// `RecurringSubscription` yang belum dikonfirmasi pemilik — nominal
  /// langganan bisa berubah antar siklus (FR-CARD-004), jadi tidak ikut
  /// `CardStatement.confirmedTotal` sampai dikonfirmasi. Bawaan `true` untuk
  /// transaksi yang diketik manual.
  final bool isConfirmed;

  /// Salinan [CardTransaction] dengan field yang disebutkan diganti.
  CardTransaction copyWith({String? merchant, int? amount, String? note, bool? isConfirmed}) {
    return CardTransaction(
      id: id,
      date: date,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  List<Object?> get props => [id, date, merchant, amount, note, isConfirmed];
}
