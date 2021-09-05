local br = require "burning_rope"
local nw = require "nodeworks"
local rh = require "rocket_hook"

local scene = {}


local pause_system = ecs.system()

function pause_system:update(dt)
    return self.paused
end

function pause_system:keypressed(key)
    if key == "p" then
        self.paused = not self.paused
    end
end

local player_draw_system = ecs.system(nw.component.sprite, rh.component.player_control)

function player_draw_system:draw()
    List.foreach(self.pool, systems.sprite.draw)
end

local logic_systems = list(
    pause_system,
    br.system.burn,
    br.system.rope,
    nw.system.parenting
)

local action_systems = list(
    rh.system.input_remap,
    rh.system.action.dodge,
    rh.system.action.throw,
    rh.system.action.hook
)

local decision_systems = list(
    rh.system.decision.gibbles
)

local motion_systems = list(
    nw.system.motion,
    br.system.fixture,
    nw.system.collision,
    nw.system.collision_contact,
    rh.system.collision_response,
    rh.system.moving_platform
)

local render_systems = list(
    nw.system.animation,
    br.system.geometry_draw,
    rh.system.camera,
    player_draw_system
)

local all_systems =
    render_systems
    + logic_systems
    + decision_systems
    + action_systems
    + motion_systems


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

function scene.load()
    world = ecs.world(all_systems)
    bump_world = bump.newWorld()

    local box = ecs.entity(world)
        :add(nw.component.hitbox, 0, 0, 200, 50)
        :add(nw.component.bump_world, bump_world)
        :add(nw.component.position, 0, 0)
        :add(nw.component.velocity)
        :add(nw.component.gravity, 0, 100)
        :add(nw.component.body)

    rope = ecs.entity(world)
        :add(nw.component.hitbox, -5, 0, 10, 200)
        :add(nw.component.bump_world, bump_world)
        :add(nw.component.position, 300, 100)
        --:add(br.component.burning)
        :add(br.component.flammable)
        :add(br.component.rope)

    fixture = ecs.entity((world))
        :add(br.component.fixture,
            {
                [rope] = Spatial.centerbottom,
                [box] = Spatial.centertop
            }
        )
        :add(nw.component.parent, rope)

    boxes = list()

    for i = 1, 30 do
        local e = ecs.entity(world)
            :add(nw.component.body)
            :add(nw.component.hitbox, 0, 0, 20, 20)
            :add(nw.component.bump_world, bump_world)
            :add(nw.component.position, 300 + (i - 1) * 20, 100)
            :add(br.component.flammable)
        table.insert(boxes, e)
    end

    ecs.entity(world)
        :add(nw.component.hitbox, 100, 100, 100, 10)
        :add(nw.component.bump_world, bump_world)
        :add(nw.component.position)
        :add(nw.component.oneway)

    ecs.entity(world)
        :add(nw.component.hitbox, 100, 300, 100, 10)
        :add(nw.component.bump_world, bump_world)
        :add(nw.component.position)
        :add(nw.component.oneway)

    gibbles = ecs.entity(world, "gibbles")
        :assemble(rh.assemblage.gibbles, 200, 200, bump_world)

    mover_platform = ecs.entity(world, "platform")
        :add(nw.component.hitbox, -50, -5, 100, 10)
        :add(nw.component.position, 400, 200)
        :add(nw.component.bump_world, bump_world)
        :add(rh.component.moving_platform)
        :add(nw.component.oneway)


    mover_platform2 = ecs.entity(world, "platform2")
        :add(nw.component.hitbox, -50, -5, 100, 10)
        :add(nw.component.position, 400, 200)
        :add(nw.component.bump_world, bump_world)
        :add(rh.component.moving_platform)
        :add(nw.component.oneway)

    camera = ecs.entity(world)
        :assemble(rh.assemblage.camera, gibbles)


    local foobar = {1, 2, 3, 4, 5}

    for index, value in pairs(foobar) do
        print("go", index, value)
        if index == 2 then
            table.remove(foobar, index)
        end
    end

end

function scene.update(dt)
    world("update", dt)

    local t = love.timer.getTime()
    local x = 600 - 100 * math.cos(t)
    local y = 330 - 100 * math.cos(t)
    local x2 = 600 - 100 * math.cos(t)
    local y2 = 330 + 100 * math.cos(t)
    nw.system.collision.move_to(mover_platform, x, y)
    nw.system.collision.move_to(mover_platform2, x2, y2)
end

function scene.draw()
    --gfx.scale(2, 2)
    rh.system.camera.track(camera).transform(camera)
    world("draw")
    gfx.origin()
    world("gui")
end

function scene.keypressed(key, ...)
    world("keypressed", key, ...)
    if key == "c" then rope:destroy() end
end

return scene
