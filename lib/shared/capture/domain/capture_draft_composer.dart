import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/capture/domain/capture_draft_resolver.dart';
import 'package:saldough/shared/capture/domain/capture_evidence.dart';
import 'package:saldough/shared/capture/domain/interpreted_transaction.dart';
import 'package:saldough/shared/capture/domain/language/capture_language.dart';
import 'package:saldough/shared/capture/domain/record_draft.dart';
import 'package:saldough/shared/capture/domain/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Menyusun [RecordDraft] dari bukti (ADR-029 §3.4): aturan dulu bila bahasa
/// bukti punya paket, cloud bila draf aturan tidak yakin atau bahasanya tidak
/// punya paket.
///
/// Tidak pernah gagal: cloud yang tidak terpasang, galat, atau lewat
/// [cloudTimeout] jatuh ke draf aturan, atau ke draf kosong (transkrip
/// terlihat, nominal disorot) — tanpa pesan galat (ADR-027 §3.5 butir 7).
final class CaptureDraftComposer {
  /// Membuat [CaptureDraftComposer]. [cloudInterpreter] `null` sampai
  /// penyedia cloud terpasang (T-11.7).
  const CaptureDraftComposer({
    required this.ruleInterpreterFor,
    this.cloudInterpreter,
    this.cloudTimeout = const Duration(seconds: 5),
  });

  /// Interpreter aturan untuk satu paket bahasa.
  final TransactionInterpreter Function(CaptureLanguage language) ruleInterpreterFor;

  /// Interpreter cloud, atau `null`.
  final TransactionInterpreter? cloudInterpreter;

  /// Batas waktu jawaban cloud.
  final Duration cloudTimeout;

  /// Draf untuk [evidence] dengan [wallets] aktif, [categories], dan mata
  /// uang [currencyCode]. [cloudText] menggantikan teks bukti yang dikirim ke
  /// cloud (mis. notifikasi yang saldonya disamarkan, ADR-032 §10); kutipan
  /// tetap divalidasi terhadap teks bukti asli.
  Future<RecordDraft> compose(
    CaptureEvidence evidence, {
    required List<Wallet> wallets,
    required List<Category> categories,
    required String currencyCode,
    String? cloudText,
  }) async {
    final language = CaptureLanguages.of(evidence.languageCode);
    final resolver = CaptureDraftResolver(
      wallets: wallets,
      categories: categories,
      currencyCode: currencyCode,
      language: language,
    );
    final context = InterpretationContext(
      walletNames: [for (final w in wallets) w.name],
      expenseCategoryNames: [
        for (final c in categories)
          if (c.kind == CategoryKind.expense && !c.isArchived) c.name,
      ],
      incomeCategoryNames: [
        for (final c in categories)
          if (c.kind == CategoryKind.income && !c.isArchived) c.name,
      ],
      today: evidence.capturedAt,
      currencyCode: currencyCode,
    );

    RecordDraft? ruleDraft;
    if (language != null) {
      final interpreted = await _interpret(ruleInterpreterFor(language), evidence, context);
      if (interpreted != null) ruleDraft = resolver.resolve(evidence, interpreted);
      if (ruleDraft != null && ruleDraft.isConfident) return ruleDraft;
    }

    final cloud = cloudInterpreter;
    if (cloud != null) {
      final cloudEvidence = cloudText == null
          ? evidence
          : CaptureEvidence(
              source: evidence.source,
              text: cloudText,
              capturedAt: evidence.capturedAt,
              languageCode: evidence.languageCode,
              origin: evidence.origin,
            );
      final interpreted = await _interpret(cloud, cloudEvidence, context, timeout: cloudTimeout);
      if (interpreted != null) return resolver.resolve(evidence, interpreted);
    }

    return ruleDraft ?? resolver.resolve(evidence, const InterpretedTransaction());
  }

  /// Hasil [interpreter], atau `null` bila galat, melempar apa pun (termasuk
  /// `Error` dari SDK), atau lewat [timeout].
  Future<InterpretedTransaction?> _interpret(
    TransactionInterpreter interpreter,
    CaptureEvidence evidence,
    InterpretationContext context, {
    Duration? timeout,
  }) async {
    try {
      final pending = interpreter.interpret(evidence, context);
      final result = await (timeout == null ? pending : pending.timeout(timeout));
      return switch (result) {
        Right(:final value) => value,
        Left() => null,
      };
    } on Object {
      return null;
    }
  }
}
