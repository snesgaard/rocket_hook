local br = require "burning_rope"
local nw = require "nodeworks"

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

local logic_systems = list(
    pause_system,
    br.system.burn,
    br.system.rope,
    nw.system.parenting
)

local motion_systems = list(
    nw.system.motion,
    br.system.fixture,
    nw.system.collision
)

local render_systems = list(
    br.system.geometry_draw
)

local all_systems =
    render_systems
    + logic_systems
    + motion_systems

function scene.load()
    world = ecs.world(all_systems)
    bump_world = bump.newWorld()


    local box = ecs.entity(world)
        :add(nw.component.hitbox, 0, 0, 200, 50)
        :add(nw.component.bump_world, bump_world)
        :add(nw.component.position, 0, 0)
        :add(nw.component.velocity)
        :add(nw.component.gravity, 0, 100)
        :add(br.component.flammable)

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

    boxes:tail():add(br.component.burning)
end

function scene.update(dt)
    world("update", dt)
end

function scene.draw()
    world("draw")
end

function scene.keypressed(key, ...)
    world("keypressed", key, ...)
    if key == "c" then rope:destroy() end
end

return scene
