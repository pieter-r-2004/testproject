extends Node2D
## Minimal developer readout, built from labels and shapes with no external art.

const TEXT: Color = Color("e4edf5")
const MUTED: Color = Color("8299ad")
const ACCENT: Color = Color("6edac5")


func _ready() -> void:
	var world = $Battlefield.world
	_label("PICK ME UP / PROTOTYPE", 48, 22, 12, ACCENT)
	_label("Autonomous Heroes", 48, 43, 30, TEXT)
	_label("Deterministic simulation sandbox", 49, 87, 15, MUTED)
	_label("MILESTONE 00", 812, 57, 14, ACCENT)
	_label("BATTLEFIELD", 72, 132, 12, MUTED)
	_label("BOOTSTRAP", 720, 197, 12, ACCENT)
	_label("1v1 test arena", 720, 224, 21, TEXT)
	_label("%d x %d square grid" % [world.grid.width, world.grid.height], 720, 265, 17, TEXT)
	_label("%d placeholder tiles" % [world.grid.width * world.grid.height], 720, 293, 14, MUTED)
	_label("SIMULATION", 720, 346, 12, ACCENT)
	_label("Seed       %d" % world.snapshot()["seed"], 720, 376, 16, TEXT)
	_label("Step       %d" % world.snapshot()["step_index"], 720, 404, 16, TEXT)
	_label("View only / no automatic steps", 720, 438, 13, MUTED)
	_label("PLACEHOLDER GRAPHICS", 720, 493, 12, ACCENT)
	_label("Empty placeholder arena.\nGroup maps will be larger.", 720, 524, 14, MUTED)
	_label("LOCAL DEVELOPMENT", 720, 620, 12, ACCENT)
	_label("Godot 4 / Compatibility\nCPU-only headless tests\nNo AI training required", 720, 651, 14, MUTED)
	_label("FOUNDATION ONLY", 48, 781, 12, ACCENT)
	_label("No combat, agents, or model connection in Milestone 0", 204, 780, 13, MUTED)


func _draw() -> void:
	draw_line(Vector2(48, 120), Vector2(952, 120), Color("23394b"))
	draw_rect(Rect2(696, 176, 256, 576), Color("10202e"))
	draw_line(Vector2(720, 328), Vector2(928, 328), Color("23394b"))
	draw_line(Vector2(720, 475), Vector2(928, 475), Color("23394b"))
	draw_line(Vector2(720, 600), Vector2(928, 600), Color("23394b"))


func _label(text: String, x: float, y: float, size: int, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(x, y)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
