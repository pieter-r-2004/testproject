# Autonomous Heroes — Project Plan (v0.5)

> **Concept:** A *Pick Me Up!*-inspired prototype where heroes are autonomous individuals who can speak, plan, move, fight, remember, and form relationships. Combat takes place on a 2D square grid with a *Baldur's Gate 3*-inspired turn/action economy. The player is ultimately the **Master**, not a directly controlled combatant.
>
> **Document status:** Working design and Codex implementation guide. Names, numbers, missions, and balance values are **prototype defaults**, not fixed design laws.

## 0. Project rules for Codex

1. Implement **one small, working, testable slice at a time**. Do not attempt the full game in one pass.
2. Build and test the **deterministic simulation/rulebook before connecting any LLM**.
3. The **game engine is authoritative**. AI proposes actions; the engine validates and executes them. Never let a model directly edit HP, positions, cooldowns, inventory, or world state.
4. Keep simulation state independent of rendering, so battles can run **headlessly** for tests and training-data generation.
5. Use **data-driven** definitions (JSON or Godot Resources) for species, stats, abilities, characters, and missions. Separate static definitions from per-character runtime state.
6. Support **seeded reproducible simulations**, structured event logs, save/load, and replayable test cases.
7. Avoid committing model weights, huge datasets, or generated assets. Build a provider-agnostic AI adapter with a deterministic fallback.
8. AI input must contain **only knowledge available to that character** through perception, memory, or communication.
9. Only ask Codex to proceed to the next milestone after the current milestone's tests pass.
10. Keep the **full Master interface out of scope** for now. Minimal developer controls are allowed.

## 1. Scope and design pillars

### Prototype target

- **Engine:** Godot 4.x, GDScript, 2D square grid. Start with placeholder sprites/colored tiles; potentially switch to 2.5D/isometric presentation later.
- **Heroes:** 20–25 persistent, summonable/test-generated hero records; deploy up to **five** on an active mission.
- **Missions:** 10 fixed, handcrafted maps/scenarios (not procedurally generated).
- **Combat:** Turn-based initiative, grid movement, actions, bonus actions, reactions, movement abilities, cooldowns, statuses, and victory/defeat objectives.
- **Autonomy:** Heroes decide for themselves. The developer can choose a squad and start a mission but does **not** directly control individual turns in the normal simulation.
- **NPCs:** The same fundamental character and combat rules as heroes, but with intelligence tiers and species-specific abilities.
- **Unified AI experiment:** One **shared, small language-action model** can output **both** legal game-action choices and speech; character identity, temperament, relationship data, and memory are stored independently.
- **Communication:** Sight, hearing radius/attenuation, walls/doors, speech volume, language comprehension, and information propagation.
- **Persistence:** Injuries, health, experience, relationships, abilities, traits, and memorable events persist between missions.
- **Hardware:** Aim for a consumer PC, approximately 16 GB system RAM; a 6–8 GB GPU is a preferred target, not a strict requirement. CPU fallback is allowed with longer AI turns.

### Non-goals for the initial version

- Full Master UI (summoning menus, polished party UI, equipment screens, shop, etc.) — **future note only**.
- Multiplayer/networking, procedural missions, advanced 2.5D/3D art, voice synthesis, large open world, hundreds of simultaneously reasoning LLM agents.
- Training a foundation model from scratch.
- Free-form invented abilities or arbitrary movement coordinates outside the rulebook.
- Expecting sophisticated emergent social behavior from the earliest prototype.

## 2. High-level architecture

```text
+-------------------------------+
| 2D Godot viewer + debug tools |
+---------------+---------------+
                |
+---------------v---------------+
| Deterministic Simulation Core |
| World / grid / turns / events |
+--+-----------+-----------+----+
   |           |           |
+--v----+ +----v------+ +--v------------------+
|Rules  | |Perception| |Character persistence |
|Engine | |& Hearing | |Memory / relationships|
+--+----+ +----+------+ +--+------------------+
   |           |           |
   +-----------+-----------+
               |
+--------------v----------------+
| Agent Controller              |
| - Tier 0-1 rules/utility AI   |
| - Tier 2-4 shared LLM adapter |
| - legality filtering/fallback |
+--------------+----------------+
               |
+--------------v----------------+
| Local model server (optional) |
| llama.cpp-compatible HTTP API |
+-------------------------------+
```

