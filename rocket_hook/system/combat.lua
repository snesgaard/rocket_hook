local nw = require "nodeworks"
local rh = require "rocket_hook"

local combat = nw.ecs.system()

local peek = {}

function peek.deal_damage(target, damage)
    local health = target:ensure(rh.component.health)
    local next_health = math.max(0, health - math.max(0, damage))

    local damage_dealt = health - next_health

    return damage_dealt, next_health
end

function peek.heal(target, heal)
    local max_health = target:ensure(rh.component.max_health)
    local health = target:ensure(rh.component.health)
    local next_health = math.min(max_health, health + math.max(0, heal))
    local actual_heal = next_health - health

    return actual_heal, next_health
end

function peek.attack(attacker, target, base_damage)
    local str = attacker:ensure(rh.component.strength)
    local def = target:ensure(rh.component.defense)

    local actual_damage = math.max(0, base_damage + str)

    local charge_used = peek.use_charge(attacker)

    if charge_used then actual_damage = actual_damage * 2 end

    actual_damage = math.max(0, actual_damage - def)

    local shield_used = peek.use_shield(target, actual_damage)

    if shield_used then actual_damage = 0 end

    return {
        damage = actual_damage,
        shield_used = shield_used,
        charge_used = charge_used
    }
end

function peek.use_shield(target, damage)
    return damage > 0 and target:ensure(rh.component.shield) > 0
end

function peek.use_charge(attacker)
    return attacker:ensure(rh.component.charge) > 0
end

function combat.heal(target, heal)
    local actual_heal, health = peek.heal(target, heal)

    target:set(rh.component.health, health)
    target:event("on_heal", target, actual_heal)

    return actual_heal, health
end

function combat.deal_damage(target, damage)
    local damage_dealt, health = peek.deal_damage(target, damage)

    target:set(rh.component.health, health)
    target:event("on_damage", target, damage_dealt)

    return damage_dealt, health
end

function combat.attack(attacker, target, damage)
    local attack_data = peek.attack(attacker, target, damage)

    target:event("on_attack", attacker, target, attack_data)

    if attack_data.charge_used then combat.use_charge(attacker) end
    if attack_data.shield_used then combat.use_shield(target) end

    combat.deal_damage(target, attack_data.damage)

    return attack_data
end

function combat.use_charge(target)
    local charge = target:ensure(rh.component.charge)
    if charge <= 0 then return false end

    target:set(rh.component.charge, charge - 1)
    target:event("on_charge_used", target)

    return true
end

function combat.use_shield(target)
    local shield = target:ensure(rh.component.shield)
    if shield <= 0 then return false end

    target:set(rh.component.shield, shield - 1)
    target:event("on_shield_used", target)

    return true
end

function combat.gain_shield(target)
    local shield = target:ensure(rh.component.shield)

    target:set(rh.component.shield, shield + 1)
    target:event("on_shield_gain", target)
end

function combat.gain_charge(target)
    local charge = target:ensure(rh.component.charge)

    target:set(rh.component.charge, charge + 1)
    target:event("on_charge_gain", target)
end

combat.peek = peek

return combat
