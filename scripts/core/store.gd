class_name Store
extends RefCounted

const PROJECTS_DIR := "user://projects"
const ASSETS_DIR := "user://assets"
const BACKUPS_DIR := "user://backups"
const EXPORTS_DIR := "user://exports"
const MAX_AUTOSAVES := 12


static func ensure_dirs() -> void:
	for path in [PROJECTS_DIR, ASSETS_DIR, BACKUPS_DIR, EXPORTS_DIR]:
		DirAccess.make_dir_recursive_absolute(path)


static func safe_name(value: String, fallback := "Board") -> String:
	var cleaned := value.strip_edges()
	var invalid := ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for ch in invalid:
		cleaned = cleaned.replace(ch, "-")
	cleaned = cleaned.replace(" ", "-")
	cleaned = cleaned.strip_edges().trim_prefix(".").trim_suffix(".")
	if cleaned.length() > 48:
		cleaned = cleaned.substr(0, 48)
	return cleaned if not cleaned.is_empty() else fallback


static func project_path(project_id: String) -> String:
	return "%s/%s.json" % [PROJECTS_DIR, project_id]


static func assets_dir(project_id: String) -> String:
	return "%s/%s" % [ASSETS_DIR, project_id]


static func save_project(project: CanvasProject) -> bool:
	ensure_dirs()
	project.touch()
	DirAccess.make_dir_recursive_absolute(assets_dir(project.id))
	var path := project_path(project.id)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write project: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(project.to_dict(), "", false, true))
	file.close()
	var dir := DirAccess.open(PROJECTS_DIR)
	if dir == null:
		return false
	if dir.file_exists(project.id + ".json"):
		dir.remove(project.id + ".json")
	return dir.rename(project.id + ".json.tmp", project.id + ".json") == OK


static func load_project(project_id: String) -> CanvasProject:
	var path := project_path(project_id)
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return CanvasProject.from_dict(parsed)


static func list_projects() -> Array:
	ensure_dirs()
	var dir := DirAccess.open(PROJECTS_DIR)
	if dir == null:
		return []
	var result := []
	for filename in dir.get_files():
		if not filename.ends_with(".json"):
			continue
		var path := "%s/%s" % [PROJECTS_DIR, filename]
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var project := CanvasProject.from_dict(parsed)
		result.append({
			"id": project.id,
			"title": project.title,
			"updated_at": project.updated_at,
			"created_at": project.created_at,
			"stats": project.stats(),
		})
	result.sort_custom(func(a, b): return float(a["updated_at"]) > float(b["updated_at"]))
	return result


