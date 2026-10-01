---
name: release-email
description: Buat email pembaruan rilis Tanukonomy untuk penguji closed testing (Google Group), dalam bahasa Indonesia, berupa HTML bergaya pixel yang siap disalin ke Gmail. Isi diambil dari git (tag, commit, anotasi tag) dan TASK_LIST, hanya perubahan yang terasa oleh pengguna. Gunakan saat pemilik minta "buatkan email rilis/update", "email release note untuk penguji", "email untuk versi X", atau "email dari tag A sampai B". Bukan untuk listing Play Store, catatan rilis "What's new" di Play Console, atau postingan promosi.
---

# Email pembaruan rilis untuk penguji

Pemilik cukup bilang "buatkan email rilis", kadang dengan rentang tag.
Hasilnya satu berkas HTML dari `assets/email-template.html`, terisi, plus
subjek dan daftar hal yang perlu dicek pemilik sebelum mengirim.

Email dikirim ke `tanukonomy-closed-tester@googlegroups.com` dari Gmail
pemilik. Pembacanya penguji awam, bukan pengembang.

## 1. Tentukan rentang

- Ambil tag terbaru: `git fetch --tags origin`, lalu
  `git tag --sort=creatordate`.
- Pemilik menyebut rentang (mis. "dari 0.2.0+3 sampai 0.3.0+4-patch-3")
  → pakai persis itu.
- Pemilik tidak menyebut rentang → dari tag yang terakhir dikirimi email
  sampai tag terbaru. Tag yang sudah diumumkan tidak tercatat di repo, jadi
  **tanya** pemilik versi mana yang terakhir diumumkan kalau tidak jelas
  dari percakapan. Jangan menebak: email yang mengulang fitur lama atau
  melewatkan fitur membingungkan penguji.
- Versi untuk subjek: baris `version:` di `pubspec.yaml` pada tag akhir
  (`git show <tag>:pubspec.yaml`). Tag `-patch-N` biasanya memakai versi
  yang sama; sebut versi tanpa sufiks patch, dan ingatkan pemilik
  mencocokkannya dengan Play Console.

## 2. Kumpulkan bahan

Baca dari tag, bukan dari working tree (branch aktif bisa berbeda):

```bash
git log --format='%h %s' <awal>..<akhir>
git tag --merged <akhir> --no-merged <awal>           # tag di dalam rentang
git tag -l --format='%(contents)' <tag>                 # anotasi: sumber terbaik
git log -1 --format=%B <commit>                         # badan commit besar
git show <akhir>:docs/04-planning/TASK_LIST.md > <scratchpad>/tl.md
```

- Anotasi tag yang punya bagian "Perubahan untuk pengguna" adalah sumber
  paling tepercaya; mulai dari sana.
