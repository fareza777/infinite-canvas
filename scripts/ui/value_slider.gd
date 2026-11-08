class_name ValueSlider
extends Control

signal changed(value: float)

var title := "Value"
var min_value := 0.0
var max_value := 1.0
var step := 0.01
var value := 0.5
var suffix := ""
var decimals := 2
var accent := Kit.ACCENT
var _dragging := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 56)
	set_process(false)


func setup(p_title: String, p_min: float, p_max: float, p_step: float, p_value: float, p_suffix := "", p_decimals := 2, p_accent := Kit.ACCENT) -> ValueSlider:
	title = p_title
	min_value = p_min
	max_value = p_max
	step = p_step
	value = clampf(p_value, p_min, p_max)
	suffix = p_suffix
	decimals = p_decimals
	accent = p_accent
	queue_redraw()
	return self


func set_value(v: float, emit := false) -> void:
	var new_value := clampf(snappedf(v, step), min_value, max_value)
	if is_equal_approx(new_value, value):
		return
	value = new_value
	queue_redraw()
	if emit:
		changed.emit(value)


func _draw() -> void:
	var label_font := AppFonts.body(600)
	var value_font := AppFonts.mono(650)
	var fsize := 15
	draw_string(label_font, Vector2(0, 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Kit.MUTED)
	var text := ("%." + str(decimals) + "f") % value + suffix
	var text_size := value_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	draw_string(value_font, Vector2(size.x - text_size.x, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, accent)
	var track_y := 39.0
	var track := Rect2(0, track_y, size.x, 5.0)
	draw_rect(track, Color(Kit.TEXT.r, Kit.TEXT.g, Kit.TEXT.b, 0.10), true)
	var t := (value - min_value) / maxf(0.0001, max_value - min_value)
	var fill := Rect2(0, track_y, size.x * t, 5.0)
	draw_rect(fill, accent, true)
	var knob_x := clampf(size.x * t, 9.0, size.x - 9.0)
	draw_circle(Vector2(knob_x, track_y + 2.5), 10.0, Color(0.09, 0.13, 0.22, 0.16))
	draw_circle(Vector2(knob_x, track_y + 2.5), 9.0, Kit.SURFACE)
	draw_circle(Vector2(knob_x, track_y + 2.5), 5.5, accent)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_apply_at(event.position.x)
		else:
			_dragging = false
	elif event is InputEventScreenDrag:
		if _dragging:
			_apply_at(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_apply_at(event.position.x)
	elif event is InputEventMouseMotion and _dragging:
		_apply_at(event.position.x)


func _apply_at(x: float) -> void:
	var t := clampf(x / maxf(1.0, size.x), 0.0, 1.0)
	set_value(lerpf(min_value, max_value, t), true)
