class_name Kit
extends RefCounted

# Theme tokens. Light is the default porcelain studio; Dark and AMOLED are
# selectable in Settings. The UI is rebuilt when the theme changes.
static var BG := Color("#F2EFE8")
static var BG_2 := Color("#E9E4D9")
static var SURFACE := Color("#FFFFFF")
static var SURFACE_2 := Color("#F8F5EF")
static var SURFACE_3 := Color("#EFEAE1")
static var GLASS := Color(1.0, 1.0, 1.0, 0.91)
static var HOVER := Color(0.09, 0.13, 0.22, 0.06)
static var PRESSED := Color(0.09, 0.13, 0.22, 0.11)
static var STROKE := Color(0.09, 0.13, 0.22, 0.10)
static var STROKE_STRONG := Color(0.09, 0.13, 0.22, 0.18)
static var TEXT := Color("#162033")
static var MUTED := Color("#5D687A")
static var DIM := Color("#8B95A6")
static var ACCENT := Color("#2F5BFF")
static var ACCENT_DEEP := Color("#1F42D6")
static var ON_ACCENT := Color("#FFFFFF")
static var VIOLET := Color("#7455FF")
static var VIOLET_DEEP := Color("#5B3EE8")
static var GOLD := Color("#B8780F")
static var GREEN := Color("#0C8F6A")
static var DANGER := Color("#D84357")
static var SCRIM := Color(0.06, 0.09, 0.15, 0.36)
static var SHADOW := Color(0.09, 0.13, 0.22, 0.14)
static var GRAD_C := Color("#202A6E")
static var THEME_NAME := "light"
const NOTE_COLORS := ["#FFFDF8", "#F4F8FF", "#F7F1FF", "#EFFBF5", "#FFF4EA", "#FFF0F3"]
const ACCENTS := ["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#162033"]

static var TYPE_SCALE := 1.12

static var _theme: Theme


static func apply_theme(name: String) -> void:
	match name:
		"dark":
			THEME_NAME = "dark"
			BG = Color("#0A0F18")
			BG_2 = Color("#0F1622")
			SURFACE = Color("#141D2B")
			SURFACE_2 = Color("#1A2535")
			SURFACE_3 = Color("#223044")
			GLASS = Color(0.055, 0.075, 0.11, 0.94)
			HOVER = Color(1, 1, 1, 0.06)
			PRESSED = Color(1, 1, 1, 0.11)
			STROKE = Color(1, 1, 1, 0.09)
			STROKE_STRONG = Color(1, 1, 1, 0.16)
			TEXT = Color("#F3F7FF")
			MUTED = Color("#AAB7C9")
			DIM = Color("#78879B")
			ACCENT = Color("#6E8DFF")
			ACCENT_DEEP = Color("#4E6EF0")
			ON_ACCENT = Color("#08101F")
			VIOLET = Color("#A58BFF")
			VIOLET_DEEP = Color("#8568F4")
			GOLD = Color("#F2C66B")
			GREEN = Color("#6BE5BB")
			DANGER = Color("#FF8A9C")
			SCRIM = Color(0, 0, 0, 0.62)
			SHADOW = Color(0, 0, 0, 0.40)
			GRAD_C = Color("#0B1740")
		"amoled":
			THEME_NAME = "amoled"
			BG = Color("#000000")
			BG_2 = Color("#05070C")
			SURFACE = Color("#090E16")
			SURFACE_2 = Color("#0F1620")
			SURFACE_3 = Color("#17212E")
			GLASS = Color(0.01, 0.015, 0.025, 0.96)
			HOVER = Color(1, 1, 1, 0.06)
			PRESSED = Color(1, 1, 1, 0.11)
			STROKE = Color(1, 1, 1, 0.08)
			STROKE_STRONG = Color(1, 1, 1, 0.15)
			TEXT = Color("#F4F8FF")
			MUTED = Color("#A3B0C4")
			DIM = Color("#6E7D92")
			ACCENT = Color("#6F8DFF")
			ACCENT_DEEP = Color("#4A67E8")
			ON_ACCENT = Color("#050A12")
			VIOLET = Color("#A78BFF")
			VIOLET_DEEP = Color("#8568F4")
			GOLD = Color("#F3C86A")
			GREEN = Color("#69E3B7")
			DANGER = Color("#FF8194")
			SCRIM = Color(0, 0, 0, 0.70)
			SHADOW = Color(0, 0, 0, 0.50)
			GRAD_C = Color("#050C24")
		_:
			THEME_NAME = "light"
			BG = Color("#F2EFE8")
			BG_2 = Color("#E9E4D9")
			SURFACE = Color("#FFFFFF")
			SURFACE_2 = Color("#F8F5EF")
			SURFACE_3 = Color("#EFEAE1")
			GLASS = Color(1.0, 1.0, 1.0, 0.91)
			HOVER = Color(0.09, 0.13, 0.22, 0.06)
			PRESSED = Color(0.09, 0.13, 0.22, 0.11)
			STROKE = Color(0.09, 0.13, 0.22, 0.10)
			STROKE_STRONG = Color(0.09, 0.13, 0.22, 0.18)
			TEXT = Color("#162033")
			MUTED = Color("#5D687A")
			DIM = Color("#8B95A6")
			ACCENT = Color("#2F5BFF")
			ACCENT_DEEP = Color("#1F42D6")
			ON_ACCENT = Color("#FFFFFF")
			VIOLET = Color("#7455FF")
			VIOLET_DEEP = Color("#5B3EE8")
			GOLD = Color("#B8780F")
			GREEN = Color("#0C8F6A")
			DANGER = Color("#D84357")
			SCRIM = Color(0.06, 0.09, 0.15, 0.36)
			SHADOW = Color(0.09, 0.13, 0.22, 0.14)
			GRAD_C = Color("#202A6E")
	_theme = null


