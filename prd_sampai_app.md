# SAMPAI — Figma-Level Screen Specification
**Versi:** MVP v1.0  
**Tanggal:** 8 Oktober 2026  
**Platform:** Mobile app  
**Tagline:** *Bikin gaji sampai.*

---

## 1. Tujuan Dokumen

Dokumen ini menjadi blueprint desain dan implementasi untuk empat area MVP SAMPAI:

1. **Onboarding** — mengumpulkan data awal siklus gaji dan rencana keuangan.
2. **Home** — menunjukkan kondisi keuangan saat ini, terutama Safe-to-Spend dan Money Velocity.
3. **Add Expense** — mencatat pengeluaran secepat mungkin.
4. **Budget** — memantau dan mengatur anggaran selama siklus gaji.

Spesifikasi mencakup ukuran frame, hierarchy, penempatan komponen, interaksi, contoh data, state UI, dan aturan kalkulasi. Ukuran menggunakan px sebagai acuan Figma; pada implementasi mobile, sesuaikan dengan logical pixel / density platform.

## 2. Prinsip Produk dan UX

- **Salary-cycle first:** konteks utama adalah periode dari satu tanggal gajian ke tanggal gajian berikutnya, bukan hanya bulan kalender.
- **Cepat mencatat:** pengguna harus bisa menyimpan pengeluaran umum dalam beberapa langkah.
- **Jujur tentang data:** jika data saldo atau transaksi belum lengkap, tampilkan estimasi dan jangan menyebutnya sebagai saldo aktual.
- **Satu pesan utama:** Home harus menjawab “berapa yang aman saya belanjakan sekarang?”.
- **Tanpa rasa bersalah:** kondisi anggaran disampaikan secara jelas, bukan menghakimi.
- **Progressive disclosure:** detail kategori dan kalkulasi tersedia saat diperlukan, tetapi tidak membebani layar utama.

## 3. Design System

### 3.1 Frame dan grid

| Properti | Spesifikasi |
|---|---|
| Frame referensi | 390 × 844 px |
| Alternatif pengujian | 360 × 800 px dan 430 × 932 px |
| Page horizontal padding | 24 px |
| Grid dasar | 8 px |
| Jarak antar-section | 24 px |
| Jarak komponen terkait | 8–16 px |
| Card padding | 16–20 px |
| Card radius | 20 px |
| Input/button height | 56 px |
| Minimum touch target | 44 × 44 px |
| Bottom navigation | sekitar 72 px + safe area |
| Scroll | Konten dapat di-scroll; header dan bottom navigation dapat tetap terlihat sesuai platform |

**Catatan:** ukuran di atas adalah acuan desain, bukan batas kaku. Pastikan konten tidak terpotong pada layar kecil, ukuran font aksesibilitas, dan keyboard terbuka.

### 3.2 Warna

| Token | Hex | Penggunaan |
|---|---|---|
| Canvas | `#F7F7F5` | Background utama |
| Surface | `#FFFFFF` | Card, sheet, input |
| Primary | `#202522` | Teks utama, CTA |
| Secondary text | `#737873` | Label sekunder |
| Border | `#E5E7E3` | Outline, divider |
| Accent | `#E9F0C8` | Sorotan Safe-to-Spend |
| Success | `#E6F3E9` | Status aman |
| Warning | `#FFF0D7` | Peringatan |
| Critical background | `#FBE8E7` | Kondisi kritis |
| Critical text | `#A32925` | Teks kritis |
| Disabled | `#D9DCD7` | Komponen nonaktif |

Jangan mengandalkan warna saja untuk mengomunikasikan status. Sertakan label atau ikon yang relevan.

### 3.3 Typography

Gunakan **Inter** atau font sans-serif sistem yang konsisten.

| Style | Ukuran / line height | Weight | Penggunaan |
|---|---:|---:|---|
| Display | 36 / 42 px | 700 | Nilai Safe-to-Spend |
| H1 | 28 / 34 px | 700 | Judul layar |
| H2 | 22 / 28 px | 600 | Judul section/card |
| H3 | 17 / 24 px | 600 | Judul komponen |
| Body | 15 / 22 px | 400 | Konten utama |
| Body Strong | 15 / 22 px | 600 | Nilai dan aksi penting |
| Label | 13 / 18 px | 500 | Label field |
| Caption | 12 / 16 px | 400 | Helper text, tanggal |

### 3.4 Komponen bersama

- **Primary button:** tinggi 56 px, radius 16 px, background Primary, teks putih, lebar penuh pada form.
- **Secondary button:** tinggi minimal 48 px, surface putih, border Border.
- **Text field:** tinggi minimum 56 px, radius 14 px, padding horizontal 16 px.
- **Card:** Surface, radius 20 px, padding 16–20 px.
- **Progress bar:** tinggi 8 px, radius 999 px, track Border.
- **Category icon tile:** 64 × 64 px minimum, icon di tengah, label di bawah atau samping.
- **Bottom navigation:** Home, Budget, Transactions, Profile; gunakan label teks untuk kejelasan.
- **Currency formatter:** tampilkan format Rupiah Indonesia, misalnya `Rp8.000.000`, konsisten di seluruh aplikasi.

