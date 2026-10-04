import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/utils/clamped_date.dart';

/// Jenis transaksi yang dijadwalkan sebuah rutin. Sama dengan tiga jenis
/// `Transaction`.
enum RecurringKind {
  /// Pemasukan ke satu dompet.
  income,

  /// Pengeluaran dari satu dompet.
  expense,

  /// Pemindahan antar dompet.
  transfer,
}

/// Satuan selang jadwal.
enum RecurringFrequency {
  /// Tiap `interval` minggu sejak tanggal patokan.
  weekly,

  /// Tiap `interval` bulan, pada hari patokan (dijepit ke akhir bulan).
  monthly,

  /// Tiap `interval` tahun, pada bulan dan hari patokan.
  yearly,
}

/// Apakah nominal rutin pasti atau perkiraan.
enum RecurringAmountMode {
  /// Nominal sama tiap kali; boleh dicatat satu ketuk (ADR-035 §3.3).
  fixed,

  /// Nominal berubah (listrik, kos); dikonfirmasi lewat CATAT tiap kali.
  estimated,
}

/// Cara uangnya benar-benar keluar. Aplikasi tidak membayar apa pun; ini
/// hanya menentukan pengingat (ADR-035 §3.8).
enum RecurringPaymentMode {
  /// Ditarik otomatis oleh bank atau penyedia; tanpa pengingat H−n.
  autoDebit,

  /// Pemilik membayar sendiri; diingatkan `remindDaysBefore` hari sebelumnya.
  manual,
}

/// Jadwal sebuah rutin: patokan dan selangnya.
///
/// ⚠ [anchorDay] disimpan terpisah dari [anchorDate]: patokan 31 menghasilkan
/// 28 Feb lalu kembali ke 31 Mar, tidak bergeser permanen ke 28.
final class RecurringSchedule extends Equatable {
  /// Membuat [RecurringSchedule]. [anchorDay] bawaan hari dari [anchorDate].
  RecurringSchedule({
    required this.frequency,
    required DateTime anchorDate,
    this.interval = 1,
    int? anchorDay,
  }) : anchorDate = DateTime(anchorDate.year, anchorDate.month, anchorDate.day),
       anchorDay = anchorDay ?? anchorDate.day,
       assert(interval >= 1, 'Selang jadwal minimal 1.');

  /// Satuan selang.
  final RecurringFrequency frequency;

  /// Kelipatan satuan: 2 + [RecurringFrequency.weekly] = tiap dua minggu.
  final int interval;

  /// Kemunculan pertama (tanpa jam).
  final DateTime anchorDate;

  /// Hari dalam bulan yang dituju jadwal bulanan dan tahunan, 1–31.
  final int anchorDay;

  /// Tanggal kemunculan ke-[n] (mulai 0), tanpa memperhatikan akhir rutin.
  DateTime occurrenceAt(int n) {
    final a = anchorDate;
    return switch (frequency) {
      RecurringFrequency.weekly => DateTime(a.year, a.month, a.day + 7 * interval * n),
      RecurringFrequency.monthly => clampedDate(a.year, a.month + interval * n, anchorDay),
      RecurringFrequency.yearly => clampedDate(a.year + interval * n, a.month, anchorDay),
    };
  }

  @override
  List<Object?> get props => [frequency, interval, anchorDate, anchorDay];
}

/// Kapan sebuah rutin berakhir.
sealed class RecurringEnd extends Equatable {
  const RecurringEnd();
}

/// Tidak pernah berakhir.
final class RecurringNeverEnds extends RecurringEnd {
  /// Membuat [RecurringNeverEnds].
  const RecurringNeverEnds();

  @override
  List<Object?> get props => const [];
}

/// Berakhir pada [date] (inklusif): kemunculan sesudahnya tidak ada.
final class RecurringEndsOn extends RecurringEnd {
  /// Membuat [RecurringEndsOn].
  const RecurringEndsOn(this.date);

  /// Tanggal terakhir yang masih boleh menjadi kemunculan.
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// Berakhir sesudah [count] kemunculan, apa pun statusnya (dilewati ikut
/// terhitung).
final class RecurringEndsAfter extends RecurringEnd {
  /// Membuat [RecurringEndsAfter].
  const RecurringEndsAfter(this.count) : assert(count >= 1, 'Minimal satu kali.');

  /// Jumlah kemunculan.
  final int count;