**Key decision:** Even with a *unified language-action model*, actual movement execution stays in Godot. The model picks a **destination/path intention** and may speak in the same decision; the engine handles A* paths, terrain costs, occupancy, attack-of-opportunity triggers, and animations.

### Recommended project layout

```text
repo/
  README.md
  AGENTS.md                         # Codex rules and local run/test commands
  PROJECT_PLAN.md                   # this file
  game/
    project.godot
    scenes/
      main.tscn
      battlefield.tscn
    scripts/
      simulation/
        world_state.gd
        grid_map.gd
        turn_manager.gd
        action_validator.gd
        action_executor.gd
        event_bus.gd
        perception_system.gd
        hearing_system.gd
        character_state.gd
        save_manager.gd
      ai/
        agent_controller.gd
        scripted_agent.gd
        model_agent.gd
        model_client.gd
      ui/
        debug_panel.gd
        combat_view.gd
  data/
    ruleset.json
    abilities.json
    species.json
    character_templates.json
    missions/
      mission_01.json ... mission_10.json
  ai/
    prompts/
    schema/
    training/                       # scripts and small examples, not model weights
    evaluation/
  tests/
    unit/
    integration/
    scenarios/
  docs/
    RULEBOOK.md
    AI_PROTOCOL.md
    DECISIONS.md
```

Paths are a proposal; keep them consistent and simple rather than forcing every empty folder to exist immediately.

## 3. Universal rulebook and statistics

Each **hero and NPC** has a unique ID, species, role/class, faction, intelligence tier, stats, known abilities, resources, statuses, current position, goals, memory references, relationships, and perception profile.

### Stat groups

| Category | Example fields | Scale / meaning |
|---|---|---|
| Resources | `hp`, `max_hp`, `stamina`, `max_stamina`, `mana`, `max_mana` | 0 through character-specific maximum (bosses may have thousands of HP) |
| Attributes | `strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`, `charisma` | Start with 1–30; data-driven ranges |
| Combat | `armor`, `accuracy`, `initiative`, `movement_tiles`, `attack_power` | Rule-specific numbers |
| Psychological state | `fear`, `stress`, `morale`, `fatigue` | 0–100; dynamic |
| Personality | `courage`, `discipline`, `empathy`, `aggression`, `sociability` | 0–100; comparatively stable |
| Social relationships | per-target `trust`, `affinity`, `respect` | 0–100 (start neutral at 50) |
| Senses | `sight_range`, `hearing_sensitivity`, `known_languages` | Grid tiles / modifiers / list |
| Progression | `level`, `experience`, `skill_proficiency`, `injuries` | Persistent |
| Cognition | `intelligence_tier`, `goals`, `known_facts` | Controls agent implementation and available information |

**Clarification:** `fear: 1/100` and `health: 1/4534` represent very different systems. Fear is a normalized psychological state; HP has a character-specific maximum. Do not clamp every stat to 100.

### Suggested intelligence tiers

| Tier | Behavior | Example |
|---|---|---|
| 0 | Scripted / swarm controller; no LLM | Slimes, insects |
| 1 | Utility AI + simple signals / pack behavior | Wolves, basic monsters |
| 2 | Simple planning; **optional** small-model language call | Common goblins |
| 3 | Human-like planning, conversation and memory | Heroes, bandits, villagers |
| 4 | Larger context/planning budget; same model initially | Hero captains, intelligent bosses |

Intelligence tier governs agent *capabilities and inference budget*, not species worth or combat strength. Special individuals can use higher tiers than their species default. All tiers still follow the same world rules.

### Sample character instance