---

# 4. Onboarding

## 4.1 Tujuan

Mengumpulkan data minimum untuk membuat salary cycle dan estimasi awal. Hindari meminta terlalu banyak informasi sebelum pengguna merasakan manfaat aplikasi.

### Flow

`Welcome → Income → Payday → Fixed expenses → Savings & budget preview → Home`

Sediakan tombol **Kembali** pada langkah 2–5 dan indikator progres yang terlihat.

## 4.2 Screen 1 — Welcome

**Frame:** 390 × 844 px.

### Hierarchy dan placement

1. Area logo/wordmark SAMPAI di bagian atas, margin top mengikuti safe area.
2. Ilustrasi atau visual sederhana di tengah, sekitar 220 × 180 px.
3. Heading: “Bikin gaji sampai.”
4. Body: “Atur pengeluaran, sisihkan kebutuhan penting, dan tahu berapa yang aman dibelanjakan.”
5. CTA utama: “Mulai atur gaji”, tinggi 56 px, margin horizontal 24 px, dekat bagian bawah.
6. Link sekunder: “Saya sudah punya akun” jika autentikasi termasuk scope produk.

### Interaksi

- Tap CTA → Screen Income.
- Jika login diperlukan, jangan tampilkan link yang belum terhubung ke flow nyata.

## 4.3 Screen 2 — Income

**Tujuan:** menentukan pendapatan bersih yang tersedia per siklus.

### Layout

- Top bar: back + progress `1 dari 4`.
- Heading H1: “Berapa gaji bersihmu?”
- Helper: “Masukkan jumlah yang benar-benar masuk ke rekening setelah potongan.”
- Label field: “Gaji bersih per periode”.
- Input currency besar dengan prefix `Rp`.
- Pilihan frekuensi: `Bulanan` (default), `Mingguan`, `Dua mingguan`, bila produk mendukung selain bulanan.
- CTA bawah: “Lanjutkan”.

### Contoh data

- Gaji bersih: **Rp8.000.000**
- Frekuensi: **Bulanan**

### Validasi dan state

- Kosong: CTA nonaktif; helper “Masukkan jumlah gaji bersih.”
- Nilai nol/negatif: error inline “Jumlah harus lebih besar dari Rp0.”
- Input terlalu besar: validasi batas produk dan format ribuan; jangan mengubah nilai diam-diam.
- Loading saat menyimpan: CTA menampilkan indikator dan mencegah submit berulang.
- Error server: pertahankan input; tampilkan “Belum berhasil menyimpan. Coba lagi.”

## 4.4 Screen 3 — Payday

**Tujuan:** menetapkan awal siklus dan memperkirakan tanggal siklus berikutnya.

### Layout

- Top bar: back + progress `2 dari 4`.
- Heading: “Kapan gajian?”
- Helper: “Kami gunakan tanggal ini untuk menghitung sisa hari dalam siklus gajimu.”
- Pilihan tanggal: date picker atau pilihan tanggal 1–31.
- Field opsional: tanggal gajian berikutnya bila tanggal tidak tetap.
- Informasi kecil: “Jika tanggal gajian tidak ada di suatu bulan, gunakan hari terakhir bulan tersebut.”
- CTA: “Lanjutkan”.

### Contoh data

- Tanggal gajian: **25**
- Siklus contoh: **25 September–24 Oktober 2026**

### Aturan tanggal

- Untuk tanggal 29, 30, atau 31 yang tidak ada di bulan tertentu, gunakan hari kalender terakhir bulan itu.
- Tentukan batas siklus secara konsisten: tanggal gajian termasuk hari pertama siklus; siklus berakhir sehari sebelum tanggal gajian berikutnya.
- Simpan tanggal lokal dan timezone yang sesuai dengan pengguna.

## 4.5 Screen 4 — Fixed expenses

**Tujuan:** mencatat kewajiban berulang yang perlu disisihkan.

### Layout

- Top bar + progress `3 dari 4`.
- Heading: “Apa yang harus dibayar tiap gajian?”
- Helper: “Masukkan tagihan tetap. Kamu bisa menambah atau mengubahnya nanti.”
- Daftar baris tagihan, masing-masing berisi:
  - Nama tagihan
  - Jumlah Rupiah
  - Tanggal jatuh tempo atau opsi “Tanggal tetap”
  - Toggle aktif/nonaktif
  - Tombol hapus
- Tombol sekunder: “+ Tambah tagihan”.
- Ringkasan sticky di bawah daftar: “Total tagihan per siklus”.
- CTA: “Lanjutkan”.
- Link sekunder: “Lewati dulu” jika diperbolehkan oleh aturan produk.

### Contoh data

