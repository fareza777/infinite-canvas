class_name ModelItem
extends CanvasItem3D

var model_root: Node3D
var halo: MeshInstance3D
var label: Label3D
var error_label: Label3D
var _model_size := Vector3(2, 2, 2)
var _loaded_asset := ""
var _loaded_size := -1.0
var _model_error := ""


func _build() -> void:
	halo = make_glow(5.0, Kit.VIOLET, 0.3)
	halo.position = Vector3(0, 0, -0.4)
	label = make_label("", AppFonts.body(600), 32, Color("#A9BDD8"), 0.0095, -1, VERTICAL_ALIGNMENT_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label = make_label("", AppFonts.body(500), 30, Color("#FF8FA3"), 0.0095, 760, VERTICAL_ALIGNMENT_CENTER)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.visible = false
	_load_model()


func _refresh() -> void:
	var props: Dictionary = data.get("props", {})
	if str(props.get("asset", "")) != _loaded_asset or absf(float(props.get("size", 2.4)) - _loaded_size) > 0.001:
		_load_model()
	else:
		_apply_materials()
		label.text = str(props.get("title", props.get("asset", "").get_file()))
		label.visible = bool(props.get("show_label", true))


func _load_model() -> void:
	var props: Dictionary = data.get("props", {})
	var asset := str(props.get("asset", ""))
	_loaded_asset = asset
	_loaded_size = float(props.get("size", 2.4))
	if model_root != null:
		model_root.queue_free()
		model_root = null
	error_label.visible = false
	_model_error = ""
	if asset.is_empty() or not FileAccess.file_exists(asset):
		_model_error = "3D file not found\nRe-link the GLB from the inspector"
		error_label.text = _model_error
		error_label.position = Vector3.ZERO
		error_label.visible = true
		label.visible = false
		return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err := doc.append_from_file(ProjectSettings.globalize_path(asset), state)
	if err != OK:
		_model_error = "Could not read this 3D file\nTry a binary .glb export"
		error_label.text = _model_error
		error_label.visible = true
		label.visible = false
		return
	var scene := doc.generate_scene(state)
	if scene == null:
		error_label.text = "Empty 3D scene"
		error_label.visible = true
		return
	model_root = scene
	visual.add_child(model_root)
	var aabb := _relative_aabb(model_root, Transform3D.IDENTITY)
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var target := clampf(float(props.get("size", 2.4)), 0.3, 12.0)
	var factor := target / maxf(0.0001, max_dim)
	model_root.scale = Vector3.ONE * factor
	model_root.position = -aabb.get_center() * factor
	_model_size = aabb.size * factor
	var radius := maxf(_model_size.x, maxf(_model_size.y, _model_size.z))
	halo.mesh.size = Vector2(radius * 2.5, radius * 2.5)
	halo.position = Vector3(0, 0, -radius * 0.5)
	label.text = str(props.get("title", asset.get_file()))
	label.position = Vector3(0, -radius * 0.62, 0.08)
	label.visible = bool(props.get("show_label", true))
	for player in model_root.find_children("*", "AnimationPlayer", true, false):
		var ap := player as AnimationPlayer
		if ap != null and not ap.get_animation_list().is_empty():
			ap.play(ap.get_animation_list()[0])
	_apply_materials()
	_rect = Rect2(-radius, -radius, radius * 2.0, radius * 2.0)


func _relative_aabb(node: Node, xf: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	var node_xf := xf
	if node is Node3D:
		node_xf = xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			var local := mi.get_aabb()
			var world := node_xf * local
			result = world
			first = false
	for child in node.get_children():
		var child_aabb := _relative_aabb(child, node_xf)
		if child_aabb.size == Vector3.ZERO and child_aabb.position == Vector3.ZERO:
			continue
		if first:
			result = child_aabb
			first = false
		else:
			result = result.merge(child_aabb)
	if first:
		return AABB(Vector3.ZERO, Vector3.ZERO)
	return result


func _apply_materials() -> void:
	if model_root == null:
		return
	var props: Dictionary = data.get("props", {})
	var tint := color_from(props.get("tint", "#FFFFFF"), Color.WHITE)
	var mat_props: Dictionary = props.get("material", {})
	var metallic := float(mat_props.get("metallic", 0.15))
	var roughness := float(mat_props.get("roughness", 0.6))
	var emission := color_from(mat_props.get("emission", "#000000"), Color.BLACK)
	for mi in model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mi as MeshInstance3D
		var surfaces := mesh_instance.mesh.get_surface_count() if mesh_instance.mesh != null else 0
		for i in range(surfaces):
			var original := mesh_instance.get_active_material(i)
			var mat: StandardMaterial3D
			if original is StandardMaterial3D:
				mat = (original as StandardMaterial3D).duplicate()
			else:
				mat = StandardMaterial3D.new()
			mat.albedo_color = tint
			mat.metallic = metallic
			mat.roughness = roughness
			mat.emission_enabled = emission.r + emission.g + emission.b > 0.01
			mat.emission = emission
			mat.emission_energy_multiplier = float(mat_props.get("emission_energy", 1.0))
			mesh_instance.set_surface_override_material(i, mat)


func is_flat() -> bool:
	return false


func get_bounds_aabb() -> AABB:
	var radius := maxf(_model_size.x, maxf(_model_size.y, _model_size.z)) * 0.6
	return AABB(global_position - Vector3(radius, radius, radius), Vector3(radius, radius, radius) * 2.0)


func hit_test_ray(origin: Vector3, dir: Vector3) -> float:
	var radius := maxf(0.2, maxf(_model_size.x, maxf(_model_size.y, _model_size.z)) * 0.6)
	return hit_test_sphere(origin, dir, get_center_world(), radius)


func get_center_world() -> Vector3:
	return global_transform.origin + Vector3(0, 0, 0.0)
