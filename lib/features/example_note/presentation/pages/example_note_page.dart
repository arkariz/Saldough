import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_bloc.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_state.dart';
import 'package:state_management/state_management.dart';

/// Halaman contoh — lihat catatan di `ExampleNote`.
class ExampleNotePage extends StatefulWidget {
  /// Membuat [ExampleNotePage].
  const ExampleNotePage({super.key});

  @override
  State<ExampleNotePage> createState() => _ExampleNotePageState();
}

class _ExampleNotePageState extends State<ExampleNotePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.app.title)),
      body: EffectListener<ExampleNoteBloc, ExampleNoteState>(
        child: BlocBuilder<ExampleNoteBloc, ExampleNoteState>(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: _controller),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: t.common.add,
                      onPressed: state.isLoading
                          ? null
                          : () {
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              context.read<ExampleNoteBloc>().add(ExampleNoteAdded(text));
                              _controller.clear();
                            },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => AppCard(child: Text(state.notes[index].text)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
