import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';

/// Bentuk notifikasi yang BUKAN transaksi (ADR-044 §3.4, E1/B-85): dipelajari
/// dari "Bukan transaksi" di kartu, supaya promosi dan pengumuman yang sama
/// tidak muncul lagi. Templat memakai mesin [NotificationTemplate].
final class NegativeShape extends Equatable {
  /// Membuat [NegativeShape].
  const NegativeShape({required this.packageName, required this.template});

  /// Aplikasi sumber.
  final String packageName;

  /// Templat teks: nominal dan angka lain jadi penanda, sisanya literal.
  final String template;

  @override
  List<Object?> get props => [packageName, template];
}

/// Penyimpanan bentuk negatif, urutan sisip dipertahankan.
abstract interface class NegativeShapeStore {
  /// Seluruh bentuk negatif.
  Future<Either<Failure, List<NegativeShape>>> load();

  /// Mengganti seluruh bentuk negatif.
  Future<Either<Failure, Unit>> save(List<NegativeShape> shapes);
}

/// Batas jumlah bentuk negatif; yang tertua dibuang saat penuh.
const negativeShapeLimit = 200;

/// Templat bentuk negatif dari [text]: nominal pertama menjadi
/// [NotificationPattern.amountToken], angka lain [NotificationPattern.anyToken],
/// kata lain tetap literal. `null` bila teks tidak punya nominal terbaca
/// (tidak ada yang bisa dipelajari dengan aman).
String? negativeTemplateFor(String text) {
  final words = NotificationTemplate.words(text);
  final amountIndex = words.indexWhere((w) => NotificationTemplate.isAmountWord(w.text));
  if (amountIndex < 0) return null;
  return NotificationTemplate.fromSample(text, {amountIndex: TemplateWordRole.amount});
}

/// [NegativeShape] di atas [NegativeShapeStore]: dimuat ulang tiap [refresh].
final class StoreBackedNegativeShapes {
  /// Membuat [StoreBackedNegativeShapes].
  StoreBackedNegativeShapes(this._store);

  final NegativeShapeStore _store;
  List<NegativeShape> _shapes = const [];

  /// Memuat bentuk terbaru; dipanggil pemroses sebelum menyaring.
  Future<void> refresh() async {
    _shapes = (await _store.load()).getOrElse((_) => const []);
  }

  /// `true` bila [text] dari [packageName] cocok dengan bentuk negatif.
  bool matches(String packageName, String text) {
    for (final shape in _shapes) {
      if (shape.packageName == packageName && NotificationTemplate.match(shape.template, text) != null) return true;
    }
    return false;
  }

  /// Menambah bentuk dari [text]; mengembalikan fungsi Batalkan, atau `null`
  /// bila tidak ada yang bisa dipelajari dari teks itu.
  Future<Future<void> Function()?> add({required String packageName, required String text}) async {
    final template = negativeTemplateFor(text);
    if (template == null) return null;
    await refresh();
    final shape = NegativeShape(packageName: packageName, template: template);
    if (_shapes.contains(shape)) return () async {};
    final next = [..._shapes, shape];
    while (next.length > negativeShapeLimit) {
      next.removeAt(0);
    }
    await _store.save(next);
    _shapes = next;
    return () async {
      await refresh();
      await _store.save([
        for (final s in _shapes)
          if (s != shape) s,
      ]);
      await refresh();
    };
  }
}
