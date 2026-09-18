import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';

/// Dialog indikator "menyimpan…" yang tampil selagi `RecordBloc` sedang
/// menulis transaksi (`state.isSaving`), lalu menutup dirinya sendiri saat
/// selesai. Tidak membedakan berhasil/gagal secara visual di sini --
/// `EffectListener` yang sudah terpasang di `AppShellPage` yang menampilkan
/// snackbar berhasil/galat setelah dialog ini tertutup.
///
/// [bloc] diteruskan sebagai instance Dart langsung, BUKAN diambil lewat
/// `context.read<RecordBloc>()` — pola bug yang sudah pernah terjadi di
/// proyek ini: context builder `showDialog` berada di cabang `Navigator`
/// yang terpisah dari tempat `BlocProvider` dipasang di `AppShellPage`,
/// sehingga `context.read` di sini gagal menemukannya.
class RecordSavingDialog extends StatelessWidget {
  /// Membuat [RecordSavingDialog] untuk [bloc].
  const RecordSavingDialog({required this.bloc, super.key});

  /// Instance `RecordBloc` yang sedang menyimpan.
  final RecordBloc bloc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecordState>(
      stream: bloc.stream,
      initialData: bloc.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? bloc.state;
        if (!state.isSaving) {
          // Ditunda ke frame berikutnya -- memanggil `Navigator.pop` di
          // tengah `build` melempar galat "setState()/markNeedsBuild()
          // called during build".
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: AppHardCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(t.record.savingMessage),
              ],
            ),
          ),
        );
      },
    );
  }
}
