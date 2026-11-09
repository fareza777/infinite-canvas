class_name SettingsPanel
extends RefCounted

var ui: GameUI
var app: Node


func _init(p_ui: GameUI, p_app: Node) -> void:
	ui = p_ui
	app = p_app


func build() -> Control:
	var root := _root()
	var s: Dictionary = app.project.settings
	root.add_child(_hero(s))

	root.add_child(_section("Appearance"))
	root.add_child(_segmented("Text size", ["Compact", "Large", "XL"], _text_label(float(s.get("text_scale", 1.12))), func(v): app.set_setting("text_scale", _text_value(v))))
	root.add_child(_segmented("UI theme", ["Light", "Dark", "AMOLED"], str(app.get_ui_theme()).capitalize(), func(v): app.set_ui_theme(v.to_lower())))
	root.add_child(_segmented("Canvas atmosphere", ["Studio", "Warm", "Midnight", "Neon"], str(s.get("look", {}).get("preset", "studio")).capitalize(), func(v): app.apply_look_preset(v.to_lower())))
	root.add_child(Kit.label("Canvas accent", 14, Kit.MUTED, 650))
	root.add_child(_swatches(["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44"], str(s.get("accent", "#2F5BFF")), func(hex): app.set_canvas_accent(hex)))
	root.add_child(_toggle("Reduce motion", "Snap camera moves and skip travel animations", bool(s.get("reduce_motion", false)), func(on): app.set_setting("reduce_motion", on), "bolt"))

	root.add_child(_section("Canvas"))
	root.add_child(_segmented("Grid style", ["Lines", "Dots", "Off"], str(s.get("grid_style", "lines")).capitalize(), func(v): app.set_setting("grid_style", v.to_lower())))
	root.add_child(_toggle("Snap to grid", "Align objects and guides to the grid", bool(s.get("snap", true)), func(on): app.set_setting("snap", on), "grid_4x4"))
	root.add_child(_segmented("Grid size", ["0.5", "1", "2", "5"], _grid_label(float(s.get("grid", 1.0))), func(v): app.set_grid_step(float(v))))
	root.add_child(_segmented("Angle snap", ["15°", "45°"], "45°" if is_equal_approx(float(s.get("snap_angle", 15.0)), 45.0) else "15°", func(v): app.set_snap_angle(float(v.trim_suffix("°")))))
	root.add_child(_toggle("Show links", "Draw the 3D connectors between objects", bool(s.get("show_connectors", true)), func(on): app.set_setting("show_connectors", on), "polyline"))
	root.add_child(_toggle("Performance mode", "Lower scene detail when the board gets dense", bool(s.get("performance_mode", false)), func(on): app.set_setting("performance_mode", on), "speed"))

	root.add_child(_section("Tools"))
	root.add_child(_segmented("Default tool", ["Select", "Pen", "Note"], str(s.get("default_tool", "select")).capitalize(), func(v): app.set_setting("default_tool", v.to_lower())))
	root.add_child(_toggle("Stylus pressure", "Vary ink width with pen pressure", bool(s.get("pressure", true)), func(on): app.set_setting("pressure", on), "stylus"))
	root.add_child(_toggle("Haptics", "Small vibrations on tools and actions", bool(s.get("haptics", true)), func(on): app.set_setting("haptics", on), "phone_android"))
	root.add_child(_toggle("Left-handed layout", "Move the tool rail and controls to the other side", bool(s.get("left_handed", false)), func(on): app.set_setting("left_handed", on), "pan_tool_alt"))

	root.add_child(_section("Editor"))
	root.add_child(_toggle("Autosave", "Save quietly while you work", bool(s.get("autosave", true)), func(on): app.set_setting("autosave", on), "save"))
	root.add_child(_segmented("Autosave delay", ["Instant", "5s", "10s"], _delay_label(float(s.get("autosave_delay", 1.2))), func(v): app.set_setting("autosave_delay", _delay_value(v))))
	root.add_child(_segmented("Undo history", ["30", "60", "120"], str(int(s.get("undo_limit", 60))), func(v): app.set_setting("undo_limit", int(v))))
	root.add_child(_toggle("Keep the screen awake", "Prevent the display from sleeping while the board is open", bool(s.get("keep_awake", false)), func(on): app.set_setting("keep_awake", on), "light_mode"))
	root.add_child(_toggle("Show FPS", "Display the live frame rate in the top bar", bool(s.get("show_fps", false)), func(on): app.set_setting("show_fps", on), "speed"))
	root.add_child(_toggle("Confirm before delete", "Ask before removing selected objects", bool(s.get("confirm_delete", false)), func(on): app.set_setting("confirm_delete", on), "delete"))

	root.add_child(_section("Ads & support"))
	root.add_child(_ads_card())
	if not app.has_removed_ads():
		root.add_child(_row("block", "Remove Ads  ·  %s" % app.get_remove_ads_price(), "Permanently remove banner, interstitial and rewarded ads", func(): app.purchase_remove_ads(), "BUY", Kit.GOLD))
		root.add_child(_row("restore", "Restore purchase", "Check this Google Play account for Remove Ads", func(): app.restore_purchases(), "", Kit.ACCENT))
		root.add_child(_row("redeem", "Watch a rewarded ad", "Optional · remove banner and interstitial ads for 24 hours", func(): app.watch_rewarded_ad(), "24H", Kit.GREEN))
		if not app.is_ad_free():
			root.add_child(_row("play_circle", "Watch a short ad", "Support the studio with an interstitial", func(): app.show_interstitial_ad(), "AD", Kit.ACCENT))
		root.add_child(Kit.wrapped(app.get_billing_message(), 13, Kit.DIM, 450))
	if app.needs_privacy_options():
		root.add_child(_row("tune", "Privacy options", "Review or change your ad consent choices", func(): app.show_privacy_options(), "", Kit.VIOLET))

	root.add_child(_section("Data"))
	root.add_child(_storage_card())
	root.add_child(_row("save", "Save now", "Write the board and a restore point", func(): app.save_now(); app.create_restore_point(); ui.toast("Saved with a restore point", "save", Kit.GREEN), "SAVE", Kit.GREEN))
	var board_count: int = int(app.get_projects().size())
	root.add_child(_row("folder_open", "Projects", "%d %s on this device" % [board_count, "board" if board_count == 1 else "boards"], func(): ui.open_sheet("projects"), "", Kit.ACCENT))
	root.add_child(_row("ios_share", "Export", "PNG, project, Markdown, GLB or ZIP", func(): ui.open_sheet("export"), "", Kit.VIOLET))
	root.add_child(_row("archive", "Backup now", "Save a portable ZIP with all media", func(): app.create_backup(), "", Kit.GOLD))
	root.add_child(_row("restore", "Restore from file", "Open a previous backup or board", func(): app.restore_backup(), "", Kit.GOLD))
	root.add_child(_row("history", "Restore points", "Browse autosaved snapshots of this board", func(): ui.open_sheet("restore_points"), "", Kit.ACCENT))
	root.add_child(_row("delete", "Clear export cache", "Remove temporary exported files", func(): ui.confirm("Clear export cache?", "This only removes generated exports, not your boards.", func(): app.clear_exports()), "", Kit.DANGER))

	root.add_child(_section("Support"))
	root.add_child(_row("help", "Help & gestures", "Shortcuts, gestures and a quick tour", func(): ui.open_sheet("help"), "", Kit.ACCENT))
	root.add_child(_row("info", "About", "Version, engine, privacy and credits", func(): ui.open_sheet("about"), "", Kit.ACCENT))
	root.add_child(_row("share", "Share the app", "Send an invite to a friend", func(): app.share_app(), "", Kit.GREEN))
	root.add_child(_row("star", "Rate on Google Play", "Tell others what you built", func(): app.rate_app(), "", Kit.GOLD))
	root.add_child(_row("article", "Privacy policy", "How ads, purchases and on-device data are handled", func(): app.open_privacy_policy(), "", Kit.VIOLET))
	root.add_child(_row("shield", "Licences", "Ads, Billing and open-source details", func(): ui.open_sheet("about"), "", Kit.VIOLET))
	root.add_child(Kit.label("v%s · Godot 4.7.2" % str(ProjectSettings.get_setting("application/config/version", "3.3.0")), 12, Kit.DIM, 500, "mono"))
	return root


