import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/app/shell/shell_requests.dart';

/// Menggambar nol widget; menyalurkan [ShellRequest] ke shell. Dipasang di
/// bawah `BlocProvider` shell supaya [onShowPlanRecurring] boleh membaca bloc.
class ShellRequestHost extends StatefulWidget {
  /// Membuat [ShellRequestHost].
  const ShellRequestHost({required this.container, required this.onShowPlanRecurring, super.key});

  /// Container akar tempat [ShellRequests] terdaftar.
  final GetIt container;

  /// Membuka tab Rencana pada segmen Rutin.
  final VoidCallback onShowPlanRecurring;

  @override
  State<ShellRequestHost> createState() => _ShellRequestHostState();
}

class _ShellRequestHostState extends State<ShellRequestHost> {
  StreamSubscription<ShellRequest>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<ShellRequests>()) return;
    _subscription = widget.container<ShellRequests>().stream.listen((request) {
      if (!mounted) return;
      switch (request) {
        case ShellRequest.showPlanRecurring:
          widget.onShowPlanRecurring();
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
