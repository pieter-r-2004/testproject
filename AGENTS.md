# Codex project instructions

- Read `PICK_ME_UP_AI_PROJECT_PLAN.md`, `docs/RULEBOOK.md`, and
  `docs/DECISIONS.md` before changing gameplay behavior.
- Implement only the milestone requested by the user. Milestone 0 is an empty
  12×12 arena and deterministic bootstrap, not the first complete battle.
- The user clarified that 12×12 is for a future 1v1 test only. Larger maps are
  needed for group battles; never treat 12×12 as a global game-size constraint.
- This laptop is for development and lightweight tests. AI training happens on
  separate hardware. Do not add training dependencies, weights, or datasets.
- Future heroes have individually prewritten starting identities and six
  authored backstory entries each; do not randomly generate heroes. Levels
  and stars are separate. Item-gated star promotions raise level caps up to
  6 stars / level 99 (see the cap table in decisions). Star ranks also unlock
  memories and awareness of being people used in a game; keep both separate
  from AI intelligence tiers. Withhold locked material from agents.
  See `docs/DECISIONS.md`; do not
  implement hero progression in Milestone 0.
- Keep the simulation authoritative and independent of Node/rendering, frame
  timing, wall-clock time, and global RNG. Use explicit seeded RNG per world.
- Future AI proposes actions; only the engine may validate and mutate state.
  Never execute free-form model output as code or leak private observations.
- Static definitions belong under `game/data/`; keep runtime state separate.
  Use `res://` paths and explicit script preloads so headless scripts work
  without an editor-generated global class cache.
- Use original placeholder shapes. Do not copy third-party game art or IP.
- Do not add the full Master UI, combat, pathfinding, save/load, or AI code to
  Milestone 0. Their future requirements are in the supplied plan.
- Update tests and documentation with changes. Run `./tools/test.ps1` from the
  repository root; pass `-Godot <console executable>` or set `GODOT_BIN` if needed.
  On other platforms run both commands below:

  ```text
  godot --headless --path game --script res://tests/run_tests.gd
  godot --headless --path game --script res://tests/viewer_smoke.gd
  ```

- Verify the normal entry point with
  `godot --headless --path game --quit-after 3`; visually inspect changes to
  the battlefield using the Compatibility renderer.
- Ignore `.godot/`, local tools, generated artifacts, model weights, and large
  datasets. Do not commit, push, or publish without user authorization.
- Report files changed, checks run, failures or limitations, and the exact
  next milestone task. Do not proceed to the next milestone automatically.
