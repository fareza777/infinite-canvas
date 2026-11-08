class_name FrameItem
extends CanvasItem3D

const W := 6.4
const H := 4.6
const PIXEL := 0.0095
const PAD := 0.38

var panel: MeshInstance3D
var panel_mat: ShaderMaterial
var frame_outline: MeshInstance3D
var number_label: Label3D
var title_label: Label3D
var body_label: Label3D
var footer_label: Label3D
var status_label: Label3D


func _build() -> void:
	panel_mat = ShaderMaterial.new()
	panel_mat.shader = load("res://assets/shaders/note_panel.gdshader")
	panel = make_quad(Vector2(W, H), panel_mat, 0.0)
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = load("res://assets/shaders/shape_panel.gdshader")
	frame_outline = make_quad(Vector2(W - 0.75, H - 1.55), outline_mat, -0.004)
	frame_outline.position = Vector3(0.0, 0.42, -0.004)
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = load("res://assets/shaders/note_shadow.gdshader")
	var shadow := make_quad(Vector2(W + 0.3, H + 0.3), shadow_mat, -0.025)
	shadow.position = Vector3(0.08, -0.12, -0.025)
	shadow_mat.set_shader_parameter("rect_size", Vector2(W + 0.3, H + 0.3))
	shadow_mat.set_shader_parameter("radius", 0.24)
	shadow_mat.set_shader_parameter("opacity", 0.5)
	number_label = make_label("01", AppFonts.display(700), 100, Color("#5BE7FF"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	title_label = make_label("Frame", AppFonts.display(600), 44, Color("#EDF3FF"), PIXEL, 340, VERTICAL_ALIGNMENT_TOP)
	body_label = make_label("", AppFonts.body(450), 34, Color("#A9B8CF"), PIXEL, 340, VERTICAL_ALIGNMENT_TOP)
	footer_label = make_label("3s  ·  16:9", AppFonts.mono(500), 28, Color("#7F92AC"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	status_label = make_label("DRAFT", AppFonts.body(650), 26, Color("#5BE7FF"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_visual()


func _refresh() -> void:
	_update_visual()


func _update_visual() -> void:
	var props: Dictionary = data.get("props", {})
	var order := int(props.get("order", 1))
	var status := str(props.get("status", "Draft"))
	var accent := Color("#5BE7FF")
	if status.to_lower() == "final":
		accent = Kit.GREEN
	elif status.to_lower() == "ready":
		accent = Kit.GOLD
	elif status.to_lower() == "draft":
		accent = Kit.VIOLET
	number_label.text = "%02d" % order
	number_label.modulate = accent
	var shot_title := str(props.get("title", "Untitled shot"))
	if shot_title.length() > 38:
		shot_title = shot_title.substr(0, 37) + "…"
	title_label.text = shot_title
	var summary := str(props.get("body", "Describe the action, camera and mood."))
	if summary.length() > 64:
		summary = summary.substr(0, 63) + "…"
	body_label.text = summary
	footer_label.text = "%ss  ·  16:9" % str(props.get("duration", 3))
	status_label.text = status.to_upper()
	status_label.modulate = accent
	panel_mat.set_shader_parameter("base_color", Color("#0C1421"))
	panel_mat.set_shader_parameter("accent", accent)
	panel_mat.set_shader_parameter("border_color", Color(0.55, 0.72, 0.95, 0.35))
	panel_mat.set_shader_parameter("rect_size", Vector2(W, H))
	panel_mat.set_shader_parameter("radius", 0.24)
	panel_mat.set_shader_parameter("header_height", 1.5)
	panel_mat.set_shader_parameter("footer_height", 0.66)
	panel_mat.set_shader_parameter("dark", 1.0)
	panel_mat.set_shader_parameter("grain", 0.25)
	panel_mat.set_shader_parameter("left_bar", 1.0)
	var outline_mat := frame_outline.material_override as ShaderMaterial
	outline_mat.set_shader_parameter("rect_size", Vector2(W - 0.75, H - 1.55))
	outline_mat.set_shader_parameter("radius", 0.16)
	outline_mat.set_shader_parameter("fill_color", Color(accent.r, accent.g, accent.b, 0.025))
	outline_mat.set_shader_parameter("border_color", Color(accent.r, accent.g, accent.b, 0.35))
	outline_mat.set_shader_parameter("border_width", 0.02)
	outline_mat.set_shader_parameter("filled", 0.0)
	number_label.position = Vector3(-W * 0.5 + PAD, H * 0.5 - 0.72, 0.014)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.position = Vector3(-W * 0.5 + 1.72, H * 0.5 - 0.30, 0.014)
	body_label.position = Vector3(-W * 0.5 + 1.72, H * 0.5 - 1.10, 0.014)
	status_label.position = Vector3(W * 0.5 - PAD - 0.52, -H * 0.5 + 0.38, 0.014)
	footer_label.position = Vector3(-W * 0.5 + PAD, -H * 0.5 + 0.38, 0.014)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_rect = Rect2(-W * 0.5, -H * 0.5, W, H)
