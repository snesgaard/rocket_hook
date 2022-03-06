local nw = require "nodeworks"
local rh = require "rocket_hook"
local T = nw.third.knife.test

local combat = rh.system.combat

T("combat", function(T)
    local max_hp = 10
    local base_hp = 7

    local attacker = nw.ecs.entity()
    local defender = nw.ecs.entity()
        :set(rh.component.max_health, max_hp)
        :set(rh.component.health, base_hp)

    T("peek", function(T)
        T:assert(combat.peek.deal_damage(defender, 5) == 5)
        T:assert(combat.peek.deal_damage(defender, 10) == 7)
        T:assert(combat.peek.deal_damage(defender, -1) == 0)

        T:assert(combat.peek.heal(defender, 1) == 1)
        T:assert(combat.peek.heal(defender, 10) == 3)
        T:assert(combat.peek.heal(defender, -1) == 0)

        local attack_data = combat.peek.attack(attacker, defender, 3)
        T:assert(attack_data.damage == 3)
        T:assert(not attack_data.charge_used)
        T:assert(not attack_data.shield_used)

        T("shield", function(T)
            combat.gain_shield(defender)
            T:assert(defender[rh.component.shield] == 1)

            local attack_data = combat.peek.attack(attacker, defender, 3)
            T:assert(attack_data.damage == 0)
            T:assert(attack_data.shield_used)
            T:assert(not attack_data.charge_used)
        end)

        T("charge", function(T)
            combat.gain_charge(attacker)
            T:assert(attacker[rh.component.charge] == 1)

            local attack_data = combat.peek.attack(attacker, defender, 3)
            T:assert(attack_data.damage == 6)
            T:assert(not attack_data.shield_used)
            T:assert(attack_data.charge_used)
        end)
    end)

    T("pop", function(T)
        T("normal", function(T)
            local attack_data = combat.attack(attacker, defender, 3)
            T:assert(attack_data.damage == 3)
            T:assert(not attack_data.shield_used)
            T:assert(not attack_data.charge_used)

            T:assert(defender[rh.component.health] == base_hp - 3)
        end)

        T("shield", function(T)
            combat.gain_shield(defender)
            T:assert(defender[rh.component.shield] == 1)

            local attack_data = combat.attack(attacker, defender, 3)
            T:assert(attack_data.damage == 0)
            T:assert(attack_data.shield_used)
            T:assert(not attack_data.charge_used)

            T:assert(defender[rh.component.shield] == 0)
            T:assert(defender[rh.component.health] == base_hp)
        end)

        T("charge", function(T)
            combat.gain_charge(attacker)
            T:assert(attacker[rh.component.charge] == 1)

            local attack_data = combat.attack(attacker, defender, 3)
            T:assert(attack_data.damage == 6)
            T:assert(not attack_data.shield_used)
            T:assert(attack_data.charge_used)

            T:assert(attacker[rh.component.charge] == 0)
            T:assert(defender[rh.component.health] == base_hp - 6)
        end)

        T("heal", function(T)
            local heal = combat.heal(defender, 2)
            T:assert(heal == 2)
            T:assert(defender[rh.component.health] == base_hp + 2)
        end)
    end)

end)
