import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/period_book/domain/services/tanuki_lines.dart';

/// Merakit [lines] menjadi kalimat Kata Tanuki dalam bahasa aktif (BP-8).
/// Nominal lewat `AppMoneyFormatter`, jadi ikut Sembunyikan nominal (BP-12):
/// nominal tertutup, persen dan kalimat tetap tampil. Persen ditulis tanpa
/// koma (bulat, aturan Analisis).
List<String> tanukiSentences(List<TanukiLine> lines) {
  final texts = t.book.tanuki;
  return [
    for (final line in lines)
      switch (line) {
        TanukiRecords(:final count) => texts.records(n: count, count: count),
        TanukiFlow(:final income, :final expense, :final net) =>
          net >= 0
              ? texts.flow(
                  income: AppMoneyFormatter.format(income),
                  expense: AppMoneyFormatter.format(expense),
                  net: AppMoneyFormatter.format(net),
                )
              : texts.flowNegative(
                  income: AppMoneyFormatter.format(income),
                  expense: AppMoneyFormatter.format(expense),
                  net: AppMoneyFormatter.format(net),
                ),
        TanukiTopCategory(:final name, :final percent) => texts.topCategory(name: name, percent: percent),
        TanukiRecurringClear(:final recorded, :final skipped) =>
          texts.recurringClear(recorded: recorded, skipped: skipped),
        TanukiTidy() => texts.tidy,
      },
  ];
}
