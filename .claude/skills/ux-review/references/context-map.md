# Peta konteks — baca sebelum menilai apa pun

## Dokumen (baca dulu, urut)

| Berkas | Kenapa dibaca |
|---|---|
| `docs/01-product/prd-saldough-2.0.md` — §5 "Prinsip produk", §7 FR, §8.4 NFR-UX | Tujuan produk dan FR — acuan "apakah ini sesuai kebutuhan" sebelum menilai "apakah ini enak dipakai". NFR-UX-001 (catat dalam satu layar) dan NFR-UX-005 (kosakata pencatatan) paling sering relevan. `prd-saldough-1.0.md` hanya arsip — jangan jadikan acuan. |
| `docs/00-foundation/PROJECT_GLOSSARY.md` | Istilah resmi (`Dompet`, `Saldo tercatat`, `Pos anggaran`, `Worklog`, dst) dan tabel "Bahasa yang dipakai aplikasi" (Pakai / Jangan pakai). Acuan checklist kategori D. |
| `docs/02-architecture/DOMAIN_MODEL.md` | Entitas dan rumus. Beberapa hal yang kelihatan aneh di UI adalah invarian domain yang disengaja: transfer tidak dihitung sebagai masuk/keluar, saldo boleh negatif, anggaran tidak mengubah saldo, worklog tidak menyentuh saldo. |
| `docs/02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md` dan `docs/03-design/design-system/README.md` (atau artefak design system) | Bahasa visual yang berlaku: token, sudut piksel, ikon piksel vs Material Symbols, aturan warna (pengeluaran `ink`, status selalu dengan teks). ADR-015/016 sudah digantikan; selama Fase 14 belum selesai, kode masih bergaya lama dan itu bukan temuan baru. |

| `.claude/AGENT_CONTEXT.md` — "Tampilan" dan "Nilai yang sudah terkonfirmasi" | Aturan tampilan yang mengikat, dan nilai yang SUDAH dikonfirmasi pemilik (jangan tanya ulang). |
| `docs/04-planning/TASK_LIST.md` — Fase 2 (T-2.1 s.d. T-2.12) | Catatan `⚠` = keputusan UI yang sudah diambil bersama pemilik. Jangan dilaporkan ulang sebagai temuan baru. |
| `docs/04-planning/UI_UX_DESIGN_TASKS.md` | Status desain per layar dan catatan terbuka. |
| `docs/03-design/prototype/*.dc.html` (atau artefak prototipe) | Layar acuan baru yang disetujui pemilik 3 Okt 2026. |

## Kode — zona `core` (dipakai semua layar)

- `lib/core/theme/` — `PixelTheme.light`/`.dark` adalah tema global `MaterialApp` (ADR-031); `AppColorsExtension` (`pixelLight`/`pixelDark`), token `AppSpacing`/`AppRadius`/`AppBorder`/`AppElevation`. Baca nilainya di sini, jangan menebak dari nama variabel.
- `lib/core/presentation/widgets/` — komponen bersama: `AppHardCard`, `AppButton`, `AppQuickChip`, `AppSegmented`, `AppMoneyText`, `AppIcon`/`CategoryIcon`, `AppSkeleton`, `AppSegmentedProgressBar`, `FullScreenSheet`, `ConfirmDeleteDialog`, `AppMenuSelectButton`, `AppForm*`. Cek di sini dulu sebelum menilai "kenapa kartu ini beda dengan kartu itu" — biasanya bedanya hanya parameter.
- `lib/app/shell/app_shell_page.dart` — shell di rute `/home`: empat tab navigasi bawah (Beranda, Anggaran, Riwayat, Dompet) dan dua FAB bertumpuk di kanan bawah (Catat pakai suara, CATAT). Fitur lain dibuka lewat `context.pushRoute(XRouteKeys.y, input)` (ADR-030).
- `assets/i18n/id.i18n.json` (dan `en`) — seluruh copy antarmuka. Baca JSON-nya langsung untuk audit copy — lebih cepat daripada grep tiap `t.xxx.yyy`. Kode hasil slang ada di `lib/core/i18n/`.

## Kode — zona `features`

Baca `*_state.dart` sebelum page/widget. Flag seperti `isLoading`,
`loadFailed`, `isSaving` menentukan state apa yang SEHARUSNYA tampil. Kalau
widget tidak mengecek flag itu, itu temuan nyata, bukan dugaan. Semua path
di bawah relatif ke `lib/features/<fitur>/presentation/`.

| Fitur | Layar / lembar | Bloc | Widget penting |
|---|---|---|---|
| `record` (CATAT — satu-satunya jalur pembuatan transaksi manual) | `open_record_sheet.dart`, `open_edit_transaction_sheet.dart`, `widgets/record_form_host.dart` (segmen keluar/masuk/transfer), `income_`/`expense_`/`transfer_form_sheet.dart`; suara: `capture/voice_capture_sheet.dart`, `capture/speech_language_sheet.dart` | `bloc/record_bloc.dart`, `capture/bloc/voice_capture_bloc.dart` | `record_form_frame.dart`, `record_amount_field.dart`, `record_category_field.dart`, `record_date_field.dart`, `record_draft_card.dart`, `record_saving_dialog.dart` |
| `transaction` (Riwayat) | `pages/transaction_list_page.dart`, `pages/transaction_detail_page.dart` | `bloc/transaction_bloc.dart` | `transaction_filter_bar.dart`, `transaction_month_header.dart`, `transaction_empty_states.dart` |
| `wallet` | `pages/wallet_list_page.dart`, `pages/wallet_detail_page.dart` | `bloc/wallet_bloc.dart`, `bloc/wallet_activity_bloc.dart` | `wallet_card.dart`, `wallet_summary_card.dart`, `wallet_form_sheet.dart`, `wallet_empty_states.dart` |
| `budget` | `pages/budget_list_page.dart`, `budget_detail_page.dart`, `budget_template_page.dart` | `bloc/budget_bloc.dart`, `bloc/budget_template_bloc.dart` | `budget_card.dart`, `budget_form_sheet.dart`, `budget_item_form_sheet.dart`, `budget_summary_card.dart` |
| `freelance` | `pages/freelance_overview_page.dart`, `freelance_project_page.dart` (dibuka dari CATAT → Catat Pemasukan → Freelance) | `bloc/freelance_bloc.dart` | `freelance_cards.dart`, `entry_form_sheet.dart`, `receive_payment_sheet.dart`, `net_pay_breakdown_card.dart` |
| `home` | `pages/home_page.dart` | `bloc/home_bloc.dart` | `widgets/home_cards.dart` |
| `account` | `pages/account_page.dart`, `pages/category_page.dart` | `bloc/account_bloc.dart`, `bloc/category_manager_bloc.dart` | `currency_setting.dart`, `language_setting.dart`, `category_setting.dart` |
| `onboarding` | `pages/onboarding_page.dart` | — | `onboarding_language_step.dart`, `onboarding_currency_step.dart`, `onboarding_scene.dart` |

Tampilan entitas bersama ada di `lib/shared/<modul>/presentation/` lewat
barrel `<modul>_presentation.dart`: `wallet_select_field.dart`,
`wallet_balance_preview.dart`, `transaction_date_group_card.dart`,
`transaction_display.dart`, `category_display.dart`, `category_name_dialog.dart`.

Domain bersama: `lib/shared/wallet/`, `lib/shared/transaction/`, `lib/shared/category/`.
Keduanya relevan kalau perlu tahu apa yang sebenarnya dihitung (mis.
`CalculateWalletBalance`, `RecomputeWalletBalances`) sebelum menilai angka
yang tampil.
