# TopBar

Top bar dan kepala halaman.

**Top bar** (`ds-topbar`, 56px): latar `surface-canvas` 90% + blur, garis bawah `outline-subtle`. Kiri: logo 28px, logo kata "tanukonomy" (Space Mono, huruf kecil, `action-primary`) dan daun bulat 16px. Kanan: lonceng dan avatar.
**Kepala halaman** (`ds-pagehead`): sapaan `headlineSm` di kiri, status pill di kanan, subjudul `bodySm` `text-muted` di bawahnya. Selisih acuan: sapaan 22px tidak ada di skala; dipetakan ke 18 atau 24.
**Kepala bagian** (`ds-section`): ikon 18px `action-primary` + judul 15 w600; tautan "Semua ›" Space Mono kapital `action-primary`.
**Catatan kaki** (`ds-footnote`): Space Mono kapital `text-secondary` 60%.

App bar menyusut di gulir 110–240px (`DsCollapsingTopBar`); bayangan setelah 15px.

**Flutter:** `DsTopBar`, `DsPageHeader`, `DsSectionHeader`, `DsFootnote`.
