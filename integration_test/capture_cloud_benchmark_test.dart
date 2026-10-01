// Laporan benchmark ditulis ke konsol.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';

import '../test/shared/capture/benchmark/capture_benchmark_dataset.dart';

/// Benchmark Catat Cerdas T-11.9 (VOICE_INPUT_RESEARCH.md §10) di perangkat,
/// dengan Gemini sungguhan lewat Firebase AI Logic. Tiga jalur per kasus:
///
/// - **aturan**: interpreter aturan + resolver saja;
/// - **kaskade**: `CaptureDraftComposer` seperti di aplikasi (aturan, Gemini
///   hanya bila ragu, batas waktu 5 dtk);
/// - **Gemini**: Gemini untuk setiap kasus (batas 20 dtk), tetap lewat
///   resolver yang menolak nominal/dompet/kategori karangan.
///
/// Jalankan (token debug App Check perangkat itu harus terdaftar di Console):
///
/// ```bash
/// fvm flutter test integration_test/capture_cloud_benchmark_test.dart -d <perangkat>
/// ```
///
/// Panggilan diberi jarak [_minGap] supaya tidak menabrak batas laju tier
/// gratis; jeda itu tidak dihitung sebagai latensi.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('aturan vs kaskade vs Gemini', () async {
    await Firebase.initializeApp();
    // Penyedia debug seperti build debug aplikasi. `firebase_ai` selalu
    // mengirim token App Check bila pluginnya terpasang -- tanpa penyedia
    // debug, token Play Integrity build sideload ditolak walau penegakan mati.
    await FirebaseAppCheck.instance.activate(providerAndroid: const AndroidDebugProvider());

    final sets = <String, (CaptureLanguage, List<BenchmarkCase>)>{
      'id': (indonesian, indonesianCases),
      'en': (english, englishCases),
      'id-sulit': (indonesian, hardIndonesianCases),
      'en-sulit': (english, hardEnglishCases),
    };
    final cascadeCloud = _Metered(FirebaseAiTransactionInterpreter());
    final directCloud = _Metered(FirebaseAiTransactionInterpreter());
    final composer = CaptureDraftComposer(
      ruleInterpreterFor: (language) =>
          RuleBasedTransactionInterpreter(language: language, categories: () => benchmarkCategories),
      cloudInterpreter: cascadeCloud,
    );
    final context = InterpretationContext(
      walletNames: [for (final w in benchmarkWallets) w.name],
      expenseCategoryNames: [
        for (final c in benchmarkCategories)
          if (c.kind == CategoryKind.expense) c.name,
      ],
      incomeCategoryNames: [
        for (final c in benchmarkCategories)
          if (c.kind == CategoryKind.income) c.name,
      ],
      today: benchmarkNow,
      currencyCode: 'IDR',
    );

    // Satu panggilan uji dulu: gagal di sini = masalah akses, bukan tafsir.
    final probe = await FirebaseAiTransactionInterpreter().interpret(
      CaptureEvidence(source: CaptureSource.voice, text: 'makan 25 ribu', capturedAt: benchmarkNow, languageCode: 'id'),
      context,
    );
    expect(probe.isRight(), isTrue, reason: probe.fold((f) => 'Gemini menolak: ${f.message}', (_) => ''));

    final report = StringBuffer()..writeln('\n=== BENCHMARK T-11.9 (${FirebaseAiTransactionInterpreter.modelName}) ===');
    final details = StringBuffer();
    for (final MapEntry(key: name, value: (language, cases)) in sets.entries) {
      final rules = _Score();
      final cascade = _Score();
      final cloud = _Score();
      final cascadeCallsBefore = cascadeCloud.calls;
      for (final c in cases) {
        final evidence = CaptureEvidence(
          source: CaptureSource.voice,
          text: c.$1,
          capturedAt: benchmarkNow,
          languageCode: language.code,
        );
        final resolver = CaptureDraftResolver(
          wallets: benchmarkWallets,
          categories: benchmarkCategories,
          language: language,
        );
        final ruleDraft = resolver.resolve(
          evidence,
          RuleBasedTransactionInterpreter(
            language: language,
            categories: () => benchmarkCategories,
          ).interpretSync(c.$1, context),
        );
        final cascadeDraft = await composer.compose(
          evidence,
          wallets: benchmarkWallets,
          categories: benchmarkCategories,
          currencyCode: 'IDR',
        );
        final interpreted = await directCloud.interpretWithin(evidence, context, const Duration(seconds: 20));
        final cloudDraft = resolver.resolve(evidence, interpreted ?? const InterpretedTransaction());

        final r = rules.add(c, ruleDraft);
        final k = cascade.add(c, cascadeDraft);
        final g = cloud.add(c, cloudDraft);
        if (!r || !k || !g) {
          details.writeln(
            '[$name] "${c.$1}"  aturan:${r ? 'ok' : _describe(ruleDraft)}  '
            'kaskade:${k ? 'ok' : _describe(cascadeDraft)}  gemini:${g ? 'ok' : _describe(cloudDraft)}',
          );
        }
      }
      report
        ..writeln('\n[$name] ${cases.length} kasus; kaskade memanggil Gemini ${cascadeCloud.calls - cascadeCallsBefore}x')
        ..writeln('           jenis  nominal dompet tujuan kategori SEMUA')
        ..writeln('aturan   ${rules.row()}')
        ..writeln('kaskade  ${cascade.row()}')
        ..writeln('gemini   ${cloud.row()}');
    }
    report
      ..writeln('\nGemini di kaskade: ${cascadeCloud.summary()}')
      ..writeln('Gemini langsung  : ${directCloud.summary()}')
      ..writeln('\n--- kasus yang tidak sempurna ---')
      ..write(details);
    report.toString().split('\n').forEach(print);
    expect(directCloud.ok, greaterThan(0), reason: 'Gemini tidak pernah menjawab: cek token debug App Check');
  }, timeout: const Timeout(Duration(minutes: 40)));
}