- Untuk tiap kode tugas (`T-x.y`, `B-n`) yang disebut commit, baca entrinya
  di TASK_LIST: centang `[x]`/`[ ]`, catatan **"Belum teruji"**/**"Belum
  dicek di HP"**, dan perubahan perilaku.
- Nama menu dan tombol yang disebut di email: cek ejaannya di
  `assets/i18n/id.i18n.json` pada tag akhir. Jangan mengarang nama menu.

Jangan membaca kode sumber kecuali satu klaim benar-benar tidak bisa
dipastikan dari dokumen. Biaya token adalah pertimbangan nyata di proyek ini.

## 3. Pilah

Masuk email hanya yang **terasa oleh pengguna**:

| Bagian template | Isi |
|---|---|
| ✨ Yang baru | Fitur atau kemampuan baru, satu kartu per fitur, paling banyak 5; urutkan dari yang paling berdampak |
| 🔧 Yang diperbaiki | Gejala yang dulu dialami pengguna dan sekarang hilang |
| ⚠️ Perlu kamu ketahui | Data yang dimigrasi/diubah otomatis, perilaku yang berubah, fitur yang butuh internet, keterbatasan yang sudah diketahui |
| 🧪 Bantu kami mencoba | 2–3 skenario untuk fitur yang paling butuh data nyata, terutama yang di TASK_LIST tertulis belum teruji di perangkat |

**Buang:** refactor, arsitektur, uji, CI, versi SDK, dokumen, ADR, menu
pengembang, dan perapian kode tanpa perubahan tampilan.

Hapus bagian yang kosong (seluruh bloknya, termasuk judulnya). Bagian
"Cara memberi masukan" dan kotak "Untuk penguji awal" selalu ada.

## 4. Tulis

- Bahasa Indonesia, sapaan "kamu", hangat dan ringkas.
- Tulis manfaat dan cara pakai, bukan nama teknis. Tidak boleh ada kode
  tugas, nomor ADR, nama kelas, nama paket, atau istilah seperti "bloc",
  "migrasi skema", "STT".
- Kosakata produk: aplikasi **mencatat**, bukan melakukan. "Catat
  transfer", bukan "transfer uang". Jangan menulis seolah aplikasi
  membayar, memindahkan uang, atau terhubung ke bank.
- Jangan menyuruh kebiasaan ("catat setiap hari"). Tawarkan solusinya saja.
- Jangan mengarang angka, testimoni, jumlah pengguna, atau tanggal rilis.
- Fitur yang menurut TASK_LIST belum teruji dengan pemakaian nyata tetap
  boleh diumumkan, tapi masukkan ke "Bantu kami mencoba" dan beri flag ke
  pemilik (langkah 6).
- Hadiah penguji: biarkan `[durasi]` kecuali pemilik sudah menyebut
  durasinya di percakapan.
- Saluran masukan: "balas email ini" dan "Masukan pribadi untuk
  developer" di Play Store. Jangan menyebut `halo@tanukonomy.app` kecuali
  pemilik bilang email itu sudah bisa menerima pesan.

## 5. Isi template

Salin `assets/email-template.html` ke scratchpad sebagai
`email-rilis-<versi>.html`, lalu isi:

- Kepala: `Versi [versi] sudah tersedia` dan satu kalimat sorotan.
- Paragraf pembuka: `[versi] ([nomor build])`.
- Kartu fitur: ulangi blok di antara `<!-- ULANGI -->` dan
  `<!-- /ULANGI -->`; baris jarak 8px hanya di antara kartu.
- `<li>` di bagian lain sesuai jumlah butir.
- Hapus komentar `ULANGI` dan semua isian `[...]` yang sudah terjawab.
  Isian yang memang harus diisi pemilik (`[durasi]`, `[Nama kamu]`) tetap
  dalam kurung siku.

Jangan mengubah warna, gaya inline, atau struktur tabel. Gmail membuang
`<style>` dan kelas CSS, jadi semua gaya harus tetap inline.

## 6. Serahkan

1. Kirim berkas dengan `SendUserFile` (`display: render`).
2. Di balasan, tulis:
   - **Subjek** siap salin, maksimal ±60 karakter:
     `Tanukonomy <versi>: <2–3 sorotan>`.
   - **Cara kirim** singkat: buka HTML di peramban → Ctrl+A, Ctrl+C →
     tempel di Gmail ke alamat grup → kirim percobaan ke diri sendiri dulu.
     Jangan kirim lewat situs Google Groups (gaya hilang).
   - **Cek sebelum kirim**, hanya yang berlaku untuk rilis ini:
     - fitur yang belum teruji di perangkat (sebut kode tugasnya);
     - fitur baru yang mengirim data keluar perangkat (jaringan, AI, audio):
       cek apakah kebijakan privasi di `arkariz/tanukonomy-web` dan tugas
       Keamanan Data di TASK_LIST sudah menyebutnya; kalau belum, beri draf
       paragraf pemberitahuan untuk "Perlu kamu ketahui";
     - migrasi data yang belum dicek dengan data lama sungguhan;
     - isian yang masih tersisa (`[durasi]`, `[Nama kamu]`, nomor build).

Jangan meng-commit berkas email. Itu hasil sekali pakai, bukan bagian repo.
