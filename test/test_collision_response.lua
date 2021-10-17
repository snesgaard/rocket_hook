T("collision_response", function(T)
    local world = nw.ecs.world{rh.system.collision_response}

    local entity = nw.ecs.entity(world)
        + {rh.component.player_control}

    local other_entity = nw.ecs.entity(world)

    local brittle_entity = nw.ecs.entity(world)
        + {rh.component.brittle}

    T("pool_size", function(T)
        local pool = world:context(rh.system.collision_response).pool
        T:assert(#pool == 1)
    end)

    T("on_collision_none", function(T)
        local colinfos = {
            -- No player control
            {
                item = other_entity,
                other = entity,
                normal = {x=0, y=1},
                type = "slide"
            },
            -- Wrong y-axis
            {
                item = entity,
                other = other_entity,
                normal = {x=0, y=1},
                type = "slide"
            },
            -- Wrong collision type
            {
                item = entity,
                other = other_entity,
                normal = {x=0, y=-1},
                type = "cross"
            }
        }

        for i = 1, #colinfos do
            world.on_event = on_event()
            world("on_collision", {colinfos[i]})
            -- Just one for on collision
            T:assert(#world.on_event == 1)
        end
    end)

    T("on_collision_ground", function(T)
        world.on_event = on_event()

        world(
            "on_collision",
            {
                {
                    item = entity,
                    other = other_entity,
                    normal = {x=0, y=-1},
                    type = "slide"
                }
            }
        )

        -- We got on ground
        T:assert(world.on_event:has("on_ground_collision"))
        -- And entity should be on ground
        T:assert(rh.system.collision_response.is_on_ground(entity))
        -- Now wait for the timeout plus a bit
        world("update", rh.system.collision_response.ON_GROUND_TIMEOUT + 1)
        -- No longer on ground
        T:assert(not rh.system.collision_response.is_on_ground(entity))
    end)

    T("brittle", function(T)
        world(
            "on_collision",
            {
                {
                    item = brittle_entity,
                    other = entity,
                    normal = {x=1, y=0},
                    type="slide"
                }
            }
        )

        T:assert(brittle_entity.world == nil)
    end)
end)
