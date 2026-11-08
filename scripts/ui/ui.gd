class_name GameUI
extends CanvasLayer

const TOP_H := 58.0
const DOCK_H := 64.0
const RAIL_W := 58.0
const SIDE_W := 48.0
const SHEET_MAX := 830.0

const TOOL_DEFS := [
	["select", "touch_app", "Select & move", "Tap to select, drag to move, drag empty space for a marquee."],
	["pan", "pan_tool_alt", "Pan", "Drag to glide across the infinite canvas."],
	["pen", "stylus", "Pen", "Draw directly on the canvas plane, in 2D or 3D."],
	["highlighter", "ink_highlighter", "Highlighter", "Layer soft translucent marks under your notes."],
	["eraser", "ink_eraser", "Eraser", "Drag across ink to erase whole strokes."],
	["note", "sticky_note_2", "Note", "Tap anywhere to drop a spatial note."],
	["shape", "category", "Shape", "Tap to add a shape, then fine-tune it in the inspector."],
	["connect", "polyline", "Connect", "Tap one object, then another to link them."],
]

const SHEET_META := {
	"create": ["CREATE", "Make something", "Objects land at the center of your current view."],
	"primitive": ["3D WORKSPACE", "3D object", "Sculptural objects float in front of the canvas."],
	"layers": ["ORGANIZE", "Layers", "Structure visibility, locking and colour across the board."],
	"templates": ["START FASTER", "Templates", "Professional layouts built from real notes, frames and links."],
	"smart": ["INTELLIGENCE", "Smart Studio", "On-device analysis. Private by design."],
	"graph": ["SPATIAL KNOWLEDGE", "Idea graph", "A living map of what connects to what."],
	"timeline": ["NARRATIVE", "Storyboard", "Sequence shots, present the board, keep the story moving."],
	"projects": ["LIBRARY", "Your boards", "Everything stays on this device."],
	"export": ["SHARE", "Export", "Take the work with you in real, portable formats."],
	"more": ["WORKSPACE", "Studio menu", "Projects, files, views and preferences."],
	"nav": ["NAVIGATION", "Move through space", "Six directions, presets and camera bookmarks."],
	"look": ["ATMOSPHERE", "View & lighting", "Tune the grid, lighting and snap behaviour."],
	"help": ["GUIDE", "Help", "Gestures, shortcuts and a quick tour."],
	"about": ["ULTIMATE INFINITE CANVAS 3D", "About", "Version 3.2.0 · Godot 4.7.2 · Ad-supported"],
	"inspector": ["INSPECTOR", "Selected object", "Adjust content, appearance and transform."],
	"layer_options": ["LAYER", "Layer options", "Rename, recolour or reorder this layer."],
	"settings": ["PREFERENCES", "Settings", "Appearance, canvas, tools, editor, data and support."],
	"restore_points": ["HISTORY", "Restore points", "Autosaved snapshots of this board, kept on device."],
}

var app: Node
var root: Control
var overlay: CanvasOverlay
var chrome: Control

var topbar: PanelContainer
var project_button: Button
var project_title_label: Label
var status_label: Label
var undo_btn: Button
var redo_btn: Button
var mode_btn: Button
var menu_btn: Button
var rail: PanelContainer
var rail_buttons := {}
var dock: PanelContainer
var dock_buttons := {}
var side_panel: PanelContainer
var side_buttons := {}
var selection_bar: PanelContainer
var selection_icon: Label
var selection_name: Label
var selection_sub: Label
var selection_actions: HBoxContainer
var tool_bar: PanelContainer
var tool_bar_row: HBoxContainer
var toast_panel: PanelContainer
var toast_icon: Label
var toast_label: Label
var toast_tween: Tween
var empty_hint: Control
var safe_top := 0.0
var safe_bottom := 0.0
var zoom_percent := 100.0
var active_dock := ""

var sheet_root: Control
var sheet_dim: ColorRect
var sheet_panel: PanelContainer
var sheet_body: VBoxContainer
var sheet_scroll: ScrollContainer
var sheet_eyebrow: Label
var sheet_title: Label
var sheet_subtitle: Label
var sheet_kind := ""
var sheet_ctx: Dictionary = {}

var modal_root: Control
var modal_panel: PanelContainer
var modal_box: VBoxContainer

var onboarding: Control
var onboarding_card: PanelContainer
var splash_root: Control
var busy_root: Control
var busy_label: Label
var busy_spin: Control
var image_root: Control
var image_texture: TextureRect
var image_caption: Label
var panels: Panels
var _did_layout := false
var _sheet_token := 0


func setup(p_app: Node) -> void:
	app = p_app
	layer = 20
	root = Control.new()
	root.name = "UIRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Kit.theme()
	add_child(root)
	panels = Panels.new(self, app)
	_build_overlay()
	chrome = Control.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chrome)
	_build_topbar()
	_build_rail()
	_build_dock()
	_build_side()
	_build_selection_bar()
	_build_tool_bar()
	_build_empty_hint()
	_build_sheet()
	_build_modal()
	_build_onboarding()
	_build_splash()
	_build_toast()
	_build_busy()
	_build_image_viewer()
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_layout")
	refresh()


func _build_overlay() -> void:
	overlay = CanvasOverlay.new()
	root.add_child(overlay)


