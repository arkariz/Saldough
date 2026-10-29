/// Barrel design system baru (ADR-043): satu-satunya jalur impor.
///
/// Berdampingan dengan design system lama (`core/theme/theme.dart`) sampai
/// rombak UI; jangan mencampur token keduanya di satu widget.
library;

export 'color/ds_color_scheme.dart';
export 'ds_theme.dart';
export 'presets/ds_theme_preset.dart';
export 'presets/ds_theme_presets.dart';
export 'presets/matcha.dart';
export 'tokens/ds_elevation.dart';
export 'tokens/ds_motion.dart';
export 'tokens/ds_radius.dart';
export 'tokens/ds_shapes.dart';
export 'tokens/ds_spacing.dart';
export 'typography/ds_fonts.dart';
export 'typography/ds_typography.dart';
