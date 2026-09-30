// Port dengan satu metode, diimplementasikan beberapa penyedia (ADR-027).
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';

/// Konteks ringkas untuk interpreter (ADR-027, riset §7): hanya nama, tanpa
/// saldo, riwayat, atau id internal.
final class InterpretationContext extends Equatable {
  /// Membuat [InterpretationContext].
  const InterpretationContext({
    required this.walletNames,
    required this.expenseCategoryNames,
    required this.incomeCategoryNames,
    required this.today,
  });

  /// Nama dompet aktif.
  final List<String> walletNames;

  /// Nama kategori pengeluaran aktif.
  final List<String> expenseCategoryNames;

  /// Nama kategori pemasukan aktif.
  final List<String> incomeCategoryNames;

  /// Tanggal hari ini.
  final DateTime today;

  @override
  List<Object?> get props => [walletNames, expenseCategoryNames, incomeCategoryNames, today];
}

/// Menafsirkan bukti teks menjadi kutipan terstruktur (ADR-027 §3.2).
///
/// Implementasi: berbasis aturan (Dart), model lokal, dan cloud. Domain hanya
/// mengenal antarmuka ini; penyedia diganti lewat registrasi DI.
abstract interface class TransactionInterpreter {
  /// Menafsirkan [evidence] dengan [context].
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  );
}
