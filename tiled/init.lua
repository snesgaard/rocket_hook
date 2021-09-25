local nw = require "nodeworks"

local tiled = {}

function tiled.load_world(sti_map, tile_load, object_load, world, bump_world)
    world = world or nw.ecs.world()
    bump_world = bump_world or bump.newWorld()

    -- FIrst pass all tile layers, to instantiate the general level geometry
    for _, layer in ipairs(sti_map.layers) do
        if layer.type == "tilelayer" then
            layer.ecs = tile_load(sti_map, layer, world, bump_world)
        end
    end

    -- Then pass all object layers
    for _, layer in ipairs(sti_map.layers) do
        if layer.type == "objectgroup" and object_load then
            layer.ecs = object_load(sti_map, layer, world, bump_world)
        end
    end

    sti_map.ecs_world = world
    sti_map.bump_world = bump_world

    return world, bump_world
end


function tiled.instantiate_tile(map, layer, tile, x, y, world, bump_world)
    local position = vec2(map:convertTileToPixel(x - 1, y - 1))
        + vec2(layer.offsetx, layer.offsety)

    local entity = ecs.entity(world)
        :add(nw.component.position, position:unpack())
        :add(nw.component.hitbox, 0, 0, tile.width, tile.height)

    local should_have_collision = tile.properties.one_way or tile.properties.body

    if should_have_collision then
        entity:add(nw.component.bump_world, bump_world)
    end

    if tile.properties.one_way then
        entity:add(nw.component.oneway)
    end

    if tile.properties.body then
        entity:add(nw.component.body)
    end

    return entity
end

function tiled.tile_load(map, layer, world, bump)
    local ecs_tiles = {}

    for y, row in ipairs(layer.data) do
        local ecs_row = {}
        for x, tile in pairs(row) do
            ecs_row[x] = tiled.instantiate_tile(
                map, layer, tile, x, y, world, bump_world
            )
        end
        ecs_tiles[y] = ecs_row
    end

    return ecs_tiles
end

return tiled
