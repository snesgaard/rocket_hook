local nw = require "nodeworks"

local function reflect_input_map(map)
    local reflection = {}

    for key, value in pairs(map) do
        local l = reflection[value] or {}
        table.insert(l, key)
        reflection[value] = l
    end

    return reflection
end

local input_from_key = {
    lshift = "hook",
    space = "jump",
    left = "left",
    right = "right",
    up = "up",
    down = "down",
    a = "throw",
    lalt = "jump",
    z = "jump",
    d = "punch"
}

local keys_from_input = reflect_input_map(input_from_key)

local player_input = nw.ecs.system()

player_input.INPUT_FROM_KEY = input_from_key

local function get_direction()
    local dir = vec2()

    local dir_from_key = {
        left = vec2(-1, 0),
        right = vec2(1, 0),
        up = vec2(0, -1),
        down = vec2(0, 1)
    }

    for key, d in pairs(dir_from_key) do
        if love.keyboard.isDown(key) then
            dir = dir + d
        end
    end

    return dir
end

function player_input:keypressed(key)
    local input = input_from_key[key]

    if input then
        self.world("input_pressed", input)
    end
end

function player_input:keyreleased(key)
    local input = input_from_key[key]
    if input then
        self.world("input_released", input)
    end
end

local function less(threshold, value) return value < threshold end
local function greater(threshold, value) return threshold < value end
local general_threshold = 0.3

local axis_remap = {
    {"leftx", "right", greater, general_threshold},
    {"leftx", "left", less, -general_threshold},
    {"lefty", "up", less, -general_threshold},
    {"lefty", "down", greater, general_threshold},
    {"rightx", "aim_right", greater, general_threshold},
    {"rightx", "aim_left", less, -general_threshold},
    {"righty", "aim_up", less, -general_threshold},
    {"righty", "aim_down", greater, general_threshold}
}

local function axis_active(axis, cmp, threshold)
    local joysticks = love.joystick.getJoysticks()

    for _, j in ipairs(joysticks) do
        if cmp(threshold, j:getGamepadAxis(axis)) then return true end
    end

    return false
end

local gamepad_button_remap = {
    a = "jump",
    rightshoulder = "hook",
    x = "throw"
}

local function gamepad_isdown(key)
    local joysticks = love.joystick.getJoysticks()

    for _, j in ipairs(joysticks) do
        if j:isGamepadDown(key) then return true end
    end

    return false
end

function player_input:gamepadpressed(joystick, key)
    local input = gamepad_button_remap[key]

    if input then
        self.world("input_pressed", input)
    end
end

function player_input:gamepadreleased(joystick, key)
    local input = gamepad_button_remap[key]

    if input then
        self.world("input_released", input)
    end
end

function player_input:gamepadaxis(joystick, axis, value)

end

function player_input.is_down(input)
    local is_down = false

    for _, key in ipairs(keys_from_input[input] or {}) do
        is_down = is_down or love.keyboard.isDown(key)
    end

    for _, ar in ipairs(axis_remap) do
        local axis, axis_to_input, cmp, t = unpack(ar)
        if axis_to_input == input then
            is_down = is_down or axis_active(axis, cmp, t)
        end
    end

    for gamepad_button, gamepad_input in pairs(gamepad_button_remap) do
        if gamepad_input == input then
            is_down = is_down or gamepad_isdown(gamepad_button)
        end
    end

    return is_down
end

return player_input
