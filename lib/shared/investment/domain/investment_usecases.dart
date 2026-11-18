import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/investment/domain/instrument_position.dart';
import 'package:saldough/shared/investment/domain/instrument_summary.dart';
import 'package:saldough/shared/investment/domain/investment_repository.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kode [ValidationFailure] investasi (ADR-049 §3.6, §3.7, §3.12).
abstract final class InvestmentFailures {
  /// Nama instrumen kosong.
  static const nameRequired = FailureCode('INSTRUMENT_NAME_REQUIRED');

  /// Jumlah atau nominal tidak positif.
  static const notPositive = FailureCode('INVESTMENT_NOT_POSITIVE');

  /// Penjualan melebihi jumlah yang dimiliki, atau perubahan yang membuat
  /// posisi negatif.
  static const insufficientQuantity = FailureCode('INVESTMENT_INSUFFICIENT_QUANTITY');

  /// Instrumen masih punya catatan beli/jual, jadi tidak bisa dihapus.
  static const hasRecords = FailureCode('INSTRUMENT_HAS_RECORDS');

  /// Jenis tidak bisa diubah sesudah ada aktivitas.
  static const typeLocked = FailureCode('INSTRUMENT_TYPE_LOCKED');

  /// Batas instrumen Aktif Gratis tercapai (P12).
  static const limitReached = FailureCode('INSTRUMENT_LIMIT_REACHED');
}

Either<Failure, T> _invalid<T>(FailureCode code, String message) =>
    left(ValidationFailure(code: code, message: message));

/// Ringkasan semua instrumen dari penyimpanan (layar Investasi, lapis
/// Investasi Total aset, batas Gratis).
final class LoadInstrumentSummaries {
  /// Membuat [LoadInstrumentSummaries].
  const LoadInstrumentSummaries({required this.investments, required this.transactions});

  /// Instrumen dan valuasi.
  final InvestmentRepository investments;

  /// Buku besar, sumber beli/jual.
  final TransactionRepository transactions;

  /// Ringkasan per instrumen, urut dibuat.
  Future<Either<Failure, List<InstrumentSummary>>> call() async {
    final instruments = await investments.listInstruments();
    if (instruments case Left(value: final f)) return left(f);
    final list = instruments.getOrElse((_) => const []);
    if (list.isEmpty) return right(const []);
    final valuations = await investments.listValuations();
    if (valuations case Left(value: final f)) return left(f);
    final ledger = await transactions.listAllTransactions();
    if (ledger case Left(value: final f)) return left(f);
    final trades = [for (final t in ledger.getOrElse((_) => const [])) if (t is InvestmentTransaction) t];
    final vals = valuations.getOrElse((_) => const []);
    return right([for (final i in list) InstrumentSummary.of(i, trades, vals)]);
  }
}

/// [InvestmentLedgerGuard] yang memutar ulang instrumen terdampak dengan
/// perubahan yang diusulkan (ADR-049 §3.6).
final class InvestmentPositionGuard implements InvestmentLedgerGuard {
  /// Membuat [InvestmentPositionGuard].
  const InvestmentPositionGuard({required this.investments, required this.transactions});

  /// Instrumen (untuk kepemilikan awal).
  final InvestmentRepository investments;

  /// Buku besar saat ini.
  final TransactionRepository transactions;

