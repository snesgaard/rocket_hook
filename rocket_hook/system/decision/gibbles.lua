local rh = require "rocket_hook"
local nw = require "nodeworks"


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

local function get_aim_direction()
    local dir_from_input = {
        aim_up = vec2(0, -1),
        aim_down = vec2(0, 1),
        aim_left = vec2(-1, 0),
        aim_right = vec2(1, 0)
    }

    local dir = vec2()

    for input, d in pairs(dir_from_input) do
        if rh.system.input_remap.is_down(input) then
            dir = dir + d
        end
    end

    return dir
end


local idle = {}

function idle.input(entity)
    local input = rh.system.input_buffer
    local can_jump = entity % rh.component.can_jump
    local hooks = entity % rh.component.hook_charges

    local on_ground = rh.system.collision_response.is_on_ground(entity)
    local charge_index = List.argfind(hooks, function(t) return t:done() end)

    if charge_index and input.is_pressed(entity, "hook") then
        hooks[charge_index]:reset()
        entity[rh.component.can_jump] = true
        rh.system.collision_response.clear_ground(entity)
        rh.system.action.hook.hook(entity, get_input_direction())
    elseif can_jump and input.is_pressed(entity, "jump") then
        entity[rh.component.can_jump] = false
        rh.system.collision_response.clear_ground(entity)
        rh.system.action.dodge.dodge(entity, get_input_direction())
    elseif on_ground and input.is_pressed(entity, "throw") then
        rh.system.action.throw.throw(entity, get_input_direction())
    end
end

function idle.update(entity, dt)
    local v = entity:ensure(nw.component.velocity)
    local dir = get_input_direction()
    local speed = 200

    if dir.x < 0 then
        entity:update(nw.component.mirror, true)
    elseif dir.x > 0 then
        entity:update(nw.component.mirror, false)
    end

    if rh.system.collision_response.is_on_ground(entity) then
        entity:update(nw.component.velocity, dir.x * speed, v.y)

        if dir.x == 0 then
            nw.system.animation.play(entity, "idle")
        else
            nw.system.animation.play(entity, "run")
        end
    else
        if math.abs(v.x) <= speed then
            entity:update(nw.component.velocity, dir.x * speed, v.y)
        elseif v.x * speed * dir.x < 0 then
            entity:update(nw.component.velocity, v.x * 0.99, v.y)
        end

        if v.y < 0 then
            nw.system.animation.play(entity, "ascend")
        else
            nw.system.animation.play(entity, "descend")
        end
    end
end

local states = {idle = idle}

local function get_state_func(states, action, func_key)
    local a = states[action]
    if not a then return end
    return a[func_key]
end

local system = nw.ecs.system(
    rh.component.player_control, nw.component.action, nw.component.hook_charges,
    rh.component.can_jump, rh.component.input_buffer
)

local function handle_input(entity)
    local action = entity % nw.component.action
    local f = get_state_func(states, action:type(), "input")
    if f then return f(entity) end
end

function system:on_ground_collision(entity)
    if not self.pool[entity] then return end

    entity[rh.component.can_jump] = true
end

function system:input_buffer_update(entity)
    if not self.pool[entity] then return end
    handle_input(entity)
end

function system:update(dt)
    List.foreach(self.pool, handle_input)

    List.foreach(self.pool, function(entity)
        local f = get_state_func(
            states, (entity % nw.component.action):type(), "update"
        )
        if f then f(entity, dt) end
    end)

    List.foreach(self.pool, function(entity)
        local h = entity[rh.component.hook_charges]
        local on_ground = rh.system.collision_response.is_on_ground(entity)
        local rate = on_ground and 1 or 0.3
        for _, t in ipairs(h) do
            if not t:done() then t:update(dt * rate) end
        end
    end)
end

function system:draw(...)
    for _, entity in ipairs(self.pool) do
        local action = entity % nw.component.action
        local f = get_state_func(states, action:type(), "draw")
        if f then f(entity, ...) end
    end
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
