class_name ShapeItem
extends CanvasItem3D

var mesh_instance: MeshInstance3D
var border_instance: MeshInstance3D
var _shape := "rect"
var _w := 3.0
var _h := 2.0
var _color := Color("#5BE7FF")
var _border := Color("#5BE7FF")
var _border_w := 0.04
var _filled := true
var _opacity := 0.25


func _build() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(mesh_instance)
	border_instance = MeshInstance3D.new()
	border_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(border_instance)
	_update_visual()


func _refresh() -> void:
	_update_visual()


func _update_visual() -> void:
	var props: Dictionary = data.get("props", {})
	_shape = str(props.get("shape", "rect"))
	_w = clampf(float(props.get("w", 3.0)), 0.2, 40.0)
	_h = clampf(float(props.get("h", 2.0)), 0.2, 40.0)
	_color = color_from(props.get("color", "#5BE7FF"), Kit.ACCENT)
	_border = color_from(props.get("border_color", "#5BE7FF"), Kit.ACCENT)
	_border_w = clampf(float(props.get("border_width", 0.04)), 0.0, 2.0)
	_filled = bool(props.get("filled", true))
	_opacity = clampf(float(props.get("opacity", 0.25)), 0.0, 1.0)
	_rect = Rect2(-_w * 0.5, -_h * 0.5, _w, _h)
	if _shape == "ellipse" or _shape == "triangle":
		_build_polygon_shape()
	else:
		_build_rect_shape()


func _build_rect_shape() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/shape_panel.gdshader")
	mat.set_shader_parameter("fill_color", Color(_color.r, _color.g, _color.b, _opacity))
	mat.set_shader_parameter("border_color", Color(_border.r, _border.g, _border.b, clampf(_opacity + 0.55, 0.0, 1.0)))
	mat.set_shader_parameter("rect_size", Vector2(_w, _h))
	mat.set_shader_parameter("radius", clampf(float(data.get("props", {}).get("corner", 0.25)), 0.0, minf(_w, _h) * 0.5))
	mat.set_shader_parameter("border_width", _border_w)
	mat.set_shader_parameter("filled", 1.0 if _filled else 0.0)
	mesh_instance.material_override = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(_w, _h)
	mesh_instance.mesh = quad
	border_instance.mesh = null
	border_instance.material_override = null


func _build_polygon_shape() -> void:
	var fill_mesh: ArrayMesh = null
	var border_mesh: ArrayMesh = null
	if _shape == "ellipse":
		fill_mesh = _ellipse_mesh(Vector2(_w * 0.5, _h * 0.5), 64)
		if _border_w > 0.0:
			border_mesh = _ellipse_ring_mesh(Vector2(_w * 0.5, _h * 0.5), 64, _border_w)
	else:
		fill_mesh = _triangle_mesh(Vector2(_w * 0.5, _h * 0.5))
		if _border_w > 0.0:
			border_mesh = _triangle_border_mesh(Vector2(_w * 0.5, _h * 0.5), _border_w)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.albedo_color = Color(_color.r, _color.g, _color.b, _opacity if _filled else 0.0)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill_mat.no_depth_test = false
	mesh_instance.mesh = fill_mesh
	mesh_instance.material_override = fill_mat
	if border_mesh != null:
		var border_mat := StandardMaterial3D.new()
		border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		border_mat.albedo_color = Color(_border.r, _border.g, _border.b, clampf(_opacity + 0.6, 0.2, 1.0))
		border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		border_instance.mesh = border_mesh
		border_instance.material_override = border_mat
		border_instance.position.z = 0.003
	else:
		border_instance.mesh = null


func _ellipse_mesh(radius: Vector2, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		st.add_vertex(Vector3(0, 0, 0))
		st.add_vertex(Vector3(cos(a0) * radius.x, sin(a0) * radius.y, 0))
		st.add_vertex(Vector3(cos(a1) * radius.x, sin(a1) * radius.y, 0))
	return st.commit()


func _ellipse_ring_mesh(radius: Vector2, segments: int, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := Vector2(maxf(0.01, radius.x - width), maxf(0.01, radius.y - width))
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var o0 := Vector3(cos(a0) * radius.x, sin(a0) * radius.y, 0)
		var o1 := Vector3(cos(a1) * radius.x, sin(a1) * radius.y, 0)
		var i0 := Vector3(cos(a0) * inner.x, sin(a0) * inner.y, 0)
		var i1 := Vector3(cos(a1) * inner.x, sin(a1) * inner.y, 0)
		st.add_vertex(o0)
		st.add_vertex(o1)
		st.add_vertex(i0)
		st.add_vertex(o1)
		st.add_vertex(i1)
		st.add_vertex(i0)
	return st.commit()


func _triangle_points(radius: Vector2) -> Array:
	return [
		Vector3(0, radius.y, 0),
		Vector3(radius.x, -radius.y, 0),
		Vector3(-radius.x, -radius.y, 0),
	]


func _triangle_mesh(radius: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := _triangle_points(radius)
	st.add_vertex(pts[0])
	st.add_vertex(pts[1])
	st.add_vertex(pts[2])
	return st.commit()


func _triangle_border_mesh(radius: Vector2, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := _triangle_points(radius)
	var center := Vector3.ZERO
	var inset := []
	for p in pts:
		var dir: Vector3 = (center - p).normalized()
		inset.append(p + dir * width)
	for i in range(3):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 3]
		var ai: Vector3 = inset[i]
		var bi: Vector3 = inset[(i + 1) % 3]
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(ai)
		st.add_vertex(b)
		st.add_vertex(bi)
		st.add_vertex(ai)
	return st.commit()


func get_flat_rect() -> Rect2:
	if _shape == "triangle":
		return Rect2(-_w * 0.5, -_h * 0.5, _w, _h)
	return _rect
