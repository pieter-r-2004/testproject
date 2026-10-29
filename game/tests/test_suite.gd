extends RefCounted
## Small test helper: expectations run in release builds too.

var checks: int = 0
var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func require_script(path: String) -> Script:
	check(ResourceLoader.exists(path), "Required script exists: " + path)
	if not ResourceLoader.exists(path):
		return null
	var script: Script = load(path) as Script
	check(script != null and script.can_instantiate(), "Required script compiles: " + path)
	if script == null or not script.can_instantiate():
		return null
	return script
