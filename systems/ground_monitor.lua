local function on_ground_timer()
    return components.timer.create(0.2)
end

local ground_monitor = ecs.system(components.player_control)

function ground_monitor:on_collision(collisions)
    List.foreach(collisions, function(info)
        if not self.pool[info.item] then return end
        if info.normal.y > -0.9 then return end
        info.item:add(on_ground_timer)
    end)
end

function ground_monitor.is_on_ground(entity)
    return entity[on_ground_timer] and not entity[on_ground_timer]:done()
end

function ground_monitor:update(dt)
    for _, entity in ipairs(self.pool) do
        if entity[on_ground_timer] then entity[on_ground_timer]:update(dt) end
    end
end

return ground_monitor
