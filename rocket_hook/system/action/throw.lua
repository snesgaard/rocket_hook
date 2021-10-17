local br = require "burning_rope"
local rh = require "rocket_hook"
local nw = require "nodeworks"

local function box_component(x, y, w, h)
    return spatial(x, y, w, h)
end

local function entity_filter(entity)
    return {
        pool = entity:has(nw.component.action) and entity[nw.component.action]:type() == "throw",
        boxes = entity:has(box_component)
    }
end

local system = nw.ecs.system.from_function(entity_filter)

function system.throw(entity, dir)
    entity:update(nw.component.action, "throw", dir)
end

function system:on_entity_added(entity, pool)
    if pool ~= self.pool then return end
    entity:add(nw.component.root_motion)
    local dir = entity[nw.component.action]:args()

    if dir.x > 0 then
        entity:update(nw.component.mirror, false)
    elseif dir.x < 0 then
        entity:update(nw.component.mirror, true)
    end

    nw.system.animation.play(entity, "throw", {interrupt=true, once=true})
end

function system:on_entity_removed(entity)
    entity:remove(nw.component.root_motion)
end

function system:on_animation_ended(entity, id)
    if not self.pool[entity] or id ~= "throw" then return end

    entity:update(nw.component.action, "idle")
end

function system:draw()
    for _, box in ipairs(self.boxes) do
        gfx.setColor(1, 1, 1)
        gfx.rectangle("fill", box[box_component]:unpack())
    end
end

system["animation_event:throw"] = function(self, entity, frame)
    local slice = nw.system.animation.transform_slice(
        entity, frame:get_slice("throw", "body")
    )

    local sx = entity[nw.component.mirror] and -1 or 1

    nw.ecs.entity(self.world)
        :add(nw.component.hitbox, slice:relative(slice):unpack())
        :add(nw.component.bump_world, entity[nw.component.bump_world])
        :add(nw.component.position, slice:center())
        :add(nw.component.velocity, sx * 200, -200)
        :add(nw.component.gravity, 0, 1000)
        :add(rh.component.brittle)
        :add(br.component.burning)
end

return system
