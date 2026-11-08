class_name Panels
extends RefCounted

var ui: GameUI
var app: Node


func _init(p_ui: GameUI, p_app: Node) -> void:
	ui = p_ui
	app = p_app


func build(kind: String, ctx: Dictionary) -> Control:
	match kind:
		"create":
			return _create()
		"primitive":
			return _primitive()
		"layers":
			return _layers()
		"templates":
			return _templates()
		"smart":
			return _smart()
		"graph":
			return _graph()
		"timeline":
			return _timeline()
		"projects":
			return _projects()
		"export":
			return _export()
		"more":
			return _more()
		"nav":
			return _nav()
		"look":
			return _look()
		"help":
			return _help()
		"about":
			return _about()
		"inspector":
			return _inspector()
		"layer_options":
			return _layer_options(str(ctx.get("layer", "")))
		"settings":
			return SettingsPanel.new(ui, app).build()
		"restore_points":
			return SettingsPanel.new(ui, app).build_restore_points()
		_:
			return _root_with([_empty("No content", "This panel is not available.")])


func _plural(count: int, word: String, plural_word := "") -> String:
	return "%d %s" % [count, word if count == 1 else (plural_word if not plural_word.is_empty() else word + "s")]


func _root() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box


func _root_with(children: Array) -> VBoxContainer:
	var box := _root()
	for c in children:
		if c is Control:
			box.add_child(c)
	return box


func _section(text: String) -> Label:
	var l := Kit.label(text.to_upper(), 12, Kit.MUTED, 650, "mono")
	l.add_theme_color_override("font_color", Kit.MUTED)
	return l


func _empty(title: String, subtitle: String, icon := "auto_awesome") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 44)
	box.add_child(holder)
	var ic := Kit.icon(icon, 30, Kit.ACCENT, 1.0)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ic)
	var t := Kit.display_label(title, 20, Kit.TEXT, 650)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var s := Kit.wrapped(subtitle, 13, Kit.MUTED, 450)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(s)
	return box


func _icon_tile(icon_name: String, color: Color, dim := 34, icon_size := 19, fill := 1.0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(dim, dim)
	panel.add_theme_stylebox_override("panel", Kit.style(Color(color.r, color.g, color.b, 0.13), 11, Color(color.r, color.g, color.b, 0.30), 1, 0))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Kit.icon(icon_name, icon_size, color, fill)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(ic)
	return panel


func _card(icon_name: String, title: String, subtitle: String, callback: Callable, badge := "", accent := Kit.ACCENT, height := 150.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Kit.style(Kit.SURFACE_2, 16, Kit.STROKE, 1, 0))
	b.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 16, Color(accent.r, accent.g, accent.b, 0.35), 1))
	b.add_theme_stylebox_override("pressed", Kit.style(Kit.SURFACE, 16, Color(accent.r, accent.g, accent.b, 0.55), 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(callback)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	b.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_icon_tile(icon_name, accent, 38, 22))
	col.add_child(top)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	if not badge.is_empty():
		var chip := Kit.badge(badge, Kit.GOLD)
		top.add_child(chip)
	var t := Kit.label(title, 18, Kit.TEXT, 650)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	col.add_child(t)
	var s := Kit.wrapped(subtitle, 14, Kit.MUTED, 450)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.max_lines_visible = 3
	col.add_child(s)
	return b


func _row(icon_name: String, title: String, subtitle: String, callback: Callable, right_text := "", accent := Kit.ACCENT, height := 86.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Kit.style(Kit.SURFACE_2, 15, Kit.STROKE, 1, 0))
	b.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 15, Color(accent.r, accent.g, accent.b, 0.3), 1))
	b.add_theme_stylebox_override("pressed", Kit.style(Kit.SURFACE, 15, Color(accent.r, accent.g, accent.b, 0.5), 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(callback)
	b.add_child(_row_content(icon_name, title, subtitle, right_text, accent, true))
	return b


func _info_row(icon_name: String, title: String, subtitle: String, accent := Kit.ACCENT, height := 92.0) -> PanelContainer:
	var panel := Kit.panel(Kit.SURFACE, 15, Kit.HOVER, 1, 0)
	panel.custom_minimum_size = Vector2(0, height)
	var content := _row_content(icon_name, title, subtitle, "", accent, false, 3)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(content)
	return panel


func _row_content(icon_name: String, title: String, subtitle: String, right_text: String, accent: Color, chevron: bool, max_lines := 2) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(_icon_tile(icon_name, accent, 38, 22))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 1)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var t := Kit.label(title, 18, Kit.TEXT, 650)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	texts.add_child(t)
	if not subtitle.is_empty():
		var s := Kit.wrapped(subtitle, 14, Kit.MUTED, 450)
		s.max_lines_visible = max_lines
		texts.add_child(s)
	if not right_text.is_empty():
		var rt := Kit.label(right_text, 13, accent, 650, "mono")
		row.add_child(rt)
	if chevron:
		row.add_child(Kit.icon("chevron_right", 21, Kit.DIM, 0.0))
	return margin


func _grid(columns := 2) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


func _field_line(title: String, value: String, placeholder: String, on_change: Callable, multiline := false, height := 0) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.add_child(Kit.label(title, 13, Kit.MUTED, 650))
	if multiline:
		var te := TextEdit.new()
		te.text = value
		te.placeholder_text = placeholder
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.custom_minimum_size = Vector2(0, height if height > 0 else 120)
		te.add_theme_font_size_override("font_size", 18)
		te.text_changed.connect(func(): on_change.call(te.text))
		box.add_child(te)
	else:
		var le := LineEdit.new()
		le.text = value
		le.placeholder_text = placeholder
		le.custom_minimum_size = Vector2(0, 50)
		le.add_theme_font_size_override("font_size", 18)
		le.text_changed.connect(func(text): on_change.call(text))
		box.add_child(le)
	return box


func _toggle_row(title: String, active: bool, callback: Callable, icon_name := "") -> PanelContainer:
	var panel := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	if not icon_name.is_empty():
		row.add_child(Kit.icon(icon_name, 19, Kit.MUTED, 0.0))
	var lab := Kit.label(title, 13, Kit.TEXT, 500)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var state := {"on": active}
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(58, 30)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var apply_style := func():
		var on: bool = state["on"]
		btn.text = "ON" if on else "OFF"
		btn.add_theme_font_override("font", AppFonts.mono(700))
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Kit.ACCENT if on else Kit.DIM)
		btn.add_theme_stylebox_override("normal", Kit.style(Color(0.184, 0.357, 1.0, 0.14 if on else 0.04), 9, Color(0.184, 0.357, 1.0, 0.4 if on else 0.08), 1))
		btn.add_theme_stylebox_override("hover", Kit.style(Kit.STROKE, 9))
		btn.add_theme_stylebox_override("pressed", Kit.style(Kit.STROKE_STRONG, 9))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	apply_style.call()
	btn.pressed.connect(func():
		state["on"] = not bool(state["on"])
		apply_style.call()
		callback.call(bool(state["on"]))
	)
	row.add_child(btn)
	return panel


func _swatches(colors: Array, selected: String, on_pick: Callable, size := 34) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var buttons := []
	for entry in colors:
		var hex: String = entry if entry is String else str(entry)
		var color := Color.from_string(hex, Kit.ACCENT)
		var b := Button.new()
		b.custom_minimum_size = Vector2(size, size)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var style_on := Kit.style(color, 999, Color.WHITE, 2)
		var style_off := Kit.style(color, 999, Kit.STROKE_STRONG, 1)
		b.add_theme_stylebox_override("normal", style_on if hex.to_upper() == selected.to_upper() else style_off)
		b.add_theme_stylebox_override("hover", style_on)
		b.add_theme_stylebox_override("pressed", style_on)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var check := Kit.icon("check", 17, Color("#07101C") if color.get_luminance() > 0.45 else Color("#F0F5FF"), 1.0)
		check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		check.visible = hex.to_upper() == selected.to_upper()
		b.add_child(check)
		b.pressed.connect(func(): on_pick.call(hex))
		row.add_child(b)
		buttons.append({"button": b, "check": check, "hex": hex, "on": style_on, "off": style_off})
	return row