```json
{
  "id": "hero_mira_001",
  "name": "Mira",
  "faction": "heroes",
  "species_id": "human",
  "class_id": "warrior",
  "level": 4,
  "intelligence_tier": 3,
  "stats": {
    "hp": 115, "max_hp": 140,
    "stamina": 72, "max_stamina": 100,
    "mana": 12, "max_mana": 30,
    "strength": 14, "dexterity": 11, "constitution": 16,
    "intelligence": 13, "wisdom": 10, "charisma": 12,
    "fear": 25, "morale": 85, "stress": 18,
    "courage": 78, "discipline": 76,
    "movement_tiles": 6, "sight_range": 7,
    "hearing_sensitivity": 65
  },
  "languages": ["common"],
  "ability_ids": ["basic_slash", "shield_bash", "dash", "jump", "disengage", "shove"],
  "ability_cooldowns": {"shield_bash": 0},
  "personality_tags": ["protective", "stubborn"],
  "goals": ["protect_party", "become_leader"],
  "relationships": {"hero_arin_002": {"trust": 85, "affinity": 70}},
  "memory_event_ids": ["ev_103", "ev_145"]
}
```

Static base stats, class modifiers, and ability definitions should live in separate records. The instance contains only its overrides and persistent/dynamic state when practical.

## 4. Turn-based grid and action economy

We take inspiration from BG3 but define our **own explicit rules** for predictable training and testing.

### Basic turn defaults

- Square grid; **4-direction cardinal movement** initially; no diagonals in v0.1.
- **Initiative order:** deterministic from stats + a seeded random roll, calculated at battle start; tie-break by stable entity ID.
- **Per turn:** 1 Action, 1 Bonus Action, 6 movement points for a normal human, plus 1 Reaction available until its next turn. These are **not** interchangeable.
- Movement may be split around actions (move → attack → move), provided enough points remain.
- Ordinary tile cost = 1 movement point; difficult terrain = 2; walls and occupied tiles block movement unless an ability expressly allows otherwise.
- Abilities may have cooldowns measured in **the acting character's turns**, separate from action costs.
- **Short speech:** up to one meaningful utterance per character turn for v0.1, free of AP but subject to hearing and language rules. Reactions or scripted battle calls may create separate event-limited speech.
- **Opportunity attack:** if a unit leaves an adjacent enemy's threatened tile without Disengage, an eligible enemy may use its Reaction for one legal melee attack. Implement after basic movement works.
- **Status handling:** stun, prone, fear/panic, buffs, injuries; add gradually, not simultaneously.
- At 0 HP: incapacitated; death/permadeath policy remains a configurable testing rule.

### Movement-related abilities (prototype definitions)

| Ability | Cost | Effect | Cooldown |
|---|---|---|---|
| **Walk** | Movement points | Follow legal grid path; may split movement | None |
| **Dash** | 1 Action | Gain additional movement equal to base movement for this turn | None |
| **Jump** | 1 Bonus Action + 2 movement points | Cross a legal short gap/obstacle; distance derived from Strength | None |
| **Disengage** | 1 Action | Moving out of enemy reach does not trigger opportunity attacks for the rest of this turn | None |
| **Shove** | 1 Bonus Action | Contested push of an adjacent unit into a legal tile | None |
| **Basic Attack** | 1 Action | Species/class weapon attack | None |
| **Shield Bash** | 1 Action | Adjacent attack + short stun when successful | 2 own turns |

These are **BG3-inspired prototype values**, not a commitment to identical game mechanics. Jump and Shove need dedicated rulebook validators and must not bypass map boundaries or occupied cells.

### Fixed mission action budgets

The user also wants a **set amount of actions on missions**. Keep this separate from movement points and per-turn AP:

- Each mission has `max_rounds` (default **20** for initial testing).
- A mission may enable `mission_action_budget_per_unit` (initial **30**). This is a cross-mission cap on **spent Actions and Bonus Actions**, not an extra charge per walked tile.
- A standard action or bonus action that is actually performed counts as **one mission action**. Reactions and free short speech do not count; ordinary walking uses movement points only.
- A unit with no mission actions remaining may still end its turn, walk using normal movement (unless mission rules say otherwise), and receive passive effects. It cannot voluntarily spend Actions or Bonus Actions.
- Log every budget expenditure. Both the per-unit budget and round limit must be data-driven and can be disabled in a mission.

This is a **prototype testing mechanic**; adjust after observing whether it adds strategy or simply slows exploration.

### Rulebook validation sequence

1. Confirm actor exists, is alive/able to act, and it is their turn.
2. Check requested action type, ownership/unlocked ability, resource costs, cooldown, and mission budget.
3. Validate path, occupancy, map bounds, range, line of sight, target visibility/knowledge, and status restrictions.
4. Spend resources **only on accepted actions** (or on explicitly defined failed attempts like contested Shove).
5. Resolve effect using seeded RNG and emit world events.
6. Apply triggered reactions, status updates, death checks and victory/defeat conditions.
7. Append a structured event to the log; deliver perceived events to relevant agents.

## 5. Ability definitions

All abilities come from a **registry**, not a language model. The AI may select or sequence only listed legal abilities.

```json
{
  "id": "shield_bash",
  "name": "Shield Bash",
  "action_cost": "action",
  "movement_cost": 0,
  "stamina_cost": 10,
  "cooldown_own_turns": 2,
  "range_tiles": 1,
  "targeting": "visible_enemy",
  "requires_line_of_sight": true,
  "effects": [
    {"type": "physical_damage", "amount": 5},
    {"type": "apply_status", "status": "stunned", "duration_target_turns": 1}
  ]
}
```

In later versions, proficiency, damage rolls, criticals, resistances, class abilities, equipment bonuses and environment interactions can be layered onto these definitions.

## 6. Perception, hearing, language and knowledge

**Non-negotiable rule:** AI prompts must never include omniscient world state.

### Sight

- Compute visible tiles using range and wall/obstacle occlusion; begin with a simple line-of-sight algorithm.
- Only return visible units and objects in the agent's current `observation`.
- Remember previously observed positions as **last known** positions, with timestamps; do not silently update unseen positions.

### Hearing

- Speech events store `speaker_id`, **speaker position at the instant of speech**, text, language, volume (`whisper`, `normal`, `shout`), and turn/event index.
- Start with **tile-distance thresholds + wall/closed-door attenuation**. Later, use flood-fill acoustic propagation if needed.
- Per-character hearing sensitivity can shift the threshold; environmental noise reduces clarity.
- Hearing a voice is distinct from understanding its words. A listener without the language may receive `unrecognized speech nearby` instead of the text.
- Characters outside effective hearing range receive **no event or transcript**. There must be no hidden leakage from debug UI to agent context.
- Only in-range listeners receive the event, optionally as a partial/uncertain observation if muffled.

### Knowledge/memory

- Every perceived event has a source and timestamp; maintain a small `known_facts` store and a separate episodic memory log.
- A hero may learn a fact through sight, hearing, being told, or remembered events. Rumors can have confidence levels.
- Memory retrieval for the model: prioritize recent events and goal-/relationship-relevant facts, not unlimited history.
- The model may *propose* sharing a fact through speech; the hearing system actually determines recipients.

### Example hearing acceptance test

One hero whispers behind a closed door. Another hero nearby hears it; a guard on the other side of the wall does not understand or receive the transcript. Change the speech volume to shout: the guard may hear a warning, subject to attenuation and known languages. Verify the guard's AI prompt contains **only** what it perceived.

## 7. Unified language–action AI

### What unified means here

One shared neural model consumes **character observation + traits + memories + legal action choices** and produces a **structured action/utterance decision**. It learns correlations between movement, combat intentions, and dialogue.

It is **not** a model that moves sprites every frame. Grid movement is discrete and the authoritative engine executes paths.

### Agent interface

