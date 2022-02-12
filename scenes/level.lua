local level = {}

function level.on_push(ctx)
    ctx.bump_world = nw.third.bump.newWorld()
    ctx.map = nw.third.sti("art/maps/build/test.lua")

    for _, layer in ipairs(ctx.map.layers) do
        if layer.type ~= "objectgroup" then
            ctx:entity()
                :set(nw.component.tiled_layer, layer)
                :set(nw.component.layer_type, "tiled")
                :set(nw.component.parallax, layer.parallaxx, layer.parallaxy)
        end
    end

    ctx:singleton()
        :set(nw.component.position, 100, 100)
        :set(nw.component.scale, 2, 2)
end

function level.draw(ctx, x, y)
end

function level.mousemoved(ctx, x, y, dx, dy)
    if not love.mouse.isDown(3) then return end
    local pos = ctx:singleton() % nw.component.position
    pos.x = pos.x + dx
    pos.y = pos.y + dy
end

return level