| Tagihan | Jumlah | Jatuh tempo |
|---|---:|---|
| Kos | Rp1.500.000 | Tanggal 1 |
| Transportasi | Rp500.000 | Tanggal 25 |
| Internet & pulsa | Rp300.000 | Tanggal 10 |
| Langganan | Rp100.000 | Tanggal 12 |
| Lainnya | Rp400.000 | Tanggal 15 |
| **Total** | **Rp2.800.000** | |

### Interaksi dan state

- Tap “Tambah tagihan” → tambahkan baris kosong.
- Hapus tagihan → hapus dari draft; jika sudah tersimpan, minta konfirmasi atau sediakan undo.
- Nilai tidak valid → pesan inline.
- Daftar kosong → empty state “Belum ada tagihan tetap” dan opsi lanjut.
- Jangan menyimpulkan semua tagihan bersifat bulanan jika frekuensinya tidak diketahui; MVP dapat menetapkan per siklus bulanan dengan label yang eksplisit.

## 4.6 Screen 5 — Savings & budget preview

**Tujuan:** menetapkan target simpanan dan menunjukkan gambaran rencana awal sebelum masuk Home.

### Layout

- Top bar + progress `4 dari 4`.
- Heading: “Mau sisihkan berapa?”
- Helper: “Tabungan dipisahkan dari uang belanja agar tidak terhitung dua kali.”
- Input target tabungan per siklus.
- Preview card:
  - Gaji bersih
  - Tagihan tetap
  - Target tabungan
  - Sisa untuk pengeluaran fleksibel
- CTA utama: “Buat rencana saya”.

### Contoh data

| Item | Nilai |
|---|---:|
| Gaji bersih | Rp8.000.000 |
| Tagihan tetap | Rp2.800.000 |
| Target tabungan | Rp1.000.000 |
| Anggaran fleksibel awal | Rp4.200.000 |

Perhitungan preview: `Rp8.000.000 − Rp2.800.000 − Rp1.000.000 = Rp4.200.000`.

### State dan interaksi

- Jika hasil fleksibel negatif, tampilkan warning yang jelas dan sarankan menurunkan target tabungan atau meninjau tagihan.
- CTA → simpan konfigurasi onboarding, buat salary cycle, lalu masuk Home.
- Jika penyimpanan gagal, jangan menghapus input pengguna.

---

# 5. Home

## 5.1 Tujuan

Home menjawab tiga pertanyaan dalam beberapa detik:

1. Berapa yang aman dibelanjakan sekarang?
2. Apakah pengeluaran berjalan terlalu cepat?
3. Apa kewajiban atau tindakan terdekat?

**Frame:** 390 × 844 px. Konten utama scrollable. Bottom navigation berada di bawah dan memperhitungkan safe area.

## 5.2 Hierarchy dan component placement

Urutan dari atas ke bawah:

### A. Header — tinggi sekitar 56 px

- Kiri: sapaan singkat, misalnya “Halo!”
- Baris bawah atau subtitle: “Siklus 25 Sep – 24 Okt”
- Kanan: avatar/profile atau tombol notifikasi.
- Padding horizontal 24 px.

### B. Safe-to-Spend card — margin top 16 px

**Ukuran acuan:** lebar penuh dalam margin 24 px, tinggi sekitar 220–250 px, padding 20 px, radius 20 px.

Isi:
1. Label: “AMAN DIBELANJAKAN”
2. Nilai utama Display: **Rp140.000/hari**
3. Helper: “Rata-rata per hari sampai gajian”
4. Divider atau ruang vertikal.
5. Baris ringkasan: “Sisa uang fleksibel” — contoh **Rp2.800.000**
6. Baris: “12 hari tersisa”
7. Link kecil: “Cara hitungnya”

Gunakan Accent `#E9F0C8` sebagai background card. Jika data belum lengkap, tampilkan badge teks **Estimasi** dan helper “Lengkapi saldo atau catatan pengeluaran agar hasil lebih akurat.”

**Interaksi:**
- Tap “Cara hitungnya” → bottom sheet penjelasan komponen kalkulasi.
- Tap nilai atau card → detail ringkasan keuangan bila halaman detail disediakan.
- Jangan membuat nilai per hari terlihat seperti saldo bank aktual.

### C. Money Velocity card — margin top 24 px

**Ukuran acuan:** tinggi 150–180 px, padding 16 px.

Isi:
- Header: “Money Velocity”
- Status ringkas: “Pengeluaran sedikit lebih cepat dari rencana”
- Progress waktu: **40% siklus berlalu**
- Progress pengeluaran fleksibel: **65% anggaran terpakai**
- Rasio: **1,63×**
- Caption: “Kamu menggunakan anggaran lebih cepat dibanding waktu yang sudah berjalan.”

Visual:
- Dua progress bar terpisah dengan label yang jelas.
- Bila rasio > 1, gunakan status warning.
- Bila rasio <= 1, gunakan status netral/positif.
- Jangan menyampaikan prediksi yang pasti; ini indikator laju, bukan jaminan uang akan habis.

