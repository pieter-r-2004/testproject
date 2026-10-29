extends RefCounted
## Rendering-independent bootstrap state. Advances only through explicit calls.
## The diagnostic step is not a gameplay turn, action, or combat event.

const GridDefinition = preload("res://scripts/simulation/grid_map.gd")
const DEFAULT_SEED: int = 12345

var grid: GridDefinition
var _initial_seed: int
var _step_index: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int = DEFAULT_SEED, grid_size: Vector2i = Vector2i(12, 12)) -> void:
	grid = GridDefinition.new(grid_size)
	_initial_seed = seed_value
	_rng.seed = seed_value


func step() -> Dictionary:
	_step_index += 1
	return {"step": _step_index, "sample": _rng.randi_range(1, 6)}


func snapshot() -> Dictionary:
	# Return fresh value containers so inspection cannot mutate the live state.
	return {
		"seed": _initial_seed,
		"step_index": _step_index,
		"rng_state": _rng.state,
		"grid": {"width": grid.width, "height": grid.height},
	}
