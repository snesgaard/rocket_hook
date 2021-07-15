local hook_distance = 200
local player_time = 0.5
local hook_time = 0.25
local rocket_ease = ease.outQuad
local player_ease = ease.inQuad

local player_drag_speed = hook_distance / player_time

local function hook_animation_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "hook_hv_fire"
    elseif dir.y ~= 0 then
        return "hook_v_fire"
    else
        return "hook_h_fire"
    end
end

local function drag_animation_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "hook_hv_drag"
    elseif dir.y ~= 0 then
        return "hook_v_drag"
    else
        return "hook_h_drag"
    end
end

local function rocket_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "rocket/rocket_hv"
    elseif dir.y ~= 0 then
        return "rocket/rocket_v"
    else
        return "rocket/rocket_h"
    end
end

local function chain_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "rocket/chain_hv"
    elseif dir.y ~= 0 then
        return "rocket/chain_v"
    else
        return "rocket/chain_h"
    end
end

local function smoke_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "smoke_hv"
    elseif dir.y ~= 0 then
        return "smoke_v"
    else
        return "smoke_h"
    end
end

local function jet_from_direction(dir)
    if dir.x ~= 0 and dir.y ~= 0 then
        return "jet_hv"
    elseif dir.y ~= 0 then
        return "jet_v"
    else
        return "jet_h"
    end
end

local function direction_component(dir) return dir:normalize() end

local function hook_tween_component()
    return components.tween(0, hook_distance, hook_time):ease(rocket_ease)
end

local function drag_tween_component(length)
    return components.tween(0, length, length / player_drag_speed):ease(player_ease)
end

local function hook_offset_component(entity, dir)
    local animation_key = hook_animation_from_direction(dir)
    local slice = systems.animation.get_slice(
        entity, "hook", "body", animation_key
    ) or spatial()
    if dir.x < 0 or entity[components.mirror] then slice = slice:hmirror() end
    return slice:center()
end

local function initial_position_component(pos) return vec2(pos:unpack()) end

local function hook_component(parent, dir)
    local entity = ecs.entity(parent.world)

    return entity
        :add(direction_component, dir)
        :add(hook_tween_component)
        :add(hook_offset_component, parent, dir)
        :add(components.parent, parent)
        :add(initial_position_component, parent[components.position])
        :add(components.position, entity[initial_position_component] + entity[hook_offset_component])
        :add(components.bump_world, parent[components.bump_world])
        :add(components.hitbox, -5, -5, 10, 10)
end

local function smoke_component() return true end

local function jet_component(world, dir, mirror)
    local jet = ecs.entity(world)
        :add(components.sprite, {[components.draw_args] = {0, 0, 0, 1, 1}})
        :add(components.animation_state)
        :add(
            components.animation_map,
            get_atlas("art/characters"),
            {
                jet_v="rocket_jet_ball/jet_v_huge",
                jet_h="rocket_jet_ball/jet_h_huge",
                jet_hv="rocket_jet_ball/jet_hv_huge",
            }
        )
        :add(components.mirror, mirror)

    systems.animation.play(jet, jet_from_direction(dir))

    return jet
end

local system = ecs.system.from_function(
    function(entity)
        return {
            candidates = entity:has(components.bump_world, components.position),
            hook_travel = entity:has(hook_component) and not entity:has(drag_tween_component),
            player_drag = entity:has(hook_component) and entity:has(drag_tween_component),
            smoke = entity:has(smoke_component)
        }
    end
)

function system:throw_hook(entity, dir)
    if dir.x > 0 then
        entity:update(components.mirror, false)
    elseif dir.x < 0 then
        entity:update(components.mirror, true)
    end

    entity
        :add(hook_component, entity, dir)
        :remove(components.velocity)
        :remove(components.gravity)
end


local function create_smoke_puff(world, x, y)
    return ecs.entity(world)
        :add(components.sprite)
        :add(components.animation_state)
        :add(
            components.animation_map,
            get_atlas("art/characters"),
            {
                smoke_v="smoke/smoke_v",
                smoke_h="smoke/smoke_h",
                smoke_hv="smoke/smoke_hv"
            }
        )
        :add(components.position, x or 0, y or 0)
        :add(smoke_component)
end

function system:on_entity_added(entity, pool)
    if pool == self.hook_travel then
        local dir = entity[hook_component][direction_component]
        local animation_key = hook_animation_from_direction(dir)
        local slice = systems.animation.get_transformed_slice(
            entity, "hook", "body", animation_key
        )
        systems.animation.play(entity, animation_key)

        local smoke = create_smoke_puff(entity.world, slice:center():unpack())
        smoke:add(components.mirror, entity[components.mirror])
        systems.animation.play(smoke, smoke_from_direction(dir), true)
    elseif pool == self.player_drag then
        local dir = entity[hook_component][direction_component]
        local animation_key = drag_animation_from_direction(dir)
        systems.animation.play(entity, animation_key)
    end
end

function system:on_animation_ended(entity)
    if not self.smoke[entity] then return end

    entity:destroy()
end

function system:on_entity_removed(entity, pool, component, prev_value)
    if component == hook_component then
        local jet = prev_value[jet_component]
        if jet then jet:destroy() end
        prev_value:destroy()
    end
