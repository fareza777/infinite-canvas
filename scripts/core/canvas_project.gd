class_name CanvasProject
extends RefCounted

const FORMAT_VERSION := 3
const ITEM_TYPES := ["note", "text", "image", "pdf", "model", "primitive", "shape", "frame", "group", "stroke"]

var id := ""
var title := "Untitled Board"
var created_at := 0.0
var updated_at := 0.0
var layers: Array = []
var items: Array = []
var connectors: Array = []
var bookmarks: Array = []
var storyboard: Dictionary = {}
var settings: Dictionary = {}
var camera: Dictionary = {}
var active_layer_id := ""
var meta: Dictionary = {}


static func gen_id(prefix: String) -> String:
	return "%s_%s%s" % [prefix, str(Time.get_unix_time_from_system()).replace(".", ""), str(randi_range(100, 999))]


static func create(project_title := "Untitled Board") -> CanvasProject:
	var p := CanvasProject.new()
	p.id = gen_id("prj")
	p.title = project_title
	p.created_at = Time.get_unix_time_from_system()
	p.updated_at = p.created_at
	p.layers = [
		p._make_layer("lyr_ink", "Ink", "#2F5BFF"),
		p._make_layer("lyr_ideas", "Ideas", "#7455FF"),
		p._make_layer("lyr_objects", "Objects", "#B8780F"),
	]
	p.active_layer_id = "lyr_ideas"
	p.settings = {
		"snap": true,
		"grid": 1.0,
		"snap_angle": 15.0,
		"show_grid": true,
		"grid_style": "lines",
		"show_connectors": true,
		"performance_mode": false,
		"onboarded": false,
		"pen_color": "#2F5BFF",
		"pen_size": 2.4,
		"pen_kind": "pen",
		"last_tool": "select",
		"default_tool": "select",
		"show_help_hints": true,
		"haptics": true,
		"pressure": true,
		"autosave": true,
		"autosave_delay": 1.2,
		"reduce_motion": false,
		"left_handed": false,
		"show_fps": false,
		"keep_awake": false,
		"confirm_delete": false,
		"undo_limit": 60,
		"text_scale": 1.12,
		"accent": "#2F5BFF",
		"look": {"preset": "studio", "key_energy": 1.15, "ambient": 0.68},
	}
	p.storyboard = {"frames": [], "current": 0, "autoplay": false}
	p.camera = {"pivot": [0.0, 0.0, 0.0], "view_height": 22.0, "yaw": 0.0, "pitch": 0.0}
	return p


func _make_layer(layer_id: String, layer_name: String, color: String) -> Dictionary:
	return {"id": layer_id, "name": layer_name, "color": color, "visible": true, "locked": false}


func touch() -> void:
	updated_at = Time.get_unix_time_from_system()


func add_layer(layer_name: String, color := "#5BE7FF") -> Dictionary:
	var layer := _make_layer(gen_id("lyr"), layer_name, color)
	layers.append(layer)
	active_layer_id = layer.id
	touch()
	return layer


func get_layer(layer_id: String) -> Dictionary:
	for layer in layers:
		if layer.get("id", "") == layer_id:
			return layer
	return {}


func active_layer() -> Dictionary:
	var layer := get_layer(active_layer_id)
	if layer.is_empty() and not layers.is_empty():
		layer = layers[0]
		active_layer_id = layer.get("id", "")
	return layer


func is_layer_visible(layer_id: String) -> bool:
	var layer := get_layer(layer_id)
	return layer.is_empty() or layer.get("visible", true)


func is_layer_locked(layer_id: String) -> bool:
	var layer := get_layer(layer_id)
	return not layer.is_empty() and layer.get("locked", false)


func add_item(type: String, pos: Vector3, props := {}, layer_id := "", parent_id := "") -> Dictionary:
	var resolved_layer := layer_id
	if resolved_layer.is_empty():
		resolved_layer = active_layer_id
	var item := {
		"id": gen_id("it"),
		"type": type,
		"layer": resolved_layer,
		"parent": parent_id,
		"pos": [pos.x, pos.y, pos.z],
		"rot": [0.0, 0.0, 0.0],
		"scale": [1.0, 1.0, 1.0],
		"props": props.duplicate(true),
		"created": Time.get_unix_time_from_system(),
	}
	items.append(item)
	touch()
	return item


func get_item(item_id: String) -> Dictionary:
	for item in items:
		if item.get("id", "") == item_id:
			return item
	return {}


func index_of(item_id: String) -> int:
	for i in range(items.size()):
		if items[i].get("id", "") == item_id:
			return i
	return -1


func children_of(item_id: String) -> Array:
	var result := []
	for item in items:
		if item.get("parent", "") == item_id:
			result.append(item)
	return result


