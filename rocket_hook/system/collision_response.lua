local rh = require "rocket_hook"
local nw = require "nodeworks"


local ground_monitor = nw.ecs.system(rh.component.player_control)

ground_monitor.ON_GROUND_TIMEOUT = 0.1

local function on_ground_timer()
    return nw.component.timer.create(ground_monitor.ON_GROUND_TIMEOUT)
end

function ground_monitor:on_collision(collisions)
    List.foreach(collisions, function(info)
        if not self.pool[info.item] then return end
        if info.normal.y > -0.9 or info.type == "cross" then return end
        info.item:add(on_ground_timer)

        self.world("on_ground_collision", info.item)
    end)

    List.foreach(collisions, function(info)
        if info.item[rh.component.brittle] then info.item:destroy() end
        if info.other[rh.component.brittle] then info.other:destroy() end
    end)
end

function ground_monitor.is_on_ground(entity)
    return entity[on_ground_timer] and not entity[on_ground_timer]:done()
end

function ground_monitor.clear_ground(entity)
    local timer = entity[on_ground_timer]
    if not timer then return end
    entity:remove(on_ground_timer)
end

function ground_monitor:update(dt)
    for _, entity in ipairs(self.pool) do
        if entity[on_ground_timer] then entity[on_ground_timer]:update(dt) end
    end
end

return ground_monitor
