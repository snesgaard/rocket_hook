local nw = require "nodeworks"
local rh = require "rocket_hook"
local tiled = require "tiled"
local common_systems = require "common_systems"
require "lovedebug.lovedebug"

function nw.system.collision.default_move_filter(item, other)
    local f = item[rh.component.move_filter] or function() end
    local t = f(item, other)
    if t then return t end

    local function is_solid(item, other)
        if item[components.body] then return true end

        if item[components.oneway] then
            local item_hb = nw.system.collision.get_world_hitbox(item)
            local other_hb = nw.system.collision.get_world_hitbox(other)
            if item_hb.y >= other_hb.y + other_hb.h then return true end
        end

        return false
    end

    local item_solid = is_solid(item, other)
    local other_solid = is_solid(other, item)

    if item_solid and other_solid then return "slide" end

    return "cross"
end


local all_systems = common_systems.logic + common_systems.action
    + common_systems.decision + common_systems.motion + common_systems.render

local scene = {}

local function object_load(map, layer, world, bump_world)
    layer.visible = false
    for _, obj in ipairs(layer.objects) do
        if obj.type == "player_spawn" then
            gibbles = ecs.entity(world, "gibbles")
                :assemble(rh.assemblage.gibbles, obj.x, obj.y, bump_world)
            camera = ecs.entity(world)
                :assemble(rh.assemblage.camera)
        end
    end


end

function scene.load()
    world = ecs.world(all_systems)
    bump_world = bump.newWorld()

    map = sti("art/maps/build/test.lua")

    tiled.load_world(map, tiled.tile_load, object_load, world, bump_world)

    --gibbles = ecs.entity(world, "gibbles")
        --:assemble(rh.assemblage.gibbles, 200, 0, bump_world)
    --instantiate_map(map, world, bump_world)

    local e = ecs.entity()
        + {nw.component.position, 2, 3}
        + {nw.component.velocity, 300, 200}

    local position = e % nw.component.position
end

function scene.update(dt)
    world("update", dt)
end

function scene.draw()
    local tx, ty, sx, sy = rh.system.camera
        .track(camera, gibbles)
        .translation_scale(camera)
    map:draw(tx, ty, 2, 2)
    gfx.scale(2, 2)
    gfx.translate(tx, ty)
    world("draw")
    gfx.origin()
    world("gui")
    --bump_debug.draw_world(bump_world)
end

function scene.keypressed(key, ...)
    world("keypressed", key, ...)
    if key == "c" then rope:destroy() end
end

return scene
