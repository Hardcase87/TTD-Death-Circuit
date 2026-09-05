extends Node2D

const MAX_SPEED = 680.0
const NITRO_SPEED = 840.0
const ACCEL = 218.0
const BRAKE_POWER = 310.0
const COAST = 38.0
const DRAW_DISTANCE = 8400.0
const ROAD_SLICES = 104
const ROAD_SCALE = 1.0
const MAP_SAMPLES = 220

const NEON_GREEN = Color("8aff2b")
const NEON_PINK = Color("ff2d95")
const NEON_CYAN = Color("39d7ff")
const HOT_YELLOW = Color("ffe53b")
const PEARL = Color("f5f2e9")

const DISTRICT_HORIZONS = [
	preload("res://assets/environment/district-vhs-quarter.webp"),
	preload("res://assets/environment/district-financial.webp"),
	preload("res://assets/environment/district-nutrition.webp"),
	preload("res://assets/environment/district-military.webp"),
	preload("res://assets/environment/district-titan-heights.webp"),
	preload("res://assets/environment/district-titan-run.webp")
]
const GATE_TEX = preload("res://assets/environment/ttd-checkpoint-gate.png")
const CAR_POSES = [
	preload("res://assets/vehicles/mutant-maniac-hard-left.png"),
	preload("res://assets/vehicles/mutant-maniac-soft-left.png"),
	preload("res://assets/vehicles/mutant-maniac-center.png"),
	preload("res://assets/vehicles/mutant-maniac-soft-right.png"),
	preload("res://assets/vehicles/mutant-maniac-hard-right.png")
]
const SIGN_TEXTURES = [
	preload("res://assets/signs/billboard-death-circuit.webp"),
	preload("res://assets/signs/billboard-skull-juice.webp"),
	preload("res://assets/signs/billboard-titan-babe.webp"),
	preload("res://assets/signs/billboard-mortis.webp"),
	preload("res://assets/signs/billboard-tdi.webp")
]
const CHEVRON_TEX = preload("res://assets/signs/road-chevron.webp")
const BARRICADE_TEX = preload("res://assets/signs/road-barricade.webp")

# Each Vector3 is local section progress, signed corner force and hill force.
# Long holds create committed arcade bends instead of generic sine-wave wandering.
const ROAD_KEYS = [
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.10, 0.00, 0.04),
		Vector3(0.23, 0.78, 0.02), Vector3(0.37, 0.92, -0.16),
		Vector3(0.50, -0.72, 0.12), Vector3(0.64, -0.82, 0.04),
		Vector3(0.77, 0.42, -0.28), Vector3(0.89, 0.00, 0.10),
		Vector3(1.00, 0.00, 0.00)
	],
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.12, -0.48, 0.04),
		Vector3(0.27, -0.96, -0.14), Vector3(0.41, -0.30, 0.20),
		Vector3(0.54, 0.72, 0.05), Vector3(0.68, 1.02, -0.20),
		Vector3(0.82, 0.26, 0.27), Vector3(0.92, 0.00, 0.04),
		Vector3(1.00, 0.00, 0.00)
	],
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.11, 0.62, -0.05),
		Vector3(0.24, 1.08, 0.18), Vector3(0.38, 0.18, 0.34),
		Vector3(0.51, -0.94, 0.06), Vector3(0.65, -0.52, -0.30),
		Vector3(0.79, 0.88, -0.08), Vector3(0.91, 0.00, 0.16),
		Vector3(1.00, 0.00, 0.00)
	],
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.10, -0.58, 0.10),
		Vector3(0.24, -1.12, 0.32), Vector3(0.39, -0.20, -0.18),
		Vector3(0.52, 0.86, -0.32), Vector3(0.67, 0.98, 0.18),
		Vector3(0.80, -0.66, 0.28), Vector3(0.92, 0.00, -0.05),
		Vector3(1.00, 0.00, 0.00)
	],
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.12, 0.38, 0.18),
		Vector3(0.26, 0.82, 0.48), Vector3(0.40, -0.44, -0.24),
		Vector3(0.54, -1.05, 0.36), Vector3(0.69, 0.54, 0.50),
		Vector3(0.82, 0.90, -0.34), Vector3(0.92, 0.00, 0.08),
		Vector3(1.00, 0.00, 0.00)
	],
	[
		Vector3(0.00, 0.00, 0.00), Vector3(0.11, -0.36, -0.08),
		Vector3(0.24, -0.84, 0.20), Vector3(0.38, 0.70, -0.18),
		Vector3(0.52, 1.12, 0.14), Vector3(0.66, -0.76, -0.24),
		Vector3(0.80, -0.32, 0.18), Vector3(0.91, 0.00, -0.04),
		Vector3(1.00, 0.00, 0.00)
	]
]