```text
observe(character_id, world) -> private_observation
list_legal_actions(character_id, private_observation) -> legal_actions
choose_action(private_observation, legal_actions, memory) -> action_proposal
validate_and_execute(action_proposal) -> events + new_state
```

Start with **one atomic action proposal** at a time rather than trusting a long batch of commands: a movement step can trigger opportunity attacks or reveal an enemy, invalidating the rest of a predicted plan. Permit a higher-level `intent` field and a bounded number of follow-up decisions in the same turn.

### Sample private model request

```json
{
  "actor_id": "hero_mira_001",
  "turn_index": 8,
  "current_goal": "protect_ally",
  "personality": {"courage": 78, "discipline": 76, "fear": 25},
  "position": [2, 4],
  "resources": {"hp": 115, "max_hp": 140, "movement_remaining": 6, "action": 1, "bonus": 1, "reaction": 1, "mission_actions_remaining": 23},
  "visible_units": [
    {"id": "ally_02", "position": [2, 5], "status": "wounded"},
    {"id": "goblin_03", "position": [4, 4], "status": "healthy"}
  ],
  "heard_recently": [{"speaker": "ally_02", "text": "Help me!"}],
  "relevant_memories": ["ally_02 saved my life on mission 2"],
  "legal_actions": [
    {"id": "move_3_4", "type": "move", "destination": [3, 4]},
    {"id": "dash", "type": "ability", "ability_id": "dash"},
    {"id": "end_turn", "type": "end_turn"}
  ]
}
```

### Sample model response

```json
{
  "action_id": "move_3_4",
  "intent": "block_enemy_approach_to_ally",
  "speech": {
    "text": "Stay behind me!",
    "volume": "shout",
    "language": "common"
  }
}
```

**Rules:** `action_id` must match exactly one enumerated legal action. Speech must obey limits and allowed languages. Model `intent` is explanatory metadata, not game authority. The engine performs one legal action, generates a speech event if permitted, then updates state. Untrusted model output is never executed as code.

### Initial inference stack

- Implement `AgentController` interface with `ScriptedAgent`, `RandomLegalAgent`, and `ModelAgent` implementations.
- First model experiment: a **small 0.5B–1.5B instruction model**, quantized for local inference; exact model remains swappable.
- Run a local llama.cpp-compatible HTTP server or another interchangeable local model host.
- Prefer schema-constrained JSON output, but **still perform game-engine validation**; syntactically valid JSON can describe an invalid action.
- Turn decisions are queued, prioritized for active agents; don't keep 25 independent model instances in memory.
- Set a configurable timeout, token cap, and max **1–3 model decisions per turn**. On failure/timeout, choose a valid deterministic fallback (`end_turn`, `defend`, or best scripted action).
- Scripted agents must always work even with the model server completely offline.

### NPC usage

- Tier 0–1: no LLM, only rule/utility behavior.
- Tier 2: LLM only for meaningful communication or complex decisions; otherwise lightweight policies.
- Tier 3–4: shared model for important decisions and dialogue; higher tiers get more context/decision budget.
- **Not every character needs an LLM call every round**. Only active intelligent agents in consequential situations do.

## 8. How to train it (later, not on day one)

Training from scratch is out of scope. First prove the rulebook and agent contract with a scripted baseline.

1. **Generate legal-action examples** from deterministic planners, scripted tactics, and seeded simulations: navigation, threatened tiles, Dash/Jump/Disengage/Shove, target priorities.
2. **Capture action-plus-speech examples**, including hearing constraints, species languages, objectives, fear, relationships and memories.
3. Record tuples: `observation`, `legal_actions`, `selected_action_id`, `speech`, `outcome`, `seed`, `ruleset_version`.
4. Begin with **supervised fine-tuning (LoRA/QLoRA)** only after prompt-only performance is measured and the dataset is validated. A small proof-of-concept dataset is better than tens of thousands of inconsistent labels.
5. Hold out **entire maps and scenario variations** for evaluation to test generalization.
6. Compare against `ScriptedAgent`, `RandomLegalAgent`, and **prompt-only ModelAgent**. Don't claim the model is better unless the metrics show it.
7. Use failure cases for targeted data collection, then retrain/evaluate. Reinforcement learning is a **later experiment**, not a dependency for the prototype.

