class_name GroupItem
extends CanvasItem3D


func _build() -> void:
	_rect = Rect2(-0.05, -0.05, 0.1, 0.1)


func is_flat() -> bool:
	return false


func hit_test_ray(_origin: Vector3, _dir: Vector3) -> float:
	return -1.0


func get_center_world() -> Vector3:
	return global_position


func get_bounds_aabb() -> AABB:
	return AABB(global_position, Vector3(0.1, 0.1, 0.1))
