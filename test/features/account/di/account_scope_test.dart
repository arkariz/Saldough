import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/account/di/account_scope.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/category/category.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockCurrency extends Mock implements CurrencyPreferenceRepository {}

class _MockCategory extends Mock implements CategoryRepository {}

class _MockFinancialMonth extends Mock implements FinancialMonthPreferenceRepository {}

class _MockLanguage extends Mock implements LanguagePreferenceRepository {}

void main() {
  test('layar Akun membawa preferensi bulan keuangan dari root (T-15.16)', () {
    final financialMonth = _MockFinancialMonth();
    final parent = GetIt.asNewInstance()
      ..registerSingleton<AuthRepository>(_MockAuth())
      ..registerSingleton<CurrencyPreferenceRepository>(_MockCurrency())
      ..registerSingleton<CategoryRepository>(_MockCategory())
      ..registerSingleton<FinancialMonthPreferenceRepository>(financialMonth)
      ..registerSingleton<ChangeAppLanguage>(ChangeAppLanguage(repository: _MockLanguage()));
    final child = GetIt.asNewInstance();

    AccountScope(parentContainer: parent).bridge(child);

    expect(child<FinancialMonthPreferenceRepository>(), same(financialMonth));
  });
}
