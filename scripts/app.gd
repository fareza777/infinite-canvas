extends Node

const ITEM_SCRIPTS := {
	"note": preload("res://scripts/world/note_item.gd"),
	"text": preload("res://scripts/world/note_item.gd"),
	"image": preload("res://scripts/world/media_item.gd"),
	"pdf": preload("res://scripts/world/media_item.gd"),
	"model": preload("res://scripts/world/model_item.gd"),
	"primitive": preload("res://scripts/world/primitive_item.gd"),
	"shape": preload("res://scripts/world/shape_item.gd"),
	"frame": preload("res://scripts/world/frame_item.gd"),
	"group": preload("res://scripts/world/group_item.gd"),
	"stroke": preload("res://scripts/world/stroke_item.gd"),
}

const NOTE_PAPERS := [
	{"color": "#FFFDF8", "accent": "#2F5BFF"},
	{"color": "#F4F8FF", "accent": "#7455FF"},
	{"color": "#F7F1FF", "accent": "#B8780F"},
	{"color": "#EFFBF5", "accent": "#0C8F6A"},
	{"color": "#FFF0F3", "accent": "#E05A44"},
	{"color": "#FFF6EA", "accent": "#B8780F"},
]

const FREE_LIMIT := 3
const APP_CONFIG := "user://app_config.json"
const FOV_3D := 48.0
const PRIVACY_POLICY_URL := "https://fareza777.github.io/infinitecanvas3d/privacy-policy.html"
const APP_DISPLAY_NAME := "Infinite Canvas 3D: Whiteboard"

var project: CanvasProject
var undo: UndoManager
var rig: CameraRig
var world: Node3D
var content: Node3D
var connector_root: Node3D
var grid: InfiniteGrid
var environment_node: WorldEnvironment
var env: Environment
var sky_mat: ShaderMaterial
var key_light: DirectionalLight3D
var light_a: OmniLight3D
var light_b: OmniLight3D
var item_nodes := {}
var connector_nodes := {}
var ui: GameUI
var billing: Billing
var ads: AdsService
var app_cfg: Dictionary = {"onboarded": false, "last_project": ""}
var ad_free_until := 0.0
var _ad_overlay_hidden := true
var _last_interstitial_ms := 0
var _ad_free_timer: Timer

var selected_ids: Array = []
var selected_connector_id := ""
var active_tool := "select"
var pen_color := Color("#2F5BFF")
var pen_size := 2.6
var ink_3d := false
var dirty := false
var storyboard_playing := false
var inspector_active := false
var busy := false
var last_saved_at := 0.0
var _last_autosave_snapshot := 0.0
var _save_timer: Timer
var _present_timer: Timer
var _long_press_timer: Timer
var _live_undo_active := false
var _live_undo_label := ""
var _live_undo_timer: Timer
var _connect_source := ""
var _new_project_counter := 1

var _touches := {}
var _active_index := -1
var _gesture := ""
var _down_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _down_time := 0.0
var _moved := false
var _pending_item := ""
var _pending_handle := ""
var _suppress_tap := false
var _pinching := false
var _pinch_last_dist := 0.0
var _pinch_last_center := Vector2.ZERO
var _marquee := Rect2()
var _guides_v: Array = []
var _guides_h: Array = []
var _drag_label := ""
var _drag_label_pos := Vector2.ZERO
var _eraser_pos := Vector2(-9999, -9999)
var _pen_pos := Vector2(-9999, -9999)
var _stroke_node: StrokeItem
var _stroke_item: Dictionary = {}
var _stroke_points: Array = []
var _stroke_width := 0.05
var _stroke_kind := "pen"
var _erased_count := 0
var _move_start_positions := {}
var _move_plane_z := 0.05
var _move_start_world := Vector3.ZERO
var _move_other_rects: Array = []
var _gizmo_item_id := ""
var _gizmo_center := Vector2.ZERO
var _gizmo_start_dist := 0.0
var _gizmo_start_angle := 0.0
var _gizmo_start_scale := Vector3.ONE
var _gizmo_start_rot := 0.0
var _last_tap_item := ""
var _last_tap_time := 0.0
var _last_tap_pos := Vector2.ZERO
var _connectors_dirty := true
var _last_connector_refresh := 0.0
var _last_ui_refresh := 0.0
var _last_lod_refresh := 0.0
var _last_overlay_refresh := 0.0
var _last_zoom_refresh := 0.0
var _overlay_visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	Store.ensure_dirs()
	_load_app_config()
	if OS.get_cmdline_user_args().has("--dark"):
		app_cfg["theme"] = "dark"
	elif OS.get_cmdline_user_args().has("--amoled"):
		app_cfg["theme"] = "amoled"
	_build_services()
	_build_world()
	_bootstrap_project()
	_build_ui()
	_build_billing()
	_build_ads()
	_enter_project(project, true)
	if not bool(app_cfg.get("onboarded", false)):
		ui.show_onboarding(true)
	if not OS.get_cmdline_user_args().has("--no-splash"):
		ui.show_splash()
	_sync_ui()
	_sync_camera_to_project()
	_handle_debug_args()


func _handle_debug_args() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_path := ""
	var sheet := ""
	var sheet_scroll := 0.0
	var select_first := false
	var mode_3d := false
	for arg in args:
		if str(arg).begins_with("--shot="):
			shot_path = str(arg).trim_prefix("--shot=")
		elif str(arg).begins_with("--sheet="):
			sheet = str(arg).trim_prefix("--sheet=")
		elif str(arg).begins_with("--scroll="):
			sheet_scroll = float(str(arg).trim_prefix("--scroll="))
	if args.has("--skip-onboarding"):
		ui.show_onboarding(false)
	if args.has("--onboarding"):
		ui.show_onboarding(true)
	if args.has("--new-board"):
		new_project()
	if args.has("--demo"):
		ui.show_onboarding(false)
		first_run(true)
	if args.has("--select-first"):
		select_first = true
	if args.has("--mode3d"):
		mode_3d = true
	if select_first:
		for item in project.items:
			if str(item.get("type", "")) in ["note", "text", "frame", "image", "primitive"]:
				select_ids([str(item.get("id", ""))])
				break
	if mode_3d:
		rig.mode = "3d"
		rig.set_mode_3d(false)
		rig.apply_view_now()
	if not sheet.is_empty():
		_debug_open_sheet(sheet, sheet_scroll)
	if not shot_path.is_empty():
		_debug_capture(shot_path)


func _debug_open_sheet(sheet: String, scroll := 0.0) -> void:
	await get_tree().create_timer(0.45).timeout
	ui.open_sheet(sheet)
	if scroll > 0.0:
		await get_tree().process_frame
		ui.set_sheet_scroll(scroll)


func _debug_capture(path: String) -> void:
	await get_tree().create_timer(1.4).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := image.save_png(path)
	print("DEBUG_SHOT ", path, " err=", err, " size=", image.get_size())
	get_tree().quit()


func _build_services() -> void:
	undo = UndoManager.new()
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 1.2
	_save_timer.timeout.connect(func(): save_now())
	add_child(_save_timer)
	_present_timer = Timer.new()
	_present_timer.one_shot = true
	_present_timer.timeout.connect(_on_present_tick)
	add_child(_present_timer)
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = 0.5
	_long_press_timer.timeout.connect(_on_long_press)
	add_child(_long_press_timer)
	_live_undo_timer = Timer.new()
	_live_undo_timer.one_shot = true
	_live_undo_timer.wait_time = 0.55
	_live_undo_timer.timeout.connect(_flush_live_edit)
	add_child(_live_undo_timer)


func _build_world() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	content = Node3D.new()
	content.name = "Content"
	world.add_child(content)
	connector_root = Node3D.new()
	connector_root.name = "Connectors"
	world.add_child(connector_root)
	grid = InfiniteGrid.new()
	grid.name = "InfiniteGrid"
	world.add_child(grid)
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://assets/shaders/sky.gdshader")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.ambient_light_color = Color("#8FB4FF")
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	environment_node = WorldEnvironment.new()
	environment_node.environment = env
	world.add_child(environment_node)
	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-36, -32, 0)
	key_light.light_color = Color("#FFF2DE")
	key_light.light_energy = 1.25
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 80.0
	world.add_child(key_light)
	light_a = OmniLight3D.new()
	light_a.name = "CyanFill"
	light_a.light_color = Color("#2F5BFF")
	light_a.light_energy = 2.6
	light_a.omni_range = 28.0
	light_a.omni_attenuation = 1.4
	world.add_child(light_a)
	light_b = OmniLight3D.new()
	light_b.name = "VioletFill"
	light_b.light_color = Color("#7455FF")
	light_b.light_energy = 2.2
	light_b.omni_range = 24.0
	light_b.omni_attenuation = 1.5
	world.add_child(light_b)
	rig = CameraRig.new()
	rig.name = "CameraRig"
	world.add_child(rig)


func _bootstrap_project() -> void:
	Store.ensure_dirs()
	var loaded: CanvasProject = null
	var last_id := str(app_cfg.get("last_project", ""))
	if not last_id.is_empty():
		loaded = Store.load_project(last_id)
	if loaded == null:
		var projects := Store.list_projects()
		if not projects.is_empty():
			loaded = Store.load_project(str(projects[0].get("id", "")))
	if loaded == null:
		loaded = CanvasProject.create("My First Board")
		Store.save_project(loaded)
	project = loaded
	project._normalize()
	app_cfg["last_project"] = project.id
	_save_app_config()


func _build_ui() -> void:
	Kit.apply_theme(str(app_cfg.get("theme", "light")))
	Kit.set_type_scale(float(app_cfg.get("text_scale", project.settings.get("text_scale", 1.12))))
	ui = GameUI.new()
	ui.name = "GameUI"
	add_child(ui)
	ui.setup(self)
	ui.set_zoom(_zoom_percent())


func _build_billing() -> void:
	billing = Billing.new()
	billing.name = "Billing"
	add_child(billing)
	billing.notice.connect(func(text, icon, color): ui.toast(text, icon, color, 3.0))
	billing.state_changed.connect(func():
		if ui != null:
			ui.refresh()
			if ui.sheet_kind == "settings":
				ui.reload_sheet()
		_refresh_ads()
	)


func _build_ads() -> void:
	ads = AdsService.new()
	ads.name = "Ads"
	add_child(ads)
	ads.notice.connect(func(text, icon, color): ui.toast(text, icon, color, 2.6))
	ads.state_changed.connect(_on_ads_state)
	ads.privacy_options_changed.connect(_on_privacy_options_changed)
	ads.reward_earned.connect(_on_reward_earned)
	ad_free_until = float(app_cfg.get("ad_free_until", 0.0))
	_refresh_ads()
	_schedule_ad_free_expiry()


func _on_ads_state() -> void:
	if ui != null:
		ui.relayout()
		ui.refresh()


func _refresh_ads() -> void:
	if ads == null:
		return
	var free := is_ad_free()
	ads.set_enabled(not free)
	ads.set_rewarded_enabled(not has_removed_ads())
	ads.set_overlay_hidden(_ad_overlay_hidden or free)
	if ui != null:
		ui.relayout()


func _on_privacy_options_changed() -> void:
	if ui != null and ui.sheet_kind == "settings":
		ui.reload_sheet()


func needs_privacy_options() -> bool:
	return ads != null and ads.is_privacy_options_required()


func show_privacy_options() -> void:
	if ads != null:
		ads.show_privacy_options()


func open_privacy_policy() -> void:
	var err := OS.shell_open(PRIVACY_POLICY_URL)
	if err != OK:
		ui.toast("Could not open the privacy policy", "warning", Kit.DANGER, 1.8)
		return
	ui.toast("Opening privacy policy", "shield", Kit.ACCENT, 1.4)


func set_ad_overlay_hidden(hidden: bool) -> void:
	_ad_overlay_hidden = hidden
	if ads != null:
		ads.set_overlay_hidden(hidden or is_ad_free())
	if ui != null:
		ui.relayout()


func get_ad_banner_reserve() -> float:
	if ads == null or is_ad_free():
		return 0.0
	return ads.get_banner_height()


func is_ad_free() -> bool:
	if billing != null and billing.ads_removed:
		return true
	return Time.get_unix_time_from_system() < ad_free_until


func has_removed_ads() -> bool:
	return billing != null and billing.ads_removed


func get_ad_free_until() -> float:
	return ad_free_until


func get_ad_status_text() -> String:
	if has_removed_ads():
		return "Ads removed permanently. Thank you."
	if is_ad_free():
		return "Ad-free until %s" % Time.get_datetime_string_from_unix_time(int(ad_free_until), true)
	return ads.status_text() if ads != null else "Ads are unavailable."


func get_remove_ads_price() -> String:
	if billing != null:
		var price := billing.get_price()
		if not price.is_empty():
			return price
	return "$4.99"


func purchase_remove_ads() -> void:
	if billing != null:
		billing.purchase_remove_ads()


func show_interstitial_ad() -> void:
	if is_ad_free():
		ui.toast("You are already ad-free", "block", Kit.GREEN)
		return
	if ads != null:
		ads.show_interstitial()


func watch_rewarded_ad() -> void:
	if has_removed_ads():
		ui.toast("Ads are already removed permanently", "block", Kit.GREEN)
		return
	if ads == null:
		ui.toast("Ads are unavailable in this build", "warning", Kit.MUTED)
		return
	ads.show_rewarded()


func _on_reward_earned() -> void:
	ad_free_until = maxf(ad_free_until, Time.get_unix_time_from_system() + 86400.0)
	app_cfg["ad_free_until"] = ad_free_until
	_save_app_config()
	_refresh_ads()
	_schedule_ad_free_expiry()
	ui.toast("Ads are off for 24 hours", "block", Kit.GREEN, 2.6)
	if ui.sheet_root.visible:
		ui.reload_sheet()


func _schedule_ad_free_expiry() -> void:
	if _ad_free_timer == null:
		_ad_free_timer = Timer.new()
		_ad_free_timer.one_shot = true
		_ad_free_timer.timeout.connect(func():
			ad_free_until = 0.0
			app_cfg.erase("ad_free_until")
			_save_app_config()
			_refresh_ads()
			if ui != null and ui.sheet_kind == "settings":
				ui.reload_sheet()
		)
		add_child(_ad_free_timer)
	_ad_free_timer.stop()
	var remaining := ad_free_until - Time.get_unix_time_from_system()
	if remaining > 0.0:
		_ad_free_timer.start(remaining)


func _maybe_show_interstitial() -> void:
	if ads == null or is_ad_free():
		return
	var now := Time.get_ticks_msec()
	if now - _last_interstitial_ms < 90000:
		return
	_last_interstitial_ms = now
	await get_tree().create_timer(0.9).timeout
	if ads != null and not is_ad_free() and not ui.sheet_root.visible:
		ads.show_interstitial()


func set_ui_theme(theme_name: String) -> void:
	if not theme_name in ["light", "dark", "amoled"]:
		theme_name = "light"
	app_cfg["theme"] = theme_name
	_save_app_config()
	Kit.apply_theme(theme_name)
	_rebuild_ui()


func get_ui_theme() -> String:
	return str(app_cfg.get("theme", "light"))


func _enter_project(p: CanvasProject, initial := false) -> void:
	project = p
	project._normalize()
	undo.clear()
	_clear_scene_nodes()
	selected_ids.clear()
	selected_connector_id = ""
	_connect_source = ""
	project.sync_storyboard()
	_load_settings_from_project()
	for item in project.items:
		_spawn_item_node(item)
	_connect_parent_nodes()
	_build_connectors()
	_refresh_connector_visibility()
	var cam: Dictionary = project.camera
	rig.set_state(cam, false)
	rig.mode = str(cam.get("mode", "2d"))
	if rig.mode == "3d":
		rig.fov_target = FOV_3D
		rig.fov = FOV_3D
	else:
		rig.mode = "2d"
		rig.fov_target = CameraRig.FOV_2D
		rig.fov = CameraRig.FOV_2D
	rig.apply_view_now()
	_apply_look()
	active_tool = str(project.settings.get("last_tool", "select"))
	if not ["select", "pan", "pen", "highlighter", "eraser", "note", "shape", "connect"].has(active_tool):
		active_tool = "select"
	app_cfg["last_project"] = project.id
	_save_app_config()
	_connectors_dirty = true
	dirty = false
	if ui != null:
		ui.refresh()
		ui.refresh_selection()
		ui.set_zoom(_zoom_percent())
		_update_overlay()
	if initial:
		_update_overlay()


func _load_settings_from_project() -> void:
	pen_color = Color.from_string(str(project.settings.get("pen_color", "#2F5BFF")), Kit.ACCENT)
	pen_size = float(project.settings.get("pen_size", 2.4))
	ink_3d = bool(project.settings.get("ink_3d", false))
	if not project.settings.has("look"):
		project.settings["look"] = {"preset": "studio", "key_energy": 1.15, "ambient": 0.68}
	if not project.settings.has("accent"):
		project.settings["accent"] = "#2F5BFF"
	_apply_behavior_settings()


func _spawn_item_node(item: Dictionary) -> CanvasItem3D:
	var type := str(item.get("type", "note"))
	var script: Script = ITEM_SCRIPTS.get(type, ITEM_SCRIPTS["note"])
	var node: CanvasItem3D = script.new()
	node.name = "Item_" + str(item.get("id", ""))
	content.add_child(node)
	node.setup(self, item)
	item_nodes[str(item.get("id", ""))] = node
	return node


