local function broadcast_action(self, action, ...)
    for _, entity in ipairs(self.pool) do
        self.world("player_action", action, entity, ...)
    end
end


local player_input = ecs.system(components.player_control)

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


function player_input:update(dt)
    local dir = get_direction()

    dir = dir:normalize() * dt

    broadcast_action(self, "move", dir)
end

function player_input:keypressed(key)
    if key == "lshift" then
        broadcast_action(self, "hook", get_direction())
    elseif key == "space" then
        broadcast_action(self, "jump", get_direction():normalize())
    end
end

return player_input
