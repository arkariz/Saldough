import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Ikon kategori bawaan per `builtInKey`, persis README design system
/// bagian Ikon. Kategori tanpa ikon piksel (Keluarga, Donasi, Bonus, Hadiah,
/// Lainnya) memakai Material Symbols di tile berwarna (B-22).
const Map<String, IconKey> _builtInIcons = {
  'food': IconKey.categoryFood,
  'groceries': IconKey.categoryGroceries,
  'transport': IconKey.categoryTransport,
  'bills': IconKey.categoryBills,
  'internet': IconKey.categoryInternet,
  'health': IconKey.categoryHealth,
  'entertainment': IconKey.categoryEntertainment,
  'shopping': IconKey.categoryShopping,
  'education': IconKey.categoryEducation,
  'family': IconKey.categoryFamily,
  'donation': IconKey.categoryDonation,
  'expenseOther': IconKey.categoryOther,
  'salary': IconKey.income,
  'freelance': IconKey.freelance,
  'bonus': IconKey.categoryBonus,
  'gift': IconKey.categoryGift,
  'incomeOther': IconKey.categoryOther,
};

/// Kata pada judul transaksi yang memilih ikon lebih spesifik di dalam satu
/// kategori bawaan: "kopi" di Makan & Minum, "bensin" di Transportasi.
const Map<IconKey, (IconKey, List<String>)> _titleVariants = {
  IconKey.categoryFood: (IconKey.categoryCoffee, ['kopi', 'ngopi', 'coffee']),
  IconKey.categoryTransport: (IconKey.categoryFuel, ['bensin', 'bbm', 'pertalite', 'pertamax', 'solar', 'fuel']),
};

/// Ikon [category]: pemetaan kategori bawaan, lalu `iconKey` tersimpan
/// kalau dikenal, lalu tebakan dari namanya ([categoryIconFor]).
///
/// [title] (catatan transaksi) memilih varian: "Kopi susu" di Makan & Minum
/// memakai ikon kopi.
IconKey categoryIcon(Category category, {String? title}) {
  final icon = _baseIcon(category);
  final variant = _titleVariants[icon];
  if (variant != null && title != null) {
    final lower = title.toLowerCase();
    if (variant.$2.any(lower.contains)) return variant.$1;
  }
  return icon;
}

IconKey _baseIcon(Category category) {
  final builtIn = _builtInIcons[category.builtInKey];
  if (builtIn != null) return builtIn;
  final key = category.iconKey;
  if (key != null) {
    for (final icon in IconKey.values) {
      if (icon.name == key) return icon;
    }
  }
  return categoryIconFor(category.name);
}