var sections = [
	{
		"name": "VHS QUARTER",
		"tag": "REWIND OR DIE",
		"length": 15000.0,
		"curve": 0.20,
		"hill": 0.16,
		"accent": NEON_PINK,
		"road": Color("282438"),
		"ground": Color("122538")
	},
	{
		"name": "FINANCIAL DISTRICT",
		"tag": "CREDIT IS A WEAPON",
		"length": 14500.0,
		"curve": -0.36,
		"hill": 0.08,
		"accent": HOT_YELLOW,
		"road": Color("222735"),
		"ground": Color("101e2f")
	},
	{
		"name": "NUTRITION DISTRICT",
		"tag": "100% MUTANT ENERGY",
		"length": 15000.0,
		"curve": 0.48,
		"hill": 0.28,
		"accent": NEON_GREEN,
		"road": Color("273127"),
		"ground": Color("143522")
	},
	{
		"name": "MILITARY ZONE",
		"tag": "RESTRICTED ROAD",
		"length": 14500.0,
		"curve": -0.54,
		"hill": 0.34,
		"accent": NEON_CYAN,
		"road": Color("252a2b"),
		"ground": Color("252d27")
	},
	{
		"name": "TITAN HEIGHTS",
		"tag": "POWER LIVES ABOVE",
		"length": 15500.0,
		"curve": 0.30,
		"hill": 0.48,
		"accent": NEON_PINK,
		"road": Color("242039"),
		"ground": Color("111d37")
	},
	{
		"name": "TITAN RUN",
		"tag": "CITY LIMITS TERMINATED",
		"length": 15500.0,
		"curve": -0.18,
		"hill": 0.20,
		"accent": NEON_CYAN,
		"road": Color("2b2432"),
		"ground": Color("1b3026")
	}
]

var section_starts = PackedFloat32Array()
var track_length = 0.0
var map_points = PackedVector2Array()
var world_objects = []

var race_distance = 0.0
var speed = 0.0
var road_x = 0.0
var steer_visual = 0.0
var nitro = 100.0
var elapsed = 0.0
var current_section = 0
var previous_section = -1
var transition_from_section = 0
var district_banner = 0.0
var background_transition = 0.0
var boost_visual = 0.0
var camera_impact = 0.0
var state = "title"

var touch_points = {}
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_phase = 0.0
var engine_mix_rate = 22050.0


func _ready() -> void:
	_build_track()
	_build_world_objects()
	_build_minimap()
	_setup_audio()
	set_process(true)
	queue_redraw()


func _build_track() -> void:
	section_starts.clear()
	track_length = 0.0
	for section in sections:
		section_starts.append(track_length)
		track_length += section.length


func _build_world_objects() -> void:
	world_objects.clear()
	for index in range(sections.size()):
		var start: float = section_starts[index]
		var length: float = sections[index].length
		if index > 0:
			world_objects.append({"z": start, "type": "gate", "side": 0.0, "section": index})
		var prop_count = 11
		var usable_start = 1750.0
		var usable_length = length - 3200.0
		for slot in range(prop_count):
			var side_pattern = (slot * 3 + index * 2) % 7
			var side = -1.0 if side_pattern < 3 else 1.0
			var kind = "billboard"
			if slot % 3 == 1:
				kind = "chevron"
			elif slot % 3 == 2:
				kind = "barricade"
			var spacing = usable_length / float(prop_count - 1)
			var stagger = float((slot * 137 + index * 79) % 260) - 130.0
			world_objects.append(
				{
					"z": start + usable_start + float(slot) * spacing + stagger,
					"type": kind,
					"side": side,
					"asset": (slot + index * 2) % SIGN_TEXTURES.size(),
					"section": index
				}
			)
	world_objects.append({"z": track_length - 450.0, "type": "gate", "side": 0.0, "section": 5})
	world_objects.sort_custom(_sort_world_objects)


func _sort_world_objects(a: Dictionary, b: Dictionary) -> bool:
	return float(a.z) < float(b.z)


func _build_minimap() -> void:
	map_points.clear()
	var heading = 0.0
	var point = Vector2.ZERO
	var raw = PackedVector2Array([point])
	for i in range(1, MAP_SAMPLES + 1):
		var z = track_length * float(i) / float(MAP_SAMPLES)
		var info = _track_info(z)
		heading += float(info.curve) * 0.075
		point += Vector2(sin(heading), -cos(heading)) * 4.0
		raw.append(point)
	var bounds = Rect2(raw[0], Vector2.ZERO)
	for p in raw:
		bounds = bounds.expand(p)
	var scale_value: float = min(150.0 / max(bounds.size.x, 1.0), 180.0 / max(bounds.size.y, 1.0))
	for p in raw:
		map_points.append((p - bounds.position - bounds.size * 0.5) * scale_value)


func _setup_audio() -> void:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = engine_mix_rate
	generator.buffer_length = 0.18
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = generator
	audio_player.volume_db = -15.0
	add_child(audio_player)
	audio_player.play()
	audio_playback = audio_player.get_stream_playback()


