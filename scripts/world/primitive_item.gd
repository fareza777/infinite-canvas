class_name PrimitiveItem
extends CanvasItem3D

var mesh_instance: MeshInstance3D
var halo: MeshInstance3D
var label: Label3D
var _mesh_size := 1.6


func _build() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual.add_child(mesh_instance)
	var props: Dictionary = data.get("props", {})
	var accent := color_from(props.get("accent", props.get("color", "#5BE7FF")), Kit.ACCENT)
	halo = make_glow(1.0, accent, 0.28)
	halo.position = Vector3(0, 0, -0.7)
	label = make_label("", AppFonts.body(600), 30, Color("#9FB4D0"), 0.0095, -1, VERTICAL_ALIGNMENT_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_visual()


func _refresh() -> void:
	_update_visual()


func _update_visual() -> void:
	var props: Dictionary = data.get("props", {})
	var shape := str(props.get("shape", "box"))
	var size := float(props.get("size", 1.6))
	_mesh_size = clampf(size, 0.2, 20.0)
	var mesh: Mesh
	match shape:
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = _mesh_size * 0.5
			sphere.height = _mesh_size
			sphere.radial_segments = 48
			sphere.rings = 24
			mesh = sphere
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = _mesh_size * 0.36
			cylinder.bottom_radius = _mesh_size * 0.36
			cylinder.height = _mesh_size * 1.1
			cylinder.radial_segments = 48
			mesh = cylinder
		"cone":
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = _mesh_size * 0.45
			cone.height = _mesh_size * 1.15
			cone.radial_segments = 48
			mesh = cone
		"torus":
			var torus := TorusMesh.new()
			torus.inner_radius = _mesh_size * 0.3
			torus.outer_radius = _mesh_size * 0.55
			torus.rings = 48
			torus.ring_segments = 24
			mesh = torus
		"plane":
			var plane := PlaneMesh.new()
			plane.size = Vector2(_mesh_size * 1.5, _mesh_size * 1.1)
			mesh = plane
		_:
			var box := BoxMesh.new()
			box.size = Vector3(_mesh_size * 1.15, _mesh_size * 0.85, _mesh_size * 0.85)
			mesh = box
	mesh_instance.mesh = mesh
	var color := color_from(props.get("color", "#5BE7FF"), Kit.ACCENT)
	var metallic := float(props.get("metallic", 0.35))
	var roughness := float(props.get("roughness", 0.35))
	var emission := color_from(props.get("emission", "#000000"), Color.BLACK)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = clampf(metallic, 0.0, 1.0)
	mat.roughness = clampf(roughness, 0.02, 1.0)
	mat.emission_enabled = emission.r + emission.g + emission.b > 0.01
	mat.emission = emission
	mat.emission_energy_multiplier = float(props.get("emission_energy", 1.2))
	mat.rim_enabled = true
	mat.rim = 0.35
	mat.rim_tint = 0.35
	mesh_instance.material_override = mat
	var halo_mat := halo.material_override as ShaderMaterial
	halo_mat.set_shader_parameter("glow_color", Color(color.r, color.g, color.b, 1.0))
	halo.mesh.size = Vector2(_mesh_size * 2.4, _mesh_size * 2.4)
	halo.position = Vector3(0, 0, -_mesh_size * 0.55)
	label.text = shape.capitalize()
	label.position = Vector3(0, -_mesh_size * 0.72, 0.05)
	label.visible = bool(props.get("show_label", false))
	var radius := _mesh_size * 0.72
	_rect = Rect2(-radius, -radius, radius * 2.0, radius * 2.0)


func is_flat() -> bool:
	return false


func get_bounds_aabb() -> AABB:
	if mesh_instance == null or mesh_instance.mesh == null:
		return AABB(global_position, Vector3.ONE)
	var aabb := mesh_instance.get_aabb()
	var xf := mesh_instance.global_transform
	var result := AABB(xf * aabb.position, Vector3.ZERO)
	var corners := [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	var first := true
	for c in corners:
		var w: Vector3 = xf * c
		if first:
			result = AABB(w, Vector3.ZERO)
			first = false
		else:
			result = result.expand(w)
	return result


func hit_test_ray(origin: Vector3, dir: Vector3) -> float:
	var center := mesh_instance.global_transform.origin if mesh_instance != null else global_position
	return hit_test_sphere(origin, dir, center, _mesh_size * 0.62)


func get_center_world() -> Vector3:
	if mesh_instance != null:
		return mesh_instance.global_transform.origin
	return global_position