func _slider(title: String, min_value: float, max_value: float, step: float, value: float, suffix: String, decimals: int, callback: Callable) -> ValueSlider:
	var slider := ValueSlider.new()
	slider.setup(title, min_value, max_value, step, value, suffix, decimals, Kit.ACCENT)
	slider.changed.connect(callback)
	return slider


func _button_row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for b in buttons:
		var btn: Control = b
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)
	return row


# ---------------------------------------------------------------- create

func _create() -> Control:
	var root := _root()
	var grid := _grid(2)
	root.add_child(grid)
	grid.add_child(_card("sticky_note_2", "Note", "A spatial card for an idea", func(): app.create_at_center("note"); ui.close_sheet()))
	grid.add_child(_card("text_fields", "Text", "Clean type on the canvas", func(): app.create_at_center("text"); ui.close_sheet()))
	grid.add_child(_card("image", "Image", "Embed a photo or artwork", func(): app.import_media("image"), "", Kit.GREEN))
	grid.add_child(_card("picture_as_pdf", "PDF", "Rasterise pages into the board", func(): app.import_media("pdf"), "", Kit.DANGER))
	grid.add_child(_card("movie", "Frame", "Add a storyboard shot", func(): app.create_at_center("frame"); ui.close_sheet(), "", Kit.GOLD))
	grid.add_child(_card("category", "Shape", "Geometry with fill and border", func(): app.create_at_center("shape"); ui.close_sheet(), "", Kit.VIOLET))
	grid.add_child(_card("view_in_ar", "3D object", "Box, sphere, cone, torus", func(): ui.open_sheet("primitive"), "", Kit.ACCENT))
	grid.add_child(_card("3d_rotation", "3D model", "Import GLB or glTF", func(): app.import_media("model"), "", Kit.VIOLET))
	var tip := Kit.wrapped("Tip: double-tap any note to edit. Two fingers pan and zoom. In 3D, drag empty space to orbit.", 14, Kit.MUTED, 450)
	root.add_child(tip)
	return root


func _primitive() -> Control:
	var root := _root()
	root.add_child(Kit.wrapped("Objects are placed just in front of the canvas. Switch to 3D to walk around them.", 12, Kit.MUTED, 450))
	var grid := _grid(2)
	root.add_child(grid)
	var defs := [
		["box", "Box", "view_in_ar"],
		["sphere", "Sphere", "circle"],
		["cylinder", "Cylinder", "grid_4x4"],
		["cone", "Cone", "change_history"],
		["torus", "Torus", "blur_circular"],
		["plane", "Plane", "crop_free"],
	]
	for d in defs:
		var shape: String = d[0]
		grid.add_child(_card(d[2], d[1], "Add a %s to the scene" % d[1].to_lower(), func(): app.add_primitive(shape); ui.close_sheet(), "", Kit.ACCENT, 130))
	var import_row := _row("upload_file", "Import a 3D model", "GLB or glTF · real meshes and materials", func(): app.import_media("model"), "", Kit.VIOLET)
	root.add_child(import_row)
	return root


# ---------------------------------------------------------------- layers

func _layers() -> Control:
	var root := _root()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	var info := Kit.label("%s · %s" % [_plural(app.project.layers.size(), "layer"), _plural(app.project.items.size(), "object")], 13, Kit.MUTED, 500)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var add := Kit.button("Add layer", "add", false, 44, 19)
	add.custom_minimum_size.x = 128
	add.pressed.connect(func(): app.add_layer(); ui.reload_sheet())
	top.add_child(add)
	for layer in app.project.layers:
		var layer_id := str(layer.get("id", ""))
		var color := Color.from_string(str(layer.get("color", "#2F5BFF")), Kit.ACCENT)
		var active: bool = layer_id == app.project.active_layer_id
		var panel := Kit.panel(Color(0.184, 0.357, 1.0, 0.07) if active else Kit.SURFACE, 14, Color(0.184, 0.357, 1.0, 0.4) if active else Kit.HOVER, 1, 8)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		panel.add_child(row)
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(22, 22)
		dot.add_theme_stylebox_override("panel", Kit.style(color, 999))
		row.add_child(dot)
		var name_btn := Button.new()
		name_btn.text = str(layer.get("name", "Layer"))
		name_btn.flat = true
		name_btn.focus_mode = Control.FOCUS_NONE
		name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_btn.add_theme_font_override("font", AppFonts.body(550))
		name_btn.add_theme_font_size_override("font_size", 14)
		name_btn.add_theme_color_override("font_color", Kit.TEXT)
		name_btn.add_theme_color_override("font_hover_color", Kit.ACCENT)
		name_btn.pressed.connect(func(): app.set_active_layer(layer_id); ui.reload_sheet())
		row.add_child(name_btn)
		var count := Kit.label(str(app.project.items_in_layer(layer_id).size()), 12, Kit.DIM, 600, "mono")
		row.add_child(count)
		var eye := Kit.icon_button("visibility" if layer.get("visible", true) else "visibility_off", 30, 17, false)
		eye.tooltip_text = "Show / hide layer"
		var eye_glyph: Label = eye.get_meta("glyph")
		eye_glyph.add_theme_color_override("font_color", Kit.MUTED if layer.get("visible", true) else Kit.DIM)
		eye.pressed.connect(func(): app.toggle_layer_visible(layer_id); ui.reload_sheet())
		row.add_child(eye)
		var lock := Kit.icon_button("lock_open" if not layer.get("locked", false) else "lock", 30, 17, false)
		lock.tooltip_text = "Lock / unlock layer"
		lock.pressed.connect(func(): app.toggle_layer_locked(layer_id); ui.reload_sheet())
		row.add_child(lock)
		var more := Kit.icon_button("more_vert", 30, 17, false)
		more.pressed.connect(func(): ui.open_sheet("layer_options", {"layer": layer_id}))
		row.add_child(more)
		root.add_child(panel)
	var hint := Kit.wrapped("Tap a layer name to make it active. New objects are created on the active layer. Locked layers cannot be selected on the canvas.", 12, Kit.MUTED, 450)
	root.add_child(hint)
	root.add_child(Kit.divider())
	root.add_child(_section("Hierarchy"))
	var count_rows := 0
	for item in app.project.items:
		if not str(item.get("parent", "")).is_empty():
			continue
		if str(item.get("type", "")) == "stroke":
			continue
		if count_rows >= 40:
			break
		count_rows += _add_hierarchy_row(root, item, 0, count_rows)
	if count_rows == 0:
		root.add_child(Kit.wrapped("Notes, frames and groups will appear here as the board grows.", 13, Kit.DIM, 450))
	return root


func _add_hierarchy_row(root: VBoxContainer, item: Dictionary, depth: int, count_rows: int) -> int:
	if count_rows >= 40:
		return 0
	var item_id := str(item.get("id", ""))
	var type := str(item.get("type", ""))
	var layer: Dictionary = app.project.get_layer(str(item.get("layer", "")))
	var color := Color.from_string(str(layer.get("color", "#2F5BFF")), Kit.ACCENT)
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 46)
	row.focus_mode = Control.FOCUS_NONE
	row.add_theme_stylebox_override("normal", Kit.style(Kit.SURFACE, 10, Kit.HOVER, 1, 0))
	row.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 10, Kit.STROKE_STRONG, 1, 0))
	row.add_theme_stylebox_override("pressed", Kit.style(Kit.STROKE, 10))
	row.pressed.connect(func():
		app.select_ids([item_id])
		ui.close_sheet()
		app.focus_item(item_id)
	)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8 + depth * 16)
	margin.add_theme_constant_override("margin_right", 8)
	row.add_child(margin)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(h)
	h.add_child(Kit.icon(_icon_for_type(type), 17, color, 0.0))
	var label_text := _item_label(item)
	if type == "group":
		label_text += "  ·  %d" % app.project.children_of(item_id).size()
	var l := Kit.label(label_text, 14, Kit.TEXT, 500)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(Kit.label(type.to_upper(), 12, Kit.DIM, 600, "mono"))
	root.add_child(row)
	var used := 1
	if type == "group":
		for child in app.project.children_of(item_id):
			if used >= 40:
				break
			used += _add_hierarchy_row(root, child, depth + 1, count_rows + used)
	return used


