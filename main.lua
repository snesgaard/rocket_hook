local nw = require "nodeworks"
gfx.setDefaultFilter("nearest", "nearest")

local function load_scene(args)
    local key = args[1]

    if key == "test" then
        require("test")
        print("ALL TEST PASSED")
        love.event.quit()
        return
    end

    return require "scenes.tiled_load"
end

function love.load(args)
    scene = load_scene(args) or {}
    if scene.load then scene.load() end
end

function love.update(dt)
    if scene.update then scene.update(dt) end
end

function love.keypressed(key, ...)
    if scene.keypressed then scene.keypressed(key, ...) end
    if key == "escape" then love.event.quit() end
end

function love.keyreleased(key, ...)
    if scene.keyreleased then scene.keyreleased(key, ...) end
end

function love.draw()
    if scene.draw then scene.draw() end
end
