import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/pages/category_page.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:state_management/state_management.dart';

/// Pintu masuk layar Kategori di bagian "Pengaturan" layar Akun (ADR-026
/// §3.6). Tampil baik sudah maupun belum masuk — kategori tidak butuh akun.
class CategorySettingEntry extends StatelessWidget {
  /// Membuat [CategorySettingEntry].
  const CategorySettingEntry({super.key});

  @override
  Widget build(BuildContext context) => SettingRow(
    key: const ValueKey('category-setting'),
    icon: IconKey.label,
    title: t.category.accountEntryTitle,
    subtitle: t.category.accountEntryBody,
    onTap: () => openCategoryPage(context, context.read<CategoryManagerBloc>()),
  );
}
