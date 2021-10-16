T("camera", function(T)
    local world = nw.ecs.world{rh.system.camera}

    local entity = nw.ecs.entity(world)
        + {nw.component.position, 100, 50}

    local camera = nw.ecs.entity(world)
        ^ {rh.assemblage.camera, vec2(0, 0)}

    T("pool size", function(T)
        local pool = world:context(rh.system.camera).pool
        T:assert(#pool == 1)
    end)

    T("get transform", function(T)
        local x, y, sx, sy = rh.system.camera.translation_scale(camera)
        local reference_scale = camera % rh.component.scale
        T:assert(reference_scale.x == sx)
        T:assert(reference_scale.y == sy)
    end)

    T("tracking", function(T)
        rh.system.camera.track(camera, entity)

        local sl = camera % rh.component.camera_slack
        local ep = entity % nw.component.position
        local cp = camera % nw.component.position

        T:assert(cp.x == ep.x - sl.x)
        T:assert(cp.y == ep.y - sl.y)
    end)
end)
