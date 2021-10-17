T("platform_patrol", function(T)
    local world = nw.ecs.world{rh.system.platform_patrol}

    local path = list(
        vec2(0, 0),
        vec2(0, 50),
        vec2(150, 50)
    )

    local cycle_time = 1.0

    local platform = nw.ecs.entity(world)
        ^ {rh.system.platform_patrol.assemblage, path, cycle_time}
        + {nw.component.position, 0, 0}

    T("pool members", function(T)
        local pool = world:context(rh.system.platform_patrol).pool
        T:assert(#pool == 1)
    end)

    T("bug: move platform at exactly half", function(T)
        world("update", cycle_time * 0.5)
        local expected_pos = path:tail()
        local pos = platform % nw.component.position
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)

    T("move full", function(T)
        world("update", cycle_time)
        local expected_pos = path:head()
        local pos = platform % nw.component.position
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)

    T("move 1.125 cycle", function(T)
        world("update", cycle_time * 1.125)
        local expected_pos = path[2]
        local pos = platform % nw.component.position
        T:assert(isclose(pos.x, expected_pos.x))
        T:assert(isclose(pos.y, expected_pos.y))
    end)
end)
