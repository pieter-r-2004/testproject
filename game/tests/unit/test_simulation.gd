extends "res://tests/test_suite.gd"
## Catches dimension drift, hidden RNG coupling, and frame-driven advancement.


func run() -> bool:
	var world_script: Script = require_script("res://scripts/simulation/world_state.gd")
	if world_script == null:
		return false
	var first = world_script.new(12345)
	check(first is RefCounted and not first is Node, "World needs no scene tree")
	check(first.grid is RefCounted and not first.grid is Node, "Grid needs no scene tree")
	check(first.grid.width == 12 and first.grid.height == 12, "Grid is exactly 12x12")
	check(first.grid.width * first.grid.height == 144, "Grid contains 144 cells")
	check(first.snapshot()["step_index"] == 0, "World starts at step zero")
	check(first.snapshot()["seed"] == 12345, "World keeps the explicit seed")
	check(first.snapshot() == first.snapshot(), "Reading a snapshot does not advance state")
	var detached_snapshot: Dictionary = first.snapshot()
	detached_snapshot["grid"]["width"] = 99
	check(first.grid.width == 12, "A snapshot cannot mutate live dimensions")

	var second = world_script.new(12345)
	var other_seed = world_script.new(98765)
	var results: Array[Dictionary] = []
	var other_results: Array[Dictionary] = []
	for index in range(32):
		var event: Dictionary = first.step()
		results.append(event)
		check(event["step"] == index + 1, "One call advances exactly one discrete step")
		check(event["sample"] >= 1 and event["sample"] <= 6, "Diagnostic sample is in 1..6")
		# Deliberately perturb the global RNG and another world's RNG between calls.
		randi()
		other_results.append(other_seed.step())
		check(event == second.step(), "Same seed reproduces an interleaved sequence")
	check(first.snapshot() == second.snapshot(), "Equal seeded steps give identical state")
	check(results != other_results, "Different seeds change the diagnostic sequence")
	check(first.snapshot()["step_index"] == 32, "Step count matches explicit calls")
	var untouched: Dictionary = second.snapshot()
	first.step()
	check(second.snapshot() == untouched, "Stepping one world does not mutate another")
	var zero_a = world_script.new(0)
	var zero_b = world_script.new(0)
	check(zero_a.snapshot()["seed"] == 0, "Zero is a valid explicit seed")
	for index in range(8):
		check(zero_a.step() == zero_b.step(), "Seed zero also reproduces its sequence")
	# 12x12 is the future 1v1 test arena, not a group-battle map size limit.
	var larger = world_script.new(12345, Vector2i(24, 18))
	check(larger.grid.width == 24 and larger.grid.height == 18, "Simulation supports larger maps")
	check(first.grid.width == 12 and first.grid.height == 12, "Custom dimensions do not change defaults")
	return true
