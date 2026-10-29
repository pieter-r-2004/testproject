extends SceneTree
## Invoke directly with --headless --path game --script res://tests/run_tests.gd.
## This runner never instantiates the battlefield or the main scene.

const SUITES: Array[String] = [
	"res://tests/unit/test_simulation.gd",
	"res://tests/integration/test_bootstrap.gd",
]


func _initialize() -> void:
	var total_checks: int = 0
	var total_failures: int = 0
	for path in SUITES:
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("FAIL: Cannot load test suite: " + path)
			total_failures += 1
			continue
		var suite = script.new()
		var completed: Variant = suite.run()
		total_checks += suite.checks
		if completed != true:
			printerr("FAIL: Suite did not complete: " + path)
			total_failures += 1
		for failure in suite.failures:
			printerr("FAIL: " + failure)
			total_failures += 1
		if completed == true and suite.failures.is_empty():
			print("PASS: %s (%d checks)" % [path, suite.checks])
	print("RESULT: %d checks, %d failures" % [total_checks, total_failures])
	quit(0 if total_failures == 0 and total_checks > 0 else 1)