func _icon_for_type(type: String) -> String:
	match type:
		"note", "text":
			return "sticky_note_2"
		"frame":
			return "movie"
		"image":
			return "image"
		"pdf":
			return "picture_as_pdf"
		"model", "primitive":
			return "view_in_ar"
		"shape":
			return "category"
		"group":
			return "group_work"
		_:
			return "category"


func _item_label(item: Dictionary) -> String:
	var props: Dictionary = item.get("props", {})
	var title := str(props.get("title", "")).strip_edges()
	if title.is_empty():
		title = str(props.get("caption", "")).strip_edges()
	if title.is_empty():
		title = str(item.get("type", "Object")).capitalize()
	return title


func _layer_options(layer_id: String) -> Control:
	var root := _root()
	var layer: Dictionary = app.project.get_layer(layer_id)
	if layer.is_empty():
		return _root_with([_empty("Layer missing", "This layer no longer exists.")])
	var title := Kit.label(str(layer.get("name", "Layer")), 19, Kit.TEXT, 650, "display")
	root.add_child(title)
	root.add_child(_field_line("Name", str(layer.get("name", "")), "Layer name", func(text):
		if not text.strip_edges().is_empty():
			app.rename_layer(layer_id, text)
	))
	root.add_child(_section("Colour"))
	root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#F0F5FF"], str(layer.get("color", "#2F5BFF")), func(hex): app.set_layer_color(layer_id, hex)))
	root.add_child(_section("Order"))
	var order_row := _button_row([
		_make_btn("Move up", "arrow_upward", func(): app.move_layer(layer_id, -1); ui.open_sheet("layers")),
		_make_btn("Move down", "arrow_downward", func(): app.move_layer(layer_id, 1); ui.open_sheet("layers")),
	])
	root.add_child(order_row)
	root.add_child(Kit.divider())
	var del := Kit.button("Delete this layer", "delete", false, 44)
	del.add_theme_color_override("font_color", Kit.DANGER)
	del.pressed.connect(func():
		ui.confirm("Delete layer?", "Objects on this layer will move to the first remaining layer. This can be undone.", func():
			app.delete_layer(layer_id)
			ui.open_sheet("layers")
		, "Delete", true)
	)
	root.add_child(del)
	root.add_child(_toggle_row("Visible", bool(layer.get("visible", true)), func(on): app.toggle_layer_visible(layer_id), "visibility"))
	root.add_child(_toggle_row("Locked", bool(layer.get("locked", false)), func(on): app.toggle_layer_locked(layer_id), "lock"))
	return root


func _make_btn(text: String, icon_name: String, callback: Callable, primary := false) -> Button:
	var b := Kit.button(text, icon_name, primary, 42, 18)
	b.pressed.connect(callback)
	return b


# ---------------------------------------------------------------- templates

func _templates() -> Control:
	var root := _root()
	var intro := Kit.wrapped("Every template creates real, editable notes, links, frames and 3D objects at your current view.", 14, Kit.MUTED, 450)
	root.add_child(intro)
	var grid := _grid(2)
	root.add_child(grid)
	for t in app.get_templates():
		var id := str(t.get("id", ""))
		var accent := Color.from_string(str(t.get("accent", "#2F5BFF")), Kit.ACCENT)
		grid.add_child(_card(str(t.get("icon", "dashboard_customize")), str(t.get("title", "Template")), str(t.get("subtitle", "")), func():
			app.apply_template(id)
			ui.close_sheet()
		, "", accent, 170))
	return root


# ---------------------------------------------------------------- smart

func _smart() -> Control:
	var root := _root()
	var badge := HBoxContainer.new()
	badge.add_theme_constant_override("separation", 6)
	badge.add_child(Kit.chip("ON-DEVICE", Kit.GREEN, 12))
	badge.add_child(Kit.chip("PRIVATE", Kit.VIOLET, 12))
	root.add_child(badge)
	var stats: Dictionary = app.get_stats()
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 6)
	for pair in [["notes", "Note"], ["connectors", "Link"], ["frames", "Frame"]]:
		var count_value := int(stats.get(pair[0], 0))
		var word: String = pair[1] if count_value == 1 else pair[1] + "s"
		var chip := Kit.chip("%d %s" % [count_value, word], Kit.ACCENT, 13)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_row.add_child(chip)
	root.add_child(stat_row)
	root.add_child(_row("auto_fix_high", "Auto-connect ideas", "Find shared concepts and draw smart links", func(): app.smart_action("connect"); ui.close_sheet(), "", Kit.ACCENT))
	root.add_child(_row("account_tree", "Cluster & arrange", "Group related notes into spatial clusters", func(): app.smart_action("cluster"); ui.close_sheet(), "", Kit.VIOLET))
	root.add_child(_row("cleaning_services", "Tidy the board", "Align notes to a calm, readable grid", func(): app.smart_action("tidy"); ui.close_sheet(), "", Kit.GREEN))
	root.add_child(_row("summarize", "Summarize the board", "Extract the strongest sentences into a note", func(): app.smart_action("summarize"); ui.close_sheet(), "", Kit.GOLD))
	root.add_child(_row("insights", "Suggest next steps", "A practical checklist based on the board", func(): app.smart_action("next"); ui.close_sheet(), "", Kit.ACCENT))
	var keywords: Array = app.get_top_keywords()
	if not keywords.is_empty():
		root.add_child(_section("Themes on this board"))
		var flow := GridContainer.new()
		flow.columns = 3
		flow.add_theme_constant_override("h_separation", 5)
		flow.add_theme_constant_override("v_separation", 5)
		root.add_child(flow)
		for kw in keywords:
			var word := str(kw.get("word", ""))
			if word.is_empty():
				continue
			var chip_btn := Button.new()
			chip_btn.text = "%s · %d" % [word, int(kw.get("count", 0))]
			chip_btn.focus_mode = Control.FOCUS_NONE
			chip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip_btn.custom_minimum_size = Vector2(0, 38)
			chip_btn.add_theme_font_override("font", AppFonts.body(550))
			chip_btn.add_theme_font_size_override("font_size", 13)
			chip_btn.add_theme_color_override("font_color", Kit.TEXT)
			chip_btn.add_theme_stylebox_override("normal", Kit.style(Kit.HOVER, 999, Kit.PRESSED, 1))
			chip_btn.add_theme_stylebox_override("hover", Kit.style(Color(0.184, 0.357, 1.0, 0.12), 999, Color(0.184, 0.357, 1.0, 0.4), 1))
			chip_btn.add_theme_stylebox_override("pressed", Kit.style(Kit.PRESSED, 999))
			chip_btn.pressed.connect(func(): app.select_keyword(word); ui.close_sheet())
			flow.add_child(chip_btn)
	var note := Kit.wrapped("Smart Studio analyses your own text locally — no uploads, no account, no network.", 13, Kit.DIM, 450)
	root.add_child(note)
	return root


# ---------------------------------------------------------------- graph

func _graph() -> Control:
	var root := _root()
	var data: Dictionary = app.get_graph_data()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Kit.style(Kit.SURFACE, 16, Kit.STROKE, 1, 0))
	panel.custom_minimum_size = Vector2(0, 300)
	root.add_child(panel)
	var graph := GraphView.new()
	graph.custom_minimum_size = Vector2(0, 300)
	panel.add_child(graph)
	graph.set_graph(data.get("nodes", []), data.get("edges", []))
	graph.node_pressed.connect(func(id):
		app.select_ids([id])
		app.focus_item(id)
		ui.close_sheet()
	)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	stats.add_child(Kit.chip("%d nodes" % int(data.get("nodes", []).size()), Kit.ACCENT, 12))
	stats.add_child(Kit.chip("%d links" % int(data.get("edges", []).size()), Kit.VIOLET, 12))
	root.add_child(stats)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 8)
	legend.add_theme_constant_override("v_separation", 4)
	root.add_child(legend)
	for layer in app.project.layers:
		var color := Color.from_string(str(layer.get("color", "#2F5BFF")), Kit.ACCENT)
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		var dot := Kit.icon("circle", 10, color, 1.0)
		item.add_child(dot)
		item.add_child(Kit.label(str(layer.get("name", "Layer")), 12, Kit.MUTED, 500))
		legend.add_child(item)
	root.add_child(Kit.wrapped("Tap a node to select it and fly the camera to that idea.", 13, Kit.MUTED, 450))
	return root


