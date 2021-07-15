local visuals = require(... .. ".visuals")
local hook_components = require(... .. ".components")
local constants = require(... .. ".constants")

local system = ecs.system.from_function(
    function(entity)
        return {
            candidates = entity:has(components.bump_world, components.position),
            hook_travel = entity:has(hook_components.hook) and not entity:has(hook_components.drag_tween),
            player_drag = entity:has(hook_components.hook) and entity:has(hook_components.drag_tween),
            smoke = entity:has(hook_components.smoke)
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
        :add(hook_components.hook, entity, dir)
        :remove(components.velocity)
        :remove(components.gravity)
end

function system:on_entity_added(entity, pool)
    if pool == self.hook_travel then
        local dir = entity[hook_components.hook][hook_components.direction]
        local animation_key = constants.hook_animation_from_direction(dir)
        local slice = systems.animation.get_transformed_slice(
            entity, "hook", "body", animation_key
        )
        systems.animation.play(entity, animation_key)

        local smoke = visuals.create_smoke_puff(entity.world, slice:center():unpack())
        smoke:add(components.mirror, entity[components.mirror])
        systems.animation.play(smoke, constants.smoke_from_direction(dir), true)
    elseif pool == self.player_drag then
        local dir = entity[hook_components.hook][hook_components.direction]
        local animation_key = constants.drag_animation_from_direction(dir)
        systems.animation.play(entity, animation_key)
    end
end

function system:on_animation_ended(entity)
    if not self.smoke[entity] then return end

    entity:destroy()
end

function system:on_entity_removed(entity, pool, component, prev_value)
    if component == hook_components.hook then
        local jet = prev_value[hook_components.jet]
        if jet then jet:destroy() end
        prev_value:destroy()
    end
end

function system:player_action(action, entity)
    return self.hook_travel[entity] or self.player_drag[entity]
end

function system:update(dt)
    List.foreach(self.hook_travel, function(entity)
        local hook = entity[hook_components.hook]
        local tween = hook[hook_components.hook_tween]
        local d = tween:update(dt)
        local dir = hook[hook_components.direction]
        local init_pos = hook[hook_components.initial_position]
        local o = hook[hook_components.hook_offset]
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
            entity:add(hook_components.drag_tween, tween:value())
            hook:add(hook_components.jet, entity.world, dir, entity[components.mirror])
        end
    end)

    List.foreach(self.player_drag, function(entity)
        local tween = entity[hook_components.drag_tween]
        local hook = entity[hook_components.hook]
        local init_pos = hook[hook_components.initial_position]
        local dir = hook[hook_components.direction]
        local d = tween:update(dt)
        local next_pos = init_pos + dir * d

        self.world:action("move_to", entity, next_pos:unpack())

        if tween:is_done() then
            local velocity = tween:derivative(tween:get_duration()) * dir
            entity
                :remove(hook_components.hook)
                :remove(hook_components.drag_tween)
                :assemble(
                    assemblages.player_motion,
                    {
                        [components.velocity] = {velocity:unpack()}
                    }
                )
        end
    end)
end

function system:draw()
    local function draw_rocket(entity)
        local hook = entity[hook_components.hook]
        local dir = hook[hook_components.direction]
        local animation_key = constants.rocket_from_direction(dir)
        local frame = get_atlas("art/characters"):get_frame(animation_key)
        local pos = hook[components.position]
        local sx = dir.x < 0 and -1 or 1
        gfx.setColor(1, 1, 1)
        frame:draw("body", pos.x, pos.y, 0, sx, 1)
    end

    local function draw_chain(entity)
        local hook = entity[hook_components.hook]
        local offset = hook[hook_components.hook_offset]
        local start_pos = entity[components.position] + offset
        local end_pos = hook[components.position]
        local dir = hook[hook_components.direction]

        if dir.x ~= 0 and dir.y ~= 0 then
            visuals.draw_chain_hv(start_pos, end_pos)
        elseif dir.y ~= 0 then
            visuals.draw_chain_v(start_pos, end_pos)
        else
            visuals.draw_chain_h(start_pos, end_pos)
        end

    end

    local function draw_jet(entity)
        local hook = entity[hook_components.hook]
        local x, y = hook[components.position]:unpack()
        systems.sprite.draw(hook[hook_components.jet], x, y)
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
