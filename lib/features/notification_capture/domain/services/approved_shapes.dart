import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/services/auto_record_policy.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Bentuk notifikasi yang disetujui pengguna untuk dicatat otomatis
/// (ADR-044 §3.7, E3/B-87).
final class ApprovedShape extends Equatable {
  /// Membuat [ApprovedShape].
  const ApprovedShape({
    required this.packageName,
    required this.template,
    required this.approvedAt,
    this.amounts = const [],
    this.autoCount = 0,
  });

  /// Aplikasi sumber.
  final String packageName;

  /// Templat teks: nominal `{amount}`, catatan `{note}`, angka lain `{*}`.
  final String template;

  /// Kapan disetujui.
  final DateTime approvedAt;

  /// Nominal (sen) terakhir dari bentuk ini: konfirmasi yang disetujui, lalu
  /// tiap catatan otomatis. Dasar pagar nominal besar.
  final List<int> amounts;

  /// Jumlah catatan otomatis dari bentuk ini; dua yang pertama bertanda "baru".
  final int autoCount;

  /// Salinan dengan perubahan.
  ApprovedShape copyWith({List<int>? amounts, int? autoCount}) => ApprovedShape(
    packageName: packageName,
    template: template,
    approvedAt: approvedAt,
    amounts: amounts ?? this.amounts,
    autoCount: autoCount ?? this.autoCount,
  );

  @override
  List<Object?> get props => [packageName, template, approvedAt, amounts, autoCount];
}

/// Penyimpanan bentuk yang disetujui, urutan sisip dipertahankan.
abstract interface class ApprovedShapeStore {
  /// Seluruh bentuk.
  Future<Either<Failure, List<ApprovedShape>>> load();

  /// Mengganti seluruh bentuk.
  Future<Either<Failure, Unit>> save(List<ApprovedShape> shapes);
}

/// Batas jumlah bentuk; yang tertua dibuang saat penuh.
const approvedShapeLimit = 100;

/// Banyak nominal terakhir yang diingat per bentuk.
const approvedShapeAmountWindow = 20;

/// Pagar nominal besar (KT-N2, diputuskan pemilik 5 Nov 2026): nominal di atas
/// kelipatan ini dari median ditinjau, bukan dicatat otomatis.
const approvedShapeAmountFence = 10;

/// Pagar baru berlaku bila bentuk punya sekurang-kurangnya sekian nominal.
const approvedShapeMinSamples = 3;

/// Tanda "baru": sekian catatan otomatis pertama dari bentuk yang baru disetujui.
const approvedShapeNewCount = 2;

/// Templat bentuk dari [text] dengan nominal pertama jadi `{amount}`, angka
/// lain `{*}`, dan [note] (nama pedagang, bila ditemukan utuh di teks) jadi
/// `{note}` supaya pedagang lain dengan bentuk sama ikut cocok. `null` bila
/// tidak ada nominal terbaca.
String? approvedTemplateFor(String text, String note) {
  final words = NotificationTemplate.words(text);
  final amountIndex = words.indexWhere((w) => NotificationTemplate.isAmountWord(w.text));
  if (amountIndex < 0) return null;
  final roles = <int, TemplateWordRole>{amountIndex: TemplateWordRole.amount};
  String clean(String w) => w.toLowerCase().replaceAll(RegExp(r'[,.;:!?]+$'), '');
  final noteWords = [
    for (final w in note.trim().split(RegExp(r'\s+')))
      if (w.isNotEmpty) clean(w),
  ];
  if (noteWords.isNotEmpty) {
    for (var i = 0; i + noteWords.length <= words.length; i++) {
      var same = true;
      for (var j = 0; j < noteWords.length; j++) {
        if (i + j == amountIndex || clean(words[i + j].text) != noteWords[j]) {
          same = false;
          break;
        }
      }
      if (same) {
        for (var j = 0; j < noteWords.length; j++) {
          roles[i + j] = TemplateWordRole.note;
        }
        break;
      }
    }
  }
  return NotificationTemplate.fromSample(text, roles);
}

