import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/category_icon.dart';

void main() {
  group('categoryIconFor', () {
    test('mencocokkan kata kunci Indonesia tanpa peduli huruf besar/kecil', () {
      expect(categoryIconFor('Makan Siang & Es Teh'), IconKey.categoryFood);
      expect(categoryIconFor('TAGIHAN LISTRIK PLN'), IconKey.categoryElectricity);
      expect(categoryIconFor('Belanja Mingguan Supermarket'), IconKey.categoryGroceries);
      expect(categoryIconFor('Gaji Bulanan'), IconKey.income);
      expect(categoryIconFor('Bonus Kinerja Proyek Mini'), IconKey.income);
    });

    test('mencocokkan kata kunci Inggris', () {
      expect(categoryIconFor('Groceries'), IconKey.categoryGroceries);
      expect(categoryIconFor('Coffee'), IconKey.categoryCoffee);
      expect(categoryIconFor('Health'), IconKey.categoryHealth);
    });

    test('kata kunci yang lebih spesifik menang atas yang lebih umum', () {
      // "Online" cocok dengan belanja online, tapi ojek online adalah transport.
      expect(categoryIconFor('Ojek Online Kantor'), IconKey.categoryTransport);
      expect(categoryIconFor('Belanja Online'), IconKey.categoryShopping);
      // "Tagihan" umum, tapi "Tagihan Internet" adalah internet.
      expect(categoryIconFor('Tagihan Internet'), IconKey.categoryInternet);
      expect(categoryIconFor('Tagihan'), IconKey.categoryBills);
    });

    test('kata kunci pendek tidak cocok tanpa sengaja di dalam kata lain', () {
      expect(categoryIconFor('Business Lunch'), IconKey.categoryFood);
      expect(categoryIconFor('Petrol Station'), IconKey.categoryOther);
    });

    test('nama tak dikenal jatuh ke ikon "lainnya", bukan melempar', () {
      expect(categoryIconFor('Xyzzy'), IconKey.categoryOther);
      expect(categoryIconFor(''), IconKey.categoryOther);
    });
  });
}
