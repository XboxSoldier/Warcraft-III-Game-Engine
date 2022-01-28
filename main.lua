do
    -- Game --
    game = {}

    -- Settings --
    independentStartup = false
    displayDamageValue = true

    -- Basic Library --
    function group2Table(group)
        local r = {}
        for k = 0, BlzGroupGetSize(group) - 1 do
            table.insert(r, BlzGroupUnitAt(group, k))
        end
        return r
    end

    function group2Storage(group)
        local r = storage:create()
        for k = 0, BlzGroupGetSize(group) - 1 do
            r:add(BlzGroupUnitAt(group, k))
        end
        return r
    end

    function table2Group(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local group = CreateGroup()
        for i = 1, #parameters do
            GroupAddUnit(group, parameters[i])
        end
        return group
    end

    function unitApplyBuff(unit, buffAbility, command)
        local code = FourCC(buffAbility)
        local dummy = DummyRetrieve(Player(PLAYER_NEUTRAL_PASSIVE), GetUnitX(unit), GetUnitY(unit), GetUnitFlyHeight(unit), 0)

        UnitAddAbility(dummy, code)
        IssueTargetOrder(dummy, command, unit)
        UnitRemoveAbility(dummy, code)
        DummyRecycle(dummy)
    end

    -- Init --
    if independentStartup then
        local init_array = {}
        local init_old = InitBlizzard
        onInitialization = function(code)
            if type(code) == 'function' then table.insert(init_array, code) end
        end
        InitBlizzard = function()
            init_old()
            for i = 1, #init_array do
                init_array[i]()
            end
        end
    else
        onInitialization = function(code)
            onInit(code)
        end
    end

    -- Normal Table --
    function tableNotObject(list)
        if type(list) ~= 'table' then return false end
        local mt = getmetatable(list)
        if not mt then return true end
        return false
    end

    -- Game Data --
    function aquireGameData(create, ...)
        local arguments = {...}
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        local current = game
        for i = 1, #arguments do
            if ((not create) and (not current[arguments[i]])) or (type(current[arguments[i]]) ~= 'table' and i ~= #arguments) then
                return nil
            elseif i ~= #arguments or create then
                current[arguments[i]] = {}
            end
            current = current[arguments[i]]
        end
        return current
    end

    function writeGameData(value, ...)
        local arguments = {...}
        local item = arguments[-1]
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        table.remove(arguments)
        local current = aquireGameData(true, arguments)
        if current then current[item] = value end
    end

    -- Storage --
    storage = setmetatable({}, {})
    local storage_mt = getmetatable(storage)
    storage_mt.__index = storage_mt

    function storage_mt:create(...)
        local arguments = {...}
        local this = {}
        setmetatable(this, storage_mt)
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        for i = 1, #arguments do
            this:add(arguments[i])
        end
        return this
    end

    function storage_mt:add(...)
        local arguments = {...}
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        for i = 1, #arguments do
            local b = true
            for j = 1, #self do
                if arguments[i] == self[j] then
                    b = false
                    break
                end
            end
            if b then table.insert(self, arguments[i]) end
        end
    end

    function storage_mt:destroy()
        self = nil
    end

    function storage_mt:search(item)
        for i = 1, #self do
            if item == self[i] then
                return i
            end
        end
    end

    function storage_mt:remove(item)
        for i = 1, #self do
            if item == self[i] then
                table.remove(self, i)
                break
            end
        end
    end

    function storage_mt:convert()
        local list = {}
        for i = 1, #self do
            list[i] = self[i]
        end
        return list
    end

    -- Valiador --
    valiador = setmetatable({}, {})
    local valiador_mt = getmetatable(valiador)
    valiador_mt.__index = valiador_mt

    local valiador_array = {}

    function valiador_mt:create(...)
        local this = {}
        setmetatable(this, valiador_mt)
        local arguments = {...}
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        for i = 1, #arguments do
            if type(arguments[i]) == 'string' then this.name = arguments[i] end
            if type(arguments[i]) == 'function' then this.code = arguments[i] end
        end
        valiador_array[this.name] = this
        return this
    end

    function valiador_mt:retrieve(name)
        return valiador_array[name]
    end

    function valiador_mt:apply(...)
        return self.code(...)
    end

    -- Effect --
    effect = setmetatable({}, {})
    local effect_mt = getmetatable(effect)
    effect_mt.__index = effect_mt

    local effect_array = {}

    function effect_mt:create(...)
        local this = {}
        setmetatable(this, effect_mt)
        local arguments = {...}
        if tableNotObject(arguments[1]) then arguments = arguments[1] end
        for i = 1, #arguments do
            if type(arguments[i]) == 'string' then this.name = arguments[i] end
            if type(arguments[i]) == 'function' then this.code = arguments[i] end
            if getmetatable(arguments[i]) == storage_mt then this.valiadors = arguments[i] end
        end
        effect_array[this.name] = this
        return this
    end

    function effect_mt:retrieve(name)
        return effect_array[name]
    end

    function effect_mt:apply(...)
        for i = 1, #self.valiadors do
            if not self.valiadors[i]:apply(...) then return end
        end
        self.code(...)
    end

    -- Score --
    function score(value, ...)
        local arguments = {...}
        local item = arguments[-1]
        table.remove(arguments)
        local list = aquireGameData(true, arguments)
        if type(list[item]) ~= 'number' and list[item] ~= nil then return end
        list[item] = (list[item] or 0) + value
    end

    function getScore(...)
        return aquireGameData(false, ...) or 0
    end

    -- Attribute --
    attribute = setmetatable({}, {})
    local attribute_mt = getmetatable(attribute)
    attribute_mt.__index = attribute_mt

    local attribute_array = {}

    function attribute_mt:create(name)
        local this = {}
        setmetatable(this, attribute_mt)
        this.name = name
        attribute_array[name] = this
        return this
    end

    function attribute_mt:retrieve(name)
        return attribute_array[name]
    end

    function attribute_mt:initEffect(item)
        if not self.initEffects then
            self.initEffects = storage:create()
        end
        self.initEffects:add(item)
    end

    function attribute_mt:removeEffect(item)
        if not self.removeEffects then
            self.removeEffects = storage:create()
        end
        self.removeEffects:add(item)
    end

    function attribute_mt:changeEffect(item)
        if not self.changeEffects then
            self.changeEffects = storage:create()
        end
        self.changeEffects:add(item)
    end

    function attribute_mt:change(parent, value)
        if value == 0 then return end
        local parameters = {}
        parameters.parent = parent
        parameters.attribute = self
        parameters.value = value
        if getScore(parent, "attribute", self) == 0 then
            for i = 1, #self.initEffects do
                self.initEffects[i]:apply(parameters)
            end
        end
        score(value, parent, "attribute", self)
        for i = 1, #self.changeEffects do
            self.changeEffects[i]:apply(parameters)
        end
        if getScore(parent, "attribute", self) == 0 then
            for i = 1, #self.removeEffects do
                self.removeEffects[i]:apply(parameters)
            end
        end
    end

    function attribute_mt:get(parent)
        return getScore(parent, "attribute", self) or 0
    end

    -- Event --
    event = setmetatable({}, {})
    local event_mt = getmetatable(event)
    event_mt.__index = event_mt

    local event_array = {}

    function event_mt:create(name, code)
        local this = {}
        setmetatable(this, event_mt)
        this.name = name
        this.code = code
        event_array[name] = this
        return this
    end

    function event_mt:retrieve(name)
        return event_array[name]
    end

    function event_mt:apply(parameters)
        self.code(parameters)
    end

    function event_mt:registerEffect(parent, Effect, stack)
        local orginalScore = getScore(parent, self, Effect)
        score(stack, parent, self, Effect)
        if orginalScore <= 0 and getScore(parent, self, Effect) > 0 then
            local t = aquireGameData(false, parent)
            if not t[self] then t[self] = storage:create() end
            t[self]:add(Effect)
        elseif orginalScore > 0 and getScore(parent, self, Effect) <= 0 then
            local t = aquireGameData(false, parent)
            if not t[self] then return end
            t[self]:remove(Effect)
        end
    end

    -- Behavior --
    local TICK = 0.03250000
    behavior = setmetatable({}, {})
    local behavior_mt = getmetatable(behavior)
    behavior_mt.__index = behavior_mt

    local behavior_storage = storage:create()
    local filtering = false
    local pending = storage:create()

    event_BehaviorApplied = event:create('BehaviorApplied', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters.target), parameters.target}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_BehaviorApplied)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_BehaviorRemoved = event:create('BehaviorRemoved', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters.target), parameters.target}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_BehaviorRemoved)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_BehaviorApplying = event:create('BehaviorApplying', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters.source), parameters.source}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_BehaviorApplying)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_BehaviorRemoving = event:create('BehaviorRemoving', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters.source), parameters.source}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_BehaviorRemoving)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    function behavior_mt:create(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        setmetatable(parameters, behavior_mt)
        table.insert(behavior_storage, parameters)
        local t = aquireGameData(true, parameters.source)
        if not t.behaviorApplying then t.behaviorApplying = storage:create() end
        t.behaviorApplying:add(parameters)
        t = aquireGameData(true, parameters.target)
        if not t.behaviorApplied then t.behaviorApplied = storage:create() end
        t.behaviorApplied:add(parameters)
        if parameters.linkBuff then
            score(1, parameters.target, "buffs", parameters.linkBuff)
            if getScore(parameters.target, "buffs", parameters.linkBuff) > 0 and not UnitHasBuffBJ(parameters.target, FourCC(parameters.linkBuff)) then
                unitApplyBuff(parameters.target, parameters.buffAbility, parameters.buffCommand)
            end
        end
        event_BehaviorApplying:apply(parameters)
        event_BehaviorApplied:apply(parameters)
        return parameters
    end

    function behavior_mt:destroy()
        for i = 1, #self.destroyEffects do
            self.destroyEffects[i]:apply(self)
        end
        event_BehaviorRemoving:apply(self)
        event_BehaviorRemoved:apply(self)
        if self.linkBuff then
            score(-1, self.target, "buffs", self.linkBuff)
            if getScore(self.target, "buffs", self.linkBuff) <= 0 and UnitHasBuffBJ(self.target, FourCC(self.linkBuff)) then
                UnitRemoveBuffBJ(self.target, FourCC(self.linkBuff))
            end
        end
        local t = aquireGameData(true, self.source, 'behaviorApplying')
        t:remove(self)
        t = aquireGameData(true, self.target, 'behaviorApplied')
        t:remove(self)
        behavior_storage:remove(self)
        self = nil
    end

    function behavior_mt:finish()
        pending:add(self)
    end

    function behavior_mt:search(target, name, source)
        local t = aquireGameData(false, target, "behaviorApplied")
        for i = 1, #t do
            if t[i].name == name then
                if not source then return t[i] end
                if t[i].source == source then return t[i] end
            end
        end
    end

    function behavior_mt:destroyPending()
        if filtering then return end
        while #pending > 0 do
            local list = pending:convert()
            pending:destroy()
            pending = storage:create()
            for i = 1, #list do
                list[i]:destroy()
            end
        end
    end

    onInitialization(function()
        local timer = CreateTimer()
        TimerStart(timer, TICK, true, function()
            behavior:destroyPending()

            local t = behavior_storage:convert()

            filtering = true
            for k, v in ipairs(t) do
                local r = false
                for i = 1, #v.valiadors do
                    if not v.valiadors[i]:apply(v) then
                        r = true
                        break
                    end
                end
                if v.linkBuff then
                    if v.buffControl and not UnitHasBuffBJ(v.target, FourCC(v.linkBuff)) then
                        r = true
                    elseif not v.buffControl and not UnitHasBuffBJ(v.target, FourCC(v.linkBuff)) then
                        unitApplyBuff(v.target, v.buffAbility, v.buffCommand)
                    end
                end
                if r then
                    v:finish()
                end
            end
            filtering = false

            behavior:destroyPending()

            t = nil
            t = behavior_storage:convert()

            filtering = true
            for k, v in pairs(t) do
                if v.duration then v.duration = v.duration - TICK end
                if v.period then
                    v.periodRemain = (v.periodRemain or v.period) - TICK
                    if v.periodRemain <= 0 then
                        v.periodRemain = v.period
                        for i = 1, #v.periodEffects do
                            v.periodEffects[i]:apply(v)
                        end
                    end
                end
                if v.duration <= 0 then
                    v:finish()
                end
            end
            filtering = false

            behavior:destroyPending()
        end)
    end)
end

-- Shield --
do
    attribute_Shield = attribute:create('shield')
    attribute_MaxShield = attribute:create('maxShield')
    effect_ShieldUpdate = effect:create('shieldUpdate', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        if attribute_Shield:get(parameters.parent) > attribute_MaxShield:get(parameters.parent) then
            attribute_Shield:change(parameters.parent, attribute_MaxShield:get(parameters.parent) - attribute_Shield:get(parameters.parent))
        end
    end)
    effect_AddMaxShield = effect:create('addMaxShield', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        attribute_Shield:change(parameters.parent, parameters.value)
    end)

    attribute_Shield:changeEffect(effect_ShieldUpdate)
    attribute_MaxShield:changeEffect(effect_AddMaxShield)
    attribute_MaxShield:changeEffect(effect_ShieldUpdate)
end

-- Unit Management --
do
    local unitGenerate = nil
    local unitDeath = nil
    local unitDecay = nil

    event_UnitInit = event:create('UnitInit', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters[1]), parameters[1]}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_UnitInit)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_UnitKilled = event:create('UnitKilled', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters[2]), parameters[2]}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_UnitKilled)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_UnitKilling = event:create('UnitKilling', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters[1]), parameters[1]}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_UnitKilling)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_UnitDecay = event:create('UnitDecay', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', GetOwningPlayer(parameters[1]), parameters[1]}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_UnitDecay)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    onInitialization(function()
        unitGenerate = CreateTrigger()
        unitDeath = CreateTrigger()
        unitDecay = CreateTrigger()
        local region=CreateRegion()
        local rect = GetWorldBounds()
        RegionAddRect(region, rect)
        TriggerRegisterEnterRegionSimple(unitGenerate, region)
        RemoveRect(rect)
        TriggerRegisterAnyUnitEventBJ(unitDeath, EVENT_PLAYER_UNIT_DEATH)
        TriggerRegisterAnyUnitEventBJ(unitDecay, EVENT_PLAYER_UNIT_DECAY)
        TriggerAddCondition(unitGenerate, Filter(function()
            local unit = GetTriggerUnit()
            event_UnitInit:apply(unit)
        end))
        TriggerAddCondition(unitDeath, Filter(function()
            local unit = GetTriggerUnit()
            local killer = GetKillingUnit()
            if killer then
                event_UnitKilling:apply(killer, unit)
            end
            event_UnitKilled:apply(killer, unit)
        end))
        TriggerAddCondition(triggerDecay, Filter(function()
            local unit = GetTriggerUnit()
            event_UnitDecay:apply(unit)
            game[unit]=nil
        end))
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local group = CreateGroup()
            GroupEnumUnitsOfPlayer(group, Player(i), Filter(function()
                local unit = GetFilterUnit()
                event_UnitInit:apply(unit)
            end))
        end
    end)
