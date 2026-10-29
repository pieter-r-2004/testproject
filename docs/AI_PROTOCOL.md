# AI protocol status — deferred

No AI protocol, agent implementation, or model server is connected in
Milestone 0. This file records the boundary for future work only.

The intended model contract is private observation plus enumerated legal
actions in, structured action/speech proposal out. The engine remains the
authority: it validates proposals and applies all state changes. Future
agents must receive only perceived information, and a deterministic fallback
must work while the model provider is offline.

See sections 6–8 of
[`PICK_ME_UP_AI_PROJECT_PLAN.md`](../PICK_ME_UP_AI_PROJECT_PLAN.md) for the
proposed contract. Agent plumbing and inference belong to later milestones.
Any training, fine-tuning, or large dataset work will run on separate hardware,
not this development laptop.
