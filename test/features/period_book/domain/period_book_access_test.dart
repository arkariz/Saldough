import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/period_book/domain/services/period_book_access.dart';

/// BP-1 dan BP-10: gerbang buku.
void main() {
  test('Plus aktif: buku apa pun terbuka', () {
    expect(bookAccessOf(plusActive: true, everOpened: false), BookAccess.open);
    expect(bookAccessOf(plusActive: true, everOpened: true), BookAccess.open);
  });

  test('Plus berakhir: yang pernah dibuka tetap terbuka (BP-10)', () {
    expect(bookAccessOf(plusActive: false, everOpened: true), BookAccess.open);
  });

  test('Gratis: buku yang belum pernah dibuka terkunci', () {
    expect(bookAccessOf(plusActive: false, everOpened: false), BookAccess.locked);
  });
}