static func px(size: float, minimum := 12.0) -> int:
	return int(round(maxf(size, minimum) * TYPE_SCALE))


static func set_type_scale(scale: float) -> void:
	TYPE_SCALE = clampf(scale, 0.9, 1.35)
	_theme = null


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = AppFonts.body(500)
	t.default_font_size = px(18)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_font("font", "Label", AppFonts.body(500))
	t.set_font_size("font_size", "Label", px(18))
	t.set_color("font_color", "Button", TEXT)
	t.set_font("font", "Button", AppFonts.body(600))
	t.set_font_size("font_size", "Button", px(17))
	t.set_stylebox("normal", "Button", style(Color(0, 0, 0, 0), 15))
	t.set_stylebox("hover", "Button", style(HOVER, 15))
	t.set_stylebox("pressed", "Button", style(PRESSED, 15))
	t.set_stylebox("disabled", "Button", style(Color(0, 0, 0, 0), 15))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_disabled_color", "Button", Color(TEXT.r, TEXT.g, TEXT.b, 0.30))
	t.set_font("font", "LineEdit", AppFonts.body(500))
	t.set_font_size("font_size", "LineEdit", px(17))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(MUTED.r, MUTED.g, MUTED.b, 0.85))
	t.set_color("caret_color", "LineEdit", ACCENT)
	t.set_color("selection_color", "LineEdit", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18))
	t.set_stylebox("normal", "LineEdit", style(SURFACE_2, 15, STROKE, 1, 14))
	t.set_stylebox("focus", "LineEdit", style(SURFACE, 15, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55), 1, 14))
	t.set_stylebox("read_only", "LineEdit", style(SURFACE_2, 15, STROKE, 1, 14))
	t.set_font("font", "TextEdit", AppFonts.body(450))
	t.set_font_size("font_size", "TextEdit", px(17))
	t.set_color("font_color", "TextEdit", TEXT)
	t.set_color("caret_color", "TextEdit", ACCENT)
	t.set_color("selection_color", "TextEdit", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.16))
	t.set_stylebox("normal", "TextEdit", style(SURFACE_2, 15, STROKE, 1, 14))
	t.set_stylebox("focus", "TextEdit", style(SURFACE, 15, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55), 1, 14))
	t.set_stylebox("read_only", "TextEdit", style(SURFACE_2, 15, STROKE, 1, 14))
	t.set_color("font_readonly_color", "TextEdit", Color(TEXT.r, TEXT.g, TEXT.b, 0.86))
	t.set_stylebox("panel", "PanelContainer", style(SURFACE, 20, STROKE, 1, 0, 12))
	t.set_stylebox("panel", "ColorRect", StyleBoxEmpty.new())
	t.set_stylebox("panel", "Panel", style(SURFACE, 20, STROKE, 1, 0, 12))
	t.set_stylebox("panel", "PopupMenu", style(SURFACE, 18, STROKE_STRONG, 1, 10, 22))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_font("font", "PopupMenu", AppFonts.body(500))
	t.set_font_size("font_size", "PopupMenu", px(16))
	t.set_color("font_hover_color", "PopupMenu", TEXT)
	t.set_stylebox("hover", "PopupMenu", style(HOVER, 10, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("separator", "PopupMenu", style(STROKE, 1))
	t.set_stylebox("grabber", "VScrollBar", style(Color(TEXT.r, TEXT.g, TEXT.b, 0.18), 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", style(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55), 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", style(ACCENT, 4))
	t.set_stylebox("scroll", "VScrollBar", style(Color(TEXT.r, TEXT.g, TEXT.b, 0.05), 4))
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 12)
	t.set_stylebox("panel", "TooltipPanel", style(SURFACE, 14, STROKE_STRONG, 1, 12, 16))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", px(14))
	t.set_font("font", "TooltipLabel", AppFonts.body(500))
	_theme = t
	return t


static func style(bg: Color, radius := 18, border := Color(0, 0, 0, 0), border_w := 0, pad := 0, shadow := 0, shadow_color := Color(0, 0, 0, 0.45)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if border_w > 0:
		sb.border_color = border
		sb.border_width_left = border_w
		sb.border_width_top = border_w
		sb.border_width_right = border_w
		sb.border_width_bottom = border_w
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	if shadow > 0:
		sb.shadow_color = shadow_color
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 0.9
	return sb


static func label(text: String, size := 18, color := TEXT, weight := 500, kind := "body") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", AppFonts.font(kind, weight))
	l.add_theme_font_size_override("font_size", px(size, 12.0))
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func display_label(text: String, size := 32, color := TEXT, weight := 700) -> Label:
	return label(text, px(size, 22.0), color, weight, "display")


static func wrapped(text: String, size := 15, color := MUTED, weight := 450) -> Label:
	var l := label(text, px(size, 13.0), color, weight)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(140, 0)
	return l


static func icon(name: String, size := 24, color := TEXT, fill := 0.0, weight := 400.0) -> Label:
	var l := Label.new()
	l.text = Icons.glyph(name)
	l.add_theme_font_override("font", AppFonts.icon_font(fill, weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func panel(bg := SURFACE, radius := 20, border := STROKE, border_w := 1, pad := 16, shadow := 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, radius, border, border_w, pad, shadow))
	return p


static func glass(radius := 20, pad := 14, bg := GLASS) -> PanelContainer:
	return panel(bg, radius, STROKE, 1, pad, 18)


static func gradient(a := ACCENT, b := VIOLET, radius := 18.0, sheen := 0.5) -> GradientPanel:
	var gp := GradientPanel.new()
	gp.setup(a, b, GRAD_C, radius, 0.0, sheen)
	gp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gp


static func icon_button(name: String, dim := 46, icon_size := 23, active := false, fill := 0.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(dim, dim)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _icon_bg(active, false))
	b.add_theme_stylebox_override("hover", _icon_bg(active, true))
	b.add_theme_stylebox_override("pressed", _icon_bg(true, true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var glyph := icon(name, icon_size, ON_ACCENT if active else TEXT, 1.0 if active else fill)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(glyph)
	b.set_meta("glyph", glyph)
	b.set_meta("icon_name", name)
	return b


static func _icon_bg(active: bool, hover: bool) -> StyleBoxFlat:
	if active:
		return style(ACCENT_DEEP if hover else ACCENT, 15, Color(0, 0, 0, 0), 0, 0, 8, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.20))
	if hover:
		return style(HOVER, 15)
	return style(Color(0, 0, 0, 0), 15)


static func set_active(button: Button, active: bool) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _icon_bg(active, false))
	button.add_theme_stylebox_override("hover", _icon_bg(active, true))
	var glyph: Label = button.get_meta("glyph", null)
	if glyph != null:
		glyph.add_theme_color_override("font_color", ON_ACCENT if active else TEXT)
		var font := AppFonts.icon_font(1.0 if active else 0.0, 400.0)
		glyph.add_theme_font_override("font", font)


static func button(text: String, icon_name := "", primary := false, height := 52, icon_size := 21, align := BoxContainer.ALIGNMENT_CENTER) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new() if primary else style(Color(0, 0, 0, 0), 15, STROKE, 1))
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new() if primary else style(HOVER, 15, STROKE, 1))
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new() if primary else style(PRESSED, 15, STROKE, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var gradient_bg: GradientPanel = null
	if primary:
		gradient_bg = gradient(ACCENT, VIOLET, 15.0, 0.75)
		gradient_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(gradient_bg)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.offset_right = -20
	row.alignment = align
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	if not icon_name.is_empty():
		var ic := icon(icon_name, px(icon_size, 18.0), ON_ACCENT if primary else TEXT)
		row.add_child(ic)
		b.set_meta("button_icon", ic)
	var button_px := px(17, 15)
	var lbl := label(text, button_px / TYPE_SCALE, ON_ACCENT if primary else TEXT, 650 if primary else 550)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if align == BoxContainer.ALIGNMENT_BEGIN else HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var lbl_font := AppFonts.font("body", 650 if primary else 550)
	var measured := lbl_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, button_px)
	lbl.custom_minimum_size = Vector2(minf(measured.x + 2.0, 340.0), 0)
	var min_width := measured.x + 42.0
	if not icon_name.is_empty():
		min_width += float(px(icon_size, 18.0)) + 10.0
	min_width = minf(min_width, 390.0)
	b.custom_minimum_size = Vector2(min_width, height)
	row.add_child(lbl)
	b.set_meta("button_label", lbl)
	if primary:
		b.button_down.connect(func():
			if gradient_bg != null:
				gradient_bg.modulate = Color(1.12, 1.12, 1.12)
		)
		b.button_up.connect(func():
			if gradient_bg != null:
				gradient_bg.modulate = Color.WHITE
		)
	return b


static func chip(text: String, color := ACCENT, size := 13) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(color.r, color.g, color.b, 0.11), 999, Color(color.r, color.g, color.b, 0.32), 1, 8))
	var l := label(text, size, color, 650)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


