class_name UndoManager
extends RefCounted

signal changed

var limit := 60
var last_action := ""
var _undo: Array = []
var _redo: Array = []
var _before: Dictionary = {}
var _has_pending := false


func begin(project: CanvasProject) -> void:
	if _has_pending:
		return
	_before = project.to_dict()
	_has_pending = true


func commit(project: CanvasProject, label: String) -> bool:
	if not _has_pending:
		return false
	var after := project.to_dict()
	var unchanged: bool = _before == after
	_has_pending = false
	if unchanged:
		return false
	_undo.append({"label": label, "before": _before, "after": after})
	if _undo.size() > limit:
		_undo.pop_front()
	_redo.clear()
	last_action = label
	changed.emit()
	return true


func cancel() -> void:
	_has_pending = false
	_before = {}


func clear() -> void:
	_undo.clear()
	_redo.clear()
	_cancel_internal()
	changed.emit()


func _cancel_internal() -> void:
	_has_pending = false
	_before = {}


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo_label() -> String:
	if _undo.is_empty():
		return ""
	return str(_undo[-1].get("label", ""))


func redo_label() -> String:
	if _redo.is_empty():
		return ""
	return str(_redo[-1].get("label", ""))


func undo(project: CanvasProject) -> bool:
	if _undo.is_empty():
		return false
	var entry: Dictionary = _undo.pop_back()
	_redo.append(entry)
	project.apply_dict((entry["before"] as Dictionary).duplicate(true))
	last_action = "Undo " + str(entry.get("label", ""))
	_cancel_internal()
	changed.emit()
	return true


func redo(project: CanvasProject) -> bool:
	if _redo.is_empty():
		return false
	var entry: Dictionary = _redo.pop_back()
	_undo.append(entry)
	project.apply_dict((entry["after"] as Dictionary).duplicate(true))
	last_action = "Redo " + str(entry.get("label", ""))
	_cancel_internal()
	changed.emit()
	return true


func depth() -> int:
	return _undo.size()
