class_name StrokeItem
extends CanvasItem3D

var mesh_instance: MeshInstance3D
var glow_instance: MeshInstance3D
var _points: Array = []
var _color := Color("#5BE7FF")
var _width := 0.05
var _kind := "pen"
var _material: StandardMaterial3D


func _build() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(mesh_instance)
	glow_instance = MeshInstance3D.new()
	glow_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(glow_instance)
	_update_material()
	rebuild()


func _update_material() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = _color
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = false
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.disable_receive_shadows = true
	if _kind == "highlighter":
		_material.albedo_color = Color(_color.r, _color.g, _color.b, 0.32)
		_material.render_priority = 1


func _refresh() -> void:
	var props: Dictionary = data.get("props", {})
	_color = color_from(props.get("color", "#5BE7FF"), Kit.ACCENT)
	_width = maxf(0.004, float(props.get("width", 0.05)))
	_kind = str(props.get("kind", "pen"))
	_points = props.get("points", [])
	_update_material()
	rebuild()


func set_points(points: Array, width: float, color: Color, kind: String) -> void:
	_points = points
	_width = maxf(0.002, width)
	_color = color
	_kind = kind
	_update_material()
	rebuild()


func add_point(world_point: Vector3, pressure: float) -> void:
	if _points.size() >= 4200:
		return
	var last := Vector3.ZERO
	if not _points.is_empty():
		var lp: Array = _points[-1]
		last = Vector3(float(lp[0]), float(lp[1]), float(lp[2]))
		if last.distance_to(world_point) < maxf(0.008, _width * 0.35):
			return
	_points.append([world_point.x, world_point.y, world_point.z, pressure])
	rebuild()


func rebuild() -> void:
	if mesh_instance == null:
		return
	if _points.size() < 2:
		mesh_instance.mesh = null
		glow_instance.mesh = null
		return
	var mesh := _build_mesh(_width, 1.0)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material
	if _kind == "highlighter":
		glow_instance.mesh = null
	else:
		var glow_mat := StandardMaterial3D.new()
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.16)
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		glow_mat.disable_receive_shadows = true
		glow_instance.mesh = _build_mesh(_width * 2.8, 0.0)
		glow_instance.material_override = glow_mat
	_build_bounds()


func _build_mesh(width: float, z_bias: float) -> ArrayMesh:
	var count := _points.size()
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var caps := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(count):
		var p: Array = _points[i]
		var pos := Vector3(float(p[0]), float(p[1]), float(p[2]) + z_bias)
		var pressure := clampf(float(p[3]), 0.0, 1.0) if p.size() > 3 else 0.7
		var w := width * (0.45 + pressure * 0.85)
		var prev_pos := Vector3.ZERO
		var next_pos := Vector3.ZERO
		if i > 0:
			var pp: Array = _points[i - 1]
			prev_pos = Vector3(float(pp[0]), float(pp[1]), float(pp[2]) + z_bias)
		else:
			prev_pos = pos - (Vector3(float(_points[1][0]), float(_points[1][1]), float(_points[1][2]) + z_bias) - pos)
		if i < count - 1:
			var np: Array = _points[i + 1]
			next_pos = Vector3(float(np[0]), float(np[1]), float(np[2]) + z_bias)
		else:
			next_pos = pos + (pos - prev_pos)
		var dir := (next_pos - prev_pos)
		dir.z = 0.0
		if dir.length_squared() < 0.0000001:
			dir = Vector3.RIGHT
		dir = dir.normalized()
		var perp := Vector3(-dir.y, dir.x, 0.0)
		verts.append(pos - perp * w)
		verts.append(pos + perp * w)
		caps.append(pos)
		radii.append(w)
	for i in range(count - 1):
		var base := i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)
	var cap_segments := 8
	for end_i in [0, count - 1]:
		var c: Vector3 = caps[end_i]
		var r: float = radii[end_i]
		var center_index := verts.size()
		verts.append(c)
		for s in range(cap_segments + 1):
			var a := TAU * float(s) / float(cap_segments)
			verts.append(c + Vector3(cos(a) * r, sin(a) * r, 0.0))
		for s in range(cap_segments):
			indices.append(center_index)
			indices.append(center_index + 1 + s)
			indices.append(center_index + 2 + s)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in range(verts.size()):
		st.add_vertex(verts[i])
	for i in range(indices.size()):
		st.add_index(indices[i])
	return st.commit()


func _build_bounds() -> void:
	if _points.is_empty():
		_rect = Rect2(0, 0, 0, 0)
		return
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for p in _points:
		var v := Vector2(float(p[0]), float(p[1]))
		minp = Vector2(minf(minp.x, v.x), minf(minp.y, v.y))
		maxp = Vector2(maxf(maxp.x, v.x), maxf(maxp.y, v.y))
	var pad := _width * 2.0 + 0.1
	_rect = Rect2(minp - Vector2(pad, pad), maxp - minp + Vector2(pad, pad) * 2.0)


func contains_world_point(world: Vector3, tolerance := 0.0) -> bool:
	if _points.size() < 2:
		return false
	var local := to_local(world)
	var threshold := _width * 1.6 + tolerance
	for i in range(_points.size() - 1):
		var a := Vector3(float(_points[i][0]), float(_points[i][1]), float(_points[i][2]))
		var b := Vector3(float(_points[i + 1][0]), float(_points[i + 1][1]), float(_points[i + 1][2]))
		if _distance_point_segment(local, a, b) <= threshold:
			return true
	return false


func _distance_point_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(0.000001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func hit_test_ray(origin: Vector3, dir: Vector3) -> float:
	if _points.size() < 2:
		return -1.0
	var threshold := _width * 1.8 + 0.02
	var ray_end := origin + dir * 100000.0
	var best := INF
	for i in range(_points.size() - 1):
		var a := Vector3(float(_points[i][0]), float(_points[i][1]), float(_points[i][2]))
		var b := Vector3(float(_points[i + 1][0]), float(_points[i + 1][1]), float(_points[i + 1][2]))
		var closest := Geometry3D.get_closest_points_between_segments(a, b, origin, ray_end)
		if closest.size() >= 2 and closest[0].distance_to(closest[1]) <= threshold:
			var along := (closest[1] - origin).dot(dir)
			if along >= 0.0:
				best = minf(best, along)
	return -1.0 if best == INF else best


func point_count() -> int:
	return _points.size()
