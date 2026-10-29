extends SceneTree
## Separate from the pure smoke test: loads the real configured main scene.

const Checks = preload("res://tests/test_suite.gd")
var suite = Checks.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	suite.check(ResourceLoader.exists(scene_path), "Configured main scene exists")
	if not ResourceLoader.exists(scene_path):
		_finish()
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	suite.check(scene != null and scene.can_instantiate(), "Configured main scene loads")
	if scene == null or not scene.can_instantiate():
		_finish()
		return
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var battlefield: Node = main.get_node_or_null("Battlefield")
	suite.check(battlefield is Node2D, "Main scene contains a 2D battlefield")
	if battlefield == null:
		_finish()
		return
	var world: Variant = battlefield.get("world")
	suite.check(world is RefCounted, "Viewer reads a simulation object")
	if world == null:
		_finish()
		return
	suite.check(world.grid.width == 12 and world.grid.height == 12, "Viewer uses the 12x12 grid")
	var before: Dictionary = world.snapshot()
	for frame in range(3):
		await process_frame
	suite.check(world.snapshot() == before, "Viewer frames do not advance the simulation")
	suite.check(before["step_index"] == 0, "Viewer starts without running gameplay")
	main.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	for failure in suite.failures:
		printerr("FAIL: " + failure)
	print("VIEWER: %d checks, %d failures" % [suite.checks, suite.failures.size()])
	quit(0 if suite.failures.is_empty() and suite.checks > 0 else 1)
