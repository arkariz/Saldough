import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/domain/usecases/create_budget_from_template.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_state.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'budget_template_effect.dart';
part 'budget_template_event.dart';

/// Bloc layar Template Anggaran (T-7.2, FR-BUD-005): muat, tambah, sunting
/// (termasuk aktif/nonaktif), gandakan, dan hapus template.
///
/// ⚠ Tidak ada satu pun jalur di sini yang menulis dompet atau transaksi:
/// template hanya susunan rencana dan tidak pernah mengubah saldo (aturan 5).
/// Membuat anggaran DARI template dikerjakan `BudgetBloc` lewat formulir
/// anggaran yang sama.
final class BudgetTemplateBloc extends Bloc<BudgetTemplateEvent, BudgetTemplateState> {
  /// Membuat [BudgetTemplateBloc].
  BudgetTemplateBloc({
    required this._templateRepository,
    required this._walletRepository,
  }) : super(BudgetTemplateState.initial()) {
    on<BudgetTemplatesStarted>(_onStarted);
    on<BudgetTemplateAdded>(_onAdded);
    on<BudgetTemplateEdited>(_onEdited);
    on<BudgetTemplateDuplicated>(_onDuplicated);
    on<BudgetTemplateDeleted>(_onDeleted);
  }

  final BudgetTemplateRepository _templateRepository;
  final WalletRepository _walletRepository;

  /// Id baru; urutan menjamin unik walau dipanggil beruntun dalam satu
  /// mikrodetik.
  var _sequence = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> _onStarted(BudgetTemplatesStarted event, Emitter<BudgetTemplateState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    final (templates, wallets) = await (_templateRepository.listTemplates(), _walletRepository.listWallets()).wait;
    switch ((templates, wallets)) {
      case (Right(value: final templates), Right(value: final wallets)):
        emit(state.copyWith(templates: templates, wallets: wallets, isLoading: false, loadFailed: false));
      case (Left(value: final failure), _) || (_, Left(value: final failure)):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
    }
  }

  Future<void> _onAdded(BudgetTemplateAdded event, Emitter<BudgetTemplateState> emit) async {
    final template = BudgetTemplate(id: _newId(), name: event.name.trim(), items: event.items);
    await _afterWrite(await _templateRepository.saveTemplate(template), t.budget.templateSavedMessage, emit);
  }

  Future<void> _onEdited(BudgetTemplateEdited event, Emitter<BudgetTemplateState> emit) async {
    await _afterWrite(await _templateRepository.saveTemplate(event.template), t.budget.templateUpdatedMessage, emit);
  }

  Future<void> _onDuplicated(BudgetTemplateDuplicated event, Emitter<BudgetTemplateState> emit) async {
    final source = event.template;
    final copy = BudgetTemplate(
      id: _newId(),
      name: t.budget.templateCopyName(name: source.name),
      items: const CreateBudgetFromTemplate().draftItems(source, newItemId: _newId),
      isEnabled: source.isEnabled,
    );
    await _afterWrite(await _templateRepository.saveTemplate(copy), t.budget.templateDuplicatedMessage, emit);
  }

  Future<void> _onDeleted(BudgetTemplateDeleted event, Emitter<BudgetTemplateState> emit) async {
    await _afterWrite(
      await _templateRepository.deleteTemplate(event.template.id),
      t.budget.templateDeletedMessage,
      emit,
    );
  }

  /// Sesudah menulis: gagal → pertahankan layar dan tampilkan galat;
  /// berhasil → muat ulang template tanpa `isLoading`, lalu pesan berhasil.
  Future<void> _afterWrite(
    Either<Failure, Unit> result,
    String successMessage,
    Emitter<BudgetTemplateState> emit,
  ) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        switch (await _templateRepository.listTemplates()) {
          case Left(value: final failure):
            emit(state.copyWith(effect: _effectError(failure)));
          case Right(value: final templates):
            emit(state.copyWith(templates: templates, effect: _effectSaved(successMessage)));
        }
    }
  }
}
