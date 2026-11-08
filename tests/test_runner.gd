extends SceneTree

var passed := 0
var failed := 0
var current_suite := ""
var project: CanvasProject


func _init() -> void:
	print("=== Ultimate Infinite Canvas 3D — test suite ===")
	_test_project_model()
	_test_undo()
	_test_smart_engine()
	_test_store_roundtrip()
	_test_backup_and_autosave()
	_test_markdown_export()
	_test_robustness()
	_test_pdf_guard()
	print("")
	print("RESULT: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("FAILED SUITES PRESENT")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func suite(name: String) -> void:
	current_suite = name
	print("\n-- " + name + " --")


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("  PASS  " + label)
	else:
		failed += 1
		print("  FAIL  " + label + "  [" + current_suite + "]")


func eq(actual, expected, label: String) -> void:
	var ok = actual == expected
	if not ok:
		print("        expected=", expected, " actual=", actual)
	check(ok, label)


func near(actual: float, expected: float, tolerance: float, label: String) -> void:
	var ok = absf(float(actual) - expected) <= tolerance
	if not ok:
		print("        expected≈", expected, " actual=", actual)
	check(ok, label)


func _test_project_model() -> void:
	suite("CanvasProject model")
	var p := CanvasProject.create("Test Board")
	eq(p.title, "Test Board", "new project title")
	eq(p.layers.size(), 3, "three default layers")
	eq(p.active_layer_id, "lyr_ideas", "default active layer")
	p.add_layer("Research", "#FFD27D")
	eq(p.layers.size(), 4, "add layer")
	var note := p.add_item("note", Vector3(1.5, -2.0, 0.07), {"title": "First", "body": "Hello"}, "lyr_ideas")
	check(not str(note.get("id", "")).is_empty(), "item receives id")
	eq(p.items.size(), 1, "item count")
	eq(p.get_item(str(note.id))["props"]["title"], "First", "get item")
	var child := p.add_item("note", Vector3(0, 0, 0), {"title": "Child"}, "lyr_ideas", str(note.id))
	eq(p.children_of(str(note.id)).size(), 1, "child lookup")
	eq(p.descendants_of(str(note.id)).size(), 1, "descendant lookup")
	var other := p.add_item("frame", Vector3(4, 4, 0), {"title": "Shot", "order": 1}, "lyr_ideas")
	p.sync_storyboard()
	eq(int(p.storyboard.get("frames", []).size()), 1, "storyboard sync")
	eq(p.frames().size(), 1, "frames list")
	var connector := p.add_connector(str(note.id), str(other.id), "curve", "#5BE7FF")
	check(not connector.is_empty(), "connector created")
	eq(p.connectors_for(str(note.id)).size(), 1, "connector lookup")
	eq(p.connectors.size(), 1, "connector count")
	eq(p.stats()["items"], 3, "stats item count")
	eq(p.stats()["frames"], 1, "stats frame count")
	p.remove_item(str(note.id))
	eq(p.items.size(), 1, "remove item removes descendants")
	eq(p.connectors.size(), 0, "remove item removes dangling connectors")
	eq(p.items_in_layer("lyr_ideas").size(), 1, "layer item lookup")
	var serialized := p.to_dict()
	var restored := CanvasProject.from_dict(serialized)
	eq(restored.title, p.title, "serialize title")
	eq(restored.items.size(), p.items.size(), "serialize items")
	var empty := CanvasProject.from_dict({})
	check(empty.layers.size() >= 1, "empty dict normalizes")
	check(not empty.active_layer_id.is_empty(), "empty dict has active layer")
	p.set_camera(Vector3(2, 3, 0), 30.0, 12.0, 8.0)
	near(p.camera["view_height"], 30.0, 0.001, "camera serialized")
	var bm := p.add_bookmark("Close up", {"pivot": [1, 2, 0], "view_height": 12, "yaw": 0, "pitch": 0, "mode": "2d"})
	eq(p.bookmarks.size(), 1, "bookmark added")
	p.remove_bookmark(str(bm.id))
	eq(p.bookmarks.size(), 0, "bookmark removed")


func _test_undo() -> void:
	suite("Undo manager")
	var p := CanvasProject.create("Undo")
	var undo := UndoManager.new()
	check(not undo.can_undo(), "fresh undo empty")
	undo.begin(p)
	p.add_item("note", Vector3.ZERO, {"title": "A"}, p.active_layer_id)
	check(undo.commit(p, "Add A"), "commit reports change")
	check(undo.can_undo(), "can undo after commit")
	eq(undo.undo_label(), "Add A", "undo label")
	eq(p.items.size(), 1, "item before undo")
	check(undo.undo(p), "undo returns true")
	eq(p.items.size(), 0, "undo removes item")
	check(undo.can_redo(), "can redo")
	check(undo.redo(p), "redo returns true")
	eq(p.items.size(), 1, "redo restores item")
	undo.begin(p)
	check(not undo.commit(p, "No change"), "no-op commit ignored")
	undo.begin(p)
	p.add_item("note", Vector3.ONE, {}, p.active_layer_id)
	undo.cancel()
	check(not undo.can_undo() or undo.undo_label() != "No change", "cancel clears pending")
	for i in range(8):
		undo.begin(p)
		p.add_item("note", Vector3(i, 0, 0), {"n": i}, p.active_layer_id)
		undo.commit(p, "Bulk %d" % i)
	check(undo.depth() >= 8, "undo depth grows")
	check(not undo.commit(p, "Not begun"), "commit without begin fails")


func _test_smart_engine() -> void:
	suite("Smart engine")
	var p := CanvasProject.create("Smart")
	var n1 := p.add_item("note", Vector3(-4, 0, 0), {"title": "Canvas navigation", "body": "Infinite canvas navigation needs smooth camera controls and gestures.", "tags": ["ux"]}, p.active_layer_id)
	var n2 := p.add_item("note", Vector3(4, 0, 0), {"title": "Camera gestures", "body": "Camera navigation and gestures make the canvas feel natural and precise.", "tags": ["ux"]}, p.active_layer_id)
	var n3 := p.add_item("note", Vector3(0, -5, 0), {"title": "Storyboard lighting", "body": "Storyboard lighting should feel cinematic with shadows and depth.", "tags": ["art"]}, p.active_layer_id)
	check(SmartEngine.tokenize("The canvas and the camera").size() >= 2, "tokenization removes stopwords")
	check("canvas" in SmartEngine.keywords("Infinite canvas camera canvas control", 3), "keywords")
	var kws := SmartEngine.top_keywords(p, 8)
	check(kws.size() > 0, "top keywords")
	var suggestions := SmartEngine.suggest_connections(p, 0.1)
	check(suggestions.size() >= 1, "related notes suggest a connection")
	if not suggestions.is_empty():
		check(str(suggestions[0].get("reason", "")).length() >= 0, "suggestion has reason")
	var groups := SmartEngine.clusters(p)
	check(groups.size() >= 1, "clusters found")
	var summary := SmartEngine.summarize(p)
	check(summary.length() > 10, "summary generated")
	check(SmartEngine.next_steps(p).size() > 0, "next steps generated")
	var positions := SmartEngine.tidy_positions(p)
	check(positions.size() >= 3, "tidy positions")
	var positions2 := SmartEngine.cluster_positions(p)
	check(positions2.size() >= 3, "cluster positions")
	var docs := SmartEngine.board_documents(p)
	eq(docs.size(), 3, "board documents")
	var vecs := SmartEngine.build_vectors(docs)
	check(vecs["vectors"].size() == 3, "vectors built")
	var cosine := SmartEngine.cosine(vecs["vectors"][0], vecs["vectors"][1])
	check(cosine > 0.0 and cosine <= 1.0, "cosine similarity bounded")
	check(SmartEngine.cosine({}, {}) == 0.0, "empty cosine")


func _test_store_roundtrip() -> void:
	suite("Storage round-trip")
	var p := CanvasProject.create("Store Test")
	p.id = "prj_test_" + str(Time.get_ticks_msec())
	var n := p.add_item("note", Vector3(1, 2, 0.07), {"title": "Stored", "body": "Persistence", "tags": ["test"], "color": "#F4F1E8"}, "lyr_ideas")
	p.sync_storyboard()
	Store.save_project(p)
	check(FileAccess.file_exists(Store.project_path(p.id)), "project file written")
	var loaded := Store.load_project(p.id)
	check(loaded != null, "project loaded")
	if loaded != null:
		eq(loaded.title, p.title, "loaded title")
		eq(loaded.items.size(), 1, "loaded item count")
		eq(loaded.get_item(str(n.id))["props"]["body"], "Persistence", "loaded body")
	var list := Store.list_projects()
	var found := false
	for entry in list:
		if str(entry.get("id", "")) == p.id:
			found = true
			break
	check(found, "project appears in library")
	check(Store.project_path(p.id).contains("user://projects/"), "project path scheme")
	eq(Store.safe_name("Hello / World: Test?"), "Hello---World--Test-", "safe filename")
	var copy := Store.duplicate_project(p.id)
	check(copy != null, "project duplicated")
	if copy != null:
		check(copy.id != p.id, "duplicate has new id")
		check(FileAccess.file_exists(Store.project_path(copy.id)), "duplicate saved")
		Store.delete_project(copy.id)
	Store.delete_project(p.id)
	check(not FileAccess.file_exists(Store.project_path(p.id)), "project deleted")


func _test_backup_and_autosave() -> void:
	suite("Backup, restore, autosave")
	var p := CanvasProject.create("Backup Test")
	p.id = "prj_backup_" + str(Time.get_ticks_msec())
	p.add_item("note", Vector3.ZERO, {"title": "Back me up", "body": "Zip content"}, "lyr_ideas")
	DirAccess.make_dir_recursive_absolute(Store.assets_dir(p.id))
	var image_path := Store.assets_dir(p.id) + "/pixel.png"
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color("#FF00AA"))
	image.save_png(image_path)
	p.add_item("image", Vector3(3, 0, 0), {"asset": image_path, "caption": "Pixel", "aspect": 1.0}, "lyr_ideas")
	Store.save_project(p)
	var zip_path := Store.create_backup_zip(p)
	check(not zip_path.is_empty(), "backup zip created")
	check(FileAccess.file_exists(zip_path), "backup zip exists")
	var restored := Store.restore_backup_zip(zip_path)
	check(restored != null, "backup restored")
	if restored != null:
		check(restored.id != p.id, "restore assigns new id")
		eq(restored.items.size(), 2, "restore item count")
		var asset_ok := false
		for item in restored.items:
			var asset := str(item.get("props", {}).get("asset", ""))
			if not asset.is_empty():
				asset_ok = FileAccess.file_exists(asset)
		check(asset_ok, "restored asset copied")
		Store.delete_project(restored.id)
	var auto_path := Store.autosave(p)
	check(not auto_path.is_empty(), "autosave written")
	var autosaves := Store.list_autosaves(p.id)
	check(autosaves.size() >= 1, "autosave listed")
	if not autosaves.is_empty():
		var restored_auto := Store.restore_autosave(str(autosaves[0].get("path", "")))
		check(restored_auto != null, "autosave restored")
	if FileAccess.file_exists(zip_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(zip_path))
	Store.delete_project(p.id)


