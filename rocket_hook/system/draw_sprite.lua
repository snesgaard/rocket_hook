local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.sprite)

local function draw_entity(entity)
    if entity[nw.component.hidden] then return end
    nw.system.sprite.draw(entity)
end

function system:draw()
    List.foreach(self.pool, draw_entity)
end

return system
