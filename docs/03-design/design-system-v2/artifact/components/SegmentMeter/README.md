# SegmentMeter

Meter tersegmen: 10 segmen sama lebar, jarak 4px. Persen dibulatkan ke bawah per segmen.

- `health` (6px, pil): kartu mood.
- `budget` (10px, sudut 4): segmen terisi `action-primary`, segmen terakhir yang terisi `income`; kosong `surface-sunken`. Melewati batas: `warning`, lalu `error` (aturan status; tidak ada di acuan).
- Opsi `breathing` di aplikasi: segmen bernapas 2,2 dtk. Berhenti saat gerak dikurangi.

Selalu disertai angka atau teks; meter bukan satu-satunya sumber informasi.

**Flutter:** `DsSegmentMeter`.
