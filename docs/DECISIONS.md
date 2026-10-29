# Architecture decisions

## 2026-10-29 — Milestone 0 boundary

The supplied plan remains the design reference. This implementation stops at
repository bootstrap, an empty battlefield, example metadata, deterministic
diagnostic state, and tests. No combat, initiative, pathfinding, schema registry,
character instances, save/load, event bus, agents, or training is implemented.

The user clarified that **12×12 is only for a future 1v1 test**. Group fights
need larger maps. Core constructors accept dimensions; the current viewer
layout is for this small test arena only. Tests exercise 24×18 as an arbitrary
non-square alternative, not a chosen group-battle default.

## Authored heroes, levels, and star-gated memories — user requirements

Every hero has a custom, prewritten starting identity. Heroes must not be
randomly generated. Each has **six authored backstory entries**, revealed
gradually as the hero ranks up. A 1-star hero remembers very little; 2-star
and 3-star heroes progressively recover more, with later ranks revealing
further material. The exact unlock amounts and mapping of all six entries
to stars remain to be designed; do not invent them in Milestone 0.

**Levels and stars are separate progression values.** Stars set the level
cap, and raising star rank requires a promotion item; ordinary level gains
do not automatically grant another star. At 1 star a hero can progress
through levels 1–10 and needs an item to promote to 2 stars. The remaining
specified caps are:

| Star rank | Maximum level |
| --- | --- |
| 1 | 10 |
| 2 | 20 |
| 3 | 40 |
| 4 | 60 |
| 5 | 80 |
| 6 | 99 (absolute maximum) |

These confirmed caps supersede all earlier values and the earlier statement
that going above level 50 requires 5 stars. A 4-star hero may reach level 60;
going above level 60 requires at least 5 stars, and above 80 requires 6 stars.
Promotion item definitions, quantities, and additional conditions remain unspecified.
Do not invent them. Stat/XP effects of ordinary levels also remain to be
defined. Do not equate level, star rank, or the plan's NPC/AI intelligence tier.

Memory/backstory unlocks follow star rank. The exact amount unlocked at each
star still needs authoring; six star ranks do not by themselves define how
the six authored backstory entries are divided or revealed.

Progression also expands the hero's understanding of their own reality. This
includes awareness that they are people being used to play a game, rather
than just learning more setting lore. Preserve this as authored character
progression tied to star rank.

Future static hero definitions should hold the authored material; per-hero
runtime state should track level, stars, unlocked memories, and awareness
separately. An agent must receive only material unlocked for that hero,
alongside legitimately perceived or learned information. Locked author
knowledge must not leak into prompts or decisions. This supersedes the
original plan's suggestion of test-generated hero identities. It is recorded
for later hero/persistence work; no heroes, rank system, or memory system are
implemented in Milestone 0.

## Project/resource layout

Keep `game/` as the Godot project root and put data/tests inside it. Paths under
`res://data/` work consistently in the editor, headless scripts, and future
exports. This deliberately adapts the plan's proposed top-level `data/` and
`tests/` folders. Do not duplicate definitions in both locations. AI folders
contain boundary notes only; add real subsystems when their milestone arrives.

## Rendering and local hardware

Use the standard Godot 4 build with GDScript and the Compatibility renderer.
Verification used Godot 4.7.2 stable on Intel UHD integrated graphics; the
project declares a 4.6 baseline. Use built-in fonts and drawn colored tiles.
There are no third-party asset or test-framework dependencies.

This laptop is a development/viewing/test machine. Training and large datasets
belong on separate hardware. No GPU compute stack or model service is needed.

## Determinism and tests

Simulation objects extend `RefCounted`. Each `WorldState` owns its RNG, seeded
explicitly including zero, and changes only through explicit diagnostic steps.
Snapshots return fresh dictionaries. No simulation code depends on Nodes,
time, frame delta, input, or rendering. A future authoritative rules layer will
be added incrementally instead of letting the viewer or model mutate gameplay.

Reproducibility currently covers the same Godot build and explicit inputs.
Godot does not guarantee a stable RNG algorithm across engine versions.
Snapshots are an inspection format, not a versioned save or replay contract.

The plain SceneTree runner needs no editor import/global class cache and
never loads UI scenes. A second headless process checks actual viewer startup
and confirms frames leave simulation state unchanged. Explicit expectations
and suite completion checks report failures with nonzero exit codes. The
PowerShell wrapper additionally treats logged engine/script errors as failures:
Godot can otherwise exit zero after a scene's `_ready()` reports an error.

Windows tests redirect the child processes' `APPDATA` to ignored
`.tools/userdata/`, restoring the previous environment afterward. This avoids
sandbox writes to the user's profile. A portable Godot editor lives in ignored
`.tools/godot/`; neither engine binaries nor generated verification frames are
part of the repository sources.
