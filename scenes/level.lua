local function object_type_component(key) return key end
local function name_component(name) return name end

local spawn_select = {}

function spawn_select.on_push(ctx, parent_ctx)
    ctx.ui = nw.ui(ctx)
    ctx.parent = parent_ctx
    ctx.spawn_points = List
        .filter(ctx.parent.entities, function(entity)
            return entity[object_type_component] == "player_spawn"
        end)
        :map(function(spawn_point)
            return nw.ecs.entity()
                :set(nw.component.parent, spawn_point)
                :set(nw.component.text, spawn_point[name_component])
        end)
    ctx.original_pos = vec2((parent_ctx.camera % nw.component.position):unpack())
end

function spawn_select.block_event(ctx, event)
    return event ~= "draw"
end

function spawn_select.update(ctx, dt)
    ctx.ui:position("spawn_points", 50, 50)
    local item, select = ctx.ui:menu("spawn_points", ctx.spawn_points)

    if item then
        local point = (item % nw.component.parent) % nw.component.position
        local pos = ctx.parent.camera % nw.component.position
        local scale = ctx.parent.camera % nw.component.scale
        pos.x = -point.x + gfx.getWidth() / (scale.x * 2)
        pos.y = -point.y + gfx.getHeight() / (scale.y * 2)
    end

    if select then ctx.world:pop() end

    if nw.system.input_buffer.is_pressed(ctx:singleton(), "escape") then
        ctx.parent.camera[nw.component.position] = ctx.original_pos
        ctx.world:pop()
    end
end

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

    ctx.layer = ctx:entity()
        :set(nw.component.layer_type, "entitygroup")

    for _, layer in ipairs(ctx.map.layers) do
        if layer.type == "objectgroup" then
            for _, object in ipairs(layer.objects) do
                ctx:entity()
                    :set(object_type_component, object.type)
                    :set(nw.component.position, object.x, object.y)
                    :set(name_component, object.name)
                    :set(nw.component.drawable, "rectangle")
                    :set(nw.component.layer, ctx.layer)
                    :set(nw.component.draw_mode, "fill")
                    :set(nw.component.rectangle, spatial(0, 0, 10, 10))
                    :set(nw.component.hidden, object.type ~= "player_spawn")
            end
        end
    end

    ctx.camera = ctx:entity()
        :set(nw.component.position, 100, 100)
        :set(nw.component.scale, 3, 3)
end

function level.draw(ctx)
    local pos = ctx.camera % nw.component.position
    local scale = ctx.camera % nw.component.scale
    --ctx.world("draw", pos.x, pos.y, scale.x, scale.y)
    ctx:invoke_event("draw", pos.x, pos.y, scale.x, scale.y)
end

function level.keypressed(ctx, key)
    if key == "f1" then
        ctx.world:push(spawn_select, ctx)
    end
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
