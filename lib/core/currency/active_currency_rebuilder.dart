import 'package:flutter/widgets.dart';
import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/language/active_language.dart';

/// Membangun ulang seluruh keturunannya saat [ActiveCurrency] berganti
/// (ADR-025 §3.6), [ActiveLanguage] berganti (ADR-028), [AmountVisibility]
/// berganti (ADR-034), atau saat [also] memberi tahu perubahan (daftar kategori,
/// ADR-026 §3.5).
///
/// Formatter nominal dipanggil statis, jadi tidak ada `InheritedWidget` yang
/// bisa memberi tahu layar yang sudah terbuka (termasuk rute di bawah layar
/// Akun). Menandai setiap elemen kotor adalah cara paling sempit untuk itu
/// tanpa mengganti `Navigator` dan kehilangan tumpukan rutenya. Bloc tidak
/// ikut dibuat ulang; hanya `build` yang dijalankan lagi dengan state yang
/// sama.
class ActiveCurrencyRebuilder extends StatefulWidget {
  /// Membuat [ActiveCurrencyRebuilder] di atas [child].
  const ActiveCurrencyRebuilder({required this.child, this.also, super.key});

  /// Subpohon yang dibangun ulang.
  final Widget child;

  /// Nilai statis lain yang dibaca langsung oleh layar (di luar `core`, jadi
  /// diberikan pemanggil), misalnya `ActiveCategories.notifier`.
  final Listenable? also;

  @override
  State<ActiveCurrencyRebuilder> createState() => _ActiveCurrencyRebuilderState();
}

class _ActiveCurrencyRebuilderState extends State<ActiveCurrencyRebuilder> {
  @override
  void initState() {
    super.initState();
    ActiveCurrency.notifier.addListener(_rebuildAll);
    ActiveLanguage.notifier.addListener(_rebuildAll);
    AmountVisibility.notifier.addListener(_rebuildAll);
    widget.also?.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    ActiveCurrency.notifier.removeListener(_rebuildAll);
    ActiveLanguage.notifier.removeListener(_rebuildAll);
    AmountVisibility.notifier.removeListener(_rebuildAll);
    widget.also?.removeListener(_rebuildAll);
    super.dispose();
  }

  void _rebuildAll() {
    void mark(Element element) {
      element
        ..markNeedsBuild()
        ..visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