String _describe(RecordDraft d) =>
    '{${d.kind.name} ${d.amountSen == null ? '-' : d.amountSen! ~/ 100} ${d.walletId ?? '-'}'
    '${d.toWalletId == null ? '' : '>${d.toWalletId}'} ${d.categoryId?.replaceFirst('builtin.', '') ?? '-'}'
    '${d.issues.isEmpty ? '' : ' ${d.issues.map((i) => i.name).join(',')}'}}';

/// Ketepatan per field.
final class _Score {
  int n = 0;
  int kind = 0;
  int amount = 0;
  int wallet = 0;
  int toWallet = 0;
  int category = 0;
  int categoryN = 0;
  int all = 0;

  /// Mencatat [draft] terhadap harapan [c]; `true` bila semua field benar.
  bool add(BenchmarkCase c, RecordDraft draft) {
    final (_, kind, units, wallet, toWallet, category, _) = c;
    n++;
    final okKind = draft.kind == kind;
    final okAmount = draft.amountSen == (units == null ? null : units * 100);
    final okWallet = draft.walletId == wallet;
    final okTo = draft.toWalletId == toWallet;
    final graded = category != anyCategory;
    final okCategory = !graded || draft.categoryId == category;
    if (okKind) this.kind++;
    if (okAmount) amount++;
    if (okWallet) this.wallet++;
    if (okTo) this.toWallet++;
    if (graded) {
      categoryN++;
      if (okCategory) this.category++;
    }
    final ok = okKind && okAmount && okWallet && okTo && okCategory;
    if (ok) all++;
    return ok;
  }

  String _pct(int x, int of) => of == 0 ? '   -' : '${(100 * x / of).round()}%'.padLeft(4);

  String row() =>
      '  ${_pct(kind, n)}    ${_pct(amount, n)}   ${_pct(wallet, n)}   ${_pct(toWallet, n)}   '
      '${_pct(category, categoryN)}   ${_pct(all, n)}';
}

/// Interpreter cloud yang dihitung: jumlah panggilan, gagal, batas waktu,
/// dan latensi. Panggilan diberi jarak [_minGap].
final class _Metered implements TransactionInterpreter {
  _Metered(this._inner);

  final TransactionInterpreter _inner;
  final latencies = <int>[];
  int calls = 0;
  int ok = 0;
  int failed = 0;
  int timedOut = 0;
  DateTime? _last;

  static const _minGap = Duration(seconds: 4);

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async {
    final last = _last;
    if (last != null) {
      final wait = _minGap - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    calls++;
    final watch = Stopwatch()..start();
    try {
      final result = await _inner.interpret(evidence, context);
      latencies.add(watch.elapsedMilliseconds);
      if (result.isRight()) {
        ok++;
      } else {
        failed++;
        result.fold((f) => print('gagal: ${f.message}'), (_) {});
      }
      return result;
    } finally {
      _last = DateTime.now();
    }
  }

  /// [interpret] dengan batas waktu; `null` bila gagal atau lewat batas.
  Future<InterpretedTransaction?> interpretWithin(
    CaptureEvidence evidence,
    InterpretationContext context,
    Duration timeout,
  ) async {
    try {
      final result = await interpret(evidence, context).timeout(timeout);
      return result.fold<InterpretedTransaction?>((_) => null, (r) => r);
    } on TimeoutException {
      timedOut++;
      return null;
    }
  }

  String summary() {
    final sorted = [...latencies]..sort();
    int p(double q) => sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * q).round()];
    return '$calls panggilan, $ok berhasil, $failed gagal, $timedOut lewat batas; '
        'latensi p50 ${p(0.5)} ms, p95 ${p(0.95)} ms, maks ${sorted.isEmpty ? 0 : sorted.last} ms';
  }
}
