local burn_components = {}

local function rng(min, max)
    return love.math.random() * (max - min) + min
end

function burn_components.burning()
    return {
        lifetime = rng(3, 5),
        cooldown = rng(0.1, 0.15)
    }
end

function burn_components.flammable()
    return true
end

function burn_components.charcoal()
    return true
end

function burn_components.brittle()
    return true
end

local box_drawer_system = ecs.system.from_function(function(entity)
    local is_box = entity:has(components.position, components.hitbox)
    local is_burning = entity:has(burn_components.burning)
    local is_flammable = entity:has(burn_components.flammable)
    local is_charcoal = entity:has(burn_components.charcoal)
    return {
        pool = is_box and not (is_burning or is_flammable or is_charcoal),
        burning = is_box and is_burning,
        flammable = is_box and is_flammable,
        charcoal = is_box and is_charcoal
    }
end)

function box_drawer_system:draw()
    local function draw_box(mode, entity)
        local hitbox = entity[components.hitbox]
        local x, y = entity[components.position]:unpack()
        local x, y, w, h = hitbox:move(x, y):unpack()
        gfx.rectangle(mode, x, y, w, h)
    end

    gfx.setColor(1, 1, 1)
    for _, entity in ipairs(self.pool) do
        draw_box("fill", entity)
    end

    for _, entity in ipairs(self.burning) do
        gfx.setColor(1, 0.2, 0.1)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.flammable) do
        gfx.setColor(0.5, 0.2, 0.3)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.flammable) do
        gfx.setColor(0.5, 0.2, 0.3)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end

    for _, entity in ipairs(self.charcoal) do
        gfx.setColor(0.5, 0.5, 0.5)
        draw_box("fill", entity)
        gfx.setColor(0, 0, 0, 0.5)
        draw_box("line", entity)
    end
end

local flammable_system = ecs.system(burn_components.flammable)

function flammable_system.__fetch_burning_entity(e1, e2)
    if e1[burn_components.burning] then return e1 end
    if e2[burn_components.burning] then return e2 end
end

function flammable_system.__fetch_flammable_entity(e1, e2)
    if e1[burn_components.flammable] then return e1 end
    if e2[burn_components.flammable] then return e2 end
end

function flammable_system:on_collision(collisions)
    for _, colinfo in ipairs(collisions) do
        local b = flammable_system.__fetch_burning_entity(colinfo.item, colinfo.other)
        local f = flammable_system.__fetch_flammable_entity(colinfo.item, colinfo.other)
        if b and f then
            f
                :remove(burn_components.flammable)
                :add(burn_components.burning)
        end
    end
end

local brittle_system = ecs.system(burn_components.brittle)

function brittle_system.__handle_collision(colinfo)
    for _, entity in ipairs{colinfo.item, colinfo.other} do
        if entity[burn_components.brittle] then
            entity:destroy()
        end
    end
end

function brittle_system:on_collision(collisions)
    List.foreach(collisions, brittle_system.__handle_collision)
end

local burn_system = ecs.system(
    burn_components.burning, burn_components.bump_world, burn_components.hitbox,
    burn_components.position
)

function burn_system:update(dt)
    List.foreach(self.pool, function(entity)
        local burn = entity[burn_components.burning]
        if not burn.cooldown then return end
        burn.cooldown = math.max(burn.cooldown - dt, 0)
        if burn.cooldown > 0 then return end
        burn.cooldown = nil
        local rect = systems.collision.get_rect(entity)
        if not rect then return end
        local rect_margin = rect:expand(2, 2)
        local collisions = systems.collision.check_rect(entity, rect_margin)
        for _, other in ipairs(collisions) do
            if other ~= entity and other[burn_components.flammable] then
                other
                    :remove(burn_components.flammable)
                    :add(burn_components.burning)
            end
        end
    end)

    List.foreach(self.pool, function(entity)
        local burn = entity[burn_components.burning]
        burn.lifetime = burn.lifetime - dt
        if burn.lifetime > 0 then return end
        entity
            :remove(burn_components.burning)
            :add(burn_components.charcoal)
    end)
end

local box_assemblage = function(x, y, w, h)
    return {
        [components.hitbox] = {0, 0, w or 40, h or 40},
        [components.position] = {x or 0, y or 0}
    }
end


local scene = {}

function scene.load()
    world = ecs.world(
        systems.motion,
        systems.collision,
        burn_system,
        flammable_system,
        box_drawer_system,
        brittle_system
    )

    bump_world = bump.newWorld()

    ecs.entity(world)
        :assemble(box_assemblage(150, 100))
        :add(burn_components.burning)
        :add(components.velocity, 0, 100)
        :add(components.gravity, 0, 0)
        :add(components.bump_world, bump_world)
        :add(burn_components.brittle)

    for r = 1, 10 do
        for c = 1, 10 do
            local w, h = 40, 40
            local x, y = 100 + w * (c - 1), 300 + h * (r - 1)

            ecs.entity(world)
                :assemble(box_assemblage(x, y, w, h))
                :add(burn_components.flammable)
                :add(components.bump_world, bump_world)
        end
    end
end

function scene.update(dt)
    world("update", dt)
end

function scene.keypressed(...)
    world("keypressed", ...)
end

function scene.draw()
    world("draw")
end

return scene
