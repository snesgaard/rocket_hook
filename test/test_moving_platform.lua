T("moving platform", function(T)
    local world = nw.ecs.world{rh.system.moving_platform}

    local platform = nw.ecs.entity(world)
        + {rh.component.moving_platform}

    local entity = nw.ecs.entity(world)
        + {nw.component.position, 0, 0}
        + {nw.component.velocity}

    T("members", function(T)
        local pool = world:context(rh.system.moving_platform).pool
        T:assert(#pool == 1)
    end)

    -- Activate tether
    world(
        "on_contact_begin",
        entity, platform,
        {
            item = entity,
            other = platform,
            normal = vec2(0, 1),
            itemRect = spatial(0, 0, 10, 10),
            otherRect = spatial(0, 11, 10, 10)
        }
    )

    T("tether_begin", function(T)
        T:assert(rh.system.moving_platform.is_bound(platform, entity))
    end)

    T("move", function(T)
        local begin_pos = entity % nw.component.position
        local motion = vec2(0, 100)
        local expected_pos = begin_pos + motion

        world("on_moved", platform, motion:unpack())
        local pos = entity % nw.component.position
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)

    world("on_contact_end", entity, platform)
    -- Break tether
    T("thether_break", function(T)
        T:assert(not rh.system.moving_platform.is_bound(platform, entity))
    end)

    -- Move, assure that nothing is moved with it
    T("move, hopefully no change", function(T)
        local begin_pos = entity % nw.component.position
        local motion = vec2(0, 100)
        local expected_pos = begin_pos

        world("on_moved", platform, motion:unpack())
        local pos = entity % nw.component.position
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)
end)
