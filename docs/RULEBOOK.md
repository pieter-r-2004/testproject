# Rulebook status — Milestone 0

There are no gameplay rules implemented yet. The source design is
[`PICK_ME_UP_AI_PROJECT_PLAN.md`](../PICK_ME_UP_AI_PROJECT_PLAN.md).

The bootstrap view is an empty 12×12 square grid, intended only as a future
1v1 test arena. Larger group-battle maps will be defined later. Alternating
tile colors have no movement cost or terrain meaning. No heroes or NPCs are
spawned, and the developer does not control turns.

The simulation currently owns grid dimensions, an explicit seed, an integer
diagnostic step counter, and its private RNG. Calling `step()` returns one
seeded sample in 1–6. It is a smoke-test operation, not initiative, an attack
roll, a turn, or an action economy. The viewer never calls it.

Milestone 1 will define data validation, character state, bounds, occupancy,
terrain, cardinal movement/pathfinding, and structured events. The subsequent
milestones own turn/action rules, combat, perception, persistence, and AI.
Use the project plan for their proposed values; do not mistake those proposals
for working systems in this bootstrap.
