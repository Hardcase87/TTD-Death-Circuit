extends Node2D

const MAX_SPEED = 540.0
const NITRO_SPEED = 690.0
const ACCEL = 165.0
const BRAKE_POWER = 310.0
const COAST = 52.0
const DRAW_DISTANCE = 7200.0
const ROAD_SLICES = 92
const ROAD_SCALE = 1.0
const MAP_SAMPLES = 220

const NEON_GREEN = Color("8aff2b")
const NEON_PINK = Color("ff2d95")
const NEON_CYAN = Color("39d7ff")
const HOT_YELLOW = Color("ffe53b")
const PEARL = Color("f5f2e9")

const HORIZON_TEX = preload("res://assets/environment/titan-city-horizon.png")
const GATE_TEX = preload("res://assets/environment/ttd-checkpoint-gate.png")
const CAR_MUTANT = preload("res://assets/vehicles/mutant-maniac-idle.png")
const SIGN_TEXTURES = [
	preload("res://assets/signs/billboard-death-circuit.webp"),
	preload("res://assets/signs/billboard-skull-juice.webp"),
	preload("res://assets/signs/billboard-titan-babe.webp"),
	preload("res://assets/signs/billboard-mortis.webp"),
	preload("res://assets/signs/billboard-tdi.webp")
]
const CHEVRON_TEX = preload("res://assets/signs/road-chevron.webp")
const BARRICADE_TEX = preload("res://assets/signs/road-barricade.webp")

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
var district_banner = 0.0
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
		for slot in range(9):
			var side = -1.0 if (slot + index) % 2 == 0 else 1.0
			var kind = "billboard"
			if slot in [2, 6]:
				kind = "chevron"
			elif slot == 4:
				kind = "barricade"
			world_objects.append(
				{
					"z": start + length * (0.08 + float(slot) * 0.098),
					"type": kind,
					"side": side,
					"asset": (slot + index * 2) % SIGN_TEXTURES.size(),
					"section": index
				}
			)
	world_objects.append({"z": track_length - 450.0, "type": "gate", "side": 0.0, "section": 5})


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
	var rpm = 44.0 + speed * 0.31
	for i in range(frames):
		audio_phase = fmod(audio_phase + rpm / engine_mix_rate, 1.0)
		var wave = sin(audio_phase * TAU) * 0.10
		wave += sin(audio_phase * TAU * 2.01) * 0.045
		wave += sin(audio_phase * TAU * 0.5) * 0.025
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
	var keyboard_steer = (
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	)
	var steer = keyboard_steer + float(controls.steer)
	steer = clamp(steer, -1.0, 1.0)
	steer_visual = move_toward(steer_visual, steer, delta * 5.0)

	var target_speed = NITRO_SPEED if boosting else MAX_SPEED
	if throttle:
		speed = move_toward(speed, target_speed, ACCEL * delta * (1.35 if speed < 120.0 else 1.0))
	else:
		speed = move_toward(speed, 0.0, COAST * delta)
	if braking:
		speed = move_toward(speed, 0.0, BRAKE_POWER * delta)
	if boosting:
		nitro = max(0.0, nitro - 18.0 * delta)
	else:
		nitro = min(100.0, nitro + 4.0 * delta)

	var grip = 1.75 if braking else 1.15
	road_x += steer * grip * delta * (0.45 + speed / MAX_SPEED)
	road_x = clamp(road_x, -1.32, 1.32)
	if abs(road_x) > 0.94:
		speed = move_toward(speed, MAX_SPEED * 0.50, 190.0 * delta)

	_racing_step(delta)
	queue_redraw()


func _racing_step(delta: float) -> void:
	elapsed += delta
	district_banner = max(0.0, district_banner - delta)
	race_distance += speed * ROAD_SCALE * delta
	if race_distance >= track_length:
		race_distance = track_length
		speed = 0.0
		state = "finish"
	current_section = int(_track_info(race_distance).index)
	if current_section != previous_section:
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
	var curve_wave = sin(local * TAU * (2.0 + float(index % 3))) * 0.58
	curve_wave += sin(local * TAU * 0.5 + float(index)) * 0.34
	var curve = float(section.curve) + curve_wave
	var hill = sin(local * TAU * (1.0 + float(index % 2))) * float(section.hill)
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
	var horizon = view.y * 0.43
	var bottom = view.y * 0.965
	var u = sqrt(clamp(distance / DRAW_DISTANCE, 0.0, 1.0))
	var info = _track_info(min(race_distance + distance, track_length - 1.0))
	var y = lerp(bottom, horizon, pow(u, 0.72))
	y -= float(info.hill) * sin(u * PI) * view.y * 0.22
	var half_width = lerp(view.x * 0.47, view.x * 0.012, pow(u, 0.78))
	var bend = _integrated_curve(distance) * pow(distance / DRAW_DISTANCE, 1.35)
	var center = view.x * 0.5 - road_x * view.x * 0.255 + bend * view.x * 0.49
	return {"center": center, "y": y, "half": half_width, "u": u, "info": info}


func _draw() -> void:
	var view = get_viewport_rect().size
	_draw_background(view)
	_draw_road(view)
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
	var horizon_h = view.y * 0.54
	var tint: Color = section.accent.lerp(Color.WHITE, 0.74)
	draw_texture_rect(HORIZON_TEX, Rect2(0.0, 0.0, view.x, horizon_h), false, tint)
	draw_rect(Rect2(0.0, 0.0, view.x, horizon_h), Color(section.accent, 0.055))
	var horizon = view.y * 0.43
	for layer in range(3):
		var layer_y = horizon + 16.0 + layer * 22.0
		var shift = fposmod(race_distance * (0.008 + layer * 0.006), 150.0)
		var color = Color(0.025 + layer * 0.01, 0.018, 0.06, 0.88 - layer * 0.16)
		for i in range(-2, 13):
			var x = i * 125.0 - shift
			var height = 35.0 + fmod(float(i * 47 + current_section * 31 + layer * 19), 105.0)
			draw_rect(Rect2(x, layer_y - height, 70.0 + layer * 12.0, height), color)
			if layer == 2:
				draw_rect(Rect2(x + 10.0, layer_y - height + 12.0, 4.0, 4.0), section.accent)


