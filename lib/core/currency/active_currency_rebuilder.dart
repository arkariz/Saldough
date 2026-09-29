import 'package:flutter/widgets.dart';
import 'package:saldough/core/currency/active_currency.dart';

/// Membangun ulang seluruh keturunannya saat [ActiveCurrency] berganti
/// (ADR-025 §3.6).
///
/// Formatter nominal dipanggil statis, jadi tidak ada `InheritedWidget` yang
/// bisa memberi tahu layar yang sudah terbuka (termasuk rute di bawah layar
/// Akun). Menandai setiap elemen kotor adalah cara paling sempit untuk itu
/// tanpa mengganti `Navigator` dan kehilangan tumpukan rutenya. Bloc tidak
/// ikut dibuat ulang; hanya `build` yang dijalankan lagi dengan state yang
/// sama.
class ActiveCurrencyRebuilder extends StatefulWidget {
  /// Membuat [ActiveCurrencyRebuilder] di atas [child].
  const ActiveCurrencyRebuilder({required this.child, super.key});

  /// Subpohon yang dibangun ulang.
  final Widget child;

  @override
  State<ActiveCurrencyRebuilder> createState() => _ActiveCurrencyRebuilderState();
}

class _ActiveCurrencyRebuilderState extends State<ActiveCurrencyRebuilder> {
  @override
  void initState() {
    super.initState();
    ActiveCurrency.notifier.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    ActiveCurrency.notifier.removeListener(_rebuildAll);
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