# ---------------------------------------------------------------- timeline

func _timeline() -> Control:
	var root := _root()
	var frames: Array = app.project.frames()
	var current := int(app.project.storyboard.get("current", 0))
	if frames.is_empty():
		root.add_child(_empty("No frames yet", "Create your first storyboard frame, then sequence the story.", "movie"))
		var add := Kit.button("Create first frame", "add", true, 48, 20)
		add.pressed.connect(func(): app.add_frame(); ui.reload_sheet())
		root.add_child(add)
		var tpl := Kit.button("Use the storyboard template", "dashboard_customize", false, 46, 19)
		tpl.pressed.connect(func(): app.apply_template("storyboard"); ui.close_sheet())
		root.add_child(tpl)
		return root
	var strip := ScrollContainer.new()
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size = Vector2(0, 104)
	root.add_child(strip)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	strip.add_child(hbox)
	for i in range(frames.size()):
		var frame: Dictionary = frames[i]
		var props: Dictionary = frame.get("props", {})
		var active := i == current
		var card := Button.new()
		card.custom_minimum_size = Vector2(122, 92)
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_stylebox_override("normal", Kit.style(Color(0.184, 0.357, 1.0, 0.11) if active else Kit.SURFACE_2, 13, Color(0.184, 0.357, 1.0, 0.5) if active else Kit.STROKE, 1))
		card.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 13))
		card.add_theme_stylebox_override("pressed", Kit.style(Kit.PRESSED, 13))
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		card.pressed.connect(func():
			app.go_to_frame(i)
			ui.reload_sheet()
		)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 9
		box.offset_right = -8
		box.offset_top = 7
		box.offset_bottom = -6
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 1)
		card.add_child(box)
		var num := Kit.label("%02d" % int(props.get("order", i + 1)), 20, Kit.ACCENT if active else Kit.MUTED, 700, "mono")
		box.add_child(num)
		var t := Kit.label(str(props.get("title", "Frame")), 14, Kit.TEXT, 550)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		t.clip_text = true
		box.add_child(t)
		var dur := Kit.label("%ss · %s" % [str(props.get("duration", 3)), str(props.get("status", "Draft"))], 12, Kit.DIM, 500, "mono")
		box.add_child(dur)
		hbox.add_child(card)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	root.add_child(controls)
	var prev := Kit.icon_button("skip_previous", 38, 19)
	prev.pressed.connect(func(): app.step_frame(-1); ui.reload_sheet())
	controls.add_child(prev)
	var play := Kit.icon_button("stop_circle" if app.storyboard_playing else "play_circle", 46, 25, app.storyboard_playing)
	play.pressed.connect(func():
		app.toggle_presentation()
		if app.storyboard_playing:
			ui.close_sheet()
		else:
			ui.reload_sheet()
	)
	controls.add_child(play)
	var next := Kit.icon_button("skip_next", 38, 19)
	next.pressed.connect(func(): app.step_frame(1); ui.reload_sheet())
	controls.add_child(next)
	var add_btn := Kit.icon_button("add", 38, 19)
	add_btn.pressed.connect(func(): app.add_frame(); ui.reload_sheet())
	controls.add_child(add_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	var progress := Kit.label("%d / %d" % [current + 1, frames.size()], 12, Kit.MUTED, 600, "mono")
	controls.add_child(progress)
	var frame: Dictionary = frames[clampi(current, 0, frames.size() - 1)]
	var props2: Dictionary = frame.get("props", {})
	var detail := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
	root.add_child(detail)
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 6)
	detail.add_child(dbox)
	dbox.add_child(Kit.label("SHOT %02d" % int(props2.get("order", 1)), 12, Kit.ACCENT, 650, "mono"))
	dbox.add_child(Kit.display_label(str(props2.get("title", "Frame")), 18, Kit.TEXT, 650))
	var desc := str(props2.get("body", ""))
	if not desc.is_empty():
		var desc_label := Kit.wrapped(desc, 14, Kit.MUTED, 450)
		desc_label.max_lines_visible = 3
		dbox.add_child(desc_label)
	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 6)
	meta_row.add_child(Kit.chip("%ss" % str(props2.get("duration", 3)), Kit.GOLD, 12))
	meta_row.add_child(Kit.chip(str(props2.get("status", "Draft")), Kit.VIOLET, 12))
	dbox.add_child(meta_row)
	var edit := Kit.button("Edit this frame", "edit", true, 40, 18)
	edit.pressed.connect(func(): app.select_ids([frame.get("id", "")]); ui.open_sheet("inspector"))
	dbox.add_child(edit)
	var reorder := HBoxContainer.new()
	reorder.add_theme_constant_override("separation", 6)
	reorder.add_child(_make_btn("Move earlier", "arrow_back", func(): app.reorder_frame(-1); ui.reload_sheet()))
	reorder.add_child(_make_btn("Move later", "arrow_forward", func(): app.reorder_frame(1); ui.reload_sheet()))
	root.add_child(reorder)
	var present := Kit.button("Present from here", "play_arrow", false, 44, 18)
	present.pressed.connect(func(): app.present_from(current); ui.close_sheet())
	root.add_child(present)
	return root


# ---------------------------------------------------------------- pro

func _pro() -> Control:
	var root := _root()
	var hero := PanelContainer.new()
	hero.custom_minimum_size = Vector2(0, 116)
	hero.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(hero)
	var gradient := Kit.gradient(Kit.ACCENT, Kit.VIOLET, 18.0, 0.8)
	gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero.add_child(gradient)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	hero.add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 2)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(Kit.label("ULTIMATE", 10, Kit.ACCENT, 700, "mono"))
	text_box.add_child(Kit.display_label("Pro membership", 22, Kit.TEXT, 700))
	var hero_sub := Kit.wrapped("More boards, premium templates and richer atmospheres. One purchase, no ads, ever.", 11, Color(0.85, 0.9, 1, 0.8), 450)
	hero_sub.max_lines_visible = 3
	text_box.add_child(hero_sub)
	row.add_child(Kit.icon("diamond", 34, Kit.GOLD, 1.0))
	if app.is_premium():
		var active := Kit.panel(Color(0.184, 0.357, 1.0, 0.08), 14, Color(0.184, 0.357, 1.0, 0.35), 1, 12)
		var arow := HBoxContainer.new()
		arow.add_theme_constant_override("separation", 8)
		active.add_child(arow)
		arow.add_child(Kit.icon("verified", 20, Kit.GREEN, 1.0))
		var active_label := Kit.label("Pro is active on this account", 13, Kit.TEXT, 550)
		active_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arow.add_child(active_label)
		root.add_child(active)
	else:
		root.add_child(_section("Included in Pro"))
		for f in [
			"Unlimited boards (Free includes %d)" % app.get_free_limit(),
			"Pitch deck and research-wall templates",
			"Warm and Neon canvas atmospheres",
			"Gold and Rose canvas accents",
		]:
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 8)
			row2.add_child(Kit.icon("check_circle", 17, Kit.GREEN, 1.0))
			var l := Kit.wrapped(f, 12, Kit.TEXT, 450)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.add_child(l)
			root.add_child(row2)
		root.add_child(_section("Choose a plan"))
		var products: Array = app.get_products()
		if products.is_empty():
			var warn := Kit.panel(Color(0.72, 0.47, 0.06, 0.07), 14, Color(0.72, 0.47, 0.06, 0.25), 1, 12)
			var wbox := VBoxContainer.new()
			wbox.add_theme_constant_override("separation", 6)
			warn.add_child(wbox)
			wbox.add_child(Kit.wrapped(app.get_billing_message(), 12, Kit.GOLD, 550))
			var retry := Kit.button("Retry connection", "refresh", false, 38, 17)
			retry.pressed.connect(func(): app.retry_billing(); ui.toast("Reconnecting to Google Play…", "sync", Kit.ACCENT); ui.reload_sheet())
			wbox.add_child(retry)
			root.add_child(warn)
		else:
			for product in products:
				var p := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
				var prow := HBoxContainer.new()
				prow.add_theme_constant_override("separation", 8)
				p.add_child(prow)
				var ptext := VBoxContainer.new()
				ptext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				ptext.add_theme_constant_override("separation", 1)
				prow.add_child(ptext)
				ptext.add_child(Kit.label(str(product.get("title", "Pro")), 14, Kit.TEXT, 600))
				ptext.add_child(Kit.label(str(product.get("description", "")), 10, Kit.MUTED, 450))
				var price := Kit.label(str(product.get("price", "")), 15, Kit.ACCENT, 700, "mono")
				prow.add_child(price)
				var buy := Kit.button("Unlock", "diamond", true, 38, 17)
				buy.custom_minimum_size.x = 94
				if not bool(product.get("available", true)):
					buy.disabled = true
				var product_id := str(product.get("id", ""))
				buy.pressed.connect(func(): app.purchase(product_id))
				prow.add_child(buy)
				root.add_child(p)
		var restore := Kit.button("Restore purchases", "restore", false, 42, 18)
		restore.pressed.connect(func(): app.restore_purchases(); ui.toast("Checking Google Play purchases…", "restore", Kit.ACCENT))
		root.add_child(restore)
	var usage := Kit.wrapped("%d of %d free boards used. Purchases are handled securely by Google Play." % [app.get_projects().size(), app.get_free_limit()], 11, Kit.DIM, 450)
	root.add_child(usage)
	return root


