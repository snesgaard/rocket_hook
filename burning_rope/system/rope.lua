local br = require("burning_rope")
local nw = require "nodeworks"

local rope_system = nw.ecs.system(br.component.rope)

function rope_system:on_burned(entity)
    if not self.pool[entity] then return end

    entity:destroy()
end

return rope_system