func _ads_card() -> Control:
	var panel := Kit.panel(Kit.SURFACE_2, 16, Kit.STROKE, 1, 14)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var ad_free: bool = bool(app.is_ad_free())
	h.add_child(Kit.icon("block" if app.has_removed_ads() else ("shield" if ad_free else "campaign"), 22, Kit.GREEN if ad_free else Kit.GOLD, 1.0))
	h.add_child(Kit.label("Ads removed" if app.has_removed_ads() else ("Ad-free" if ad_free else "Ad-supported"), 17, Kit.TEXT, 650))
	var status := Kit.wrapped(app.get_ad_status_text(), 14, Kit.MUTED, 450)
	v.add_child(status)
	if app.has_removed_ads():
		v.add_child(Kit.label("Remove Ads purchased · thank you for supporting the studio", 12, Kit.GREEN, 500))
	return panel


func build_restore_points() -> Control:
	var root := _root()
	var save := Kit.button("Create a restore point now", "restore", true, 54, 20)
	save.pressed.connect(func():
		app.create_restore_point()
		ui.reload_sheet()
	)
	root.add_child(save)
	var points: Array = app.get_autosaves()
	if points.is_empty():
		root.add_child(_empty("No restore points yet", "Autosave is on. A snapshot is kept while you work, and you can also create one above.", "restore"))
		return root
	for p in points:
		var row := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
		root.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		h.add_child(Kit.icon("history", 22, Kit.ACCENT, 1.0))
		var tb := VBoxContainer.new()
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tb)
		var stamp := int(p.get("timestamp", 0))
		var when := Time.get_datetime_string_from_unix_time(stamp, true) if stamp > 0 else str(p.get("filename", "Snapshot"))
		tb.add_child(Kit.label(when, 14, Kit.TEXT, 600))
		tb.add_child(Kit.label(app.format_bytes(int(p.get("size", 0))), 12, Kit.MUTED, 500, "mono"))
		var restore := Kit.button("Restore", "", false, 38, 16)
		var point_path := str(p.get("path", ""))
		restore.pressed.connect(func():
			ui.confirm("Restore this snapshot?", "The current board will be replaced. You can still undo the change before saving over it.", func(): app.restore_autosave(point_path))
		)
		h.add_child(restore)
	return root


