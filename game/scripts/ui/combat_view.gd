extends Node2D
## Static placeholder viewer. It reads dimensions; it never advances the world.

const WorldState = preload("res://scripts/simulation/world_state.gd")
const TILE_SIZE: int = 48
const TILE_A: Color = Color("172b3b")
const TILE_B: Color = Color("1b3243")
const GRID_LINE: Color = Color("304b5d")
const COORDINATE_COLOR: Color = Color("8299ad")

var world = WorldState.new()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for row in range(world.grid.height):
		for column in range(world.grid.width):
			var cell: Rect2 = Rect2(
				Vector2(column * TILE_SIZE, row * TILE_SIZE), Vector2.ONE * TILE_SIZE
			)
			draw_rect(cell, TILE_A if (column + row) % 2 == 0 else TILE_B)
	for column in range(world.grid.width + 1):
		var x: float = column * TILE_SIZE
		draw_line(Vector2(x, 0), Vector2(x, world.grid.height * TILE_SIZE), GRID_LINE)
	for row in range(world.grid.height + 1):
		var y: float = row * TILE_SIZE
		draw_line(Vector2(0, y), Vector2(world.grid.width * TILE_SIZE, y), GRID_LINE)
	for column in range(world.grid.width):
		draw_string(font, Vector2(column * TILE_SIZE + 15, -12),
			str(column + 1).pad_zeros(2), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COORDINATE_COLOR)
	for row in range(world.grid.height):
		draw_string(font, Vector2(-30, row * TILE_SIZE + 29),
			str(row + 1).pad_zeros(2), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COORDINATE_COLOR)
	draw_rect(Rect2(Vector2.ZERO,
		Vector2(world.grid.width, world.grid.height) * TILE_SIZE), Color("52798c"), false, 2.0)
