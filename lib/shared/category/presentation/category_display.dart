import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Ikon [category]: `iconKey` tersimpan kalau dikenal, selain itu ditebak
/// dari namanya ([categoryIconFor]).
IconKey categoryIcon(Category category) {
  final key = category.iconKey;
  if (key != null) {
    for (final icon in IconKey.values) {
      if (icon.name == key) return icon;
    }
  }
  return categoryIconFor(category.name);
}
