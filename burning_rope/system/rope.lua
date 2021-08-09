local br = require("burning_rope")

local rope_system = ecs.system(br.component.rope)

function rope_system:on_burned(entity)
    if not self.pool[entity] then return end

    entity:destroy()
end

return rope_system