func _draw_road(view: Vector2) -> void:
	var current = _track_info(race_distance)
	draw_rect(Rect2(0.0, view.y * 0.42, view.x, view.y * 0.58), current.section.ground)
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


func _draw_world_objects(view: Vector2) -> void:
	var visible = []
	for object in world_objects:
		var distance: float = float(object.z) - race_distance
		if distance > 50.0 and distance < DRAW_DISTANCE:
			visible.append({"object": object, "distance": distance})
	visible.sort_custom(func(a, b): return a.distance > b.distance)
	for item in visible:
		_draw_projected_object(item.object, item.distance, view)


func _draw_projected_object(object: Dictionary, distance: float, _view: Vector2) -> void:
	var point = _road_point(distance)
	var closeness: float = 1.0 - point.u
	if closeness <= 0.01:
		return
	var kind: String = object.type
	if kind == "gate":
		var width = max(24.0, point.half * 2.52)
		var height = width * float(GATE_TEX.get_height()) / float(GATE_TEX.get_width())
		var rect = Rect2(point.center - width * 0.5, point.y - height * 0.91, width, height)
		draw_texture_rect(GATE_TEX, rect, false)
		if width > 180.0:
			var label: String = sections[int(object.section)].name
			_draw_centered(
				label,
				Vector2(point.center, point.y - height * 0.56),
				max(10, int(width * 0.035)),
				PEARL
			)
		return
	var side: float = float(object.side)
	var x = point.center + side * point.half * 1.32
	var tex: Texture2D
	var base_width = 255.0
	if kind == "billboard":
		tex = SIGN_TEXTURES[int(object.asset)]
	elif kind == "chevron":
		tex = CHEVRON_TEX
		base_width = 150.0
	else:
		tex = BARRICADE_TEX
		base_width = 170.0
	var width = max(8.0, base_width * pow(closeness, 1.42))
	var height = width * float(tex.get_height()) / float(tex.get_width())
	var rect = Rect2(x - width * 0.5, point.y - height, width, height)
	draw_texture_rect(tex, rect, false)
	if kind == "billboard" and width > 90.0:
		draw_line(
			Vector2(x - width * 0.34, point.y),
			Vector2(x - width * 0.34, point.y + height * 0.44),
			Color("17171d"),
			max(2.0, width * 0.025)
		)
		draw_line(
			Vector2(x + width * 0.34, point.y),
			Vector2(x + width * 0.34, point.y + height * 0.44),
			Color("17171d"),
			max(2.0, width * 0.025)
		)


func _draw_car(view: Vector2) -> void:
	var keyboard_boost = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)
	var boosting = (
		state == "race"
		and (keyboard_boost or _control_state().nitro)
		and nitro > 0.0
		and speed > 120.0
	)
	var tex: Texture2D = CAR_MUTANT
	var width = clamp(view.x * 0.205, 170.0, 292.0)
	var height = width * float(tex.get_height()) / float(tex.get_width())
	var car_x = view.x * 0.5 + road_x * view.x * 0.27
	var speed_ratio = clamp(speed / MAX_SPEED, 0.0, 1.25)
	var suspension_bob = sin(race_distance * 0.043) * speed_ratio * 2.6
	var car_y = view.y * 0.925 + suspension_bob
	if boosting:
		draw_circle(
			Vector2(car_x, car_y - height * 0.05), width * 0.38, Color(1.0, 0.1, 0.62, 0.16)
		)
	var rect = Rect2(car_x - width * 0.5, car_y - height, width, height)
	var road_vibration = sin(race_distance * 0.071) * speed_ratio * 0.004
	draw_set_transform(rect.get_center(), steer_visual * -0.045 + road_vibration, Vector2.ONE)
	if boosting:
		_draw_mutant_boost(width, height)
	draw_texture_rect(tex, Rect2(-rect.size * 0.5, rect.size), false)
	_draw_spinning_wheels(width, height, speed_ratio)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_spinning_wheels(width: float, height: float, speed_ratio: float) -> void:
	if state != "race" or speed < 8.0:
		return
	var spin = fposmod(race_distance * 0.022, 1.0)
	var tire_centers = [-width * 0.445, width * 0.445]
	var tire_half_width = width * 0.043
	var tire_top = -height * 0.015
	var tire_bottom = height * 0.43
	for side_index in range(tire_centers.size()):
		var tire_x: float = tire_centers[side_index]
		for tread_index in range(7):
			var phase = fposmod(float(tread_index) / 7.0 + spin, 1.0)
			var tread_y = lerp(tire_top, tire_bottom, phase)
			var edge_fade = sin(phase * PI)
			var tread_color = NEON_CYAN if (tread_index + side_index) % 2 == 0 else NEON_PINK
			tread_color.a = (0.10 + speed_ratio * 0.34) * edge_fade
			draw_line(
				Vector2(tire_x - tire_half_width, tread_y - height * 0.007),
				Vector2(tire_x + tire_half_width, tread_y + height * 0.007),
				tread_color,
				max(1.0, width * 0.006),
				true
			)
		var contact_y = height * 0.47
		var streak = width * (0.035 + speed_ratio * 0.07)
		draw_line(
			Vector2(tire_x - streak, contact_y),
			Vector2(tire_x + streak, contact_y),
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
	district_banner = 2.5
	state = "race"