static func delete_project(project_id: String) -> bool:
	var path := project_path(project_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_remove_dir_recursive(assets_dir(project_id))
	_remove_dir_recursive("%s/%s" % [BACKUPS_DIR, project_id])
	return true


static func duplicate_project(project_id: String) -> CanvasProject:
	var project := load_project(project_id)
	if project == null:
		return null
	var new_id := CanvasProject.gen_id("prj")
	var new_project := CanvasProject.from_dict(project.to_dict())
	new_project.id = new_id
	new_project.title = project.title + " Copy"
	new_project.created_at = Time.get_unix_time_from_system()
	new_project.updated_at = new_project.created_at
	var old_assets := assets_dir(project_id)
	var new_assets := assets_dir(new_id)
	DirAccess.make_dir_recursive_absolute(new_assets)
	for item in new_project.items:
		var asset_path := str(item.get("props", {}).get("asset", ""))
		if asset_path.begins_with("user://"):
			var relative := asset_path.trim_prefix("user://")
			var subpath := relative.trim_prefix("assets/%s/" % project_id)
			var new_path := "%s/%s" % [new_assets, subpath]
			_copy_file(asset_path, new_path)
			item.get("props", {})["asset"] = new_path
	save_project(new_project)
	return new_project


static func display_name(path: String) -> String:
	var cleaned := path.replace("\\", "/").uri_decode()
	var name := cleaned.get_file()
	if name.is_empty() or name.contains("%"):
		var parts := path.replace("\\", "/").split("/")
		if not parts.is_empty():
			name = parts[parts.size() - 1].uri_decode()
	if name.is_empty() or name == "/":
		name = "Imported file"
	return name


static func copy_asset(project_id: String, source_path: String, keep_original := false) -> String:
	ensure_dirs()
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return ""
	var dir_path := assets_dir(project_id)
	DirAccess.make_dir_recursive_absolute(dir_path)
	var base := display_name(source_path)
	if base.is_empty():
		base = "asset_%s" % str(Time.get_ticks_msec())
	base = base.replace(" ", "_")
	var extension := base.get_extension().to_lower()
	var stamp := str(Time.get_unix_time_from_system()).replace(".", "")
	var filename := "%s_%s" % [stamp, base]
	var target := "%s/%s" % [dir_path, filename]
	if FileAccess.file_exists(source_path):
		var already_ours := source_path.begins_with("user://") and source_path.contains(project_id)
		if already_ours and keep_original:
			return source_path
		if extension in ["png", "jpg", "jpeg", "webp", "bmp", "tga"]:
			var image := Image.load_from_file(source_path)
			if image != null and not image.is_empty():
				if image.get_width() > 2400 or image.get_height() > 2400:
					var ratio := 2400.0 / float(maxi(image.get_width(), image.get_height()))
					image.resize(int(image.get_width() * ratio), int(image.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
				if image.is_compressed():
					image.decompress()
				filename = filename.get_basename() + ".webp"
				target = "%s/%s" % [dir_path, filename]
				image.save_webp(target, 0.9)
				return target
		_copy_file(source_path, target)
		return target
	return ""


static func _copy_file(source_path: String, target_path: String) -> bool:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return false
	DirAccess.make_dir_recursive_absolute(target_path.get_base_dir())
	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		source.close()
		return false
	target.store_buffer(source.get_buffer(source.get_length()))
	source.close()
	target.close()
	return true


static func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for subdir in dir.get_directories():
		_remove_dir_recursive(path + "/" + subdir)
	for file in dir.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + "/" + file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func autosave(project: CanvasProject) -> String:
	ensure_dirs()
	var dir_path := "%s/%s" % [BACKUPS_DIR, project.id]
	DirAccess.make_dir_recursive_absolute(dir_path)
	var filename := "auto_%s.json" % str(int(Time.get_unix_time_from_system()))
	var path := "%s/%s" % [dir_path, filename]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(project.to_dict(), "", false, true))
	file.close()
	save_project(project)
	var backups := list_autosaves(project.id)
	while backups.size() > MAX_AUTOSAVES:
		var oldest: Dictionary = backups.pop_back()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(oldest["path"]))
	return path


static func list_autosaves(project_id: String) -> Array:
	var dir_path := "%s/%s" % [BACKUPS_DIR, project_id]
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return []
	var result := []
	for filename in dir.get_files():
		if not filename.ends_with(".json"):
			continue
		var path := "%s/%s" % [dir_path, filename]
		result.append({
			"path": path,
			"filename": filename,
			"timestamp": FileAccess.get_modified_time(path),
			"size": FileAccess.get_size(path),
		})
	result.sort_custom(func(a, b): return int(a["timestamp"]) > int(b["timestamp"]))
	return result


static func restore_autosave(path: String) -> CanvasProject:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return CanvasProject.from_dict(parsed)


static func clear_exports() -> void:
	_remove_dir_recursive(EXPORTS_DIR)
	ensure_dirs()


static func create_backup_zip(project: CanvasProject) -> String:
	ensure_dirs()
	var filename := "%s_backup_%s.ic3d.zip" % [safe_name(project.title), str(int(Time.get_unix_time_from_system()))]
	var path := "%s/%s" % [EXPORTS_DIR, filename]
	var packer := ZIPPacker.new()
	var err := packer.open(path)
	if err != OK:
		return ""
	packer.start_file("project.json")
	packer.write_file(JSON.stringify(project.to_dict(), "", false, true).to_utf8_buffer())
	packer.close_file()
	var asset_root := assets_dir(project.id)
	var asset_files := _collect_files(asset_root)
	for asset_path in asset_files:
		var relative: String = str(asset_path).trim_prefix(asset_root + "/")
		packer.start_file("assets/" + relative)
		var file := FileAccess.open(asset_path, FileAccess.READ)
		if file != null:
			packer.write_file(file.get_buffer(file.get_length()))
			file.close()
		packer.close_file()
	packer.close()
	return path


static func restore_backup_zip(zip_path: String) -> CanvasProject:
	if not FileAccess.file_exists(zip_path):
		return null
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return null
	var project_bytes := reader.read_file("project.json")
	if project_bytes.is_empty():
		reader.close()
		return null
	var parsed = JSON.parse_string(project_bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		reader.close()
		return null
	var project := CanvasProject.from_dict(parsed)
	var new_id := CanvasProject.gen_id("prj")
	project.id = new_id
	project.title = project.title + " Restored"
	project.updated_at = Time.get_unix_time_from_system()
	var new_assets := assets_dir(new_id)
	DirAccess.make_dir_recursive_absolute(new_assets)
	var copied := {}
	for entry in reader.get_files():
		if entry.begins_with("assets/"):
			var bytes := reader.read_file(entry)
			var relative := entry.trim_prefix("assets/")
			var target := "%s/%s" % [new_assets, relative]
			DirAccess.make_dir_recursive_absolute(target.get_base_dir())
			var out := FileAccess.open(target, FileAccess.WRITE)
			if out != null:
				out.store_buffer(bytes)
				out.close()
			copied[relative] = target
	reader.close()
	for item in project.items:
		var asset := str(item.get("props", {}).get("asset", ""))
		if not asset.is_empty():
			var relative := asset.get_file()
			if copied.has(relative):
				item.get("props", {})["asset"] = copied[relative]
			else:
				for rel in copied.keys():
					if str(rel).ends_with(relative):
						item.get("props", {})["asset"] = copied[rel]
						break
	save_project(project)
	return project


static func _collect_files(path: String) -> Array:
	var result := []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for subdir in dir.get_directories():
		result.append_array(_collect_files(path + "/" + subdir))
	for file in dir.get_files():
		result.append(path + "/" + file)
	return result


static func export_json(project: CanvasProject, target_path := "") -> String:
	ensure_dirs()
	if target_path.is_empty():
		target_path = "%s/%s.ic3d.json" % [EXPORTS_DIR, safe_name(project.title)]
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(project.to_dict(), "\t", false, true))
	file.close()
	return target_path


static func export_markdown(project: CanvasProject, target_path := "") -> String:
	ensure_dirs()
	if target_path.is_empty():
		target_path = "%s/%s.md" % [EXPORTS_DIR, safe_name(project.title)]
	var lines := ["# " + project.title, ""]
	var stats := project.stats()
	lines.append("_Exported %s — %d objects, %d connections, %d frames_" % [Time.get_date_string_from_system(), stats["items"], stats["connectors"], stats["frames"]])
	lines.append("")
	for layer in project.layers:
		var layer_items := project.items_in_layer(layer.get("id", ""))
		if layer_items.is_empty():
			continue
		lines.append("## " + str(layer.get("name", "Layer")))
		lines.append("")
		for item in layer_items:
			var props: Dictionary = item.get("props", {})
			var type: String = item.get("type", "")
			if type in ["note", "text"]:
				var note_title := str(props.get("title", "Untitled"))
				var body := str(props.get("body", ""))
				lines.append("### " + note_title)
				if not body.is_empty():
					lines.append(body)
				var tags: Array = props.get("tags", [])
				if not tags.is_empty():
					lines.append("Tags: " + ", ".join(tags))
				lines.append("")
			elif type == "frame":
				lines.append("### Shot %02d — %s" % [int(props.get("order", 0)), str(props.get("title", "Frame"))])
				var description := str(props.get("body", ""))
				if not description.is_empty():
					lines.append(description)
				lines.append("Duration: %ss" % str(props.get("duration", 3)))
				lines.append("")
			elif type == "image":
				lines.append("- Image: " + str(props.get("caption", props.get("asset", "image"))))
			elif type == "pdf":
				lines.append("- PDF page: " + str(props.get("caption", "PDF")))
			elif type == "model":
				lines.append("- 3D model: " + str(props.get("title", "Model")))
			elif type == "primitive":
				lines.append("- 3D %s" % str(props.get("shape", "object")))
		lines.append("")
	if not project.connectors.is_empty():
		lines.append("## Connections")
		lines.append("")
		for connector in project.connectors:
			var from_item := project.get_item(connector.get("from", ""))
			var to_item := project.get_item(connector.get("to", ""))
			if from_item.is_empty() or to_item.is_empty():
				continue
			lines.append("- %s → %s" % [_item_label(from_item), _item_label(to_item)])
		lines.append("")
	if not project.bookmarks.is_empty():
		lines.append("## Camera Bookmarks")
		lines.append("")
		for bookmark in project.bookmarks:
			lines.append("- " + str(bookmark.get("name", "View")))
		lines.append("")
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string("\n".join(lines))
	file.close()
	return target_path


static func _item_label(item: Dictionary) -> String:
	var props: Dictionary = item.get("props", {})
	var label := str(props.get("title", "")).strip_edges()
	if label.is_empty():
		label = str(props.get("caption", "")).strip_edges()
	if label.is_empty():
		label = str(item.get("type", "Item")).capitalize()
	return label