### Measurable AI evaluation

- JSON parse rate, valid-action proposal rate, fallback frequency, time per decision, tokens per decision.
- Mission success rate and damage taken relative to scripted baseline.
- Turns/action budget spent per objective.
- Rate of illegal/unreachable move proposals.
- Personality contrast: do different hero profiles choose observably different actions in comparable scenarios?
- Knowledge isolation: can an agent react to an unheard conversation or unseen enemy? **Must be zero leakage in tests.**
- Speech/action coherence: warnings and utterances match the actual selected intent/action.

## 9. Ten fixed missions

Build **one** mission completely before authoring the rest. Each mission is a data definition containing a grid, terrain, spawn points, objectives, round limits, optional mission action budgets, and scripted event hooks.

| # | Mission | Objective | Main test |
|---|---|---|---|
| 01 | First Encounter | Defeat 3 weak enemies | Turns, attacks, basic movement |
| 02 | The Crossroads | Reach an exit through obstacles | Navigation, terrain, Dash and Jump |
| 03 | Wounded Ally | Extract an injured friendly NPC | Protecting allies, movement priorities |
| 04 | Ambush | Survive or escape an ambush | Perception, initiative, Disengage |
| 05 | Village Defense | Prevent enemies reaching civilians | Defensive positioning, target choices |
| 06 | Lost Expedition | Retrieve an artifact and escape | Exploration, persistent knowledge |
| 07 | Supply Crisis | Retrieve limited supplies | Mission budgets, risk vs. reward |
| 08 | The Commander | Defeat coordinated enemies | Intelligent NPC tactics and hearing |
| 09 | No One Left Behind | Evacuate a wounded hero | Team coordination, fear, memory |
| 10 | Final Trial | Win a multi-phase boss battle | Cooldowns, planning, adaptation |

Keep environments small, reuse art, and make special mechanics opt-in. Missions can be added as data after the underlying engine is stable.

## 10. Implementation milestones for Codex

### Milestone 0 — Repository bootstrap

**Tasks:** Create Godot project, folders, README/AGENTS.md, empty battlefield scene, example data, and a minimal headless smoke test.

**Done when:** Project starts, displays a grid, and a headless command can run a simple deterministic test without opening the full UI.

### Milestone 1 — Rulebook, character records, and grid

**Tasks:** Parse character/ability/mission JSON; validate schemas; create grid occupancy, walls, terrain costs, and A* pathfinding; implement seeded world state and event log.

**Done when:** Tests catch out-of-bounds movement, blocked tiles, invalid stats, duplicate IDs, missing abilities, and movement over budget. Seeded simulations are reproducible.

### Milestone 2 — Turn engine and movement abilities

**Tasks:** Initiative, Action/Bonus/Reaction, movement points, Walk, Dash, Jump, Disengage, Shove, action-cost spending, cooldowns, opportunity attacks, optional mission action budget and round limit.

**Done when:** Move–attack–move works; Dash does not grant a free Action; Shove cannot push into blocked tiles; Disengage prevents eligible opportunity attacks; cooldowns tick consistently.

### Milestone 3 — Combat and objectives

**Tasks:** Basic attacks, damage, HP/death/incapacitation, two or three combat abilities, minimal statuses, victory/defeat, Mission 01, scripted AI.

**Done when:** Two scripted parties can complete Mission 01 headlessly and in the 2D viewer, with a full event log and no illegal state transitions.

### Milestone 4 — Perception and communication

**Tasks:** Vision/LOS, speech event propagation, whisper/normal/shout, walls/doors, languages, last-known positions, private observation construction.

