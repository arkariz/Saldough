import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_text.dart';

/// Satu notifikasi yang ditampung layanan native (ADR-032 §3.1), belum
/// ditafsirkan.
final class CapturedNotification extends Equatable {
  /// Membuat [CapturedNotification].
  const CapturedNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.body,
    required this.postedAt,
    this.icon,
  });

  /// Identitas tangkapan (stabil di antrean native).
  final String id;

  /// Paket aplikasi pengirim.
  final String packageName;

  /// Judul notifikasi.
  final String title;

  /// Isi notifikasi (teks panjang bila ada).
  final String body;

  /// Waktu notifikasi diposting.
  final DateTime postedAt;

  /// Ikon notifikasi (logo bank/merchant) atau ikon aplikasi pengirim, PNG.
  final Uint8List? icon;

  /// Teks yang ditafsirkan: judul + isi.
  String get text => NotificationText.combine(title, body);

  @override
  List<Object?> get props => [id, packageName, title, body, postedAt];
}
