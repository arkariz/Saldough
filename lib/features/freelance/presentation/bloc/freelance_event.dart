part of 'freelance_bloc.dart';

/// Event [FreelanceBloc].
sealed class FreelanceEvent {
  /// Membuat [FreelanceEvent].
  const FreelanceEvent();
}

/// Memuat proyek, worklog, pembayaran, dan dompet untuk pertama kali (atau
/// lewat "Coba lagi").
final class FreelanceStarted extends FreelanceEvent {
  /// Membuat [FreelanceStarted].
  const FreelanceStarted();
}

/// Menambah proyek baru (FR-FRL-001). `id` diberikan bloc.
final class FreelanceProjectAdded extends FreelanceEvent {
  /// Membuat [FreelanceProjectAdded].
  const FreelanceProjectAdded({required this.name, required this.hourlyRate, required this.deductionRules});

  /// Nama klien atau proyek.
  final String name;

  /// Tarif per jam bawaan, sen.
  final int hourlyRate;

  /// Potongan bawaan.
  final List<DeductionRule> deductionRules;
}

/// Menimpa proyek yang sudah ada. Entri dan pembayaran lama tidak berubah,
/// karena tarif dan potongannya sudah disalin (ADR-019).
final class FreelanceProjectEdited extends FreelanceEvent {
  /// Membuat [FreelanceProjectEdited].
  const FreelanceProjectEdited(this.project);

  /// Proyek hasil sunting.
  final FreelanceProject project;
}

/// Menghapus proyek yang belum punya entri (ADR-019).
final class FreelanceProjectDeleted extends FreelanceEvent {
  /// Membuat [FreelanceProjectDeleted].
  const FreelanceProjectDeleted(this.project);

  /// Proyek yang dihapus.
  final FreelanceProject project;
}

/// Mencatat entri worklog baru (FR-FRL-002). Tidak menyentuh saldo.
final class FreelanceEntryAdded extends FreelanceEvent {
  /// Membuat [FreelanceEntryAdded].
  const FreelanceEntryAdded({
    required this.projectId,
    required this.date,
    required this.hours,
    required this.hourlyRate,
    this.note,
  });

  /// Proyek yang dikerjakan.
  final String projectId;

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// Tarif per jam, sen.
  final int hourlyRate;

  /// Catatan opsional.
  final String? note;
}

/// Menimpa entri yang belum ditagihkan.
final class FreelanceEntryEdited extends FreelanceEvent {
  /// Membuat [FreelanceEntryEdited].
  const FreelanceEntryEdited(this.entry);

  /// Entri hasil sunting.
  final WorklogEntry entry;
}

/// Menghapus entri yang belum ditagihkan.
final class FreelanceEntryDeleted extends FreelanceEvent {
  /// Membuat [FreelanceEntryDeleted].
  const FreelanceEntryDeleted(this.entry);

  /// Entri yang dihapus.
  final WorklogEntry entry;
}

/// Mengelompokkan entri satu proyek jadi pembayaran tertunda (FR-FRL-003).
/// Potongan disalin dari proyek (ADR-019).
final class FreelancePaymentCreated extends FreelanceEvent {
  /// Membuat [FreelancePaymentCreated].
  const FreelancePaymentCreated({required this.projectId, required this.entryIds, required this.expectedDate});

  /// Proyek yang ditagihkan.
  final String projectId;

  /// Entri yang ditagihkan, semuanya belum ditagihkan dan dari [projectId].
  final List<String> entryIds;

  /// Perkiraan tanggal diterima.
  final DateTime expectedDate;
}

/// Mengganti tanggal perkiraan pembayaran tertunda.
final class FreelancePaymentDateChanged extends FreelanceEvent {
  /// Membuat [FreelancePaymentDateChanged].
  const FreelancePaymentDateChanged(this.payment, this.expectedDate);

  /// Pembayaran yang diubah.
  final FreelancePayment payment;

  /// Tanggal perkiraan baru.
  final DateTime expectedDate;
}

/// Menghapus pembayaran tertunda; entrinya kembali belum ditagihkan.
final class FreelancePaymentDeleted extends FreelanceEvent {
  /// Membuat [FreelancePaymentDeleted].
  const FreelancePaymentDeleted(this.payment);

  /// Pembayaran yang dihapus.
  final FreelancePayment payment;
}

/// Mencatat pembayaran diterima (FR-FRL-004): satu transaksi pemasukan
/// sebesar gaji bersih ke [walletId].
final class FreelancePaymentReceived extends FreelanceEvent {
  /// Membuat [FreelancePaymentReceived].
  const FreelancePaymentReceived({
    required this.payment,
    required this.walletId,
    required this.date,
    required this.note,
  });

  /// Pembayaran yang diterima.
  final FreelancePayment payment;

  /// Dompet tujuan.
  final String walletId;

  /// Tanggal diterima.
  final DateTime date;

  /// Catatan transaksi pemasukannya.
  final String note;
}

/// Membatalkan penerimaan: transaksinya dihapus, pembayaran kembali
/// tertunda (ADR-019).
final class FreelanceReceiptCancelled extends FreelanceEvent {
  /// Membuat [FreelanceReceiptCancelled].
  const FreelanceReceiptCancelled(this.payment);

  /// Pembayaran yang dibatalkan penerimaannya.
  final FreelancePayment payment;
}