func descendants_of(item_id: String) -> Array:
	var result := []
	var stack := [item_id]
	while not stack.is_empty():
		var current: String = stack.pop_back()
		for item in items:
			if item.get("parent", "") == current:
				result.append(item)
				stack.append(item.get("id", ""))
	return result


func items_in_layer(layer_id: String) -> Array:
	var result := []
	for item in items:
		if item.get("layer", "") == layer_id:
			result.append(item)
	return result


func remove_item(item_id: String) -> void:
	var doomed := {item_id: true}
	for d in descendants_of(item_id):
		doomed[d.get("id", "")] = true
	items = items.filter(func(i): return not doomed.has(i.get("id", "")))
	connectors = connectors.filter(func(c): return not doomed.has(c.get("from", "")) and not doomed.has(c.get("to", "")))
	sync_storyboard()
	touch()


func remove_items(ids: Array) -> void:
	for item_id in ids.duplicate():
		remove_item(str(item_id))


func add_connector(from_id: String, to_id: String, style := "curve", color := "#8FA0B8", label := "") -> Dictionary:
	if from_id == to_id or from_id.is_empty() or to_id.is_empty():
		return {}
	for existing in connectors:
		if existing.get("from", "") == from_id and existing.get("to", "") == to_id:
			return existing
	var connector := {
		"id": gen_id("cn"),
		"from": from_id,
		"to": to_id,
		"style": style,
		"color": color,
		"label": label,
		"layer": active_layer_id,
		"width": 0.035,
		"arrow": true,
		"dashed": style == "dashed",
	}
	connectors.append(connector)
	touch()
	return connector


func remove_connector(connector_id: String) -> void:
	connectors = connectors.filter(func(c): return c.get("id", "") != connector_id)
	touch()


func connector_between(a: String, b: String) -> Dictionary:
	for c in connectors:
		if (c.get("from", "") == a and c.get("to", "") == b) or (c.get("from", "") == b and c.get("to", "") == a):
			return c
	return {}


func connectors_for(item_id: String) -> Array:
	var result := []
	for c in connectors:
		if c.get("from", "") == item_id or c.get("to", "") == item_id:
			result.append(c)
	return result


func set_camera(pivot: Vector3, view_height: float, yaw: float, pitch: float) -> void:
	camera = {
		"pivot": [pivot.x, pivot.y, pivot.z],
		"view_height": view_height,
		"yaw": yaw,
		"pitch": pitch,
	}


func add_bookmark(bookmark_title: String, cam: Dictionary) -> Dictionary:
	var bookmark := {
		"id": gen_id("bm"),
		"name": bookmark_title,
		"camera": cam.duplicate(true),
		"created": Time.get_unix_time_from_system(),
	}
	bookmarks.append(bookmark)
	touch()
	return bookmark


func remove_bookmark(bookmark_id: String) -> void:
	bookmarks = bookmarks.filter(func(b): return b.get("id", "") != bookmark_id)
	touch()


func frames() -> Array:
	var result := []
	for item in items:
		if item.get("type", "") == "frame":
			result.append(item)
	result.sort_custom(func(a, b): return int(a.get("props", {}).get("order", 0)) < int(b.get("props", {}).get("order", 0)))
	return result


func next_frame_order() -> int:
	var highest := 0
	for f in frames():
		highest = maxi(highest, int(f.get("props", {}).get("order", 0)))
	return highest + 1


func sync_storyboard() -> void:
	var ids := []
	for f in frames():
		ids.append(f.get("id", ""))
	storyboard["frames"] = ids
	storyboard["current"] = clampi(int(storyboard.get("current", 0)), 0, maxi(0, ids.size() - 1))


func set_frame_order(frame_ids: Array) -> void:
	var order := 1
	for frame_id in frame_ids:
		var item := get_item(str(frame_id))
		if item.is_empty():
			continue
		item.get("props", {})["order"] = order
		order += 1
	sync_storyboard()
	touch()


func stats() -> Dictionary:
	var counts := {}
	for item in items:
		var t: String = item.get("type", "")
		counts[t] = int(counts.get(t, 0)) + 1
	return {
		"items": items.size(),
		"connectors": connectors.size(),
		"frames": counts.get("frame", 0),
		"notes": counts.get("note", 0) + counts.get("text", 0),
		"models": counts.get("model", 0) + counts.get("primitive", 0),
		"strokes": counts.get("stroke", 0),
		"layers": layers.size(),
	}


func to_dict() -> Dictionary:
	return {
		"format": FORMAT_VERSION,
		"id": id,
		"title": title,
		"created_at": created_at,
		"updated_at": updated_at,
		"layers": layers.duplicate(true),
		"items": items.duplicate(true),
		"connectors": connectors.duplicate(true),
		"bookmarks": bookmarks.duplicate(true),
		"storyboard": storyboard.duplicate(true),
		"settings": settings.duplicate(true),
		"camera": camera.duplicate(true),
		"active_layer_id": active_layer_id,
		"meta": meta.duplicate(true),
	}


