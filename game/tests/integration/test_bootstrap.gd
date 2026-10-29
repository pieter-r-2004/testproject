extends "res://tests/test_suite.gd"
## Example data is export-safe and agrees with the bootstrap simulation.


func run() -> bool:
	var rules: Dictionary = _read_example("res://data/ruleset.json")
	var battlefield: Dictionary = _read_example("res://data/missions/bootstrap_battlefield.json")
	if rules.is_empty() or battlefield.is_empty():
		return false
	check(rules.get("schema_version") == 1, "Rules example has a version")
	check(rules.get("ruleset_version") == "0.0.1", "Bootstrap rules version is explicit")
	check(battlefield.get("schema_version") == 1, "Battlefield example has a version")
	check(battlefield.get("id") == "bootstrap_battlefield", "Bootstrap is not a playable mission")
	check(battlefield.get("units") == [], "Bootstrap battlefield has no units")
	var world_script: Script = require_script("res://scripts/simulation/world_state.gd")
	if world_script == null:
		return false
	var world = world_script.new()
	# JSON numbers are floats; compare numeric values, not Dictionary storage types.
	var example_grid: Dictionary = battlefield.get("grid", {})
	check(example_grid.get("width") == world.grid.width, "Example width matches live grid")
	check(example_grid.get("height") == world.grid.height, "Example height matches live grid")
	check(rules.get("default_seed") == world.snapshot()["seed"], "Example seed matches the default")
	return true


func _read_example(path: String) -> Dictionary:
	check(FileAccess.file_exists(path), "Example data exists: " + path)
	if not FileAccess.file_exists(path):
		return {}
	var parser: JSON = JSON.new()
	var result: Error = parser.parse(FileAccess.get_file_as_string(path))
	check(result == OK, "Example data is valid JSON: " + path)
	if result != OK:
		return {}
	check(parser.data is Dictionary, "Example data is an object: " + path)
	return parser.data if parser.data is Dictionary else {}
