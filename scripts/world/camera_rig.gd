class_name CameraRig
extends Node3D

const FOV_2D := 5.0
const FOV_3D := 48.0
const MIN_VIEW_HEIGHT := 0.55
const MAX_VIEW_HEIGHT := 18000.0
const YAW_LIMIT := 72.0
const PITCH_MIN := -52.0
const PITCH_MAX := 74.0

var camera: Camera3D
var pivot := Vector3.ZERO
var view_height := 22.0
var yaw := 0.0
var pitch := 0.0
var fov := FOV_2D
var mode := "2d"

var pivot_target := Vector3.ZERO
var view_height_target := 22.0
var yaw_target := 0.0
var pitch_target := 0.0
var fov_target := FOV_2D

var _smooth := 14.0
var _distance := 150.0
var _size := Vector2(432.0, 960.0)
var _anim_velocity := 0.0
var reduce_motion := false


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = FOV_2D
	camera.current = true
	add_child(camera)
	_update_size()
	_apply()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_update_size()


func _update_size() -> void:
	_size = get_viewport().get_visible_rect().size
	if _size.x < 1.0 or _size.y < 1.0:
		_size = Vector2(432.0, 960.0)


func _process(delta: float) -> void:
	if reduce_motion:
		pivot = pivot_target
		view_height = view_height_target
		yaw = yaw_target
		pitch = pitch_target
		fov = fov_target
		_apply()
		return
	var speed := _smooth + _anim_velocity
	var t := 1.0 - exp(-speed * delta)
	pivot = pivot.lerp(pivot_target, t)
	view_height = lerpf(view_height, view_height_target, t)
	yaw = lerpf(yaw, yaw_target, t)
	pitch = lerpf(pitch, pitch_target, t)
	fov = lerpf(fov, fov_target, t)
	if abs(view_height - view_height_target) < 0.0005:
		view_height = view_height_target
	if abs(yaw - yaw_target) < 0.01:
		yaw = yaw_target
	if abs(pitch - pitch_target) < 0.01:
		pitch = pitch_target
	if abs(fov - fov_target) < 0.01:
		fov = fov_target
	_anim_velocity = maxf(0.0, _anim_velocity - delta * 10.0)
	_apply()


func _apply() -> void:
	if camera == null:
		return
	view_height = clampf(view_height, MIN_VIEW_HEIGHT, MAX_VIEW_HEIGHT)
	pivot_target.y = clampf(pivot_target.y, -100000.0, 100000.0)
	pivot_target.x = clampf(pivot_target.x, -100000.0, 100000.0)
	var fov_rad := deg_to_rad(fov)
	var dist := (view_height * 0.5) / tan(fov_rad * 0.5)
	_distance = dist
	var yaw_rad := deg_to_rad(yaw)
	var pitch_rad := deg_to_rad(pitch)
	var offset := Vector3(
		sin(yaw_rad) * cos(pitch_rad) * dist,
		sin(pitch_rad) * dist,
		cos(yaw_rad) * cos(pitch_rad) * dist
	)
	camera.global_position = pivot + offset
	if offset.length_squared() > 0.0001:
		camera.look_at(pivot, Vector3.UP)
	camera.fov = fov
	camera.near = clampf(dist * 0.04, 0.01, 100000.0)
	camera.far = maxf(2000.0, dist * 6.0 + 4000.0)


func set_mode_2d(animate := true) -> void:
	mode = "2d"
	yaw_target = 0.0
	pitch_target = 0.0
	fov_target = FOV_2D
	if animate:
		_anim_velocity = 26.0


func set_mode_3d(animate := true) -> void:
	mode = "3d"
	yaw_target = 26.0 if absf(yaw_target) < 1.0 else yaw_target
	pitch_target = 22.0 if absf(pitch_target) < 1.0 else pitch_target
	fov_target = FOV_3D
	if animate:
		_anim_velocity = 26.0


func toggle_mode() -> void:
	if mode == "2d":
		set_mode_3d()
	else:
		set_mode_2d()


func pan_screen(delta: Vector2) -> void:
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	right.z = 0.0
	up.z = 0.0
	if right.length_squared() < 0.0005:
		right = Vector3.RIGHT
	if up.length_squared() < 0.0005:
		up = Vector3.UP
	right = right.normalized()
	up = up.normalized()
	var wpp := view_height / maxf(1.0, _size.y)
	pivot_target += (-right * delta.x + up * delta.y) * wpp
	pivot_target.z = 0.0


func zoom_at(factor: float, screen_pos: Vector2) -> void:
	factor = clampf(factor, 0.2, 5.0)
	var anchor := screen_to_plane(screen_pos)
	var new_height := clampf(view_height_target / factor, MIN_VIEW_HEIGHT, MAX_VIEW_HEIGHT)
	var ratio := new_height / maxf(0.0001, view_height_target)
	pivot_target = anchor - (anchor - pivot_target) * ratio
	view_height_target = new_height
	pivot_target.z = 0.0


func zoom_center(factor: float) -> void:
	zoom_at(factor, _size * 0.5)


func orbit_screen(delta: Vector2) -> void:
	if mode == "2d":
		pan_screen(delta)
		return
	yaw_target = clampf(yaw_target - delta.x * 0.24, -YAW_LIMIT, YAW_LIMIT)
	pitch_target = clampf(pitch_target - delta.y * 0.20, PITCH_MIN, PITCH_MAX)


func orbit_degrees(delta_yaw: float, delta_pitch: float) -> void:
	yaw_target = clampf(yaw_target + delta_yaw, -YAW_LIMIT, YAW_LIMIT)
	pitch_target = clampf(pitch_target + delta_pitch, PITCH_MIN, PITCH_MAX)