# ---------------------------------------------------------------- projects

func _projects() -> Control:
	var root := _root()
	var projects: Array = app.get_projects()
	var info := Kit.label("%s · all features unlocked" % _plural(projects.size(), "board"), 14, Kit.MUTED, 500, "mono")
	root.add_child(info)
	var new_btn := Kit.button("New board", "add", true, 46, 19)
	new_btn.pressed.connect(func(): app.new_project())
	root.add_child(new_btn)
	root.add_child(_section("Your boards"))
	for p in projects:
		var pid := str(p.get("id", ""))
		var active: bool = pid == app.project.id
		var panel := Kit.panel(Color(0.184, 0.357, 1.0, 0.06) if active else Kit.SURFACE_2, 14, Color(0.184, 0.357, 1.0, 0.35) if active else Kit.STROKE, 1, 8)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		panel.add_child(row)
		var open := Button.new()
		open.flat = true
		open.focus_mode = Control.FOCUS_NONE
		open.alignment = HORIZONTAL_ALIGNMENT_LEFT
		open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		open.custom_minimum_size = Vector2(0, 64)
		var stats: Dictionary = p.get("stats", {})
		open.text = "%s\n%s · %s · %s" % [str(p.get("title", "Board")), _plural(int(stats.get("items", 0)), "object"), _plural(int(stats.get("frames", 0)), "frame"), _date(float(p.get("updated_at", 0)))]
		open.add_theme_font_override("font", AppFonts.body(500))
		open.add_theme_font_size_override("font_size", 14)
		open.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		open.clip_text = true
		open.add_theme_color_override("font_color", Kit.TEXT)
		open.add_theme_color_override("font_hover_color", Kit.ACCENT)
		open.pressed.connect(func(): app.open_project(pid))
		row.add_child(open)
		var duplicate := Kit.icon_button("content_copy", 30, 17)
		duplicate.tooltip_text = "Duplicate"
		duplicate.pressed.connect(func(): app.duplicate_project(pid); ui.reload_sheet())
		row.add_child(duplicate)
		var trash := Kit.icon_button("delete", 30, 17)
		trash.tooltip_text = "Delete"
		trash.pressed.connect(func():
			ui.confirm("Delete board?", "\"%s\" and its media will be removed from this device. This cannot be undone." % str(p.get("title", "Board")), func():
				app.delete_project(pid)
				ui.reload_sheet()
			, "Delete", true)
		)
		row.add_child(trash)
		root.add_child(panel)
	if projects.is_empty():
		root.add_child(_empty("No boards yet", "Create your first infinite canvas.", "dashboard_customize"))
	root.add_child(Kit.divider())
	var import_row := _row("upload_file", "Import a board", "Open a .ic3d.json or backup .zip", func(): app.import_any(), "", Kit.VIOLET)
	root.add_child(import_row)
	return root


func _date(timestamp: float) -> String:
	if timestamp <= 0.0:
		return "—"
	var t := int(timestamp)
	return Time.get_datetime_string_from_unix_time(t, true).substr(0, 16).replace("T", " ")


# ---------------------------------------------------------------- export

func _export() -> Control:
	var root := _root()
	root.add_child(Kit.wrapped("Files are written to the app's export folder, then you can choose a destination on your device.", 12, Kit.MUTED, 450))
	var defs := [
		["png", "image", "PNG snapshot", "A clean image of the current view", Kit.ACCENT],
		["json", "description", "Project file", "Editable .ic3d.json document", Kit.VIOLET],
		["md", "article", "Markdown outline", "Notes, frames and links as text", Kit.GREEN],
		["glb", "view_in_ar", "3D scene (GLB)", "Models and primitives, ready for other apps", Kit.GOLD],
		["zip", "folder_zip", "Full backup (.zip)", "Project plus all embedded media", Kit.VIOLET],
	]
	for d in defs:
		root.add_child(_row(d[1], d[2], d[3], func(): app.export_format(d[0]), "EXPORT", d[4], 88))
	root.add_child(Kit.divider())
	root.add_child(Kit.wrapped("GLB export includes only 3D objects and their materials. The project file and backup preserve the entire board, including ink, notes and media.", 13, Kit.DIM, 450))
	return root


# ---------------------------------------------------------------- more

func _more() -> Control:
	var root := _root()
	root.add_child(_row("tune", "Settings", "Appearance, canvas, tools, data and support", func(): ui.open_sheet("settings"), "OPEN", Kit.ACCENT, 88))
	root.add_child(Kit.divider())
	var panel := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_icon_tile("dashboard_customize", Kit.ACCENT, 36, 19))
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_constant_override("separation", 0)
	row.add_child(tb)
	tb.add_child(Kit.label(app.project.title, 16, Kit.TEXT, 650))
	var stats: Dictionary = app.get_stats()
	tb.add_child(Kit.label("%s · %s · %s" % [_plural(int(stats.get("items", 0)), "object"), _plural(int(stats.get("connectors", 0)), "link"), _plural(int(stats.get("layers", 0)), "layer")], 12, Kit.MUTED, 450))
	var rename := Kit.icon_button("edit", 32, 18)
	rename.pressed.connect(func(): ui.prompt("Rename board", "Board name", app.project.title, func(text): app.rename_project(text)))
	row.add_child(rename)
	var grid := _grid(2)
	root.add_child(grid)
	var actions := [
		["projects", "Projects", "folder_open", func(): ui.open_sheet("projects")],
		["save", "Save now", "save", func(): app.save_now(); ui.toast("Board saved", "save", Kit.GREEN)],
		["export", "Export", "ios_share", func(): ui.open_sheet("export")],
		["import", "Import file", "upload_file", func(): app.import_any()],
		["backup", "Backup", "archive", func(): app.create_backup()],
		["restore", "Restore", "restore", func(): app.restore_backup()],
		["nav", "Bookmarks", "bookmark", func(): ui.open_sheet("nav")],
		["look", "Lighting & grid", "light_mode", func(): ui.open_sheet("look")],
		["help", "Help & gestures", "help", func(): ui.open_sheet("help")],
		["about", "About", "info", func(): ui.open_sheet("about")],
	]
	for a in actions:
		grid.add_child(_card(a[2], a[1], "", a[3], "", Kit.ACCENT, 96))
	root.add_child(Kit.wrapped("v3.2.0 · offline-first · ads can be removed in Settings", 13, Kit.DIM, 450))
	return root


# ---------------------------------------------------------------- nav