### D. Budget summary — margin top 24 px

Header:
- “Anggaran bulan ini” atau lebih tepat “Anggaran siklus ini”
- Link “Lihat semua”

Contoh:
- Makan — Rp900.000 dari Rp1.200.000 (75%)
- Transportasi — Rp350.000 dari Rp600.000 (58%)
- Hiburan — Rp250.000 dari Rp400.000 (63%)

Setiap baris berisi ikon kategori, nama, nilai terpakai/anggaran, dan progress bar. Maksimal tiga kategori ditampilkan di Home; sisanya melalui Budget.

### E. Upcoming bills — margin top 24 px

Contoh:
- “Internet & pulsa” — Rp300.000 — “Jatuh tempo 10 Okt”
- “Langganan” — Rp100.000 — “Jatuh tempo 12 Okt”

Tampilkan hanya tagihan relevan dalam siklus berjalan, terutama yang belum dibayar. Jika tidak ada, tampilkan “Tidak ada tagihan terdekat.”

### F. Recent transactions — margin top 24 px

Header “Transaksi terbaru” + “Lihat semua”.

Contoh:
- Warung makan — Makan — `−Rp45.000` — Hari ini
- Kopi — Jajan — `−Rp28.000` — Hari ini
- Bensin — Transportasi — `−Rp75.000` — Kemarin

Floating action button `+` untuk Add Expense dapat dipakai jika tidak menutupi konten. Alternatif yang lebih aman: tombol “+ Catat pengeluaran” sebagai tombol yang terlihat jelas di atas bottom navigation.

### G. Bottom navigation

Item:
- Home
- Budget
- Transaksi
- Profil

Item aktif memiliki label dan indikator visual yang tidak hanya mengandalkan warna.

## 5.3 Contoh data Home

Untuk contoh visual, gunakan data simulasi yang konsisten:
- Gaji bersih: Rp8.000.000
- Tagihan tetap: Rp2.800.000
- Target tabungan: Rp1.000.000
- Anggaran fleksibel awal: Rp4.200.000
- Siklus: 25 Sep–24 Okt 2026
- Waktu siklus berlalu: 40%
- Pengeluaran fleksibel: Rp2.730.000 (65% dari Rp4.200.000)
- Sisa anggaran fleksibel: Rp1.470.000

**Penting:** angka Rp140.000/hari pada contoh Safe-to-Spend tidak otomatis sama dengan `Rp1.470.000 / 12`. UI produksi harus menampilkan nilai yang benar-benar dihasilkan oleh satu formula yang konsisten. Gunakan mock data terpisah hanya bila layar sedang dalam mode desain.

## 5.4 Home states

### Loading
- Skeleton untuk Safe-to-Spend, Money Velocity, dan daftar.
- Hindari menampilkan angka nol sebagai data final saat data masih dimuat.

### First-use / empty
- Safe-to-Spend: “Atur siklus gajimu untuk mulai menghitung.”
- CTA: “Selesaikan pengaturan”.
- Transaksi kosong: “Belum ada pengeluaran tercatat” + “Catat pengeluaran pertama”.

### Normal
- Tampilkan angka, tanggal siklus, status, dan daftar sesuai data.

### Warning
- Money Velocity > 1.
- Gunakan warna warning dan copy yang membantu, misalnya “Pengeluaran berjalan lebih cepat dari waktu siklus.”
- Berikan tindakan: “Tinjau anggaran”.

### Critical
- Safe-to-Spend = 0 atau kewajiban melebihi uang yang dialokasikan.
- Teks: “Anggaran harian sudah terpakai.”
- Hindari menampilkan nilai negatif sebagai uang yang “aman dibelanjakan”.
- Sediakan detail perhitungan dan cara mengubah rencana.

### Offline
- Tampilkan data terakhir yang tersimpan lokal dan label “Data terakhir diperbarui …”.
- Jangan mengklaim sinkronisasi berhasil sampai server mengonfirmasi.

### Error
- Pesan singkat: “Data belum bisa dimuat.”
- Tombol “Coba lagi”.
- Pertahankan data lokal bila tersedia.

---

# 6. Add Expense

## 6.1 Tujuan

Memungkinkan pengguna mencatat pengeluaran umum secara cepat, idealnya tanpa perlu berpindah layar penuh.

**Presentasi:** bottom sheet di atas Home atau Transactions.  
**Ukuran:** lebar mengikuti frame; top radius 24 px; tinggi menyesuaikan konten dan keyboard. Gunakan scroll saat layar kecil.

## 6.2 Layout dan hierarchy

### A. Sheet header

- Handle di tengah.
- Judul: “Catat pengeluaran”.
- Tombol close di kanan atas, touch target minimum 44 × 44 px.

### B. Amount input

