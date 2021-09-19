local scene = require "scenes.freeze"

function love.load()
    if scene.load then scene.load() end
end

function love.update(dt)
    if scene.update then scene.update(dt) end
end

function love.keypressed(key, ...)
    if scene.keypressed then scene.keypressed(key, ...) end
    if key == "escape" then love.event.quit() end
end

function love.draw()
    if scene.draw then scene.draw() end
end
