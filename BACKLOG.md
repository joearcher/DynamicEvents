# Backlog

Loose ideas and open questions. Not ordered, not commitments.

- **Delayed spawn steps** — let one event stagger its own spawns over time
  (e.g. plane crash now, wandering horde drifts in 2h later). Simpler than separate
  chained events; reserve a standalone event only when the follow-up needs its own
  lifetime/radio/clear.
  *Solution:* `e:After(delaySeconds, fn)` on the context — can't block in PZ Lua, so
  it queues a deferred callback the scheduler runs on the upkeep pass, on the same
  `e` (same uid/tags/cleanup). Caveats: pending steps are lost on restart (like
  `_pendingSpawns` today); re-sync the event's radius after a step that reaches out.

- **On-spawn notifications** — overhead text when an event spawns, globally or to
  nearby players only. Optional per event (like `radio`).
  *Solution:* hook `EM.runSpawn`; pick players via `getOnlinePlayers()` + distance
  filter; show with `HaloTextHelper`/`player:Say` (server → client command in MP).

- **Attract unloaded hordes?** — open question: can a horde drift toward a point
  while its chunk is unloaded? `DE.attractZombies` only re-paths loaded zombies.
  *Solution to try:* test the vanilla world-sound/meta-migration API for an
  unloaded attraction source; else fall back to today's park-then-attract-on-load.
