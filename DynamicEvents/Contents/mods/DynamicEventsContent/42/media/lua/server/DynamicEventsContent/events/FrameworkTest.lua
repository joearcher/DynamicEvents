DE = DE or {}

-- ============================================================================
-- Exercises every piece of the event definition + spawn-context API in one
-- event, for manual testing (spawn it, poke around, clear it, check nothing
-- was left behind except what's explicitly marked permanent/world-owned).
-- Off by default; enable the sandbox option, then:
--   DE.SpawnHere("framework_test")   -- spawn at your position
--   DE.ListEvents()                  -- find its uid
--   DE.GoTo(uid)                     -- jump back to it
--   DE.ClearEvent(uid)               -- clear and verify cleanup
-- cooldownHours = 0 so you can immediately re-trigger it after clearing.
-- ============================================================================

local manualLoot = {
    "Base.Pistol", "Base.9mmClip", "Base.Bandage", "Base.FirstAidKit",
}

local crateLoot = {
    "Base.Screwdriver", "Base.Wrench", "Base.Hammer", "Base.Saw",
}

local EVENT = {
    id              = "framework_test",
    name            = "Framework Test Event",
    enabledVar      = "DynamicEventsContent.FrameworkTest",
    weight          = 10,
    cooldownHours   = 0,
    minDaysSurvived = 0,

    -- Clear vehicles from the footprint instead of skipping the location.
    clearObstacles  = true,
    clearRadius     = 15,

    -- Short warning so testing doesn't mean sitting around.
    warning         = { delay = 5 },

    sound           = "MetaShotgun1",

    -- Auto-clears itself quickly so you can also test that path without
    -- calling DE.ClearEvent by hand; lower/raise to taste.
    lifetimeHours   = 0.1,

    -- Non-default, to check it's actually read (default is 20).
    zombieCleanupRadius = 30,

    -- dependencies = { "SomeModID" },  -- would skip this location if not loaded

    locations = {
        { name = "Test Site North", x = 10000, y = 10000, z = 0, rot = 0  },
        { name = "Test Site East",  x = 10600, y = 10200, z = 0, rot = 90 },
    },

    radio = {
        frequency = 104200,
        interval  = 60,
        range     = 300,
        messages  = {
            "Test broadcast from {name}, coordinates {x},{y}.",
            "%s reporting in.",   -- legacy placeholder, resolves to "name (x, y)"
        },
    },

    spawn = function(x, y, z, e)
        -- SpawnVehicle: wrecked with a hand-picked loot list, plus a drivable
        -- one with vanilla loot and a specific skin.
        e:SpawnVehicle("Base.PickUpTruck_Camo", -6, -6, {
            rot  = e.rot + DE.rand(-10, 10),
            loot = manualLoot,
        })
        e:SpawnVehicle("Base.PickUpTruck_Camo", 6, -6, {
            rot     = e.rot,
            skin    = 1,
            working = true,
            loot    = "vanilla",
        })

        -- SpawnZombies: tracked, removed by clear. Uses DE.Outfits-listed names.
        e:SpawnZombies(5, 0, 0, { outfit = "ArmyCamoGreen", spread = 6 })

        -- SpawnHorde: world-owned, untracked — should survive DE.ClearEvent.
        e:SpawnHorde(5, 0, 10, { outfit = "Police", spread = 10 })

        -- SpawnItem: plain, then one with name/note/permanent (should survive
        -- clear since it's tagged permanent instead of the event uid).
        e:SpawnItem("Base.Crowbar", 2, 2)
        e:SpawnItem("Base.Note", -2, 2, {
            name      = "Test Note",
            note      = "This item is permanent and should survive DE.ClearEvent.",
            permanent = true,
        })

        -- SpawnLoot: scattered ground loot with chance/spread.
        e:SpawnLoot({ "Base.Rock", "Base.Twigs", "Base.Plank" }, 0, -3, {
            spread = 4, chance = 50,
        })

        -- SpawnContainer: hand-picked list, then a vanilla loot distribution.
        e:SpawnContainer("Base.Bag_Military", crateLoot, 3, 0, { chance = 100 })
        e:SpawnContainer("Base.Mov_MilitaryCrate", { distribution = "ArmyStorageGuns" }, -3, 0)

        -- Fire/smoke.
        e:SpawnFire(2, 0, 4)
        e:SpawnSmoke(2, 0, 4)

        -- SpawnSprite: scattered scorched-floor decals (the correct method —
        -- there is no SpawnScorch on EventContext, see file header note).
        for _ = 1, 5 do
            e:SpawnSprite("floors_burnt_01_" .. DE.rand(1, 8), 0, 4, { radius = 2 })
        end

        -- Utility exports, exercised directly.
        DE.log("[framework_test] DE.pick sample: %s", DE.pick({ "a", "b", "c" }))
        if DE.chance(50) then
            DE.log("[framework_test] DE.chance(50) hit")
        end
    end,

    -- Pulse: logs each tick and nudges any nearby loaded zombies toward the
    -- nearest player, to exercise DE.attractZombies too.
    pulse = {
        intervalSeconds = 20,
        fn = function(x, y, z, ev)
            DE.log("[framework_test] pulse tick at (%d, %d)", x, y)
            local p = DE.nearestPlayer(x, y)
            if p then
                DE.attractZombies(x, y, 50, p:getX(), p:getY())
            end
        end,
    },
}

DE.EventManager.register(EVENT)
