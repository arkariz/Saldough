# Prompt Gemini: ilustrasi onboarding yang bervariasi

**Status:** Usulan (designer, 20 Okt 2026). Permintaan aset ke pemilik: ilustrasi
tiap langkah onboarding Fase 21 selama ini memakai ulang tiga gambar yang ada
(`onboarding_3`, `onboarding_4`, `onboarding_5`). Berkas ini berisi prompt untuk
membuat gambar baru yang berbeda satu sama lain tetapi tetap satu keluarga.
**Berkaitan:** [ONBOARDING_ART_BRIEF.md](../../../01-product/features/ONBOARDING_ART_BRIEF.md)
(maskot dan aturannya), [FEATURE_DISCOVERY.md](../../../01-product/features/FEATURE_DISCOVERY.md) §4,
T-21.0.

## Cara pakai

1. Buka Gemini (model gambar, mis. Nano Banana / Gemini 2.5 Flash Image atau
   yang lebih baru). Satu percakapan baru untuk tiap gambar.
2. **Lampirkan gambar rujukan**: `assets/illustration/onboarding_3.png`,
   `onboarding_4.png`, `onboarding_5.png`, dan `mascot_head.png`. Tanpa
   rujukan, tanuki akan berubah rupa di tiap gambar.
3. Tempel **Blok gaya** (di bawah), lalu **satu** prompt adegan.
4. Pilih hasil yang rupa tanuki-nya paling mirip rujukan. Bila gaya melenceng
   (halus, 3D, anti-alias), kirim: *"Redo as strict pixel art: visible square
   pixels, no gradients, no smoothing, same character as the references."*
5. Latar: Gemini tidak membuat transparansi sungguhan. Minta latar putih polos
   (sudah ada di blok gaya), lalu hapus latarnya dengan alat penghapus latar
   dan simpan PNG transparan. Skala ulang dengan *nearest neighbor* (tanpa
   penghalusan) bila perlu.
6. Simpan sebagai `onboarding_6.png` dst. di `assets/illustration/` (engineer
   yang memasangnya; designer tidak mengubah `assets/`). Periksa hasil dengan
   daftar periksa di bagian akhir.

## Blok gaya (tempel di awal setiap prompt)

```
Use the attached images as the exact character and style reference.

Style: true pixel art, crisp square pixels clearly visible, limited warm
palette, 1-pixel dark brown outlines, flat shading with at most two tones per
colour, NO gradients, NO anti-aliasing, NO blur, NO 3D, NO glow. Cozy,
friendly, tidy "notebook" mood. Plain pure white background (#FFFFFF), no
floor shadow, no border, no frame. No text, no letters, no numbers, no logos,
no watermark.

Palette (stay inside it): terracotta #A94F33 (scarf, accents), cream #F7F5F2,
warm brown fur #8A5A3A and tan belly #E3C9A0, straw yellow #D9A441, dark
outline brown #2A1F18, soft sand #F0E3D3, muted sage #8FA884 used sparingly.

Character (identical in every image): Nuki the tanuki, small and round, warm
brown-grey fur, dark raccoon-dog eye mask, cream muzzle and belly, thick
striped tail, small straw hat, terracotta scarf. Calm, friendly, careful
bookkeeper personality. Never holds coins, cash, cards or a sake bottle, and
never has a leaf on the head. If a prop is needed, use a small brown ledger
and a yellow pencil.

Composition: one clear subject, generous empty space around it, readable at
small size on a phone (about 200 px tall).
```

## Prompt adegan

Setiap adegan berbeda **komposisi, sudut, dan prop**; palet dan tanuki sama.

### A. Awal periode keuangan (tanggal gajian), lanskap 4:3

```
Scene: Nuki stands beside a big wall calendar that is a simple grid of empty
squares, with ONE square circled by a thick terracotta ring and a small
pencil tucked behind the ear. Nuki points at the circled square with the
yellow pencil and looks at the viewer. A small sun icon rises behind the
calendar. Side view, slightly low angle, calendar taking about half the
image. Mood: calm planning, "this is where my month starts".
Aspect ratio 4:3.
```