end

-- Damage --
do
    local trigger = nil

    local location = Location(0, 0)

    local damageconstants = {{1.00, 1.00, 1.00, 1.00, 1.00, 0.75, 0.05, 1.00}, {1.00, 1.50, 1.00, 0.70, 1.00, 1.00, 0.05, 1.00}, {2.00, 0.75, 1.00, 0.35, 1.00, 0.50, 0.05, 1.50}, {1.00, 0.50, 1.00, 1.50, 1.00, 0.50, 0.05, 1.50}, {1.25, 0.75, 2.00, 0.35, 1.00, 0.50, 0.05, 1.00}, {1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00}, {1.00, 1.00, 1.00, 0.50, 1.00, 1.00, 0.05, 1.00}}

    local ethernalconstants = {0, 0, 0, 1.66, 0, 1.66, 0}

    DamageCategories = {"DAMAGE_CAT_PHYSICAL", "DAMAGE_CAT_ARCANE", "DAMAGE_CAT_FIRE", "DAMAGE_CAT_FROST", "DAMAGE_CAT_NATURAL", "DAMAGE_CAT_SHADOW", "DAMAGE_CAT_CHAOS", "DAMAGE_CAT_DIVINE", "DAMAGE_CAT_UNIVERSAL"}

    function AttackTypeToInteger(attacktype)
        for i=0, 6 do
            if attacktype == ConvertAttackType(i) then return i end
        end
    end

    event_Damaging_1 = event:create('Damaging1', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_1)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaging_2 = event:create('Damaging2', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_2)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaging_3 = event:create('Damaging3', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_3)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaging_4 = event:create('Damaging4', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_4)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaging_5 = event:create('Damaging5', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_5)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaging_6 = event:create('Damaging6', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.source.player, parameters.source.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaging_6)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_1 = event:create('Damaged1', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_1)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_2 = event:create('Damaged2', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_2)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_3 = event:create('Damaged3', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_3)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_4 = event:create('Damaged4', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_4)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_5 = event:create('Damaged5', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_5)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    event_Damaged_6 = event:create('Damaged6', function(...)
        local parameters = {...}
        if tableNotObject(parameters[1]) then parameters = parameters[1] end
        local effects = storage:create()
        local parents = {'global', parameters.target.player, parameters.target.unit}
        for i = 1, #parents do
            local t = aquireGameData(false, parents[i], event_Damaged_6)
            for j = 1, #t do
                effects:add(t[j])
            end
        end
        for i = 1, #effects do
            effects[i]:apply(parameters)
        end
        effects:destroy()
    end)

    local function ConvertDamageCat(damagetype)
        local i = 0
        if damagetype == DAMAGE_TYPE_NORMAL then i = 1 end
        if damagetype == DAMAGE_TYPE_ENHANCED then i = 1 end
        if damagetype == DAMAGE_TYPE_FIRE then i = 3 end
        if damagetype == DAMAGE_TYPE_COLD then i = 4 end
        if damagetype == DAMAGE_TYPE_LIGHTNING then i = 5 end
        if damagetype == DAMAGE_TYPE_POISON then i = 5 end
        if damagetype == DAMAGE_TYPE_DISEASE then i = 5 end
        if damagetype == DAMAGE_TYPE_DIVINE then i = 8 end
        if damagetype == DAMAGE_TYPE_MAGIC then i = 2 end
        if damagetype == DAMAGE_TYPE_SONIC then i = 1 end
        if damagetype == DAMAGE_TYPE_ACID then i = 5 end
        if damagetype == DAMAGE_TYPE_FORCE then i = 1 end
        if damagetype == DAMAGE_TYPE_DEATH then i = 6 end
        if damagetype == DAMAGE_TYPE_MIND then i = 6 end
        if damagetype == DAMAGE_TYPE_PLANT then i = 5 end
        if damagetype == DAMAGE_TYPE_DEFENSIVE then i = 1 end
        if damagetype == DAMAGE_TYPE_DEMOLITION then i = 1 end
        if damagetype == DAMAGE_TYPE_SLOW_POISON then i = 5 end
        if damagetype == DAMAGE_TYPE_SPIRIT_LINK then i = 9 end
        if damagetype == DAMAGE_TYPE_SHADOW_STRIKE then i = 5 end
        if damagetype == DAMAGE_TYPE_UNIVERSAL then i = 9 end
        if i == 0 then return 'DAMAGE_CAT_UNIVERSAL' end
        return DamageCategories[i]
    end

    local function GetUnitZ(unit)
        MoveLocation(location, GetUnitX(unit), GetUnitY(unit))
        return GetUnitFlyHeight(unit) + GetLocationZ(location)
    end

    function DamageUnit(source,target,value,attackType,damageType,flags)
        local parameters = {}
        parameters.source = {}
        parameters.target = {}
        parameters.value = value
        parameters.damageToHull = value
        parameters.attackType = attackType
        parameters.damageType = damageType
        parameters.flags = flags or storage:create()

        parameters.source.unit = source
        parameters.source.player = GetOwningPlayer(source)
        parameters.source.handle = GetHandleId(source)
        parameters.source.id = GetUnitTypeId(source)
        parameters.source.x = GetUnitX(source)
        parameters.source.y = GetUnitY(source)
        parameters.source.z = GetUnitZ(source)

        parameters.target.unit = target
        parameters.target.player = GetOwningPlayer(target)
        parameters.target.handle = GetHandleId(target)
        parameters.target.id = GetUnitTypeId(target)
        parameters.target.x = GetUnitX(target)
        parameters.target.y = GetUnitY(target)
        parameters.target.z = GetUnitZ(target)

        parameters.modifiers = 0.00
        parameters.factors = 1.00
        parameters.ignorarmor = false

        event_Damaging_1:apply(parameters)
        event_Damaged_1:apply(parameters)

        if parameters.flags:search('DAMAGE_FLAG_ATTACK') and not parameters.ignorarmor then
            if BlzGetUnitArmor(parameters.target.unit) > 0 then
                parameters.value = parameters.value * (1.00- ((BlzGetUnitArmor(parameters.target.unit) * 0.06) / (BlzGetUnitArmor(parameters.target.unit) * 0.06 +1 )))
            elseif BlzGetUnitArmor(parameters.target.unit) < 0 then
                parameters.value = parameters.value * (2- ( 0.94 ^ (-1 * BlzGetUnitArmor(parameters.target.unit))))
            end
        end
        if not parameters.ignorarmor then
            parameters.value = parameters.value * damageconstants[AttackTypeToInteger(parameters.attackType) + 1][BlzGetUnitIntegerField(parameters.target.unit, UNIT_IF_DEFENSE_TYPE) + 1]
        end
        if IsUnitType(parameters.target.unit,UNIT_TYPE_ETHEREAL) then
            parameters.value=parameters.value * ethernalconstants[AttackTypeToInteger(parameters.attackType) + 1]
        end

        if parameters.value == 0.00 then return end

        event_Damaging_2:apply(parameters)
        event_Damaged_2:apply(parameters)

        event_Damaging_3:apply(parameters)
        event_Damaged_3:apply(parameters)

        event_Damaging_4:apply(parameters)
        event_Damaged_4:apply(parameters)

        event_Damaging_5:apply(parameters)
        event_Damaged_5:apply(parameters)

        parameters.damageToHull = parameters.value

        if attribute:retireve('shield'):get(parameters.target.unit) > 0 then
            local shield = attribute:retireve('shield'):get(parameters.target.unit)
            local shieldDamage = parameters.value
            if shieldDamage > shield then shieldDamage = shield end
            parameters.value = parameters.value - shieldDamage
            attribute:retireve('shield'):change(parameters.target.unit, -1 * shieldDamage)
        end

        UnitDamageTarget(parameters.source.unit, parameters.target.unit, parameters.value, false, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_UNKNOWN, WEAPON_TYPE_WHOKNOWS)

        if event.value>0 and displayDamageValue then
            local text = I2S(R2I(parameters.value))
            local color = 'ffffffff'
            if parameters.flags:search('DAMAGE_FLAG_ATTACK') then
                color = 'ffff0000'
            end
            if parameters.flags:search('DAMAGE_FLAG_SPELL') then
                color = 'ffff00ff'
            end
            ArcingTextTag('|c' .. color .. text .. '|r', parameters.target.unit)
        end

        event_Damaging_6:apply(parameters)
        event_Damaged_6:apply(parameters)
    end

    onInitialization(function()
        trigger = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_UNIT_DAMAGED)

        TriggerAddCondition(trigger,Filter(function()
            if GetEventDamage() == 0 or BlzGetEventDamageType() == DAMAGE_TYPE_UNKNOWN then
                return
            end

            if GetEventDamage() <= 0.001 then
                BlzSetEventDamage(0.00)
                return
            end

            local flags = storage:create()
            if BlzGetEventAttackType() == ATTACK_TYPE_NORMAL then
                flags:add("DAMAGE_FLAG_SPELL")
            else
                flags:add("DAMAGE_FLAG_ATTACK")
            end

            flags:add(ConvertDamageCat(BlzGetEventDamageType()))

            DamageUnit(GetEventDamageSource(), GetTriggerUnit(), GetEventDamage(), BlzGetEventAttackType(), BlzGetEventDamageType(), flags)

            BlzSetEventDamage(0.00)
        end))
    end)
