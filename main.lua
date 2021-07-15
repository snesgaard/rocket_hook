require "nodeworks"
require "components"
require "systems"

assemblages = require "assemblages"

local pause_system = ecs.system()

function pause_system:update(dt)
    return self.paused
end

function pause_system:keypressed(key)
    if key == "p" then
        self.paused = not self.paused
    end
end

local function geometry_draw_component() return true end

local geometry_draw_system = ecs.system(components.bump_world, geometry_draw_component)

function geometry_draw_system:draw()
    for _, entity in ipairs(self.pool) do
        local world = entity[components.bump_world]
        local x, y, w, h = world:getRect(entity)
        gfx.rectangle("fill", x, y, w, h)
    end
end

local player_draw_system = ecs.system(components.sprite, components.player_control)

function player_draw_system:draw()
    List.foreach(self.pool, systems.sprite.draw)
end

function love.load()
    systems.collision:show()
    world = ecs.world(
        geometry_draw_system,
        pause_system,
        systems.player_input,
        systems.animation,
        player_draw_system,
        systems.ground_monitor,
        systems.dodge,
        systems.hook,
        systems.normal,
        systems.motion,
        systems.collision
    )
    bump_world = bump.newWorld()

    local frame = get_atlas("art/characters"):get_frame("gibbles_reference")
    mc = ecs.entity(world)
        :add(components.hitbox, -5, -60, 10, 60)
        :add(components.body)
        :add(components.bump_world, bump_world)
        :add(components.position, 200, 200)
        :add(components.player_control)
        :assemble(assemblages.player_motion)
        :add(
            components.sprite,
            {
                [components.image] = {frame.image, frame.quad},
                [components.slices] = {frame.slices},
                [components.draw_args] = {0, 0, 0, 1, 1, -frame.offset.x, -frame.offset.y}
            }
        )
        :add(components.mirror)
        :add(components.animation_state)
        :add(
            components.animation_map,
            get_atlas("art/characters"),
            {
                idle="gibbles_idle/animation",
                hook_h_fire="gibbles_hook/h_fire",
                hook_h_drag="gibbles_hook/h_drag",
                hook_v_fire="gibbles_hook/v_fire",
                hook_v_drag="gibbles_hook/v_drag",
                hook_hv_fire="gibbles_hook/hv_fire",
                hook_hv_drag="gibbles_hook/hv_drag",
                descend="gibbles_arial/descend",
                ascend="gibbles_arial/ascend",
                run="gibbles_run"
            }
        )
        --:add(components.hook_point, 10, -10)

    ecs.entity(world)
        :add(components.hitbox, 0, 0, 20, 1200)
        :add(components.body)
        :add(components.bump_world, bump_world)
        :add(components.position, 0, 0)
        :add(geometry_draw_component)

    ecs.entity(world)
        :add(components.hitbox, 1200, 0, 20, 1200)
        :add(components.body)
        :add(components.bump_world, bump_world)
        :add(components.position, 0, 0)
        :add(geometry_draw_component)

    ecs.entity(world)
        :add(components.hitbox, 0, 550, 1200, 20)
        :add(components.body)
        :add(components.bump_world, bump_world)
        :add(components.position, 0, 0)
        :add(geometry_draw_component)

    ecs.entity(world)
        :add(components.hitbox, 0, 0, 1200, 20)
        :add(components.body)
        :add(components.bump_world, bump_world)
        :add(components.position, 0, 0)
        :add(geometry_draw_component)

    print(get_atlas("art/characters"):get_animation("smoke"))

end

function love.update(dt)
    world("update", dt)
end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.draw()
    gfx.translate(gfx.getWidth() * 0.5, gfx.getHeight() * 0.65)
    gfx.scale(2, 2)
    gfx.translate((-mc[components.position]):unpack())
    --bump_debug.draw_world(bump_world)
    --bump_debug.draw_coordinate_systems(world:entities())
    world("draw")
end
