class_name MediaItem
extends CanvasItem3D

const PIXEL := 0.0095
const CAPTION_H := 0.92

var panel: MeshInstance3D
var panel_mat: ShaderMaterial
var caption_label: Label3D
var badge_label: Label3D
var missing_label: Label3D
var _texture: Texture2D
var _asset := ""
var _width := 5.0
var _height := 3.4


func is_pdf() -> bool:
	return item_type == "pdf"


func _build() -> void:
	panel_mat = ShaderMaterial.new()
	panel_mat.shader = load("res://assets/shaders/media_panel.gdshader")
	panel = make_quad(Vector2(_width, _height), panel_mat, 0.01)
	caption_label = make_label("", AppFonts.body(550), 34, Color("#DCE8FA"), PIXEL, 900, VERTICAL_ALIGNMENT_TOP)
	badge_label = make_label("", AppFonts.body(650), 30, Color("#EAF4FF"), PIXEL, -1, VERTICAL_ALIGNMENT_CENTER)
	badge_label.outline_size = 5
	badge_label.outline_modulate = Color(0.02, 0.04, 0.07, 0.85)
	badge_label.position = Vector3(-2.3, 1.8, 0.03)
	missing_label = make_label("", AppFonts.display(600), 34, Color("#FF8FA3"), PIXEL, 800, VERTICAL_ALIGNMENT_CENTER)
	missing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missing_label.visible = false
	_update_visual()


func _refresh() -> void:
	_update_visual()


func _update_visual() -> void:
	var props: Dictionary = data.get("props", {})
	var asset := str(props.get("asset", ""))
	var caption := str(props.get("caption", ""))
	if caption.is_empty():
		caption = asset.get_file()
	var aspect := float(props.get("aspect", 1.5))
	_width = float(props.get("width", 5.0))
	_width = clampf(_width, 1.8, 9.0)
	_height = clampf(_width / maxf(0.2, aspect), 1.0, 8.0) + CAPTION_H
	if asset != _asset or _texture == null:
		_texture = null
		_asset = asset
		if not asset.is_empty() and FileAccess.file_exists(asset):
			var image := Image.load_from_file(asset)
			if image != null and not image.is_empty():
				image.generate_mipmaps()
				_texture = ImageTexture.create_from_image(image)
	panel.mesh.size = Vector2(_width, _height)
	panel_mat.set_shader_parameter("image_tex", _texture)
	panel_mat.set_shader_parameter("rect_size", Vector2(_width, _height))
	panel_mat.set_shader_parameter("radius", 0.18)
	panel_mat.set_shader_parameter("caption_frac", CAPTION_H / _height)
	panel_mat.set_shader_parameter("accent", Kit.ACCENT)
	panel_mat.set_shader_parameter("is_pdf", 1.0 if is_pdf() else 0.0)
	panel_mat.set_shader_parameter("dark", 1.0)
	caption_label.text = caption
	caption_label.width = int((_width - 0.5) / PIXEL)
	caption_label.position = Vector3(-_width * 0.5 + 0.28, -_height * 0.5 + CAPTION_H * 0.78, 0.02)
	var page := int(props.get("pdf_page", 0))
	var pages := int(props.get("pdf_pages", 0))
	if is_pdf() and pages > 0:
		badge_label.text = "PDF  %d/%d" % [page, pages]
	elif is_pdf():
		badge_label.text = "PDF"
	else:
		badge_label.text = "IMAGE"
	badge_label.position = Vector3(-_width * 0.5 + 0.62, _height * 0.5 - 0.28, 0.02)
	if _texture == null:
		missing_label.text = "Media not found\nRe-link this file from the inspector"
		missing_label.position = Vector3(0, CAPTION_H * 0.3, 0.03)
		missing_label.visible = true
		badge_label.visible = false
	else:
		missing_label.visible = false
		badge_label.visible = true
	_rect = Rect2(-_width * 0.5, -_height * 0.5, _width, _height)


func get_texture() -> Texture2D:
	return _texture
