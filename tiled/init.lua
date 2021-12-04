local nw = require "nodeworks"
local rh = require "rocket_hook"

local tiled = {}

function tiled.spawn(sti_map, layer)
    if not layer then
        error("layer must be specified")
    end
    return nw.ecs.entity(sti_map.ecs_world)
        :add(rh.component.layer, layer.name)
end

function tiled.load_world(sti_map, tile_load, object_load, world, bump_world)
    world = world or nw.ecs.world()
    bump_world = bump_world or bump.newWorld()

    for _, layer in ipairs(sti_map.layers) do
        local entities = tiled.handle_layer(
            sti_map, layer, tile_load, object_load, world, bump_world
        )
        for _, entity in ipairs(entities or {}) do
            entity[rh.component.layer] = layer.name
        end
    end

    sti_map.ecs_world = world
    sti_map.bump_world = bump_world

    return world, bump_world
end

function tiled.handle_layer(sti_map, layer, tile_load, object_load, world, bump_world)
    if layer.type == "tilelayer" then
        return tiled.tile_load(sti_map, layer, tile_load, world, bump_world)
    elseif layer.type == "objectgroup" then
        layer.visible = false
        return tiled.object_load(sti_map, layer, object_load, world, bump_world)
    end
end

function tiled.object_load(sti_map, layer, object_load, world, bump_world)
    local entities = {}

    for _, object in ipairs(layer.objects) do
        local entity = object_load(sti_map, layer, object, world, bump_world)
        if entity then table.insert(entities, entity) end
    end

    return entities
end

local function handle_layer_data(map, layer, tile_load, world, bump_world)
    if not layer.data then return end

    local entities = list()

    for y, row in ipairs(layer.data) do
        for x, tile in pairs(row) do
            local entity = tile_load(map, layer, tile, x, y, world, bump_world)
            if entity then table.insert(entities, entity) end
        end
    end

    return entities
end

local function handle_layer_chunks(map, layer, tile_load, world, bump_world)
    if not layer.chunks then return end

    local entities = list()

    for _, chunk in ipairs(layer.chunks) do
        for y, row in ipairs(chunk.data) do
            for x, tile in pairs(row) do
                local entity = tile_load(
                    map, layer, tile, x + chunk.x, y + chunk.y, world, bump_world
                )
                if entity then table.insert(entities, entity) end
            end
        end
    end

    return entities
end

function tiled.tile_load(map, layer, tile_load, world, bump)
    local data_entities = handle_layer_data(map, layer, tile_load, world, bump_world)
    local chunk_entities = handle_layer_chunks(map, layer, tile_load, world, bump_world)

    if not data_entities then return chunk_entities end
    if not chunk_entities then return data_entities end

    return data_entities + chunk_entities
end

function tiled.find_object(map, search_function)
    local objects = list()

    -- Then pass all object layers
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" then
            for _, obj in ipairs(layer.objects) do
                if search_function(obj) then table.insert(objects, obj) end
            end
        end
    end

    return objects
end

function tiled.draw(map, x, y, sx, sy)
    gfx.setCanvas{map.canvas, stencil=true}
    gfx.clear()
    --map:draw(tx, ty, 2, 2)
    --gfx.scale(2, 2)
    for _, layer in ipairs(map.layers) do
        gfx.push()
        local px, py = x * layer.parallaxx, y * layer.parallaxy
        gfx.translate(math.floor(px), math.floor(py))
        if layer.visible then layer:draw() end
        gfx.pop()

        gfx.push()
        local function entity_filter(entity)
            return entity[rh.component.layer] == layer.name
        end
        gfx.translate(px, py)
        world:filter_event(entity_filter, "draw"):spin()

        gfx.pop()
    end

    gfx.translate(x, y)


    gfx.setCanvas()
    gfx.origin()
    gfx.scale(sx, sy)
    gfx.draw(map.canvas, 0, 0)
end

return tiled
