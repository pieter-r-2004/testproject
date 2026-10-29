# Autonomous Heroes — Milestone 0

A small Godot 4 / GDScript bootstrap for the game described in
[`PICK_ME_UP_AI_PROJECT_PLAN.md`](PICK_ME_UP_AI_PROJECT_PLAN.md).

**The 12×12 grid is only a test arena for a future 1v1 fight.** It is not the
size limit for group battles. The simulation accepts other dimensions; larger
group maps will be defined in later milestones.

Currently the project displays an **empty** arena using colored square tiles
and coordinate labels. The side panel shows the seed and initial step index.
There are no units, turns, combat, player controls, agents, or model calls yet.
Tile colors are decorative, not terrain types.

## Setup and run

Use **Godot 4.6 or newer, standard edition** (GDScript; .NET is unnecessary).
Verified with **Godot 4.7.2 stable** on this laptop using Intel integrated
graphics. For reproducible random sequences, use the same engine version.

1. Download and extract the [official Godot editor](https://godotengine.org/download/).
2. In the Project Manager, import `game/project.godot`.
3. Open the project and press **F6** for the current scene or **F5** for the main scene.
   The main scene is `game/scenes/main.tscn`.

From the repository root, if Godot is on PATH:

```powershell
godot --editor --path game
godot --path game
```

A portable editor was downloaded for this checkout into the Git-ignored
`.tools/godot/` directory. To run that copy:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path game
```

The Compatibility renderer and simple shapes keep the viewer lightweight.
There are no third-party packages, asset downloads, or export templates needed
to edit, view, or test the project.

## Tests

From the repository root in PowerShell:

```powershell
.\tools\test.ps1
```

The wrapper finds the portable copy first, then `godot` / `godot4` on PATH.
You can override it explicitly or set `GODOT_BIN`:

```powershell
.\tools\test.ps1 -Godot 'C:\path\to\Godot_console.exe'
```

It runs two short processes with **no game window**:

- Simulation and JSON smoke tests: grid dimensions, explicit steps, same-seed
  reproducibility, seed zero, separate RNG streams, snapshot isolation, custom
  dimensions, and example-data consistency. This process never loads a scene.
- Viewer smoke test: load the actual configured main scene, check its 12×12
  simulation grid, and confirm rendering frames do not advance simulation state.

No editor import is required before these tests. Checks use explicit failure
reporting instead of debug-only `assert`; a failed or interrupted suite exits
nonzero. The wrapper also fails on logged Godot engine/script errors, even if
Godot itself exits successfully, and stops at the first failure. On Windows,
it temporarily redirects the child processes' `APPDATA` into `.tools/userdata/`
and restores the environment afterward, keeping sandbox test data local.

Equivalent direct commands on any platform with Godot on PATH:

```text
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --script res://tests/viewer_smoke.gd
godot --headless --path game --quit-after 3
```

The last command checks the normal main-scene entry point. Direct commands use
Godot's usual OS user-data directory. See the official
[command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

## Structure

```text
game/
  project.godot
  scenes/                 Main scene and empty battlefield
  scripts/
    simulation/           RefCounted grid dimensions and seeded diagnostic state
    ui/                   Static battlefield drawing and developer readout
    ai/                   Boundary note only; no agent implementation
  data/
    ruleset.json          Versioned bootstrap metadata example
    missions/             Empty 1v1 arena example; not a playable mission
  tests/
    unit/                 Deterministic simulation checks
    integration/          Example-data consistency checks
    run_tests.gd          Scene-free test entry point
    viewer_smoke.gd       Separate main-scene startup check
ai/                       Future external AI/training boundary note
docs/                     Scope, architecture decisions, and implementation plan
tools/test.ps1            Windows test convenience command
```

Data and GDScript tests deliberately live under `game/`, Godot's `res://` root.
The runtime does not load mission or character definitions yet. JSON parsing in
the smoke test only confirms the small examples are valid and consistent.

## Deterministic foundation

`WorldState` and `GridMap` extend `RefCounted`; neither needs a scene tree,
rendering, wall-clock time, network, or frame delta. Each world owns a seeded
`RandomNumberGenerator`. Only an explicit `step()` advances its counter and
returns a small `{step, sample}` diagnostic record. This is **not** a gameplay
turn or a combat/event-log implementation. `snapshot()` returns fresh value
containers; it is not a save/load protocol.

The viewer reads the world without stepping it. `WorldState.new(seed,
Vector2i(width, height))` supports larger simulation dimensions; the current
viewer layout is only for the 12×12 bootstrap arena. Dimension/schema validation,
occupancy, walls, terrain, pathfinding, and a structured event log belong to
Milestone 1.

Reproducibility is scoped to the same engine version and sequence of explicit
calls. Godot's RNG algorithm is an implementation detail, so matching results
across engine upgrades are not promised. See the
[Godot RNG documentation](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).

## This laptop and future AI work

This laptop is for development, viewing the game, and lightweight CPU tests.
**AI training will run on separate hardware.** Milestone 0 has no ML packages,
CUDA requirement, model weights, datasets, inference server, or network service.
Future AI integration must keep the engine authoritative and use an external,
replaceable provider with a deterministic fallback. The current build works
fully offline once Godot is available.

Godot cache files, `.tools/`, `.artifacts/`, model weights, and training outputs
are excluded from Git. The source repository is
[`pieter-r-2004/testproject`](https://github.com/pieter-r-2004/testproject),
with `main` as the default branch.

## Authored hero direction (future work)

Heroes will have custom prewritten starting identities and six authored
backstory entries each, rather than random generation. **Levels and stars
are separate**: item-gated star promotions raise level caps up to 6★ / level 99,
and star rank gradually unlocks memories and deeper awareness of being people
used to play a game. Maximum levels for stars 1–6 are **10, 20, 40, 60, 80, 99**.
Ordinary level effects and the exact memory unlock schedule are still
unspecified. This is recorded in
[decisions](docs/DECISIONS.md), not implemented in Milestone 0.

## Next milestone

Request **Milestone 1 only**: versioned character, ability, and mission
definitions with schema checks; character runtime state; grid occupancy,
walls, terrain costs, cardinal A* paths; seeded world state and structured
events. Add tests for invalid definitions and movement constraints, including
a larger group-battle map. Keep turns, combat, LLM code, and training out of
that task. See [the current rulebook](docs/RULEBOOK.md) and
[decisions](docs/DECISIONS.md).
