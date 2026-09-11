# Peta konteks — baca sebelum menilai apa pun

## Dokumen (baca dulu, urut)

| Berkas | Kenapa dibaca |
|---|---|
| `docs/01-product/prd-saldough-1.0.md` | Tujuan produk dan FR — acuan "apakah ini sesuai kebutuhan" sebelum menilai "apakah ini enak dipakai". |
| `docs/02-architecture/DOMAIN_MODEL.md` | Entitas dan rumus. Banyak hal yang kelihatan aneh di UI (nominal `rollUp` tidak bisa disunting, baris `needsReview`) sebenarnya invarian domain yang sengaja — bukan bug UX. |
| `docs/00-foundation/PROJECT_GLOSSARY.md` | Istilah resmi proyek (`siklus`, `baris`, `pos`, `rencana belanja`, dst). Dipakai mengecek konsistensi copy (checklist kategori D). |
| `docs/02-architecture/adr/0006-design-token-semantic-color-mapping.md` | Palet, tipografi, dan bahasa visual "komik/meme" yang DISENGAJA (bukan konvensi fintech biasa, dan itu keputusan pemilik, bukan sesuatu yang perlu dipertanyakan lagi). Jadi acuan checklist kategori E. |
| `.claude/AGENT_CONTEXT.md` bagian "Tampilan" dan "Nilai seed yang sudah terkonfirmasi" | Aturan token yang mengikat + nilai yang SUDAH dikonfirmasi pemilik (jangan tanya ulang atau tandai sebagai "tidak jelas dari mana asalnya"). |
| `docs/04-planning/TASK_LIST.md` — cari "Catatan pengerjaan" tiap fase, terutama bagian setelah Fase 6 | Daftar 9 perbaikan UI/UX yang SUDAH dikerjakan dari laporan pemilik sebelumnya. Jangan dilaporkan ulang sebagai temuan baru. |
| `docs/04-planning/UI_UX_DESIGN_TASKS.md` | Status desain per layar, kalau ada catatan terbuka yang masih relevan. |

## Kode — satu per zona

Zona `core` (bukan per fitur, tapi dipakai semua layar):

- `lib/core/theme/` — token (`AppColorsExtension`, `AppSpacing`, `AppRadius`) dan `AppTheme`. Kalau checklist kategori E butuh tahu nilai hex/ukuran pasti, baca di sini, jangan menebak dari nama variabel.
- `lib/core/presentation/widgets/` — komponen bersama (`AppButton`, `AppChip`, `AppMoneyText`, dst). Cek di sini dulu sebelum menilai "kenapa tombol ini beda sama tombol itu" — kemungkinan besar semua screen memang memakai komponen yang sama, dan Bedanya hanya parameter.
- `lib/core/presentation/shell/main_shell_page.dart` — struktur bottom nav 4 tab, dan urutan dependensi tab mana yang punya rute sendiri (worklog, card) vs yang cuma tab.
- `lib/core/i18n/` (dan `assets/i18n/id.i18n.json`) — seluruh copy antarmuka. Baca `id.i18n.json` langsung untuk audit copy — lebih cepat daripada grep tiap `t.xxx.yyy` satu-satu.

Zona `features` — satu layar, satu bloc, satu sheet (kalau ada):

| Fitur | Page | Bloc (state+event+effect) | Sheet/dialog |
|---|---|---|---|
| `cycle` (tab utama, paling kompleks) | `presentation/pages/cycle_page.dart` | `presentation/bloc/cycle_bloc.dart` (+ `_state.dart`/`_event.dart`/`_effect.dart`) | `presentation/widgets/line_edit_sheet.dart` |
| `income` | `presentation/pages/income_source_list_page.dart` | `presentation/bloc/income_source_bloc.dart` | `presentation/widgets/income_source_edit_sheet.dart` |
| `worklog` | `presentation/pages/worklog_page.dart` | `presentation/bloc/worklog_bloc.dart` | — |
| `grocery` | `presentation/pages/grocery_page.dart` | `presentation/bloc/grocery_bloc.dart` | — |
| `card` | `presentation/pages/card_page.dart` | `presentation/bloc/card_bloc.dart` | `presentation/widgets/credit_card_edit_sheet.dart`, `recurring_subscription_edit_sheet.dart` |
| `investment` | `presentation/pages/investment_page.dart` | `presentation/bloc/investment_bloc.dart` | `presentation/widgets/goal_edit_sheet.dart`, `goal_loan_edit_sheet.dart` |

Baca `*_state.dart` sebelum `*_page.dart` — state yang membawa flag seperti
`isLoading`, `canDeleteCycle`, `rollUpSourceUnavailable`, `needsReview`
menentukan state apa yang SEHARUSNYA tampil di UI; kalau widget tidak
mengecek flag itu, itu temuan nyata (bukan dugaan).
