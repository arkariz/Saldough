import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/auth/presentation/account_avatar.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('belum masuk: bulat dengan ikon orang', (tester) async {
    await tester.pumpWidget(_host(const AccountAvatar(user: null)));
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    final box = tester.widget<Container>(find.byType(Container).first);
    expect((box.decoration! as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('sudah masuk tanpa foto: inisial berlatar warna aksi utama', (tester) async {
    await tester.pumpWidget(_host(const AccountAvatar(user: AppUser(uid: 'u', displayName: 'sari dewi'))));
    expect(find.text('S'), findsOneWidget);
    final box = tester.widget<Container>(find.byType(Container).first);
    expect((box.decoration! as BoxDecoration).color, DsThemePresets.fallback.light.actionPrimary);
  });
}
