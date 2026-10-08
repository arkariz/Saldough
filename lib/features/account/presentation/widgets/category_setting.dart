import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/pages/category_page.dart';
import 'package:state_management/state_management.dart';

/// Pintu masuk layar Kategori di bagian "Pengaturan" layar Akun (ADR-026
/// §3.6). Tampil baik sudah maupun belum masuk — kategori tidak butuh akun.
class CategorySettingEntry extends StatelessWidget {
  /// Membuat [CategorySettingEntry].
  const CategorySettingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppTappable(
      key: const ValueKey('category-setting'),
      label: t.category.accountEntryTitle,
      onTap: () => openCategoryPage(context, context.read<CategoryManagerBloc>()),
      child: AppHardCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.category.accountEntryTitle, style: textTheme.titleSmall),
                  Text(
                    t.category.accountEntryBody,
                    style: textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
                  ),
                ],
              ),
            ),
            const AppIcon(IconKey.chevronRight),
          ],
        ),
      ),
    );
  }
}
