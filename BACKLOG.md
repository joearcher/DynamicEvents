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

- **Multiple sounds per event** — `def.sound` only plays one clip at spawn today
  (`DE.EventHelpers.playSound`, called once from `EM.runSpawn`). Want a simple way
  for an event to play more than one sound together (e.g. plane-crash impact:
  engine sound + explosion), without a big API.
  *Solution sketch:* let `def.sound` accept either a single sound string (today's
  behavior) or a table of sound strings, and have `playSound` loop over the table.

- **Clear trees/destroy buildings on crash-site spawn** — the plane-crash mods
  (`DynamicEventsPlaneCrash`) only clear vehicles via `clearObstacles`/`clearRadius`
  today; the original "Plane Crash Event" mod also razes trees and buildings along
  the crash/skid path so wrecks don't spawn overlapping forest or houses.
  *Solution sketch:* add a helper alongside `DE.EventHelpers.clearVehicles` that
  walks the footprint (or just the skid line) removing `IsoTree` objects and
  optionally demolishing building squares under it; likely a new opt-in flag
  (e.g. `clearTrees` / `clearBuildings`) rather than folding into `clearObstacles`.

- **Plane-crash wreck vehicles: empty trunk + salvage.** Two related fixes for
  `DynamicEventsPlaneCrash`'s wreck vehicles (4 fuselage sections, 4 wing/engine
  pieces, A-10, 2 heli variants — 11 total):

  1. *Trunk loot never lands.* `EH.spawnVehicle`'s `partContainer(vehicle,
     "TruckBed", "Trunk")` (`DE_EventHelpers.lua`) only matches those two literal
     vanilla part IDs, but every custom wreck names its container after itself
     (e.g. `pzkPlaneSection1Trunk`), so `opts.loot` silently goes nowhere on all
     11 vehicles today.
     *Fix (framework, `DE_EventHelpers.lua`):* after the named lookups fail, fall
     back to the first vehicle part that has any item container at all —
     `vehicle:getParts()` / `getPartByIndex(i):getItemContainer()`, same pattern
     `fillVehicleVanillaLoot` already uses. No vehicle-script renames needed;
     works because the loot-trunk part is the only part with a container on any
     of these wrecks.

  2. *"Salvage the wreck" like a car wreck.* Checked vanilla: there's no bulk
     "scrap whole vehicle" action tied to mechanicType — burnt cars are just a
     differently-named vehicle script, and get salvaged via a real, already-built
     vanilla mechanic: `ISRemoveBurntVehicle.lua` (client/shared, vanilla files).
     Any vehicle whose script name contains `"Burnt"` or `"Smashed"` gets a
     **"Dismantle Car Wreck"** option added in `ISVehicleMenu.lua:616-623`
     (`FillMenuOutsideVehicle`); the action needs a blowtorch (≥10 charges), runs
     a timed action scaled by MetalWelding skill, rolls a big list of real
     vanilla scrap items (`ScrapMetal`, `SheetMetal`, `EngineParts`,
     `ElectricWire`, `NutsBolts`, `MetalBar`, etc.) onto the ground, grants
     MetalWelding XP, then `vehicle:permanentlyRemove()`s it.
     *Fix (content mod, `DynamicEventsPlaneCrash`, client-side only):* don't
     reimplement anything — wrap `ISVehicleMenu.FillMenuOutsideVehicle` (save the
     original, call it, then extend the check) so it also adds the same
     `ContextMenu_RemoveBurntVehicle` slice → `ISVehicleMenu.onRemoveBurntVehicle`
     for our `pzk*` wreck script names. Zero new items/actions/XP formulas — all
     vanilla, just widening which vehicles the existing menu option shows up on.
     Keep this as a separate salvage layer from the trunk loot: trunk = instant
     personal-effects loot (luggage etc.), blowtorch dismantle = structural
     salvage (scrap/engine parts), same split a real crash site would have.
