import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Data satu slide status di Beranda ("perlu dicek"): ringkasan satu baris
/// yang membuka layar lain. Slide tidak membawa aksi pencatatan sendiri:
/// mencatat selalu lewat CATAT atau layar tujuannya (aturan 8).
@immutable
class DsStatusSlideData {
  /// Membuat data slide.
  const DsStatusSlideData({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.attention = false,
    this.order = 0,
  });

  /// Pengenal tetap sumbernya (`notification`, `recurring`, `reminder`).
  final String id;

  /// Ikon tile.
  final IconData icon;

  /// Judul satu baris.
  final String title;

  /// Keterangan satu baris.
  final String subtitle;

  /// Teks tombol di kanan; `null` tanpa tombol.
  final String? actionLabel;

  /// Dipanggil saat tombol atau slide diketuk.
  final VoidCallback? onAction;

  /// Perlu dicek sekarang: latar kuning dan tampil lebih dulu.
  final bool attention;

  /// Urutan di antara slide sejenis (kecil dulu).
  final int order;

  /// Sama dalam hal yang terlihat. [onAction] sengaja tidak dibandingkan:
  /// penutupnya dibuat ulang tiap bangun tetapi tidak mengubah tampilan.
  bool sameAppearance(DsStatusSlideData other) =>
      id == other.id &&
      icon == other.icon &&
      title == other.title &&
      subtitle == other.subtitle &&
      actionLabel == other.actionLabel &&
      attention == other.attention &&
      order == other.order;
}

/// Papan tempat tiap sumber status melapor ([report]) dan carousel status
/// membaca [slides]. Dimiliki satu layar (Beranda); sumbernya adalah widget
/// tanpa tampilan di fitur masing-masing (`DsStatusReport`), sehingga data
/// dan logikanya tetap di fitur dan Beranda tidak mengimpor fitur lain.
class DsStatusBoard extends ChangeNotifier {
  final Map<String, DsStatusSlideData> _slides = {};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Slide aktif: yang perlu dicek dulu, lalu menurut `order`, lalu `id`.
  List<DsStatusSlideData> get slides => [..._slides.values]
    ..sort((a, b) {
      if (a.attention != b.attention) return a.attention ? -1 : 1;
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });

  /// Melapor data terbaru sumber [id]; `null` mencabutnya. Pendengar hanya
  /// dibangunkan bila tampilan berubah. Aman dipanggil saat membangun:
  /// pemberitahuan ditunda ke sesudah bingkai.
  void report(String id, DsStatusSlideData? data) {
    if (_disposed) return;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle || binding.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      _apply(id, data);
    } else {
      binding.addPostFrameCallback((_) => _apply(id, data));
    }
  }

  void _apply(String id, DsStatusSlideData? data) {
    // Pelaporan tertunda bisa tiba sesudah papan dibuang (layar ditutup).
    if (_disposed) return;
    final old = _slides[id];
    if (data == null) {
      if (_slides.remove(id) != null) notifyListeners();
      return;
    }
    _slides[id] = data;
    if (old == null || !old.sameAppearance(data)) notifyListeners();
  }
}

/// Widget tanpa tampilan yang melaporkan [data] ke [board] selama terpasang,
/// dan mencabutnya saat dilepas. `data` `null` berarti tidak ada yang
/// dilaporkan (sumbernya sedang kosong).
class DsStatusReport extends StatefulWidget {
  /// Membuat pelapor untuk sumber [id].
  const DsStatusReport({required this.board, required this.id, required this.data, super.key});

  /// Papan tujuan.
  final DsStatusBoard board;

  /// Pengenal sumber.
  final String id;

  /// Data terbaru, atau `null`.
  final DsStatusSlideData? data;

  @override
  State<DsStatusReport> createState() => _DsStatusReportState();
}

class _DsStatusReportState extends State<DsStatusReport> {
  @override
  void initState() {
    super.initState();
    widget.board.report(widget.id, widget.data);
  }

  @override
  void didUpdateWidget(DsStatusReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.board.report(widget.id, widget.data);
  }

  @override
  void dispose() {
    widget.board.report(widget.id, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
