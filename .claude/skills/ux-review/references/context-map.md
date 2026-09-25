# Peta konteks — baca sebelum menilai apa pun

## Dokumen (baca dulu, urut)

| Berkas | Kenapa dibaca |
|---|---|
| `docs/01-product/prd-saldough-2.0.md` — §5 "Prinsip produk", §7 FR, §8.4 NFR-UX | Tujuan produk dan FR — acuan "apakah ini sesuai kebutuhan" sebelum menilai "apakah ini enak dipakai". NFR-UX-001 (catat dalam satu layar) dan NFR-UX-005 (kosakata pencatatan) paling sering relevan. `prd-saldough-1.0.md` hanya arsip — jangan jadikan acuan. |
| `docs/00-foundation/PROJECT_GLOSSARY.md` | Istilah resmi (`Dompet`, `Saldo tercatat`, `Pos anggaran`, `Worklog`, dst) dan tabel "Bahasa yang dipakai aplikasi" (Pakai / Jangan pakai). Acuan checklist kategori D. |
| `docs/02-architecture/DOMAIN_MODEL.md` | Entitas dan rumus. Beberapa hal yang kelihatan aneh di UI adalah invarian domain yang disengaja: transfer tidak dihitung sebagai masuk/keluar, saldo boleh negatif, anggaran tidak mengubah saldo, worklog tidak menyentuh saldo. |
| `docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md` — §3 dan §7 | Bahasa visual pixel (palet, tipografi, bayangan keras, garis tepi 2px, sistem ikon) beserta batasan dan antipolanya. Keputusan pemilik — bukan hal yang perlu dipertanyakan lagi. |
| `docs/02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md` — §3 | "Satu peran, satu warna": terracotta = aksi, hijau = uang masuk, merah = uang keluar, biru = transfer, amber = status. Kontrak slot teks-aman vs `…Fill`. Acuan checklist kategori E. |
| `.claude/AGENT_CONTEXT.md` — "Tampilan" dan "Nilai yang sudah terkonfirmasi" | Aturan tampilan yang mengikat, dan nilai yang SUDAH dikonfirmasi pemilik (jangan tanya ulang). |
| `docs/04-planning/TASK_LIST.md` — Fase 2 (T-2.1 s.d. T-2.12) | Catatan `⚠` = keputusan UI yang sudah diambil bersama pemilik. Jangan dilaporkan ulang sebagai temuan baru. |
| `docs/04-planning/UI_UX_DESIGN_TASKS.md` | Status desain per layar dan catatan terbuka. |
| `docs/stitch_pixel_finance_tracker/pixel_kas_*/` | Rujukan visual layar dari pemilik (`screen.png` + `code.html`), mis. `pixel_kas_catat_pengeluaran`, `pixel_kas_daftar_dompet`, `pixel_kas_riwayat_transaksi_kosong`. Rujukan, bukan spesifikasi piksel — ADR-015 §7 melarang menyalin CSS-nya. |

## Kode — zona `core` (dipakai semua layar)

- `lib/core/theme/` — `AppColorsExtension` (palet `pixelLight`/`pixelDark` untuk layar 2.0; `light`/`dark` ADR-0006 hanya tema global lama), `PixelTheme`, token `AppSpacing`/`AppRadius`/`AppBorder`/`AppElevation`. Baca nilainya di sini, jangan menebak dari nama variabel.
- `lib/core/presentation/widgets/` — komponen bersama: `AppHardCard`, `AppButton`, `AppChip`, `AppQuickChip`, `AppMoneyText`, `AppIcon`/`CategoryIcon`, `AppSkeleton`, `AppSegmentedProgressBar`, `FullScreenSheet`, `ConfirmDeleteDialog`, `AppMenuSelectButton`. Cek di sini dulu sebelum menilai "kenapa kartu ini beda dengan kartu itu" — biasanya bedanya hanya parameter.
- `lib/core/presentation/shell/app_shell_page.dart` — shell di rute `/home`: lima slot navigasi bawah (Beranda, Anggaran, **CATAT** di tengah, Transaksi, Dompet). CATAT membuka lembar pilihan, bukan tab. Tab yang belum dibangun memakai `_ComingSoonTab`.
- `assets/i18n/id.i18n.json` (dan `en`) — seluruh copy antarmuka. Baca JSON-nya langsung untuk audit copy — lebih cepat daripada grep tiap `t.xxx.yyy`. Kode hasil slang ada di `lib/core/i18n/`.

## Kode — zona `features`

Baca `*_state.dart` sebelum page/widget. Flag seperti `isLoading`,
`loadFailed`, `isSaving` menentukan state apa yang SEHARUSNYA tampil. Kalau
widget tidak mengecek flag itu, itu temuan nyata, bukan dugaan.

| Fitur | Layar / lembar | Bloc | Widget penting |
|---|---|---|---|
| `record` (CATAT — satu-satunya jalur pembuatan transaksi manual) | `presentation/open_record_sheet.dart`, `open_edit_transaction_sheet.dart`; `widgets/record_choice_sheet.dart`, `income_form_sheet.dart`, `expense_form_sheet.dart`, `transfer_form_sheet.dart` | `presentation/bloc/record_bloc.dart` (`RecordState`: `wallets`, `isLoading`, `isSaving`, `loadFailed`) | `record_form_frame.dart`, `record_amount_field.dart`, `record_category_field.dart`, `wallet_select_field.dart`, `wallet_balance_preview.dart`, `record_saving_dialog.dart` |
| `transaction` (riwayat) | `pages/transaction_list_page.dart`, `pages/transaction_detail_page.dart` | `presentation/bloc/transaction_bloc.dart` (`TransactionState`: `month`, filter jenis/dompet/kategori, `searchQuery`, `groups`, `typeCounts`, `isLoading`, `loadFailed`) | `transaction_filter_bar.dart`, `transaction_month_header.dart`, `transaction_date_group_card.dart`, `transaction_empty_states.dart`, `transaction_display.dart` |
| `wallet` | `pages/wallet_list_page.dart`, `pages/wallet_detail_page.dart` | `presentation/bloc/wallet_bloc.dart` (`WalletState`: `wallets`, `isLoading`, `loadFailed`) | `wallet_card.dart`, `wallet_summary_card.dart`, `wallet_form_sheet.dart`, `wallet_empty_states.dart`, `wallet_type.dart` |
| `freelance` | Belum ada layar (Fase 5). Baru domain `CalculateNetPay` | — | — |
| `example_note` | Fitur bukti pola, hanya dari menu pengembang debug | — | Bukan bagian produk — **jangan direview** |

Domain bersama: `lib/shared/wallet/` dan `lib/shared/transaction/`.
Keduanya relevan kalau perlu tahu apa yang sebenarnya dihitung (mis.
`CalculateWalletBalance`, `RecomputeWalletBalances`) sebelum menilai angka
yang tampil.