end

-- Advanced Selection --
do
    local function LocIsAlly(u, p)
        return IsUnitAlly(u, p)
    end
    local function LocIsEnemy(u, p)
        return IsUnitEnemy(u, p)
    end
    local function LocIsBiological(u, p)
        return not IsUnitType(u, UNIT_TYPE_MECHANICAL)
    end
    local function LocIsMechanical(u, p)
        return IsUnitType(u, UNIT_TYPE_MECHANICAL)
    end
    local function LocIsNonHero(u, p)
        return not IsUnitType(u, UNIT_TYPE_HERO)
    end
    local function LocIsHero(u, p)
        return IsUnitType(u, UNIT_TYPE_HERO)
    end
    local function LocIsMagicVulnerable(u, p)
        return not IsUnitType(u, UNIT_TYPE_MAGIC_IMMUNE)
    end
    local function LocIsMagicImmune(u, p)
        return IsUnitType(u, UNIT_TYPE_MAGIC_IMMUNE)
    end
    local function LocIsNonStructure(u, p)
        return not IsUnitType(u, UNIT_TYPE_STRUCTURE)
    end
    local function LocIsStructure(u, p)
        return IsUnitType(u, UNIT_TYPE_STRUCTURE)
    end
    local function LocIsVulnerable(u, p)
        return not BlzIsUnitInvulnerable(u)
    end
    local function LocIsInvulnerable(u, p)
        return BlzIsUnitInvulnerable(u)
    end
    local function LocIsGround(u, p)
        return IsUnitType(u, UNIT_TYPE_GROUND)
    end
    local function LocIsAir(u, p)
        return IsUnitType(u, UNIT_TYPE_FLYING)
    end

    function filterTable(t,f,p)
        local r = storage:create()
        local e = {}
        for k, v in ipairs(f) do
            if v=="ally" then
                table.insert(e, LocIsAlly)
            elseif v=="enemy" then
                table.insert(e, LocIsEnemy)
            elseif v=="biological" then
                table.insert(e, LocIsBiological)
            elseif v=="mechanical" then
                table.insert(e, LocIsMechanical)
            elseif v=="non-hero" then
                table.insert(e, LocIsNonHero)
            elseif v=="hero" then
                table.insert(e, LocIsHero)
            elseif v=="magic-vulnerable" then
                table.insert(e, LocIsMagicVulnerable)
            elseif v=="magic-immune" then
                table.insert(e, LocIsMagicImmune)
            elseif v=="vulnerable" then
                table.insert(e, LocIsVulnerable)
            elseif v=="invulnerable" then
                table.insert(e, LocIsInvulnerable)
            elseif v=="non-structure" then
                table.insert(e, LocIsNonStructure)
            elseif v=="structure" then
                table.insert(e, LocIsStructure)
            elseif v=="ground" then
                table.insert(e, LocIsGround)
            elseif v=="air" then
                table.insert(e, LocIsAir)
            end
        end
        for k, v in ipairs(t) do
            local access=true
            for i, u in ipairs(e) do
                if not u(v, p) then
                    access=false
                    break
                end
            end
            if access then r:add(v) end
        end
        return r
    end

    function getUnitsInRangeCollision(x, y, radius)
        local group = CreateGroup()
        GroupEnumUnitsInRange(group, x, y, radius+450, nil)
        local list = Group2Table(group)
        DestroyGroup(group)

        for k, v in ipairs(list) do
            local distance = SquareRoot((x-GetUnitX(v)) ^ 2 + (y-GetUnitY(v)) ^ 2)
            if distance - BlzGetUnitCollisionSize(v) > radius then list[k] = nil end
        end

        local r = storage:create()
        for _, v in ipairs(list) do r:add(v) end

        return r
    end

    function getUnitsInRangeOfUnitCollision(unit, radius)
        local group = CreateGroup()
        local x = GetUnitX(unit)
        local y = GetUnitY(unit)
        GroupEnumUnitsInRange(group, x, y, radius+450, nil)
        local list = Group2Table(group)
        DestroyGroup(group)

        for k, v in ipairs(list) do
            local distance = SquareRoot((x-GetUnitX(v)) ^ 2 + (y-GetUnitY(v)) ^ 2)
            if distance - BlzGetUnitCollisionSize(unit) - BlzGetUnitCollisionSize(v) > radius then list[k] = nil end
        end

        local r = storage:create()
        for _, v in ipairs(list) do
            r:add(v)
        end

        return r
    end

    function getUnitsInRangeOfLineCollision(x1, y1, x2, y2, radius)
        if x1-x2 == 0 then x1 = x2 + 0.05 end
        local k = (y1 - y2)/(x1 - x2)
        local b = y1 - k * x1
        local group = CreateGroup()
        GroupEnumUnitsInRange(group, (x1 + x2) / 2, (y1 + y2) / 2, 0.5 * SquareRoot((x1 - x2) ^ 2 + (y1 - y2) ^ 2) + radius + 450, nil)
        local list = Group2Table(group)
        DestroyGroup(group)
        for i, u in ipairs(list) do
            local distance = (k * GetUnitX(u) + b - GetUnitY(u)) / SquareRoot(1 + k ^ 2)
            if distance < 0 then distance = -1 * distance end
            if distance - BlzGetUnitCollisionSize(u) > radius then list[i] = nil end
        end

        local r = storage:create()
        for _, v in pairs(list) do
            r:add(v)
        end

        return r
    end
end