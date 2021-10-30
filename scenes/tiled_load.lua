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
        if item[nw.component.body] then return true end

        if item[nw.component.oneway] then
            local item_hb = nw.system.collision.get_world_hitbox(item)
            local other_hb = nw.system.collision.get_world_hitbox(other)

            -- Add some slack to account for floating point shenanigans
            if item_hb.y + 1e-15 >= other_hb.y + other_hb.h then
                return true
            end
        end

        return false
    end

    local item_solid = is_solid(item, other)
    local other_solid = is_solid(other, item)

    if item_solid and other_solid then return "slide" end

    return "cross"
end



local scene = {}

local function object_load(map, layer, world, bump_world)
    layer.visible = false

    for _, obj in ipairs(layer.objects) do
        if obj.type == "platform" then
            local w, h = obj.width, obj.height
            local entity = nw.ecs.entity(world, obj.name)
                :add(nw.component.hitbox, -w / 2, -h  /2, w, h)
                :add(nw.component.oneway)
                :add(nw.component.position, obj.x, obj.y)
                :add(nw.component.bump_world, bump_world)
                :add(rh.component.moving_platform)

            if obj.properties.path then
                local path_id = obj.properties.path.id
                local function path_query(other) return other.id == path_id end
                local path_obj = unpack(tiled.find_object(map, path_query))
                if not path_obj then
                    errorf("Tried to locate path %i, but couln't", path_id)
                end
                if not path_obj.polyline then
                    errorf("Path should be of type polyline")
                end

                --entity:add(rh.component.patrol, path_obj.polyline, 5)
                entity:assemble(
                    rh.system.platform_patrol.assemblage, path_obj.polyline,
                    obj.properties.patrol_time
                )
            end
        end
    end


end

local platform_draw = nw.ecs.system(
    rh.component.moving_platform, nw.component.hitbox, nw.component.position
)

function platform_draw:draw()
    local function draw_box(entity)
        local hitbox = entity[nw.component.hitbox]
        local x, y = entity[nw.component.position]:unpack()
        local x, y, w, h = hitbox:move(x, y):unpack()
        gfx.rectangle("fill", x, y, w, h)
    end

    gfx.setColor(1, 1, 1)
    List.foreach(self.pool, draw_box)
end


local all_systems = common_systems.logic + common_systems.action
    + common_systems.decision + list(rh.system.platform_patrol)
    + common_systems.motion + list(platform_draw) + common_systems.render

function scene.load()
    world = nw.ecs.world(all_systems)
    bump_world = nw.third.bump.newWorld()

    map = nw.third.sti("art/maps/build/test.lua")

    tiled.load_world(map, tiled.tile_load, object_load, world, bump_world)

    map.camera = nw.ecs.entity(world):assemble(rh.assemblage.camera)

    local spawn_locations = tiled.find_object(
        map, function(obj) return obj.type == "player_spawn" end
    )

    local location_name = "platform_debug"
    local location = spawn_locations:find(function(obj) return obj.name == location_name end)

    if not location then
        errorf("Could not find player_spawn with name %s", location_name)
    end

    map.gibbles = nw.ecs.entity(world, "gibbles")
        :assemble(rh.assemblage.gibbles, location.x, location.y, bump_world)

    --gibbles = ecs.entity(world, "gibbles")
        --:assemble(rh.assemblage.gibbles, 200, 0, bump_world)
    --instantiate_map(map, world, bump_world)

    local e = nw.ecs.entity()
        + {nw.component.position, 2, 3}
        + {nw.component.velocity, 300, 200}

    local position = e % nw.component.position
end

function scene.update(dt)
    world("update", dt)
end

function scene.draw()
    local tx, ty, sx, sy = rh.system.camera
        .track(map.camera, map.gibbles)
        .translation_scale(map.camera)
    map:draw(tx, ty, 2, 2)
    gfx.scale(2, 2)
    gfx.translate(tx, ty)
    world("draw")
    --bump_debug.draw_world(bump_world)
    gfx.origin()
    world("gui")
end

function scene.keypressed(key, ...)
    world("keypressed", key, ...)
    if key == "f1" then
        print("Entities =", #world.__entities)
    end
end

function scene.keyreleased(key, ...)
    world("keyreleased", key, ...)
end

return scene