func _build_topbar() -> void:
	topbar = PanelContainer.new()
	topbar.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 20, Kit.STROKE, 1, 10, 20, Kit.SHADOW))
	chrome.add_child(topbar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	topbar.add_child(row)
	var logo_holder := Control.new()
	logo_holder.custom_minimum_size = Vector2(32, 32)
	var logo_texture := TextureRect.new()
	logo_texture.texture = load("res://assets/icon_192.png")
	logo_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_holder.add_child(logo_texture)
	if logo_texture.texture == null:
		var fallback := Kit.icon("view_in_ar", 21, Kit.ACCENT, 1.0)
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		logo_holder.add_child(fallback)
	row.add_child(logo_holder)
	project_button = Button.new()
	project_button.focus_mode = Control.FOCUS_NONE
	project_button.flat = true
	project_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	project_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	project_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	project_button.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 10))
	project_button.add_theme_stylebox_override("pressed", Kit.style(Kit.STROKE, 10))
	project_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	project_button.pressed.connect(func(): open_sheet("projects"))
	row.add_child(project_button)
	var title_box := VBoxContainer.new()
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_box.offset_left = 6
	title_box.offset_right = -4
	title_box.add_theme_constant_override("separation", 1)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	project_button.add_child(title_box)
	project_title_label = Kit.label("Untitled Board", 17, Kit.TEXT, 650, "display")
	project_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	project_title_label.clip_text = true
	project_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(project_title_label)
	status_label = Kit.label("Local · saved", 12, Kit.MUTED, 500, "mono")
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.clip_text = true
	title_box.add_child(status_label)
	undo_btn = Kit.icon_button("undo", 32, 19, false)
	undo_btn.tooltip_text = "Undo"
	undo_btn.pressed.connect(func(): app.undo_action())
	row.add_child(undo_btn)
	redo_btn = Kit.icon_button("redo", 32, 19, false)
	redo_btn.tooltip_text = "Redo"
	redo_btn.pressed.connect(func(): app.redo_action())
	row.add_child(redo_btn)
	mode_btn = Button.new()
	mode_btn.custom_minimum_size = Vector2(58, 36)
	mode_btn.focus_mode = Control.FOCUS_NONE
	mode_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_mode_button(false)
	mode_btn.pressed.connect(func(): app.toggle_mode())
	row.add_child(mode_btn)
	var mode_row := HBoxContainer.new()
	mode_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_row.add_theme_constant_override("separation", 4)
	mode_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_btn.add_child(mode_row)
	var mode_icon := Kit.icon("view_in_ar", 16, Kit.TEXT, 0.0)
	mode_row.add_child(mode_icon)
	var mode_label := Kit.label("3D", 12, Kit.TEXT, 700, "mono")
	mode_row.add_child(mode_label)
	mode_btn.set_meta("mode_icon", mode_icon)
	mode_btn.set_meta("mode_label", mode_label)
	menu_btn = Kit.icon_button("more_horiz", 32, 20, false)
	menu_btn.tooltip_text = "Studio menu"
	menu_btn.pressed.connect(func(): open_sheet("more"))
	row.add_child(menu_btn)


func _style_mode_button(active: bool) -> void:
	var bg := Color(0.184, 0.357, 1.0, 0.16) if active else Kit.HOVER
	var border := Kit.ACCENT if active else Kit.STROKE
	mode_btn.add_theme_stylebox_override("normal", Kit.style(bg, 11, border, 1))
	mode_btn.add_theme_stylebox_override("hover", Kit.style(bg.lightened(0.06), 11, border, 1))
	mode_btn.add_theme_stylebox_override("pressed", Kit.style(bg.lightened(0.12), 11, border, 1))
	mode_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _build_rail() -> void:
	rail = PanelContainer.new()
	rail.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 22, Kit.STROKE, 1, 6, 18))
	chrome.add_child(rail)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	rail.add_child(col)
	for def in TOOL_DEFS:
		var key: String = def[0]
		var btn := Kit.icon_button(def[1], 44, 24)
		btn.tooltip_text = def[2]
		btn.pressed.connect(func(): app.set_tool(key))
		col.add_child(btn)
		rail_buttons[key] = btn


func _build_dock() -> void:
	dock = PanelContainer.new()
	dock.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 22, Kit.STROKE, 1, 8, 20))
	chrome.add_child(dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(row)
	var defs := [
		["add", "add", "Create"],
		["layers", "layers", "Layers"],
		["templates", "dashboard_customize", "Templates"],
		["smart", "auto_awesome", "Smart Studio"],
		["graph", "hub", "Idea graph"],
		["timeline", "view_timeline", "Storyboard"],
	]
	for def in defs:
		var key: String = def[0]
		var btn := Kit.icon_button(def[1], 42, 23)
		btn.tooltip_text = def[2]
		btn.pressed.connect(func(): _on_dock(key))
		if key == "add":
			btn.add_theme_stylebox_override("normal", Kit.style(Color(0.184, 0.357, 1.0, 0.14), 14, Color(0.184, 0.357, 1.0, 0.45), 1))
			var glyph: Label = btn.get_meta("glyph")
			glyph.add_theme_color_override("font_color", Kit.ACCENT)
		row.add_child(btn)
		dock_buttons[key] = btn


func _on_dock(key: String) -> void:
	match key:
		"add":
			open_sheet("create")
		"layers":
			open_sheet("layers")
		"templates":
			open_sheet("templates")
		"smart":
			open_sheet("smart")
		"graph":
			open_sheet("graph")
		"timeline":
			open_sheet("timeline")


func _build_side() -> void:
	side_panel = PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 20, Kit.STROKE, 1, 5, 16))
	chrome.add_child(side_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	side_panel.add_child(col)
	var defs := [
		["nav", "explore", "Navigate", func(): open_sheet("nav")],
		["fit", "fit_screen", "Fit board", func(): app.focus_all()],
		["focus", "filter_center_focus", "Focus selection", func(): app.focus_selected()],
	]
	for def in defs:
		var btn := Kit.icon_button(def[1], 38, 21)
		btn.tooltip_text = def[2]
		btn.pressed.connect(def[3])
		col.add_child(btn)
		side_buttons[def[0]] = btn


func _build_selection_bar() -> void:
	selection_bar = PanelContainer.new()
	selection_bar.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 16, Kit.STROKE_STRONG, 1, 8, 14))
	selection_bar.visible = false
	chrome.add_child(selection_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	selection_bar.add_child(row)
	selection_icon = Kit.icon("sticky_note_2", 23, Kit.ACCENT, 1.0)
	row.add_child(selection_icon)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)
	selection_name = Kit.label("Note", 16, Kit.TEXT, 600)
	selection_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selection_name.clip_text = true
	text_box.add_child(selection_name)
	selection_sub = Kit.label("Ideas layer", 12, Kit.MUTED, 500, "mono")
	selection_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selection_sub.clip_text = true
	text_box.add_child(selection_sub)
	selection_actions = HBoxContainer.new()
	selection_actions.add_theme_constant_override("separation", 1)
	row.add_child(selection_actions)
	_add_selection_action("edit", "Edit object", func(): open_sheet("inspector"))
	_add_selection_action("palette", "Appearance", func(): open_sheet("inspector"))
	_add_selection_action("content_copy", "Duplicate", func(): app.duplicate_selection())
	_add_selection_action("delete", "Delete", func(): app.delete_selection(), Kit.DANGER)


