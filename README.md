# Tutorial 3 - Introduction to Game Engine
- **Nama**  : Akhyar Rasyid Asy syifa
- **Kelas** : Game Development - A
- **NPM**   : 2306241682

---

## Latihan Mandiri: Eksplorasi Mekanika Pergerakan

### *Double Jump*

Saya mengimplementasikan *double jump* menggunakan variabel `jump_count` sebagai penjaga state lompatan. Setiap kali karakter menyentuh lantai, saya me-*reset* `jump_count` ke `0` di dalam `apply_gravity()`. Saya membagi logika lompatan menjadi dua kondisi di `handle_jump()`:

- Jika `jump_count == 0` atau `coyote_timer > 0` → saya eksekusi lompatan pertama dan naikkan `jump_count` ke `1`
- Jika `jump_count == 1` dan karakter tidak di lantai → saya eksekusi *double jump* dan naikkan `jump_count` ke `2`

Saya menggunakan nilai `jump_force` yang sama (`-480.0`) untuk kedua lompatan agar tingginya identik. Saya juga menerapkan *variable jump height* — jika tombol dilepas lebih cepat saat lompatan pertama (`jump_count == 1`), saya kalikan `velocity.y` dengan `jump_cut_multiplier` sehingga lompatan menjadi lebih pendek. Saya sengaja tidak menerapkan pemotongan pada *double jump* agar tingginya selalu konsisten.

---

### *Dashing*

Saya mengimplementasikan *dash* dengan mendeteksi *double tap* pada tombol arah menggunakan `Time.get_ticks_msec()` untuk membandingkan waktu antar-*press*. Saya menggunakan dua variabel timestamp terpisah: `last_right_tap` dan `last_left_tap`, dan saya hanya melakukan deteksi saat `is_action_just_pressed` — bukan tiap *frame* — agar tidak terjadi *false trigger*.

Jika jarak waktu antar-*press* kurang dari `double_tap_window` (0.25 detik), saya memanggil fungsi `start_dash(dir)`. Di dalam fungsi tersebut:

- Saya mengatur `is_dashing = true` dan mengisi `dash_timer` dengan nilai `dash_time`
- Saya menambahkan **freeze frame** selama `dash_freeze_time` (0.04 detik) di awal *dash* — saya mengatur `velocity` ke `Vector2.ZERO` selama periode ini untuk memberikan *game feel* yang lebih berasa
- Saya mengelola *cooldown* dengan `dash_cooldown_timer` yang saya hitung mundur setiap `delta`, bukan dengan `create_timer()` di *runtime*, agar tidak menumpuk instance *timer*
- Saya membatasi *air dash* dengan `air_dashes_left` yang saya *reset* setiap kali karakter mendarat

---

### *Crouching*

Saya mengimplementasikan *crouching* yang aktif saat `ui_down` ditekan di lantai dan karakter tidak sedang *dash*. Saya mengelola state melalui fungsi `_set_crouch(state: bool)` di mana saya mengubah `is_crouching` dan menyesuaikan `collision_stand.scale.y` — saya kecilkan ke `0.6` saat *crouch* dan kembalikan ke `1.0` saat berdiri. Saat karakter dalam posisi *crouch*, saya hitung kecepatan geraknya menggunakan `target_spd *= crouch_speed_multiplier` di `apply_horizontal_movement()` sehingga gerakannya menjadi lebih lambat.

---

## *Polishing* Sederhana

### Memperbaiki *Sprite* Karakter Sesuai Arah Gerak

Saya mengimplementasikan *sprite flip* menggunakan `sprite.scale.x` alih-alih `sprite.flip_h`. Saya memilih pendekatan ini karena `flip_h` dapat menyebabkan *ghost artifact* apabila posisi `AnimatedSprite2D` tidak tepat berada di titik `(0, 0)` relatif terhadap *parent*-nya. Dengan mengatur `scale.x = 1.0` untuk arah kanan dan `scale.x = -1.0` untuk arah kiri, saya memastikan *flip* dilakukan dari titik tengah *sprite* sehingga tidak ada offset visual.

Saya juga menyimpan nilai `current_dir` sekali di awal `_physics_process()` via `Input.get_axis("ui_left", "ui_right")` dan menggunakannya kembali di `handle_input()`, `apply_horizontal_movement()`, serta `update_animation()` — sehingga saya tidak memanggil `Input` berulang kali dalam satu *frame*.

---

## Fitur Tambahan yang Saya Implementasikan

### *Split Gravity*

Saya membagi gravity menjadi dua nilai: `gravity_up` (1000) saat karakter naik, dan `gravity_down` (1800) saat turun. Saya memilih teknik ini karena menghasilkan kurva lompatan yang terasa lebih natural dan responsif dibanding gravity tunggal. Saat *ground slam* aktif, saya menggunakan `gravity_slam` (3000) untuk mempercepat penurunan.

### *Fast Fall*

Saat karakter berada di udara dan `ui_down` ditekan, saya mengalikan nilai `gravity_down` dengan `fast_fall_multiplier` (1.8) sehingga karakter turun lebih cepat. Fitur ini saya tambahkan untuk memberikan kontrol vertikal tambahan kepada pemain.

### *Coyote Time*

Saya mengimplementasikan *coyote time* dengan me-*reset* `coyote_timer` setiap *frame* selama karakter berada di lantai. Saat karakter berjalan melewati tepi platform, timer ini memberi saya jendela waktu singkat (0.12 detik) di mana lompatan masih bisa dieksekusi meskipun karakter sudah tidak menyentuh lantai.

### *Jump Buffering*

Saya mengatur `jump_buffer_timer` saat tombol lompat ditekan. Jika karakter mendarat dalam jendela waktu tersebut (0.14 detik), saya eksekusi lompatan secara otomatis. Saya menambahkan fitur ini agar input lompat terasa lebih responsif dan tidak menghukum pemain karena timing yang sedikit meleset.

### *Wall Slide*

Saya mengimplementasikan *wall slide* dengan membatasi `velocity.y` ke `wall_slide_speed` (80) saat karakter menempel dinding di udara, sehingga turunnya lebih lambat. Saya memastikan fitur ini hanya aktif jika karakter secara aktif menekan input ke arah dinding dengan mengecek `sign(current_dir) == sign(-wall_normal.x)`, agar *wall slide* tidak terpicu secara tidak sengaja.

### *Ground Slam*

Saat di udara, saya mengimplementasikan *ground slam* yang terpicu saat `ui_accept` (Space) ditekan. Saya langsung mengatur `velocity.y = 1400` dan menghentikan gerakan horizontal. Saya juga menggunakan flag `override_gravity` untuk melewati satu *frame* gravity agar efek *slam* terasa lebih *snappy*.
