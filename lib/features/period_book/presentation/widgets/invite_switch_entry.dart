import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/period_book/presentation/period_book_settings_access.dart';

/// Baris Akun **Ajakan akhir periode** (BP-14): sakelar untuk menampilkan atau
/// menyembunyikan ajakan Tutup buku di Beranda. Mematikannya tidak mengunci apa
/// pun: rapor dan Rak Buku tetap bisa dibuka manual. Dimuat dari ingatan buku;
/// perubahan disimpan langsung.
class InviteSwitchEntry extends StatefulWidget {
  /// Membuat [InviteSwitchEntry].
  const InviteSwitchEntry({required this.access, super.key});

  /// Pintu ke ingatan.
  final PeriodBookSettingsAccess access;

  @override
  State<InviteSwitchEntry> createState() => _InviteSwitchEntryState();
}

class _InviteSwitchEntryState extends State<InviteSwitchEntry> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    unawaited(widget.access.inviteEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    }));
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.book.setting;
    return DsSwitchRow(
      title: texts.label,
      subtitle: texts.hint,
      value: _enabled ?? true,
      onChanged: (enabled) {
        setState(() => _enabled = enabled);
        unawaited(widget.access.setInviteEnabled(enabled: enabled));
      },
    );
  }
}