func _add_selection_action(icon_name: String, tip: String, callable: Callable, color := Kit.TEXT) -> void:
	var btn := Kit.icon_button(icon_name, 34, 20)
	btn.tooltip_text = tip
	btn.add_theme_stylebox_override("normal", Kit.style(Kit.SURFACE_2, 10))
	var glyph: Label = btn.get_meta("glyph")
	glyph.add_theme_color_override("font_color", color)
	btn.pressed.connect(callable)
	selection_actions.add_child(btn)


func _build_tool_bar() -> void:
	tool_bar = PanelContainer.new()
	tool_bar.add_theme_stylebox_override("panel", Kit.style(Kit.GLASS, 18, Kit.STROKE, 1, 8, 16))
	tool_bar.visible = false
	chrome.add_child(tool_bar)
	tool_bar_row = HBoxContainer.new()
	tool_bar_row.add_theme_constant_override("separation", 6)
	tool_bar.add_child(tool_bar_row)


func _build_empty_hint() -> void:
	empty_hint = Control.new()
	empty_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_hint.visible = false
	chrome.add_child(empty_hint)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_hint.add_child(center)
	var card := Kit.panel(Kit.SURFACE, 24, Kit.STROKE, 1, 22, 24)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(292, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var halo := CenterContainer.new()
	halo.custom_minimum_size = Vector2(0, 78)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(halo)
	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(68, 68)
	icon_holder.size = Vector2(68, 68)
	halo.add_child(icon_holder)
	var bg := Kit.gradient(Kit.ACCENT, Kit.VIOLET, 22.0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_holder.add_child(bg)
	var glyph := Kit.icon("auto_awesome", 30, Kit.ON_ACCENT, 1.0)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_holder.add_child(glyph)
	var title := Kit.display_label("A space for every idea", 26, Kit.TEXT, 700)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)
	var sub := Kit.wrapped("Tap the + button to create a note, sketch with your finger, or open Templates to start from a professional layout.", 15, Kit.MUTED, 450)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.custom_minimum_size = Vector2(290, 0)
	box.add_child(sub)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var add_note := Kit.button("Add a note", "add", true, 50, 20)
	add_note.custom_minimum_size.x = 148
	add_note.pressed.connect(func(): app.create_at_center("note"))
	actions.add_child(add_note)
	var templates := Kit.button("Templates", "dashboard_customize", false, 50, 20)
	templates.custom_minimum_size.x = 136
	templates.pressed.connect(func(): open_sheet("templates"))
	actions.add_child(templates)


func _build_sheet() -> void:
	sheet_root = Control.new()
	sheet_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_root.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet_root.visible = false
	root.add_child(sheet_root)
	sheet_dim = ColorRect.new()
	sheet_dim.color = Kit.SCRIM
	sheet_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet_dim.gui_input.connect(_on_sheet_dim_input)
	sheet_root.add_child(sheet_dim)
	sheet_panel = PanelContainer.new()
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Kit.SURFACE
	sheet_style.corner_radius_top_left = 28
	sheet_style.corner_radius_top_right = 28
	sheet_style.corner_radius_bottom_left = 0
	sheet_style.corner_radius_bottom_right = 0
	sheet_style.border_color = Kit.STROKE_STRONG
	sheet_style.border_width_left = 1
	sheet_style.border_width_right = 1
	sheet_style.border_width_top = 1
	sheet_style.shadow_color = Kit.SHADOW
	sheet_style.shadow_size = 30
	sheet_panel.add_theme_stylebox_override("panel", sheet_style)
	sheet_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet_root.add_child(sheet_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	sheet_panel.add_child(outer)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 3)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 20)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(header_margin)
	header_margin.add_child(header)
	var grabber_row := HBoxContainer.new()
	grabber_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(grabber_row)
	var grabber := ColorRect.new()
	grabber.color = Kit.STROKE_STRONG
	grabber.custom_minimum_size = Vector2(38, 4)
	grabber_row.add_child(grabber)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	header.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	sheet_eyebrow = Kit.label("WORKSPACE", 12, Kit.ACCENT, 700, "mono")
	title_box.add_child(sheet_eyebrow)
	sheet_title = Kit.display_label("Panel", 26, Kit.TEXT, 700)
	sheet_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(sheet_title)
	sheet_subtitle = Kit.wrapped("", 14, Kit.MUTED, 450)
	sheet_subtitle.custom_minimum_size = Vector2(0, 0)
	title_box.add_child(sheet_subtitle)
	var close_btn := Kit.icon_button("close", 40, 22)
	close_btn.pressed.connect(close_sheet)
	title_row.add_child(close_btn)
	sheet_scroll = ScrollContainer.new()
	sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sheet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 18)
	body_margin.add_theme_constant_override("margin_right", 18)
	body_margin.add_theme_constant_override("margin_bottom", 30)
	body_margin.add_theme_constant_override("margin_top", 2)
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(sheet_scroll)
	sheet_scroll.add_child(body_margin)
	sheet_body = VBoxContainer.new()
	sheet_body.add_theme_constant_override("separation", 12)
	sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_child(sheet_body)