func _connect_parent_nodes() -> void:
	for item in project.items:
		var parent_id := str(item.get("parent", ""))
		if parent_id.is_empty():
			continue
		var node: Node3D = item_nodes.get(str(item.get("id", "")), null)
		var parent_node: Node3D = item_nodes.get(parent_id, null)
		if node == null or parent_node == null or node.get_parent() == parent_node:
			continue
		node.get_parent().remove_child(node)
		parent_node.add_child(node)
		node.position = Vector3(float(item.get("pos", [0, 0, 0])[0]), float(item.get("pos", [0, 0, 0])[1]), float(item.get("pos", [0, 0, 0])[2]))
		node.rotation_degrees = Vector3(float(item.get("rot", [0, 0, 0])[0]), float(item.get("rot", [0, 0, 0])[1]), float(item.get("rot", [0, 0, 0])[2]))
		node.scale = Vector3(float(item.get("scale", [1, 1, 1])[0]), float(item.get("scale", [1, 1, 1])[1]), float(item.get("scale", [1, 1, 1])[2]))


func _clear_scene_nodes() -> void:
	for child in content.get_children():
		child.free()
	for child in connector_root.get_children():
		child.free()
	item_nodes.clear()
	connector_nodes.clear()


func _build_connectors() -> void:
	for c in project.connectors:
		_add_connector_node(c)
	_connectors_dirty = true


func _add_connector_node(data: Dictionary) -> ConnectorNode:
	var node := ConnectorNode.new()
	node.name = "Connector_" + str(data.get("id", ""))
	connector_root.add_child(node)
	node.setup(self, data)
	connector_nodes[str(data.get("id", ""))] = node
	return node


func _rebuild_scene(keep_selection := true) -> void:
	var keep := selected_ids.duplicate()
	var keep_connector := selected_connector_id
	_clear_scene_nodes()
	for item in project.items:
		_spawn_item_node(item)
	_connect_parent_nodes()
	_build_connectors()
	selected_ids = []
	if keep_selection:
		for id in keep:
			if item_nodes.has(id):
				selected_ids.append(id)
	if not keep_connector.is_empty() and connector_nodes.has(keep_connector):
		selected_connector_id = keep_connector
	else:
		selected_connector_id = ""
	_connectors_dirty = true
	if ui != null:
		ui.refresh()
		ui.refresh_selection()
		_update_overlay()


func _spawn_for_item(item: Dictionary, select := false) -> CanvasItem3D:
	var node := _spawn_item_node(item)
	var parent_id := str(item.get("parent", ""))
	if not parent_id.is_empty() and item_nodes.has(parent_id):
		var parent_node: Node3D = item_nodes[parent_id]
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		parent_node.add_child(node)
		node.position = _to_vec3(item.get("pos", [0, 0, 0]))
		node.rotation_degrees = _to_vec3(item.get("rot", [0, 0, 0]))
		node.scale = _to_vec3(item.get("scale", [1, 1, 1]))
	if select:
		select_ids([str(item.get("id", ""))])
	_connectors_dirty = true
	return node


func _focus_bounds_of(ids: Array, margin := 1.35) -> void:
	if ids.is_empty():
		return
	var rect := Rect2()
	var first := true
	for id in ids:
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node == null:
			continue
		var r := _node_world_rect(node)
		if r.size.x <= 0.001 and r.size.y <= 0.001:
			continue
		if first:
			rect = r
			first = false
		else:
			rect = rect.merge(r)
	if first:
		return
	rig.focus_rect(rect, margin)


func _node_world_rect(node: CanvasItem3D) -> Rect2:
	if node is GroupItem:
		var merged := Rect2()
		var first := true
		for child in project.descendants_of(node.item_id):
			var child_node: CanvasItem3D = item_nodes.get(str(child.get("id", "")), null)
			if child_node == null:
				continue
			var r := _node_world_rect(child_node)
			if first:
				merged = r
				first = false
			else:
				merged = merged.merge(r)
		return merged
	if node.is_flat():
		return node.get_world_rect()
	var aabb := node.get_bounds_aabb()
	return Rect2(Vector2(aabb.position.x, aabb.position.y), Vector2(aabb.size.x, aabb.size.y))


func _to_vec3(value) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


func _zoom_percent() -> float:
	if rig == null or rig.view_height <= 0.0:
		return 100.0
	return clampf(100.0 * 22.0 / maxf(0.01, rig.view_height), 1.0, 99999.0)


func get_zoom_percent() -> float:
	return _zoom_percent()


func _sync_ui() -> void:
	if ui == null:
		return
	ui.refresh()
	ui.refresh_selection()
	ui.set_zoom(_zoom_percent())
	_update_overlay()


func _process(delta: float) -> void:
	if project == null or rig == null:
		return
	var now := Time.get_ticks_msec()
	grid.update_view(rig, bool(project.settings.get("show_grid", true)), str(project.settings.get("grid_style", "lines")))
	grid.set_accent(Color.from_string(str(project.settings.get("accent", "#2F5BFF")), Kit.ACCENT))
	light_a.position = rig.pivot + Vector3(-8, 7, 9)
	light_b.position = rig.pivot + Vector3(9, -6, 7)
	if ui != null:
		if now - _last_ui_refresh > 400:
			_last_ui_refresh = now
			ui.set_zoom(_zoom_percent())
			ui.refresh()
		if now - _last_overlay_refresh > 32 and (not selected_ids.is_empty() or not selected_connector_id.is_empty() or _gesture != ""):
			_last_overlay_refresh = now
			_update_overlay()
	if _connectors_dirty and now - _last_connector_refresh > 60:
		_last_connector_refresh = now
		_refresh_connectors()
	if now - _last_lod_refresh > 480:
		_last_lod_refresh = now
		_update_lod()
	if now - _last_zoom_refresh > 400:
		_last_zoom_refresh = now
		if not storyboard_playing:
			_sync_camera_to_project(false)


func _update_lod() -> void:
	var view_height := rig.view_height
	for node in item_nodes.values():
		if node is NoteItem:
			var screen_h: float = (node.get_flat_rect().size.y / view_height) * 900.0
			node.update_lod(0.0, view_height)
			node.body_label.visible = screen_h > 46.0 and not node.full_text().strip_edges().is_empty()
			node.tags_label.visible = screen_h > 78.0
			node.type_icon.visible = screen_h > 95.0 and not node.pin_label.visible
		elif node is MediaItem:
			var h: float = node.get_flat_rect().size.y / view_height * 900.0
			node.caption_label.visible = h > 54.0
			node.badge_label.visible = h > 76.0
		elif node is ModelItem:
			var h: float = node.get_bounds_aabb().size.y / view_height * 900.0
			node.label.visible = h > 54.0 and bool(node.data.get("props", {}).get("show_label", true))
		elif node is FrameItem:
			var fh: float = (4.6 / view_height) * 900.0
			node.body_label.visible = fh > 60.0
			node.footer_label.visible = fh > 78.0


func _refresh_connectors() -> void:
	_connectors_dirty = false
	for node in connector_nodes.values():
		if node != null and is_instance_valid(node):
			node.refresh(rig.view_height)


func _refresh_connectors_for(item_id: String) -> void:
	for c in project.connectors_for(item_id):
		var node: ConnectorNode = connector_nodes.get(str(c.get("id", "")), null)
		if node != null:
			node.refresh(rig.view_height)
	_connectors_dirty = true


func _refresh_selected_connectors() -> void:
	_connectors_dirty = true


func _sync_camera_to_project(mark_dirty := false) -> void:
	if project == null or rig == null:
		return
	project.camera = {
		"pivot": [rig.pivot_target.x, rig.pivot_target.y, rig.pivot_target.z],
		"view_height": rig.view_height_target,
		"yaw": rig.yaw_target,
		"pitch": rig.pitch_target,
		"mode": rig.mode,
	}
	if mark_dirty:
		project.touch()


func _apply_look() -> void:
	var look: Dictionary = project.settings.get("look", {"preset": "studio", "key_energy": 1.15, "ambient": 0.68})
	var preset := str(look.get("preset", "studio"))
	var key_energy := float(look.get("key_energy", 1.15))
	var ambient := float(look.get("ambient", 0.68))
	var key_color := Color("#FFF6E8")
	var a_color := Color("#5A7BFF")
	var b_color := Color("#FF9E80")
	var a_energy := 2.1
	var b_energy := 1.7
	var sky_top := Color("#F4F8FF")
	var sky_bottom := Color("#FBF3E8")
	var grid_top := Color("#FAF7F1")
	var grid_bottom := Color("#EFEAE0")
	var grid_line := Color(0.48, 0.43, 0.36, 0.30)
	match preset:
		"midnight":
			key_color = Color("#B8D4FF")
			key_energy = key_energy * 0.65
			a_color = Color("#3E8BFF")
			b_color = Color("#8B5CF6")
			a_energy = 1.6
			b_energy = 1.8
			sky_top = Color("#02040A")
			sky_bottom = Color("#070D18")
			grid_top = Color("#0A1222")
			grid_bottom = Color("#05080F")
			grid_line = Color(0.42, 0.58, 0.78, 0.42)
		"warm":
			key_color = Color("#FFD9B0")
			key_energy = key_energy * 1.2
			a_color = Color("#E05A44")
			b_color = Color("#FF7A9C")
			a_energy = 2.2
			b_energy = 1.6
			sky_top = Color("#FFF9EF")
			sky_bottom = Color("#F4E4D0")
			grid_top = Color("#FFFBF3")
			grid_bottom = Color("#F1E5D2")
			grid_line = Color(0.55, 0.45, 0.33, 0.30)
		"neon":
			key_color = Color("#C6E7FF")
			key_energy = key_energy * 0.9
			a_color = Color("#2F5BFF")
			b_color = Color("#C084FC")
			a_energy = 3.6
			b_energy = 3.0
			sky_top = Color("#F6FBFF")
			sky_bottom = Color("#E9F1FF")
			grid_top = Color("#F7FAFF")
			grid_bottom = Color("#E7EFFF")
			grid_line = Color(0.40, 0.51, 0.70, 0.28)
	key_light.light_color = key_color
	key_light.light_energy = key_energy
	light_a.light_color = a_color
	light_a.light_energy = a_energy
	light_b.light_color = b_color
	light_b.light_energy = b_energy
	env.ambient_light_energy = ambient
	if sky_mat != null:
		sky_mat.set_shader_parameter("top_color", sky_top)
		sky_mat.set_shader_parameter("bottom_color", sky_bottom)
		sky_mat.set_shader_parameter("accent_two", b_color)
	var accent := Color.from_string(str(project.settings.get("accent", "#2F5BFF")), Kit.ACCENT)
	if sky_mat != null:
		sky_mat.set_shader_parameter("accent_one", accent)
	if grid != null:
		grid.set_palette(grid_top, grid_bottom, grid_line, accent)
	if env != null:
		env.glow_intensity = 0.18 if preset != "neon" else 0.32
		env.tonemap_exposure = 1.0
	_connectors_dirty = true


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_pressed(event)
		else:
			_on_touch_released(event)
	elif event is InputEventScreenDrag:
		_on_touch_drag(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)


func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		if ui.handle_back():
			return
		if not selected_ids.is_empty() or not selected_connector_id.is_empty():
			select_ids([])
			return
	match event.keycode:
		KEY_V:
			set_tool("select")
		KEY_H:
			set_tool("pan")
		KEY_P:
			set_tool("pen")
		KEY_M:
			set_tool("highlighter")
		KEY_E:
			set_tool("eraser")
		KEY_N:
			set_tool("note")
		KEY_R:
			set_tool("shape")
		KEY_C:
			set_tool("connect")
		KEY_TAB:
			toggle_mode()
		KEY_F:
			focus_all()
		KEY_DELETE, KEY_BACKSPACE:
			delete_selection()
		KEY_W:
			if event.ctrl_pressed:
				ui.close_sheet()
		KEY_Z:
			if event.ctrl_pressed and event.shift_pressed:
				redo_action()
			elif event.ctrl_pressed:
				undo_action()
		KEY_Y:
			if event.ctrl_pressed:
				redo_action()
		KEY_S:
			if event.ctrl_pressed:
				save_now()
		KEY_D:
			if event.ctrl_pressed:
				duplicate_selection()
		KEY_G:
			if event.ctrl_pressed:
				group_selection()
		KEY_A:
			if event.ctrl_pressed:
				select_ids(_all_selectable_ids())


func _on_touch_pressed(event: InputEventScreenTouch) -> void:
	_touches[event.index] = event.position
	if _touches.size() == 1:
		_active_index = event.index
		_down_pos = event.position
		_last_pos = event.position
		_down_time = Time.get_ticks_msec()
		_moved = false
		_suppress_tap = false
		_begin_single_press(event.position)
	elif _touches.size() == 2:
		_begin_pinch()


func _on_touch_drag(event: InputEventScreenDrag) -> void:
	_touches[event.index] = event.position
	if _pinching:
		if _touches.size() >= 2:
			_update_pinch()
		return
	if event.index != _active_index:
		return
	var pos := event.position
	if _gesture == "":
		return
	if not _moved and pos.distance_to(_down_pos) > 7.0:
		_moved = true
		_long_press_timer.stop()
		_resolve_pending()
	var delta := pos - _last_pos
	_last_pos = pos
	if not _moved:
		return
	match _gesture:
		"pan":
			rig.pan_screen(delta)
			_connectors_dirty = true
		"orbit":
			rig.orbit_screen(delta)
			_connectors_dirty = true
		"draw":
			_add_stroke_point(pos, event.pressure)
		"erase":
			_erase_at(pos)
			_eraser_pos = pos
		"marquee":
			_marquee = Rect2(_down_pos, pos - _down_pos).abs()
			_update_overlay()
		"move":
			_apply_move(pos)
		"scale":
			_apply_scale(pos)
		"rotate":
			_apply_rotate(pos)
		"connect":
			pass
		_:
			pass


func _on_touch_released(event: InputEventScreenTouch) -> void:
	_touches.erase(event.index)
	_long_press_timer.stop()
	if _pinching:
		if _touches.size() < 2:
			_pinching = false
			_gesture = ""
			_active_index = -1
			_touches.clear()
		return
	if event.index != _active_index:
		return
	var pos := event.position
	match _gesture:
		"draw":
			_end_stroke()
		"erase":
			_end_erase()
		"move":
			_finish_move()
		"scale":
			_finish_scale()
		"rotate":
			_finish_rotate()
		"marquee":
			_apply_marquee()
		"pan", "orbit":
			pass
		_:
			if not _moved and not _suppress_tap:
				_handle_tap(pos)
	_gesture = ""
	_active_index = -1
	_moved = false
	_pending_item = ""
	_pending_handle = ""
	_dev_reset_drag_state()
	_update_overlay()


func _dev_reset_drag_state() -> void:
	_marquee = Rect2()
	_guides_v.clear()
	_guides_h.clear()
	_drag_label = ""
	_pen_pos = Vector2(-9999, -9999)
	_eraser_pos = Vector2(-9999, -9999)


func _begin_single_press(pos: Vector2) -> void:
	if _pinching:
		return
	match active_tool:
		"pen", "highlighter":
			_begin_stroke(pos)
			_gesture = "draw"
		"eraser":
			_gesture = "erase"
			_erased_count = 0
			_eraser_pos = pos
			undo.begin(project)
		"pan":
			_gesture = "pan"
		"select":
			_begin_select_press(pos)
		"note", "shape", "text":
			_gesture = "pending"
		"connect":
			_gesture = "pending"
		_:
			_gesture = "pending"


func _begin_select_press(pos: Vector2) -> void:
	_gesture = "pending"
	var handle := _hit_gizmo(pos)
	if not handle.is_empty():
		_pending_handle = handle
		return
	var hit_id := _pick_item(pos)
	if not hit_id.is_empty():
		if not selected_ids.has(hit_id):
			select_ids([hit_id])
		_pending_item = hit_id
		_long_press_timer.start()
		return
	var connector_id := _pick_connector(pos)
	if not connector_id.is_empty():
		select_connector(connector_id)
		return
	_pending_item = ""


func _resolve_pending() -> void:
	if active_tool == "select":
		if not _pending_handle.is_empty():
			if _pending_handle == "rotate":
				_begin_rotate(_down_pos)
			else:
				_begin_scale(_down_pos)
			return
		if not _pending_item.is_empty():
			_begin_move(_down_pos)
			return
		if rig.mode == "3d":
			_gesture = "orbit"
		else:
			_gesture = "marquee"
			_marquee = Rect2(_down_pos, _down_pos)
	elif active_tool == "connect":
		_gesture = "connect"
	elif active_tool in ["note", "shape", "text"]:
		pass


func _handle_tap(pos: Vector2) -> void:
	match active_tool:
		"select":
			var hit_id := _pick_item(pos)
			if not hit_id.is_empty():
				var now := Time.get_ticks_msec()
				if hit_id == _last_tap_item and now - _last_tap_time < 380 and pos.distance_to(_last_tap_pos) < 34:
					select_ids([hit_id])
					ui.open_sheet("inspector")
					_last_tap_item = ""
				else:
					_last_tap_item = hit_id
					_last_tap_time = now
					_last_tap_pos = pos
			else:
				var connector_id := _pick_connector(pos)
				if not connector_id.is_empty():
					select_connector(connector_id)
				else:
					select_ids([])
		"note":
			_create_from_tap("note", pos)
		"text":
			_create_from_tap("text", pos)
		"shape":
			_create_from_tap("shape", pos)
		"connect":
			_handle_connect_tap(pos)