end

function system:player_action(action, entity)
    return self.hook_travel[entity] or self.player_drag[entity]
end

function system:update(dt)
    List.foreach(self.hook_travel, function(entity)
        local hook = entity[hook_component]
        local tween = hook[hook_tween_component]
        local d = tween:update(dt)
        local dir = hook[direction_component]
        local init_pos = hook[initial_position_component]
        local o = hook[hook_offset_component]
        local next_pos = init_pos + d * dir + o
        local x, y, cols = self.world:action("move_to", hook, next_pos:unpack())

        local function did_we_collide()
            for _, c in ipairs(cols) do
                if c.other[components.body] and c.other ~= entity then
                    return true
                end
            end
            return false
        end

        if did_we_collide() or tween:is_done() then
            entity:add(drag_tween_component, tween:value())
            hook:add(jet_component, entity.world, dir, entity[components.mirror])
        end
    end)

    List.foreach(self.player_drag, function(entity)
        local tween = entity[drag_tween_component]
        local hook = entity[hook_component]
        local init_pos = hook[initial_position_component]
        local dir = hook[direction_component]
        local d = tween:update(dt)
        local next_pos = init_pos + dir * d

        self.world:action("move_to", entity, next_pos:unpack())

        if tween:is_done() then
            local velocity = tween:derivative(tween:get_duration()) * dir
            entity
                :remove(hook_component)
                :remove(drag_tween_component)
                :assemble(
                    assemblages.player_motion,
                    {
                        [components.velocity] = {velocity:unpack()}
                    }
                )
        end
    end)
end

local function draw_chain_h(start_pos, end_pos)
    local length = math.abs(start_pos.x - end_pos.x)
    if length == 0 then return end
    local n = (end_pos.x - start_pos.x) / length
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_h")
    local _, _, w, h = chain.quad:getViewport()

    gfx.setColor(1, 1, 1)
    gfx.stencil(function()
        gfx.rectangle("fill", math.min(start_pos.x, end_pos.x), start_pos.y - h, length, h * 2)
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    local d = 0
    while d < length do
        local x = start_pos.x + d * n
        chain:draw("body", x, start_pos.y, 0, n, 1)
        d = d + w
    end

    gfx.setStencilTest()
end

local function draw_chain_v(start_pos, end_pos)
    local length = math.abs(start_pos.y - end_pos.y)
    if length == 0 then return end
    local n = (end_pos.y - start_pos.y) / length
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_v")
    local _, _, w, h = chain.quad:getViewport()

    gfx.setColor(1, 1, 1)
    gfx.stencil(function()
        gfx.rectangle("fill", start_pos.x - w, math.max(start_pos.y, end_pos.y), w * 2, -length)
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    local d = 0

    while d < length do
        local y = start_pos.y + d * n
        chain:draw("body", start_pos.x, y, 0, 1, -n)
        d = d + h
    end

    gfx.setStencilTest()
end

local function draw_chain_hv(start_pos, end_pos)
    local dv = end_pos - start_pos
    local sx = dv.x > 0 and 1 or -1
    local sy = dv.y > 0 and 1 or -1
    local chain = get_atlas("art/characters"):get_frame("rocket/chain_hv")
    local _, _, w, h = chain.quad:getViewport()

    local x, y = start_pos:unpack()

    gfx.setColor(1, 1, 1)

    gfx.stencil(function()
        gfx.circle("fill", start_pos.x, start_pos.y, dv:length())
    end, "replace", 1)
    gfx.setStencilTest("equal", 1)

    while x * sx + y * sy < end_pos.x * sx + end_pos.y * sy do
        chain:draw("body", x, y, 0, sx, -sy)
        x = x + w * sx
        y = y + h * sy
    end

    gfx.setStencilTest()
end


function system:draw()
    local function draw_rocket(entity)
        local hook = entity[hook_component]
        local dir = hook[direction_component]
        local animation_key = rocket_from_direction(dir)
        local frame = get_atlas("art/characters"):get_frame(animation_key)
        local pos = hook[components.position]
        local sx = dir.x < 0 and -1 or 1
        gfx.setColor(1, 1, 1)
        frame:draw("body", pos.x, pos.y, 0, sx, 1)
    end

    local function draw_chain(entity)
        local hook = entity[hook_component]
        local offset = hook[hook_offset_component]
        local start_pos = entity[components.position] + offset
        local end_pos = hook[components.position]
        local dir = hook[direction_component]

        if dir.x ~= 0 and dir.y ~= 0 then
            draw_chain_hv(start_pos, end_pos)
        elseif dir.y ~= 0 then
            draw_chain_v(start_pos, end_pos)
        else
            draw_chain_h(start_pos, end_pos)
        end

    end

    local function draw_jet(entity)
        local hook = entity[hook_component]
        local x, y = hook[components.position]:unpack()
        systems.sprite.draw(hook[jet_component], x, y)
    end

    local function draw_rocket_and_chain(entity)
        draw_chain(entity)
        draw_jet(entity)
        draw_rocket(entity)
    end

    List.foreach(self.hook_travel, draw_rocket_and_chain)
    List.foreach(self.player_drag, draw_rocket_and_chain)

    List.foreach(self.smoke, systems.sprite.draw)
end

return system
