local nw = require "nodeworks"
local visuals = require(... .. ".visuals")
local hook_component = require(... .. ".components")
local constants = require(... .. ".constants")

local system = nw.ecs.system.from_function(
    function(entity)
        return {
            entities = entity:has(
                nw.component.action,
                nw.component.position,
                nw.component.hook
            )
                and entity[nw.component.action]:type() == "hook",
            smoke = entity:has(hook_component.smoke)
        }
    end
)

system.visuals = visuals

system.constants = constants

function system.hook_goes_where(entity, dir)
    local hc = hook_component.hook(entity, dir)
    local p = hc[nw.component.position] + dir:normalize() * constants.hook_distance
    return p
end

function system.hook(entity, dir)
    dir = vec2(dir.x, math.min(dir.y, 0))
    if dir:length() < 1e-10 then
        dir = vec2(entity[nw.component.mirror] and -1 or 1, 0)
    end
    entity:update(nw.component.action, "hook", dir)
    system.init_hook(entity)
end

function system:on_entity_added(entity, pool)
    if pool == self.entities then
        -- Deactivate velocity as we want to dictate how it goes
        entity:remove(nw.component.velocity)
    end
end

function system:on_entity_removed(entity, pool)
    if pool == self.entities then
        local hook = entity[hook_component.hook]
        local jet = hook[hook_component.jet]
        if jet then jet:destroy() end
        if hook then hook:destroy() end
        entity:remove(hook_component.drag_tween)
        entity:remove(hook_component.hook)

        -- Readd velocity, just to make sure
        entity:ensure(nw.component.velocity)
    end
end

function system:on_animation_ended(entity)
    if not self.smoke[entity] then return end

    entity:destroy()
end


function system.init_hook(entity)
    if entity[hook_component.hook] then return end

    local dir = entity[nw.component.action]:args()

    if dir.x > 0 then
        entity:update(nw.component.mirror, false)
    elseif dir.x < 0 then
        entity:update(nw.component.mirror, true)
    end

    entity:add(hook_component.hook, entity, dir, entity.world)

    -- Initialize animation
    local animation_key = constants.hook_animation_from_direction(dir)
    local slice = nw.system.animation.get_slice(
        entity, "hook", "body", animation_key
    )
    nw.system.animation.play(entity, animation_key)

    -- Create the smoke puff visuals
    local smoke = visuals.create_smoke_puff(entity, slice:center():unpack())
    smoke:add(nw.component.mirror, entity[nw.component.mirror])
    nw.system.animation.play(
        smoke, constants.smoke_from_direction(dir),
        {once=true, interrupt=true}
    )
end

function system.update_hook(self, entity, dt)
    local hook = entity[hook_component.hook]
    local tween = hook[hook_component.hook_tween]

    if tween:is_done() or tween:is_paused() then return dt end

    local d, dt_left  = tween:update(dt)
    local dir = hook[hook_component.direction]
    local init_pos = hook[hook_component.initial_position]
    local o = hook[hook_component.hook_offset]
    local next_pos = init_pos + d * dir + o
    local x, y, cols = nw.system.collision.move_to(hook, next_pos:unpack())

    if tween:is_done() then
        entity:add(hook_component.drag_tween, tween:value())
        hook:add(hook_component.jet, entity.world, dir, entity[nw.component.mirror])
        tween:pause()
    end

    return dt_left
end

function system.init_drag(entity)
    local dir = entity[hook_component.hook][hook_component.direction]
    local animation_key = constants.drag_animation_from_direction(dir)
    nw.system.animation.play(entity, animation_key)
end

local function did_we_collide_with_solid(cols)
    for _, c in ipairs(cols) do
        if c.type == "slide" then
            return true
        end
    end

    return false
end

function system.update_drag(self, entity, dt)
    local tween = entity[hook_component.drag_tween]
    local hook = entity[hook_component.hook]
    local init_pos = hook[hook_component.initial_position]
    local dir = hook[hook_component.direction]

    if tween:is_done() then return dt end

    local d, dt_left = tween:update(dt)
    local next_pos = init_pos + dir * d

    local _, _, cols = nw.system.collision.move_to(entity, next_pos:unpack())

    if did_we_collide_with_solid(cols) then
        tween:complete()
    end

    if tween:is_done() then
        local velocity = tween:derivative(tween:get_duration()) * dir
        velocity.y = math.min(velocity.y, -100)
        entity
            :add(nw.component.velocity, velocity:unpack())
    end

    return dt_left
end

local function update_entity(entity, dt)
    dt = system.update_hook(self, entity, dt)
    if dt <= 0 then return end

    system.init_drag(entity)
    dt = system.update_drag(self, entity, dt)

    if dt <= 0 then return end

    -- Exit by setting the action component to idle
    entity:update(nw.component.action, "idle")
end

function system.update(self, dt)
    List.foreach(self.entities, update_entity, dt)
end

function system:draw()
    local function draw_rocket(entity)
        local hook = entity[hook_component.hook]
        local dir = hook[hook_component.direction]
        local animation_key = constants.rocket_from_direction(dir)
        local frame = get_atlas("art/characters"):get_frame(animation_key)
        local pos = hook[nw.component.position]
        local sx = dir.x < 0 and -1 or 1
        gfx.setColor(1, 1, 1)
        frame:draw("body", pos.x, pos.y, 0, sx, 1)
    end

    local function draw_chain(entity)
        local hook = entity[hook_component.hook]
        local offset = hook[hook_component.hook_offset]
        local start_pos = entity[nw.component.position] + offset
        local end_pos = hook[nw.component.position]
        local dir = hook[hook_component.direction]

        if dir.x ~= 0 and dir.y ~= 0 then
            visuals.draw_chain_hv(start_pos, end_pos)
        elseif dir.y ~= 0 then
            visuals.draw_chain_v(start_pos, end_pos)
        else
            visuals.draw_chain_h(start_pos, end_pos)
        end

    end

    local function draw_jet(entity)
        local hook = entity[hook_component.hook]
        local x, y = hook[nw.component.position]:unpack()
        nw.system.sprite.draw(hook[hook_component.jet], x, y)
    end

    local function draw_rocket_and_chain(entity)
        draw_chain(entity)
        draw_jet(entity)
        draw_rocket(entity)
    end

    List.foreach(self.entities, draw_rocket_and_chain)
    List.foreach(self.smoke, nw.system.sprite.draw)
end

return system