func _root() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box


func _hero(s: Dictionary) -> Control:
	var panel := Kit.panel(Kit.SURFACE_2, 18, Kit.STROKE, 1, 14)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icon_192.png")
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(icon)
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_constant_override("separation", 2)
	h.add_child(tb)
	tb.add_child(Kit.label("Studio settings", 20, Kit.TEXT, 700, "display"))
	tb.add_child(Kit.wrapped("%s theme · %s stored · v%s" % [str(app.get_ui_theme()).capitalize(), app.format_bytes(app.get_storage_used()), str(ProjectSettings.get_setting("application/config/version", "3.3.0"))], 13, Kit.MUTED, 500))
	var dot := Kit.chip(str(app.get_ui_theme()).to_upper(), Kit.ACCENT, 12)
	h.add_child(dot)
	return panel


func _section(text: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(Kit.label(text.to_upper(), 13, Kit.MUTED, 700, "mono"))
	v.add_child(Kit.divider())
	return v


func _segmented(title: String, options: Array, selected: String, callback: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.add_child(Kit.label(title, 15, Kit.MUTED, 650))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	box.add_child(row)
	var buttons := []
	for opt in options:
		var label := str(opt)
		var b := Button.new()
		b.text = label
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		b.clip_text = true
		b.add_theme_font_override("font", AppFonts.body(600))
		b.add_theme_font_size_override("font_size", Kit.px(14))
		buttons.append(b)
		row.add_child(b)
		_style_choice(b, label.to_lower() == selected.to_lower())
		b.pressed.connect(func():
			for other in buttons:
				_style_choice(other, other == b)
			callback.call(label)
		)
	return box


func _style_choice(b: Button, active: bool) -> void:
	b.add_theme_color_override("font_color", Kit.ON_ACCENT if active else Kit.TEXT)
	var normal := Kit.style(Kit.ACCENT if active else Kit.SURFACE_2, 12, Kit.ACCENT if active else Kit.STROKE, 1, 0)
	var hover := Kit.style(Kit.ACCENT_DEEP if active else Kit.HOVER, 12, Kit.ACCENT if active else Kit.STROKE_STRONG, 1, 0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _toggle(title: String, subtitle: String, active: bool, callback: Callable, icon_name := "") -> PanelContainer:
	var panel := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	if not icon_name.is_empty():
		h.add_child(_icon_tile(icon_name, Kit.ACCENT, 38, 22))
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_constant_override("separation", 1)
	h.add_child(tb)
	tb.add_child(Kit.label(title, 17, Kit.TEXT, 650))
	tb.add_child(Kit.wrapped(subtitle, 14, Kit.MUTED, 430))
	var state := {"on": active}
	var toggle := Button.new()
	toggle.custom_minimum_size = Vector2(72, 42)
	toggle.focus_mode = Control.FOCUS_NONE
	var paint := func():
		var on: bool = state["on"]
		toggle.text = "ON" if on else "OFF"
		toggle.add_theme_color_override("font_color", Kit.ON_ACCENT if on else Kit.MUTED)
		toggle.add_theme_font_override("font", AppFonts.body(700))
		toggle.add_theme_font_size_override("font_size", Kit.px(13))
		toggle.add_theme_stylebox_override("normal", Kit.style(Kit.ACCENT if on else Kit.SURFACE, 12, Kit.ACCENT if on else Kit.STROKE, 1, 0))
		toggle.add_theme_stylebox_override("hover", Kit.style(Kit.ACCENT_DEEP if on else Kit.HOVER, 12))
		toggle.add_theme_stylebox_override("pressed", Kit.style(Kit.ACCENT_DEEP if on else Kit.PRESSED, 12))
	paint.call()
	toggle.pressed.connect(func():
		state["on"] = not bool(state["on"])
		paint.call()
		callback.call(state["on"])
	)
	h.add_child(toggle)
	return panel


func _row(icon_name: String, title: String, subtitle: String, callback: Callable, right_text := "", accent := Kit.ACCENT) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 100)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Kit.style(Kit.SURFACE_2, 15, Kit.STROKE, 1, 0))
	b.add_theme_stylebox_override("hover", Kit.style(Kit.HOVER, 15, Color(accent.r, accent.g, accent.b, 0.35), 1))
	b.add_theme_stylebox_override("pressed", Kit.style(Kit.SURFACE, 15, Color(accent.r, accent.g, accent.b, 0.5), 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(callback)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	b.add_child(margin)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(h)
	h.add_child(_icon_tile(icon_name, accent, 38, 22))
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_constant_override("separation", 1)
	tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tb)
	tb.add_child(Kit.label(title, 18, Kit.TEXT, 650))
	if not subtitle.is_empty():
		var sub := Kit.wrapped(subtitle, 14, Kit.MUTED, 450)
		sub.max_lines_visible = 2
		tb.add_child(sub)
	if not right_text.is_empty():
		h.add_child(Kit.label(right_text, 12, accent, 700, "mono"))
	h.add_child(Kit.icon("chevron_right", 20, Kit.DIM, 0.0))
	return b


func _icon_tile(name: String, color: Color, dim: int, icon_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(dim, dim)
	panel.add_theme_stylebox_override("panel", Kit.style(Color(color.r, color.g, color.b, 0.12), 11, Color(color.r, color.g, color.b, 0.30), 1, 0))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Kit.icon(name, icon_size, color, 1.0)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(ic)
	return panel


func _swatches(colors: Array, selected: String, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	for hex in colors:
		var c := Color.from_string(str(hex), Kit.ACCENT)
		var b := Button.new()
		b.custom_minimum_size = Vector2(36, 36)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Kit.style(c, 999, Kit.STROKE_STRONG, 1, 0))
		b.add_theme_stylebox_override("hover", Kit.style(c, 999, Kit.TEXT, 2, 0))
		b.add_theme_stylebox_override("pressed", Kit.style(c, 999, Kit.ON_ACCENT, 2, 0))
		var chosen := str(hex).to_upper() == selected.to_upper()
		if chosen:
			b.add_theme_stylebox_override("normal", Kit.style(c, 999, Kit.ON_ACCENT, 2, 0))
			var check_color := Color("#17203A") if c.get_luminance() > 0.45 else Kit.ON_ACCENT
			var check := Kit.icon("check", 18, check_color, 1.0)
			check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			b.add_child(check)
		b.pressed.connect(func(): on_pick.call(str(hex)))
		row.add_child(b)
	return row


func _storage_card() -> Control:
	var panel := Kit.panel(Kit.SURFACE_2, 14, Kit.STROKE, 1, 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	h.add_child(Kit.icon("database", 22, Kit.ACCENT, 1.0))
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tb)
	tb.add_child(Kit.label("Local storage", 17, Kit.TEXT, 650))
	tb.add_child(Kit.wrapped("%s used · projects, media and restore points" % app.format_bytes(app.get_storage_used()), 14, Kit.MUTED, 450))
	h.add_child(Kit.label(str(app.get_projects().size()), 20, Kit.ACCENT, 700, "mono"))
	return panel


func _empty(title: String, subtitle: String, icon_name: String) -> Control:
	var box := Kit.panel(Kit.SURFACE_2, 16, Kit.STROKE, 1, 18)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	v.add_child(Kit.icon(icon_name, 32, Kit.ACCENT, 1.0))
	v.add_child(Kit.label(title, 18, Kit.TEXT, 650))
	v.add_child(Kit.wrapped(subtitle, 14, Kit.MUTED, 450))
	return box


func _text_label(scale: float) -> String:
	if scale < 1.06:
		return "Compact"
	if scale > 1.18:
		return "XL"
	return "Large"


func _text_value(label: String) -> float:
	match label:
		"Compact":
			return 1.0
		"XL":
			return 1.24
		_:
			return 1.12


func _grid_label(value: float) -> String:
	if is_equal_approx(value, 0.5):
		return "0.5"
	if is_equal_approx(value, 2.0):
		return "2"
	if is_equal_approx(value, 5.0):
		return "5"
	return "1"


func _delay_label(value: float) -> String:
	if value >= 9.0:
		return "10s"
	if value >= 4.0:
		return "5s"
	return "Instant"


func _delay_value(label: String) -> float:
	match label:
		"5s":
			return 5.0
		"10s":
			return 10.0
		_:
			return 1.2
