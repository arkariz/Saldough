part of 'card_bloc.dart';

/// Event [CardBloc].
sealed class CardEvent {
  /// Membuat [CardEvent].
  const CardEvent();
}

/// Memuat daftar kartu dan langganan, memilih kartu pertama.
final class CardOpened extends CardEvent {
  /// Membuat [CardOpened].
  const CardOpened();
}

/// Memilih kartu ber-`id` [cardId] dan memuat siklus tagihannya.
final class CardSelected extends CardEvent {
  /// Membuat [CardSelected].
  const CardSelected(this.cardId);

  /// Identitas kartu.
  final String cardId;
}

/// Menambah atau menyunting sebuah kartu (FR-CARD-001).
final class CreditCardSaved extends CardEvent {
  /// Membuat [CreditCardSaved].
  const CreditCardSaved(this.card);

  /// Kartu yang disimpan.
  final CreditCard card;
}

/// Menghapus kartu ber-`id` [id].
final class CreditCardDeleted extends CardEvent {
  /// Membuat [CreditCardDeleted].
  const CreditCardDeleted(this.id);

  /// Identitas kartu.
  final String id;
}

/// Mencatat transaksi baru pada kartu yang sedang dipilih (FR-CARD-002).
final class CardTransactionAdded extends CardEvent {
  /// Membuat [CardTransactionAdded].
  const CardTransactionAdded({
    required this.date,
    required this.merchant,
    required this.amount,
    this.note = '',
  });

  /// Tanggal transaksi.
  final DateTime date;

  /// Nama merchant.
  final String merchant;

  /// Nominal dalam sen.
  final int amount;

  /// Catatan bebas.
  final String note;
}

/// Mengonfirmasi transaksi hasil penyiapan langganan ber-`id`
/// [transactionId], dengan nominal akhir [amount] (FR-CARD-004).
final class CardTransactionConfirmed extends CardEvent {
  /// Membuat [CardTransactionConfirmed].
  const CardTransactionConfirmed({required this.transactionId, required this.amount});

  /// Identitas transaksi.
  final String transactionId;

  /// Nominal akhir dalam sen, boleh berbeda dari nilai langganan terakhir.
  final int amount;
}

/// Menutup siklus tagihan terbuka kartu yang sedang dipilih (FR-CARD-003).
final class CardStatementClosed extends CardEvent {
  /// Membuat [CardStatementClosed].
  const CardStatementClosed();
}

/// Menambah atau menyunting sebuah langganan (FR-CARD-004).
final class RecurringSubscriptionSaved extends CardEvent {
  /// Membuat [RecurringSubscriptionSaved].
  const RecurringSubscriptionSaved(this.subscription);

  /// Langganan yang disimpan.
  final RecurringSubscription subscription;
}

/// Menghapus langganan ber-`id` [id].
final class RecurringSubscriptionDeleted extends CardEvent {
  /// Membuat [RecurringSubscriptionDeleted].
  const RecurringSubscriptionDeleted(this.id);

  /// Identitas langganan.
  final String id;
}
