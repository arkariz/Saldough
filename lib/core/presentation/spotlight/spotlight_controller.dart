import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_tours.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

/// Otak tur spotlight (ADR-021 §3.3): registri target, progres per langkah,
/// dan tur yang sedang tampil. Dipegang `SpotlightHost`.
class SpotlightController extends ChangeNotifier {
  /// Membuat [SpotlightController] di atas [repository].
  SpotlightController({required this._repository});

  final TutorialProgressRepository _repository;
  final Map<SpotlightKey, GlobalKey> _targets = {};

  TutorialProgress? _progress;
  bool _starting = false;

  TourId? _tour;
  List<SpotlightStep> _steps = const [];
  int _index = 0;

  /// Tur yang sedang tampil, atau null.
  TourId? get activeTour => _tour;

  /// True saat sebuah tur tampil.
  bool get isActive => _tour != null;

  /// Langkah yang tampil pada putaran tur ini, sesudah disaring.
  List<SpotlightStep> get steps => _steps;

  /// Indeks langkah yang tampil.
  int get index => _index;

  /// Langkah yang tampil, atau null.
  SpotlightStep? get currentStep => isActive ? _steps[_index] : null;

  /// True di langkah terakhir.
  bool get isLastStep => isActive && _index == _steps.length - 1;

  /// Mendaftarkan [globalKey] sebagai target [key].
  void register(SpotlightKey key, GlobalKey globalKey) => _targets[key] = globalKey;

  /// Mencabut [globalKey] — hanya kalau masih pemilik [key].
  void unregister(SpotlightKey key, GlobalKey globalKey) {
    if (_targets[key] == globalKey) _targets.remove(key);
  }

  /// `BuildContext` target [key] yang sedang terpasang dan ter-layout.
  BuildContext? targetContext(SpotlightKey key) {
    final context = _targets[key]?.currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize || box.size.isEmpty) return null;
    return context;
  }

  Future<TutorialProgress> _loadProgress() async =>
      _progress ??= (await _repository.load()).getOrElse((_) => TutorialProgress.empty);

  /// True kalau [tour] punya langkah yang belum dilihat dan targetnya sedang
  /// tampil — dipakai pemicu sebelum menyiapkan layar (mis. menggulir ke
  /// atas), supaya layar tidak digulir untuk tur yang tidak akan tampil.
  Future<bool> wouldStart(TourId tour) async {
    if (isActive || _starting) return false;
    final progress = await _loadProgress();
    return tourSteps[tour]!.any((key) => !progress.hasSeen(key) && targetContext(key) != null);
  }

  /// Memulai [tour] dengan langkah yang targetnya tampil dan belum dilihat —
  /// atau semua langkah yang tampil kalau [force] ("Tur layar ini").
  /// Mengembalikan true kalau tur tampil.
  ///
  /// Karena progres dicatat per langkah, elemen yang baru muncul belakangan
  /// (kartu anggaran, kartu Freelance, ...) disorot sendiri saat pertama
  /// tampil, tanpa mengulang langkah yang sudah dilihat (ADR-021 §3.1).
  Future<bool> maybeStart(TourId tour, {bool force = false}) async {
    if (isActive || _starting) return false;
    _starting = true;
    try {
      final progress = await _loadProgress();
      final available = [
        for (final step in spotlightStepsFor(tour))
          if ((force || !progress.hasSeen(step.key)) && targetContext(step.key) != null) step,
      ];
      if (available.isEmpty) return false;
      _tour = tour;
      _steps = available;
      _index = 0;
      notifyListeners();
      return true;
    } finally {
      _starting = false;
    }
  }

  /// Ke langkah berikutnya, atau selesai di langkah terakhir.
  Future<void> next() async {
    if (!isActive) return;
    if (isLastStep) return finish();
    _index++;
    notifyListeners();
  }

  /// Menutup tur — dipakai "Selesai", "Lewati tur", dan tombol kembali
  /// sistem. Semua langkah putaran ini ditandai sudah dilihat; langkah untuk
  /// elemen yang belum tampil tetap menunggu.
  Future<void> finish() async {
    if (!isActive) return;
    final shown = [for (final step in _steps) step.key];
    _tour = null;
    _steps = const [];
    _index = 0;
    final progress = await _loadProgress();
    _progress = progress.copyWith(seenSteps: {...progress.seenSteps, ...shown});
    notifyListeners();
    await _repository.markStepsSeen(shown);
  }

  /// Mengembalikan onboarding dan semua tur ke belum dilihat.
  Future<void> resetAll() async {
    _progress = TutorialProgress.empty;
    await _repository.resetAll();
  }
}
