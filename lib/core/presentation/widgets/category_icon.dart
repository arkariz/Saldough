import 'package:saldough/core/presentation/widgets/app_icon.dart';

/// Pasangan ikon pixel-art untuk sebuah kategori, dicari dari kata kunci pada
/// namanya.
///
/// Kategori adalah TEKS BEBAS (`PROJECT_GLOSSARY.md` §"Konvensi penamaan"),
/// bukan enum, jadi tidak ada pemetaan pasti -- ini heuristik pencocokan kata
/// kunci (Indonesia dan Inggris, tanpa peduli huruf besar/kecil) dengan
/// cadangan [IconKey.categoryOther]. Urutan daftar menentukan pemenang kalau
/// satu nama cocok dengan beberapa kata kunci: yang lebih spesifik lebih
/// dulu ("Ojek Online" -> transport, bukan belanja online).
IconKey categoryIconFor(String category) {
  final name = category.toLowerCase();
  for (final (icon, keywords) in _rules) {
    if (keywords.any(name.contains)) return icon;
  }
  return IconKey.categoryOther;
}

const List<(IconKey, List<String>)> _rules = [
  (IconKey.categoryEmergencyFund, ['darurat', 'emergency']),
  (IconKey.categoryFuel, ['bensin', 'bbm', 'fuel', 'pertamax', 'pertalite', 'solar']),
  (IconKey.categoryTransport, ['transport', 'ojek', 'gojek', 'grab', 'taksi', 'taxi', 'kereta', 'parkir']),
  (IconKey.categoryElectricity, ['listrik', 'pln', 'electric']),
  (IconKey.categoryInternet, ['internet', 'wifi', 'pulsa', 'kuota']),
  (IconKey.categoryBills, ['tagihan', 'bill', 'cicilan', 'sewa', 'kontrakan']),
  (IconKey.categoryHealth, ['sehat', 'health', 'obat', 'dokter', 'medis', 'apotek', 'pharmacy', 'klinik']),
  (
    IconKey.categoryEducation,
    ['sekolah', 'kuliah', 'kursus', 'education', 'school', 'course', 'tuition', 'buku', 'spp'],
  ),
  (IconKey.categoryPets, ['hewan', 'peliharaan', 'kucing', 'anjing']),
  (IconKey.categoryInvestment, ['invest', 'saham', 'reksa', 'crypto', 'kripto', 'stock', 'emas']),
  (
    IconKey.categoryEntertainment,
    ['hibur', 'entertain', 'game', 'nonton', 'film', 'musik', 'netflix', 'spotify', 'bioskop', 'konser'],
  ),
  (IconKey.categoryFood, ['makan', 'food', 'resto', 'warung', 'lunch', 'dinner', 'sarapan', 'snack', 'jajan']),
  (IconKey.categoryCoffee, ['kopi', 'coffee', 'cafe', 'kafe', 'ngopi']),
  (IconKey.categoryShopping, ['shop', 'mall', 'fashion', 'baju', 'pakaian', 'online']),
  (IconKey.categoryGroceries, ['belanja', 'grocer', 'supermarket', 'sembako', 'pasar', 'market']),
  (
    IconKey.income,
    ['gaji', 'salary', 'bonus', 'penjualan', 'sales', 'hadiah', 'gift', 'honor', 'freelance', 'dividen'],
  ),
];