func _create_from_tap(kind: String, screen_pos: Vector2) -> void:
	var world_point := _world_point(screen_pos)
	_create_item_at(kind, world_point)
	set_tool("select")


func _handle_connect_tap(pos: Vector2) -> void:
	var hit_id := _pick_item(pos)
	if hit_id.is_empty():
		_connect_source = ""
		ui.toast("Tap an object to start a connection", "polyline", Kit.ACCENT)
		return
	if _connect_source.is_empty():
		_connect_source = hit_id
		select_ids([hit_id])
		ui.toast("Now tap the second object", "polyline", Kit.ACCENT)
		_haptic(12)
		return
	if hit_id == _connect_source:
		_connect_source = ""
		return
	undo.begin(project)
	var connector := project.add_connector(_connect_source, hit_id, "curve", _hex(pen_color), "")
	if connector.is_empty():
		undo.cancel()
	else:
		_add_connector_node(connector)
		undo.commit(project, "Connect objects")
		dirty = true
		_schedule_save()
		select_connector(str(connector.get("id", "")))
		ui.toast("Ideas connected", "polyline", Kit.GREEN)
		_haptic(16)
	_connect_source = ""
	ui.refresh()


func _begin_pinch() -> void:
	_cancel_current_for_pinch()
	_pinching = true
	_gesture = "pinch"
	_update_pinch(true)


func _cancel_current_for_pinch() -> void:
	if _gesture == "draw":
		_end_stroke()
	elif _gesture == "erase":
		_end_erase()
	elif _gesture == "move":
		_finish_move()
	elif _gesture == "scale":
		_finish_scale()
	elif _gesture == "rotate":
		_finish_rotate()
	elif _gesture == "marquee":
		_marquee = Rect2()
		_update_overlay()
	_pending_item = ""
	_pending_handle = ""
	_long_press_timer.stop()
	_gesture = "pinch"


func _update_pinch(reset := false) -> void:
	if _touches.size() < 2:
		return
	var keys := _touches.keys()
	keys.sort()
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	var center := (a + b) * 0.5
	var dist := a.distance_to(b)
	if reset:
		_pinch_last_center = center
		_pinch_last_dist = maxf(1.0, dist)
		return
	var factor := dist / maxf(1.0, _pinch_last_dist)
	if absf(factor - 1.0) > 0.002:
		rig.zoom_at(factor, center)
	if center.distance_to(_pinch_last_center) > 0.01:
		rig.pan_screen(center - _pinch_last_center)
	_pinch_last_center = center
	_pinch_last_dist = maxf(1.0, dist)
	_connectors_dirty = true


# ------------------------------------------------------------------ drawing

func _begin_stroke(pos: Vector2) -> void:
	var point := _ink_point(pos)
	_stroke_width = pen_size * rig.world_per_pixel()
	if active_tool == "highlighter":
		_stroke_width *= 3.4
	_stroke_kind = "highlighter" if active_tool == "highlighter" else "pen"
	undo.begin(project)
	var initial_pressure := 0.82 if not bool(project.settings.get("pressure", true)) else 1.0
	_stroke_points = [[point.x, point.y, point.z, initial_pressure]]
	var ink_layer := _ink_layer()
	var props := {
		"points": _stroke_points,
		"color": _hex(pen_color),
		"width": _stroke_width,
		"kind": _stroke_kind,
	}
	var item := project.add_item("stroke", Vector3.ZERO, props, ink_layer)
	dirty = true
	_stroke_item = item
	var node: StrokeItem = _spawn_item_node(item)
	_stroke_node = node
	_stroke_node.set_points(_stroke_points, _stroke_width, pen_color, _stroke_kind)
	_pen_pos = pos
	_haptic(4)


func _ink_point(pos: Vector2) -> Vector3:
	if ink_3d and rig.mode == "3d":
		return rig.screen_to_camera_plane(pos, 0.0)
	return rig.screen_to_plane(pos, 0.05)


func _add_stroke_point(pos: Vector2, pressure: float) -> void:
	if _stroke_node == null:
		return
	var point := _ink_point(pos)
	var p := clampf(pressure, 0.0, 1.0)
	if p <= 0.01:
		p = 0.75
	if not bool(project.settings.get("pressure", true)):
		p = 0.82
	_stroke_points.append([point.x, point.y, point.z, p])
	_stroke_node.set_points(_stroke_points, _stroke_width, pen_color, _stroke_kind)
	_pen_pos = pos
	_connectors_dirty = true


func _end_stroke() -> void:
	if _stroke_node == null:
		return
	if _stroke_points.size() < 2:
		var p: Array = _stroke_points[0]
		_stroke_points.append([float(p[0]) + _stroke_width * 0.6, float(p[1]), float(p[2]), 0.7])
		_stroke_node.set_points(_stroke_points, _stroke_width, pen_color, _stroke_kind)
	_stroke_item.get("props", {})["points"] = _stroke_points
	_stroke_item.get("props", {})["color"] = _hex(pen_color)
	_stroke_item.get("props", {})["width"] = _stroke_width
	_stroke_item.get("props", {})["kind"] = _stroke_kind
	_stroke_item.get("props", {})["style"] = "dot" if _stroke_points.size() == 2 else "freehand"
	var committed := undo.commit(project, "Sketch")
	if committed:
		_schedule_save()
		ui.toast("Ink added", "gesture", Kit.ACCENT, 1.2)
	_stroke_node = null
	_stroke_item = {}
	_stroke_points = []
	_pen_pos = Vector2(-9999, -9999)


func _erase_at(pos: Vector2) -> void:
	var origin := rig.camera.project_ray_origin(pos)
	var dir := rig.camera.project_ray_normal(pos)
	var point := _ink_point(pos)
	for item in project.items.duplicate():
		if str(item.get("type", "")) != "stroke":
			continue
		var node: StrokeItem = item_nodes.get(str(item.get("id", "")), null)
		if node == null or not node.visible:
			continue
		var hit := false
		if ink_3d and rig.mode == "3d":
			hit = node.hit_test_ray(origin, dir) >= 0.0
		else:
			hit = node.contains_world_point(point, rig.view_per_pixel() * 9.0)
		if hit:
			project.remove_item(str(item.get("id", "")))
			node.get_parent().remove_child(node)
			node.free()
			item_nodes.erase(str(item.get("id", "")))
			_erased_count += 1
			_haptic(6)
			_connectors_dirty = true


func _end_erase() -> void:
	if _erased_count > 0:
		undo.commit(project, "Erase ink")
		dirty = true
		_schedule_save()
		ui.toast("%d stroke%s erased" % [_erased_count, "" if _erased_count == 1 else "s"], "ink_eraser", Kit.ACCENT, 1.4)
	else:
		undo.cancel()
	_erased_count = 0
	_eraser_pos = Vector2(-9999, -9999)


# ------------------------------------------------------------------ picking / selection

func _pick_item(pos: Vector2) -> String:
	var origin := rig.camera.project_ray_origin(pos)
	var dir := rig.camera.project_ray_normal(pos)
	var best := ""
	var best_dist := INF
	for item in project.items:
		var id := str(item.get("id", ""))
		if str(item.get("type", "")) == "group":
			continue
		if not project.is_layer_visible(str(item.get("layer", ""))):
			continue
		if project.is_layer_locked(str(item.get("layer", ""))):
			continue
		var node: CanvasItem3D = item_nodes.get(id, null)
		if node == null or not node.visible:
			continue
		var d := node.hit_test_ray(origin, dir)
		if d > 0.0 and d < best_dist:
			best_dist = d
			best = id
	return best


func _pick_connector(pos: Vector2) -> String:
	var best := ""
	var best_dist := 14.0
	for c in project.connectors:
		var node: ConnectorNode = connector_nodes.get(str(c.get("id", "")), null)
		if node == null or not node.visible:
			continue
		if not project.is_layer_visible(str(c.get("layer", ""))):
			continue
		var d := node.screen_distance(rig, pos)
		if d < best_dist:
			best_dist = d
			best = str(c.get("id", ""))
	return best


func select_ids(ids: Array, additive := false) -> void:
	var valid := []
	for id in ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		if project.is_layer_locked(str(item.get("layer", ""))):
			continue
		if additive and selected_ids.has(str(id)):
			selected_ids.erase(str(id))
			continue
		if not valid.has(str(id)):
			valid.append(str(id))
	if additive:
		for id in valid:
			if not selected_ids.has(id):
				selected_ids.append(id)
	else:
		selected_ids = valid
	selected_connector_id = ""
	for node in connector_nodes.values():
		if node != null:
			node.set_selected(false)
	if not selected_ids.is_empty():
		_haptic(8)
	if ui != null:
		ui.refresh_selection()
	_update_overlay()


func select_connector(connector_id: String) -> void:
	selected_connector_id = connector_id
	selected_ids.clear()
	for c in connector_nodes:
		var node: ConnectorNode = connector_nodes[c]
		if node != null:
			node.set_selected(c == connector_id)
	_haptic(8)
	ui.refresh_selection()
	_update_overlay()


func get_selected_items() -> Array:
	var result := []
	for id in selected_ids:
		var item := project.get_item(str(id))
		if not item.is_empty():
			result.append(item)
	return result


func get_selected_connector() -> Dictionary:
	if selected_connector_id.is_empty():
		return {}
	for c in project.connectors:
		if str(c.get("id", "")) == selected_connector_id:
			return c
	return {}


func get_selection_summary() -> Dictionary:
	if not selected_connector_id.is_empty():
		var c := get_selected_connector()
		if c.is_empty():
			return {}
		var from_item := project.get_item(str(c.get("from", "")))
		var to_item := project.get_item(str(c.get("to", "")))
		return {
			"count": 1,
			"title": str(c.get("label", "Connection")) if not str(c.get("label", "")).is_empty() else "Connection",
			"subtitle": "%s  →  %s" % [_item_label(from_item), _item_label(to_item)],
			"icon": "polyline",
			"color": str(c.get("color", "#8FA0B8")),
		}
	if selected_ids.is_empty():
		return {}
	if selected_ids.size() == 1:
		var item := project.get_item(str(selected_ids[0]))
		var props: Dictionary = item.get("props", {})
		var type := str(item.get("type", "note"))
		var layer := project.get_layer(str(item.get("layer", "")))
		return {
			"count": 1,
			"title": _item_label(item),
			"subtitle": "%s · %s" % [str(layer.get("name", "Layer")), type.capitalize()],
			"icon": _item_icon(type),
			"color": str(layer.get("color", "#2F5BFF")),
		}
	return {
		"count": selected_ids.size(),
		"title": "%d objects selected" % selected_ids.size(),
		"subtitle": "Move them together or combine them into a group",
		"icon": "group_work",
		"color": "#7455FF",
	}


func _item_label(item: Dictionary) -> String:
	if item.is_empty():
		return "Object"
	var props: Dictionary = item.get("props", {})
	var title := str(props.get("title", "")).strip_edges()
	if title.is_empty():
		title = str(props.get("caption", "")).strip_edges()
	if title.is_empty():
		title = str(item.get("type", "Object")).capitalize()
	return title


func _item_icon(type: String) -> String:
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
		"stroke":
			return "gesture"
		"group":
			return "group_work"
		_:
			return "category"


func _all_selectable_ids() -> Array:
	var ids := []
	for item in project.items:
		if str(item.get("type", "")) == "group":
			continue
		if project.is_layer_visible(str(item.get("layer", ""))) and not project.is_layer_locked(str(item.get("layer", ""))):
			ids.append(str(item.get("id", "")))
	return ids


func _hit_gizmo(pos: Vector2) -> String:
	if active_tool != "select" or selected_ids.is_empty():
		return ""
	if selected_ids.size() != 1:
		return ""
	var geo := _gizmo_geometry()
	for handle in geo.get("handles", []):
		if pos.distance_to(handle.get("pos", Vector2.ZERO)) < 22.0:
			return str(handle.get("kind", "scale"))
	var rotate_pos: Vector2 = geo.get("rotate", Vector2(-9999, -9999))
	if pos.distance_to(rotate_pos) < 24.0:
		return "rotate"
	return ""


