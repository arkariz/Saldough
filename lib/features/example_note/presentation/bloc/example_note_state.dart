import 'package:saldough/features/example_note/domain/entities/example_note.dart';
import 'package:state_management/state_management.dart';

/// State [ExampleNoteBloc]. `effect` tidak pernah masuk [props] — lihat
/// ADR-0003 dan aturan yang mengikat di ARCHITECTURE_OVERVIEW.md.
final class ExampleNoteState extends UiState<ExampleNoteState> {
  /// Membuat [ExampleNoteState].
  const ExampleNoteState({
    required this.notes,
    required this.isLoading,
    super.effect,
  });

  /// State awal sebelum catatan dimuat.
  factory ExampleNoteState.initial() => const ExampleNoteState(notes: [], isLoading: false);

  /// Seluruh catatan yang sudah dimuat.
  final List<ExampleNote> notes;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  @override
  ExampleNoteState copyWith({
    List<ExampleNote>? notes,
    bool? isLoading,
    UiEffect? effect,
  }) {
    return ExampleNoteState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [notes, isLoading];
}