func _reset_sheet_scroll() -> void:
	if sheet_scroll != null:
		sheet_scroll.scroll_vertical = 0


func set_sheet_scroll(value: float) -> void:
	if sheet_scroll != null:
		sheet_scroll.scroll_vertical = int(value)


func _on_sheet_dim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		close_sheet()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_sheet()


func open_sheet(kind: String, ctx := {}) -> void:
	if sheet_kind == kind and sheet_root.visible:
		close_sheet()
		return
	_sheet_token += 1
	if sheet_kind == "inspector" and kind != "inspector":
		app.end_inspector_session()
	sheet_kind = kind
	sheet_ctx = ctx
	if kind == "inspector":
		app.begin_inspector_session()
	var meta: Array = SHEET_META.get(kind, ["WORKSPACE", kind.capitalize(), ""])
	sheet_eyebrow.text = meta[0]
	sheet_title.text = meta[1]
	sheet_subtitle.text = meta[2]
	sheet_subtitle.visible = not str(meta[2]).is_empty()
	for child in sheet_body.get_children():
		child.queue_free()
	var content: Control = panels.build(kind, ctx)
	if content != null:
		sheet_body.add_child(content)
	active_dock = kind
	_refresh_dock_active()
	sheet_root.visible = true
	sheet_root.modulate.a = 0.0
	if app.has_method("set_ad_overlay_hidden"):
		app.set_ad_overlay_hidden(true)
	_sheet_layout()
	sheet_scroll.scroll_vertical = 0
	call_deferred("_reset_sheet_scroll")
	var target_y := sheet_panel.position.y
	sheet_panel.position.y = target_y + 60.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sheet_root, "modulate:a", 1.0, 0.16)
	tw.tween_property(sheet_panel, "position:y", target_y, 0.24).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func close_sheet() -> void:
	if not sheet_root.visible:
		return
	_sheet_token += 1
	var token := _sheet_token
	if sheet_kind == "inspector":
		app.end_inspector_session()
	active_dock = ""
	_refresh_dock_active()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sheet_root, "modulate:a", 0.0, 0.14)
	tw.tween_property(sheet_panel, "position:y", sheet_panel.position.y + 40.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if token != _sheet_token:
			return
		sheet_root.visible = false
		sheet_kind = ""
		for child in sheet_body.get_children():
			child.queue_free()
		refresh()
		refresh_selection()
		if app.has_method("set_ad_overlay_hidden"):
			app.set_ad_overlay_hidden(onboarding.visible or (splash_root != null and splash_root.visible))
	)


func reload_sheet() -> void:
	if not sheet_root.visible:
		return
	var kind := sheet_kind
	var ctx: Dictionary = sheet_ctx.duplicate(true)
	_sheet_token += 1
	sheet_root.visible = false
	sheet_kind = ""
	for child in sheet_body.get_children():
		sheet_body.remove_child(child)
		child.queue_free()
	call_deferred("open_sheet", kind, ctx)


func _refresh_dock_active() -> void:
	for key in dock_buttons.keys():
		var btn: Button = dock_buttons[key]
		var active: bool = (key == active_dock)
		if key == "add":
			btn.add_theme_stylebox_override("normal", Kit.style(Color(0.184, 0.357, 1.0, 0.2 if active else 0.14), 13, Color(0.184, 0.357, 1.0, 0.7 if active else 0.45), 1))
			continue
		Kit.set_active(btn, active)


func _build_modal() -> void:
	modal_root = Control.new()
	modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_root.visible = false
	root.add_child(modal_root)
	var dim := ColorRect.new()
	dim.color = Kit.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_root.add_child(dim)
	modal_panel = PanelContainer.new()
	modal_panel.add_theme_stylebox_override("panel", Kit.style(Kit.SURFACE, 22, Kit.STROKE_STRONG, 1, 18, 26))
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_root.add_child(modal_panel)
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 12)
	modal_panel.add_child(modal_box)


