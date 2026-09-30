import 'package:saldough/core/utils/formatters/spoken_amount_parser.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mengubah keluaran interpreter mana pun menjadi [RecordDraft] (ADR-027
/// §3.3). Deterministik dan sama untuk semua penyedia — inilah pagar yang
/// mencegah keluaran model mengarang data:
///
/// - nominal hanya diambil dari frasa yang **benar-benar ada** di teks bukti,
///   lalu dihitung [SpokenAmountParser] dalam `int` sen;
/// - dompet dan kategori hanya dicocokkan ke daftar yang ada, tidak pernah
///   dibuat;
/// - hal yang meragukan menjadi [DraftIssue], bukan tebakan.
final class CaptureDraftResolver {
  /// Membuat [CaptureDraftResolver] untuk [wallets] aktif dan [categories].
  const CaptureDraftResolver({required this.wallets, required this.categories, this.currencyCode = 'IDR'});

  /// Dompet aktif yang boleh dipilih.
  final List<Wallet> wallets;

  /// Seluruh kategori (yang terarsip tidak dipilih).
  final List<Category> categories;

  /// Kode ISO mata uang aplikasi (ADR-025).
  final String currencyCode;

  /// Menyusun draf dari [interpreted] untuk [evidence].
  RecordDraft resolve(CaptureEvidence evidence, InterpretedTransaction interpreted) {
    final kind = interpreted.kind ?? DraftKind.expense;
    final issues = <DraftIssue>{};

    final amountSen = _resolveAmount(evidence.text, interpreted.amountText, issues);

    String? walletId;
    String? toWalletId;
    if (kind == DraftKind.transfer) {
      walletId = _resolveWallet(interpreted.walletText, issues);
      toWalletId = _resolveWallet(interpreted.toWalletText, issues);
      if (walletId != null && walletId == toWalletId) toWalletId = null;
      if (walletId == null) issues.add(DraftIssue.transferSourceMissing);
      if (toWalletId == null) issues.add(DraftIssue.transferTargetMissing);
    } else {
      walletId = _resolveWallet(interpreted.walletText, issues);
    }

    String? categoryId;
    final categoryName = interpreted.categoryName?.trim() ?? '';
    if (kind != DraftKind.transfer && categoryName.isNotEmpty) {
      final categoryKind = kind == DraftKind.income ? CategoryKind.income : CategoryKind.expense;
      final match = matchCategory(categories.where((c) => !c.isArchived), categoryKind, categoryName);
      if (match == null) {
        issues.add(DraftIssue.categoryUnknown);
      } else {
        categoryId = match.id;
      }
    }

    return RecordDraft(
      kind: kind,
      amountSen: amountSen,
      walletId: walletId,
      toWalletId: toWalletId,
      categoryId: categoryId,
      note: interpreted.note?.trim() ?? '',
      date: _resolveDate(evidence, interpreted.dateText),
      issues: issues,
    );
  }

  int? _resolveAmount(String evidenceText, String? amountText, Set<DraftIssue> issues) {
    final phrase = amountText?.trim() ?? '';
    // Kutipan yang tidak ada di teks bukti adalah karangan -- abaikan.
    if (phrase.isEmpty || !_normalize(evidenceText).contains(_normalize(phrase))) {
      issues.add(DraftIssue.amountMissing);
      return null;
    }
    final result = SpokenAmountParser.parse(phrase, currencyCode: currencyCode);
    switch (result.issue) {
      case null:
        return result.sen;
      case SpokenAmountIssue.missing:
        issues.add(DraftIssue.amountMissing);
      case SpokenAmountIssue.multiple:
        issues.add(DraftIssue.amountMultiple);
      case SpokenAmountIssue.withoutUnit:
        issues.add(DraftIssue.amountWithoutUnit);
      case SpokenAmountIssue.ambiguous:
        issues.add(DraftIssue.amountAmbiguous);
      case SpokenAmountIssue.foreignCurrency:
        issues.add(DraftIssue.currencyUnsupported);
    }
    return null;
  }

  String? _resolveWallet(String? spoken, Set<DraftIssue> issues) {
    final text = spoken?.trim() ?? '';
    if (text.isEmpty) return null;
    final wallet = matchWallet(wallets, text);
    if (wallet == null) issues.add(DraftIssue.walletUnknown);
    return wallet?.id;
  }

  DateTime? _resolveDate(CaptureEvidence evidence, String? dateText) {
    final base = evidence.capturedAt;
    final spoken = _normalize(dateText ?? '');
    if (spoken.contains('kemarin lusa')) return base.subtract(const Duration(days: 2));
    if (spoken.contains('kemarin') || spoken.contains('yesterday')) return base.subtract(const Duration(days: 1));
    // Suara dicatat saat diucapkan (tanggal bawaan formulir); notifikasi dan
    // struk memakai waktu buktinya.
    return evidence.source == CaptureSource.voice ? null : base;
  }
}

/// Sinonim dompet tunai: "cash", "tunai", dan "dompet" merujuk dompet yang
/// sama.
const _cashWords = {'cash', 'tunai', 'uang tunai', 'kas', 'dompet'};

/// Dompet di [wallets] yang dirujuk [spoken]: nama sama persis (tanpa beda
/// huruf/spasi), lalu satu-satunya dompet yang namanya memuat atau dimuat
/// sebutan itu sebagai kata utuh, lalu sinonim tunai. `null` kalau tidak ada
/// atau lebih dari satu kandidat -- tidak menebak.
Wallet? matchWallet(List<Wallet> wallets, String spoken) {
  final needle = _normalize(spoken);
  if (needle.isEmpty) return null;
  for (final wallet in wallets) {
    if (_normalize(wallet.name) == needle) return wallet;
  }
  final partial = [
    for (final wallet in wallets)
      if (_containsWord(_normalize(wallet.name), needle) || _containsWord(needle, _normalize(wallet.name))) wallet,
  ];
  if (partial.length == 1) return partial.single;
  if (_cashWords.contains(needle)) {
    final cash = [
      for (final wallet in wallets)
        if (_cashWords.any((w) => _containsWord(_normalize(wallet.name), w)) || wallet.iconKey == 'walletCash') wallet,
    ];
    if (cash.length == 1) return cash.single;
  }
  return null;
}

bool _containsWord(String haystack, String needle) =>
    RegExp('(^|\\s)${RegExp.escape(needle)}(\\s|\$)').hasMatch(haystack);

String _normalize(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
