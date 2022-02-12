local nw = require "nodeworks"

gfx.setDefaultFilter("nearest", "nearest")

function love.load(args)
    local key = args[1]
    world = nw.ecs.world{}

    if not key then return end

    printf("Loading scene %s", key)
    local scene = require(key:gsub("%.lua", ""))
    world:push(scene)
end

function love.update(dt)
    world("update", dt)
end

function love.keypressed(key, ...)
    if key == "escape" then love.event.quit() end
    world("keypressed", key, ...)
end

function love.keyreleased(key, ...)
    world("keyreleased", key, ...)
end

function love.gamepadpressed(joystick, button)
    world("gamepadpressed", joystick, button)
end

function love.gamepadreleased(joystick, button)
    world("gamepadreleased", joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    world("gamepadreleased", joystick, button)
end

function love.draw()
end
