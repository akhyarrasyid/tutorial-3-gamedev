extends CharacterBody2D

# ==================================================
# =================== CONFIG =======================
# ==================================================
@export var move_speed              := 220.0
@export var acceleration            := 1200.0
@export var friction                := 1400.0

@export var gravity_up              := 1000.0
@export var gravity_down            := 1800.0
@export var gravity_slam            := 3000.0
@export var max_fall_speed          := 900.0
@export var fast_fall_multiplier    := 1.8

@export var jump_force              := -480.0
@export var jump_cut_multiplier     := 0.35
@export var coyote_time             := 0.12
@export var jump_buffer_time        := 0.14

@export var dash_speed              := 700.0
@export var dash_time               := 0.18
@export var dash_freeze_time        := 0.04
@export var dash_cooldown           := 0.55
@export var max_air_dashes          := 1
@export var double_tap_window       := 0.25

@export var wall_slide_speed        := 80.0
@export var crouch_speed_multiplier := 0.5

# ==================================================
# =================== STATE ========================
# ==================================================
var jump_count          := 0
var coyote_timer        := 0.0
var jump_buffer_timer   := 0.0

var is_dashing          := false
var dash_timer          := 0.0
var dash_freeze_timer   := 0.0
var dash_cooldown_timer := 0.0
var can_dash            := true
var air_dashes_left     := 0
var dash_direction      := 0

var is_crouching        := false
var is_ground_slam      := false
var override_gravity    := false

var was_on_floor        := true
var prev_velocity_y     := 0.0
var current_dir         := 0.0

var last_right_tap      := -999.0
var last_left_tap       := -999.0

# ==================================================
# ================= REFERENCES =====================
# ==================================================
@onready var sprite          := $AnimatedSprite2D
@onready var collision_stand := $CollisionShape2D

# ==================================================
# =================== READY ========================
# ==================================================
func _ready():
	air_dashes_left = max_air_dashes
	was_on_floor    = true
	jump_count      = 0
	dash_timer      = dash_time
	print("✅ Player ready!")

# ==================================================
# ================= MAIN LOOP ======================
# ==================================================
func _physics_process(delta):
	prev_velocity_y = velocity.y
	current_dir     = Input.get_axis("ui_left", "ui_right")

	handle_timers(delta)
	apply_gravity(delta)
	handle_input(delta)
	handle_jump()
	handle_dash(delta)
	handle_wall_slide()
	apply_horizontal_movement(delta)
	move_and_slide()
	update_animation()
	handle_landing_effect()
	was_on_floor = is_on_floor()

# ==================================================
# ================== TIMERS ========================
# ==================================================
func handle_timers(delta):
	coyote_timer      -= delta
	jump_buffer_timer -= delta

	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true
			print("✅ Dash ready again")

	if dash_freeze_timer > 0:
		dash_freeze_timer -= delta

# ==================================================
# =================== GRAVITY ======================
# ==================================================
func apply_gravity(delta):
	if is_on_floor():
		if not was_on_floor:
			jump_count       = 0
			air_dashes_left  = max_air_dashes
			is_ground_slam   = false
			override_gravity = false
			print("🟢 Landed — states reset")
		coyote_timer = coyote_time
		return

	if dash_freeze_timer > 0:
		return

	if override_gravity:
		override_gravity = false
		return

	if is_ground_slam:
		velocity.y += gravity_slam * delta
	elif velocity.y < 0:
		velocity.y += gravity_up * delta
	else:
		var grav := gravity_down
		if Input.is_action_pressed("ui_down"):
			grav *= fast_fall_multiplier
		velocity.y += grav * delta

	velocity.y = min(velocity.y, max_fall_speed)