func confirm(title_text: String, message: String, on_confirm: Callable, confirm_label := "Confirm", danger := false) -> void:
	_clear_modal()
	modal_root.visible = true
	modal_root.modulate.a = 0.0
	modal_box.add_child(Kit.display_label(title_text, 21, Kit.TEXT, 700))
	var msg := Kit.wrapped(message, 14, Kit.MUTED, 450)
	modal_box.add_child(msg)
	modal_box.add_child(Kit.divider())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	modal_box.add_child(row)
	var cancel := Kit.button("Cancel", "", false, 44)
	cancel.custom_minimum_size.x = 100
	cancel.pressed.connect(_hide_modal)
	row.add_child(cancel)
	var go := Kit.button(confirm_label, "", danger, 44)
	go.custom_minimum_size.x = 128
	go.pressed.connect(func():
		_hide_modal()
		if on_confirm.is_valid():
			on_confirm.call()
	)
	row.add_child(go)
	modal_panel.custom_minimum_size = Vector2(minf(360.0, root.size.x - 32.0), 0)
	modal_panel.reset_size()
	_center_modal()
	var tw := create_tween()
	tw.tween_property(modal_root, "modulate:a", 1.0, 0.14)


func prompt(title_text: String, placeholder: String, initial: String, on_submit: Callable, submit_label := "Save") -> void:
	_clear_modal()
	modal_root.visible = true
	modal_root.modulate.a = 0.0
	modal_box.add_child(Kit.display_label(title_text, 21, Kit.TEXT, 700))
	var le := LineEdit.new()
	le.text = initial
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(0, 48)
	modal_box.add_child(le)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	modal_box.add_child(row)
	var cancel := Kit.button("Cancel", "", false, 44)
	cancel.custom_minimum_size.x = 100
	cancel.pressed.connect(_hide_modal)
	row.add_child(cancel)
	var go := Kit.button(submit_label, "", true, 44)
	go.custom_minimum_size.x = 128
	var submit := func():
		var text := le.text.strip_edges()
		_hide_modal()
		if on_submit.is_valid():
			on_submit.call(text)
	go.pressed.connect(submit)
	le.text_submitted.connect(func(_t): submit.call())
	row.add_child(go)
	modal_panel.custom_minimum_size = Vector2(minf(360.0, root.size.x - 32.0), 0)
	modal_panel.reset_size()
	_center_modal()
	le.grab_focus()
	var tw := create_tween()
	tw.tween_property(modal_root, "modulate:a", 1.0, 0.14)


func _clear_modal() -> void:
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()


func _hide_modal() -> void:
	modal_root.visible = false
	_clear_modal()


func _center_modal() -> void:
	modal_panel.position = (root.size - modal_panel.size) * 0.5


func _build_onboarding() -> void:
	onboarding = Control.new()
	onboarding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	onboarding.mouse_filter = Control.MOUSE_FILTER_STOP
	onboarding.visible = false
	root.add_child(onboarding)
	var bg := Kit.gradient(Kit.BG, Kit.BG_2, 0.0, 0.18)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	onboarding.add_child(bg)
	var halo_a := PanelContainer.new()
	halo_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_a.add_theme_stylebox_override("panel", Kit.style(Color(Kit.ACCENT.r, Kit.ACCENT.g, Kit.ACCENT.b, 0.10), 999))
	halo_a.position = Vector2(-120, -90)
	halo_a.size = Vector2(360, 360)
	onboarding.add_child(halo_a)
	var halo_b := PanelContainer.new()
	halo_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_b.add_theme_stylebox_override("panel", Kit.style(Color(Kit.VIOLET.r, Kit.VIOLET.g, Kit.VIOLET.b, 0.08), 999))
	halo_b.position = Vector2(300, 680)
	halo_b.size = Vector2(240, 240)
	onboarding.add_child(halo_b)
	var top := HBoxContainer.new()
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 18
	top.offset_bottom = 62
	top.add_theme_constant_override("separation", 9)
	onboarding.add_child(top)
	var brand_icon := TextureRect.new()
	brand_icon.texture = load("res://assets/icon_192.png")
	brand_icon.custom_minimum_size = Vector2(32, 32)
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(brand_icon)
	top.add_child(Kit.label("ULTIMATE CANVAS", 13, Kit.ACCENT, 700, "mono"))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_spacer)
	var skip_btn := Button.new()
	skip_btn.text = "Skip"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.custom_minimum_size = Vector2(76, 42)
	skip_btn.add_theme_font_override("font", AppFonts.body(650))
	skip_btn.add_theme_font_size_override("font_size", 17)
	skip_btn.add_theme_color_override("font_color", Kit.MUTED)
	skip_btn.add_theme_stylebox_override("normal", Kit.style(Color(0, 0, 0, 0), 12))
	skip_btn.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 12))
	skip_btn.add_theme_stylebox_override("pressed", Kit.style(Kit.PRESSED, 12))
	skip_btn.pressed.connect(func(): onboarding.visible = false; app.first_run(false))
	top.add_child(skip_btn)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 26
	center.offset_right = -26
	center.offset_top = 74
	center.offset_bottom = -30
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	onboarding.add_child(center)
	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 116)
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon_center)
	var icon_holder := PanelContainer.new()
	icon_holder.custom_minimum_size = Vector2(112, 112)
	icon_holder.add_theme_stylebox_override("panel", Kit.style(Kit.SURFACE, 30, Kit.STROKE, 1, 8, 24, Kit.SHADOW))
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(icon_holder)
	var app_icon := TextureRect.new()
	app_icon.texture = load("res://assets/icon_512.png")
	app_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	app_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	app_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(app_icon)
	var eyebrow := Kit.label("ULTIMATE INFINITE CANVAS 3D PRO", 14, Kit.ACCENT, 700, "mono")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(eyebrow)
	var title := Kit.display_label("Think in space.", 38, Kit.TEXT, 700)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var subtitle := Kit.wrapped("A hybrid 2D + 3D infinite canvas for notes, mind maps, storyboards, PDFs and real 3D objects.", 17, Kit.MUTED, 460)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.custom_minimum_size = Vector2(340, 0)
	center.add_child(subtitle)
	var feature_card := Kit.panel(Kit.SURFACE, 22, Kit.STROKE, 1, 14, 18)
	onboarding_card = feature_card
	center.add_child(feature_card)
	var feature_box := VBoxContainer.new()
	feature_box.add_theme_constant_override("separation", 11)
	feature_card.add_child(feature_box)
	for f in [
		["stylus", "Draw & write", "Pressure-aware ink, highlighter and eraser", Kit.ACCENT],
		["view_in_ar", "2D ↔ 3D", "Orbit a spatial workspace without losing context", Kit.VIOLET],
		["auto_awesome", "Smart studio", "Links, summaries, storyboards & templates", Color("#E05A44")],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(42, 42)
		tile.add_theme_stylebox_override("panel", Kit.style(Color(f[3].r, f[3].g, f[3].b, 0.14), 12))
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := Kit.icon(f[0], 23, f[3], 1.0)
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.add_child(ic)
		row.add_child(tile)
		var text_box := VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 1)
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(Kit.label(f[1], 18, Kit.TEXT, 650))
		var sub := Kit.wrapped(f[2], 15, Kit.MUTED, 450)
		sub.max_lines_visible = 2
		text_box.add_child(sub)
		row.add_child(text_box)
		feature_box.add_child(row)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	center.add_child(spacer)
	var start := Kit.button("Start creating", "add", true, 58, 22)
	start.name = "OnboardingStart"
	start.pressed.connect(func(): onboarding.visible = false; app.first_run(false))
	center.add_child(start)
	var sample := Kit.button("Explore sample board", "auto_awesome", false, 54, 21)
	sample.name = "OnboardingSample"
	sample.pressed.connect(func(): onboarding.visible = false; app.first_run(true))
	center.add_child(sample)
	var privacy := Kit.wrapped("Your work stays on this device  ·  No account needed", 14, Kit.DIM, 500)
	privacy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy.max_lines_visible = 2
	center.add_child(privacy)