**Done when:** Agents cannot target unseen enemies using fresh information, nor react to speech they cannot hear/understand. Debug logs show recipients without giving transcripts to unintended agents.

### Milestone 5 — Hero minds and persistence

**Tasks:** Character goals, fear/morale/stress updates, relationship effects, episodic event memories, save/load with versioning, five hero archetypes, 20–25 persistent hero records.

**Done when:** Stat changes influence scripted choices and survive save/reload. Memory references remain stable across missions. The system can load 25 heroes without deploying them all.

### Milestone 6 — Unified model adapter

**Tasks:** Implement local model HTTP client, private observation serializer, legal action enumerator, structured model response parser, strict validation, timeout/retry/fallback, speech+action event integration.

**Done when:** A model-controlled hero can complete Mission 01 with legal movement and optional spoken dialogue. Disconnecting the model causes fallback behavior rather than a stalled game.

### Milestone 7 — NPC intelligence tiers

**Tasks:** Swarm controller, animal utility agent, Tier 2 goblin controller, Tier 3 intelligent opponent, command/hearing responses, shared model call scheduler.

**Done when:** Goblins can coordinate only when their messages are perceived; slimes function without an LLM; all NPCs share base combat and stats systems.

### Milestone 8 — Remaining nine missions and progression

**Tasks:** Implement Missions 02–10 as data/scenarios. Add XP, training, injuries, relationship changes, class abilities, mission results and persistent consequences.

**Done when:** All 10 missions are loadable, have objective-driven outcomes, and run with scripted agents end-to-end. Model agents may replace scripted ones without changing mission data.

### Milestone 9 — Unified model fine-tuning and optimization

**Tasks:** Export validated demonstrations, train a small LoRA adapter, measure quality vs. baseline, quantize/test the result, add inference scheduling and performance instrumentation.

**Done when:** There are repeatable performance benchmarks for the target consumer PC, plus documented measurements of decision speed, mission success, legality and dialogue coherence. If fine-tuning harms results, keep the prompt-only baseline.

### Milestone 10 — Prototype polish (not Master UI)

**Tasks:** Clear animations, debug inspector, pause/step/fast-forward, simulation replay, logs, basic test mission selector, user-facing setup instructions.

**Done when:** Someone can run a local demo, watch a five-hero party act autonomously, hear/see dialogue, inspect stats and finish a mission without manually driving hero turns.

## 11. First vertical slice (build this before the full plan)

**Single map:** 12×12, walls and two kinds of terrain.

**Units:** Two autonomous heroes versus two goblins; only one hero uses the model initially.

**Features:** Seeded initiative, Action/Bonus/Reaction, 6-tile movement, Dash, Basic Attack, one cooldown ability, sight, short speech/hearing, legal-action list, event log, end-turn, victory/defeat.

**Out of scope for this slice:** Jump physics, full Shove contest, save-game UI, 25 live agents, advanced social memory, fine-tuning, fancy sprites, 10 missions.

**Success:** Watch an entire match run from start to finish, see each character select legal actions, observe speech only when its recipients can hear it, and reproduce the same scripted match using a fixed seed.

## 12. Testing checklist

- [ ] Save/load maintains HP, cooldowns, inventory references, stats, and memory IDs.
- [ ] AI output cannot teleport, invent an ability, alter its own health, or bypass AP/movement costs.
- [ ] Moving away from a threat triggers at most one valid Reaction per eligible defender; Disengage avoids it.
- [ ] Jump cannot land off-map, on occupied tiles, or beyond allowed reach.
- [ ] Round limits and mission action budgets end or restrict battles correctly.
- [ ] Unseen entities and unheard/private conversations are not included in agent observations.
- [ ] Foreign-language speech doesn't reveal full text to a character that cannot understand it.
- [ ] Model timeout, malformed JSON, or illegal proposals produce deterministic legal fallback.
- [ ] Every random roll is seedable and logged; replay produces the same **simulation decisions** with deterministic agents.
- [ ] Twenty-five persistent heroes load successfully; active battles remain bounded to a small party.
- [ ] Ten missions load and can be completed/failed with scripted agents.
- [ ] Runtime diagnostics report per-decision latency, call count, fallback rate and token usage when available.

