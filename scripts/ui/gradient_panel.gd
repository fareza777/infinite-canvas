class_name GradientPanel
extends Control

var color_a := Color("#5BE7FF")
var color_b := Color("#8B5CF6")
var color_c := Color("#1B2A4A")
var radius := 18.0
var border_width := 0.0
var border_color := Color(1, 1, 1, 0.12)
var sheen := 0.5
var _mat: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://assets/shaders/ui_gradient.gdshader")
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	material = _mat
	resized.connect(_sync)
	_sync()


func setup(a: Color, b: Color, c := Color("#1B2A4A"), p_radius := 18.0, p_border := 0.0, p_sheen := 0.5) -> GradientPanel:
	color_a = a
	color_b = b
	color_c = c
	radius = p_radius
	border_width = p_border
	sheen = p_sheen
	_sync()
	return self


func _sync() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("color_a", color_a)
	_mat.set_shader_parameter("color_b", color_b)
	_mat.set_shader_parameter("color_c", color_c)
	_mat.set_shader_parameter("radius", radius)
	_mat.set_shader_parameter("rect_size", size)
	_mat.set_shader_parameter("border_width", border_width)
	_mat.set_shader_parameter("border_color", border_color)
	_mat.set_shader_parameter("sheen", sheen)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, true)


func set_gradient(a: Color, b: Color) -> void:
	color_a = a
	color_b = b
	_sync()
