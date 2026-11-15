/// Aset ikon clay untuk kategori di halaman Ke mana uang pergi (rupa D6):
/// kategori bawaan lewat kuncinya, kategori buatan pengguna dan lainnya lewat
/// ikon label. Aset sama dengan yang dipakai Analisis dan Riwayat.
String categoryClayAsset(String? builtInKey) {
  final name = switch (builtInKey) {
    'food' => 'bowl_food',
    'groceries' => 'basket_groceries',
    'transport' => 'train_transport',
    'bills' => 'receipt_bills',
    'internet' => 'wifi_internet',
    'health' => 'heart_health',
    'entertainment' => 'headphones_subscription',
    'shopping' => 'bag_shopping',
    'education' => 'cap_education',
    'family' => 'family_people',
    'donation' => 'heart_donation',
    'expenseOther' || 'incomeOther' => 'tray_other',
    'salary' => 'income_arrow',
    'freelance' => 'stylus_freelance',
    'bonus' => 'star_bonus',
    'gift' => 'gift_box',
    _ => 'tag_category',
  };
  return 'assets/icons_clay/$name.svg';
}