func _fill_engine_audio() -> void:
	if audio_playback == null:
		return
	var frames = audio_playback.get_frames_available()
	var gear_band = fposmod(speed, 145.0)
	var rpm = 48.0 + gear_band * 0.62 + speed * 0.055
	for i in range(frames):
		audio_phase = fmod(audio_phase + rpm / engine_mix_rate, 1.0)
		var wave = sin(audio_phase * TAU) * 0.095
		wave += sin(audio_phase * TAU * 2.01) * 0.052
		wave += sin(audio_phase * TAU * 0.49) * 0.030
		wave += sin(audio_phase * TAU * 5.03) * 0.018 * boost_visual
		if state != "race":
			wave *= 0.32
		audio_playback.push_frame(Vector2(wave, wave))


func _process(delta: float) -> void:
	_fill_engine_audio()
	if state != "race":
		queue_redraw()
		return
	var controls = _control_state()
	var throttle: bool = (
		Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or controls.throttle
	)
	var braking: bool = (
		Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or controls.brake
	)
	var keyboard_boost = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)
	var boosting: bool = (keyboard_boost or controls.nitro) and nitro > 0.0 and speed > 120.0
	if boosting and boost_visual < 0.05:
		camera_impact = 1.0
	boost_visual = move_toward(boost_visual, 1.0 if boosting else 0.0, delta * 4.5)
	camera_impact = max(0.0, camera_impact - delta * 2.8)
	var keyboard_steer = (
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	)
	var steer = keyboard_steer + float(controls.steer)
	steer = clamp(steer, -1.0, 1.0)
	steer_visual = move_toward(steer_visual, steer, delta * 5.0)

	var target_speed = NITRO_SPEED if boosting else MAX_SPEED
	if throttle:
		var launch_power = 1.45 if speed < 145.0 else 1.0
		speed = move_toward(speed, target_speed, ACCEL * delta * launch_power)
	else:
		speed = move_toward(speed, 0.0, COAST * delta)
	if braking:
		speed = move_toward(speed, 0.0, BRAKE_POWER * delta)
	if boosting:
		nitro = max(0.0, nitro - 18.0 * delta)
	else:
		nitro = min(100.0, nitro + 4.0 * delta)

	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.25)
	var grip = 1.82 if braking else 1.22
	road_x += steer * grip * delta * (0.38 + speed_ratio)
	var road_force = float(_track_info(race_distance).curve) * speed_ratio * speed_ratio
	road_x -= road_force * delta * 0.105
	road_x = clamp(road_x, -1.32, 1.32)
	if abs(road_x) > 0.94:
		speed = move_toward(speed, MAX_SPEED * 0.50, 190.0 * delta)

	_racing_step(delta)
	queue_redraw()


func _racing_step(delta: float) -> void:
	elapsed += delta
	district_banner = max(0.0, district_banner - delta)
	background_transition = max(0.0, background_transition - delta)
	race_distance += speed * ROAD_SCALE * delta
	if race_distance >= track_length:
		race_distance = track_length
		speed = 0.0
		state = "finish"
	current_section = int(_track_info(race_distance).index)
	if current_section != previous_section:
		transition_from_section = max(previous_section, 0)
		if previous_section >= 0:
			background_transition = 1.0
		previous_section = current_section
		district_banner = 2.5


func _track_info(z: float) -> Dictionary:
	var distance = clamp(z, 0.0, track_length - 0.001)
	var index = sections.size() - 1
	for i in range(sections.size()):
		if distance < section_starts[i] + float(sections[i].length):
			index = i
			break
	var section: Dictionary = sections[index]
	var local = (distance - section_starts[index]) / float(section.length)
	var keys: Array = ROAD_KEYS[index]
	var curve = 0.0
	var hill = 0.0
	for key_index in range(1, keys.size()):
		var previous_key: Vector3 = keys[key_index - 1]
		var next_key: Vector3 = keys[key_index]
		if local <= next_key.x:
			var key_range = max(0.001, next_key.x - previous_key.x)
			var blend = clamp((local - previous_key.x) / key_range, 0.0, 1.0)
			blend = blend * blend * (3.0 - 2.0 * blend)
			curve = lerp(previous_key.y, next_key.y, blend)
			hill = lerp(previous_key.z, next_key.z, blend)
			break
	return {"index": index, "local": local, "curve": curve, "hill": hill, "section": section}


func _integrated_curve(distance: float) -> float:
	if distance <= 0.0:
		return 0.0
	var total = 0.0
	var steps = 7
	for i in range(steps):
		var sample_z = race_distance + distance * (float(i) + 0.5) / float(steps)
		total += float(_track_info(min(sample_z, track_length - 1.0)).curve)
	return total / float(steps)


