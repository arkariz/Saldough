# NavBar

Navigasi bawah dengan empat tujuan dan tombol Catat di tengah.

**Isi tetap:** Beranda (`home`), Riwayat (`receipt_long`), Catat (`add`, kotak terakota bersudut piksel dengan bayangan piksel, terangkat), Anggaran (`donut_small`), Dompet (`account_balance_wallet`).

**Aturan**
- Tombol Catat dibungkus `tk-pixel-shadow` supaya bayangan kerasnya mengikuti sudut piksel.
- Tab aktif: pil `brand-soft` di belakang ikon berisi, label `ink`. Tab lain: ikon garis, label `ink-2`.
- Tombol Catat membuka sheet Catat. Tekan lama membuka Catat pakai suara. Tidak ada FAB lain di layar tab.
- Label selalu tampil; jangan pernah ikon saja.
- Disembunyikan di halaman turunan dan saat keyboard terbuka.
- Tambahkan area aman perangkat di bawahnya, bukan di dalam tinggi 72px.

**Disediakan pemakai:** tab aktif, handler pindah tab, handler Catat (ketuk dan tekan lama).
