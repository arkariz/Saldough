import 'package:flutter/widgets.dart';

/// Isi rute alur transparan (`RouteTransition.none`, ADR-030 §3.3):
/// menjalankan [run] sekali sesudah frame pertama, lalu menutup rutenya
/// dengan hasil [run].
///
/// Tak terlihat: lembar dan dialog alur tampil di atasnya, layar pemanggil
/// tetap terlihat di belakangnya. Scope yang dipasang di atas widget ini
/// hidup sampai [run] selesai, walau lembarnya sudah tertutup.
class FlowRunner extends StatefulWidget {
  /// Membuat [FlowRunner].
  const FlowRunner({required this.run, super.key});

  /// Alur yang dijalankan; hasilnya jadi hasil rute.
  final Future<Object?> Function(BuildContext context) run;

  @override
  State<FlowRunner> createState() => _FlowRunnerState();
}

class _FlowRunnerState extends State<FlowRunner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await widget.run(context);
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