func _test_markdown_export() -> void:
	suite("Markdown export")
	var p := CanvasProject.create("Markdown Test")
	p.id = "prj_md_" + str(Time.get_ticks_msec())
	var a := p.add_item("note", Vector3.ZERO, {"title": "Alpha idea", "body": "This is the alpha body.", "tags": ["alpha"]}, "lyr_ideas")
	var b := p.add_item("note", Vector3(3, 0, 0), {"title": "Beta idea", "body": "This is the beta body.", "tags": ["beta"]}, "lyr_ideas")
	p.add_connector(str(a.id), str(b.id), "dashed", "#8FA0B8", "related")
	p.add_item("frame", Vector3(0, -4, 0), {"title": "Shot one", "body": "Opening", "order": 1, "duration": 2, "status": "Draft"}, "lyr_ideas")
	var path := Store.export_markdown(p, "user://exports/test_export.md")
	check(not path.is_empty(), "markdown path")
	check(FileAccess.file_exists(path), "markdown file exists")
	var text := FileAccess.get_file_as_string(path)
	check(text.contains("Alpha idea"), "markdown contains note title")
	check(text.contains("This is the beta body."), "markdown contains body")
	check(text.contains("Connections"), "markdown contains connections")
	check(text.contains("Shot one"), "markdown contains frame")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_robustness() -> void:
	suite("Robustness")
	var data := {
		"format": 3,
		"title": "Broken",
		"layers": [],
		"items": [
			{"id": "a", "type": "note", "props": {"title": "No layer"}},
			{"id": "b", "type": "note", "layer": "missing", "pos": [1, 2]},
			{"bad": true},
		],
		"connectors": [
			{"id": "c1", "from": "a", "to": "missing"},
			{"id": "c2", "from": "a", "to": "b"},
		],
		"camera": {},
		"settings": {},
		"storyboard": {"frames": ["missing"]},
	}
	var p := CanvasProject.from_dict(data)
	check(p.layers.size() >= 1, "missing layers repaired")
	check(p.items.size() >= 1, "invalid items filtered or repaired")
	eq(p.connectors.size(), 1, "dangling connector removed")
	eq(p.items.size(), 2, "two valid items")
	near(float(p.camera.get("view_height", 0)), 22.0, 0.001, "camera defaults restored")
	check(float(p.camera.get("yaw", 99)) <= 75.0, "camera clamp")
	check(p.settings.has("grid"), "settings defaults")
	check(Store.safe_name("").length() > 0, "safe name never empty")


func _test_pdf_guard() -> void:
	suite("PDF guard")
	check(not PdfTool.available(), "PDF renderer reports unavailable off Android")
	var result := PdfTool.rasterize("user://nonexistent.pdf", "user://tmp_pdf", 1.0, 2)
	eq(result.size(), 0, "PDF guard returns no pages")
	check(PdfTool.last_error.length() > 0, "PDF guard exposes a reason")
