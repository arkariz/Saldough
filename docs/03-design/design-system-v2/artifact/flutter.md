# Flutter: design system v2

Semua kode di `lib/core/design_system/`, diimpor lewat `package:saldough/core/design_system/design_system.dart`. Nama berprefiks `Ds`. Tema aktif dibangun `AppThemeBridge` (tema lama + ekstensi Ds) selama layar dirombak bertahap; widget baru memakai `context.ds`, bukan `context.appColors`.

| Artefak | Flutter |
|---|---|
| token warna per tema | `DsColorScheme` (`ThemeExtension`), preset di `presets/` (`matcha`, `pink`) |
| huruf | `DsFonts.sans` (Plus Jakarta Sans), `DsFonts.pixel` (Space Mono Bold); `DsTypography`, `dsTextStyle()` |
| radius, jarak, elevasi, gerak | `DsRadius`/`DsShapes`, `DsSpacing`, `DsElevation`, `DsMotion` |
| Button, IconButton | `DsButton`, `DsIconButton` |
| IconTile, Badge, Avatar | `DsIconTile`, `DsBadge`/`DsStatusPill`, `DsAvatar` |
| SegmentMeter | `DsSegmentMeter` (`breathing`) |
| Card, LedgerRow | `DsCard`, `DsListCard`, `DsLedgerRow` |
| TopBar, header, footnote | `DsTopBar`, `DsPageHeader`, `DsSectionHeader`, `DsFootnote` |
| MascotCard, HeroCard, BudgetMeterCard, QuickAction, Banner | `DsMascotCard`, `DsHeroBalanceCard`/`DsHeroStatTile`, `DsBudgetMeterCard`, `DsQuickActionTile`, `DsInlineBanner` |
| NavBar | `DsNavBar`, `DsNavItem` |
| Motion | `DsCountUp`, `DsFlipSwitcher`, `DsPulse`, `DsIdleMotion`, `DsAmbientLayer`, `DsCelebration`, `DsJiggle` |

Isian, checkbox, radio, switch, dan kontrol segmen memakai widget Material yang digayakan `DsTheme`. Komponen hanya menerima teks yang sudah diformat dan diterjemahkan; tidak ada teks antarmuka di dalam komponen. Nominal ditampilkan lewat `AppMoneyFormatter`/`AppMoneyText`. Menambah preset: salin `presets/matcha.dart`, isi semua field, daftarkan di `DsThemePresets.all`, jalankan `test/core/design_system/`, perbarui `tokens.json`.
