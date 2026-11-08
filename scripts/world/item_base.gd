class_name CanvasItem3D
extends Node3D

var app: Node
var data: Dictionary = {}
var item_id := ""
var item_type := ""
var layer_id := ""
var visual: Node3D
var _rect := Rect2(-2.0, -1.5, 4.0, 3.0)
var _built := false
var _lod_body_visible := true


func setup(p_app: Node, p_data: Dictionary) -> void:
	app = p_app
	data = p_data
	item_id = str(data.get("id", ""))
	item_type = str(data.get("type", "note"))
	layer_id = str(data.get("layer", ""))
	name = "Item_" + item_id
	if visual == null:
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
	_read_transform()
	_build()
	_built = true
	apply_layer_state()
	pop_in()


func _read_transform() -> void:
	var p: Array = data.get("pos", [0, 0, 0])
	var r: Array = data.get("rot", [0, 0, 0])
	var s: Array = data.get("scale", [1, 1, 1])
	position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation_degrees = Vector3(float(r[0]), float(r[1]), float(r[2]))
	scale = Vector3(float(s[0]), float(s[1]), float(s[2]))


func sync_transform() -> void:
	_read_transform()


func refresh_from_data() -> void:
	_read_transform()
	if _built:
		_refresh()
	apply_layer_state()


func _build() -> void:
	pass


func _refresh() -> void:
	pass


func pop_in() -> void:
	if visual == null:
		return
	visual.scale = Vector3(0.9, 0.9, 0.9)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.32)


func apply_layer_state() -> void:
	if app == null or app.project == null:
		return
	var layer: Dictionary = app.project.get_layer(layer_id)
	visible = layer.is_empty() or bool(layer.get("visible", true))


func is_locked() -> bool:
	if app == null or app.project == null:
		return false
	return app.project.is_layer_locked(layer_id)


func get_flat_rect() -> Rect2:
	return _rect


func is_flat() -> bool:
	return true


func get_world_corners() -> PackedVector3Array:
	var r := get_flat_rect()
	var out := PackedVector3Array()
	out.append(global_transform * Vector3(r.position.x, r.position.y, 0.0))
	out.append(global_transform * Vector3(r.end.x, r.position.y, 0.0))
	out.append(global_transform * Vector3(r.end.x, r.end.y, 0.0))
	out.append(global_transform * Vector3(r.position.x, r.end.y, 0.0))
	return out


func get_world_rect() -> Rect2:
	var corners := get_world_corners()
	var minp := Vector2(corners[0].x, corners[0].y)
	var maxp := minp
	for i in range(1, corners.size()):
		minp = Vector2(minf(minp.x, corners[i].x), minf(minp.y, corners[i].y))
		maxp = Vector2(maxf(maxp.x, corners[i].x), maxf(maxp.y, corners[i].y))
	return Rect2(minp, maxp - minp)


func get_bounds_aabb() -> AABB:
	var rect := get_world_rect()
	return AABB(Vector3(rect.position.x, rect.position.y, global_position.z - 0.2), Vector3(rect.size.x, rect.size.y, 0.4))


func hit_test_ray(origin: Vector3, dir: Vector3) -> float:
	var inv := global_transform.affine_inverse()
	var local_origin := inv * origin
	var local_dir := inv.basis * dir
	if absf(local_dir.z) < 0.00001:
		return -1.0
	var t_local := -local_origin.z / local_dir.z
	if t_local < 0.0:
		return -1.0
	var point := local_origin + local_dir * t_local
	if get_flat_rect().has_point(Vector2(point.x, point.y)):
		var world_point := global_transform * point
		return origin.distance_to(world_point)
	return -1.0


func hit_test_sphere(origin: Vector3, dir: Vector3, center: Vector3, radius: float) -> float:
	var oc := origin - center
	var b := oc.dot(dir)
	var c := oc.dot(oc) - radius * radius
	var disc := b * b - c
	if disc < 0.0:
		return -1.0
	var t := -b - sqrt(disc)
	if t < 0.0:
		t = -b + sqrt(disc)
	if t < 0.0:
		return -1.0
	return t


func get_center_world() -> Vector3:
	return global_transform * Vector3(0, 0, 0.02)


func update_lod(_cam_distance: float, _view_height: float) -> void:
	pass


func color_from(value, fallback := Color.WHITE) -> Color:
	if value is Color:
		return value
	if value is String and not (value as String).is_empty():
		var c := Color.from_string(value, fallback)
		return c
	return fallback


func make_label(text: String, font: Font, size_px: int, color: Color, pixel_size := 0.0045, width_px := -1, valign := VERTICAL_ALIGNMENT_CENTER) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font
	l.font_size = size_px
	l.pixel_size = pixel_size
	l.modulate = color
	l.outline_size = 0
	l.double_sided = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = valign
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.render_priority = 2
	l.width = width_px
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if width_px > 0 else TextServer.AUTOWRAP_OFF
	visual.add_child(l)
	return l


func make_quad(size: Vector2, material: Material, z := 0.0) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = material
	mi.position.z = z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(mi)
	return mi


func make_glow(size: float, color: Color, strength := 0.35) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/glow_disc.gdshader")
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("strength", strength)
	return make_quad(Vector2(size, size), mat, -0.02)


func set_lod_body(visible_body: bool) -> void:
	_lod_body_visible = visible_body
