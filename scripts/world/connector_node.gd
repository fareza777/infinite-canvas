class_name ConnectorNode
extends Node3D

var app: Node
var data: Dictionary = {}
var connector_id := ""
var from_node: Node3D
var to_node: Node3D
var core: MeshInstance3D
var glow: MeshInstance3D
var label: Label3D
var _samples: PackedVector3Array = PackedVector3Array()
var _selected := false
var _width := 0.03
var _base_color := Color("#8FA0B8")
var _label_text := ""
var _arrow := true
var _dashed := false


func setup(p_app: Node, p_data: Dictionary) -> void:
	app = p_app
	data = p_data
	connector_id = str(data.get("id", ""))
	core = MeshInstance3D.new()
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	glow = MeshInstance3D.new()
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)
	label = Label3D.new()
	label.font = AppFonts.body(600)
	label.font_size = 34
	label.pixel_size = 0.0095
	label.double_sided = true
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.outline_size = 7
	label.outline_modulate = Color(0.02, 0.035, 0.06, 0.95)
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	label.render_priority = 3
	add_child(label)
	refresh()


func refresh(view_height := 13.0) -> void:
	if app == null:
		return
	from_node = app.item_nodes.get(str(data.get("from", "")), null)
	to_node = app.item_nodes.get(str(data.get("to", "")), null)
	if from_node == null or to_node == null:
		visible = false
		return
	visible = true
	_base_color = _color(data.get("color", "#8FA0B8"))
	_arrow = bool(data.get("arrow", true))
	_dashed = bool(data.get("dashed", false)) or str(data.get("style", "")) == "dashed"
	_label_text = str(data.get("label", ""))
	var mult := clampf(float(data.get("width", 0.035)) / 0.035, 0.4, 3.0)
	_width = clampf(view_height * 0.00135 * mult, 0.006, 1.2)
	if _selected:
		_base_color = Kit.ACCENT
	var from_center: Vector3 = from_node.get_center_world()
	var to_center: Vector3 = to_node.get_center_world()
	var start := _anchor(from_node, to_center)
	var end := _anchor(to_node, from_center)
	if start.distance_to(end) < 0.05:
		visible = false
		return
	_samples = _curve(start, end)
	_build_meshes()
	label.visible = not _label_text.is_empty()
	if label.visible:
		var mid := _samples[int(_samples.size() / 2)]
		label.position = mid + Vector3(0.07, 0.07, 0.02)
		label.text = _label_text
		label.modulate = _base_color.lightened(0.35)
		label.outline_modulate = Color(0.02, 0.035, 0.06, 0.93)


func _color(value) -> Color:
	if value is Color:
		return value
	return Color.from_string(str(value), Color("#8FA0B8"))


func _anchor(node: Node3D, toward: Vector3) -> Vector3:
	if node is CanvasItem3D and (node as CanvasItem3D).is_flat() and node is not PrimitiveItem and node is not ModelItem:
		var item := node as CanvasItem3D
		var local_toward := item.to_local(toward)
		var rect := item.get_flat_rect()
		var dir := Vector2(local_toward.x, local_toward.y)
		if dir.length_squared() < 0.000001:
			dir = Vector2(0, -1)
		var half := rect.size * 0.5
		var tx := 100000.0
		var ty := 100000.0
		if absf(dir.x) > 0.00001:
			tx = half.x / absf(dir.x)
		if absf(dir.y) > 0.00001:
			ty = half.y / absf(dir.y)
		var t := minf(tx, ty) * 0.97
		var local_point := Vector3(dir.x * t, dir.y * t, 0.055)
		return item.global_transform * local_point
	var radius := 0.8
	if node is PrimitiveItem:
		radius = 0.8
	elif node is ModelItem:
		radius = 0.9
	else:
		radius = 1.2
	var center: Vector3 = node.get_center_world()
	var dir3: Vector3 = toward - center
	if dir3.length_squared() < 0.000001:
		return center
	return center + dir3.normalized() * radius


