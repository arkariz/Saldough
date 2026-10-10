import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/domain/built_in_categories.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Ikon kategori bawaan per `builtInKey`, persis README design system
/// bagian Ikon. Ikon piksel Keluarga, Donasi, Bonus, Hadiah, dan Lainnya
/// masih draf agen yang menunggu persetujuan pemilik (B-22).
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

/// Ikon yang bisa dipilih pengguna untuk kategori (QA PR #43 F12): ikon
/// piksel kategori, termasuk draf agen B-22 (Keluarga, Donasi, Bonus,
/// Hadiah).
const List<IconKey> categoryIconChoices = [
  IconKey.categoryFood,
  IconKey.categoryCoffee,
  IconKey.categoryGroceries,
  IconKey.categoryTransport,
  IconKey.categoryFuel,
  IconKey.categoryBills,
  IconKey.categoryInternet,
  IconKey.categoryHealth,
  IconKey.categoryEntertainment,
  IconKey.categoryShopping,
  IconKey.categoryEducation,
  IconKey.categoryPets,
  IconKey.categoryEmergencyFund,
  IconKey.categoryInvestment,
  IconKey.income,
  IconKey.freelance,
  IconKey.categoryFamily,
  IconKey.categoryDonation,
  IconKey.categoryBonus,
  IconKey.categoryGift,
  IconKey.categoryOther,
];

/// Nilai `Category.iconKey` yang disimpan saat pengguna memilih [icon] untuk
/// [category]. Kategori bawaan yang kembali ke ikon bawaannya menyimpan
/// kunci bawaannya lagi, supaya ikonnya tetap mengikuti pemetaan bawaan.
String categoryIconKeyFor(Category category, IconKey icon) {
  final builtIn = BuiltInCategories.byKey(category.builtInKey);
  if (builtIn != null && _builtInIcons[builtIn.key] == icon) return builtIn.iconKey;
  return icon.name;
}

/// Ikon [category]: ikon pilihan pengguna (`iconKey` tersimpan yang dikenal;
/// untuk kategori bawaan, yang berbeda dari kunci bawaannya), lalu pemetaan
/// kategori bawaan, lalu tebakan dari namanya ([categoryIconFor]).
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
  final key = category.iconKey;
  // Kategori bawaan disimpan dengan kunci bawaan (sebagian kunci lama, mis.
  // `categoryHousehold` untuk Keluarga); hanya kunci lain yang dipilih
  // pengguna.
  final chosen = builtIn != null && key == BuiltInCategories.byKey(category.builtInKey)?.iconKey ? null : key;
  if (chosen != null) {
    for (final icon in IconKey.values) {
      if (icon.name == chosen) return icon;
    }
  }
  return builtIn ?? categoryIconFor(category.name);
}
