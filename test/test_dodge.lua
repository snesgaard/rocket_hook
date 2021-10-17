T("dodge action", function(T)
    local tt = rh.system.action.dodge.TRAVEL_TIME
    local td = rh.system.action.dodge.TRAVEL_DISTANCE

    local world = nw.ecs.world{rh.system.action.dodge}

    local player = nw.ecs.entity(world)
        + {nw.component.position, 0, 100}
        + {nw.component.action, "idle"}

    T("no members", function(T)
        local pool = world:context(rh.system.action.dodge).pool
        T:assert(#pool == 0)
    end)

    local inputs = {
        {dir = vec2(0, 0), mirror=false, offset=vec2(td, -td)},
        {dir = vec2(0, 0), mirror=true, offset=vec2(-td, -td)},
        {dir = vec2(1, 0), mirror=true, offset=vec2(td, -td)},
        {dir = vec2(-1, 0), mirror=true, offset=vec2(-td, -td)},
    }

    for _, input in ipairs(inputs) do
        local test_name = string.format(
            "dir = %s, mirror = %s, offset = %s",
            tostring(input.dir), tostring(input.mirror), tostring(input.offset)
        )

        T(test_name, function(T)
            -- Set mirror
            player = player + {nw.component.mirror, input.mirror}
            -- Activate the jump
            rh.system.action.dodge.dodge(player, input.dir)

            T("is member now", function(T)
                local pool = world:context(rh.system.action.dodge).pool
                T:assert(#pool == 1)
            end)

            T("travel to the end", function(T)
                local expected_pos = (player % nw.component.position) + input.offset

                world("update", tt)
                local pos = player % nw.component.position

                T:assert(isclose(expected_pos.x, pos.x))
                T:assert(isclose(expected_pos.y, pos.y))
            end)
        end)
    end


    T("pass through", function(T)
        local offset = vec2(0, 1)
        local expected_pos = (player % nw.component.position) + offset
        rh.system.action.dodge.dodge(player, vec2(0, 1))
        local pos = player % nw.component.position

        T:assert(isclose(expected_pos.x, pos.x))
        T:assert(isclose(expected_pos.y, pos.y))
    end)

end)
