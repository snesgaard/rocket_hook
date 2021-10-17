T("throw", function(T)
    local world = nw.ecs.world{rh.system.action.throw}
    local entity = nw.ecs.entity(world)
        + {nw.component.action, "idle"}

    T("no members", function(T)
        local pool = world:context(rh.system.action.throw).pool
        T:assert(#pool == 0)
    end)

    rh.system.action.throw.throw(entity, vec2(0, 0))

    T("members", function(T)
        local pool = world:context(rh.system.action.throw).pool
        T:assert(#pool == 1)
    end)

    world("on_animation_ended", entity, "throw")

    T("no members again", function(T)
        local pool = world:context(rh.system.action.throw).pool
        T:assert(#pool == 0)
    end)
end)