func _road_point(distance: float) -> Dictionary:
	var view = get_viewport_rect().size
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.22)
	var horizon = view.y * lerp(0.445, 0.397, speed_ratio)
	var bottom = view.y * 1.015
	var u = sqrt(clamp(distance / DRAW_DISTANCE, 0.0, 1.0))
	var info = _track_info(min(race_distance + distance, track_length - 1.0))
	var y = lerp(bottom, horizon, pow(u, lerp(0.76, 0.66, speed_ratio)))
	y -= float(info.hill) * sin(u * PI) * view.y * 0.255
	var near_width = view.x * (0.475 + speed_ratio * 0.035 + boost_visual * 0.018)
	var half_width = lerp(near_width, view.x * 0.008, pow(u, 0.76))
	var bend = _integrated_curve(distance) * pow(distance / DRAW_DISTANCE, 1.35)
	var steering_camera = steer_visual * speed_ratio * view.x * 0.020
	var corner_look = float(info.curve) * speed_ratio * view.x * 0.018
	var center = view.x * 0.5 - road_x * view.x * 0.255 + bend * view.x * 0.43
	center += steering_camera + corner_look
	return {"center": center, "y": y, "half": half_width, "u": u, "info": info}


func _draw() -> void:
	var view = get_viewport_rect().size
	_draw_background(view)
	_draw_road(view)
	_draw_speed_effects(view)
	_draw_roadside_flow(view)
	_draw_world_objects(view)
	_draw_car(view)
	_draw_hud(view)
	_draw_touch_controls(view)
	if state == "title":
		_draw_title(view)
	elif state == "finish":
		_draw_finish(view)
	elif district_banner > 0.0:
		_draw_district_banner(view)


func _draw_background(view: Vector2) -> void:
	var info = _track_info(race_distance)
	var section: Dictionary = info.section
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.22)
	var horizon_h = view.y * lerp(0.555, 0.515, speed_ratio)
	var horizon_width = view.x * 1.14
	var corner_pan = float(info.curve) * view.x * 0.020
	var horizon_x = -view.x * 0.07 - road_x * view.x * 0.018 - corner_pan
	var horizon_y = -speed_ratio * view.y * 0.010
	var horizon_rect = Rect2(horizon_x, horizon_y, horizon_width, horizon_h)
	var current_horizon: Texture2D = DISTRICT_HORIZONS[current_section]
	var tint: Color = Color.WHITE.lerp(section.accent, 0.07)
	if background_transition > 0.0 and transition_from_section != current_section:
		var old_horizon: Texture2D = DISTRICT_HORIZONS[transition_from_section]
		draw_texture_rect(old_horizon, horizon_rect, false, Color.WHITE)
		var reveal = 1.0 - clamp(background_transition, 0.0, 1.0)
		draw_texture_rect(current_horizon, horizon_rect, false, Color(tint, reveal))
	else:
		draw_texture_rect(current_horizon, horizon_rect, false, tint)
	draw_rect(Rect2(0.0, 0.0, view.x, horizon_h), Color(section.accent, 0.055))


func _draw_road(view: Vector2) -> void:
	var current = _track_info(race_distance)
	draw_rect(Rect2(0.0, view.y * 0.39, view.x, view.y * 0.61), current.section.ground)
	for i in range(ROAD_SLICES - 1, -1, -1):
		var near_d = DRAW_DISTANCE * pow(float(i) / float(ROAD_SLICES), 2.0)
		var far_d = DRAW_DISTANCE * pow(float(i + 1) / float(ROAD_SLICES), 2.0)
		var near = _road_point(near_d)
		var far = _road_point(far_d)
		var stripe = int((race_distance + near_d) / 240.0) % 2
		var info: Dictionary = near.info
		var road_color: Color = info.section.road.lightened(0.035 if stripe == 0 else 0.0)
		var ground_color: Color = info.section.ground.lightened(0.055 if stripe == 0 else 0.0)
		draw_rect(Rect2(0.0, far.y, view.x, max(1.0, near.y - far.y + 1.0)), ground_color)
		var road_poly = PackedVector2Array(
			[
				Vector2(far.center - far.half, far.y),
				Vector2(far.center + far.half, far.y),
				Vector2(near.center + near.half, near.y),
				Vector2(near.center - near.half, near.y)
			]
		)
		draw_colored_polygon(road_poly, road_color)
		var shoulder = 0.105
		var left_shoulder = PackedVector2Array(
			[
				Vector2(far.center - far.half * (1.0 + shoulder), far.y),
				Vector2(far.center - far.half, far.y),
				Vector2(near.center - near.half, near.y),
				Vector2(near.center - near.half * (1.0 + shoulder), near.y)
			]
		)
		var right_shoulder = PackedVector2Array(
			[
				Vector2(far.center + far.half, far.y),
				Vector2(far.center + far.half * (1.0 + shoulder), far.y),
				Vector2(near.center + near.half * (1.0 + shoulder), near.y),
				Vector2(near.center + near.half, near.y)
			]
		)
		var rumble = info.section.accent if stripe == 0 else PEARL
		draw_colored_polygon(left_shoulder, rumble)
		draw_colored_polygon(right_shoulder, rumble)
		if stripe == 0 and i % 3 != 0:
			for lane in [-0.333, 0.333]:
				var lane_near = near.center + near.half * lane
				var lane_far = far.center + far.half * lane
				var width_near = max(1.0, near.half * 0.013)
				var width_far = max(0.6, far.half * 0.013)
				var line = PackedVector2Array(
					[
						Vector2(lane_far - width_far, far.y),
						Vector2(lane_far + width_far, far.y),
						Vector2(lane_near + width_near, near.y),
						Vector2(lane_near - width_near, near.y)
					]
				)
				draw_colored_polygon(line, Color(1.0, 0.93, 0.74, 0.78))
		if i % 7 == 0 and near.y > view.y * 0.53:
			var center_glint_width = max(0.7, near.half * 0.006)
			draw_line(
				Vector2(near.center - center_glint_width, near.y),
				Vector2(near.center + center_glint_width, near.y),
				Color(current.section.accent, 0.25),
				max(1.0, center_glint_width),
				true
			)


