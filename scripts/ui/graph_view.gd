class_name GraphView
extends Control

signal node_pressed(item_id: String)

var nodes: Array = []
var edges: Array = []
var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedVector2Array = PackedVector2Array()
var _initialized := false
var _hover := -1
var _physics := true
var _time := 0.0
var _id_to_index := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_process(true)

func set_graph(p_nodes: Array, p_edges: Array) -> void:
	nodes = p_nodes
	edges = p_edges
	_initialized = false
	_id_to_index.clear()
	for i in range(nodes.size()):
		_id_to_index[str(nodes[i].get("id", ""))] = i
	_reset_layout()
	queue_redraw()


func _reset_layout() -> void:
	positions.resize(nodes.size())
	velocities.resize(nodes.size())
	var count := maxi(1, nodes.size())
	for i in range(nodes.size()):
		var angle := TAU * float(i) / float(count) - PI * 0.5
		var radius := minf(size.x, size.y) * 0.33
		positions[i] = size * 0.5 + Vector2(cos(angle), sin(angle)) * radius
		velocities[i] = Vector2.ZERO
	_initialized = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and nodes.size() > 0:
		_reset_layout()


func _process(delta: float) -> void:
	if not _initialized or nodes.is_empty():
		return
	_time += delta
	if not _physics:
		queue_redraw()
		return
	var count := nodes.size()
	var forces := []
	forces.resize(count)
	for i in range(count):
		forces[i] = Vector2.ZERO
	var ideal := clampf(sqrt(size.x * size.y / float(maxi(1, count))) * 0.62, 62.0, 132.0)
	for i in range(count):
		for j in range(i + 1, count):
			var delta_v: Vector2 = positions[i] - positions[j]
			var dist := maxf(24.0, delta_v.length())
			var repulse := (ideal * ideal / dist) * 0.65
			var dir := delta_v.normalized() if delta_v.length_squared() > 0.001 else Vector2.RIGHT
			forces[i] += dir * repulse
			forces[j] -= dir * repulse
	for edge in edges:
		var a := int(_id_to_index.get(str(edge.get("from", "")), -1))
		var b := int(_id_to_index.get(str(edge.get("to", "")), -1))
		if a < 0 or b < 0:
			continue
		var delta_v: Vector2 = positions[b] - positions[a]
		var dist := maxf(0.1, delta_v.length())
		var attraction := (dist - ideal) * 0.016
		var dir := delta_v / dist
		forces[a] += dir * attraction
		forces[b] -= dir * attraction
	for i in range(count):
		var center := size * 0.5
		var to_center := center - positions[i]
		forces[i] += to_center * 0.004
		velocities[i] = (velocities[i] + forces[i] * delta * 18.0) * 0.72
		positions[i] += velocities[i] * delta * 2.8
		positions[i] = Vector2(
			clampf(positions[i].x, 36.0, size.x - 36.0),
			clampf(positions[i].y, 42.0, size.y - 62.0)
		)
	queue_redraw()


func _draw() -> void:
	var font := AppFonts.body(600)
	draw_rect(Rect2(Vector2.ZERO, size), Kit.SURFACE_2, true)
	for gx in range(18, int(size.x), 32):
		for gy in range(18, int(size.y), 32):
			draw_circle(Vector2(gx, gy), 1.2, Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.07))
	if nodes.is_empty():
		draw_string(font, Vector2(18, 34), "Add notes or frames to grow the graph", HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 16, Kit.MUTED)
		return
	if not _initialized:
		_reset_layout()
	for edge in edges:
		var a := int(_id_to_index.get(str(edge.get("from", "")), -1))
		var b := int(_id_to_index.get(str(edge.get("to", "")), -1))
		if a < 0 or b < 0:
			continue
		var color := Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.18)
		draw_line(positions[a], positions[b], color, 1.4, true)
		var mid := (positions[a] + positions[b]) * 0.5
		draw_circle(mid, 2.0, Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.28))
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var accent := Color.from_string(str(node.get("color", "#2F5BFF")), Kit.ACCENT)
		var radius := 19.0 if str(node.get("type", "")) != "frame" else 23.0
		var pos := positions[i]
		draw_circle(pos + Vector2(0, 3), radius + 6.0, Color(0.09, 0.13, 0.22, 0.12))
		draw_circle(pos, radius + 5.0, Color(accent.r, accent.g, accent.b, 0.12))
		draw_circle(pos, radius, Kit.SURFACE)
		draw_arc(pos, radius, 0.0, TAU, 36, Color(accent.r, accent.g, accent.b, 0.90), 2.0, true)
		var glyph := Icons.glyph("sticky_note_2")
		if str(node.get("type", "")) == "frame":
			glyph = Icons.glyph("movie")
		elif str(node.get("type", "")) == "primitive" or str(node.get("type", "")) == "model":
			glyph = Icons.glyph("view_in_ar")
		var icon_font := AppFonts.icon_font(0.0, 450.0)
		var icon_size := 19
		var text_size := icon_font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, icon_size)
		draw_string(icon_font, pos - text_size * 0.5 + Vector2(0, text_size.y * 0.34), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, icon_size, accent)
		var label := str(node.get("label", "Untitled"))
		if label.length() > 22:
			label = label.substr(0, 21) + "…"
		var label_y := pos.y + radius + 21.0
		var label_px := 14
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_px)
		var half_label := label_size.x * 0.5 + 10.0
		var label_x := clampf(pos.x, half_label, maxf(half_label, size.x - half_label))
		draw_rect(Rect2(label_x - label_size.x * 0.5 - 8.0, label_y - 14.0, label_size.x + 16.0, 22.0), Color(Kit.SURFACE.r, Kit.SURFACE.g, Kit.SURFACE.b, 0.96), true)
		draw_rect(Rect2(label_x - label_size.x * 0.5 - 8.0, label_y - 14.0, label_size.x + 16.0, 22.0), Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.10), false, 1.0)
		draw_string(font, Vector2(label_x - label_size.x * 0.5, label_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_px, Kit.TEXT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_pick(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick(event.position)


func _pick(at: Vector2) -> void:
	var best := -1
	var best_dist := 34.0
	for i in range(positions.size()):
		var d := positions[i].distance_to(at)
		if d < best_dist:
			best_dist = d
			best = i
	if best >= 0:
		node_pressed.emit(str(nodes[best].get("id", "")))
