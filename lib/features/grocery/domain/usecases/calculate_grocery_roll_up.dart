import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

/// Menghitung roll-up bulanan dari sebuah [GroceryPlan]. Dart murni, tidak
/// menyentuh penyimpanan — bisa diuji tanpa Flutter (lihat
/// ARCHITECTURE_OVERVIEW.md bagian "Pengujian").
///
/// Rumus dari DOMAIN_MODEL.md:
/// `weeklySubtotal × weeksPerMonth + monthlySubtotal`.
final class CalculateGroceryRollUp {
  /// Menghitung roll-up untuk [plan], dalam sen.
  int call(GroceryPlan plan) {
    final weeklySubtotal = plan.weeklyItems.fold(0, (sum, item) => sum + item.amount);
    final monthlySubtotal = plan.monthlyItems.fold(0, (sum, item) => sum + item.amount);
    return weeklySubtotal * plan.weeksPerMonth + monthlySubtotal;
  }
}
