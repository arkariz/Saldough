import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/shared/capture/domain/capture_evidence.dart';
import 'package:saldough/shared/capture/domain/interpreted_transaction.dart';
import 'package:saldough/shared/capture/domain/transaction_interpreter.dart';

/// Kode galat saat jatah tafsir cerdas habis.
const quotaExhaustedCode = FailureCode('CAPTURE_QUOTA_EXHAUSTED');

/// Membatasi [inner] (tafsir cloud) dengan jatah tafsir cerdas (ADR-041 §3.7,
/// KT-P14): Gratis [EntitlementLimits.freeSmartInterpretations] per periode
/// keuangan, Plus sampai batas wajarnya per bulan; jatah dipakai bersama
/// suara, notifikasi, dan (kelak) foto struk lewat satu kunci
/// [PlusFeature.smartInterpretation].
///
/// Jatah habis mengembalikan `Left`, sehingga `CaptureDraftComposer` jatuh ke
/// hasil aturan: pencatatan tidak pernah gagal karenanya. Jatah diambil
/// sebelum memanggil [inner] dan dikembalikan bila hasilnya galat atau
/// melempar, jadi hanya tafsir yang berhasil yang menghabiskannya.
final class QuotaGatedInterpreter implements TransactionInterpreter {
  /// Membuat [QuotaGatedInterpreter].
  const QuotaGatedInterpreter({required this.inner, required this.entitlements});

  /// Penafsir cloud yang dibatasi.
  final TransactionInterpreter inner;

  /// Hak dan jatah.
  final Entitlements entitlements;

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async {
    if (!await entitlements.tryUse(PlusFeature.smartInterpretation)) {
      return left(const SystemFailure(code: quotaExhaustedCode, message: 'jatah tafsir cerdas habis'));
    }
    try {
      final result = await inner.interpret(evidence, context);
      if (result.isLeft()) await entitlements.refund(PlusFeature.smartInterpretation);
      return result;
    } on Object {
      await entitlements.refund(PlusFeature.smartInterpretation);
      rethrow;
    }
  }
}
