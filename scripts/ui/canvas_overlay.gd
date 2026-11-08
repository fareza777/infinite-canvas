class_name CanvasOverlay
extends Control

var state: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_state(value: Dictionary) -> void:
	state = value
	queue_redraw()


func _draw() -> void:
	if state.is_empty():
		return
	var accent := Kit.ACCENT
	var marquee: Rect2 = state.get("marquee", Rect2())
	if marquee.size.x > 1.0 and marquee.size.y > 1.0:
		draw_rect(marquee, Color(accent.r, accent.g, accent.b, 0.08), true)
		_draw_dashed_rect(marquee, Color(accent.r, accent.g, accent.b, 0.7), 1.5, 6.0)
	var guide_color := Color(accent.r, accent.g, accent.b, 0.42)
	for x in state.get("guides_v", []):
		_draw_dashed_line(Vector2(x, 0), Vector2(x, size.y), guide_color, 1.0, 5.0)
	for y in state.get("guides_h", []):
		_draw_dashed_line(Vector2(0, y), Vector2(size.x, y), guide_color, 1.0, 5.0)
	var connector: PackedVector2Array = state.get("connector", PackedVector2Array())
	if connector.size() > 1:
		draw_polyline(connector, Color(accent.r, accent.g, accent.b, 0.18), 12.0, true)
		draw_polyline(connector, accent, 2.6, true)
	var polys: Array = state.get("polys", [])
	for poly in polys:
		if poly.size() < 3:
			continue
		var closed := PackedVector2Array(poly)
		closed.append(poly[0])
		draw_polyline(closed, Color(accent.r, accent.g, accent.b, 0.14), 7.0, true)
		draw_polyline(closed, Color(accent.r, accent.g, accent.b, 0.95), 1.8, true)
	var bounds: Rect2 = state.get("bounds", Rect2())
	var has_bounds: bool = state.get("has_bounds", false)
	if has_bounds and bounds.size.x > 2.0 and bounds.size.y > 2.0:
		_draw_dashed_rect(bounds.grow(4.0), Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.16), 1.0, 5.0)
	var handles: Array = state.get("handles", [])
	for handle in handles:
		var pos: Vector2 = handle.get("pos", Vector2.ZERO)
		var kind: String = str(handle.get("kind", ""))
		var radius := 11.0
		draw_circle(pos + Vector2(0, 3), radius + 2.0, Color(0.09, 0.13, 0.22, 0.14))
		draw_circle(pos, radius, Kit.SURFACE)
		draw_arc(pos, radius, 0.0, TAU, 28, accent, 2.2, true)
		if kind == "rotate":
			draw_circle(pos, 4.0, accent)
			_icon_at("rotate_right", pos, 14, Kit.SURFACE)
		elif kind == "scale":
			draw_circle(pos, 2.8, accent)
		elif kind == "move":
			_icon_at("open_with", pos, 15, accent)
	var rotate_pos: Vector2 = state.get("rotate_pos", Vector2(-9999, -9999))
	if has_bounds and rotate_pos.x > -9000:
		var anchor := Vector2(bounds.get_center().x, bounds.position.y)
		draw_line(anchor, rotate_pos, Color(accent.r, accent.g, accent.b, 0.45), 1.6, true)
		draw_circle(rotate_pos + Vector2(0, 3), 15.0, Color(0.09, 0.13, 0.22, 0.16))
		draw_circle(rotate_pos, 13.5, accent)
		_icon_at("rotate_right", rotate_pos, 17, Kit.SURFACE)
	var pen_cursor: Dictionary = state.get("pen_cursor", {})
	if not pen_cursor.is_empty():
		var p: Vector2 = pen_cursor.get("pos", Vector2.ZERO)
		var r: float = pen_cursor.get("radius", 8.0)
		var c: Color = pen_cursor.get("color", accent)
		draw_circle(p, r + 3.0, Color(0.09, 0.13, 0.22, 0.12))
		draw_arc(p, r, 0.0, TAU, 32, Color(c.r, c.g, c.b, 0.95), 1.8, true)
		draw_circle(p, 2.0, c)
	var eraser_cursor: Dictionary = state.get("eraser_cursor", {})
	if not eraser_cursor.is_empty():
		var ep: Vector2 = eraser_cursor.get("pos", Vector2.ZERO)
		var er: float = eraser_cursor.get("radius", 22.0)
		draw_circle(ep, er, Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.05))
		draw_arc(ep, er, 0.0, TAU, 40, Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.45), 1.5, true)
	var label: String = str(state.get("drag_label", ""))
	if not label.is_empty():
		var lp: Vector2 = state.get("label_pos", Vector2(size.x * 0.5, size.y * 0.5))
		var font := AppFonts.mono(650)
		var fsize := 15
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var pad := Vector2(12, 7)
		var rect := Rect2(lp + Vector2(18, -44), text_size + pad * 2.0)
		draw_rect(rect, Color(0.09, 0.13, 0.22, 0.10), true)
		draw_rect(rect, Kit.SURFACE, true)
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.45), false, 1.2)
		draw_string(font, rect.position + Vector2(pad.x, pad.y + fsize - 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Kit.TEXT)


func _icon_at(icon_name: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font := AppFonts.icon_font(1.0, 500.0)
	var glyph := Icons.glyph(icon_name)
	var text_size := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, pos - text_size * 0.5 + Vector2(0, text_size.y * 0.34), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float) -> void:
	var length := from.distance_to(to)
	if length < 0.001:
		return
	var dir := (to - from) / length
	var traveled := 0.0
	while traveled < length:
		var seg := minf(dash, length - traveled)
		draw_line(from + dir * traveled, from + dir * (traveled + seg), color, width, true)
		traveled += dash * 2.0


func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash: float) -> void:
	_draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), color, width, dash)
	_draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, color, width, dash)
	_draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), color, width, dash)
	_draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, color, width, dash)