  @override
  Future<Either<Failure, Unit>> check({Transaction? next, Transaction? previous}) async {
    final affected = {
      if (next case InvestmentTransaction(:final instrumentId)) instrumentId,
      if (previous case InvestmentTransaction(:final instrumentId)) instrumentId,
    };
    if (affected.isEmpty) return right(unit);
    if (next case InvestmentTransaction(:final quantity, :final amount) when quantity <= 0 || amount <= 0) {
      return _invalid(InvestmentFailures.notPositive, 'Jumlah dan nominal harus lebih dari nol.');
    }
    final instruments = await investments.listInstruments();
    if (instruments case Left(value: final f)) return left(f);
    final ledger = await transactions.listAllTransactions();
    if (ledger case Left(value: final f)) return left(f);
    final removedId = previous?.id;
    final proposed = [
      for (final t in ledger.getOrElse((_) => const []))
        if (t is InvestmentTransaction && t.id != removedId && t.id != next?.id) t,
      ?next,
    ];
    final byId = {for (final i in instruments.getOrElse((_) => const [])) i.id: i};
    for (final id in affected) {
      final instrument = byId[id] ?? Instrument(id: id, name: '', type: InstrumentType.other, createdAt: DateTime(0));
      if (!InstrumentPosition.replay(instrument, proposed).isValid) {
        return _invalid(InvestmentFailures.insufficientQuantity, 'Jumlah yang dijual melebihi yang dimiliki.');
      }
    }
    return right(unit);
  }
}

/// Membuat instrumen baru dari Investasi › Tambah investasi (ADR-049 §3.7
/// pintu 1). Tidak menyentuh dompet. [activeLimit] `null` = Plus.
final class CreateInstrument {
  /// Membuat [CreateInstrument].
  const CreateInstrument({required this.investments, required this.summaries});

  /// Penyimpanan instrumen.
  final InvestmentRepository investments;

  /// Ringkasan untuk menghitung instrumen Aktif.
  final LoadInstrumentSummaries summaries;

  /// Menyimpan [instrument], atau menolak dengan [InvestmentFailures].
  Future<Either<Failure, Unit>> call(Instrument instrument, {int? activeLimit}) async {
    final name = instrument.name.trim();
    if (name.isEmpty) return _invalid(InvestmentFailures.nameRequired, 'Nama instrumen kosong.');
    if (activeLimit != null) {
      final current = await summaries();
      if (current case Left(value: final f)) return left(f);
      if (activeInstrumentCount(current.getOrElse((_) => const [])) >= activeLimit) {
        return _invalid(InvestmentFailures.limitReached, 'Batas instrumen aktif tercapai.');
      }
    }
    return investments.saveInstrument(instrument.copyWith(name: name));
  }
}

/// Mengubah nama, kode, atau kepemilikan awal instrumen (ADR-049 §3.1, §3.6).
final class UpdateInstrument {
  /// Membuat [UpdateInstrument].
  const UpdateInstrument({required this.investments, required this.transactions});

  /// Penyimpanan instrumen.
  final InvestmentRepository investments;

  /// Buku besar.
  final TransactionRepository transactions;

  /// Menyimpan [instrument] menggantikan versi lamanya.
  Future<Either<Failure, Unit>> call(Instrument instrument) async {
    final name = instrument.name.trim();
    if (name.isEmpty) return _invalid(InvestmentFailures.nameRequired, 'Nama instrumen kosong.');
    final instruments = await investments.listInstruments();
    if (instruments case Left(value: final f)) return left(f);
    final old = instruments.getOrElse((_) => const []).where((i) => i.id == instrument.id).firstOrNull;
    final ledger = await transactions.listAllTransactions();
    if (ledger case Left(value: final f)) return left(f);
    final trades = [
      for (final t in ledger.getOrElse((_) => const []))
        if (t is InvestmentTransaction && t.instrumentId == instrument.id) t,
    ];
    if (old != null && old.type != instrument.type) {
      final valuations = await investments.listValuations();
      if (valuations case Left(value: final f)) return left(f);
      final valued = valuations.getOrElse((_) => const []).any((v) => v.instrumentId == instrument.id);
      if (old.opening != null || trades.isNotEmpty || valued) {
        return _invalid(InvestmentFailures.typeLocked, 'Jenis tidak bisa diubah sesudah ada catatan.');
      }
    }
    if (!InstrumentPosition.replay(instrument, trades).isValid) {
      return _invalid(InvestmentFailures.insufficientQuantity, 'Jumlah yang dijual melebihi yang dimiliki.');
    }
    return investments.saveInstrument(instrument.copyWith(name: name));
  }
}

