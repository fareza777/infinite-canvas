class_name InfiniteGrid
extends MeshInstance3D

var _mat: ShaderMaterial
var _quad: QuadMesh
var _accent := Color("#2F5BFF")
var _bg_top := Color("#FAF7F1")
var _bg_bottom := Color("#EFEAE0")
var _line_color := Color(0.48, 0.43, 0.36, 0.30)


func _ready() -> void:
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	mesh = _quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material_override_setup()


func _material_override_setup() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://assets/shaders/infinite_grid.gdshader")
	material_override = _mat
	rotation = Vector3.ZERO
	_apply_palette()


func update_view(rig: CameraRig, show_grid := true, style := "lines") -> void:
	if _mat == null:
		return
	position = Vector3(rig.pivot.x, rig.pivot.y, -0.12)
	var span := maxf(40.0, rig.view_height * 3.4)
	scale = Vector3(span, span, 1.0)
	_mat.set_shader_parameter("focus", Vector2(rig.pivot.x, rig.pivot.y))
	_mat.set_shader_parameter("view_height", rig.view_height)
	_mat.set_shader_parameter("grid_enabled", 1.0 if show_grid and style != "off" else 0.0)
	_mat.set_shader_parameter("dots_only", 1.0 if style == "dots" else 0.0)
	_mat.set_shader_parameter("accent", _accent)


func set_accent(color: Color) -> void:
	_accent = color
	if _mat != null:
		_mat.set_shader_parameter("accent", color)


func set_palette(top: Color, bottom: Color, line_color: Color, accent: Color) -> void:
	_bg_top = top
	_bg_bottom = bottom
	_line_color = line_color
	_accent = accent
	_apply_palette()


func _apply_palette() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("bg_top", _bg_top)
	_mat.set_shader_parameter("bg_bottom", _bg_bottom)
	_mat.set_shader_parameter("line_color", _line_color)
	_mat.set_shader_parameter("accent", _accent)
