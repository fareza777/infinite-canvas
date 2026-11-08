class_name AppFonts
extends RefCounted

const SORA_PATH := "res://assets/fonts/Sora.ttf"
const INTER_PATH := "res://assets/fonts/Inter.ttf"
const MONO_PATH := "res://assets/fonts/JetBrainsMono.ttf"
const ICON_PATH := "res://assets/fonts/MaterialSymbolsSubset.ttf"

static var _files: Dictionary = {}
static var _variations: Dictionary = {}
static var _configured := false


static func _base(path: String) -> FontFile:
	if _files.has(path):
		return _files[path]
	var font: FontFile = load(path)
	if font != null:
		font.multichannel_signed_distance_field = true
		font.msdf_pixel_range = 8
		font.msdf_size = 48
		font.allow_system_fallback = true
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		font.generate_mipmaps = false
	_files[path] = font
	return font


static func font(kind := "body", weight := 500) -> FontVariation:
	var key := "%s_%s" % [kind, str(weight)]
	if _variations.has(key):
		return _variations[key]
	var path := INTER_PATH
	if kind == "display":
		path = SORA_PATH
	elif kind == "mono":
		path = MONO_PATH
	elif kind == "icon":
		path = ICON_PATH
	var base := _base(path)
	var variation := FontVariation.new()
	variation.base_font = base
	variation.variation_opentype = {"wght": float(weight)}
	_variations[key] = variation
	return variation


static func icon_font(fill := 0.0, weight := 400.0) -> FontVariation:
	var key := "icon_%s_%s" % [str(fill), str(weight)]
	if _variations.has(key):
		return _variations[key]
	var variation := FontVariation.new()
	variation.base_font = _base(ICON_PATH)
	variation.variation_opentype = {
		"FILL": float(fill),
		"wght": float(weight),
		"GRAD": 0.0,
		"opsz": 24.0,
	}
	_variations[key] = variation
	return variation


static func display(weight := 700) -> FontVariation:
	return font("display", weight)


static func body(weight := 500) -> FontVariation:
	return font("body", weight)


static func mono(weight := 500) -> FontVariation:
	return font("mono", weight)


static func label_font(size := 18, weight := 500, kind := "body") -> Font:
	return font(kind, weight)