- Label kecil: “Jumlah”
- Input utama 32 px / 38 px, weight 700.
- Contoh nilai: `Rp75.000`
- Default keyboard numerik.
- Nilai tidak boleh kosong atau nol saat submit.

### C. Category picker

Grid 4 kolom jika ruang mencukupi; pada layar kecil gunakan horizontal scroll atau grid 3 kolom.

Kategori awal:
- Makan
- Transportasi
- Belanja
- Tagihan
- Hiburan
- Kesehatan
- Keluarga
- Lainnya

Setiap item:
- Icon tile sekitar 64 × 64 px
- Label 12–13 px
- Selected state dengan border atau background, bukan hanya perubahan warna.

### D. Detail tambahan

- Field catatan opsional: “Beli apa? (opsional)”
- Tanggal transaksi, default hari ini.
- Akun/sumber dana hanya bila fitur multi-account masuk scope MVP.
- Jika offline, simpan lokal dengan status pending sync jika arsitektur mendukung.

### E. CTA

- Tombol lebar penuh, tinggi 56 px: “Simpan pengeluaran”.
- Tombol tetap terlihat di atas keyboard bila memungkinkan; jangan menutupi field.
- Setelah simpan sukses, tutup sheet dan perbarui Home/Budget secara optimistis hanya jika penyimpanan lokal berhasil.

## 6.3 Contoh pengisian

- Jumlah: **Rp75.000**
- Kategori: **Makan**
- Catatan: **Makan siang**
- Tanggal: **8 Okt 2026**

Setelah tersimpan, transaksi tampil sebagai:
`Makan siang · Makan · −Rp75.000 · 8 Okt 2026`

## 6.4 Interaksi

- Tap amount → fokus input dan buka numeric keyboard.
- Tap kategori → pilih satu kategori; pilihan sebelumnya dilepas.
- Tap tanggal → date picker.
- Tap simpan:
  1. Validasi jumlah.
  2. Validasi kategori jika diwajibkan.
  3. Cegah double submit.
  4. Simpan transaksi.
  5. Perbarui total pengeluaran, budget kategori, Safe-to-Spend, dan Money Velocity.
  6. Tampilkan konfirmasi singkat, misalnya “Pengeluaran tersimpan”.
- Close dengan data belum disimpan → konfirmasi hanya bila ada input yang berisiko hilang; jangan mengganggu jika form masih kosong.

## 6.5 Validation dan states

- **Empty:** jumlah belum diisi; CTA nonaktif atau menampilkan error saat submit.
- **Invalid amount:** “Masukkan jumlah lebih dari Rp0.”
- **Category missing:** “Pilih kategori pengeluaran.”
- **Saving:** CTA loading dan nonaktif untuk mencegah duplikasi.
- **Success:** sheet menutup; transaksi baru muncul di daftar.
- **Error:** sheet tetap terbuka, semua input dipertahankan, pesan “Belum berhasil menyimpan. Coba lagi.”
- **Offline:** bila penyimpanan lokal tersedia, tandai “Tersimpan di perangkat, menunggu sinkronisasi”; jika tidak tersedia, jangan mengaku transaksi telah tersimpan.
- **Duplicate submit:** gunakan idempotency key atau pencegahan submit berulang di level aplikasi bila didukung backend.

---

# 7. Budget

## 7.1 Tujuan

Menunjukkan alokasi dan pemakaian anggaran selama salary cycle, membantu pengguna menemukan kategori yang perlu disesuaikan.

**Frame:** 390 × 844 px. Konten scrollable; bottom navigation tetap.

## 7.2 Screen — Budget Overview

### A. Header

- H1: “Anggaran”
- Subtitle: “Siklus 25 Sep – 24 Okt”
- Selector periode/siklus jika beberapa periode tersedia.

### B. Total budget card

**Ukuran:** full width dalam margin 24 px, tinggi sekitar 160–190 px, padding 20 px.

Isi:
- Label: “Anggaran fleksibel”
- Nilai utama: **Rp4.200.000**
- Ringkasan: “Terpakai Rp2.730.000”
- Sisa: **Rp1.470.000**
- Progress bar: 65%

Pastikan istilah “anggaran fleksibel” tidak tercampur dengan saldo rekening aktual.

### C. Category breakdown

Header “Kategori” dan tombol “Edit anggaran”.

Setiap row:
- Ikon kategori
- Nama kategori
- Nilai terpakai / batas kategori
- Progress bar
- Status jika mendekati batas

Contoh:
| Kategori | Terpakai | Anggaran | Progress |
|---|---:|---:|---:|
| Makan | Rp900.000 | Rp1.200.000 | 75% |
| Transportasi | Rp350.000 | Rp600.000 | 58% |
| Hiburan | Rp250.000 | Rp400.000 | 63% |
| Belanja | Rp500.000 | Rp700.000 | 71% |
| Lainnya | Rp730.000 | Rp1.300.000 | 56% |
| **Total** | **Rp2.730.000** | **Rp4.200.000** | **65%** |

Angka contoh harus konsisten dengan total saat digunakan sebagai data demo.

### D. Category detail

Saat kategori ditekan, buka detail screen atau bottom sheet berisi:
- Nama kategori
- Anggaran periode
- Total terpakai
- Sisa
- Progress
- Daftar transaksi dalam kategori
- Aksi “Ubah anggaran”

Contoh Makan:
- Anggaran: Rp1.200.000
- Terpakai: Rp900.000
- Sisa: Rp300.000

### E. Edit budget flow

- Judul: “Ubah anggaran”
- Input jumlah batas kategori.
- Helper menjelaskan bahwa perubahan memengaruhi total alokasi fleksibel.
- CTA: “Simpan perubahan”.
- Jika jumlah semua kategori melebihi anggaran fleksibel, tampilkan warning dan minta pengguna mengonfirmasi atau menyesuaikan alokasi lain.
- Jangan mengubah nominal kategori lain secara diam-diam.

## 7.3 Budget states

### Loading
- Skeleton untuk total card dan daftar kategori.

### Empty
- Teks: “Belum ada anggaran kategori.”
- CTA: “Atur anggaran”.
- Berikan opsi membuat alokasi dari anggaran fleksibel.

### Normal
- Tampilkan total, pemakaian, sisa, dan progress per kategori.

### Near limit
- Ketika kategori mencapai ambang konfigurasi, misalnya 80%, tampilkan label “Mendekati batas”.
- Ambang 80% adalah default awal dan sebaiknya dapat dikonfigurasi.

### Over budget
- Progress visual boleh melebihi 100% atau memenuhi track dengan penanda overflow, tetapi jangan sampai nilai teks ambigu.
- Tampilkan “Melebihi anggaran RpX”.
- Jangan menghalangi pengguna mencatat transaksi; tampilkan konsekuensi dengan jelas.

### Error
- Pertahankan perubahan draft.
- Tampilkan pesan dan tombol coba lagi.
- Jangan mengklaim budget tersimpan sampai penyimpanan terkonfirmasi.

---

# 8. Aturan Kalkulasi Finansial

Bagian ini harus diimplementasikan sebagai satu sumber kebenaran di domain/service layer. UI hanya menampilkan hasil kalkulasi.

## 8.1 Definisi data

- `netIncome`: pendapatan bersih yang tersedia pada siklus.
- `openingAvailableCash`: uang yang benar-benar tersedia untuk siklus, jika pengguna mengonfirmasi saldo awal.
- `fixedBills`: kewajiban tetap yang belum dibayar dan jatuh tempo dalam siklus.
- `savingsTarget`: target tabungan yang belum dipindahkan/didanai.
- `safetyBuffer`: cadangan minimum yang sengaja tidak dialokasikan untuk belanja.
- `discretionaryBudget`: anggaran fleksibel setelah alokasi wajib.
- `discretionarySpent`: pengeluaran yang dihitung terhadap anggaran fleksibel.
- `cycleStart` dan `cycleEnd`: tanggal mulai dan akhir siklus.
- `today`: tanggal lokal pengguna.

## 8.2 Anggaran fleksibel awal

Jika menggunakan pendapatan bersih sebagai dasar:

`discretionaryBudget = netIncome − fixedBillsForCycle − savingsTarget − safetyBuffer`

Jika pengguna memasukkan saldo aktual yang tersedia, sistem harus menghindari penghitungan ganda antara saldo awal dan pendapatan yang sama. Tentukan satu metode dasar per siklus dan jelaskan dalam UX.

Jika hasil di bawah nol:
- Tampilkan defisit rencana.
- Jangan diam-diam menjadikan nilai negatif sebagai budget.
- Safe-to-Spend harus bernilai minimum nol.
- Arahkan pengguna meninjau tagihan, target tabungan, atau pendapatan.

## 8.3 Safe-to-Spend

Safe-to-Spend harus dijelaskan secara transparan. Untuk MVP, definisikan sebagai estimasi jumlah harian yang masih aman dibelanjakan setelah menyisihkan kewajiban, target tabungan, dan buffer.

Langkah kalkulasi:

1. Hitung uang yang dialokasikan untuk siklus dengan metode dasar yang konsisten.
2. Kurangi tagihan yang belum dibayar dan harus disisihkan dalam siklus.
3. Kurangi target tabungan yang belum didanai.
4. Kurangi safety buffer.
5. Kurangi pengeluaran yang sudah tercatat dan termasuk anggaran fleksibel.
6. Bagi sisa fleksibel dengan jumlah hari yang tersisa dalam siklus.

Formula konseptual:

`remainingFlexible = max(0, availableForCycle − reservedUnpaidBills − unfundedSavingsTarget − safetyBuffer − discretionarySpent)`

`Safe-to-Spend per day = remainingFlexible / remainingDays`

`remainingDays` adalah jumlah hari yang tersisa sampai akhir siklus berdasarkan aturan inklusif/eksklusif yang ditentukan produk. Pilih satu konvensi dan gunakan secara konsisten di seluruh aplikasi.

Jika `remainingDays = 0`, jangan melakukan pembagian nol. Tampilkan sisa anggaran fleksibel sebagai nilai periode dan copy seperti “Siklus berakhir hari ini”.

Jika data penting belum lengkap, tampilkan label **Estimasi** dan jelaskan data apa yang belum tersedia. Jangan menyatakan Safe-to-Spend sebagai saldo bank aktual.

## 8.4 Money Velocity

Money Velocity membandingkan proporsi waktu yang sudah berlalu dengan proporsi anggaran fleksibel yang sudah digunakan.

`timeProgress = elapsedCycleDays / totalCycleDays`

`spendingProgress = discretionarySpent / discretionaryBudget`

`moneyVelocity = spendingProgress / timeProgress`

Contoh:
- Waktu siklus berlalu: 40%
- Anggaran fleksibel terpakai: 65%
- Money Velocity: `0.65 / 0.40 = 1.625×`, ditampilkan sebagai **1,63×**

Interpretasi:
- `velocity < 1`: pengeluaran berjalan lebih lambat daripada laju waktu siklus.
- `velocity ≈ 1`: pengeluaran relatif sejalan dengan waktu siklus.
- `velocity > 1`: pengeluaran lebih cepat daripada waktu siklus.
- `timeProgress = 0`: belum ada waktu siklus berlalu; tampilkan “Mulai dihitung setelah siklus berjalan”.
- `discretionaryBudget = 0`: tampilkan “Atur anggaran fleksibel untuk melihat Money Velocity”; jangan membagi nol.
- Data transaksi tidak lengkap: tandai indikator sebagai estimasi.

Jangan menyamakan Money Velocity dengan prediksi pasti kapan uang akan habis. Ia adalah indikator perbandingan laju.

## 8.5 Tagihan dan tabungan tanpa penghitungan ganda

- Tagihan yang sudah dibayar tidak boleh tetap dihitung sebagai tagihan belum dibayar, sekaligus dicatat lagi sebagai pengeluaran fleksibel.
- Target tabungan yang sudah benar-benar dipindahkan/didanai tidak boleh terus dikurangkan sebagai target yang belum didanai.
- Transaksi transfer antar-akun bukan pengeluaran konsumsi kecuali produk secara eksplisit menganggapnya demikian.
- Pengeluaran yang masuk kategori tagihan tetap harus diperlakukan konsisten antara `fixedBills` dan transaksi.
- Sediakan definisi yang jelas untuk pengeluaran yang dikecualikan dari anggaran fleksibel.

## 8.6 Contoh kalkulasi

Data contoh:
- Pendapatan bersih: Rp8.000.000
- Tagihan tetap: Rp2.800.000
- Target tabungan: Rp1.000.000
- Safety buffer: Rp0 untuk contoh sederhana

Maka:
- Anggaran fleksibel awal = Rp8.000.000 − Rp2.800.000 − Rp1.000.000 = **Rp4.200.000**
- Pengeluaran fleksibel = Rp2.730.000
- Sisa fleksibel = Rp4.200.000 − Rp2.730.000 = **Rp1.470.000**

Jika tersisa 12 hari, Safe-to-Spend contoh = Rp1.470.000 / 12 = **Rp122.500 per hari**.

Gunakan angka ini bila menampilkan dataset contoh yang sama. Jangan mencampurnya dengan nilai mock yang tidak konsisten.

---

# 9. Navigation dan Interaction Flow

## 9.1 Flow utama

1. Pengguna membuka SAMPAI.
2. Jika belum ada konfigurasi siklus → Onboarding.
3. Pengguna menyelesaikan data pendapatan, payday, tagihan, dan tabungan.
4. Pengguna tiba di Home dan melihat Safe-to-Spend.
5. Pengguna menekan “Catat pengeluaran” → Add Expense sheet.
6. Setelah penyimpanan berhasil, transaksi tersimpan dan Home/Budget diperbarui.
7. Pengguna membuka Budget untuk meninjau kategori.
8. Pengguna memilih kategori → melihat detail dan transaksi kategori.
9. Pengguna mengubah anggaran → konfirmasi → data diperbarui.

## 9.2 Aturan navigasi

- Menutup Add Expense tanpa menyimpan kembali ke layar asal.
- Setelah menyimpan expense, kembali ke layar asal dan perbarui ringkasan.
- Navigasi bottom bar mempertahankan konteks siklus yang sama.
- Perubahan salary cycle harus memperbarui Home, Budget, Safe-to-Spend, dan Money Velocity secara konsisten.
- Perubahan budget harus memicu kalkulasi ulang indikator terkait.

---

# 10. Accessibility dan Responsive Behavior