static func badge(text: String, color := GOLD) -> PanelContainer:
	var p := chip(text, color, 11)
	p.add_theme_stylebox_override("panel", style(Color(color.r, color.g, color.b, 0.14), 8, Color(color.r, color.g, color.b, 0.38), 1, 5))
	return p


static func divider(color := STROKE) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = color
	cr.custom_minimum_size = Vector2(0, 1)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cr


static func vertical_gap(height := 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func horizontal_gap(width := 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func section_heading(eyebrow: String, title: String, subtitle := "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if not eyebrow.is_empty():
		var e := label(eyebrow.to_upper(), 11, ACCENT, 700, "mono")
		e.add_theme_constant_override("outline_size", 0)
		box.add_child(e)
	var t := display_label(title, 26, TEXT, 700)
	box.add_child(t)
	if not subtitle.is_empty():
		var s := wrapped(subtitle, 14, MUTED, 450)
		box.add_child(s)
	return box


static func field(label_text: String, placeholder := "", multiline := false) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.add_child(label(label_text, 14, MUTED, 600))
	if multiline:
		var te := TextEdit.new()
		te.placeholder_text = placeholder
		te.custom_minimum_size = Vector2(0, 112)
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		box.add_child(te)
	else:
		var le := LineEdit.new()
		le.placeholder_text = placeholder
		le.custom_minimum_size = Vector2(0, 54)
		box.add_child(le)
	return box


static func scroll() -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc
