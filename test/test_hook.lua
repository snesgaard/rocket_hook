T("hook", function(T)
    local constants = rh.system.action.hook.constants
    local total_time = constants.player_time + constants.hook_time

    local world = nw.ecs.world{rh.system.action.hook}

    local entity = nw.ecs.entity(world)
        + {nw.component.action, "idle"}
        + {nw.component.position, 0, 0}

    local initial_pos = entity % nw.component.position

    T("no members", function(T)
        local pool = world:context(rh.system.action.hook).entities
        T:assert(#pool == 0)
    end)

    local inputs = {
        -- Active inputs
        {dir=vec2(1, 0), expected_pos=vec2(constants.hook_distance, 0)},
        {dir=vec2(-1, 0), expected_pos=vec2(-constants.hook_distance, 0)},
        {dir=vec2(0, -1), expected_pos=vec2(0, -constants.hook_distance)},
        {dir=vec2(1, -1), expected_pos=vec2(1, -1):normalize() * constants.hook_distance},
        {dir=vec2(-1, -1), expected_pos=vec2(-1, -1):normalize() * constants.hook_distance},
        -- None inputs, should just resuilt in forward motion
        {dir=vec2(0, 0), expected_pos=vec2(constants.hook_distance, 0)},
        {dir=vec2(0, 1), expected_pos=vec2(constants.hook_distance, 0)},
        {dir=vec2(1, 1), expected_pos=vec2(constants.hook_distance, 0)},
        {dir=vec2(-1, 1), expected_pos=vec2(-constants.hook_distance, 0)},

    }

    for _, input in ipairs(inputs) do
        local msg = string.format(
            "Hook test: dir = %s, expected_pos = %s",
            tostring(input.dir), tostring(input.expected_pos)
        )
        T(msg, function(T)
            rh.system.action.hook.hook(entity, input.dir)

            T("members", function(T)
                local pool = world:context(rh.system.action.hook).entities
                T:assert(#pool == 1)
            end)

            world("update", constants.hook_time)

            T("only_hook_moved", function(T)
                local pos = entity % nw.component.position
                T:assert(isclose(pos.x, initial_pos.x))
                T:assert(isclose(pos.x, initial_pos.x))
            end)

            world("update", constants.player_time)

            T("test end position", function(T)
                local expected_pos = input.expected_pos
                local pos = entity % nw.component.position
                T:assert(isclose(pos.x, expected_pos.x))
                T:assert(isclose(pos.y, expected_pos.y))
            end)
        end)
    end
end)