func _draw_speed_effects(view: Vector2) -> void:
	if state != "race" or speed < 65.0:
		return
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.28)
	var accent: Color = sections[current_section].accent
	var far_point = _road_point(DRAW_DISTANCE)
	var vanishing = Vector2(far_point.center, far_point.y)
	for i in range(42):
		var phase = fposmod(float(i) * 0.137 + race_distance * 0.00175, 1.0)
		var depth = pow(phase, 2.1)
		var y = lerp(view.y * 0.445, view.y * 0.965, depth)
		var scatter = fposmod(float(i * 41 + current_section * 17), 100.0) / 100.0
		var x: float
		if i % 2 == 0:
			x = lerp(view.x * 0.01, view.x * 0.34, scatter)
		else:
			x = lerp(view.x * 0.66, view.x * 0.99, scatter)
		var endpoint = Vector2(x, y)
		var direction = (endpoint - vanishing).normalized()
		var streak_length = lerp(2.0, view.y * 0.17, depth) * speed_ratio
		var streak_color = accent
		streak_color.a = (0.035 + depth * 0.25) * speed_ratio
		draw_line(
			endpoint - direction * streak_length,
			endpoint,
			streak_color,
			max(1.0, depth * 3.2),
			true
		)


func _draw_roadside_flow(view: Vector2) -> void:
	if state != "race":
		return
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.24)
	var accent: Color = sections[current_section].accent
	var spacing = 315.0
	var first_distance = spacing - fposmod(race_distance, spacing)
	for marker_index in range(27):
		var distance = first_distance + float(marker_index) * spacing
		if distance < 45.0 or distance >= DRAW_DISTANCE:
			continue
		var point = _road_point(distance)
		var closeness = 1.0 - point.u
		var marker_height = max(2.0, 72.0 * pow(closeness, 1.7))
		var marker_width = max(1.0, 6.5 * pow(closeness, 1.35))
		for side in [-1.0, 1.0]:
			var edge_x = point.center + side * point.half * 1.115
			var base = Vector2(edge_x, point.y)
			draw_line(
				base,
				base - Vector2(0.0, marker_height),
				Color(0.04, 0.06, 0.10, 0.95),
				marker_width,
				true
			)
			var lamp_color = accent if (marker_index + int(side)) % 2 == 0 else NEON_CYAN
			lamp_color.a = 0.32 + speed_ratio * 0.48
			draw_circle(base - Vector2(0.0, marker_height), marker_width * 1.15, lamp_color)
			if closeness > 0.52:
				var trail = (18.0 + 90.0 * closeness) * speed_ratio
				draw_line(base, base + Vector2(-side * trail * 0.12, trail), Color(lamp_color, 0.18), marker_width, true)


func _draw_world_objects(view: Vector2) -> void:
	# Objects are sorted once when the course is built. Reverse traversal draws far to near
	# without allocating and sorting a temporary array every frame.
	for object_index in range(world_objects.size() - 1, -1, -1):
		var object: Dictionary = world_objects[object_index]
		var distance: float = float(object.z) - race_distance
		if distance >= DRAW_DISTANCE:
			continue
		if distance <= 65.0:
			continue
		_draw_projected_object(object, distance, view)


func _draw_projected_object(object: Dictionary, distance: float, view: Vector2) -> void:
	var point = _road_point(distance)
	var closeness: float = 1.0 - point.u
	if closeness <= 0.01:
		return
	if point.y > view.y * 0.835:
		return
	var kind: String = object.type
	if kind == "gate":
		var width = clamp(point.half * 2.22, 24.0, view.x * 0.61)
		var height = width * float(GATE_TEX.get_height()) / float(GATE_TEX.get_width())
		var rect = Rect2(point.center - width * 0.5, point.y - height * 0.93, width, height)
		draw_rect(
			Rect2(point.center - width * 0.45, point.y - height * 0.03, width * 0.90, height * 0.08),
			Color(0.0, 0.0, 0.0, 0.32)
		)
		draw_texture_rect(GATE_TEX, rect, false)
		return
	var side: float = float(object.side)
	var shoulder_clearance = 1.34 + closeness * 0.20
	var x = point.center + side * point.half * shoulder_clearance
	var tex: Texture2D
	var base_width = 350.0
	var maximum_width = min(250.0, view.x * 0.175)
	if kind == "billboard":
		tex = SIGN_TEXTURES[int(object.asset)]
	elif kind == "chevron":
		tex = CHEVRON_TEX
		base_width = 190.0
		maximum_width = min(145.0, view.x * 0.105)
	else:
		tex = BARRICADE_TEX
		base_width = 205.0
		maximum_width = min(155.0, view.x * 0.112)
	var width = clamp(base_width * pow(closeness, 1.42), 8.0, maximum_width)
	var height = width * float(tex.get_height()) / float(tex.get_width())
	var rect = Rect2(x - width * 0.5, point.y - height, width, height)
	if rect.position.x < 3.0 or rect.end.x > view.x - 3.0:
		return
	draw_rect(
		Rect2(x - width * 0.43, point.y - max(1.0, height * 0.028), width * 0.86, max(1.0, height * 0.06)),
		Color(0.0, 0.0, 0.0, 0.34)
	)
	draw_texture_rect(tex, rect, false)


func _draw_car(view: Vector2) -> void:
	var keyboard_boost = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)
	var boosting = (
		state == "race"
		and (keyboard_boost or _control_state().nitro)
		and nitro > 0.0
		and speed > 120.0
	)
	var turn_amount = clamp(steer_visual, -1.0, 1.0)
	var pose_index = 2
	if turn_amount < -0.58:
		pose_index = 0
	elif turn_amount < -0.16:
		pose_index = 1
	elif turn_amount > 0.58:
		pose_index = 4
	elif turn_amount > 0.16:
		pose_index = 3
	var tex: Texture2D = CAR_POSES[pose_index]
	var width = clamp(view.x * 0.215, 180.0, 316.0)
	var height = width * float(tex.get_height()) / float(tex.get_width())
	var control = _control_state()
	var drifting = bool(control.brake) and abs(turn_amount) > 0.15 and speed > 150.0
	var turn_force = turn_amount * (1.42 if drifting else 1.0)
	var car_x = view.x * 0.5 + road_x * view.x * 0.265 + turn_force * width * 0.030
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.25)
	var suspension_bob = sin(race_distance * 0.052) * speed_ratio * 3.0
	var speed_rattle = sin(race_distance * 0.151) * max(0.0, speed_ratio - 0.70) * 2.3
	var launch_squat = boost_visual * height * 0.022
	var car_y = view.y * 0.935 + suspension_bob + speed_rattle + launch_squat
	var shadow_half = width * (0.44 + speed_ratio * 0.015)
	var shadow_y = car_y - height * 0.020
	var shadow = PackedVector2Array(
		[
			Vector2(car_x - shadow_half, shadow_y),
			Vector2(car_x - shadow_half * 0.72, shadow_y + height * 0.085),
			Vector2(car_x + shadow_half * 0.72, shadow_y + height * 0.085),
			Vector2(car_x + shadow_half, shadow_y)
		]
	)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.42))
	if boosting:
		draw_circle(
			Vector2(car_x, car_y - height * 0.05), width * 0.38, Color(1.0, 0.1, 0.62, 0.16)
		)
	var rect = Rect2(car_x - width * 0.5, car_y - height, width, height)
	var road_vibration = sin(race_distance * 0.089) * speed_ratio * 0.005
	var turn_scale = Vector2(1.0 - abs(turn_force) * 0.025, 1.0 + abs(turn_force) * 0.012)
	turn_scale *= 1.0 + camera_impact * 0.025
	draw_set_transform(rect.get_center(), turn_force * -0.032 + road_vibration, turn_scale)
	if boosting:
		_draw_mutant_boost(width, height)
	draw_texture_rect(tex, Rect2(-rect.size * 0.5, rect.size), false)
	_draw_spinning_wheels(width, height, speed_ratio, turn_force)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_spinning_wheels(width: float, height: float, speed_ratio: float, turn_force: float) -> void:
	if state != "race" or speed < 8.0:
		return
	var spin_angle = race_distance * 0.045
	var wheel_y = height * 0.315
	var wheel_centers = [Vector2(-width * 0.385, wheel_y), Vector2(width * 0.385, wheel_y)]
	for wheel_index in range(wheel_centers.size()):
		var wheel_center: Vector2 = wheel_centers[wheel_index]
		var outer_side = sign(turn_force) == (-1.0 if wheel_index == 0 else 1.0)
		var radius = width * (0.070 + (0.008 if outer_side else 0.0))
		var wheel_color = NEON_PINK if wheel_index == 0 else NEON_CYAN
		wheel_color.a = 0.20 + speed_ratio * 0.34
		draw_arc(wheel_center, radius, spin_angle, spin_angle + PI * 1.25, 18, wheel_color, max(1.0, width * 0.009), true)
		for spoke_index in range(3):
			var spoke_angle = spin_angle + float(spoke_index) * TAU / 3.0
			var spoke_end = wheel_center + Vector2(cos(spoke_angle), sin(spoke_angle)) * radius * 0.78
			draw_line(wheel_center, spoke_end, Color(wheel_color, 0.42), max(1.0, width * 0.005), true)
		var contact_y = height * 0.455
		var streak = width * (0.025 + speed_ratio * 0.090)
		draw_line(
			Vector2(wheel_center.x - streak, contact_y),
			Vector2(wheel_center.x + streak, contact_y),
			Color(0.25, 0.88, 1.0, 0.10 + speed_ratio * 0.18),
			max(1.0, width * 0.008),
			true
		)


