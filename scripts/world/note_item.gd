class_name NoteItem
extends CanvasItem3D

const PIXEL := 0.0095
const PAD := 0.32
const HEADER := 0.72
const FOOTER := 0.42
const MAX_HEIGHT := 9.4
const MIN_HEIGHT := 2.5
const TITLE_PX := 66
const BODY_PX := 40
const TAG_PX := 34

var panel: MeshInstance3D
var panel_mat: ShaderMaterial
var shadow: MeshInstance3D
var title_label: Label3D
var body_label: Label3D
var tags_label: Label3D
var pin_label: Label3D
var type_icon: Label3D

var _width := 5.6
var _height := 3.2
var _wrap_px := 1000
var _is_text := false
var _full_body := ""
var _preview_body := ""


func _build() -> void:
	_width = float(data.get("props", {}).get("width", 5.6))
	_is_text = str(data.get("props", {}).get("style", "note")) == "text"
	if _is_text:
		_width = maxf(_width, 5.0)
	panel_mat = ShaderMaterial.new()
	panel_mat.shader = load("res://assets/shaders/note_panel.gdshader")
	panel = make_quad(Vector2(_width, _height), panel_mat, 0.0)
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = load("res://assets/shaders/note_shadow.gdshader")
	shadow = make_quad(Vector2(_width + 0.24, _height + 0.24), shadow_mat, -0.022)
	shadow.position = Vector3(0.035, -0.06, -0.022)
	var shadow_material := shadow.material_override as ShaderMaterial
	if shadow_material != null:
		shadow_material.set_shader_parameter("shadow_color", Color("#17213A"))
		shadow_material.set_shader_parameter("softness", 0.32)
	title_label = make_label("", AppFonts.display(650), TITLE_PX, Color("#111827"), PIXEL, 1000, VERTICAL_ALIGNMENT_TOP)
	body_label = make_label("", AppFonts.body(450), BODY_PX, Color("#26303F"), PIXEL, 1000, VERTICAL_ALIGNMENT_TOP)
	tags_label = make_label("", AppFonts.body(600), TAG_PX, Color("#4B5A6E"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	pin_label = make_label(Icons.glyph("push_pin"), AppFonts.icon_font(1.0, 500.0), 38, Color("#3A4658"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	pin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_icon = make_label(Icons.glyph("sticky_note_2"), AppFonts.icon_font(0.0, 400.0), 28, Color("#6B7A90"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	type_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_visual()


func _refresh() -> void:
	_update_visual()


func _update_visual() -> void:
	var props: Dictionary = data.get("props", {})
	var title := str(props.get("title", "Untitled idea"))
	var body := str(props.get("body", ""))
	_full_body = body
	var accent := color_from(props.get("accent", "#5BE7FF"), Kit.ACCENT)
	var base := color_from(props.get("color", "#F4F1E8"), Color("#F4F1E8"))
	var dark := bool(props.get("dark", false))
	var ink := color_from(props.get("ink", "#101722" if not dark else "#ECF3FF"), Color("#101722"))
	var title_font := AppFonts.display(650)
	var body_font := AppFonts.body(450)
	var title_px := TITLE_PX
	var body_px := BODY_PX
	if _is_text:
		title_px = 80
		body_px = 46
		ink = Color("#EDF3FF")
	_width = float(props.get("width", 7.0 if _is_text else 5.6))
	var wrap_px := int((_width - PAD * 2.0) / PIXEL)
	_wrap_px = wrap_px
	var shown_title := title
	var title_meas := title_font.get_multiline_string_size(shown_title, HORIZONTAL_ALIGNMENT_LEFT, wrap_px, title_px)
	while title_meas.y * PIXEL > 3.25 and shown_title.length() > 14:
		shown_title = shown_title.substr(0, int(shown_title.length() * 0.88)).strip_edges() + "…"
		title_meas = title_font.get_multiline_string_size(shown_title, HORIZONTAL_ALIGNMENT_LEFT, wrap_px, title_px)
	var title_h := maxf(0.30, title_meas.y * PIXEL)
	var preview := body
	if preview.length() > 1100:
		preview = preview.substr(0, 1100) + "…"
	var max_body := (MAX_HEIGHT - PAD - title_h - FOOTER - 0.5)
	var body_meas := body_font.get_multiline_string_size(preview, HORIZONTAL_ALIGNMENT_LEFT, wrap_px, body_px)
	while body_meas.y * PIXEL > max_body and preview.length() > 60:
		preview = preview.substr(0, int(preview.length() * 0.82)) + "…"
		body_meas = body_font.get_multiline_string_size(preview, HORIZONTAL_ALIGNMENT_LEFT, wrap_px, body_px)
	_preview_body = preview
	var body_h := body_meas.y * PIXEL
	var height := PAD + title_h + 0.18 + body_h + 0.18 + FOOTER + 0.08
	height = clampf(height, MIN_HEIGHT, MAX_HEIGHT)
	if _is_text:
		height = clampf(height + 0.4, 1.4, MAX_HEIGHT)
	_height = height

	title_label.text = shown_title
	title_label.font = title_font
	title_label.font_size = title_px
	title_label.width = wrap_px
	title_label.modulate = ink
	body_label.text = preview
	body_label.font = body_font
	body_label.font_size = body_px
	body_label.width = wrap_px
	body_label.modulate = ink.lerp(Color(ink.r, ink.g, ink.b, 0.78), 0.7)
	var tags: Array = props.get("tags", [])
	var tag_text := ""
	for i in range(tags.size()):
		tag_text += "#" + str(tags[i]) + ("   " if i < tags.size() - 1 else "")
	if tag_text.is_empty():
		tag_text = "NOTE" if not _is_text else "TEXT"
	tags_label.text = tag_text
	tags_label.font_size = TAG_PX
	tags_label.modulate = ink.lerp(accent, 0.55).lerp(Color(ink.r, ink.g, ink.b, 0.55), 0.45)
	pin_label.visible = bool(props.get("pinned", false))
	pin_label.modulate = accent.darkened(0.25)
	type_icon.visible = not pin_label.visible
	type_icon.text = Icons.glyph("text_fields" if _is_text else "sticky_note_2")
	type_icon.modulate = ink.lerp(accent, 0.4).lerp(Color(ink.r, ink.g, ink.b, 0.5), 0.4)

	var top := _height * 0.5
	var left := -_width * 0.5 + PAD
	var z := 0.014
	title_label.position = Vector3(left, top - PAD, z)
	body_label.position = Vector3(left, top - PAD - title_h - 0.18, z)
	tags_label.position = Vector3(left, -_height * 0.5 + FOOTER * 0.55, z)
	tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pin_label.position = Vector3(_width * 0.5 - 0.34, top - 0.30, z)
	type_icon.position = Vector3(_width * 0.5 - 0.32, -_height * 0.5 + FOOTER * 0.55, z)

	title_label.visible = true
	body_label.visible = not preview.strip_edges().is_empty()
	panel.visible = not _is_text
	shadow.visible = not _is_text
	if panel.visible:
		panel.mesh.size = Vector2(_width, _height)
		shadow.mesh.size = Vector2(_width + 0.24, _height + 0.24)
		panel_mat.set_shader_parameter("base_color", base)
		panel_mat.set_shader_parameter("accent", accent)
		panel_mat.set_shader_parameter("ink_color", ink)
		panel_mat.set_shader_parameter("border_color", Color("#0B111A") if not dark else Color(1, 1, 1, 0.25))
		panel_mat.set_shader_parameter("rect_size", Vector2(_width, _height))
		panel_mat.set_shader_parameter("radius", 0.22)
		panel_mat.set_shader_parameter("header_height", PAD + title_h + 0.10)
		panel_mat.set_shader_parameter("footer_height", FOOTER)
		panel_mat.set_shader_parameter("dark", 1.0 if dark else 0.0)
		panel_mat.set_shader_parameter("grain", 0.4 if not dark else 0.15)
		panel_mat.set_shader_parameter("left_bar", 1.0)
		(shadow.material_override as ShaderMaterial).set_shader_parameter("rect_size", Vector2(_width + 0.24, _height + 0.24))
		(shadow.material_override as ShaderMaterial).set_shader_parameter("radius", 0.24)
		(shadow.material_override as ShaderMaterial).set_shader_parameter("opacity", 0.17)
	_rect = Rect2(-_width * 0.5, -_height * 0.5, _width, _height)


func update_lod(cam_distance: float, view_height: float) -> void:
	var screen_h := (_height / maxf(0.01, view_height)) * 900.0
	body_label.visible = screen_h > 46.0 and not _preview_body.strip_edges().is_empty()
	tags_label.visible = screen_h > 78.0
	type_icon.visible = screen_h > 95.0 and not pin_label.visible


func full_text() -> String:
	return _full_body