func _build_splash() -> void:
	splash_root = Control.new()
	splash_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_root.mouse_filter = Control.MOUSE_FILTER_STOP
	splash_root.visible = false
	root.add_child(splash_root)
	var bg := ColorRect.new()
	bg.color = Color("#FBF8F2")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_root.add_child(bg)
	var picture := TextureRect.new()
	picture.texture = load("res://assets/splash.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_root.add_child(picture)


func show_splash() -> void:
	if splash_root == null:
		return
	if app.has_method("set_ad_overlay_hidden"):
		app.set_ad_overlay_hidden(true)
	splash_root.visible = true
	splash_root.modulate = Color(1, 1, 1, 0)
	var fade_in := create_tween()
	fade_in.tween_property(splash_root, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(1.25).timeout
	var fade_out := create_tween()
	fade_out.tween_property(splash_root, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	splash_root.visible = false
	splash_root.modulate = Color.WHITE
	if app.has_method("set_ad_overlay_hidden"):
		app.set_ad_overlay_hidden(onboarding.visible)


func show_onboarding(show: bool) -> void:
	onboarding.visible = show
	if app.has_method("set_ad_overlay_hidden"):
		app.set_ad_overlay_hidden(show or (splash_root != null and splash_root.visible))
	if show:
		_layout()


func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.add_theme_stylebox_override("panel", Kit.style(Kit.SURFACE, 16, Kit.STROKE_STRONG, 1, 12, 20))
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(toast_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(row)
	toast_icon = Kit.icon("check_circle", 22, Kit.GREEN, 1.0)
	row.add_child(toast_icon)
	toast_label = Kit.label("", 15, Kit.TEXT, 550)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size = Vector2(252, 0)
	row.add_child(toast_label)


func toast(message: String, icon_name := "check_circle", color := Kit.GREEN, duration := 2.2) -> void:
	toast_icon.text = Icons.glyph(icon_name)
	toast_icon.add_theme_color_override("font_color", color)
	toast_label.text = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.reset_size()
	_center_toast()
	var tw := create_tween()
	tw.tween_property(toast_panel, "modulate:a", 1.0, 0.16)
	toast_panel.position.y = toast_panel.position.y - 8.0
	tw.parallel().tween_property(toast_panel, "position:y", toast_panel.position.y + 8.0, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.2)
	toast_tween.tween_callback(func(): toast_panel.visible = false)


func _center_toast() -> void:
	toast_panel.position.x = (root.size.x - toast_panel.size.x) * 0.5
	toast_panel.position.y = safe_top + TOP_H + 22.0


func _build_busy() -> void:
	busy_root = Control.new()
	busy_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	busy_root.mouse_filter = Control.MOUSE_FILTER_STOP
	busy_root.visible = false
	root.add_child(busy_root)
	var dim := ColorRect.new()
	dim.color = Kit.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	busy_root.add_child(dim)
	var card := Kit.glass(20, 18, Kit.SURFACE)
	busy_root.add_child(card)
	var busy_box := VBoxContainer.new()
	busy_box.add_theme_constant_override("separation", 10)
	busy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(busy_box)
	busy_spin = Control.new()
	busy_spin.custom_minimum_size = Vector2(46, 46)
	busy_spin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	busy_spin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy_spin.draw.connect(_draw_spin)
	busy_box.add_child(busy_spin)
	busy_label = Kit.label("Working…", 14, Kit.TEXT, 550)
	busy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	busy_box.add_child(busy_label)


func set_busy(active: bool, message := "Working…") -> void:
	busy_root.visible = active
	busy_label.text = message
	if active:
		busy_root.set_meta("angle", 0.0)
		var card: Control = busy_root.get_child(1)
		card.reset_size()
		card.position = (root.size - card.size) * 0.5
		busy_label.custom_minimum_size.x = 0


func _draw_spin() -> void:
	if busy_root == null or not busy_root.visible:
		return
	var angle := float(busy_root.get_meta("angle", 0.0))
	busy_spin.draw_arc(busy_spin.size * 0.5, 16.0, angle, angle + PI * 1.2, 24, Kit.ACCENT, 3.0, true)
	busy_spin.draw_circle(busy_spin.size * 0.5, 3.0, Kit.ACCENT)


func _build_image_viewer() -> void:
	image_root = Control.new()
	image_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_root.mouse_filter = Control.MOUSE_FILTER_STOP
	image_root.visible = false
	root.add_child(image_root)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.025, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_root.add_child(bg)
	image_texture = TextureRect.new()
	image_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_texture.offset_left = 16
	image_texture.offset_right = -16
	image_texture.offset_top = 76
	image_texture.offset_bottom = -80
	image_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_root.add_child(image_texture)
	image_caption = Kit.label("", 15, Kit.TEXT, 550)
	image_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	image_caption.offset_top = -60
	image_caption.offset_bottom = -24
	image_caption.offset_left = 20
	image_caption.offset_right = -80
	image_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image_root.add_child(image_caption)
	var close := Kit.icon_button("close", 44, 22)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -60
	close.offset_top = 18
	close.offset_right = -16
	close.offset_bottom = 62
	close.pressed.connect(func(): image_root.visible = false)
	image_root.add_child(close)


func open_image_preview(texture: Texture2D, caption: String) -> void:
	image_texture.texture = texture
	image_caption.text = caption
	image_root.visible = true


func set_overlay_state(state: Dictionary) -> void:
	overlay.set_state(state)


func set_zoom(percent: float) -> void:
	zoom_percent = percent


func refresh() -> void:
	if app == null or app.project == null:
		return
	project_title_label.text = app.project.title
	var autosave := bool(app.project.settings.get("autosave", true))
	var status := "Saved"
	if app.dirty:
		status = "Saving…" if autosave else "Unsaved"
	if bool(app.project.settings.get("show_fps", false)):
		status += "  ·  %d fps" % Engine.get_frames_per_second()
	status_label.text = status
	undo_btn.disabled = not app.undo.can_undo()
	redo_btn.disabled = not app.undo.can_redo()
	_set_disabled_glyph(undo_btn, undo_btn.disabled)
	_set_disabled_glyph(redo_btn, redo_btn.disabled)
	var is_3d: bool = app.rig.mode == "3d"
	_style_mode_button(is_3d)
	var mode_label: Label = mode_btn.get_meta("mode_label")
	var mode_icon: Label = mode_btn.get_meta("mode_icon")
	mode_label.text = "3D" if is_3d else "2D"
	mode_label.add_theme_color_override("font_color", Kit.ACCENT if is_3d else Kit.TEXT)
	mode_icon.add_theme_color_override("font_color", Kit.ACCENT if is_3d else Kit.MUTED)
	mode_icon.text = Icons.glyph("view_in_ar")
	for key in rail_buttons.keys():
		Kit.set_active(rail_buttons[key], key == app.active_tool)
	empty_hint.visible = app.project.items.is_empty() and not sheet_root.visible and not onboarding.visible and not busy_root.visible
	_update_tool_bar()


func _set_disabled_glyph(btn: Button, disabled: bool) -> void:
	var glyph: Label = btn.get_meta("glyph", null)
	if glyph != null:
		glyph.modulate.a = 0.32 if disabled else 1.0


func _update_tool_bar() -> void:
	var show: bool = app.active_tool in ["pen", "highlighter"]
	if not show:
		tool_bar.visible = false
		return
	tool_bar.visible = true
	for child in tool_bar_row.get_children():
		child.queue_free()
	var colors := ["#F0F5FF", "#2F5BFF", "#7455FF", "#B8780F", "#E05A44", "#0C8F6A"]
	for hex in colors:
		var dot := Button.new()
		dot.custom_minimum_size = Vector2(28, 28)
		dot.focus_mode = Control.FOCUS_NONE
		dot.add_theme_stylebox_override("normal", Kit.style(Color(hex), 999, Kit.STROKE_STRONG, 1))
		dot.add_theme_stylebox_override("hover", Kit.style(Color(hex), 999, Kit.STROKE_STRONG, 2))
		dot.add_theme_stylebox_override("pressed", Kit.style(Color(hex), 999, Color.WHITE, 2))
		dot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		if app.pen_color.to_upper() == hex.to_upper():
			dot.add_theme_stylebox_override("normal", Kit.style(Color(hex), 999, Kit.ACCENT, 2))
		dot.pressed.connect(func(): app.set_pen_color(hex))
		tool_bar_row.add_child(dot)
	var sep := ColorRect.new()
	sep.color = Kit.STROKE_STRONG
	sep.custom_minimum_size = Vector2(1, 22)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tool_bar_row.add_child(sep)
	var sizes := [1.5, 2.6, 4.0]
	var size_icons := [14, 18, 23]
	for i in range(sizes.size()):
		var btn := Kit.icon_button("line_weight", 30, size_icons[i], is_equal_approx(app.pen_size, sizes[i]))
		btn.pressed.connect(func(): app.set_pen_size(sizes[i]))
		tool_bar_row.add_child(btn)
	var sep2 := ColorRect.new()
	sep2.color = Kit.STROKE_STRONG
	sep2.custom_minimum_size = Vector2(1, 22)
	sep2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tool_bar_row.add_child(sep2)
	var ink3d := Kit.icon_button("view_in_ar", 30, 19, app.ink_3d)
	ink3d.tooltip_text = "Draw on a camera-facing plane in 3D"
	ink3d.pressed.connect(func(): app.toggle_ink_3d())
	tool_bar_row.add_child(ink3d)
	tool_bar.reset_size()
	tool_bar.position.x = (root.size.x - tool_bar.size.x) * 0.5
	tool_bar.position.y = dock.position.y - 62.0


func refresh_selection() -> void:
	var summary: Dictionary = app.get_selection_summary()
	var has: bool = summary.get("count", 0) > 0
	var show: bool = has and app.active_tool == "select" and not sheet_root.visible
	selection_bar.visible = show
	if not show:
		return
	selection_name.text = str(summary.get("title", "Selection"))
	selection_sub.text = str(summary.get("subtitle", ""))
	selection_icon.text = Icons.glyph(str(summary.get("icon", "sticky_note_2")))
	var accent := Color.from_string(str(summary.get("color", "#2F5BFF")), Kit.ACCENT)
	selection_icon.add_theme_color_override("font_color", accent)
	selection_bar.reset_size()
	_layout_selection()


func flash_tool(tool: String) -> void:
	for def in TOOL_DEFS:
		if def[0] == tool:
			toast("%s  ·  %s" % [def[2], def[3]], def[1], Kit.ACCENT, 1.8)
			return


func handle_back() -> bool:
	if image_root.visible:
		image_root.visible = false
		return true
	if modal_root.visible:
		_hide_modal()
		return true
	if sheet_root.visible:
		close_sheet()
		return true
	return false


func relayout() -> void:
	_layout()


func _layout() -> void:
	if root == null:
		return
	var w := root.size.x
	var h := root.size.y
	if w < 10.0 or h < 10.0:
		return
	_did_layout = true
	_compute_safe()
	var lefty := false
	if app != null and app.project != null:
		lefty = bool(app.project.settings.get("left_handed", false))
	if topbar != null:
		topbar.position = Vector2(12, safe_top + 8)
		topbar.size = Vector2(w - 24, TOP_H)
	if rail != null:
		rail.position = Vector2(w - 12 - RAIL_W if lefty else 12, topbar.position.y + TOP_H + 10)
		rail.size = Vector2(RAIL_W, 8 * 44 + 7 * 4 + 12)
	if dock != null:
		dock.reset_size()
		dock.position = Vector2((w - dock.size.x) * 0.5, h - safe_bottom - 28 - dock.size.y)
	if side_panel != null:
		side_panel.reset_size()
		side_panel.position = Vector2(12 if lefty else w - 12 - side_panel.size.x, topbar.position.y + TOP_H + 10)
	if selection_bar != null:
		_layout_selection()
	if tool_bar != null and tool_bar.visible:
		tool_bar.reset_size()
		tool_bar.position = Vector2((w - tool_bar.size.x) * 0.5, dock.position.y - 66)
	if empty_hint != null:
		var empty_x := 76.0
		var empty_top := topbar.position.y + TOP_H + 22.0
		empty_hint.position = Vector2(empty_x, empty_top)
		empty_hint.size = Vector2(w - empty_x - 14.0, maxf(320.0, dock.position.y - empty_top - 20.0))
	if sheet_root != null and sheet_root.visible:
		_sheet_layout()
	if modal_root != null and modal_root.visible:
		modal_panel.reset_size()
		_center_modal()
	if onboarding != null and onboarding.visible:
		onboarding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if toast_panel != null and toast_panel.visible:
		toast_panel.reset_size()
		_center_toast()


func _layout_selection() -> void:
	if selection_bar == null:
		return
	var lefty := false
	if app != null and app.project != null:
		lefty = bool(app.project.settings.get("left_handed", false))
	selection_bar.reset_size()
	selection_bar.position = Vector2(12 if lefty else 76, dock.position.y - selection_bar.size.y - 12)
	selection_bar.size.x = root.size.x - 88
	selection_bar.reset_size()
	selection_bar.size.x = root.size.x - 88


func _sheet_layout() -> void:
	if sheet_panel == null or root == null:
		return
	var w: float = minf(432.0, root.size.x - 12.0)
	var h: float = minf(SHEET_MAX, root.size.y * 0.89)
	sheet_panel.size = Vector2(w, h)
	sheet_panel.position = Vector2((root.size.x - w) * 0.5, root.size.y - h)
	sheet_scroll.custom_minimum_size = Vector2(0, h - 148.0)


func _compute_safe() -> void:
	safe_top = 0.0
	safe_bottom = 0.0
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return
	var safe := DisplayServer.get_display_safe_area()
	var scale := float(win.y) / maxf(1.0, root.size.y)
	safe_top = clampf(float(safe.position.y) / scale, 0.0, 40.0)
	var bottom_px := win.y - (safe.position.y + safe.size.y)
	safe_bottom = clampf(float(bottom_px) / scale, 0.0, 40.0)
	if app != null and app.has_method("get_ad_banner_reserve"):
		safe_bottom += float(app.get_ad_banner_reserve())


func _process(delta: float) -> void:
	if not _did_layout:
		_layout()
	if busy_root != null and busy_root.visible:
		var angle := float(busy_root.get_meta("angle", 0.0)) + delta * 3.2
		busy_root.set_meta("angle", angle)
		busy_spin.queue_redraw()