func _draw_mutant_boost(width: float, height: float) -> void:
	var pulse = 0.86 + sin(elapsed * 34.0) * 0.14
	var flame_length = height * (0.34 + pulse * 0.12)
	var nozzles = [-width * 0.205, width * 0.205]
	for nozzle_x in nozzles:
		var origin = Vector2(nozzle_x, height * 0.25)
		var outer = PackedVector2Array(
			[
				origin + Vector2(-width * 0.055, 0.0),
				origin + Vector2(-width * 0.025, flame_length * 0.56),
				origin + Vector2(0.0, flame_length),
				origin + Vector2(width * 0.025, flame_length * 0.56),
				origin + Vector2(width * 0.055, 0.0)
			]
		)
		draw_colored_polygon(outer, Color(1.0, 0.08, 0.62, 0.45))
		var core = PackedVector2Array(
			[
				origin + Vector2(-width * 0.024, 0.0),
				origin + Vector2(0.0, flame_length * 0.72),
				origin + Vector2(width * 0.024, 0.0)
			]
		)
		draw_colored_polygon(core, Color(0.96, 0.94, 1.0, 0.90))
		draw_circle(origin, width * 0.050 * pulse, Color(0.45, 0.10, 1.0, 0.36))


func _draw_hud(view: Vector2) -> void:
	var info = _track_info(race_distance)
	draw_rect(Rect2(18, 16, 510, 78), Color(0.01, 0.01, 0.025, 0.80))
	draw_rect(Rect2(18, 16, 6, 78), info.section.accent)
	_draw_text("TTD DEATH CIRCUIT", Vector2(38, 45), 24, PEARL)
	_draw_text(
		"%s // %s" % [info.section.name, info.section.tag], Vector2(38, 76), 13, info.section.accent
	)
	var kph = int(speed * 0.52)
	_draw_text("%03d" % kph, Vector2(view.x - 270, view.y - 55), 42, HOT_YELLOW)
	_draw_text("KM/H", Vector2(view.x - 170, view.y - 55), 15, NEON_CYAN)
	_draw_text("TIME %s" % _format_time(elapsed), Vector2(550, 48), 18, PEARL)
	_draw_text(
		"RUN %02d%%" % int(race_distance / track_length * 100.0),
		Vector2(550, 76),
		14,
		info.section.accent
	)
	var nitro_rect = Rect2(view.x - 292, view.y - 30, 245, 12)
	draw_rect(nitro_rect, Color(0.04, 0.02, 0.08, 0.9))
	draw_rect(
		Rect2(nitro_rect.position, Vector2(nitro_rect.size.x * nitro / 100.0, nitro_rect.size.y)),
		NEON_PINK
	)
	_draw_text("NITRO", Vector2(view.x - 360, view.y - 18), 13, PEARL)
	_draw_minimap(view, info.section.accent)


func _draw_minimap(view: Vector2, accent: Color) -> void:
	var panel = Rect2(view.x - 235, 18, 215, 225)
	draw_rect(panel, Color(0.005, 0.015, 0.035, 0.84))
	draw_rect(panel, Color(accent, 0.12), false, 3.0)
	var center = panel.get_center() + Vector2(0, 5)
	var shifted = PackedVector2Array()
	for p in map_points:
		shifted.append(center + p)
	draw_polyline(shifted, Color(0.02, 0.02, 0.06, 0.95), 9.0, true)
	draw_polyline(shifted, accent, 3.0, true)
	for i in range(1, section_starts.size()):
		var index = int(float(section_starts[i]) / track_length * float(MAP_SAMPLES))
		index = clamp(index, 0, shifted.size() - 1)
		draw_circle(shifted[index], 4.5, HOT_YELLOW)
	var player_index = int(race_distance / track_length * float(MAP_SAMPLES))
	player_index = clamp(player_index, 0, shifted.size() - 1)
	draw_circle(shifted[player_index], 8.0, PEARL)
	draw_circle(shifted[player_index], 4.5, NEON_PINK)
	_draw_text("TITAN ROUTE 87", panel.position + Vector2(14, 22), 13, PEARL)