func _nav() -> Control:
	var root := _root()
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	root.add_child(mode_row)
	var m2 := Kit.button("2D canvas", "2d", app.rig.mode == "2d", 44, 18)
	m2.pressed.connect(func(): app.set_mode("2d"))
	mode_row.add_child(m2)
	var m3 := Kit.button("3D space", "view_in_ar", app.rig.mode == "3d", 44, 18)
	m3.pressed.connect(func(): app.set_mode("3d"))
	mode_row.add_child(m3)
	root.add_child(Kit.label("Zoom · %d%%  ·  %s" % [int(app.get_zoom_percent()), "3D orbit" if app.rig.mode == "3d" else "2D canvas"], 12, Kit.MUTED, 500, "mono"))
	root.add_child(_section("Six directions"))
	var pad := GridContainer.new()
	pad.columns = 3
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	root.add_child(pad)
	var empty := Control.new()
	empty.custom_minimum_size = Vector2(0, 46)
	pad.add_child(empty)
	pad.add_child(_nav_btn("arrow_upward", func(): app.camera_nudge("up")))
	pad.add_child(Control.new())
	pad.add_child(_nav_btn("arrow_back", func(): app.camera_nudge("left")))
	pad.add_child(_nav_btn("fit_screen", func(): app.focus_all()))
	pad.add_child(_nav_btn("arrow_forward", func(): app.camera_nudge("right")))
	pad.add_child(Control.new())
	pad.add_child(_nav_btn("arrow_downward", func(): app.camera_nudge("down")))
	pad.add_child(Control.new())
	var zoom_row := HBoxContainer.new()
	zoom_row.add_theme_constant_override("separation", 6)
	root.add_child(zoom_row)
	zoom_row.add_child(_make_btn("Zoom out", "zoom_out", func(): app.camera_nudge("out")))
	zoom_row.add_child(_make_btn("Zoom in", "zoom_in", func(): app.camera_nudge("in")))
	root.add_child(_section("Camera presets"))
	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 6)
	root.add_child(presets)
	for p in [["front", "Front"], ["iso", "Iso"], ["top", "Top"]]:
		var b := _make_btn(p[1], "", func(): app.set_camera_preset(p[0]))
		presets.add_child(b)
	root.add_child(Kit.divider())
	root.add_child(_section("Camera bookmarks"))
	var save := Kit.button("Save this view", "bookmark_add", true, 42, 18)
	save.pressed.connect(func():
		ui.prompt("Save view", "Name this view", "View", func(text): app.save_bookmark(text); ui.reload_sheet())
	)
	root.add_child(save)
	for bm in app.project.bookmarks:
		var bm_id := str(bm.get("id", ""))
		var panel := Kit.panel(Kit.SURFACE_2, 12, Kit.HOVER, 1, 8)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		panel.add_child(h)
		h.add_child(Kit.icon("bookmark", 17, Kit.GOLD, 1.0))
		var l := Kit.label(str(bm.get("name", "View")), 14, Kit.TEXT, 500)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var go := Kit.icon_button("north_east", 28, 16)
		go.pressed.connect(func(): app.goto_bookmark(bm_id); ui.close_sheet())
		h.add_child(go)
		var del := Kit.icon_button("delete", 28, 16)
		del.pressed.connect(func(): app.delete_bookmark(bm_id); ui.reload_sheet())
		h.add_child(del)
		root.add_child(panel)
	if app.project.bookmarks.is_empty():
		root.add_child(Kit.wrapped("Save a viewpoint to fly back to it instantly. Bookmarks are stored with this board.", 13, Kit.DIM, 450))
	return root


func _nav_btn(icon_name: String, cb: Callable) -> Button:
	var b := Kit.icon_button(icon_name, 46, 21)
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_stylebox_override("normal", Kit.style(Kit.HOVER, 12, Kit.STROKE, 1))
	b.pressed.connect(cb)
	return b


# ---------------------------------------------------------------- look

func _look() -> Control:
	var root := _root()
	var look: Dictionary = app.get_look_settings()
	root.add_child(_section("Atmosphere"))
	var presets := _grid(2)
	root.add_child(presets)
	for p in [["studio", "Studio", "light_mode"], ["midnight", "Midnight", "dark_mode"], ["warm", "Warm", "wb_sunny"], ["neon", "Neon", "flare"]]:
		var active: bool = str(look.get("preset", "studio")) == str(p[0])
		var b := Kit.button(str(p[1]), p[2], active, 40, 17)
		b.pressed.connect(func(): app.apply_look_preset(p[0]); ui.reload_sheet())
		presets.add_child(b)
	root.add_child(_slider("Key light", 0.2, 2.4, 0.05, float(look.get("key_energy", 1.2)), "×", 2, func(v): app.set_look_param("key_energy", v)))
	root.add_child(_slider("Ambient", 0.0, 1.5, 0.05, float(look.get("ambient", 0.45)), "", 2, func(v): app.set_look_param("ambient", v)))
	root.add_child(_toggle_row("Show grid", bool(look.get("grid", true)), func(on): app.toggle_setting("show_grid", on), "grid_4x4"))
	root.add_child(_toggle_row("Snap to grid & guides", bool(look.get("snap", true)), func(on): app.set_setting("snap", on), "grid_on"))
	root.add_child(_toggle_row("Performance mode", bool(look.get("performance", false)), func(on): app.set_setting("performance_mode", on), "bolt"))
	root.add_child(_section("Canvas accent"))
	var accents := ["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44"]
	root.add_child(_swatches(accents, str(look.get("accent", "#2F5BFF")), func(hex): app.set_canvas_accent(hex)))
	root.add_child(_section("Grid step"))
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 6)
	root.add_child(steps)
	for s in [0.5, 1.0, 2.0, 5.0]:
		var b := Kit.button(str(s), "", is_equal_approx(float(look.get("grid_step", 1.0)), s), 38, 16)
		b.pressed.connect(func(): app.set_grid_step(s); ui.reload_sheet())
		steps.add_child(b)
	root.add_child(_section("Rotation snap"))
	var angles := HBoxContainer.new()
	angles.add_theme_constant_override("separation", 6)
	root.add_child(angles)
	for a in [0.0, 15.0, 45.0, 90.0]:
		var b := Kit.button("Off" if a == 0.0 else "%d°" % int(a), "", is_equal_approx(float(look.get("snap_angle", 15.0)), a), 38, 16)
		b.pressed.connect(func(): app.set_snap_angle(a); ui.reload_sheet())
		angles.add_child(b)
	return root


# ---------------------------------------------------------------- help / about

func _help() -> Control:
	var root := _root()
	root.add_child(_section("Gestures"))
	for f in [
		["touch_app", "One finger", "Select, move, draw or tap to place an object."],
		["pan_tool_alt", "Two fingers", "Pan the canvas and pinch to zoom. Works in 2D and 3D."],
		["view_in_ar", "Empty space in 3D", "Drag to orbit. The same drawing stays on the canvas."],
		["edit", "Double-tap", "Open the content editor for a note, frame or image."],
		["open_with", "Long-press", "Open the inspector without opening the selection bar."],
	]:
		root.add_child(_info_row(f[0], f[1], f[2], Kit.ACCENT, 78))
	root.add_child(_section("Shortcuts (desktop)"))
	var shortcuts := "V select · H pan · P pen · M highlighter · E eraser · N note · R shape · C connect\nCtrl/⌘ Z undo · Shift Ctrl/⌘ Z redo · Ctrl/⌘ S save · Delete remove · Tab toggle 2D/3D"
	var text := Kit.wrapped(shortcuts, 14, Kit.MUTED, 450)
	root.add_child(text)
	root.add_child(Kit.divider())
	var replay := Kit.button("Replay the welcome", "auto_awesome", false, 42, 18)
	replay.pressed.connect(func(): app.replay_onboarding(); ui.close_sheet())
	root.add_child(replay)
	return root


