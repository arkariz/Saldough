import 'package:dependencies/dependencies.dart';

/// Entitas contoh — bukan fitur produk nyata.
///
/// `example_note` adalah fitur bukti pola untuk T-1.12: menunjukkan entitas,
/// repository, bloc berefek, rute, dan lingkup dependensi bekerja sama dari
/// ujung ke ujung sebelum fitur sungguhan (Fase 2 dst.) ditulis. Jangan
/// dikembangkan jadi fitur produk — hapus kalau sudah tidak relevan sebagai
/// referensi.
final class ExampleNote extends Equatable {
  /// Membuat [ExampleNote].
  const ExampleNote({required this.id, required this.text});

  /// Identitas catatan.
  final String id;

  /// Isi catatan.
  final String text;

  @override
  List<Object?> get props => [id, text];
}
