extends RefCounted
## Milestone 0 dimensions only. Occupancy, terrain, and paths belong to M1.
## The 12x12 default is a future 1v1 test arena, not the group-battle size limit.

var width: int = 12
var height: int = 12


func _init(dimensions: Vector2i = Vector2i(12, 12)) -> void:
	width = dimensions.x
	height = dimensions.y