func _about() -> Control:
	var root := _root()
	var info: Dictionary = app.get_device_info()
	var hero := Kit.panel(Kit.SURFACE_2, 18, Kit.STROKE, 1, 14)
	root.add_child(hero)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	hero.add_child(h)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icon_512.png")
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(icon)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 2)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tb)
	tb.add_child(Kit.display_label("Ultimate Canvas", 16, Kit.TEXT, 700))
	tb.add_child(Kit.label("STUDIO · v%s" % str(info.get("version", "3.2.0")), 12, Kit.ACCENT, 700, "mono"))
	tb.add_child(Kit.label("Godot %s" % str(info.get("engine", "4.7.2")), 12, Kit.MUTED, 500, "mono"))
	root.add_child(_section("Share and support"))
	root.add_child(_button_row([
		_make_btn("Share app", "share", func(): app.share_app()),
		_make_btn("Rate on Play", "star", func(): app.rate_app()),
	]))
	for f in [
		["database", "Offline-first", "Projects, media and history live on this device. No account and no analytics."],
		["shield", "Privacy", "Network is used only by AdMob ads and Google Play Billing for Remove Ads."],
		["brush", "Built with", "Inspired by Lorien (MIT) by Marcus Brummer. Godot Engine, Sora, Inter and Material Symbols."],
	]:
		root.add_child(_info_row(f[0], f[1], f[2], Kit.ACCENT, 92))
	root.add_child(_section("This device"))
	var model := str(info.get("model", "")).strip_edges()
	var device := "%s · %s" % [model, str(info.get("os", ""))] if not model.is_empty() else str(info.get("os", ""))
	root.add_child(_info_row("phone_android", "Device", device, Kit.VIOLET, 82))
	root.add_child(_info_row("view_in_ar", "Renderer", str(info.get("renderer", "GL Compatibility")), Kit.ACCENT, 82))
	root.add_child(_info_row("database", "Storage", "%s · %d boards · %s" % [str(info.get("storage", "")), int(info.get("projects", 0)), str(info.get("screen", ""))], Kit.GREEN, 82))
	root.add_child(_section("Licence"))
	var license := TextEdit.new()
	license.text = "MIT License\n\nCopyright (c) 2021-2025 Marcus Brummer\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\nGodot Engine — MIT License. Material Symbols — Apache 2.0. Sora and Inter — SIL Open Font License 1.1."
	license.editable = false
	license.custom_minimum_size = Vector2(0, 200)
	license.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	license.add_theme_font_size_override("font_size", 13)
	root.add_child(license)
	var copy := Kit.button("Copy credits", "content_copy", false, 46, 19)
	copy.pressed.connect(func():
		DisplayServer.clipboard_set("Ultimate Infinite Canvas 3D Pro · Powered by Godot 4 · Inspired by Lorien (MIT) by Marcus Brummer")
		ui.toast("Credits copied", "check_circle", Kit.GREEN)
	)
	root.add_child(copy)
	root.add_child(Kit.wrapped("Made with care for phones and tablets · Your work stays yours.", 12, Kit.DIM, 500))
	return root


# ---------------------------------------------------------------- inspector

func _inspector() -> Control:
	var root := _root()
	var connector: Dictionary = app.get_selected_connector()
	if not connector.is_empty():
		return _connector_inspector(root, connector)
	var items: Array = app.get_selected_items()
	if items.is_empty():
		root.add_child(_empty("Nothing selected", "Tap an object on the canvas or choose a layer to start editing.", "touch_app"))
		return root
	if items.size() > 1:
		return _multi_inspector(root, items)
	var item: Dictionary = items[0]
	var type := str(item.get("type", "note"))
	var props: Dictionary = item.get("props", {})
	var item_id := str(item.get("id", ""))
	match type:
		"note", "text":
			root.add_child(_section("Content"))
			root.add_child(_field_line("Title", str(props.get("title", "")), "Give this idea a name", func(text): app.update_text_prop(item_id, "title", text)))
			root.add_child(_field_line("Body", str(props.get("body", "")), "Write freely…", func(text): app.update_text_prop(item_id, "body", text), true, 124))
			root.add_child(_field_line("Tags", ", ".join(props.get("tags", [])), "design, research, next", func(text): app.update_text_prop(item_id, "tags", text)))
			root.add_child(_section("Paper"))
			var themes: Array = app.get_note_themes()
			var swatches: Array = []
			for t in themes:
				swatches.append(str(t.get("color", "#F4F1E8")))
			root.add_child(_swatches(swatches, str(props.get("color", "#F4F1E8")), func(hex):
				for t in themes:
					if str(t.get("color", "")).to_upper() == hex.to_upper():
						app.set_note_theme(str(t.get("color")), str(t.get("accent")))
						return
			))
			root.add_child(_toggle_row("Pinned to the board", bool(props.get("pinned", false)), func(on): app.pin_selection(on), "push_pin"))
		"frame":
			root.add_child(_section("Shot"))
			root.add_child(_field_line("Title", str(props.get("title", "")), "Shot title", func(text): app.update_text_prop(item_id, "title", text)))
			root.add_child(_field_line("Action & notes", str(props.get("body", "")), "What happens in this shot?", func(text): app.update_text_prop(item_id, "body", text), true, 104))
			root.add_child(_section("Status"))
			var status_row := HBoxContainer.new()
			status_row.add_theme_constant_override("separation", 6)
			root.add_child(status_row)
			for s in ["Draft", "Ready", "Final"]:
				var b := Kit.button(s, "", str(props.get("status", "Draft")) == s, 36, 15)
				b.pressed.connect(func(): app.update_selected_props({"status": s}))
				status_row.add_child(b)
			root.add_child(_slider("Duration", 0.5, 12.0, 0.5, float(props.get("duration", 3.0)), "s", 1, func(v): app.update_selected_props({"duration": v})))
			root.add_child(Kit.label("Shot %02d" % int(props.get("order", 1)), 12, Kit.DIM, 600, "mono"))
		"image", "pdf":
			root.add_child(_section("Media"))
			root.add_child(_field_line("Caption", str(props.get("caption", "")), "Describe this media", func(text): app.update_text_prop(item_id, "caption", text)))
			root.add_child(_slider("Width", 1.8, 8.0, 0.1, float(props.get("width", 5.0)), " u", 1, func(v): app.update_selected_props({"width": v})))
			root.add_child(_button_row([
				_make_btn("Preview", "open_in_full", func(): app.preview_selected_media()),
				_make_btn("Re-link", "attach_file", func(): app.relink_selected()),
			]))
			root.add_child(Kit.wrapped("PDF pages are rasterised at import time and stay inside the project folder.", 13, Kit.DIM, 450))
		"primitive":
			root.add_child(_section("Form"))
			var shapes := ["box", "sphere", "cylinder", "cone", "torus", "plane"]
			var shape_grid := _grid(3)
			root.add_child(shape_grid)
			for s in shapes:
				var b := Kit.button(s.capitalize(), "", str(props.get("shape", "box")) == s, 36, 14)
				b.pressed.connect(func(): app.update_selected_props({"shape": s}))
				shape_grid.add_child(b)
			root.add_child(_section("Material"))
			root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#F0F5FF", "#2C3A50"], str(props.get("color", "#2F5BFF")), func(hex): app.update_selected_props({"color": hex})))
			root.add_child(_slider("Metallic", 0.0, 1.0, 0.05, float(props.get("metallic", 0.35)), "", 2, func(v): app.update_selected_props({"metallic": v})))
			root.add_child(_slider("Roughness", 0.0, 1.0, 0.05, float(props.get("roughness", 0.35)), "", 2, func(v): app.update_selected_props({"roughness": v})))
			root.add_child(_slider("Glow", 0.0, 1.0, 0.05, float(props.get("emission_energy", 0.0)) / 3.0, "", 2, func(v): app.set_selected_glow(v)))
			root.add_child(_slider("Size", 0.3, 8.0, 0.1, float(props.get("size", 1.6)), " u", 1, func(v): app.update_selected_props({"size": v})))
		"model":
			root.add_child(_section("3D model"))
			root.add_child(_field_line("Title", str(props.get("title", "")), "Model name", func(text): app.update_text_prop(item_id, "title", text)))
			root.add_child(_slider("Size", 0.4, 8.0, 0.1, float(props.get("size", 2.4)), " u", 1, func(v): app.update_selected_props({"size": v})))
			root.add_child(_section("Material tint"))
			root.add_child(_swatches(["#FFFFFF", "#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44"], str(props.get("tint", "#FFFFFF")), func(hex): app.update_selected_props({"tint": hex})))
			root.add_child(_slider("Metallic", 0.0, 1.0, 0.05, float(props.get("material", {}).get("metallic", 0.15)), "", 2, func(v): app.update_model_material("metallic", v)))
			root.add_child(_slider("Roughness", 0.0, 1.0, 0.05, float(props.get("material", {}).get("roughness", 0.6)), "", 2, func(v): app.update_model_material("roughness", v)))
			root.add_child(_button_row([
				_make_btn("Re-link", "attach_file", func(): app.relink_selected()),
				_make_btn("Export GLB", "download", func(): app.export_selected_glb()),
			]))
		"shape":
			root.add_child(_section("Shape"))
			var types := ["rect", "ellipse", "triangle"]
			var type_row := HBoxContainer.new()
			type_row.add_theme_constant_override("separation", 6)
			root.add_child(type_row)
			for s in types:
				var b := Kit.button(s.capitalize(), "", str(props.get("shape", "rect")) == s, 36, 14)
				b.pressed.connect(func(): app.update_selected_props({"shape": s}))
				type_row.add_child(b)
			root.add_child(_section("Fill & border"))
			root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#F0F5FF"], str(props.get("color", "#2F5BFF")), func(hex): app.update_selected_props({"color": hex})))
			root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#F0F5FF"], str(props.get("border_color", "#2F5BFF")), func(hex): app.update_selected_props({"border_color": hex})))
			root.add_child(_slider("Opacity", 0.0, 1.0, 0.05, float(props.get("opacity", 0.25)), "", 2, func(v): app.update_selected_props({"opacity": v})))
			root.add_child(_slider("Border", 0.0, 0.3, 0.005, float(props.get("border_width", 0.04)), " u", 3, func(v): app.update_selected_props({"border_width": v})))
			root.add_child(_slider("Width", 0.3, 20.0, 0.1, float(props.get("w", 3.0)), " u", 1, func(v): app.update_selected_props({"w": v})))
			root.add_child(_slider("Height", 0.3, 20.0, 0.1, float(props.get("h", 2.0)), " u", 1, func(v): app.update_selected_props({"h": v})))
		"group":
			var count: int = app.project.descendants_of(item_id).size()
			root.add_child(_empty("Group of %d" % count, "Move the group to carry every child with it. Ungroup to edit individually.", "group_work"))
			var ungroup := Kit.button("Ungroup", "group_work", false, 42, 18)
			ungroup.pressed.connect(func(): app.ungroup_selection())
			root.add_child(ungroup)
		_:
			root.add_child(_empty("Object", "This object can be moved and styled on the canvas.", "category"))
	root.add_child(Kit.divider())
	root.add_child(_section("Transform"))
	var pos: Array = item.get("pos", [0, 0, 0])
	var rot: Array = item.get("rot", [0, 0, 0])
	var scl: Array = item.get("scale", [1, 1, 1])
	var pos_row := HBoxContainer.new()
	pos_row.add_theme_constant_override("separation", 8)
	root.add_child(pos_row)
	pos_row.add_child(_num_field("X", float(pos[0]), func(v): app.set_transform_field("x", v)))
	pos_row.add_child(_num_field("Y", float(pos[1]), func(v): app.set_transform_field("y", v)))
	root.add_child(_slider("Depth (Z)", -4.0, 8.0, 0.05, float(pos[2]), " u", 2, func(v): app.set_transform_field("z", v)))
	root.add_child(_slider("Rotation", -180.0, 180.0, 1.0, float(rot[2]), "°", 0, func(v): app.set_transform_field("rot", v)))
	root.add_child(_slider("Scale", 0.2, 3.0, 0.05, float(scl[0]), "×", 2, func(v): app.set_transform_field("scale", v)))
	root.add_child(_section("Layer"))
	var layer_grid := _grid(2)
	root.add_child(layer_grid)
	for layer in app.project.layers:
		var lid := str(layer.get("id", ""))
		var active_layer := str(item.get("layer", "")) == lid
		var color := Color.from_string(str(layer.get("color", "#2F5BFF")), Kit.ACCENT)
		var b := Button.new()
		b.text = str(layer.get("name", "Layer"))
		b.custom_minimum_size = Vector2(0, 36)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", AppFonts.body(550))
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Kit.ACCENT if active_layer else Kit.TEXT)
		b.add_theme_stylebox_override("normal", Kit.style(Color(color.r, color.g, color.b, 0.14 if active_layer else 0.035), 10, Color(color.r, color.g, color.b, 0.5 if active_layer else 0.1), 1))
		b.add_theme_stylebox_override("hover", Kit.style(Color(color.r, color.g, color.b, 0.2), 10))
		b.add_theme_stylebox_override("pressed", Kit.style(Color(color.r, color.g, color.b, 0.26), 10))
		b.pressed.connect(func(): app.move_selection_to_layer(lid))
		layer_grid.add_child(b)
	root.add_child(Kit.divider())
	root.add_child(_button_row([
		_make_btn("Duplicate", "content_copy", func(): app.duplicate_selection()),
		_make_btn("Delete", "delete", func(): app.delete_selection()),
	]))
	return root


