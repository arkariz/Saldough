import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';

void main() {
  test('sync hanya memberi tahu saat tanggal berganti (T-15.17)', () {
    ActiveDay.sync(DateTime(2026, 10, 5, 23));
    var notified = 0;
    void listener() => notified++;
    ActiveDay.notifier.addListener(listener);
    addTearDown(() => ActiveDay.notifier.removeListener(listener));

    ActiveDay.sync(DateTime(2026, 10, 5, 23, 59));
    expect(notified, 0);

    ActiveDay.sync(DateTime(2026, 10, 6, 0, 1));
    expect(notified, 1);
    expect(ActiveDay.notifier.value, DateTime(2026, 10, 6));
  });
}