func apply_dict(data: Dictionary) -> void:
	id = str(data.get("id", id))
	if id.is_empty():
		id = gen_id("prj")
	title = str(data.get("title", title))
	created_at = float(data.get("created_at", created_at))
	updated_at = float(data.get("updated_at", updated_at))
	layers = data.get("layers", layers).duplicate(true)
	items = data.get("items", []).duplicate(true)
	connectors = data.get("connectors", []).duplicate(true)
	bookmarks = data.get("bookmarks", []).duplicate(true)
	storyboard = data.get("storyboard", storyboard).duplicate(true)
	settings = data.get("settings", settings).duplicate(true)
	camera = data.get("camera", camera).duplicate(true)
	active_layer_id = str(data.get("active_layer_id", active_layer_id))
	meta = data.get("meta", meta).duplicate(true)
	_normalize()


static func from_dict(data: Dictionary) -> CanvasProject:
	var p := CanvasProject.create()
	p.apply_dict(data)
	return p


func _normalize() -> void:
	if layers.is_empty():
		layers = [_make_layer("lyr_ink", "Ink", "#2F5BFF")]
	var valid_layers := {}
	for layer in layers:
		if not layer.has("id"):
			layer["id"] = gen_id("lyr")
		valid_layers[layer["id"]] = true
		if not layer.has("color"):
			layer["color"] = "#5BE7FF"
		layer["visible"] = bool(layer.get("visible", true))
		layer["locked"] = bool(layer.get("locked", false))
	if not valid_layers.has(active_layer_id):
		active_layer_id = str(layers[0].get("id", ""))
	var cleaned := []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY or not item.has("id"):
			continue
		if not valid_layers.has(item.get("layer", "")):
			item["layer"] = active_layer_id
		if not item.has("pos") or (item["pos"] as Array).size() < 3:
			item["pos"] = [0.0, 0.0, 0.0]
		if not item.has("rot") or (item["rot"] as Array).size() < 3:
			item["rot"] = [0.0, 0.0, 0.0]
		if not item.has("scale") or (item["scale"] as Array).size() < 3:
			item["scale"] = [1.0, 1.0, 1.0]
		if not item.has("parent"):
			item["parent"] = ""
		if not item.has("props"):
			item["props"] = {}
		cleaned.append(item)
	items = cleaned
	var ids := {}
	for item in items:
		ids[item["id"]] = true
	connectors = connectors.filter(func(c): return ids.has(c.get("from", "")) and ids.has(c.get("to", "")))
	sync_storyboard()
	var cam: Dictionary = camera
	if not cam.has("pivot"):
		cam["pivot"] = [0.0, 0.0, 0.0]
	cam["view_height"] = clampf(float(cam.get("view_height", 22.0)), 0.4, 20000.0)
	cam["yaw"] = clampf(float(cam.get("yaw", 0.0)), -75.0, 75.0)
	cam["pitch"] = clampf(float(cam.get("pitch", 0.0)), -60.0, 75.0)
	camera = cam
	if settings.is_empty():
		settings = {"snap": true, "grid": 1.0, "snap_angle": 15.0}
	settings["grid"] = clampf(float(settings.get("grid", 1.0)), 0.1, 100.0)
	settings["pen_size"] = clampf(float(settings.get("pen_size", 2.4)), 0.3, 30.0)
	var defaults := {
		"snap": true, "snap_angle": 15.0, "show_grid": true, "grid_style": "lines",
		"show_connectors": true, "performance_mode": false, "haptics": true,
		"pressure": true, "autosave": true, "autosave_delay": 1.2, "reduce_motion": false,
		"left_handed": false, "show_fps": false, "keep_awake": false, "confirm_delete": false,
		"undo_limit": 60, "text_scale": 1.12, "default_tool": "select", "last_tool": "select",
		"pen_kind": "pen", "show_help_hints": true,
	}
	for key in defaults.keys():
		if not settings.has(key):
			settings[key] = defaults[key]
	if not settings.has("look"):
		settings["look"] = {"preset": "studio", "key_energy": 1.15, "ambient": 0.68}
	# Migrate the original cyan/violet palette to the premium light palette.
	var legacy_accent := {"#5BE7FF": "#2F5BFF", "#A78BFA": "#7455FF", "#FFC66D": "#B8780F", "#FFD27D": "#B8780F"}
	var pen_color := str(settings.get("pen_color", "#2F5BFF"))
	if legacy_accent.has(pen_color):
		settings["pen_color"] = legacy_accent[pen_color]
	if not settings.has("accent") or legacy_accent.has(str(settings.get("accent", ""))):
		settings["accent"] = "#2F5BFF"
	for layer in layers:
		var c := str(layer.get("color", ""))
		if legacy_accent.has(c):
			layer["color"] = legacy_accent[c]