- Semua tombol penting memiliki touch target minimum 44 × 44 px.
- Jangan menggunakan warna sebagai satu-satunya pembeda status.
- Label input tetap terlihat saat field terisi; jangan mengandalkan placeholder sebagai label.
- Nilai Rupiah tidak boleh terpotong pada layar kecil.
- Saat keyboard terbuka, field aktif dan CTA harus tetap dapat dijangkau.
- Pastikan urutan fokus logis dan elemen interaktif memiliki label aksesibilitas.
- Hormati ukuran teks sistem; layout harus dapat scroll ketika teks diperbesar.
- Hindari animasi yang menghalangi interaksi atau menyebabkan informasi berkedip.

---

# 11. Figma File Organization

Susun file Figma dengan pages berikut:

1. `00 — Foundations`
   - Color styles/tokens
   - Typography
   - Spacing and radius
   - Icons
2. `01 — Components`
   - Buttons
   - Inputs
   - Cards
   - Progress bars
   - Category picker
   - Bottom navigation
   - Empty/loading/error states
3. `02 — Onboarding`
   - Welcome
   - Income
   - Payday
   - Fixed expenses
   - Savings & budget preview
4. `03 — Home`
   - Default
   - First-use
   - Warning
   - Critical
   - Offline/error
5. `04 — Add Expense`
   - Empty
   - Editing
   - Validation error
   - Saving
   - Success
   - Offline
6. `05 — Budget`
   - Overview
   - Category detail
   - Edit budget
   - Empty/loading/error
   - Near-limit/over-budget
7. `06 — Prototype Flows`
   - Onboarding → Home
   - Home → Add Expense → Home
   - Home → Budget → Category detail → Edit budget

Gunakan Auto Layout untuk card, list row, form, dan bottom navigation. Buat komponen dan variants untuk state tombol, field, progress, dan card. Gunakan nama layer yang konsisten, misalnya `Home/SafeToSpend/Card`, `Expense/Amount/Input`, `Budget/Category/Row`.

---

# 12. Acceptance Criteria MVP

## Onboarding
- [ ] Pengguna dapat mengisi gaji bersih.
- [ ] Pengguna dapat menetapkan tanggal gajian.
- [ ] Pengguna dapat menambah dan menghapus tagihan tetap.
- [ ] Pengguna dapat menetapkan target tabungan.
- [ ] Preview budget fleksibel dihitung dengan benar.
- [ ] Error penyimpanan tidak menghapus data form.

## Home
- [ ] Siklus dan sisa hari ditampilkan secara konsisten.
- [ ] Safe-to-Spend menggunakan formula yang sama dengan service/domain layer.
- [ ] Data tidak lengkap diberi label estimasi.
- [ ] Money Velocity menampilkan waktu siklus dan persentase budget yang digunakan.
- [ ] Loading, empty, warning, critical, offline, dan error state tersedia.

## Add Expense
- [ ] Pengguna dapat memasukkan jumlah, kategori, catatan opsional, dan tanggal.
- [ ] Nilai nol/negatif ditolak.
- [ ] Submit berulang tidak membuat transaksi ganda.
- [ ] Setelah sukses, ringkasan dan daftar transaksi diperbarui.
- [ ] Error tidak menghilangkan input.

## Budget
- [ ] Total anggaran, pengeluaran, sisa, dan progress konsisten.
- [ ] Pengguna dapat membuka detail kategori.
- [ ] Pengguna dapat mengubah anggaran.
- [ ] Total kategori yang melebihi budget fleksibel diberi warning.
- [ ] Near-limit dan over-budget memiliki pesan yang jelas.

## Konsistensi finansial
- [ ] Tagihan dan transaksi tidak dihitung dua kali.
- [ ] Tabungan yang sudah didanai tidak terus dihitung sebagai target belum didanai.
- [ ] Money Velocity tidak membagi nol.
- [ ] Safe-to-Spend tidak membagi nol dan tidak menampilkan nilai negatif.
- [ ] Semua tanggal menggunakan timezone lokal dan aturan siklus yang konsisten.

---

# 13. Urutan Implementasi yang Disarankan

1. Tetapkan model domain dan aturan salary cycle.
2. Implementasikan service kalkulasi untuk budget fleksibel, Safe-to-Spend, dan Money Velocity.
3. Bangun komponen dasar dan token UI.
4. Implementasikan Home dengan loading/empty/error state.
5. Implementasikan Add Expense dan pembaruan data setelah transaksi tersimpan.
6. Implementasikan Budget Overview dan detail kategori.
7. Implementasikan onboarding dan validasi.
8. Uji perubahan tanggal siklus, data kosong, anggaran nol, tagihan jatuh tempo, transaksi duplikat, dan mode offline.

**Catatan akhir:** ini adalah spesifikasi desain dan perilaku, bukan file `.fig` native. Gunakan sebagai source of truth saat membangun frame Figma dan implementasi aplikasi. Sebelum rilis, validasikan definisi saldo yang dipakai, perlakuan tagihan, dan konvensi hari tersisa dengan satu contoh siklus end-to-end.
