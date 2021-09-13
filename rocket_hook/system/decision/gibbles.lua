local rh = require "rocket_hook"

local system = ecs.system(
    rh.component.player_control, components.action, components.hook_charges,
    rh.component.can_jump
)


local function get_input_direction()
    local dir_from_input = {
        up = vec2(0, -1),
        down = vec2(0, 1),
        left = vec2(-1, 0),
        right = vec2(1, 0)
    }

    local dir = vec2()

    for input, d in pairs(dir_from_input) do
        if rh.system.input_remap.is_down(input) then
            dir = dir + d
        end
    end

    return dir
end


local input_pressed_handlers = {}


function input_pressed_handlers.idle(entity, input)
    local h = entity[rh.component.hook_charges]
    local charge_index = List.argfind(h, function(t) return t:done() end)

    if input == "hook" and charge_index then
        --entity:update(components.action, "hook", get_input_direction())
        h[charge_index]:reset()
        entity[rh.component.can_jump] = true
        rh.system.collision_response.clear_ground(entity)
        rh.system.action.hook.hook(entity, get_input_direction())
    elseif input == "jump" and entity[rh.component.can_jump] then
        entity[rh.component.can_jump] = false
        rh.system.collision_response.clear_ground(entity)
        rh.system.action.dodge.dodge(entity, get_input_direction())
    elseif input == "throw" then
        rh.system.action.throw.throw(entity, get_input_direction())
    end
end


function system:input_pressed(input)
    for _, entity in ipairs(self.pool) do
        local action = entity[components.action]:type()
        local f = input_pressed_handlers[action]
        if f then f(entity, input) end
    end
end


function system:input_released(key)
end


function system:on_ground_collision(entity)
    if not self.pool[entity] then return end

    entity[rh.component.can_jump] = true
end


function system:update(dt)
    List.foreach(self.pool, function(entity)
        if entity[components.action]:type() ~= "idle" then return end

        local v = entity:ensure(components.velocity)


        if rh.system.collision_response.is_on_ground(entity) then
            local dir = get_input_direction()
            local speed = 200 * dir.x
            entity:update(components.velocity, speed, v.y)

            if dir.x < 0 then
                entity:update(components.mirror, true)
            elseif dir.x > 0 then
                entity:update(components.mirror, false)
            end

            if speed == 0 then
                systems.animation.play(entity, "idle")
            else
                systems.animation.play(entity, "run")
            end
        else
            if v.y < 0 then
                systems.animation.play(entity, "ascend")
            else
                systems.animation.play(entity, "descend")
            end
        end
    end)

    List.foreach(self.pool, function(entity)
        local h = entity[rh.component.hook_charges]
        if not rh.system.collision_response.is_on_ground(entity) then return end
        for _, t in ipairs(h) do
            if not t:done() then t:update(dt) end
        end
    end)
end

local icon = get_atlas("art/characters"):get_frame("rocket_icon")
local shader = gfx.newShader(
[[
vec4 effect(vec4 colour, Image texture, vec2 texpos, vec2 scrpos)
{
    vec4 pixel = Texel(texture, texpos) * colour;
    if (pixel.a < 0.5) discard;
    return pixel;
}
]]
)

function system:gui()
    for _, entity in ipairs(self.pool) do
        gfx.push("all")

        local hook_charges = entity[rh.component.hook_charges]

        for i, t in ipairs(hook_charges) do
            gfx.setColor(1, 1, 1)
            --gfx.rectangle("fill", i * 75, 25, 50, 50)
            local tl = math.max(0, t:time_left_normalized())
            if tl <= 0 then
                gfx.setColor(1, 1, 1)
            else
                gfx.setColor(0.7, 0.7, 0.7)
            end
            gfx.setShader(shader)
            local x, y = i * 75 - 25, 50
            gfx.stencil(
                function()
                    gfx.setColorMask(true, true, true, true)
                    icon:draw("body", x, y, 0, 2, 2)
                end,
                "replace", 2
            )
            gfx.setStencilTest("equal", 2)
            gfx.setShader()
            gfx.setColor(0, 0, 0, 0.9)
            gfx.arc(
                "fill", x, y, 200, -math.pi * 0.5,
                -math.pi * 0.5 + math.pi * 2 * tl
            )
        end

        gfx.pop()

        return
    end
end


return system
