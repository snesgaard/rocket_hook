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
    a = "throw"
}
local keys_from_input = reflect_input_map(input_from_key)



local player_input = ecs.system()

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

function player_input.is_down(input)
    local is_down = false

    for _, key in ipairs(keys_from_input[input] or {}) do
        is_down = is_down or love.keyboard.isDown(key)
    end

    return is_down
end

return player_input