  @override
  List<Object?> get props => [count];
}

/// Transaksi rutin: **rencana** yang dijadwalkan, bukan transaksi. Membuat,
/// menyunting, menjeda, atau menghapusnya tidak pernah mengubah saldo dompet
/// (invarian 14). Lihat ADR-035 §3.1 dan DOMAIN_MODEL.md bagian "Transaksi
/// rutin".
///
/// Kemunculan dihitung dari [schedule] (`occurrencesOf`), tidak disimpan.
/// Satu-satunya status kemunculan yang disimpan adalah [skippedDates];
/// tercatat dibaca dari `Transaction.recurrence`.
final class RecurringRule extends Equatable {
  /// Membuat [RecurringRule].
  ///
  /// [walletId] adalah dompet transaksi: dompet yang bertambah untuk
  /// pemasukan, yang berkurang untuk pengeluaran, dan dompet asal untuk
  /// transfer. [toWalletId] hanya untuk transfer.
  RecurringRule({
    required this.id,
    required this.kind,
    required this.amount,
    required this.walletId,
    required this.schedule,
    this.amountMode = RecurringAmountMode.fixed,
    this.toWalletId,
    this.categoryId,
    this.note = '',
    this.end = const RecurringNeverEnds(),
    this.paymentMode,
    this.remindDaysBefore = 1,
    this.reminders = true,
    this.autoRecord = false,
    Set<DateTime> skippedDates = const {},
    this.isPaused = false,
    this.budgetItemKey,
  }) : skippedDates = Set.unmodifiable(skippedDates.map(_dateOnly)),
       assert(amount > 0, 'Nominal rutin harus positif.'),
       assert(
         kind == RecurringKind.transfer ? toWalletId != null && toWalletId != walletId : toWalletId == null,
         'Transfer butuh dompet tujuan yang berbeda; jenis lain tidak punya dompet tujuan.',
       ),
       assert(kind != RecurringKind.transfer || categoryId == null, 'Transfer tidak berkategori.'),
       assert(!autoRecord || amountMode == RecurringAmountMode.fixed, 'Catat otomatis hanya untuk nominal tetap.'),
       assert(remindDaysBefore >= 0, 'Hari pengingat tidak boleh negatif.');

  /// Identitas rutin.
  final String id;

  /// Jenis transaksi yang dijadwalkan.
  final RecurringKind kind;

  /// Nominal dalam sen, selalu positif. Untuk [RecurringAmountMode.estimated]
  /// ini perkiraan.
  final int amount;

  /// Pasti atau perkiraan.
  final RecurringAmountMode amountMode;

  /// Dompet transaksi; dompet asal untuk transfer.
  final String walletId;

  /// Dompet tujuan transfer; `null` untuk jenis lain.
  final String? toWalletId;

  /// Kategori pemasukan atau pengeluaran (ADR-026), boleh kosong.
  final String? categoryId;

  /// Nama rutin yang tampil (mis. `Netflix`), juga catatan transaksinya.
  final String note;

  /// Jadwal kemunculan.
  final RecurringSchedule schedule;

  /// Kapan rutin berakhir.
  final RecurringEnd end;

  /// Cara bayar pengeluaran dan transfer; `null` diperlakukan
  /// [RecurringPaymentMode.manual].
  final RecurringPaymentMode? paymentMode;

  /// Pengingat H−n untuk cara bayar manual. Bawaan 1.
  final int remindDaysBefore;

  /// Sakelar pengingat per rutin (ADR-035 §3.8). Pengingat juga butuh
  /// sakelar global di Akun.
  final bool reminders;

  /// Catat otomatis tanpa ketukan (R3). Hanya sah untuk nominal tetap.
  final bool autoRecord;

  /// Tanggal kemunculan yang dilewati pemilik (tanpa jam).
  final Set<DateTime> skippedDates;

  /// Rutin yang dijeda tidak memunculkan kemunculan menunggu.
  final bool isPaused;

  /// R2: `templateItemId` pos anggaran rutin yang ditautkan.
  final String? budgetItemKey;

  /// Cara bayar efektif; `null` dibaca manual.
  RecurringPaymentMode get effectivePaymentMode => paymentMode ?? RecurringPaymentMode.manual;

  /// Salinan dengan field yang disebutkan diganti.
  ///
  /// ⚠ Field opsional (`toWalletId`, `categoryId`, `paymentMode`,
  /// `budgetItemKey`) hanya diganti kalau diisi. Untuk mengosongkannya, buat
  /// [RecurringRule] baru secara langsung.
  RecurringRule copyWith({
    int? amount,
    RecurringAmountMode? amountMode,
    String? walletId,
    String? toWalletId,
    String? categoryId,
    String? note,
    RecurringSchedule? schedule,
    RecurringEnd? end,
    RecurringPaymentMode? paymentMode,
    int? remindDaysBefore,
    bool? reminders,
    bool? autoRecord,
    Set<DateTime>? skippedDates,
    bool? isPaused,
    String? budgetItemKey,
  }) {
    return RecurringRule(
      id: id,
      kind: kind,
      amount: amount ?? this.amount,
      amountMode: amountMode ?? this.amountMode,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      schedule: schedule ?? this.schedule,
      end: end ?? this.end,
      paymentMode: paymentMode ?? this.paymentMode,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      reminders: reminders ?? this.reminders,
      autoRecord: autoRecord ?? this.autoRecord,
      skippedDates: skippedDates ?? this.skippedDates,
      isPaused: isPaused ?? this.isPaused,
      budgetItemKey: budgetItemKey ?? this.budgetItemKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    amount,
    amountMode,
    walletId,
    toWalletId,
    categoryId,
    note,
    schedule,
    end,
    paymentMode,
    remindDaysBefore,
    reminders,
    autoRecord,
    skippedDates,
    isPaused,
    budgetItemKey,
  ];
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