/// Menghapus instrumen yang tidak punya catatan beli/jual, beserta valuasinya
/// (ADR-049 §3.7).
final class DeleteInstrument {
  /// Membuat [DeleteInstrument].
  const DeleteInstrument({required this.investments, required this.transactions});

  /// Penyimpanan instrumen.
  final InvestmentRepository investments;

  /// Buku besar.
  final TransactionRepository transactions;

  /// Menghapus instrumen [id], atau menolak dengan
  /// [InvestmentFailures.hasRecords].
  Future<Either<Failure, Unit>> call(String id) async {
    final ledger = await transactions.listAllTransactions();
    if (ledger case Left(value: final f)) return left(f);
    final referenced = ledger.getOrElse((_) => const []).any((t) => t is InvestmentTransaction && t.instrumentId == id);
    if (referenced) {
      return _invalid(InvestmentFailures.hasRecords, 'Hapus dulu catatan beli/jual instrumen ini di Riwayat.');
    }
    return investments.deleteInstrument(id);
  }
}

/// Mencatat beli/jual dari CATAT (ADR-049 §3.3, §3.7 pintu 2). Instrumen baru
/// ([newInstrument]) disimpan bersama transaksinya: bila transaksi gagal,
/// instrumen baru dihapus lagi. Membeli lagi instrumen Selesai tunduk
/// [activeLimit] (§3.12); `null` = Plus.
final class RecordInvestment {
  /// Membuat [RecordInvestment].
  const RecordInvestment({required this.recordTransaction, required this.create, required this.summaries});

  /// Jalur tunggal pencatatan transaksi (aturan 8).
  final RecordTransaction recordTransaction;

  /// Pembuat instrumen (memeriksa nama dan batas).
  final CreateInstrument create;

  /// Ringkasan untuk memeriksa batas saat membeli lagi.
  final LoadInstrumentSummaries summaries;

  /// Mencatat [transaction]; [previous] diisi saat menyunting.
  Future<Either<Failure, Unit>> call(
    InvestmentTransaction transaction, {
    Instrument? newInstrument,
    InvestmentTransaction? previous,
    int? activeLimit,
    Object? source,
  }) async {
    if (newInstrument != null) {
      final created = await create(newInstrument, activeLimit: activeLimit);
      if (created case Left(value: final f)) return left(f);
      final recorded = await recordTransaction(transaction, source: source);
      if (recorded case Left(value: final f)) {
        await create.investments.deleteInstrument(newInstrument.id);
        return left(f);
      }
      return recorded;
    }
    if (activeLimit != null && transaction.side == InvestmentSide.buy && previous == null) {
      final current = await summaries();
      if (current case Left(value: final f)) return left(f);
      final all = current.getOrElse((_) => const []);
      final target = all.where((s) => s.instrument.id == transaction.instrumentId).firstOrNull;
      if (target != null && !target.position.isActive && activeInstrumentCount(all) >= activeLimit) {
        return _invalid(InvestmentFailures.limitReached, 'Batas instrumen aktif tercapai.');
      }
    }
    return recordTransaction(transaction, previousTransaction: previous, source: source);
  }
}

/// Menyimpan valuasi satu atau banyak instrumen sekaligus (ADR-049 §3.4,
/// §3.11).
final class SaveValuations {
  /// Membuat [SaveValuations].
  const SaveValuations({required this.investments});

  /// Penyimpanan valuasi.
  final InvestmentRepository investments;

  /// Menyimpan [valuations] dalam satu tulis.
  Future<Either<Failure, Unit>> call(List<InstrumentValuation> valuations) async {
    if (valuations.any((v) => v.unitPrice <= 0)) {
      return _invalid(InvestmentFailures.notPositive, 'Harga harus lebih dari nol.');
    }
    return investments.saveValuations(valuations);
  }
}
