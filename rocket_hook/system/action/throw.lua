local br = require "burning_rope"
local rh = require "rocket_hook"
local nw = require "nodeworks"

local function box_component(x, y, w, h)
    return spatial(x, y, w, h)
end

local function entity_filter(entity)
    return {
        pool = entity:has(components.action) and entity[components.action]:type() == "throw",
        boxes = entity:has(box_component)
    }
end

local system = nw.ecs.system.from_function(entity_filter)

function system.throw(entity, dir)
    entity:update(components.action, "throw", dir)
end

function system:on_entity_added(entity, pool)
    if pool ~= self.pool then return end
    entity:add(components.root_motion)
    local dir = entity[components.action]:args()

    if dir.x > 0 then
        entity:update(components.mirror, false)
    elseif dir.x < 0 then
        entity:update(components.mirror, true)
    end

    systems.animation.play(entity, "throw", {interrupt=true, once=true})
end

function system:on_entity_removed(entity)
    entity:remove(components.root_motion)
end

function system:on_animation_ended(entity, id)
    if not self.pool[entity] or id ~= "throw" then return end

    entity:update(components.action, "idle")
end

function system:draw()
    for _, box in ipairs(self.boxes) do
        gfx.setColor(1, 1, 1)
        gfx.rectangle("fill", box[box_component]:unpack())
    end
end

system["animation_event:throw"] = function(self, entity, frame)
    local slice = systems.animation.transform_slice(
        entity, frame:get_slice("throw", "body")
    )
    --ecs.entity(self.world)
    --    :add(box_component, slice:unpack())
    local sx = entity[components.mirror] and -1 or 1

    nw.ecs.entity(self.world)
        :add(components.hitbox, slice:relative(slice):unpack())
        :add(components.bump_world, entity[components.bump_world])
        :add(components.position, slice:center())
        :add(components.velocity, sx * 200, -200)
        :add(components.gravity, 0, 1000)
        :add(rh.component.brittle)
        :add(br.component.burning)
end

return system
