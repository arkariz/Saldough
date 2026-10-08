import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';

/// Pemetaan ikon kategori persis README design system bagian Ikon (ADR-034).
void main() {
  Category builtIn(
    String key, {
    CategoryKind kind = CategoryKind.expense,
    String? iconKey,
  }) => Category(
    id: 'builtin.$key',
    kind: kind,
    name: key,
    builtInKey: key,
    iconKey: iconKey,
  );

  test('kategori bawaan berikon piksel', () {
    const expected = {
      'food': IconKey.categoryFood,
      'groceries': IconKey.categoryGroceries,
      'transport': IconKey.categoryTransport,
      'bills': IconKey.categoryBills,
      'internet': IconKey.categoryInternet,
      'health': IconKey.categoryHealth,
      'entertainment': IconKey.categoryEntertainment,
      'shopping': IconKey.categoryShopping,
      'education': IconKey.categoryEducation,
      'salary': IconKey.income,
      'freelance': IconKey.freelance,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      final icon = categoryIcon(builtIn(key));
      expect(icon, value, reason: key);
      expect(isPixelIcon(icon), isTrue, reason: key);
    }
  });

  test('kategori bawaan tanpa ikon piksel memakai Material Symbols (B-22)', () {
    const expected = {
      'family': IconKey.categoryFamily,
      'donation': IconKey.categoryDonation,
      'bonus': IconKey.categoryBonus,
      'gift': IconKey.categoryGift,
      'expenseOther': IconKey.categoryOther,
      'incomeOther': IconKey.categoryOther,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      final icon = categoryIcon(builtIn(key));
      expect(icon, value, reason: key);
      expect(isPixelIcon(icon), isFalse, reason: key);
    }
  });

  test('pemetaan bawaan menang atas iconKey lama yang tersimpan', () {
    // Data lama menyimpan `income` untuk Freelance/Bonus dan
    // `categoryHousehold` untuk Keluarga.
    expect(
      categoryIcon(
        builtIn('freelance', kind: CategoryKind.income, iconKey: 'income'),
      ),
      IconKey.freelance,
    );
    expect(
      categoryIcon(builtIn('family', iconKey: 'categoryHousehold')),
      IconKey.categoryFamily,
    );
  });

  test(
    'judul memilih varian: kopi di Makan & Minum, bensin di Transportasi',
    () {
      expect(
        categoryIcon(builtIn('food'), title: 'Kopi susu'),
        IconKey.categoryCoffee,
      );
      expect(
        categoryIcon(builtIn('food'), title: 'Makan siang'),
        IconKey.categoryFood,
      );
      expect(
        categoryIcon(builtIn('transport'), title: 'Isi bensin'),
        IconKey.categoryFuel,
      );
      expect(
        categoryIcon(builtIn('health'), title: 'kopi'),
        IconKey.categoryHealth,
      );
    },
  );

  test(
    'kategori buatan pengguna: iconKey tersimpan, lalu tebakan dari nama',
    () {
      const own = Category(
        id: 'u1',
        kind: CategoryKind.expense,
        name: 'Langganan',
        iconKey: 'categoryInternet',
      );
      expect(categoryIcon(own), IconKey.categoryInternet);
      const guessed = Category(
        id: 'u2',
        kind: CategoryKind.expense,
        name: 'Ngopi pagi',
      );
      expect(categoryIcon(guessed), IconKey.categoryCoffee);
      const unknown = Category(
        id: 'u3',
        kind: CategoryKind.expense,
        name: 'Xyzzy',
      );
      expect(categoryIcon(unknown), IconKey.categoryOther);
    },
  );
}