func nudge(direction: String, amount := 0.16) -> void:
	match direction:
		"left":
			pan_screen(Vector2(_size.x * amount, 0))
		"right":
			pan_screen(Vector2(-_size.x * amount, 0))
		"up":
			pan_screen(Vector2(0, _size.y * amount))
		"down":
			pan_screen(Vector2(0, -_size.y * amount))
		"in":
			zoom_at(1.3, _size * 0.5)
		"out":
			zoom_at(0.77, _size * 0.5)


func screen_to_plane(screen_pos: Vector2, plane_z := 0.0) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.z) < 0.00001:
		return Vector3.ZERO
	var t := (plane_z - origin.z) / dir.z
	var point := origin + dir * t
	point.z = plane_z
	return point


func screen_to_camera_plane(screen_pos: Vector2, depth := 0.0) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var forward := -camera.global_transform.basis.z
	var plane_point := pivot + forward * depth
	var denom := forward.dot(dir)
	if absf(denom) < 0.00001:
		return plane_point
	var t := forward.dot(plane_point - origin) / denom
	return origin + dir * t


func world_to_screen(world: Vector3) -> Vector2:
	return camera.unproject_position(world)


func is_behind(world: Vector3) -> bool:
	return camera.is_position_behind(world)


func screen_rect_for(rect_world: Rect2) -> Rect2:
	var p0 := world_to_screen(Vector3(rect_world.position.x, rect_world.position.y, 0.0))
	var p1 := world_to_screen(Vector3(rect_world.end.x, rect_world.end.y, 0.0))
	return Rect2(p0, p1 - p0).abs()


func visible_world_rect() -> Rect2:
	var a := screen_to_plane(Vector2(0, 0))
	var b := screen_to_plane(_size)
	var c := screen_to_plane(Vector2(_size.x, 0))
	var d := screen_to_plane(Vector2(0, _size.y))
	var minx := minf(minf(a.x, b.x), minf(c.x, d.x))
	var miny := minf(minf(a.y, b.y), minf(c.y, d.y))
	var maxx := maxf(maxf(a.x, b.x), maxf(c.x, d.x))
	var maxy := maxf(maxf(a.y, b.y), maxf(c.y, d.y))
	return Rect2(minx, miny, maxx - minx, maxy - miny)


func focus_rect(rect: Rect2, margin := 1.3, animate := true) -> void:
	if rect.size.x <= 0.0 and rect.size.y <= 0.0:
		return
	var aspect := _size.x / maxf(1.0, _size.y)
	var needed_height := maxf(rect.size.y, rect.size.x / maxf(0.1, aspect)) * margin
	pivot_target = Vector3(rect.get_center().x, rect.get_center().y, 0.0)
	view_height_target = clampf(needed_height, MIN_VIEW_HEIGHT, MAX_VIEW_HEIGHT)
	if animate:
		_anim_velocity = 30.0


func focus_point(point: Vector3, height := 6.0, animate := true) -> void:
	pivot_target = Vector3(point.x, point.y, 0.0)
	view_height_target = clampf(height, MIN_VIEW_HEIGHT, MAX_VIEW_HEIGHT)
	if animate:
		_anim_velocity = 26.0


func reset_view() -> void:
	pivot_target = Vector3.ZERO
	view_height_target = 22.0
	yaw_target = 0.0
	pitch_target = 0.0
	fov_target = FOV_2D
	mode = "2d"
	_anim_velocity = 30.0


func get_state() -> Dictionary:
	return {
		"pivot": [pivot_target.x, pivot_target.y, pivot_target.z],
		"view_height": view_height_target,
		"yaw": yaw_target,
		"pitch": pitch_target,
		"mode": mode,
	}


func set_state(state: Dictionary, animate := true) -> void:
	var p: Array = state.get("pivot", [pivot_target.x, pivot_target.y, 0.0])
	pivot_target = Vector3(float(p[0]), float(p[1]), 0.0)
	view_height_target = clampf(float(state.get("view_height", view_height_target)), MIN_VIEW_HEIGHT, MAX_VIEW_HEIGHT)
	yaw_target = clampf(float(state.get("yaw", yaw_target)), -YAW_LIMIT, YAW_LIMIT)
	pitch_target = clampf(float(state.get("pitch", pitch_target)), PITCH_MIN, PITCH_MAX)
	mode = str(state.get("mode", mode))
	if mode == "3d":
		fov_target = FOV_3D
	else:
		fov_target = FOV_2D
	if not animate:
		pivot = pivot_target
		view_height = view_height_target
		yaw = yaw_target
		pitch = pitch_target
		fov = fov_target
		_apply()
	else:
		_anim_velocity = 30.0


func top_view() -> void:
	mode = "3d"
	yaw_target = 0.0
	pitch_target = 0.0
	fov_target = FOV_3D
	_anim_velocity = 30.0


func is_2d() -> bool:
	return mode == "2d"


func world_per_pixel() -> float:
	return view_height / maxf(1.0, _size.y)


func screen_center() -> Vector2:
	return _size * 0.5


func viewport_size() -> Vector2:
	return _size


func distance_to_camera(world: Vector3) -> float:
	return camera.global_position.distance_to(world)


func view_per_pixel() -> float:
	return world_per_pixel()


func apply_view_now() -> void:
	pivot = pivot_target
	view_height = view_height_target
	yaw = yaw_target
	pitch = pitch_target
	fov = fov_target
	_apply()
