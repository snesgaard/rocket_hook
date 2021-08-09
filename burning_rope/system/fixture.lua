local br = require("burning_rope")
local nw = require("nodeworks")

local system = ecs.system(br.component.fixture, nw.component.parent)

local function get_fixture_position(fixture, entity)
    local f = fixture[entity]
    local s = entity[nw.component.hitbox] or nw.component.hitbox()
    local p = entity[nw.component.position] or nw.component.position()
    return f(s:move(p.x, p.y))
end

local function update_fixture(fixture_entity, dt)
    local fixture = fixture_entity[br.component.fixture]
    local master = fixture_entity[nw.component.parent]
    local p_m = get_fixture_position(fixture, master)

    for entity, _ in pairs(fixture) do
        if entity ~= master then
            local p_x = get_fixture_position(fixture, entity)
            local d = p_m - p_x
            nw.system.collision.move(entity, d.x, d.y)
        end
    end
end

function system:update(dt)
    List.foreach(self.pool, update_fixture, dt)
end

system["on_entity_added"] = function(self, entity)
    local parent = entity[nw.component.parent]
    local fixture = entity[br.component.fixture]

    for target, _ in pairs(fixture) do
        if target ~= parent then
            target:ensure(nw.component.disable_motion)
            target:map(nw.component.disable_motion, function(v) return v + 1 end)
        end
    end

    update_fixture(entity)
end

system["on_entity_removed"] = function(self, entity, pool, component, value)
    local parent = entity[nw.component.parent]
    local fixture = entity[br.component.fixture]

    if component == nw.component.parent then parent = value end
    if component == br.component.fixture then fixture = value end

    for target, _ in pairs(fixture) do
        if target ~= parent then
            target:ensure(nw.component.disable_motion)
            target:map(nw.component.disable_motion, function(v) return v - 1 end)
        end
    end
end

return system
