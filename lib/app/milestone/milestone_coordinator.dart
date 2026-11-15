import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/features/milestone/domain/services/celebration_policy.dart';
import 'package:saldough/features/milestone/domain/services/milestone_engine.dart';
import 'package:saldough/features/milestone/domain/usecases/evaluate_milestones.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';

/// Menjalankan evaluasi tonggak pada pemicunya dan membagikan keadaan serta
/// perayaan ke layar (ADR-046 §3.4). Satu instans di akar.
///
/// Pemicu: [start] (aplikasi dibuka) dan tiap sinyal di [signals] (perubahan
/// transaksi, rutin, kotak masuk, cadangan), digabung per [debounce] supaya
/// satu rentetan perubahan menjadi satu evaluasi. Evaluasi tidak pernah
/// melempar dan tidak menunda tindakan (G-5).
class MilestoneCoordinator implements MilestoneBookAccess {
  /// Membuat [MilestoneCoordinator].
  MilestoneCoordinator({
    required this._evaluate,
    required this._store,
    required this._signals,
    this.debounce = const Duration(seconds: 1),
    Set<String> Function()? disabledIds,
  }) : _disabledIds = disabledIds ?? (() => const {}) {
    _ledger.addListener(() => _unseen.value = hasUnseenStamps(_ledger.value));
  }

  final EvaluateMilestones _evaluate;
  final MilestoneStore _store;
  final Stream<void> _signals;
  final Set<String> Function() _disabledIds;

  /// Jeda penggabung sinyal.
  final Duration debounce;

  final _ledger = ValueNotifier<MilestoneLedger>(MilestoneLedger.empty);
  final _unseen = ValueNotifier<bool>(false);
  final _pending = ValueNotifier<List<String>>(const []);
  final _celebrations = StreamController<CelebrationPlan>.broadcast();
  StreamSubscription<void>? _subscription;
  Timer? _timer;
  bool _running = false;
  bool _again = false;

  /// Perayaan boleh tampil sekarang? Diisi tuan rumah di Beranda: salah bila
  /// banner pembaruan, lembar Apa yang baru, tur, atau layar lain menghalangi
  /// (G-4). Selama salah, tidak ada perayaan yang menunggu.
  bool Function() canCelebrate = () => false;

  /// Catatan terkini, untuk titik, banner, dan Buku Stempel.
  @override
  ValueListenable<MilestoneLedger> get ledger => _ledger;

  /// Stempel baru yang perayaannya terhalang dan **menunggu satu kali** sampai
  /// Beranda bebas halangan (keputusan pemilik 15 Nov 2026, F28-1). Beberapa
  /// stempel digabung menjadi satu perayaan (G-4); tidak disimpan ke disk, jadi
  /// pembukaan aplikasi berikutnya hanya meninggalkan titik "belum dilihat".
  ValueListenable<List<String>> get pending => _pending;

  /// Ada stempel belum dilihat dan perayaan menyala: titik kecil di ikon Akun.
  ValueListenable<bool> get hasUnseen => _unseen;

  /// Perayaan yang harus ditampilkan sekarang (snackbar atau lembar).
  Stream<CelebrationPlan> get celebrations => _celebrations.stream;

  /// Memuat catatan, mulai mendengarkan sinyal, dan mengevaluasi sekali.
  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _signals.listen((_) => _schedule());
    (await _store.load()).map((value) => _ledger.value = value);
    await evaluate();
  }

  /// Berhenti mendengarkan.
  Future<void> stop() async {
    _timer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(evaluate()));
  }

  /// Mengevaluasi sekarang. Panggilan yang bertumpuk dijalankan sekali lagi
  /// sesudah yang sedang berjalan selesai.
  Future<void> evaluate() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        final result = await _evaluate(disabledIds: _disabledIds());
        result.fold((_) {}, (evaluation) {
          _ledger.value = evaluation.ledger;
          for (final id in evaluation.newlyEarned) {
            AppAnalytics.log(MilestoneEvents.earned(id: id, quiet: evaluation.quiet));
          }
          final plan = planCelebration(
            evaluation: evaluation,
            blocked: !canCelebrate(),
          );
          if (plan.kind != CelebrationKind.none) {
            _celebrations.add(plan);
          } else if (!evaluation.quiet &&
              evaluation.newlyEarned.isNotEmpty &&
              evaluation.ledger.celebrationEnabled) {
            // Terhalang: tahan satu perayaan gabungan sampai bebas halangan.
            _pending.value = [..._pending.value, ...evaluation.newlyEarned];
          }
        });
      } while (_again);
    } finally {
      _running = false;
    }
  }

  /// Menampilkan perayaan yang tertahan bila sekarang bebas halangan. Dipanggil
  /// tuan rumah tiap keadaan halangan mungkin berubah. Murah bila tidak ada
  /// yang tertahan.
  void retryPending() {
    final ids = _pending.value;
    if (ids.isEmpty) {
      return;
    }
    final ledger = _ledger.value;
    if (!ledger.celebrationEnabled) {
      _pending.value = const [];
      return;
    }
    if (!canCelebrate()) {
      return;
    }
    _pending.value = const [];
    final plan = planCelebration(
      evaluation: MilestoneEvaluation(ledger: ledger, newlyEarned: ids),
      blocked: false,
    );
    if (plan.kind != CelebrationKind.none) {
      _celebrations.add(plan);
    }
  }

  /// Stempel [ids] sudah tampil di sampul Buku Periode: dilipat ke sana, tanpa
  /// perayaan terpisah (BUKU_PERIODE BP-13, G-4). Dibuang dari perayaan yang
  /// tertahan dan dianggap sudah dilihat.
  Future<void> absorbIntoCover(Set<String> ids) {
    _pending.value = [
      for (final id in _pending.value)
        if (!ids.contains(id)) id,
    ];
    return _update(
      (l) => l.copyWith(
        earned: {
          for (final e in l.earned.values) e.id: ids.contains(e.id) ? e.markSeen() : e,
        },
      ),
    );
  }

  /// Buku Stempel dibuka: semua stempel dianggap dilihat (titik hilang), dan
  /// perayaan yang tertahan dibatalkan karena stempelnya sudah terlihat.
  @override
  Future<void> markAllSeen() {
    _pending.value = const [];
    return _markAllSeen();
  }

  Future<void> _markAllSeen() => _update(
    (l) => l.earned.values.every((e) => e.seen)
        ? l
        : l.copyWith(
            earned: {for (final e in l.earned.values) e.id: e.markSeen()},
          ),
  );

  /// Lembar pengenalan atau banner pengguna lama sudah tampil (sekali).
  Future<void> markIntroShown() =>
      _update((l) => l.introShown ? l : l.copyWith(introShown: true));

  /// Sakelar Perayaan stempel (G-8). Evaluasi dan penyimpanan tetap jalan;
  /// menyalakan lagi tidak merayakan ulang yang sudah ada.
  @override
  Future<void> setCelebrationEnabled({required bool enabled}) {
    if (!enabled) {
      _pending.value = const [];
    }
    return _update(
      (l) => l.celebrationEnabled == enabled
          ? l
          : l.copyWith(celebrationEnabled: enabled),
    );
  }

  Future<void> _update(MilestoneLedger Function(MilestoneLedger) change) async {
    final loaded = await _store.load();
    await loaded.fold((_) async {}, (current) async {
      final next = change(current);
      if (next == current) {
        _ledger.value = current;
        return;
      }
      (await _store.save(next)).map((_) => _ledger.value = next);
    });
  }
}