### B. Pengingat rutin, persegi 1:1

```
Scene: Nuki sits at a small wooden desk ringing a little brass hand bell
with one paw, with three pixel "sound lines" next to the bell. On the desk:
a tear-off paper calendar and a row of three blank bill slips (plain
rectangles with one small pixel lightning-bolt, water-drop and wifi symbol,
no words). A tiny alarm clock sits on the desk edge. Front view, centred,
symmetrical. Mood: gentle reminder, not urgent.
Aspect ratio 1:1.
```

### C. Catat dari notifikasi (penutup / Mulai cepat), potret 3:4

```
Scene: Nuki holds a large open brown ledger below, and from the top of the
image several small phone-notification bubbles (rounded rectangles with a
tiny bell and two blank text lines, no real text) float down in a gentle S
curve into the ledger's pages, where each one becomes a neat ruled line.
Nuki tilts the head up, curious and pleased, pencil ready. Slight
top-down angle. Mood: notifications turning into tidy records.
Aspect ratio 3:4.
```

### D. Mulai cepat (pilih aplikasi), lanskap 4:3

```
Scene: A big smartphone in the centre-left shows a 3x2 grid of generic
rounded-square app icons (a small bank building, a wallet, a coin-less
e-wallet shape, three blank squares), three of them with a terracotta
check mark. Nuki stands on the right, ticking the next one with the yellow
pencil, one foot slightly raised. Flat front view. Mood: quick, easy
choosing.
Aspect ratio 4:3.
```

### E. Penutup, variasi baru (potret 3:4)

```
Scene: Nuki waves with one paw while walking on a short stepping-stone path
toward an open wooden chest that is still empty (lid up, inside empty), with
a small flag on a stick next to it and a sunrise behind. Three-quarter view
from behind-left, Nuki small in the lower third, lots of sky. Mood:
welcoming, ready to start, hopeful.
Aspect ratio 3:4.
```

### F. Cadangan: bahasa dan mata uang, persegi 1:1 (opsional)

```
Scene: Nuki holds a small globe-like round pixel sticker in a simple wooden
frame on a table with two blank speech bubbles above (no text, just
different bubble shapes) and a small money-less scale icon. Cheerful,
friendly, curious. Centred, front view.
Aspect ratio 1:1.
```

## Mengatur variasi

- Tiga gambar yang ada memakai tanuki di sisi kanan atau di bawah dan nada
  oranye-cokelat. Untuk variasi, ganti **warna aksen kedua** per gambar
  dengan menambahkan satu baris di akhir prompt, mis.:
  - A: `Secondary accent: muted sage #8FA884.`
  - B: `Secondary accent: soft amber #F0C879.`
  - C: `Secondary accent: dusty blue #7C9BB8, used only on the notification bubbles.`
  - D: `Secondary accent: warm teal #5E9C93, used only on the check marks.`
- Bila hasil terlalu seragam, tambahkan: `Change the camera angle and the
  pose; do not reuse the pose from the reference images.`

## Daftar periksa sebelum dipakai

- [ ] Tanuki sama dengan rujukan: topi jerami, syal terakota, topeng mata, ekor bergaris.
- [ ] Pixel nyata (kotak terlihat), tanpa gradasi atau pinggiran halus.
- [ ] Tanpa teks, angka, logo, atau koin/uang/kartu di tangan tanuki.
- [ ] Hanya warna dari palet; kontras cukup di latar krem terang **dan** kartu gelap.
- [ ] Subjek terbaca di tinggi sekitar 120–150 px; tepi bersih setelah latar dihapus.
- [ ] Rasio sesuai papan: lanskap 4:3 untuk kartu langkah, potret 3:4 untuk penutup.