/// Median [values] (nilai tengah; rata-rata dua tengah bila genap).
int medianOf(List<int> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// `true` bila [amountSen] jauh di atas kebiasaan [shape] (lebih dari
/// [approvedShapeAmountFence] kali median, setelah [approvedShapeMinSamples]).
bool isUnusualShapeAmount(ApprovedShape shape, int amountSen) {
  if (shape.amounts.length < approvedShapeMinSamples) return false;
  return amountSen > medianOf(shape.amounts) * approvedShapeAmountFence;
}

/// Boleh-tidaknya mesin tanpa layar menuliskan keputusan Catat sendiri untuk
/// notifikasi dari bentuk yang disetujui (E3): syaratnya sama dengan pemroses
/// di aplikasi (nominal dan dompet terisi, bukan dugaan ganda, rutin tidak
/// meragukan, nominal tidak jauh di atas kebiasaan). Rutin hanya boleh bila cocok
/// persis dan bukan hasil pemutus nama.
bool mayAutoRecordFromWorker({
  required ApprovedShape? shape,
  required RecordDraft draft,
  required PlanResolution plan,
  required bool duplicate,
}) {
  if (shape == null || duplicate) return false;
  if (plan.boundUnclear || plan.ambiguous) return false;
  final match = plan.match;
  if (match != null && (!match.exact || plan.tieBroken)) return false;
  if (!const AutoRecordPolicy(AutoRecordLevel.whenAmountAndWallet).allows(draft)) return false;
  return !isUnusualShapeAmount(shape, draft.amountSen ?? 0);
}

/// [ApprovedShape] di atas [ApprovedShapeStore]: dimuat ulang tiap [refresh].
final class StoreBackedApprovedShapes {
  /// Membuat [StoreBackedApprovedShapes].
  StoreBackedApprovedShapes(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ApprovedShapeStore _store;
  final DateTime Function() _clock;
  List<ApprovedShape> _shapes = const [];

  /// Memuat bentuk terbaru; dipanggil pemroses sebelum bekerja.
  Future<void> refresh() async {
    _shapes = (await _store.load()).getOrElse((_) => const []);
  }

  /// Bentuk yang cocok dengan [text] dari [packageName], atau `null`.
  ApprovedShape? find(String packageName, String text) {
    for (final shape in _shapes) {
      if (shape.packageName == packageName && NotificationTemplate.match(shape.template, text) != null) return shape;
    }
    return null;
  }

  /// `true` bila [text] sudah disetujui, untuk menahan tawaran berulang.
  bool isApproved(String packageName, String text) => find(packageName, text) != null;

  /// Menyetujui bentuk [text] ([note] = pedagang di teks) dengan nominal
  /// konfirmasi [amountSen] sebagai contoh pertama. Mengembalikan fungsi
  /// Batalkan, atau `null` bila bentuknya tidak bisa dibuat.
  Future<Future<void> Function()?> approve({
    required String packageName,
    required String text,
    required String note,
    required int amountSen,
  }) async {
    final template = approvedTemplateFor(text, note);
    if (template == null) return null;
    await refresh();
    final existing = _shapes.where((s) => s.packageName == packageName && s.template == template);
    if (existing.isNotEmpty) return () async {};
    final shape = ApprovedShape(
      packageName: packageName,
      template: template,
      approvedAt: _clock(),
      amounts: [amountSen],
    );
    await _write([..._shapes, shape]);
    return () async {
      await refresh();
      await _write([
        for (final s in _shapes)
          if (!(s.packageName == packageName && s.template == template)) s,
      ]);
    };
  }

  /// Mencatat satu catatan otomatis [amountSen] dari [shape].
  Future<void> recordAuto(ApprovedShape shape, int amountSen) async {
    await refresh();
    await _write([
      for (final s in _shapes)
        if (s.packageName == shape.packageName && s.template == shape.template)
          s.copyWith(
            autoCount: s.autoCount + 1,
            amounts: [...s.amounts, amountSen].reversed.take(approvedShapeAmountWindow).toList().reversed.toList(),
          )
        else
          s,
    ]);
  }

  Future<void> _write(List<ApprovedShape> shapes) async {
    final next = [...shapes];
    while (next.length > approvedShapeLimit) {
      next.removeAt(0);
    }
    await _store.save(next);
    _shapes = next;
  }
}
