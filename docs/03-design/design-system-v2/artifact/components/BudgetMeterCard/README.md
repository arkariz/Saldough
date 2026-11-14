# BudgetMeterCard

Kartu pos anggaran. Tingkat `card`, sudut 16, padding 14, jarak 8. Kepala: ikon 17px + judul 15 w600 dan badge netral di kanan. Nominal: terpakai `amount` + "/ total" `bodySm`; sisa `amountSm` `income` di kanan. Lalu meter `budget` dan kaki tiga label Space Mono `text-muted` (awal, tengah, akhir periode).

Anggaran adalah rencana, bukan pemesanan uang: kartu tidak mengubah saldo dompet.

**Flutter:** `DsBudgetMeterCard`, `DsSegmentMeter`.
