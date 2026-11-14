# Card

Tiga tingkat permukaan tanpa bayangan dekoratif (spek: "zero decorative shadows"; acuan memakai bayangan sangat tipis dan itu yang dipakai).

| Tingkat | Token | Bingkai | Bayangan |
|---|---|---|---|
| 0 kanvas | `surface-canvas` | – | – |
| 1 kartu, baris, input | `surface-card` | `outline-subtle` 1px | `shadow-card` (0 2 8, 3%) |
| 2 popover, dialog, sheet | `surface-overlay` | `outline-overlay` | `shadow-overlay` |

Sudut kartu 16 (`radius-lg`), dialog 24, sheet 20. Keadaan ditekan **tidak** menaikkan elevasi: bingkai pindah ke `outline-focus` atau isi ke `surface-hover`. `ds-listcard` untuk daftar: pemisah 1px `outline-subtle`.

**Flutter:** `DsCard`, `DsListCard`, `DsElevation`.
