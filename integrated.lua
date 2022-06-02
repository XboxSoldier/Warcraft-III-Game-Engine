-- Slow
do
    Attribute('slowed')

    local EFFECT_CHANGE = Effect('Slow Change', function(arguments)
        processSlow(arguments.target)
    end)
    EFFECT_CHANGE:addValiador(valiadors.targetAlive)

    attributes.slowed:newChange(EFFECT_CHANGE)
end

-- Attack Slow
do
    Attribute('attackSlowed')

    local EFFECT_CHANGE = Effect('Attack Slow Change', function(arguments)
        processSlow(arguments.target)
    end)
    EFFECT_CHANGE:addValiador(valiadors.targetAlive)

    attributes.attackSlowed:newChange(EFFECT_CHANGE)
end

-- Integrated Slow Process
do
    local SLOW = FourCC('A000')
    local BUFF = FourCC('B000')
    local ORDER = 'cripple'
    function processSlow(unit)
        local amount1 = attributes.slowed:get(unit)
        local amount2 = attributes.attackSlowed:get(unit)
        if amount1 < 0 then amount1 = 0 end
        if amount2 < 0 then amount2 = 0 end

        UnitRemoveBuffBJ(BUFF, unit)

        if amount1 == 0 and amount2 == 0 then return end

        local ability

        local dummy = CreateUnit(GetOwningPlayer(unit), DUMMY, 0, 0, 0)
        UnitAddAbility(dummy, SLOW)
        ability = BlzGetUnitAbility(dummy, SLOW)
        BlzSetAbilityRealLevelField(ability, ABILITY_RLF_MOVEMENT_SPEED_REDUCTION_PERCENT_CRI1, 0, amount1)
        BlzSetAbilityRealLevelField(ability, ABILITY_RLF_ATTACK_SPEED_REDUCTION_PERCENT_CRI2, 0, amount2)
        IncUnitAbilityLevel(dummy, SLOW)
        DecUnitAbilityLevel(dummy, SLOW)
        IssueTargetOrder(dummy, ORDER, unit)
        delay(function()
            oldRemoveUnit(dummy)
        end)
    end
end