# ==================================================
# =================== INPUT ========================
# ==================================================
func handle_input(_delta):
	var now := Time.get_ticks_msec() / 1000.0

	# --- Sprite flip ---
	if current_dir > 0:
		sprite.scale.x = 1.0
	elif current_dir < 0:
		sprite.scale.x = -1.0

	# --- Double tap dash ---
	if Input.is_action_just_pressed("ui_right"):
		if (now - last_right_tap) < double_tap_window:
			start_dash(1)
		last_right_tap = now

	if Input.is_action_just_pressed("ui_left"):
		if (now - last_left_tap) < double_tap_window:
			start_dash(-1)
		last_left_tap = now

	# --- Jump buffer ---
	if Input.is_action_just_pressed("ui_up"):
		jump_buffer_timer = jump_buffer_time

	# --- Crouch ---
	if Input.is_action_pressed("ui_down") and is_on_floor() and not is_dashing:
		_set_crouch(true)
	elif is_crouching:
		_set_crouch(false)

	# --- Ground slam: Space ---
	if Input.is_action_just_pressed("ui_accept") and not is_on_floor() and not is_ground_slam:
		is_ground_slam   = true
		override_gravity = true
		velocity.y       = 1400.0
		velocity.x       = 0.0
		print("💥 GROUND SLAM!")

func _set_crouch(state: bool):
	is_crouching                = state
	collision_stand.scale.y     = 0.6 if state else 1.0

# ==================================================
# =================== JUMP =========================
# ==================================================
func handle_jump():
	var can_first_jump: bool  = jump_count == 0 or coyote_timer > 0
	var can_double_jump: bool = jump_count == 1 and not is_on_floor()

	if jump_buffer_timer > 0:
		if can_first_jump:
			velocity.y        = jump_force
			jump_count        = 1
			coyote_timer      = 0.0
			jump_buffer_timer = 0.0
			print("🚀 JUMP! jump_count: 1")
		elif can_double_jump:
			velocity.y        = jump_force
			jump_count        = 2
			jump_buffer_timer = 0.0
			print("🔥 DOUBLE JUMP!")

	if Input.is_action_just_released("ui_up") and velocity.y < 0 and jump_count == 1:
		velocity.y *= jump_cut_multiplier

# ==================================================
# =================== DASH =========================
# ==================================================
func start_dash(dir: int):
	if not can_dash:
		return
	if not is_on_floor() and air_dashes_left <= 0:
		print("❌ No air dashes left")
		return

	is_dashing          = true
	dash_direction      = dir
	dash_timer          = dash_time
	dash_freeze_timer   = dash_freeze_time
	can_dash            = false
	dash_cooldown_timer = dash_cooldown

	if not is_on_floor():
		air_dashes_left -= 1
		print("💨 AIR DASH! Remaining: ", air_dashes_left)
	else:
		print("💨 GROUND DASH!")

func handle_dash(delta):
	if not is_dashing:
		return

	if dash_freeze_timer > 0:
		velocity = Vector2.ZERO
		return

	velocity.x  = dash_direction * dash_speed
	velocity.y  = 0.0
	dash_timer -= delta

	if dash_timer <= 0:
		is_dashing = false
		dash_timer = dash_time
		print("⏱️ Dash ended")

# ==================================================
# ================ WALL SLIDE ======================
# ==================================================
func handle_wall_slide():
	if not is_on_wall() or is_on_floor() or velocity.y <= 0:
		return

	var wall_normal := get_wall_normal()
	var into_wall: bool = current_dir != 0 and sign(current_dir) == sign(-wall_normal.x)
	if not into_wall:
		return

	velocity.y = wall_slide_speed

# ==================================================
# ================ MOVEMENT ========================
# ==================================================
func apply_horizontal_movement(delta):
	if is_dashing:
		return

	var target_spd := move_speed
	if is_crouching:
		target_spd *= crouch_speed_multiplier

	if current_dir != 0:
		velocity.x = move_toward(velocity.x, current_dir * target_spd, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

# ==================================================
# ================ ANIMATION =======================
# ==================================================
func update_animation():
	if is_dashing:
		sprite.play("dash")
		return
	if is_crouching:
		sprite.play("crouch")
		return
	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		sprite.play("wall_slide")
		return
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
		return

	if abs(velocity.x) > 10:
		var is_skidding: bool = current_dir != 0 and sign(current_dir) != sign(velocity.x)
		sprite.play("skid" if is_skidding else "run")
	else:
		sprite.play("idle")

# ==================================================
# ============= LANDING IMPACT =====================
# ==================================================
func handle_landing_effect():
	if is_on_floor() and not was_on_floor:
		if prev_velocity_y > 600:
			print("💢 HEAVY LANDING! velocity: ", prev_velocity_y)
		elif prev_velocity_y > 200:
			print("🟡 Normal landing")