func _gizmo_geometry() -> Dictionary:
	var result := {"polys": [], "bounds": Rect2(), "handles": [], "rotate": Vector2(-9999, -9999), "has_bounds": false}
	if selected_ids.is_empty():
		return result
	var bounds := Rect2()
	var first := true
	var primary_poly := PackedVector2Array()
	for id in selected_ids:
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node == null:
			continue
		var poly := PackedVector2Array()
		if node is GroupItem:
			var rect := _node_world_rect(node)
			poly = _screen_poly_from_rect(rect)
		elif node.is_flat():
			var corners := node.get_world_corners()
			for corner in corners:
				poly.append(rig.world_to_screen(corner))
		else:
			var aabb := node.get_bounds_aabb()
			poly = _screen_poly_from_aabb(aabb)
		if poly.size() < 3:
			continue
		result["polys"].append(poly)
		if primary_poly.is_empty():
			primary_poly = poly
		for p in poly:
			if first:
				bounds = Rect2(p, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(p)
	if first:
		return result
	result["bounds"] = bounds
	result["has_bounds"] = true
	if selected_ids.size() == 1:
		var handle_poly := primary_poly
		if handle_poly.size() == 4:
			for p in handle_poly:
				result["handles"].append({"pos": p, "kind": "scale"})
		else:
			result["handles"].append({"pos": bounds.position, "kind": "scale"})
			result["handles"].append({"pos": Vector2(bounds.end.x, bounds.position.y), "kind": "scale"})
			result["handles"].append({"pos": bounds.end, "kind": "scale"})
			result["handles"].append({"pos": Vector2(bounds.position.x, bounds.end.y), "kind": "scale"})
		result["rotate"] = Vector2(bounds.get_center().x, bounds.position.y - 38.0)
	return result


func _screen_poly_from_rect(rect: Rect2) -> PackedVector2Array:
	var poly := PackedVector2Array()
	poly.append(rig.world_to_screen(Vector3(rect.position.x, rect.position.y, 0.05)))
	poly.append(rig.world_to_screen(Vector3(rect.end.x, rect.position.y, 0.05)))
	poly.append(rig.world_to_screen(Vector3(rect.end.x, rect.end.y, 0.05)))
	poly.append(rig.world_to_screen(Vector3(rect.position.x, rect.end.y, 0.05)))
	return poly


func _screen_poly_from_aabb(aabb: AABB) -> PackedVector2Array:
	var points := []
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for i in range(8):
		var corner := aabb.position + Vector3(
			aabb.size.x if (i & 1) else 0.0,
			aabb.size.y if (i & 2) else 0.0,
			aabb.size.z if (i & 4) else 0.0
		)
		var screen := rig.world_to_screen(corner)
		minp = Vector2(minf(minp.x, screen.x), minf(minp.y, screen.y))
		maxp = Vector2(maxf(maxp.x, screen.x), maxf(maxp.y, screen.y))
	var poly := PackedVector2Array([minp, Vector2(maxp.x, minp.y), maxp, Vector2(minp.x, maxp.y)])
	return poly


func _update_overlay() -> void:
	if ui == null:
		return
	if ui.sheet_root.visible or ui.onboarding.visible or ui.modal_root.visible or ui.busy_root.visible:
		if _overlay_visible:
			_overlay_visible = false
			ui.set_overlay_state({})
		return
	var state := {}
	var allow_selection := active_tool == "select"
	if allow_selection and (not selected_ids.is_empty() or not selected_connector_id.is_empty()):
		var geo := _gizmo_geometry()
		state["polys"] = geo.get("polys", [])
		state["bounds"] = geo.get("bounds", Rect2())
		state["has_bounds"] = geo.get("has_bounds", false)
		state["handles"] = geo.get("handles", [])
		state["rotate_pos"] = geo.get("rotate", Vector2(-9999, -9999))
		if not selected_connector_id.is_empty():
			var connector: ConnectorNode = connector_nodes.get(selected_connector_id, null)
			if connector != null:
				var poly := PackedVector2Array()
				for sample in connector._samples:
					poly.append(rig.world_to_screen(sample))
				state["connector"] = poly
	if not _marquee.size.is_zero_approx():
		state["marquee"] = _marquee
	if not _guides_v.is_empty():
		state["guides_v"] = _guides_v
	if not _guides_h.is_empty():
		state["guides_h"] = _guides_h
	if not _drag_label.is_empty():
		state["drag_label"] = _drag_label
		state["label_pos"] = _drag_label_pos
	if active_tool in ["pen", "highlighter"]:
		state["pen_cursor"] = {"pos": _pen_pos, "radius": maxf(3.0, pen_size * 3.0), "color": pen_color}
	if active_tool == "eraser":
		state["eraser_cursor"] = {"pos": _eraser_pos, "radius": 22.0}
	ui.set_overlay_state(state)
	_overlay_visible = true


func _world_point(pos: Vector2) -> Vector3:
	var z := 0.07 + (project.items.size() % 12) * 0.001
	return rig.screen_to_plane(pos, z)


# ------------------------------------------------------------------ move / scale / rotate

func _begin_move(down: Vector2) -> void:
	if selected_ids.is_empty():
		return
	undo.begin(project)
	_move_start_positions.clear()
	_last_pos = down
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		_move_start_positions[str(id)] = _to_vec3(item.get("pos", [0, 0, 0]))
	var primary: CanvasItem3D = item_nodes.get(str(selected_ids[0]), null)
	_move_plane_z = primary.global_position.z if primary != null else 0.05
	_move_start_world = rig.screen_to_plane(down, _move_plane_z)
	_move_other_rects.clear()
	if selected_ids.size() == 1:
		for item in project.items:
			if selected_ids.has(str(item.get("id", ""))) or str(item.get("type", "")) == "group":
				continue
			if not project.is_layer_visible(str(item.get("layer", ""))):
				continue
			var node: CanvasItem3D = item_nodes.get(str(item.get("id", "")), null)
			if node != null:
				_move_other_rects.append(_node_world_rect(node))
			if _move_other_rects.size() >= 90:
				break
	_gesture = "move"
	_haptic(8)


func _apply_move(pos: Vector2) -> void:
	if selected_ids.is_empty():
		return
	var world := rig.screen_to_plane(pos, _move_plane_z)
	var delta := world - _move_start_world
	_guides_v.clear()
	_guides_h.clear()
	var primary_rect := Rect2()
	var has_primary_rect := false
	var moved_group := false
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		var start: Vector3 = _move_start_positions.get(str(id), _to_vec3(item.get("pos", [0, 0, 0])))
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		var local_delta := delta
		if node != null and node.get_parent() != content:
			local_delta = node.get_parent().global_transform.basis.affine_inverse() * delta
		var next := start + local_delta
		if bool(project.settings.get("snap", true)):
			var grid_step := float(project.settings.get("grid", 1.0))
			next.x = snappedf(next.x, grid_step)
			next.y = snappedf(next.y, grid_step)
		item["pos"] = [next.x, next.y, next.z]
		if node != null:
			node.position = next
			node._read_transform()
			if selected_ids.size() == 1:
				primary_rect = _node_world_rect(node)
				has_primary_rect = true
			if node is GroupItem or not project.descendants_of(str(id)).is_empty():
				moved_group = true
		_refresh_connectors_for(str(id))
	if has_primary_rect and bool(project.settings.get("snap", true)):
		_apply_alignment(primary_rect)
	if moved_group:
		_refresh_connectors()
	_drag_label = "X %.2f   Y %.2f" % [delta.x, delta.y]
	_drag_label_pos = pos
	_update_overlay()


func _apply_alignment(rect: Rect2) -> void:
	var threshold := 8.0 * rig.world_per_pixel()
	var best_dx := INF
	var best_dy := INF
	var guide_x := 0.0
	var guide_y := 0.0
	var x_anchors := [rect.position.x, rect.get_center().x, rect.end.x]
	var y_anchors := [rect.position.y, rect.get_center().y, rect.end.y]
	for other in _move_other_rects:
		var other_x := [other.position.x, other.get_center().x, other.end.x]
		var other_y := [other.position.y, other.get_center().y, other.end.y]
		for ax in x_anchors:
			for bx in other_x:
				var diff: float = float(bx) - float(ax)
				if absf(diff) < threshold and absf(diff) < absf(best_dx):
					best_dx = diff
					guide_x = float(bx)
		for ay in y_anchors:
			for by in other_y:
				var diff2: float = float(by) - float(ay)
				if absf(diff2) < threshold and absf(diff2) < absf(best_dy):
					best_dy = diff2
					guide_y = float(by)
	if best_dx == INF and best_dy == INF:
		return
	var id := str(selected_ids[0])
	var item := project.get_item(id)
	var node: CanvasItem3D = item_nodes.get(id, null)
	if item.is_empty() or node == null:
		return
	var pos := _to_vec3(item.get("pos", [0, 0, 0]))
	if best_dx != INF:
		pos.x += best_dx
		_guides_v.append(rig.world_to_screen(Vector3(guide_x, rect.get_center().y, 0.05)).x)
	if best_dy != INF:
		pos.y += best_dy
		_guides_h.append(rig.world_to_screen(Vector3(rect.get_center().x, guide_y, 0.05)).y)
	item["pos"] = [pos.x, pos.y, pos.z]
	node.position = pos
	node._read_transform()
	_refresh_connectors_for(id)
	_haptic(5)


func _finish_move() -> void:
	_guides_v.clear()
	_guides_h.clear()
	_drag_label = ""
	if undo.commit(project, "Move objects"):
		dirty = true
		_schedule_save()
		ui.refresh_selection()
		ui.refresh()
	_update_overlay()


func _begin_scale(down: Vector2) -> void:
	if selected_ids.size() != 1:
		return
	var geo := _gizmo_geometry()
	_gizmo_item_id = str(selected_ids[0])
	_gizmo_center = geo.get("bounds", Rect2()).get_center()
	_gizmo_start_dist = maxf(10.0, down.distance_to(_gizmo_center))
	var item := project.get_item(_gizmo_item_id)
	_gizmo_start_scale = _to_vec3(item.get("scale", [1, 1, 1]))
	undo.begin(project)
	_gesture = "scale"
	_haptic(8)


func _apply_scale(pos: Vector2) -> void:
	var item := project.get_item(_gizmo_item_id)
	var node: CanvasItem3D = item_nodes.get(_gizmo_item_id, null)
	if item.is_empty() or node == null:
		return
	var dist := maxf(10.0, pos.distance_to(_gizmo_center))
	var factor := dist / maxf(1.0, _gizmo_start_dist)
	var next := _gizmo_start_scale * factor
	next.x = clampf(next.x, 0.15, 8.0)
	next.y = clampf(next.y, 0.15, 8.0)
	next.z = clampf(next.z, 0.15, 8.0)
	if bool(project.settings.get("snap", true)):
		next.x = snappedf(next.x, 0.05)
		next.y = snappedf(next.y, 0.05)
		next.z = snappedf(next.z, 0.05)
	item["scale"] = [next.x, next.y, next.z]
	node._read_transform()
	_drag_label = "Scale %.2f×" % next.x
	_drag_label_pos = pos
	_refresh_connectors_for(_gizmo_item_id)
	_update_overlay()


func _finish_scale() -> void:
	_drag_label = ""
	if undo.commit(project, "Scale object"):
		dirty = true
		_schedule_save()
		ui.refresh_selection()
	_update_overlay()


func _begin_rotate(down: Vector2) -> void:
	if selected_ids.size() != 1:
		return
	var geo := _gizmo_geometry()
	_gizmo_item_id = str(selected_ids[0])
	_gizmo_center = geo.get("bounds", Rect2()).get_center()
	_gizmo_start_angle = (down - _gizmo_center).angle()
	var item := project.get_item(_gizmo_item_id)
	var rot := _to_vec3(item.get("rot", [0, 0, 0]))
	_gizmo_start_rot = rot.z
	undo.begin(project)
	_gesture = "rotate"
	_haptic(8)


func _apply_rotate(pos: Vector2) -> void:
	var item := project.get_item(_gizmo_item_id)
	var node: CanvasItem3D = item_nodes.get(_gizmo_item_id, null)
	if item.is_empty() or node == null:
		return
	var angle := (pos - _gizmo_center).angle()
	var delta := rad_to_deg(angle - _gizmo_start_angle)
	var next := _gizmo_start_rot + delta
	var snap_angle := float(project.settings.get("snap_angle", 15.0))
	if bool(project.settings.get("snap", true)) and snap_angle > 0.0:
		next = snappedf(next, snap_angle)
	var rot := _to_vec3(item.get("rot", [0, 0, 0]))
	rot.z = next
	item["rot"] = [rot.x, rot.y, rot.z]
	node._read_transform()
	_drag_label = "Rotate %d°" % int(round(next))
	_drag_label_pos = pos
	_refresh_connectors_for(_gizmo_item_id)
	_update_overlay()


func _finish_rotate() -> void:
	_drag_label = ""
	if undo.commit(project, "Rotate object"):
		dirty = true
		_schedule_save()
		ui.refresh_selection()
	_update_overlay()


func _apply_marquee() -> void:
	var rect := _marquee.abs()
	_marquee = Rect2()
	var ids := []
	if rect.size.x > 6.0 and rect.size.y > 6.0:
		for item in project.items:
			if str(item.get("type", "")) == "group":
				continue
			if not project.is_layer_visible(str(item.get("layer", ""))) or project.is_layer_locked(str(item.get("layer", ""))):
				continue
			var node: CanvasItem3D = item_nodes.get(str(item.get("id", "")), null)
			if node == null:
				continue
			var r := _screen_rect_for_node(node)
			if r.intersects(rect):
				ids.append(str(item.get("id", "")))
	select_ids(ids)
	ui.refresh_selection()


func _screen_rect_for_node(node: CanvasItem3D) -> Rect2:
	if node is GroupItem:
		var rect := _node_world_rect(node)
		var poly := _screen_poly_from_rect(rect)
		var minp := Vector2(INF, INF)
		var maxp := Vector2(-INF, -INF)
		for p in poly:
			minp = Vector2(minf(minp.x, p.x), minf(minp.y, p.y))
			maxp = Vector2(maxf(maxp.x, p.x), maxf(maxp.y, p.y))
		return Rect2(minp, maxp - minp)
	if node.is_flat():
		var corners := node.get_world_corners()
		var minp := Vector2(INF, INF)
		var maxp := Vector2(-INF, -INF)
		for c in corners:
			var s := rig.world_to_screen(c)
			minp = Vector2(minf(minp.x, s.x), minf(minp.y, s.y))
			maxp = Vector2(maxf(maxp.x, s.x), maxf(maxp.y, s.y))
		return Rect2(minp, maxp - minp)
	var aabb := node.get_bounds_aabb()
	var min_screen := rig.world_to_screen(aabb.position)
	var max_screen := min_screen
	for i in range(8):
		var corner := aabb.position + Vector3(
			aabb.size.x if (i & 1) else 0.0,
			aabb.size.y if (i & 2) else 0.0,
			aabb.size.z if (i & 4) else 0.0
		)
		var s := rig.world_to_screen(corner)
		min_screen = Vector2(minf(min_screen.x, s.x), minf(min_screen.y, s.y))
		max_screen = Vector2(maxf(max_screen.x, s.x), maxf(max_screen.y, s.y))
	return Rect2(min_screen, max_screen - min_screen)


func _on_long_press() -> void:
	if _gesture == "pending" and not _moved and not _pending_item.is_empty():
		_suppress_tap = true
		select_ids([_pending_item])
		ui.open_sheet("inspector")
		_haptic(18)


# ------------------------------------------------------------------ creation

func get_note_themes() -> Array:
	return NOTE_PAPERS


func create_at_center(kind: String) -> void:
	var point := rig.screen_to_plane(rig.screen_center(), 0.07)
	_create_item_at(kind, point)


func _create_item_at(kind: String, world_point: Vector3) -> Dictionary:
	var item: Dictionary = {}
	match kind:
		"note", "text":
			var idx := project.items.size() % NOTE_PAPERS.size()
			var paper: Dictionary = NOTE_PAPERS[idx]
			var accent := str(project.settings.get("accent", paper["accent"]))
			var props := {
				"title": "New idea" if kind == "note" else "Text",
				"body": "",
				"color": paper["color"],
				"accent": accent,
				"tags": [],
				"pinned": false,
				"style": kind,
				"width": 5.6,
			}
			undo.begin(project)
			item = project.add_item(kind, world_point, props, project.active_layer_id)
			undo.commit(project, "Add " + kind)
			_spawn_for_item(item, true)
			ui.refresh()
			ui.toast("Text placed" if kind == "text" else "Note placed · double-tap to edit", "sticky_note_2", Kit.ACCENT, 1.7)
			_schedule_save()
			_haptic(14)
		"shape":
			var props := {
				"shape": "rect",
				"w": 3.2,
				"h": 2.2,
				"color": _hex(pen_color),
				"border_color": _hex(pen_color.lightened(0.15)),
				"border_width": 0.04,
				"opacity": 0.18,
				"filled": true,
				"corner": 0.24,
			}
			undo.begin(project)
			item = project.add_item("shape", world_point, props, project.active_layer_id)
			undo.commit(project, "Add shape")
			_spawn_for_item(item, true)
			ui.refresh()
			_schedule_save()
			_haptic(12)
		"frame":
			item = _add_frame_at(world_point)
		"primitive":
			item = _add_primitive_at("box", world_point)
		_:
			return {}
	if not item.is_empty():
		select_ids([str(item.get("id", ""))])
		_update_overlay()
	return item


func _add_frame_at(world_point: Vector3) -> Dictionary:
	var order := project.next_frame_order()
	var props := {
		"title": "Untitled shot",
		"body": "Describe the action, camera and mood.",
		"order": order,
		"duration": 3.0,
		"status": "Draft",
	}
	undo.begin(project)
	var item := project.add_item("frame", world_point, props, project.active_layer_id)
	project.sync_storyboard()
	project.storyboard["current"] = maxi(0, project.frames().size() - 1)
	undo.commit(project, "Add frame")
	_spawn_for_item(item, true)
	ui.refresh()
	ui.toast("Frame %02d added" % order, "movie", Kit.GOLD, 1.6)
	_schedule_save()
	_haptic(14)
	return item


func _add_primitive(shape: String) -> void:
	var center := rig.screen_to_plane(rig.screen_center(), 0.4)
	var item := _add_primitive_at(shape, center)
	if not item.is_empty():
		ui.close_sheet()
		select_ids([str(item.get("id", ""))])
		ui.toast("%s added · edit its material in the inspector" % shape.capitalize(), "view_in_ar", Kit.ACCENT, 2.2)


func _add_primitive_at(shape: String, world_point: Vector3) -> Dictionary:
	var props := {"shape": shape, "size": 1.7, "color": "#2F5BFF", "metallic": 0.38, "roughness": 0.32, "emission": "#000000", "emission_energy": 0.0, "show_label": false, "title": shape.capitalize()}
	var objects_layer := "lyr_objects" if not project.get_layer("lyr_objects").is_empty() else project.active_layer_id
	undo.begin(project)
	var item := project.add_item("primitive", Vector3(world_point.x, world_point.y, 0.8), props, objects_layer)
	item["rot"] = [14.0, 32.0, 0.0]
	undo.commit(project, "Add 3D object")
	_spawn_for_item(item, false)
	ui.refresh()
	_schedule_save()
	_haptic(14)
	return item


func add_primitive(shape: String) -> void:
	_add_primitive(shape)


func _ink_layer() -> String:
	if not project.get_layer("lyr_ink").is_empty():
		return "lyr_ink"
	return project.active_layer_id


# ------------------------------------------------------------------ inspector edits

func begin_inspector_session() -> void:
	if inspector_active:
		return
	undo.begin(project)
	inspector_active = true


func end_inspector_session() -> void:
	if not inspector_active:
		return
	inspector_active = false
	if undo.commit(project, "Edit object"):
		dirty = true
		_schedule_save()
	_refresh_all_selected_nodes()


func _refresh_all_selected_nodes() -> void:
	for id in selected_ids:
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
			_refresh_connectors_for(str(id))
	_connectors_dirty = true


func update_text_prop(item_id: String, key: String, value: String) -> void:
	var item := project.get_item(item_id)
	if item.is_empty():
		return
	var props: Dictionary = item.get("props", {})
	if key == "tags":
		var tags := []
		for part in value.split(",", false):
			var t := part.strip_edges().trim_prefix("#")
			if not t.is_empty():
				tags.append(t)
		props["tags"] = tags
	else:
		props[key] = value
	var node: CanvasItem3D = item_nodes.get(item_id, null)
	if node != null:
		node.refresh_from_data()
	_refresh_connectors_for(item_id)
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func set_note_theme(color_hex: String, accent_hex: String) -> void:
	if not inspector_active:
		_begin_live_undo("Change note colour")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		if str(item.get("type", "")) not in ["note", "text"]:
			continue
		item.get("props", {})["color"] = color_hex
		item.get("props", {})["accent"] = accent_hex
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func pin_selection(pinned: bool) -> void:
	if not inspector_active:
		_begin_live_undo("Pin note")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		item.get("props", {})["pinned"] = pinned
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func update_selected_props(values: Dictionary) -> void:
	if selected_ids.is_empty():
		return
	if not inspector_active:
		_begin_live_undo("Edit object")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		var props: Dictionary = item.get("props", {})
		for key in values.keys():
			props[key] = values[key]
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
		_refresh_connectors_for(str(id))
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func update_model_material(key: String, value: float) -> void:
	if not inspector_active:
		_begin_live_undo("Edit material")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		var props: Dictionary = item.get("props", {})
		var material: Dictionary = props.get("material", {})
		material[key] = value
		props["material"] = material
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
	dirty = true
	_schedule_save()


func set_selected_glow(value: float) -> void:
	if not inspector_active:
		_begin_live_undo("Edit glow")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		var props: Dictionary = item.get("props", {})
		var color := str(props.get("color", "#2F5BFF"))
		props["emission"] = color if value > 0.01 else "#000000"
		props["emission_energy"] = value * 3.0
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.refresh_from_data()
	dirty = true
	_schedule_save()


func set_transform_field(key: String, value: float) -> void:
	if selected_ids.is_empty():
		return
	var own := not inspector_active
	if own:
		_begin_live_undo("Transform")
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		var pos := _to_vec3(item.get("pos", [0, 0, 0]))
		var rot := _to_vec3(item.get("rot", [0, 0, 0]))
		var scale := _to_vec3(item.get("scale", [1, 1, 1]))
		match key:
			"x":
				pos.x = value
			"y":
				pos.y = value
			"z":
				pos.z = value
			"rot":
				rot.z = value
			"scale":
				scale = Vector3(value, value, value)
		item["pos"] = [pos.x, pos.y, pos.z]
		item["rot"] = [rot.x, rot.y, rot.z]
		item["scale"] = [scale.x, scale.y, scale.z]
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node._read_transform()
		_refresh_connectors_for(str(id))
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func move_selection_to_layer(layer_id: String) -> void:
	if selected_ids.is_empty() or project.get_layer(layer_id).is_empty():
		return
	var own := not inspector_active
	if own:
		undo.begin(project)
	for id in selected_ids:
		var item := project.get_item(str(id))
		if item.is_empty():
			continue
		item["layer"] = layer_id
		for d in project.descendants_of(str(id)):
			d["layer"] = layer_id
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			node.apply_layer_state()
		for d in project.descendants_of(str(id)):
			var dn: CanvasItem3D = item_nodes.get(str(d.get("id", "")), null)
			if dn != null:
				dn.apply_layer_state()
	if own:
		undo.commit(project, "Move to layer")
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func set_connector_props(values: Dictionary) -> void:
	if selected_connector_id.is_empty():
		return
	var own := not inspector_active
	if own:
		undo.begin(project)
	for c in project.connectors:
		if str(c.get("id", "")) == selected_connector_id:
			for key in values.keys():
				c[key] = values[key]
			break
	var node: ConnectorNode = connector_nodes.get(selected_connector_id, null)
	if node != null:
		node.data = get_selected_connector()
		node.refresh(rig.view_height)
	if own:
		undo.commit(project, "Edit connection")
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	_update_overlay()


func select_connector_source() -> void:
	var c := get_selected_connector()
	if c.is_empty():
		return
	select_ids([str(c.get("from", ""))])


func duplicate_selection() -> void:
	if selected_ids.is_empty() and selected_connector_id.is_empty():
		return
	undo.begin(project)
	var mapping := {}
	var new_ids := []
	if not selected_connector_id.is_empty():
		var c := get_selected_connector()
		if not c.is_empty():
			var copy: Dictionary = c.duplicate(true)
			copy["id"] = CanvasProject.gen_id("cn")
			project.connectors.append(copy)
			undo.commit(project, "Duplicate link")
			selected_connector_id = str(copy.get("id", ""))
			_add_connector_node(copy)
			dirty = true
			_schedule_save()
			ui.refresh()
			return
	for id in selected_ids:
		var copy := _duplicate_item_recursive(str(id), mapping)
		if not copy.is_empty():
			new_ids.append(str(copy.get("id", "")))
	for c in project.connectors.duplicate():
		var from_id := str(c.get("from", ""))
		var to_id := str(c.get("to", ""))
		if mapping.has(from_id) and mapping.has(to_id):
			var copy_c: Dictionary = c.duplicate(true)
			copy_c["id"] = CanvasProject.gen_id("cn")
			copy_c["from"] = mapping[from_id]
			copy_c["to"] = mapping[to_id]
			project.connectors.append(copy_c)
			_add_connector_node(copy_c)
	for item in project.items:
		if str(item.get("id", "")) in mapping.values():
			_spawn_for_item(item, false)
	undo.commit(project, "Duplicate objects")
	select_ids(new_ids)
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("Duplicated", "content_copy", Kit.GREEN, 1.3)


func _duplicate_item_recursive(item_id: String, mapping: Dictionary) -> Dictionary:
	var item := project.get_item(item_id)
	if item.is_empty():
		return {}
	var copy: Dictionary = item.duplicate(true)
	copy["id"] = CanvasProject.gen_id("it")
	var pos := _to_vec3(copy.get("pos", [0, 0, 0]))
	pos += Vector3(0.45, -0.45, 0.002)
	copy["pos"] = [pos.x, pos.y, pos.z]
	project.items.append(copy)
	mapping[item_id] = str(copy["id"])
	for child in project.children_of(item_id):
		var child_copy := _duplicate_item_recursive(str(child.get("id", "")), mapping)
		if not child_copy.is_empty():
			child_copy["parent"] = str(copy["id"])
	return copy


func _delete_selection_now() -> void:
	if selected_connector_id.is_empty() and selected_ids.is_empty():
		return
	undo.begin(project)
	if not selected_connector_id.is_empty():
		var cid := selected_connector_id
		var node: ConnectorNode = connector_nodes.get(cid, null)
		if node != null:
			node.get_parent().remove_child(node)
			node.free()
		connector_nodes.erase(cid)
		project.remove_connector(cid)
		selected_connector_id = ""
		undo.commit(project, "Delete link")
	else:
		var ids := selected_ids.duplicate()
		for id in ids:
			var node: CanvasItem3D = item_nodes.get(str(id), null)
			if node != null:
				for d in project.descendants_of(str(id)):
					var dn: CanvasItem3D = item_nodes.get(str(d.get("id", "")), null)
					if dn != null:
						dn.get_parent().remove_child(dn)
						dn.free()
						item_nodes.erase(str(d.get("id", "")))
				node.get_parent().remove_child(node)
				node.free()
				item_nodes.erase(str(id))
			project.remove_item(str(id))
		undo.commit(project, "Delete objects")
		selected_ids.clear()
	_build_connectors()
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.refresh_selection()
	_update_overlay()
	_haptic(20)


func group_selection() -> void:
	if selected_ids.size() < 2:
		ui.toast("Select two or more objects to group", "group_work", Kit.GOLD)
		return
	undo.begin(project)
	var center := Vector3.ZERO
	var count := 0
	for id in selected_ids:
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node != null:
			center += node.global_position
			count += 1
	if count > 0:
		center /= float(count)
	var group := project.add_item("group", center, {"title": "Group"}, project.active_layer_id)
	var group_id := str(group.get("id", ""))
	var group_node := _spawn_for_item(group, false)
	for id in selected_ids.duplicate():
		if str(id) == group_id:
			continue
		var item := project.get_item(str(id))
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if item.is_empty() or node == null:
			continue
		if not str(item.get("parent", "")).is_empty():
			continue
		var world := node.global_position
		var rot := node.global_transform.basis.get_euler()
		var scl := node.global_transform.basis.get_scale()
		item["parent"] = group_id
		var local := group_node.to_local(world)
		item["pos"] = [local.x, local.y, local.z]
		item["rot"] = [0.0, 0.0, rad_to_deg(rot.z)]
		item["scale"] = [scl.x, scl.y, scl.z]
		node.get_parent().remove_child(node)
		group_node.add_child(node)
		node.position = local
		node.rotation = Vector3(0, 0, rot.z)
		node.scale = scl
		_refresh_connectors_for(str(id))
	undo.commit(project, "Group objects")
	select_ids([group_id])
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.refresh_selection()
	ui.toast("Grouped %d objects" % count, "group_work", Kit.GREEN)
	_update_overlay()


func ungroup_selection() -> void:
	var groups := []
	for id in selected_ids:
		var item := project.get_item(str(id))
		if not item.is_empty() and str(item.get("type", "")) == "group":
			groups.append(item)
	if groups.is_empty():
		ui.toast("Select a group to ungroup", "group_work", Kit.GOLD)
		return
	undo.begin(project)
	var child_ids := []
	for group in groups:
		var group_id := str(group.get("id", ""))
		var group_node: CanvasItem3D = item_nodes.get(group_id, null)
		if group_node == null:
			continue
		var parent_of_group: Node3D = group_node.get_parent()
		var parent_is_content := parent_of_group == content
		for child in project.children_of(group_id):
			var child_id := str(child.get("id", ""))
			var node: CanvasItem3D = item_nodes.get(child_id, null)
			if node == null:
				continue
			var world := node.global_transform
			child["parent"] = ""
			if not parent_is_content:
				# Move into the group's parent, preserving local placement.
				var local := parent_of_group.to_local(world.origin)
				child["pos"] = [local.x, local.y, local.z]
			else:
				child["pos"] = [world.origin.x, world.origin.y, world.origin.z]
			node.get_parent().remove_child(node)
			parent_of_group.add_child(node)
			node.global_transform = world
			child_ids.append(child_id)
		group_node.get_parent().remove_child(group_node)
		group_node.free()
		item_nodes.erase(group_id)
		project.items.erase(group)
	undo.commit(project, "Ungroup")
	select_ids(child_ids)
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.refresh_selection()
	_update_overlay()


# ------------------------------------------------------------------ layers

func add_layer() -> void:
	undo.begin(project)
	var idx := project.layers.size() + 1
	var colors := ["#2F5BFF", "#7455FF", "#B8780F", "#0C8F6A", "#E05A44", "#8FA0B8"]
	var layer := project.add_layer("Layer %d" % idx, colors[int(idx - 1) % colors.size()])
	undo.commit(project, "Add layer")
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("Layer added", "layers", Kit.ACCENT, 1.4)


func set_active_layer(layer_id: String) -> void:
	if project.get_layer(layer_id).is_empty():
		return
	project.active_layer_id = layer_id
	ui.toast("Active layer: " + str(project.get_layer(layer_id).get("name", "Layer")), "layers", Kit.ACCENT, 1.3)
	_schedule_save()


func toggle_layer_visible(layer_id: String) -> void:
	var layer := project.get_layer(layer_id)
	if layer.is_empty():
		return
	undo.begin(project)
	layer["visible"] = not bool(layer.get("visible", true))
	for item in project.items_in_layer(layer_id):
		var node: CanvasItem3D = item_nodes.get(str(item.get("id", "")), null)
		if node != null:
			node.apply_layer_state()
	for c in project.connectors:
		var node: ConnectorNode = connector_nodes.get(str(c.get("id", "")), null)
		if node != null and str(c.get("layer", "")) == layer_id:
			node.visible = bool(layer["visible"])
	undo.commit(project, "Toggle layer")
	dirty = true
	_schedule_save()
	ui.refresh()


func toggle_layer_locked(layer_id: String) -> void:
	var layer := project.get_layer(layer_id)
	if layer.is_empty():
		return
	undo.begin(project)
	layer["locked"] = not bool(layer.get("locked", false))
	undo.commit(project, "Lock layer")
	if layer["locked"]:
		selected_ids = selected_ids.filter(func(id):
			var item := project.get_item(str(id))
			return not item.is_empty() and str(item.get("layer", "")) != layer_id
		)
	dirty = true
	_schedule_save()
	ui.refresh_selection()
	ui.refresh()


func rename_layer(layer_id: String, new_name: String) -> void:
	var layer := project.get_layer(layer_id)
	if layer.is_empty():
		return
	undo.begin(project)
	layer["name"] = new_name.strip_edges()
	undo.commit(project, "Rename layer")
	dirty = true
	_schedule_save()
	ui.refresh()


func set_layer_color(layer_id: String, hex: String) -> void:
	var layer := project.get_layer(layer_id)
	if layer.is_empty():
		return
	undo.begin(project)
	layer["color"] = hex
	undo.commit(project, "Layer colour")
	dirty = true
	_schedule_save()
	ui.refresh()


func move_layer(layer_id: String, direction: int) -> void:
	var index := -1
	for i in range(project.layers.size()):
		if str(project.layers[i].get("id", "")) == layer_id:
			index = i
			break
	if index < 0:
		return
	var target := clampi(index + direction, 0, project.layers.size() - 1)
	if target == index:
		return
	undo.begin(project)
	var layer: Dictionary = project.layers.pop_at(index)
	project.layers.insert(target, layer)
	undo.commit(project, "Reorder layers")
	dirty = true
	_schedule_save()
	ui.refresh()


func delete_layer(layer_id: String) -> void:
	if project.layers.size() <= 1:
		ui.toast("A board needs at least one layer", "layers", Kit.GOLD)
		return
	var target_layer := ""
	for layer in project.layers:
		if str(layer.get("id", "")) != layer_id:
			target_layer = str(layer.get("id", ""))
			break
	if target_layer.is_empty():
		return
	undo.begin(project)
	for item in project.items:
		if str(item.get("layer", "")) == layer_id:
			item["layer"] = target_layer
	project.layers = project.layers.filter(func(l): return str(l.get("id", "")) != layer_id)
	if project.active_layer_id == layer_id:
		project.active_layer_id = target_layer
	undo.commit(project, "Delete layer")
	_rebuild_scene(true)
	dirty = true
	_schedule_save()
	ui.refresh()


# ------------------------------------------------------------------ smart studio

func get_templates() -> Array:
	return [
		{"id": "mindmap", "title": "Mind map", "subtitle": "A central idea with six branches and links", "icon": "account_tree", "accent": "#2F5BFF", "premium": false},
		{"id": "storyboard", "title": "Storyboard", "subtitle": "Six cinematic frames, sequenced", "icon": "movie", "accent": "#7455FF", "premium": false},
		{"id": "moodboard", "title": "Moodboard", "subtitle": "Tone, texture and colour direction", "icon": "palette", "accent": "#B8780F", "premium": false},
		{"id": "swot", "title": "SWOT sprint", "subtitle": "Four quadrants for a strategy session", "icon": "grid_view", "accent": "#0C8F6A", "premium": false},
		{"id": "kanban", "title": "Kanban flow", "subtitle": "Now, next and later in space", "icon": "view_week", "accent": "#E05A44", "premium": false},
		{"id": "pitch", "title": "Pitch deck", "subtitle": "Storyboard a four-beat product pitch", "icon": "rocket_launch", "accent": "#B8780F", "premium": true},
		{"id": "research", "title": "Research wall", "subtitle": "Signals, insights and opportunities", "icon": "school", "accent": "#7455FF", "premium": true},
	]


func apply_template(template_id: String) -> void:
	var template := {}
	for t in get_templates():
		if str(t.get("id", "")) == template_id:
			template = t
			break
	if template.is_empty():
		ui.toast("Template not found", "warning", Kit.DANGER)
		return
	ui.close_sheet()
	undo.begin(project)
	var center := rig.screen_to_plane(rig.screen_center(), 0.07)
	var accent := str(template.get("accent", "#2F5BFF"))
	var created := []
	match template_id:
		"mindmap":
			created = _template_mindmap(center, accent)
		"storyboard":
			created = _template_storyboard(center, accent)
		"moodboard":
			created = _template_moodboard(center, accent)
		"swot":
			created = _template_swot(center, accent)
		"kanban":
			created = _template_kanban(center, accent)
		"pitch":
			created = _template_pitch(center, accent)
		"research":
			created = _template_research(center, accent)
		"welcome":
			created = _template_welcome(center)
		_:
			pass
	undo.commit(project, "Use template")
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.refresh_selection()
	_schedule_focus_ids(created, 1.3, 30.0)
	_haptic(18)
	ui.toast("%s template added" % str(template.get("title", "Board")), "dashboard_customize", Kit.GREEN)
	call_deferred("_maybe_show_interstitial")


func _schedule_focus_ids(ids: Array, margin := 1.35, max_height := 0.0) -> void:
	if ids.is_empty():
		return
	await get_tree().process_frame
	_focus_bounds_of(ids, margin)
	if max_height > 0.0:
		rig.view_height_target = minf(rig.view_height_target, max_height)


func _template_note(pos: Vector3, title: String, body: String, accent: String, tags: Array = [], paper_index := -1) -> Dictionary:
	var idx := paper_index
	if idx < 0:
		idx = project.items.size() % NOTE_PAPERS.size()
	var paper: Dictionary = NOTE_PAPERS[idx % NOTE_PAPERS.size()]
	var props := {
		"title": title,
		"body": body,
		"color": paper["color"],
		"accent": accent,
		"tags": tags,
		"pinned": false,
		"style": "note",
		"width": 5.4,
	}
	var item := project.add_item("note", pos, props, project.active_layer_id)
	_spawn_for_item(item, false)
	return item


func _template_frame(pos: Vector3, order: int, title: String, body: String, accent := "#2F5BFF", duration := 3.0, status := "Draft") -> Dictionary:
	var props := {
		"title": title,
		"body": body,
		"order": order,
		"duration": duration,
		"status": status,
	}
	var item := project.add_item("frame", pos, props, project.active_layer_id)
	_spawn_for_item(item, false)
	return item


func _template_link(from_id: String, to_id: String, color: String, label := "") -> void:
	var connector := project.add_connector(from_id, to_id, "curve", color, label)
	if not connector.is_empty():
		_add_connector_node(connector)


func _template_mindmap(center: Vector3, accent: String) -> Array:
	var ids := []
	var root := _template_note(center + Vector3(0, 0.5, 0), "Big idea", "The single thought this board should make undeniable. Write it, then branch outward.", accent, ["core"], 1)
	ids.append(str(root.get("id", "")))
	var branches := [
		["Audience", "Who feels this problem most sharply?", 0.0],
		["Problem", "What is expensive, slow or confusing today?", 60.0],
		["Insight", "What do we understand that others miss?", 120.0],
		["Solution", "The smallest product that creates real relief.", 180.0],
		["Proof", "Evidence, metrics and stories that make it true.", 240.0],
		["Next step", "The one action that moves this forward this week.", 300.0],
	]
	for i in range(branches.size()):
		var angle := deg_to_rad(branches[i][2])
		var pos := center + Vector3(cos(angle) * 10.0, sin(angle) * 6.5 - 0.4, 0.0)
		var note := _template_note(pos, branches[i][0], branches[i][1], accent, ["branch"], i)
		ids.append(str(note.get("id", "")))
		_template_link(str(root.get("id", "")), str(note.get("id", "")), accent)
	return ids


func _template_storyboard(center: Vector3, accent: String) -> Array:
	var ids := []
	var title := _template_note(center + Vector3(-7.4, 8.2, 0), "Sequence the story", "Six beats: hook, context, tension, turn, resolution, call to action.", accent, ["storyboard"], 3)
	ids.append(str(title.get("id", "")))
	var beats := [
		["Opening image", "A single frame that sets the world.", "Ready"],
		["Inciting moment", "The disruption that starts the story.", "Ready"],
		["Rising tension", "Stakes grow; the old way stops working.", "Draft"],
		["The turn", "A new idea changes the direction.", "Draft"],
		["Resolution", "The idea lands; show the change.", "Draft"],
		["Last image", "Echo the opening with a new meaning.", "Draft"],
	]
	for i in range(beats.size()):
		var col := i % 3
		var row := int(i / 3)
		var pos := center + Vector3(-7.4 + col * 7.4, 2.4 - row * 6.0, 0.0)
		var frame := _template_frame(pos, i + 1, beats[i][0], beats[i][1], accent, 3.0, beats[i][2])
		ids.append(str(frame.get("id", "")))
	project.sync_storyboard()
	project.storyboard["current"] = 0
	return ids


func _template_moodboard(center: Vector3, accent: String) -> Array:
	var ids := []
	var notes := [
		["Tone", "Quiet confidence. Warm light, precise type, nothing shouting.", Vector3(-8.2, 3.2, 0)],
		["Texture", "Fine paper grain under glass. Soft edges, hard ideas.", Vector3(-1.4, 4.2, 0)],
		["Palette", "Midnight navy, electric cyan, one warm accent to guide the eye.", Vector3(5.6, 3.4, 0)],
		["Motion", "Slow orbits and gentle parallax. Let depth do the talking.", Vector3(-6.2, -3.0, 0)],
		["Materials", "Matte ceramic, smoked glass, brushed metal.", Vector3(2.4, -3.8, 0)],
	]
	for i in range(notes.size()):
		var note := _template_note(center + notes[i][2], notes[i][0], notes[i][1], accent, ["mood"], 2 + i)
		ids.append(str(note.get("id", "")))
	var props := {"shape": "torus", "size": 2.4, "color": accent, "metallic": 0.7, "roughness": 0.22, "emission": accent, "emission_energy": 0.35, "show_label": false, "title": "Torus"}
	var object_layer := "lyr_objects" if not project.get_layer("lyr_objects").is_empty() else project.active_layer_id
	var item := project.add_item("primitive", center + Vector3(10.8, 0.0, 1.0), props, object_layer)
	_spawn_for_item(item, false)
	ids.append(str(item.get("id", "")))
	return ids


func _template_swot(center: Vector3, accent: String) -> Array:
	var ids := []
	var quadrants := [
		["Strengths", "What already works? Where are we unfairly strong?", Vector3(-4.1, 3.3, 0), "#0C8F6A"],
		["Weaknesses", "What is brittle, missing or expensive?", Vector3(4.1, 3.3, 0), "#E05A44"],
		["Opportunities", "What tailwind or insight can we use now?", Vector3(-4.1, -3.4, 0), "#2F5BFF"],
		["Threats", "What could make this irrelevant?", Vector3(4.1, -3.4, 0), "#B8780F"],
	]
	for i in range(quadrants.size()):
		var note := _template_note(center + quadrants[i][2], quadrants[i][0], quadrants[i][1], quadrants[i][3], ["swot"], i)
		ids.append(str(note.get("id", "")))
	return ids


func _template_kanban(center: Vector3, accent: String) -> Array:
	var ids := []
	var columns := [
		["Now", "Commit to the smallest valuable thing.", Vector3(-10.0, 3.6, 0)],
		["Next", "Shaped, not started. Keep it light.", Vector3(0.0, 3.6, 0)],
		["Later", "Park it without losing it.", Vector3(10.0, 3.6, 0)],
	]
	for i in range(columns.size()):
		var header := _template_note(center + columns[i][2], columns[i][0], columns[i][1], accent, ["flow"], i)
		ids.append(str(header.get("id", "")))
		for j in range(2):
			var card := _template_note(center + columns[i][2] + Vector3(0, -4.0 - j * 3.2, 0.001), "%s task %d" % [columns[i][0], j + 1], "Move this card between columns as the work evolves.", accent, ["task"], 3 + j)
			ids.append(str(card.get("id", "")))
	return ids


func _template_pitch(center: Vector3, accent: String) -> Array:
	var ids := []
	var beats := [
		["The tension", "Show the moment the old way fails.", "Ready"],
		["The promise", "A clear before-and-after for the audience.", "Draft"],
		["The proof", "One number, one story, one demo beat.", "Draft"],
		["The ask", "What exactly happens next?", "Draft"],
	]
	for i in range(beats.size()):
		var frame := _template_frame(center + Vector3(-10.0 + i * 7.0, 2.2, 0), i + 1, beats[i][0], beats[i][1], accent, 4.0, beats[i][2])
		ids.append(str(frame.get("id", "")))
	var note := _template_note(center + Vector3(-10.0, 8.0, 0), "Product pitch", "Four beats, one story. Keep every frame visually specific.", accent, ["pitch"], 1)
	ids.append(str(note.get("id", "")))
	project.sync_storyboard()
	return ids


func _template_research(center: Vector3, accent: String) -> Array:
	var ids := []
	var items := [
		["Signal", "What did we hear repeatedly from users?", Vector3(-10.0, 4.0, 0)],
		["Evidence", "Which data changes our confidence?", Vector3(-2.0, 4.6, 0)],
		["Insight", "What is the non-obvious interpretation?", Vector3(6.0, 4.0, 0)],
		["Opportunity", "Where could a small product create relief?", Vector3(-7.0, -3.2, 0)],
		["Open question", "What would make us change our mind?", Vector3(2.0, -3.6, 0)],
	]
	var previous := ""
	for i in range(items.size()):
		var note := _template_note(center + items[i][2], items[i][0], items[i][1], accent, ["research"], i)
		ids.append(str(note.get("id", "")))
		if not previous.is_empty():
			_template_link(previous, str(note.get("id", "")), accent)
		previous = str(note.get("id", ""))
	return ids


func _template_welcome(center: Vector3) -> Array:
	var ids := []
	var title := _template_note(center + Vector3(0.0, 5.2, 0.01), "Welcome to your 3D canvas", "This is a real board. Drag it, edit it, orbit it, or delete it. Everything is local.", "#2F5BFF", ["start"], 1)
	ids.append(str(title.get("id", "")))
	var note1 := _template_note(center + Vector3(-0.2, -2.6, 0), "Draw with intent", "Choose the pen and sketch on the canvas. Use the cube button for 3D ink that lives in space.", "#7455FF", ["howto"], 2)
	var note2 := _template_note(center + Vector3(0.2, -10.4, 0), "Think in layers", "Notes, ink and 3D objects live on separate layers. Hide or lock them from the layers panel.", "#0C8F6A", ["howto"], 3)
	ids.append(str(note1.get("id", "")))
	ids.append(str(note2.get("id", "")))
	_template_link(str(title.get("id", "")), str(note1.get("id", "")), "#7455FF")
	_template_link(str(note1.get("id", "")), str(note2.get("id", "")), "#0C8F6A")
	var frame := _template_frame(center + Vector3(0.0, -17.6, 0), 1, "A storyboard frame", "Tap the film icon in the dock to sequence frames and present the story.", "#B8780F", 3.0, "Draft")
	ids.append(str(frame.get("id", "")))
	project.sync_storyboard()
	var props := {"shape": "box", "size": 1.35, "color": "#2F5BFF", "metallic": 0.4, "roughness": 0.32, "emission": "#000000", "emission_energy": 0.0, "show_label": false, "title": "Cobalt cube"}
	var object_layer := "lyr_objects" if not project.get_layer("lyr_objects").is_empty() else project.active_layer_id
	var item := project.add_item("primitive", center + Vector3(3.6, 5.2, 0.8), props, object_layer)
	item["rot"] = [18.0, 35.0, 6.0]
	_spawn_for_item(item, false)
	ids.append(str(item.get("id", "")))
	return ids


# ------------------------------------------------------------------ smart studio

func smart_action(action: String) -> void:
	if project.items.is_empty():
		ui.toast("Add a few notes first", "info", Kit.MUTED)
		return
	match action:
		"connect":
			var suggestions := SmartEngine.suggest_connections(project)
			if suggestions.is_empty():
				ui.toast("No new connections found — add more text", "hub", Kit.MUTED)
				return
			undo.begin(project)
			var count := 0
			for s in suggestions:
				var c := project.add_connector(str(s.get("from", "")), str(s.get("to", "")), "dashed", "#7455FF", str(s.get("label", "")))
				if not c.is_empty():
					_add_connector_node(c)
					count += 1
			undo.commit(project, "Smart connect")
			dirty = true
			_schedule_save()
			ui.toast("%d smart links added" % count, "auto_fix_high", Kit.GREEN)
			_haptic(18)
		"cluster":
			undo.begin(project)
			var origin := rig.screen_to_plane(Vector2(70, 260))
			var positions := SmartEngine.cluster_positions(project, Vector3(origin.x, origin.y, 0.0))
			for id in positions.keys():
				var item := project.get_item(str(id))
				if item.is_empty() or not str(item.get("parent", "")).is_empty():
					continue
				var pos: Vector3 = positions[id]
				item["pos"] = [pos.x, pos.y, _to_vec3(item.get("pos", [0, 0, 0])).z]
				var node: CanvasItem3D = item_nodes.get(str(id), null)
				if node != null:
					node.position = _to_vec3(item.get("pos", [0, 0, 0]))
				_refresh_connectors_for(str(id))
			undo.commit(project, "Cluster ideas")
			dirty = true
			_schedule_save()
			ui.toast("Ideas clustered by theme", "account_tree", Kit.VIOLET)
			_schedule_focus_ids(_all_selectable_ids())
		"tidy":
			undo.begin(project)
			var origin2 := rig.screen_to_plane(Vector2(80, 260))
			var positions2 := SmartEngine.tidy_positions(project, Vector3(origin2.x, origin2.y, 0.0))
			for id in positions2.keys():
				var item := project.get_item(str(id))
				if item.is_empty() or not str(item.get("parent", "")).is_empty():
					continue
				var pos: Vector3 = positions2[id]
				item["pos"] = [pos.x, pos.y, _to_vec3(item.get("pos", [0, 0, 0])).z]
				var node: CanvasItem3D = item_nodes.get(str(id), null)
				if node != null:
					node.position = _to_vec3(item.get("pos", [0, 0, 0]))
				_refresh_connectors_for(str(id))
			undo.commit(project, "Tidy board")
			dirty = true
			_schedule_save()
			ui.toast("Board tidied", "cleaning_services", Kit.GREEN)
			_schedule_focus_ids(_all_selectable_ids())
		"summarize":
			var summary := SmartEngine.summarize(project)
			if summary.strip_edges().is_empty():
				ui.toast("There is not enough text to summarise", "summarize", Kit.MUTED)
				return
			var point := rig.screen_to_plane(rig.screen_center(), 0.12) + Vector3(0, -8.0, 0)
			undo.begin(project)
			var note := _template_note(point, "Board summary", summary, "#B8780F", ["summary"], 5)
			undo.commit(project, "Summarize board")
			dirty = true
			_schedule_save()
			select_ids([str(note.get("id", ""))])
			rig.focus_point(_to_vec3(note.get("pos", [0, 0, 0])), 8.0)
			ui.toast("Summary note created", "summarize", Kit.GOLD)
			_haptic(16)
		"next":
			var steps := SmartEngine.next_steps(project)
			var body := ""
			for s in steps:
				body += "• " + str(s) + "\n"
			var point2 := rig.screen_to_plane(rig.screen_center(), 0.12) + Vector3(7.0, -7.0, 0)
			undo.begin(project)
			var note2 := _template_note(point2, "Next moves", body, "#0C8F6A", ["next"], 3)
			undo.commit(project, "Suggest next steps")
			dirty = true
			_schedule_save()
			select_ids([str(note2.get("id", ""))])
			ui.toast("A practical next-step list is ready", "insights", Kit.GREEN)
			_haptic(16)
		_:
			return
	_connectors_dirty = true
	ui.refresh()


func get_top_keywords() -> Array:
	return SmartEngine.top_keywords(project, 12)


func select_keyword(word: String) -> void:
	var ids := []
	for doc in SmartEngine.board_documents(project):
		var tokens := SmartEngine.tokenize(str(doc.get("text", "")))
		if word in tokens:
			ids.append(str(doc.get("id", "")))
	if ids.is_empty():
		ui.toast("No notes contain that theme", "search", Kit.MUTED)
		return
	select_ids(ids)
	_focus_bounds_of(ids)
	ui.toast("%d objects mention \"%s\"" % [ids.size(), word], "search", Kit.ACCENT)


func get_graph_data() -> Dictionary:
	var nodes := []
	var node_ids := {}
	for item in project.items:
		var type := str(item.get("type", ""))
		if type not in ["note", "text", "frame", "image", "pdf", "model", "primitive"]:
			continue
		var label := _item_label(item)
		if label.strip_edges().is_empty():
			continue
		var layer := project.get_layer(str(item.get("layer", "")))
		nodes.append({
			"id": str(item.get("id", "")),
			"label": label,
			"type": type,
			"color": str(layer.get("color", "#2F5BFF")),
		})
		node_ids[str(item.get("id", ""))] = true
	var edges := []
	for c in project.connectors:
		if node_ids.has(str(c.get("from", ""))) and node_ids.has(str(c.get("to", ""))):
			edges.append({"from": str(c.get("from", "")), "to": str(c.get("to", "")), "label": str(c.get("label", ""))})
	return {"nodes": nodes, "edges": edges}


func get_stats() -> Dictionary:
	return project.stats()


# ------------------------------------------------------------------ storyboard

func add_frame() -> void:
	var point := rig.screen_to_plane(rig.screen_center(), 0.09)
	var item := _add_frame_at(point)
	if not item.is_empty():
		select_ids([str(item.get("id", ""))])
		rig.focus_point(point, 8.0)
		if ui.sheet_kind == "timeline":
			ui.reload_sheet()


func step_frame(direction: int) -> void:
	var frames := project.frames()
	if frames.is_empty():
		return
	var current := int(project.storyboard.get("current", 0)) + direction
	current = clampi(current, 0, frames.size() - 1)
	go_to_frame(current)
	if storyboard_playing:
		_restart_present_timer()


func go_to_frame(index: int) -> void:
	var frames := project.frames()
	if frames.is_empty():
		return
	index = clampi(index, 0, frames.size() - 1)
	project.storyboard["current"] = index
	var frame: Dictionary = frames[index]
	var node: CanvasItem3D = item_nodes.get(str(frame.get("id", "")), null)
	if node != null:
		var rect := _node_world_rect(node)
		rig.focus_rect(rect, 1.4)
		if not storyboard_playing:
			select_ids([str(frame.get("id", ""))])
	if ui.sheet_kind == "timeline":
		ui.reload_sheet()


func reorder_frame(direction: int) -> void:
	var frames := project.frames()
	if frames.size() < 2:
		return
	var current := int(project.storyboard.get("current", 0))
	var target := clampi(current + direction, 0, frames.size() - 1)
	if target == current:
		return
	var ids := []
	for f in frames:
		ids.append(str(f.get("id", "")))
	var moved = ids.pop_at(current)
	ids.insert(target, moved)
	undo.begin(project)
	project.set_frame_order(ids)
	project.storyboard["current"] = target
	undo.commit(project, "Reorder frames")
	dirty = true
	_schedule_save()
	for f in project.frames():
		var node: CanvasItem3D = item_nodes.get(str(f.get("id", "")), null)
		if node != null:
			node.refresh_from_data()
	ui.reload_sheet()
	_haptic(10)


func delete_current_frame() -> void:
	var frames := project.frames()
	if frames.is_empty():
		return
	var current := clampi(int(project.storyboard.get("current", 0)), 0, frames.size() - 1)
	select_ids([str(frames[current].get("id", ""))])
	delete_selection()
	project.sync_storyboard()
	ui.reload_sheet()


func toggle_presentation() -> void:
	if storyboard_playing:
		stop_presentation()
	else:
		present_from(int(project.storyboard.get("current", 0)))


func present_from(index: int) -> void:
	var frames := project.frames()
	if frames.is_empty():
		ui.toast("Add frames to present", "movie", Kit.GOLD)
		return
	storyboard_playing = true
	go_to_frame(clampi(index, 0, frames.size() - 1))
	if rig.mode != "3d":
		rig.set_mode_3d(false)
		rig.pitch_target = 12.0
		rig.yaw_target = 8.0
		rig.mode = "3d"
		rig.fov_target = FOV_3D
	ui.toast("Presenting storyboard · tap stop to end", "play_arrow", Kit.GREEN, 2.2)
	_restart_present_timer()


func _restart_present_timer() -> void:
	var frames := project.frames()
	if frames.is_empty():
		stop_presentation()
		return
	var current := int(project.storyboard.get("current", 0))
	var duration := float(frames[current].get("props", {}).get("duration", 3.0))
	_present_timer.wait_time = clampf(duration, 1.2, 12.0)
	_present_timer.start()


func _on_present_tick() -> void:
	if not storyboard_playing:
		return
	var frames := project.frames()
	var current := int(project.storyboard.get("current", 0))
	if current + 1 >= frames.size():
		stop_presentation()
		return
	go_to_frame(current + 1)
	_restart_present_timer()


func stop_presentation() -> void:
	storyboard_playing = false
	_present_timer.stop()
	ui.toast("Presentation ended", "stop_circle", Kit.MUTED, 1.6)
	if ui.sheet_kind == "timeline":
		ui.reload_sheet()


# ------------------------------------------------------------------ camera / look / nav

func set_tool(tool: String) -> void:
	if tool == active_tool and tool in ["select", "pan", "pen", "highlighter", "eraser"]:
		ui.flash_tool(tool)
		return
	active_tool = tool
	project.settings["last_tool"] = tool
	if tool == "pen":
		project.settings["pen_kind"] = "pen"
	elif tool == "highlighter":
		project.settings["pen_kind"] = "highlighter"
	_connect_source = ""
	_suppress_tap = false
	_schedule_save()
	ui.refresh()
	ui.refresh_selection()
	ui.flash_tool(tool)
	_haptic(9)
	_update_overlay()


func set_pen_color(hex: String) -> void:
	pen_color = Color.from_string(hex, Kit.ACCENT)
	project.settings["pen_color"] = hex
	_schedule_save()
	ui.refresh()


func set_pen_size(value: float) -> void:
	pen_size = clampf(value, 0.2, 30.0)
	project.settings["pen_size"] = pen_size
	_schedule_save()
	ui.refresh()


func toggle_ink_3d() -> void:
	ink_3d = not ink_3d
	project.settings["ink_3d"] = ink_3d
	_schedule_save()
	ui.refresh()
	ui.toast("3D ink " + ("on · draw on a camera-facing plane" if ink_3d else "off · draw on the canvas"), "view_in_ar", Kit.ACCENT if ink_3d else Kit.MUTED)


func toggle_mode() -> void:
	rig.toggle_mode()
	_sync_camera_to_project()
	_schedule_save()
	ui.refresh()
	ui.toast("3D space" if rig.mode == "3d" else "2D canvas", "view_in_ar" if rig.mode == "3d" else "2d", Kit.ACCENT, 1.4)
	_haptic(12)
	_update_overlay()


func set_mode(mode_name: String) -> void:
	if mode_name == "3d":
		rig.set_mode_3d()
	else:
		rig.set_mode_2d()
	rig.mode = mode_name
	_sync_camera_to_project()
	_schedule_save()
	ui.refresh()
	ui.reload_sheet()
	_update_overlay()


func set_camera_preset(preset: String) -> void:
	match preset:
		"front":
			rig.set_mode_2d()
			rig.yaw_target = 0.0
			rig.pitch_target = 0.0
		"iso":
			rig.set_mode_3d()
			rig.yaw_target = 26.0
			rig.pitch_target = 22.0
		"top":
			rig.set_mode_3d(false)
			rig.mode = "3d"
			rig.fov_target = FOV_3D
			rig.yaw_target = 0.0
			rig.pitch_target = 58.0
	_sync_camera_to_project()
	_schedule_save()
	ui.refresh()
	_haptic(10)


func camera_nudge(direction: String) -> void:
	rig.nudge(direction)
	_sync_camera_to_project()
	_connectors_dirty = true


func focus_all() -> void:
	var ids := []
	for item in project.items:
		if project.is_layer_visible(str(item.get("layer", ""))):
			ids.append(str(item.get("id", "")))
	if ids.is_empty():
		rig.reset_view()
		return
	_focus_bounds_of(ids, 1.4)
	ui.toast("Fitted the whole board", "fit_screen", Kit.ACCENT, 1.2)


func focus_selected() -> void:
	if selected_ids.is_empty():
		return
	_focus_bounds_of(selected_ids, 1.45)
	_haptic(10)


func focus_item(item_id: String) -> void:
	var item := project.get_item(item_id)
	if item.is_empty():
		return
	var node: CanvasItem3D = item_nodes.get(item_id, null)
	if node == null:
		return
	var rect := _node_world_rect(node)
	rig.focus_rect(rect, 1.5)


func save_bookmark(bookmark_title: String) -> void:
	var name := bookmark_title.strip_edges()
	if name.is_empty():
		name = "View %d" % (project.bookmarks.size() + 1)
	undo.begin(project)
	project.add_bookmark(name, rig.get_state())
	undo.commit(project, "Save camera bookmark")
	dirty = true
	_schedule_save()
	ui.toast("View saved", "bookmark", Kit.GOLD, 1.4)


func goto_bookmark(bookmark_id: String) -> void:
	for bookmark in project.bookmarks:
		if str(bookmark.get("id", "")) == bookmark_id:
			rig.set_state(bookmark.get("camera", {}), true)
			ui.refresh()
			ui.toast("Flying to " + str(bookmark.get("name", "view")), "bookmark", Kit.ACCENT, 1.3)
			return


func delete_bookmark(bookmark_id: String) -> void:
	undo.begin(project)
	project.remove_bookmark(bookmark_id)
	undo.commit(project, "Delete bookmark")
	dirty = true
	_schedule_save()


func get_look_settings() -> Dictionary:
	var look: Dictionary = project.settings.get("look", {})
	return {
		"preset": str(look.get("preset", "studio")),
		"key_energy": float(look.get("key_energy", 1.25)),
		"ambient": float(look.get("ambient", 0.45)),
		"grid": bool(project.settings.get("show_grid", true)),
		"snap": bool(project.settings.get("snap", true)),
		"performance": bool(project.settings.get("performance_mode", false)),
		"accent": str(project.settings.get("accent", "#2F5BFF")),
		"grid_step": float(project.settings.get("grid", 1.0)),
		"snap_angle": float(project.settings.get("snap_angle", 15.0)),
	}


func apply_look_preset(preset: String) -> void:
	if not project.settings.has("look"):
		project.settings["look"] = {}
	project.settings["look"]["preset"] = preset
	_apply_look()
	dirty = true
	_schedule_save()
	ui.toast("%s atmosphere" % preset.capitalize(), "light_mode", Kit.ACCENT, 1.3)


func set_look_param(key: String, value: float) -> void:
	if not project.settings.has("look"):
		project.settings["look"] = {}
	project.settings["look"][key] = value
	_apply_look()
	dirty = true
	_schedule_save()


func set_setting(key: String, value) -> void:
	if project == null:
		return
	project.settings[key] = value
	match key:
		"show_grid":
			if bool(value):
				if str(project.settings.get("grid_style", "lines")) == "off":
					project.settings["grid_style"] = "lines"
			else:
				project.settings["grid_style"] = "off"
		"grid_style":
			project.settings["show_grid"] = str(value) != "off"
		"performance_mode":
			_apply_performance_settings()
		"reduce_motion":
			rig.reduce_motion = bool(value)
			if rig.reduce_motion:
				rig.apply_view_now()
		"left_handed":
			if ui != null:
				ui.relayout()
		"autosave", "autosave_delay", "undo_limit":
			_apply_behavior_settings()
		"keep_awake":
			_apply_keep_awake()
		"show_connectors":
			_refresh_connector_visibility()
		"show_fps":
			if ui != null:
				ui.refresh()
		"text_scale":
			Kit.set_type_scale(float(value))
			app_cfg["text_scale"] = float(value)
			_save_app_config()
			_rebuild_ui()
		"default_tool":
			if ui != null:
				ui.toast("Default tool set to %s" % str(value).capitalize(), "touch_app", Kit.ACCENT, 1.4)
	project.touch()
	dirty = true
	if key == "autosave" and not bool(value):
		save_now()
	else:
		_schedule_save()
	if ui != null:
		ui.refresh()


func toggle_setting(key: String, value: bool) -> void:
	set_setting(key, value)


func _apply_behavior_settings() -> void:
	if project == null:
		return
	var settings := project.settings
	rig.reduce_motion = bool(settings.get("reduce_motion", false))
	if rig.reduce_motion:
		rig.apply_view_now()
	if _save_timer != null:
		_save_timer.wait_time = clampf(float(settings.get("autosave_delay", 1.2)), 0.5, 30.0)
	if undo != null:
		undo.limit = maxi(10, int(settings.get("undo_limit", 60)))
	_apply_keep_awake()
	_apply_performance_settings()
	_refresh_connector_visibility()


func _apply_keep_awake() -> void:
	if project == null:
		return
	if DisplayServer.has_method("screen_set_keep_on"):
		DisplayServer.screen_set_keep_on(bool(project.settings.get("keep_awake", false)))


func _apply_performance_settings() -> void:
	if project == null:
		return
	var viewport := get_viewport()
	if viewport != null:
		viewport.msaa_3d = Viewport.MSAA_DISABLED if bool(project.settings.get("performance_mode", false)) else Viewport.MSAA_2X
	_update_lod()


func _refresh_connector_visibility() -> void:
	var show_links := bool(project.settings.get("show_connectors", true))
	for node in connector_nodes.values():
		if node != null:
			node.visible = show_links


func _rebuild_ui() -> void:
	if inspector_active:
		end_inspector_session()
	if ui != null:
		remove_child(ui)
		ui.queue_free()
		ui = null
	_build_ui()
	_sync_ui()
	_update_overlay()
	call_deferred("_reopen_settings")


func _reopen_settings() -> void:
	await get_tree().process_frame
	if ui != null:
		ui.open_sheet("settings")


func delete_selection() -> void:
	if selected_connector_id.is_empty() and selected_ids.is_empty():
		return
	if not bool(project.settings.get("confirm_delete", false)):
		_delete_selection_now()
		return
	ui.confirm("Delete selection", "This can be undone with the undo button.", func(): _delete_selection_now())


func get_autosaves() -> Array:
	if project == null:
		return []
	return Store.list_autosaves(project.id)


func create_restore_point() -> void:
	if project == null:
		return
	Store.autosave(project)
	dirty = false
	last_saved_at = Time.get_unix_time_from_system()
	ui.toast("Restore point saved", "restore", Kit.GREEN, 1.6)


func restore_autosave(path: String) -> void:
	var restored := Store.restore_autosave(path)
	if restored == null:
		ui.toast("This restore point could not be opened", "warning", Kit.DANGER)
		return
	_enter_project(restored, false)
	save_now()
	if ui != null:
		ui.close_sheet()
		ui.toast("Restore point loaded", "restore", Kit.GREEN, 1.8)
	_haptic(14)


func clear_exports() -> void:
	Store.clear_exports()
	if ui != null:
		ui.reload_sheet()
		ui.toast("Export cache cleared", "delete", Kit.GREEN, 1.5)


func get_storage_used() -> int:
	return _dir_size("user://")


func _dir_size(path: String) -> int:
	var total := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	for filename in dir.get_files():
		total += FileAccess.get_size(path.path_join(filename))
	for sub in dir.get_directories():
		total += _dir_size(path.path_join(sub))
	return total


func format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return "%d B" % bytes
	if bytes < 1024 * 1024:
		return "%.1f KB" % (bytes / 1024.0)
	if bytes < 1024 * 1024 * 1024:
		return "%.1f MB" % (bytes / (1024.0 * 1024.0))
	return "%.2f GB" % (bytes / (1024.0 * 1024.0 * 1024.0))


func share_app() -> void:
	var link := "https://play.google.com/store/apps/details?id=com.fajar.ultimatecanvas3d"
	var message := "%s — a 2D + 3D infinite whiteboard for notes, mind maps, PDFs and storyboards.\n%s" % [APP_DISPLAY_NAME, link]
	if OS.has_feature("android"):
		var bridge = JavaClassWrapper.wrap("com.godot.game.ShareBridge")
		if bridge != null and bridge.has_java_method("share"):
			var result = bridge.share(APP_DISPLAY_NAME, message)
			if JavaClassWrapper.get_exception() == null and str(result).begins_with("OK"):
				return
	DisplayServer.clipboard_set(message)
	ui.toast("Invite copied to clipboard", "share", Kit.GREEN, 1.8)


func rate_app() -> void:
	var package := "com.fajar.ultimatecanvas3d"
	var err := OS.shell_open("market://details?id=" + package)
	if err != OK:
		err = OS.shell_open("https://play.google.com/store/apps/details?id=" + package)
	if err == OK:
		ui.toast("Opening Google Play", "star", Kit.GOLD, 1.6)
	else:
		ui.toast("Could not open the Play Store", "warning", Kit.DANGER, 1.8)


func get_device_info() -> Dictionary:
	var model := ""
	if OS.has_method("get_model_name"):
		model = str(OS.get_model_name())
	var screen := DisplayServer.window_get_size()
	return {
		"version": str(ProjectSettings.get_setting("application/config/version", "3.3.0")),
		"engine": str(Engine.get_version_info().get("string", "Godot")),
		"os": "%s %s" % [OS.get_name(), OS.get_version()],
		"model": model,
		"renderer": RenderingServer.get_video_adapter_name(),
		"screen": "%d × %d" % [screen.x, screen.y],
		"storage": format_bytes(get_storage_used()),
		"projects": get_projects().size(),
	}




func set_grid_step(value: float) -> void:
	project.settings["grid"] = clampf(value, 0.1, 100.0)
	dirty = true
	_schedule_save()
	ui.toast("Grid step %.1f" % value, "grid_4x4", Kit.ACCENT, 1.2)


func set_snap_angle(value: float) -> void:
	project.settings["snap_angle"] = value
	dirty = true
	_schedule_save()


func set_canvas_accent(hex: String) -> void:
	project.settings["accent"] = hex
	pen_color = Color.from_string(hex, Kit.ACCENT)
	project.settings["pen_color"] = hex
	_apply_look()
	dirty = true
	_schedule_save()
	ui.refresh()


# ------------------------------------------------------------------ projects / save

func get_projects() -> Array:
	var list := Store.list_projects()
	for p in list:
		p["active"] = str(p.get("id", "")) == project.id
	return list


func get_free_limit() -> int:
	return 0


func can_create_project() -> bool:
	return true


func is_premium() -> bool:
	return false


func new_project() -> void:
	save_now()
	_new_project_counter += 1
	var fresh := CanvasProject.create("Untitled Board %d" % _new_project_counter)
	Store.save_project(fresh)
	_enter_project(fresh, false)
	ui.close_sheet()
	ui.refresh()
	ui.toast("New board created", "add", Kit.GREEN)
	_haptic(14)


func open_project(project_id: String) -> void:
	if project_id == project.id:
		ui.close_sheet()
		return
	if dirty:
		save_now()
	var loaded := Store.load_project(project_id)
	if loaded == null:
		ui.toast("This board could not be opened", "warning", Kit.DANGER)
		return
	_enter_project(loaded, false)
	ui.close_sheet()
	ui.refresh()
	ui.toast("Opened " + loaded.title, "folder_open", Kit.ACCENT)
	_haptic(14)


func delete_project(project_id: String) -> void:
	var deleting_active := project_id == project.id
	Store.delete_project(project_id)
	if deleting_active:
		var remaining := Store.list_projects()
		if not remaining.is_empty():
			var loaded := Store.load_project(str(remaining[0].get("id", "")))
			if loaded != null:
				_enter_project(loaded, false)
				ui.refresh()
				return
		var fresh := CanvasProject.create("My First Board")
		Store.save_project(fresh)
		_enter_project(fresh, false)
		ui.refresh()
	ui.toast("Board deleted", "delete", Kit.MUTED)
	ui.reload_sheet()


func duplicate_project(project_id: String) -> void:
	var copy := Store.duplicate_project(project_id)
	if copy == null:
		ui.toast("Could not duplicate board", "warning", Kit.DANGER)
		return
	ui.toast("Board duplicated", "content_copy", Kit.GREEN)
	ui.reload_sheet()


func rename_project(new_title: String) -> void:
	var cleaned := new_title.strip_edges()
	if cleaned.is_empty():
		return
	undo.begin(project)
	project.title = cleaned
	undo.commit(project, "Rename board")
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("Renamed", "edit", Kit.GREEN, 1.2)


func save_now() -> bool:
	if project == null:
		return false
	_sync_camera_to_project()
	var ok := Store.save_project(project)
	if ok:
		dirty = false
		last_saved_at = Time.get_unix_time_from_system()
		if last_saved_at - _last_autosave_snapshot > 180.0:
			_last_autosave_snapshot = last_saved_at
			Store.autosave(project)
		if ui != null:
			ui.refresh()
		return true
	if ui != null:
		ui.toast("Could not save board", "warning", Kit.DANGER)
	return false


func _schedule_save() -> void:
	dirty = true
	if bool(project.settings.get("autosave", true)) and _save_timer != null:
		_save_timer.start()
	if ui != null:
		ui.refresh()


func first_run(sample: bool) -> void:
	app_cfg["onboarded"] = true
	_save_app_config()
	ui.show_onboarding(false)
	if sample:
		project.title = "Studio Welcome"
		_apply_template_quiet("welcome")
		rig.reset_view()
		ui.toast("Sample board loaded · everything is editable", "auto_awesome", Kit.GREEN, 3.0)
	else:
		ui.toast("Tap + to create, or draw with the pen", "auto_awesome", Kit.ACCENT, 2.4)
	dirty = true
	_schedule_save()
	ui.refresh()


func replay_onboarding() -> void:
	app_cfg["onboarded"] = false
	_save_app_config()
	ui.show_onboarding(true)


func _apply_template_quiet(template_id: String) -> void:
	undo.begin(project)
	var center := rig.screen_to_plane(rig.screen_center(), 0.07)
	var created := []
	if template_id == "welcome":
		created = _template_welcome(center)
	undo.commit(project, "Welcome board")
	ui.refresh()


func _load_app_config() -> void:
	app_cfg = {"onboarded": false, "last_project": ""}
	if not FileAccess.file_exists(APP_CONFIG):
		return
	var file := FileAccess.open(APP_CONFIG, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		app_cfg["onboarded"] = bool(parsed.get("onboarded", false))
		app_cfg["last_project"] = str(parsed.get("last_project", ""))


func _save_app_config() -> void:
	var file := FileAccess.open(APP_CONFIG, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(app_cfg))
	file.close()


# ------------------------------------------------------------------ undo / live edits

func _begin_live_undo(label: String) -> void:
	if inspector_active or _live_undo_active:
		if _live_undo_active:
			_live_undo_label = label
			_live_undo_timer.start()
		return
	_live_undo_active = true
	_live_undo_label = label
	undo.begin(project)
	_live_undo_timer.start()


func _flush_live_edit() -> void:
	if not _live_undo_active:
		return
	_live_undo_active = false
	undo.commit(project, _live_undo_label)
	_live_undo_label = ""
	ui.refresh()


func undo_action() -> void:
	_flush_live_edit()
	if undo.undo(project):
		dirty = true
		_rebuild_scene(true)
		ui.refresh()
		ui.refresh_selection()
		ui.toast("Undone", "undo", Kit.ACCENT, 1.2)
		_schedule_save()
	else:
		ui.toast("Nothing to undo", "undo", Kit.MUTED, 1.2)


func redo_action() -> void:
	_flush_live_edit()
	if undo.redo(project):
		dirty = true
		_rebuild_scene(true)
		ui.refresh()
		ui.refresh_selection()
		ui.toast("Redone", "redo", Kit.ACCENT, 1.2)
		_schedule_save()
	else:
		ui.toast("Nothing to redo", "redo", Kit.MUTED, 1.2)


# ------------------------------------------------------------------ import / export

func import_media(kind: String) -> void:
	ui.close_sheet()
	match kind:
		"image":
			_pick_file(PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; Images ; image/png,image/jpeg,image/webp,image/bmp"]), _import_image)
		"pdf":
			_pick_file(PackedStringArray(["*.pdf ; PDF documents ; application/pdf"]), _import_pdf)
		"model":
			_pick_file(PackedStringArray(["*.glb, *.gltf ; 3D models ; model/gltf-binary,model/gltf+json"]), _import_model)
		_:
			import_any()


func import_any() -> void:
	ui.close_sheet()
	var filters := PackedStringArray([
		"*.png, *.jpg, *.jpeg, *.webp ; Images ; image/png,image/jpeg,image/webp",
		"*.pdf ; PDF ; application/pdf",
		"*.glb, *.gltf ; 3D models ; model/gltf-binary,model/gltf+json",
		"*.zip ; Backups ; application/zip",
		"*.json ; Boards ; application/json",
	])
	_pick_file(filters, _import_dispatch)


func restore_backup() -> void:
	ui.close_sheet()
	_pick_file(PackedStringArray(["*.zip, *.json ; Backups ; application/zip,application/json"]), _import_dispatch)


func _pick_file(filters: PackedStringArray, callback: Callable, mode := FileDialog.FILE_MODE_OPEN_FILE, suggested := "") -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = OS.has_feature("android")
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = mode
	dialog.filters = filters
	dialog.current_file = suggested
	dialog.title = "Choose a file" if mode == FileDialog.FILE_MODE_OPEN_FILE else "Save a file"
	if not OS.has_feature("android"):
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	dialog.file_selected.connect(func(path):
		dialog.queue_free()
		if callback.is_valid():
			callback.call(path)
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())
	ui.add_child(dialog)
	dialog.popup_centered_ratio(0.9)


func _import_dispatch(path: String) -> void:
	var ext := path.get_extension().to_lower()
	if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" or ext == "bmp":
		_import_image(path)
	elif ext == "pdf":
		_import_pdf(path)
	elif ext == "glb" or ext == "gltf":
		_import_model(path)
	elif ext == "zip":
		_import_zip(path)
	elif ext == "json":
		_import_json_board(path)


func _import_image(path: String) -> void:
	ui.set_busy(true, "Importing image…")
	await get_tree().process_frame
	var asset := Store.copy_asset(project.id, path)
	if asset.is_empty():
		ui.set_busy(false)
		ui.toast("Could not read that image", "warning", Kit.DANGER)
		return
	var image := Image.load_from_file(asset)
	var aspect := 1.5
	if image != null and not image.is_empty():
		aspect = float(image.get_width()) / float(image.get_height())
	var point := rig.screen_to_plane(rig.screen_center(), 0.08)
	var props := {
		"asset": asset,
		"caption": Store.display_name(path),
		"aspect": aspect,
		"width": 5.0,
	}
	undo.begin(project)
	var item := project.add_item("image", point, props, project.active_layer_id)
	undo.commit(project, "Import image")
	set_tool("select")
	_spawn_for_item(item, true)
	ui.set_busy(false)
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("Image embedded", "image", Kit.GREEN)
	_haptic(14)


func _import_model(path: String) -> void:
	ui.set_busy(true, "Importing 3D model…")
	await get_tree().process_frame
	var asset := Store.copy_asset(project.id, path)
	if asset.is_empty():
		ui.set_busy(false)
		ui.toast("Could not read that 3D file", "warning", Kit.DANGER)
		return
	var point := rig.screen_to_plane(rig.screen_center(), 0.4)
	var objects_layer := "lyr_objects" if not project.get_layer("lyr_objects").is_empty() else project.active_layer_id
	var props := {
		"asset": asset,
		"title": Store.display_name(path).get_basename(),
		"size": 2.6,
		"tint": "#FFFFFF",
		"material": {"metallic": 0.15, "roughness": 0.6},
		"show_label": true,
	}
	undo.begin(project)
	var item := project.add_item("model", Vector3(point.x, point.y, 0.9), props, objects_layer)
	undo.commit(project, "Import 3D model")
	set_tool("select")
	_spawn_for_item(item, true)
	ui.set_busy(false)
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("3D model imported", "view_in_ar", Kit.GREEN)
	_haptic(16)


func _import_pdf(path: String) -> void:
	ui.set_busy(true, "Rasterising PDF pages…")
	await get_tree().process_frame
	var asset := Store.copy_asset(project.id, path)
	if asset.is_empty():
		ui.set_busy(false)
		ui.toast("Could not open that PDF", "warning", Kit.DANGER)
		return
	var out_dir := "%s/pdf_%s" % [Store.assets_dir(project.id), str(Time.get_unix_time_from_system()).replace(".", "")]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var pages := PdfTool.rasterize(asset, out_dir, 1.7, 32)
	ui.set_busy(false)
	if pages.is_empty():
		ui.toast(PdfTool.last_error if not PdfTool.last_error.is_empty() else "PDF rasterisation is available on Android only", "warning", Kit.DANGER, 3.5)
		return
	var display := Store.display_name(path)
	undo.begin(project)
	var center := rig.screen_to_plane(rig.screen_center(), 0.09)
	var group := project.add_item("group", center, {"title": display}, project.active_layer_id)
	var group_id := str(group.get("id", ""))
	var page_ids := [group_id]
	var columns := 3
	for i in range(pages.size()):
		var img := Image.load_from_file(pages[i])
		var aspect := 0.707
		if img != null and not img.is_empty():
			aspect = float(img.get_width()) / float(img.get_height())
		var col := i % columns
		var row := int(i / columns)
		var props := {
			"asset": pages[i],
			"caption": "%s · page %d/%d" % [display, i + 1, pages.size()],
			"aspect": aspect,
			"width": 4.4,
			"pdf_page": i + 1,
			"pdf_pages": pages.size(),
		}
		var local := Vector3(float(col) * 5.2 - float(columns - 1) * 2.6, -float(row) * 6.4 + 3.0, 0.0)
		var item := project.add_item("pdf", local, props, project.active_layer_id, group_id)
		page_ids.append(str(item.get("id", "")))
	undo.commit(project, "Import PDF")
	_spawn_for_item(group, false)
	for item in project.items:
		if page_ids.has(str(item.get("id", ""))) and str(item.get("id", "")) != group_id:
			_spawn_for_item(item, false)
	set_tool("select")
	select_ids([group_id])
	dirty = true
	_schedule_save()
	ui.refresh()
	ui.toast("PDF imported · %d pages" % pages.size(), "picture_as_pdf", Kit.GREEN)
	_schedule_focus_ids(page_ids)
	_haptic(17)


func _import_zip(path: String) -> void:
	ui.set_busy(true, "Restoring backup…")
	await get_tree().process_frame
	var restored := Store.restore_backup_zip(path)
	ui.set_busy(false)
	if restored == null:
		ui.toast("This backup could not be restored", "warning", Kit.DANGER)
		return
	_enter_project(restored, false)
	ui.refresh()
	ui.toast("Backup restored", "restore", Kit.GREEN)
	_haptic(18)


func _import_json_board(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		ui.toast("Could not open that board", "warning", Kit.DANGER)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		ui.toast("That file is not a board", "warning", Kit.DANGER)
		return
	var imported := CanvasProject.from_dict(parsed)
	imported.id = CanvasProject.gen_id("prj")
	imported.title = imported.title + " Imported"
	imported.created_at = Time.get_unix_time_from_system()
	imported.updated_at = imported.created_at
	var target_dir := Store.assets_dir(imported.id)
	DirAccess.make_dir_recursive_absolute(target_dir)
	for item in imported.items:
		var asset := str(item.get("props", {}).get("asset", ""))
		if not asset.is_empty() and FileAccess.file_exists(asset):
			var target := "%s/%s" % [target_dir, asset.get_file()]
			var src := FileAccess.open(asset, FileAccess.READ)
			if src != null:
				var out := FileAccess.open(target, FileAccess.WRITE)
				if out != null:
					out.store_buffer(src.get_buffer(src.get_length()))
					out.close()
					item.get("props", {})["asset"] = target
				src.close()
	Store.save_project(imported)
	_enter_project(imported, false)
	ui.refresh()
	ui.toast("Board imported", "upload_file", Kit.GREEN)
	_haptic(16)


func export_format(format: String) -> void:
	match format:
		"png":
			_export_png()
		"json":
			var path := Store.export_json(project)
			if path.is_empty():
				ui.toast("Export failed", "warning", Kit.DANGER)
			else:
				ui.close_sheet()
				_save_with_dialog(path, path.get_file())
		"md":
			var path := Store.export_markdown(project)
			if path.is_empty():
				ui.toast("Export failed", "warning", Kit.DANGER)
			else:
				ui.close_sheet()
				_save_with_dialog(path, path.get_file())
		"zip":
			ui.set_busy(true, "Packing backup…")
			await get_tree().process_frame
			var path := Store.create_backup_zip(project)
			ui.set_busy(false)
			if path.is_empty():
				ui.toast("Backup failed", "warning", Kit.DANGER)
			else:
				ui.close_sheet()
				_save_with_dialog(path, path.get_file())
		"glb":
			_export_glb()
		_:
			ui.toast("Unknown export format", "warning", Kit.DANGER)


func _export_png() -> void:
	ui.close_sheet()
	ui.set_busy(true, "Rendering snapshot…")
	await get_tree().process_frame
	await get_tree().process_frame
	ui.visible = false
	ui.set_busy(false)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	ui.visible = true
	if image == null or image.is_empty():
		ui.toast("Snapshot could not be captured", "warning", Kit.DANGER)
		return
	var filename := "%s_%s.png" % [Store.safe_name(project.title), str(int(Time.get_unix_time_from_system()))]
	var path := "user://exports/" + filename
	DirAccess.make_dir_recursive_absolute("user://exports")
	var err := image.save_png(path)
	if err != OK:
		ui.toast("Could not write the PNG", "warning", Kit.DANGER)
		return
	_save_with_dialog(path, filename)


func _save_with_dialog(source_path: String, suggested: String) -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = OS.has_feature("android")
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.current_file = suggested
	dialog.title = "Save " + suggested
	if not OS.has_feature("android"):
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var filters := PackedStringArray(["*%s ; %s" % [source_path.get_extension(), source_path.get_extension().to_upper()]])
	dialog.filters = filters
	dialog.file_selected.connect(func(target):
		dialog.queue_free()
		if target == source_path:
			ui.toast("Saved in the app export folder", "save", Kit.GREEN)
			return
		var source := FileAccess.open(source_path, FileAccess.READ)
		if source == null:
			ui.toast("Could not read the exported file", "warning", Kit.DANGER)
			return
		var target_file := FileAccess.open(target, FileAccess.WRITE)
		if target_file == null:
			source.close()
			ui.toast("Could not write there. The file is kept in the app export folder.", "warning", Kit.GOLD, 3.2)
			return
		target_file.store_buffer(source.get_buffer(source.get_length()))
		source.close()
		target_file.close()
		ui.toast("Saved to your device", "download", Kit.GREEN, 2.4)
		_haptic(16)
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())
	ui.add_child(dialog)
	dialog.popup_centered_ratio(0.9)


func _export_glb() -> void:
	var path := _write_glb("")
	if path.is_empty():
		ui.toast("No 3D objects to export", "warning", Kit.GOLD)
		return
	ui.close_sheet()
	_save_with_dialog(path, path.get_file())


func export_selected_glb() -> void:
	var path := _write_glb(str(selected_ids[0]) if selected_ids.size() == 1 else "")
	if path.is_empty():
		ui.toast("No 3D objects to export", "warning", Kit.GOLD)
		return
	_save_with_dialog(path, path.get_file())


func _write_glb(only_id: String) -> String:
	var export_root := Node3D.new()
	export_root.name = "InfiniteCanvas3D"
	add_child(export_root)
	var count := 0
	if not only_id.is_empty():
		var node: CanvasItem3D = item_nodes.get(only_id, null)
		if node is PrimitiveItem:
			var dup: MeshInstance3D = node.mesh_instance.duplicate()
			export_root.add_child(dup)
			dup.global_transform = node.mesh_instance.global_transform
			count += 1
		elif node is ModelItem and node.model_root != null:
			var dup: Node3D = node.model_root.duplicate()
			export_root.add_child(dup)
			dup.global_transform = node.model_root.global_transform
			count += 1
	else:
		for node in item_nodes.values():
			if node is PrimitiveItem:
				var dup: MeshInstance3D = node.mesh_instance.duplicate()
				export_root.add_child(dup)
				dup.global_transform = node.mesh_instance.global_transform
				count += 1
			elif node is ModelItem and node.model_root != null:
				var dup: Node3D = node.model_root.duplicate()
				export_root.add_child(dup)
				dup.global_transform = node.model_root.global_transform
				count += 1
	if count == 0:
		export_root.free()
		return ""
	var filename := "%s_3d.glb" % Store.safe_name(project.title)
	var path := "user://exports/" + filename
	DirAccess.make_dir_recursive_absolute("user://exports")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(export_root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(path))
	export_root.free()
	if err != OK:
		return ""
	return path


func create_backup() -> void:
	export_format("zip")


func preview_selected_media() -> void:
	for id in selected_ids:
		var node: CanvasItem3D = item_nodes.get(str(id), null)
		if node is MediaItem:
			var media := node as MediaItem
			var texture := media.get_texture()
			if texture != null:
				var caption := str(media.data.get("props", {}).get("caption", ""))
				ui.open_image_preview(texture, caption)
				return


func relink_selected() -> void:
	if selected_ids.size() != 1:
		return
	var item := project.get_item(str(selected_ids[0]))
	if item.is_empty():
		return
	var type := str(item.get("type", ""))
	ui.close_sheet()
	if type == "model":
		_pick_file(PackedStringArray(["*.glb, *.gltf ; 3D models ; model/gltf-binary,model/gltf+json"]), func(path):
			var asset := Store.copy_asset(project.id, path)
			if not asset.is_empty():
				item.get("props", {})["asset"] = asset
				var node: CanvasItem3D = item_nodes.get(str(selected_ids[0]), null)
				if node != null:
					node.refresh_from_data()
				dirty = true
				_schedule_save()
				ui.toast("3D model re-linked", "attach_file", Kit.GREEN)
		)
	else:
		_pick_file(PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images ; image/png,image/jpeg,image/webp"]), func(path):
			var asset := Store.copy_asset(project.id, path)
			if not asset.is_empty():
				item.get("props", {})["asset"] = asset
				var image := Image.load_from_file(asset)
				if image != null and not image.is_empty():
					item.get("props", {})["aspect"] = float(image.get_width()) / float(image.get_height())
				var node: CanvasItem3D = item_nodes.get(str(selected_ids[0]), null)
				if node != null:
					node.refresh_from_data()
				dirty = true
				_schedule_save()
				ui.toast("Media re-linked", "attach_file", Kit.GREEN)
		)


# ------------------------------------------------------------------ billing wrappers

func get_products() -> Array:
	if billing == null:
		return []
	return billing.products


func get_billing_message() -> String:
	if billing == null:
		return "Google Play Billing is not available."
	return billing.get_status_text()


func purchase(product_id: String) -> void:
	if billing != null:
		billing.purchase_product(product_id)


func restore_purchases() -> void:
	if billing != null:
		billing.restore_purchases()


func retry_billing() -> void:
	if billing != null:
		billing.retry()


# ------------------------------------------------------------------ utilities

func _hex(color: Color) -> String:
	return "#" + color.to_html(false)


func _haptic(ms: int) -> void:
	if project != null and not bool(project.settings.get("haptics", true)):
		return
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(ms)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if project != null:
			save_now()
			Store.autosave(project)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui != null and ui.handle_back():
			return
		if not selected_ids.is_empty() or not selected_connector_id.is_empty():
			select_ids([])
			return
		save_now()
		get_tree().quit()