func _draw_touch_controls(view: Vector2) -> void:
	if state != "race":
		return
	var alpha = 0.46
	var left = Vector2(82, view.y - 92)
	var right = Vector2(202, view.y - 92)
	var brake = Vector2(view.x - 245, view.y - 108)
	var gas = Vector2(view.x - 110, view.y - 108)
	var nitro_pos = Vector2(view.x - 175, view.y - 205)
	for p in [left, right, brake, gas, nitro_pos]:
		draw_circle(p, 48.0, Color(0.01, 0.02, 0.06, alpha))
		draw_arc(p, 48.0, 0, TAU, 40, Color(NEON_CYAN, 0.72), 3.0, true)
	_draw_centered("◀", left + Vector2(0, 10), 31, NEON_CYAN)
	_draw_centered("▶", right + Vector2(0, 10), 31, NEON_CYAN)
	_draw_centered("DRIFT", brake + Vector2(0, 6), 13, NEON_PINK)
	_draw_centered("GO", gas + Vector2(0, 8), 20, NEON_GREEN)
	_draw_centered("NITRO", nitro_pos + Vector2(0, 6), 13, HOT_YELLOW)


func _draw_title(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.0, 0.0, 0.02, 0.48))
	_draw_centered("TTD", Vector2(view.x * 0.5, view.y * 0.23), 52, NEON_GREEN)
	_draw_centered("DEATH CIRCUIT", Vector2(view.x * 0.5, view.y * 0.34), 70, NEON_PINK)
	_draw_centered(
		"TITAN CITY // 90 KM // SIX DISTRICTS", Vector2(view.x * 0.5, view.y * 0.415), 18, PEARL
	)
	var button = Rect2(view.x * 0.5 - 155, view.y * 0.55, 310, 68)
	draw_rect(button, Color(0.01, 0.02, 0.04, 0.92))
	draw_rect(button, NEON_GREEN, false, 4.0)
	_draw_centered("PRESS START", button.get_center() + Vector2(0, 8), 23, NEON_GREEN)
	_draw_centered(
		"OUTRUN THE CITY. NO REFUNDS.", Vector2(view.x * 0.5, view.y * 0.72), 16, NEON_CYAN
	)


func _draw_finish(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.0, 0.0, 0.02, 0.72))
	_draw_centered("TITAN CITY CLEARED", Vector2(view.x * 0.5, view.y * 0.38), 54, NEON_GREEN)
	_draw_centered(
		"TIME %s" % _format_time(elapsed), Vector2(view.x * 0.5, view.y * 0.48), 25, PEARL
	)
	_draw_centered(
		"SIX DISTRICTS // ONE RUN // NO REFUNDS",
		Vector2(view.x * 0.5, view.y * 0.56),
		17,
		NEON_PINK
	)
	_draw_centered("TAP TO RUN IT AGAIN", Vector2(view.x * 0.5, view.y * 0.67), 19, NEON_CYAN)


func _draw_district_banner(view: Vector2) -> void:
	var section: Dictionary = sections[current_section]
	var alpha = clamp(district_banner / 0.45, 0.0, 1.0)
	draw_rect(Rect2(0, view.y * 0.22, view.x, 142), Color(0.0, 0.0, 0.02, 0.74 * alpha))
	_draw_centered(
		"SECTOR %02d" % (current_section + 1),
		Vector2(view.x * 0.5, view.y * 0.275),
		16,
		Color(section.accent, alpha)
	)
	_draw_centered(section.name, Vector2(view.x * 0.5, view.y * 0.34), 44, Color(PEARL, alpha))
	_draw_centered(
		section.tag, Vector2(view.x * 0.5, view.y * 0.39), 15, Color(section.accent, alpha)
	)


func _draw_text(text: String, position: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_centered(text: String, position: Vector2, size: int, color: Color) -> void:
	var width = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(
		ThemeDB.fallback_font,
		position - Vector2(width * 0.5, 0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		color
	)


func _format_time(value: float) -> String:
	var total = int(value)
	return "%d:%02d.%02d" % [total / 60, total % 60, int(fmod(value, 1.0) * 100.0)]


func _control_state() -> Dictionary:
	var view = get_viewport_rect().size
	var steer = 0.0
	var throttle = false
	var brake = false
	var boost = false
	for point in touch_points.values():
		if point.y > view.y * 0.68 and point.x < view.x * 0.24:
			steer = -1.0 if point.x < view.x * 0.11 else 1.0
		elif point.y > view.y * 0.72 and point.x > view.x * 0.78:
			throttle = point.x > view.x * 0.90
			brake = point.x <= view.x * 0.90
		elif point.y > view.y * 0.58 and point.x > view.x * 0.78:
			boost = true
	return {"steer": steer, "throttle": throttle, "brake": brake, "nitro": boost}


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			if state != "race":
				_start_race()
		else:
			touch_points.erase(event.index)
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
	elif event is InputEventMouseButton and event.pressed and state != "race":
		_start_race()
	elif event is InputEventKey and event.pressed and state != "race":
		_start_race()


func _start_race() -> void:
	race_distance = 0.0
	speed = 0.0
	road_x = 0.0
	nitro = 100.0
	elapsed = 0.0
	current_section = 0
	previous_section = -1
	transition_from_section = 0
	background_transition = 0.0
	district_banner = 2.5
	state = "race"