## 13. Technical risks and mitigations

| Risk | Mitigation |
|---|---|
| Small model is bad at tactics | Keep the legal-action list small, use scripted baseline, measure before fine-tuning |
| LLM inference is too slow | One shared local model, active-agent scheduling, event-triggered calls, timeout and legal fallback |
| LLM invents powers | Static ability registry + strict action ID validation |
| NPCs become omniscient | Private observations, hearing/vision isolation unit tests, no direct world-state access in AI adapter |
| Action budgets make exploration frustrating | Keep ordinary movement outside mission action budget; configure per mission; track data |
| Hero identities feel identical | Store persistent traits, memories, goals and relationships; test paired scenarios |
| Training dataset just imitates bad rules | Record outcomes, inspect labels, hold out scenarios; benchmark against scripted baseline |
| Rendering and AI changes break each other | Headless deterministic simulation with clean UI/model adapters |
| Model output varies across runs | Log raw decisions, parsed actions, seed, model/version; deterministic replay uses recorded actions |
| Scope becomes too big | Do not move to the next milestone until acceptance checks pass; defer Master UI |

## 14. Decisions still adjustable

- Exact stat formulas and dice/randomness system.
- Whether diagonal movement is introduced later; v0.1 uses four-direction movement.
- How often model agents can speak during reactions and outside combat.
- Permanent death on/off for development builds.
- Specific local model family, quantization and inference host.
- Which agent tiers receive full LLM vs. low-cost scripted output in each situation.
- Whether the per-unit mission action budget remains after testing.

Store such choices in `docs/DECISIONS.md` rather than silently changing architecture.

## 15. Codex operating instructions

**Suggested `AGENTS.md` content:**

```md
# Codex project instructions
- Read PROJECT_PLAN.md and docs/RULEBOOK.md before changing gameplay behavior.
- Treat the game simulation as authoritative. Never execute free-form model output as code.
- Keep all actions data-driven and run through a single validator/executor.
- Preserve deterministic seeded tests and strict information isolation between agents.
- Do not implement the full Master UI unless explicitly requested.
- Work on only the requested milestone, adding tests and updating docs for rule changes.
- Use placeholder art. Do not copy artwork, characters, dialogue, or game assets from existing IP.
- After each task, report files changed, tests run, failures, and next suggested step.
```

### Copy/paste: First task to give Codex

> Read `PROJECT_PLAN.md`. Implement **Milestone 0 only**: create a minimal Godot 4.x project, a visible 12×12 square-grid debug battlefield using placeholder shapes, repository structure, `README.md`, `AGENTS.md`, and a headless deterministic smoke test. Do not add an LLM, full Master UI, combat, procedural missions, or advanced graphics. Run available checks, fix errors, and report what works and the exact next task for Milestone 1.

### Subsequent Codex requests

- **Task 2:** “Implement Milestone 1 only: versioned data definitions, character state and grid rules. Add tests. Don't add LLM code.”
- **Task 3:** “Implement Milestone 2 only: turn manager, movement points, Dash, Jump, Disengage, Shove, Action/Bonus/Reaction and limits. Add deterministic tests.”
- **Task 4:** “Implement Milestone 3 only: simple combat, fixed Mission 01, legal scripted agents and end-to-end headless battles.”
- **Task 5:** “Implement Milestone 4 only: vision, hearing, languages and per-agent private observations. Prove no knowledge leaks with tests.”
- **Task 6:** “Implement Milestones 5–6 separately, testing hero persistence first and local model adapter second.”

## Reference links

- Godot AStarGrid2D documentation: https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html
- llama.cpp local server and constrained JSON documentation: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md

---

**Guiding principle:** The simulation enforces the rules; the AI makes choices within them. Heroes have their own private histories and goals, while the Master observes their decisions and consequences.