func _curve(start: Vector3, end: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	var delta := end - start
	var dist := delta.length()
	var dir2 := Vector2(delta.x, delta.y)
	if dir2.length_squared() < 0.0001:
		dir2 = Vector2(1, 0)
	dir2 = dir2.normalized()
	var perp := Vector2(-dir2.y, dir2.x)
	var bend := clampf(dist * 0.16, 0.12, 2.2)
	if str(data.get("style", "curve")) == "straight":
		bend = 0.0
	var c1 := start + delta * 0.32 + Vector3(perp.x, perp.y, 0) * bend
	var c2 := start + delta * 0.68 + Vector3(perp.x, perp.y, 0) * bend
	var steps := clampi(int(dist * 8.0), 12, 48)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := _bezier(start, c1, c2, end, t)
		if i > 0 and result[result.size() - 1].distance_to(p) < 0.005:
			continue
		result.append(p)
	return result


func _bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var mt := 1.0 - t
	return p0 * mt * mt * mt + p1 * 3.0 * mt * mt * t + p2 * 3.0 * mt * t * t + p3 * t * t * t


func _build_meshes() -> void:
	var core_mesh := _tube_mesh(_width, false)
	core.mesh = core_mesh
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = _base_color
	core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	core_mat.disable_receive_shadows = true
	core.material_override = core_mat
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = Color(_base_color.r, _base_color.g, _base_color.b, 0.10)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_mat.disable_receive_shadows = true
	glow.mesh = _tube_mesh(_width * 3.2, true)
	glow.material_override = glow_mat


func _tube_mesh(radius: float, glow_pass: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var samples := _samples
	if samples.size() < 2:
		return null
	var dash_phase := 0.0
	var prev_ring := []
	for i in range(samples.size()):
		var p := samples[i]
		var tangent: Vector3
		if i == 0:
			tangent = samples[1] - samples[0]
		elif i == samples.size() - 1:
			tangent = samples[i] - samples[i - 1]
		else:
			tangent = samples[i + 1] - samples[i - 1]
		if tangent.length_squared() < 0.000001:
			tangent = Vector3(1, 0, 0)
		tangent = tangent.normalized()
		var side1 := tangent.cross(Vector3(0, 0, 1))
		if side1.length_squared() < 0.000001:
			side1 = Vector3(1, 0, 0)
		side1 = side1.normalized()
		var side2 := tangent.cross(side1).normalized()
		var ring := [
			p + side1 * radius,
			p + side2 * radius,
			p - side1 * radius,
			p - side2 * radius,
		]
		var show := true
		if _dashed:
			show = int(dash_phase / maxf(0.08, radius * 16.0)) % 2 == 0
			dash_phase += (samples[i] - samples[maxi(0, i - 1)]).length()
		if i > 0 and show and not prev_ring.is_empty():
			for s in range(4):
				var a: Vector3 = prev_ring[s]
				var b: Vector3 = prev_ring[(s + 1) % 4]
				var c: Vector3 = ring[s]
				var d: Vector3 = ring[(s + 1) % 4]
				st.add_vertex(a)
				st.add_vertex(b)
				st.add_vertex(c)
				st.add_vertex(b)
				st.add_vertex(d)
				st.add_vertex(c)
		prev_ring = ring if show else []
	if _arrow and not glow_pass and samples.size() >= 2:
		_add_arrow(st, samples[samples.size() - 2], samples[samples.size() - 1], radius)
	return st.commit()


func _add_arrow(st: SurfaceTool, before: Vector3, tip: Vector3, radius: float) -> void:
	var dir := tip - before
	if dir.length_squared() < 0.000001:
		return
	dir = dir.normalized()
	var side1 := dir.cross(Vector3(0, 0, 1))
	if side1.length_squared() < 0.000001:
		side1 = Vector3(1, 0, 0)
	side1 = side1.normalized()
	var side2 := dir.cross(side1).normalized()
	var base := tip - dir * radius * 5.5
	var r := radius * 3.2
	var p0 := base + side1 * r
	var p1 := base + side2 * r
	var p2 := base - side1 * r
	var p3 := base - side2 * r
	st.add_vertex(p0)
	st.add_vertex(p1)
	st.add_vertex(tip)
	st.add_vertex(p1)
	st.add_vertex(p2)
	st.add_vertex(tip)
	st.add_vertex(p2)
	st.add_vertex(p3)
	st.add_vertex(tip)
	st.add_vertex(p3)
	st.add_vertex(p0)
	st.add_vertex(tip)


func set_selected(selected: bool) -> void:
	if _selected == selected:
		return
	_selected = selected
	refresh(app.rig.view_height if app != null and app.rig != null else 13.0)


func screen_distance(rig: CameraRig, screen_pos: Vector2) -> float:
	if _samples.size() < 2 or not visible:
		return INF
	var best := INF
	for i in range(_samples.size() - 1):
		var a := rig.world_to_screen(_samples[i])
		var b := rig.world_to_screen(_samples[i + 1])
		if rig.is_behind(_samples[i]):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(screen_pos, a, b)
		best = minf(best, closest.distance_to(screen_pos))
	return best