func _multi_inspector(root: VBoxContainer, items: Array) -> Control:
	root.add_child(_empty("%d objects selected" % items.size(), "Move them together, group them, or apply a shared layer.", "group_work"))
	root.add_child(_section("Arrange"))
	root.add_child(_button_row([
		_make_btn("Group", "group_work", func(): app.group_selection()),
		_make_btn("Duplicate", "content_copy", func(): app.duplicate_selection()),
	]))
	root.add_child(_button_row([
		_make_btn("Delete", "delete", func(): app.delete_selection()),
		_make_btn("Focus", "filter_center_focus", func(): app.focus_selected()),
	]))
	root.add_child(_section("Move to layer"))
	var grid := _grid(2)
	root.add_child(grid)
	for layer in app.project.layers:
		var lid := str(layer.get("id", ""))
		var b := Kit.button(str(layer.get("name", "Layer")), "", false, 38, 14)
		b.pressed.connect(func(): app.move_selection_to_layer(lid))
		grid.add_child(b)
	return root


func _connector_inspector(root: VBoxContainer, connector: Dictionary) -> Control:
	root.add_child(_section("Connection"))
	root.add_child(_field_line("Label", str(connector.get("label", "")), "e.g. depends on", func(text): app.set_connector_props({"label": text})))
	root.add_child(_section("Style"))
	var styles := HBoxContainer.new()
	styles.add_theme_constant_override("separation", 6)
	root.add_child(styles)
	for s in [["curve", "Curve"], ["straight", "Straight"], ["dashed", "Dashed"]]:
		var b := Kit.button(s[1], "", str(connector.get("style", "curve")) == s[0], 36, 14)
		b.pressed.connect(func(): app.set_connector_props({"style": s[0]}))
		styles.add_child(b)
	root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#8FA0B8"], str(connector.get("color", "#8FA0B8")), func(hex): app.set_connector_props({"color": hex})))
	root.add_child(_toggle_row("Arrowhead", bool(connector.get("arrow", true)), func(on): app.set_connector_props({"arrow": on}), "arrow_forward"))
	root.add_child(_slider("Thickness", 0.5, 3.0, 0.1, float(connector.get("width", 0.035)) / 0.035, "×", 1, func(v): app.set_connector_props({"width": v * 0.035})))
	root.add_child(Kit.divider())
	root.add_child(_button_row([
		_make_btn("Delete link", "delete", func(): app.delete_selection()),
		_make_btn("Select source", "north_east", func(): app.select_connector_source()),
	]))
	return root


func _num_field(title: String, value: float, callback: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(Kit.label(title, 12, Kit.MUTED, 600, "mono"))
	var le := LineEdit.new()
	le.text = "%.2f" % value
	le.custom_minimum_size = Vector2(0, 40)
	le.add_theme_font_override("font", AppFonts.mono(500))
	le.add_theme_font_size_override("font_size", 14)
	le.text_submitted.connect(func(t): callback.call(float(t)))
	box.add_child(le)
	return box
