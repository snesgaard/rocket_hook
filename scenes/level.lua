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

    ctx.camera = ctx:entity()
        :set(nw.component.position, 100, 100)
        :set(nw.component.scale, 3, 3)
end

level["scene.draw"] = function(ctx)
    local pos = ctx.camera % nw.component.position
    local scale = ctx.camera % nw.component.scale
    ctx.world("draw", pos.x, pos.y, scale.x, scale.y)
end

function level.mousemoved(ctx, x, y, dx, dy)
    if not love.mouse.isDown(3) then return end
    local pos = ctx.camera % nw.component.position
    pos.x = pos.x + dx
    pos.y = pos.y + dy
end

function level.wheelmoved(ctx, x, y)
    local scale = ctx.camera % nw.component.scale
    if y > 0 then
        ctx.camera[nw.component.scale] = scale * 1.1
    elseif y < 0 then
        ctx.camera[nw.component.scale] = scale / 1.1
    end
end

return level
