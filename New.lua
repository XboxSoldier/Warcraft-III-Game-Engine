-- Debug
do
    debugCount = 0
end

-- Basic Data Methods
do
    local old = type
    function type(v)
        local result = old(v)
        if old(v) == 'table' and v.type ~= nil then return v.type end
        return result
    end

    function through(container)
        local index = 0
        if type(container) == 'array' then
            local count = container.length
            return function()
                index = index + 1
                if index <= count then
                    return index - 1, container._content[index]
                end
            end
        elseif type(container) == 'set' then
            local count = container.size
            return function()
                index = index + 1
                if index <= count then
                    return index - 1, container._values[index]
                end
            end
        elseif type(container) == 'map' then
            local count = container.size
            return function()
                index = index + 1
                if index <= count then
                    return container._keys[index], container._values[index]
                end
            end
        elseif type(container) == 'table' then
            local count = #container
            return function()
                index = index + 1
                if index <= count then
                    return index, container[index]
                end
            end
        end
        return function() return nil end
    end
end

-- Array
do
    Array = {type = 'array'}

    local arrayMT = {__call = function(this, ...)
        local newArray = {}
        newArray._content = {...}
        newArray.length = #newArray._content
        setmetatable(newArray, Array)
        return newArray
    end}

    setmetatable(Array, arrayMT)

    function Array.__index(this, key)
        if Array[key] ~= nil then return Array[key] end
        if type(key) ~= 'number' then return nil end
        return this._content[key + 1]
    end

    function Array._newindex(this, key, value)
        if type(key) ~= 'number' then return end
        if key > this.length then key = this.length end
        if this._content[key + 1] == nil then
            this.length = this.length + 1
        end
        this._content[key + 1] = value
    end

    function Array:pop()
        if self.length == 0 then return nil end
        self.length = self.length - 1
        return table.remove(self._content, self.length + 1)
    end

    function Array:push(value)
        self.length = self.length + 1
        self._content[self.length] = value
        return self.length
    end

    function Array:shift()
        if self.length == 0 then return nil end
        self.length = self.length - 1
        return table.remove(self._content, 1)
    end

    function Array:unshift(value)
        self.length = self.length + 1
        table.insert(self._content, 1, value)
        return self.length
    end

    function Array:splice(start, delete, ...)
        local arguments = Array(...)
        local deleted = Array()
        if start < 0 then start = start + self.length end
        if start < 0 then return deleted end
        if start > self.length then start = self.length end
        start = start + 1
        for i = 1, delete do
            if self._content[start] == nil then break end
            self.length = self.length - 1
            deleted:push(table.remove(self._content, start))
        end
        local move = arguments.length - 1
        while move >= 0 do
            self.length = self.length + 1
            table.insert(self._content, start, arguments[move])
            move = move - 1
        end
        return deleted
    end

    function Array:concat(...)
        local arguments = Array(self, ...)
        local array = Array()
        for _, v in through(arguments) do
            for _, w in through(v) do
                array:push(v, w)
            end
        end
        return array
    end

    function Array:slice(start, finish)
        local array = Array()
        if start == nil then start = 0 end
        if finish == nil then finish = self.length end
        if start < 0 then start = start + self.length end
        if start < 0 then return array end
        if finish < 0 then finish = finish + self.length end
        if finish < 0 then return array end
        start = start + 1
        array = Array(table.unpack(self._content, start, finish))
        return array
    end

    function Array:forEach(func, ...)
        for k, v in through(self) do
            func(v, k, ...)
        end
        return self
    end

    function Array:unpack()
        return table.unpack(self._content, 1, self.length)
    end
end

-- Set
do
    Set = {type = 'set'}

    local setMT = {__call = function(this, array)
        local newSet = {}
        newSet._values = {}
        newSet._entries = {}
        newSet.size = 0
        setmetatable(newSet, Set)
        for _, v in through(array) do
            newSet:add(v)
        end
        return newSet
    end}

    setmetatable(Set, setMT)

    function Set.__index(this, key)
        if Set[key] ~= nil then return Set[key] end
        if type(key) ~= 'number' then return nil end
        return this._values[key + 1]
    end

    function Set.__newindex(this, key, value)
        if Set[key] ~= nil then return end
        this:add(value)
    end

    function Set:valueAt(index)
        return self._values[index + 1]
    end

    function Set:add(value)
        if self._entries[value] ~= nil then return self.size end
        self.size = self.size + 1
        self._values[self.size] = value
        self._entries[value] = self.size
        return self.size
    end

    function Set:has(value)
        return self._entries[value] ~= nil
    end

    function Set:delete(value)
        if self._entries[value] == nil then return end
        local i = self._entries[value]
        self.size = self.size - 1
        table.remove(self._values, i)
        self._entries[value] = nil
        for j = i, self.size do
            self._entries[self._values[j]] = j
        end
        return self
    end

    function Set:clear()
        self._values = {}
        self._entries = {}
        self.size = 0
        return self
    end

    function Set:entries()
        return Array(table.unpack(self._values, 1, self.size))
    end

    Set.values = Set.entries
    Set.keys = Set.values

    function Set:forEach(func, ...)
        for k, v in through(self) do
            func(v, k, ...)
        end
        return self
    end

    function Set:unpack()
        return table.unpack(self._values, 1, self.size)
    end
end

-- Map
do
    Map = { type = 'map' }

    local mapMT = { __call = function(this, array)
        local newMap = {}
        newMap._entries = {}
        newMap._keys = {}
        newMap._values = {}
        newMap.size = 0
        setmetatable(newMap, Map)
        for _, v in through(array) do
            newMap:set(v[0], v[1])
        end
        return newMap
    end }

    setmetatable(Map, mapMT)

    function Map.__index(this, key)
        if Map[key] ~= nil then
            return Map[key]
        end
        if this._entries[key] == nil then return nil end
        return this._values[this._entries[key]]
    end

    function Map.__newindex(this, key, value)
        if Map[key] ~= nil then return end
        if value == nil then
            this:delete(key)
            return
        end
        if this._entries[key] == nil then
            this.size = this.size + 1
            this._keys[this.size] = key
            this._entries[key] = this.size
        end
        this._values[this._entries[key]] = value
    end

    function Map:get(key)
        if Map[key] ~= nil then
            return Map[key]
        end
        if self._entries[key] == nil then return nil end
        return self._values[self._entries[key]]
    end

    function Map:set(key, value)
        if Map[key] ~= nil then return end
        if value == nil then
            self:delete(key)
            return
        end
        if self._entries[key] == nil then
            self.size = self.size + 1
            self._keys[self.size] = key
            self._entries[key] = self.size
        end
        self._values[self._entries[key]] = value
        return self
    end

    function Map:has(key)
        return self._entries[key] ~= nil
    end

    function Map:clear()
        self._entries = {}
        self._keys = {}
        self._values = {}
        self.size = 0
        return self
    end

    function Map:delete(key)
        if self._entries[key] == nil then return end
        local i = self._entries[key]
        local value = table.remove(self._values, i)
        table.remove(self._keys, i)
        self._entries[key] = nil
        self.size = self.size - 1
        for j = i, self.size do
            self._entries[self._keys[j]] = j
        end
        return value
    end

    function Map:entries()
        local array = Array()
        for k, v in through(self) do
            array:push(Array(k, v))
        end
        return array
    end

    function Map:keys()
        return Array(table.unpack(self._keys))
    end

    function Map:values()
        return Array(table.unpack(self._values))
    end

    function Map:forEach(func, ...)
        for k, v in through(self) do
            func(v, k, ...)
        end
        return self
    end
end

-- storage
do
    gameStorage = Map()

    function getStorage(fill, fallback, ...)
        local arguments = Array(...)
        local current = gameStorage
        for i = 0, arguments.length - 2 do
            if current[arguments[i]] == nil then
                if fill then current[arguments[i]] = Map()
                else return nil end
            end
            if type(current[arguments[i]]) ~= 'map' then return nil end
            current = current[arguments[i]]
        end
        if current[arguments[arguments.length - 1]] == nil then
            if fallback == nil then return nil end
            current[arguments[arguments.length - 1]] = fallback
        end
        return current[arguments[arguments.length - 1]]
    end

    function writeStorage(...)
        local arguments = Array(...)
        if arguments.length < 2 then return end
        local value = arguments:pop()
        local key = arguments:pop()
        getStorage(true, Map(), arguments:unpack())[key] = value
    end
end

do
    local old = InitBlizzard

    local list = Set()

    function init(func)
        if type(func) == 'function' then
            list:add(func)
        end
    end

    function InitBlizzard()
        old()
        if debugCount ~= 0 then print(debugCount) end
        for _,v in through(list) do
            v()
        end
    end
end

-- Timer
do
    Timer = { type = 'timer' }

    TICK = 0.02500000

    local timerMT = { __call = function(this)
        local newTimer = {}
        setmetatable(newTimer, Timer)
        return newTimer
    end }

    local activeTimers = Set()
    local garbageBin = Set()

    setmetatable(Timer, timerMT)

    Timer.__index = Timer

    function Timer:start(duration, period, parameters, func)
        self.status = Map()
        self.status.flags = Set()
        self.status.speed = 1
        self.status.parameters = parameters
        self.status.period = period
        self.status.duration = duration
        self.status.durationLeft = duration
        self.status.func = func
        activeTimers:add(self)
        return self
    end

    function Timer:setFlag(flag)
        self.status.flags:add(flag)
        return self
    end

    function Timer:removeFlag(flag)
        self.status.flags:delete(flag)
        return self
    end

    function Timer:finish()
        activeTimers:delete(self)
        garbageBin:add(self)
        return self
    end

    function Timer:recycle()
        local array
        ::recycle::
        array = garbageBin:entries()
        garbageBin:clear()
        if garbageBin.size > 0 then goto recycle end
    end

    function Timer:tick()
        if self.status.flags:has('paused') then return end
        self.status.durationLeft = self.status.durationLeft - TICK * self.status.speed
        if self.status.durationLeft <= 0 then
            self.status.func(self.status.parameters, self)
            if self.status.period then
                self.status.durationLeft = self.status.duration
            else
                activeTimers:delete(self)
            end
        end
        return self
    end

    init(function()
        local centralTimer = CreateTimer()
        TimerStart(centralTimer, TICK, true, function()
            Timer:recycle()
            local array = activeTimers:entries()
            for _, v in through(array) do
                v:tick()
            end
        end)
    end)
end

-- Valiador
do
    Valiador = { type = 'valiador' }

    valiadors = Map()

    local valiadorMT = { __call = function(this, name, func)
        local newValiador = {}
        newValiador.name = name
        newValiador.func = func
        setmetatable(newValiador, Valiador)
        valiadors[name] = newValiador
        return newValiador
    end }

    setmetatable(Valiador, valiadorMT)

    Valiador.__index = Valiador

    function Valiador.__call(this, parameters)
        return this.func(parameters) == true
    end
end

-- Effect
do
    Effect = { type = 'effect' }

    effects = Map()

    local effectMT = { __call = function(this, name, func)
        local newEffect = {}
        newEffect.name = name
        newEffect.func = func
        newEffect.valiadors = Set()
        setmetatable(newEffect, Effect)
        effects[name] = newEffect
        return newEffect
    end }

    setmetatable(Effect, effectMT)

    Effect.__index = Effect

    function Effect.__call(this, parameters)
        for _, v in through(this.valiadors) do
            if not v(parameters) then return false end
        end
        this.func(parameters)
        return true
    end

    function Effect:addValiador(valiador)
        self.valiadors:add(valiador)
        return self
    end
end

do
    function score(parent, namespace, key, value)
        local map = getStorage(true, Map(), parent, 'scores', namespace)
        map[key] = (map[key] or 0) + value
        return map[key]
    end

    function getScore(parent, namespace, key)
        local map = getStorage(false, nil, parent, 'scores', namespace) or Map()
        return map[key] or 0
    end

    function addStoredItem(parent, namespace, key, element)
        getStorage(true, Set(), parent, 'storages', namespace, key):add(element)
    end

    function listStoredItem(parent, namespace, key)
        return getStorage(false, nil, parent, 'storages', namespace, key) or Set()
    end
end

-- Event
do
    Event = { type = 'event' }

    events = Map()

    local eventMT = { __call = function(this, name)
        local newEvent = {}
        newEvent.name = name
        setmetatable(newEvent, Event)
        events[name] = newEvent
        return newEvent
    end }

    setmetatable(Event, eventMT)

    Event.__index = Event

    function Event.__call(this, parents, parameters)
        parents:unshift('global')
        local effects = Set()
        for _, i in through(parents) do
            local storage = listStoredItem(i, 'events', this)
            for _, j in through(storage) do
                effects:add(j)
            end
        end
        for _, v in through(effects) do
            v(parameters)
        end
    end

    function Event:register(parent, effect, stack)
        if stack == 0 then return end
        local old = getScore(parent, self, effect)
        local new = score(parent, self, effect, stack)
        if (old * new) > 0 then return end
        if new > 0 then
            addStoredItem(parent, 'events', self, effect)
            return
        end
        if old > 0 then
            addStoredItem(parent, 'events', self, effect)
        end
        return self
    end
end

-- Attribute
do
    Attribute = { type = 'attribute' }

    attributes = Map()

    local attributeMT = { __call = function(this, name, range)
        local newAttribute = {}
        newAttribute.name = name
        newAttribute.range = range or Array()
        newAttribute.init = Set()
        newAttribute.change = Set()
        newAttribute.remove = Set()
        setmetatable(newAttribute, Attribute)
        attributes[name] = newAttribute
        return newAttribute
    end }

    setmetatable(Attribute, attributeMT)

    Attribute.__index = Attribute

    function Attribute:newInit(effect)
        self.init:add(effect)
        return self
    end

    function Attribute:newChange(effect)
        self.change:add(effect)
        return self
    end

    function Attribute:newRemove(effect)
        self.remove:add(effect)
        return self
    end

    function Attribute:get(parent)
        return getScore(parent, 'attributes', self)
    end

    function Attribute.__call(this, parent, value)
        if value == 0 then return end
        local event = Map(Array(
            Array('source', parent),
            Array('target', parent),
            Array('value', value),
            Array('name', 'attributeChange'),
            Array('before', this:get(parent)),
            Array('after', this:get(parent) + value)
        ))
        if this.range[0] ~= nil and event.after < this.range[0] then
            event.after = this.range[0]
            event.value = event.after - event.before
        elseif this.range[1] ~= nil and event.after > this.range[1] then
            event.after = this.range[1]
            event.value = event.after - event.before
        end
        score(parent, 'attributes', this, event.value)
        if event.before == 0 then
            for _, v in through(this.init) do
                v(event)
            end
        end
        for _, v in through(this.change) do
            v(event)
        end
        if event.after == 0 then
            for _, v in through(this.remove) do
                v(event)
            end
        end
        return event.after
    end
end

-- Behavior
do
    Behavior = { type = 'behavior' }

    behaviors = Set()
    local garbageBin = Set()

    EVENT_BEHAVIOR_APPLY = Event('behaviorApply')
    EVENT_BEHAVIOR_APPLIED = Event('behaviorApplied')

    EVENT_BEHAVIOR_REMOVE = Event('behaviorRemove')
    EVENT_BEHAVIOR_REMOVED = Event('behaviorRemoved')

    behaviorMT = { __call = function(this, parameters)
        local newBehavior = {}
        for k, v in through(parameters) do
            newBehavior[k] = v
        end
        newBehavior.durationLeft = newBehavior.duration
        newBehavior.periodLeft = newBehavior.period
        newBehavior.flags = newBehavior.flags or Set()
        setmetatable(newBehavior, Behavior)
        behaviors:add(newBehavior)
        getStorage(true, Set(), newBehavior.source, 'behaviors'):add(newBehavior)
        getStorage(true, Set(), newBehavior.target, 'behaviods'):add(newBehavior)
        if newBehavior.linkedBuff ~= nil then
            print(score(newBehavior.target, 'buffs', newBehavior.linkedBuff, 1))
            if getScore(newBehavior.target, 'buffs', newBehavior.linkedBuff) > 0 then
                Dummy(newBehavior.target, newBehavior.linkedBuffAbility, newBehavior.linkedBuffOrder, 1)
            end
        end
        EVENT_BEHAVIOR_APPLY(Array(GetOwningPlayer(newBehavior.source), newBehavior.source), newBehavior)
        EVENT_BEHAVIOR_APPLIED(Array(GetOwningPlayer(newBehavior.target), newBehavior.target), newBehavior)
        return newBehavior
    end }

    setmetatable(Behavior, behaviorMT)

    Behavior.__index = Behavior

    function Behavior.__call(this)
        if this.period then
            this.periodLeft = this.periodLeft - TICK
            if this.periodLeft <= 0 then
                for _, v in through(this.periodEffects) do
                    v(this)
                end
                this.periodLeft = this.period
            end
        end
        if this.duration then
            this.durationLeft = this.durationLeft - TICK
            if this.durationLeft <= 0 then this:finish() end
        end
    end

    function Behavior:setFlag(flag)
        self.flags:add(flag)
        return self
    end

    function Behavior:removeFlag(flag)
        self.flags:delete(flag)
        return self
    end

    function Behavior:finish()
        self.flags:add('finished')
        garbageBin:add(self)
        return self
    end

    function Behavior:destroy()
        getStorage(true, Set(), self.source, 'behaviors'):delete(self)
        getStorage(true, Set(), self.target, 'behaviods'):delete(self)
        behaviors:delete(self)
        if self.linkedBuff ~= nil then
            print(score(self.target, 'buffs', self.linkedBuff, -1))
            if getScore(self.target, 'buffs', self.linkedBuff) <= 0 then
                UnitRemoveBuffBJ(self.linkedBuff, self.target)
            end
        end
        for _, v in through(self.finishEffects) do
            v(self)
        end
        EVENT_BEHAVIOR_REMOVE(Array(GetOwningPlayer(self.source), self.source), self)
        EVENT_BEHAVIOR_REMOVED(Array(GetOwningPlayer(self.target), self.target), self)
    end

    function Behavior:recycle()
        local array
        ::recycle::
        array = garbageBin:entries()
        garbageBin:clear()
        for _, v in through(array) do
            v:destroy()
        end
        if garbageBin.size > 0 then goto recycle end
    end

    function Behavior:search(target, parameters, source)
        local storage
        if source then
            storage = getStorage(false, nil, target, 'behaviors')
        else
            storage = getStorage(false, nil, target, 'behaviods')
        end
        if storage == nil then return nil end
        for _, i in through(storage) do
            if i.flags:has('finished') then goto continue end
            for k, v in through(parameters) do
                if i[k] ~= v then goto continue end
            end
            repeat
                return i
            until true
            ::continue::
        end
        return nil
    end

    init(function()
        local timer = Timer()
        timer:start(TICK, true, Map(), function(parameters)
            Behavior:recycle()
            local array = behaviors:entries()
            for _, i in through(array) do
                if (not units:has(i.source)) or (not units:has(i.target)) then
                    i:finish()
                    goto exit
                end
                if i.linkedBuff and (not UnitHasBuffBJ(i.target, i.linkedBuff)) then
                    if i.buffLocked then
                        i:finish()
                        goto exit
                    else
                        if getScore(i.target, 'buffs', i.linkedBuff) > 0 then
                            Dummy(i.target, i.linkedBuffAbility, i.linkedBuffOrder, 1)
                        end
                    end
                end
                for _, v in through(i.valiadors) do
                    if not v(i) then
                        i:finish()
                        goto exit
                    end
                end
                ::exit::
            end
            Behavior:recycle()
            array = behaviors:entries()
            for _, i in through(array) do
                i()
            end
            Behavior:recycle()
        end)
        timer:setFlag('global')
    end)
end

-- Units
do
    units = Set()

    destructableAbility = FourCC('A000')
    destructables = Set()

    projectileAbility = FourCC('A001')
    projectiles = Set()

    specialEffectAbility = FourCC('A002')
    specialEffects = Set()
end

-- Map Bounds
do
    MapBounds = setmetatable({}, {})

    WorldBounds = setmetatable({}, getmetatable(MapBounds))

    local mt = getmetatable(MapBounds)
    mt.__index = mt

    function mt:getRandomX()
        return GetRandomReal(self.minX, self.maxX)
    end

    function mt:getRandomY()
        return GetRandomReal(self.minY, self.maxY)
    end

    local function GetBoundedValue(bounds, v, minV, maxV, margin)
        margin = margin or 0.00

        if v < (bounds[minV] + margin) then
            return bounds[minV] + margin
        elseif v > (bounds[maxV] - margin) then
            return bounds[maxV] - margin
        end

        return v
    end

    function mt:getBoundedX(x, margin)
        return GetBoundedValue(self, x, "minX", "maxX", margin)
    end

    function mt:getBoundedY(y, margin)
        return GetBoundedValue(self, y, "minY", "maxY", margin)
    end

    function mt:containsX(x)
        return self:getBoundedX(x) == x
    end

    function mt:containsY(y)
        return self:getBoundedY(y) == y
    end

    local function InitData(bounds)
        bounds.region = CreateRegion()
        bounds.minX = GetRectMinX(bounds.rect)
        bounds.minY = GetRectMinY(bounds.rect)
        bounds.maxX = GetRectMaxX(bounds.rect)
        bounds.maxY = GetRectMaxY(bounds.rect)
        bounds.centerX = (bounds.minX + bounds.maxX) / 2.00
        bounds.centerY = (bounds.minY + bounds.maxY) / 2.00
        RegionAddRect(bounds.region, bounds.rect)
    end

    local oldInit = InitGlobals
    function InitGlobals()
        oldInit()

        MapBounds.rect = bj_mapInitialPlayableArea
        WorldBounds.rect = GetWorldBounds()

        InitData(MapBounds)
        InitData(WorldBounds)
    end
end

-- Dummy
do
    dummies = Set()

    local player = Player(PLAYER_NEUTRAL_PASSIVE)
    local DUMMY = FourCC('U000')

    Dummy = setmetatable({}, { __call = function(this, unit, ability, order, level)
        local dummy = Dummy:retrieve(GetOwningPlayer(unit), 0, 0, 0, 0)
        UnitAddAbility(dummy, ability)
        SetUnitAbilityLevel(dummy, ability, level)
        IssueTargetOrder(dummy, order, unit)
        UnitRemoveAbility(dummy, ability)
        Dummy:recycle(dummy)
    end })

    function Dummy:recycle(unit)
        if GetUnitTypeId(unit) ~= DUMMY then
            print("[DummyPool] Error: Trying to recycle a non dummy unit")
        else
            dummies:add(unit)
            SetUnitX(unit, WorldBounds.maxX)
            SetUnitY(unit, WorldBounds.maxY)
            SetUnitOwner(unit, player, false)
            ShowUnit(unit, false)
            BlzPauseUnitEx(unit, true)
        end
    end

    function Dummy:retrieve(owner, x, y, z, face)
        local dummy = nil
        if dummies.size > 0 then
            dummy = dummies[dummies.size - 1]
            dummies:delete(dummy)
            BlzPauseUnitEx(dummy, false)
            ShowUnit(dummy, true)
            SetUnitX(dummy, x)
            SetUnitY(dummy, y)
            SetUnitFlyHeight(dummy, z, 0)
            BlzSetUnitFacingEx(dummy, face * bj_RADTODEG)
            SetUnitOwner(dummy, owner, false)
        else
            dummy = CreateUnit(owner, DUMMY, x, y, face * bj_RADTODEG)
            SetUnitFlyHeight(dummy, z, 0)
        end

        return dummy
    end

    function Dummy:timed(unit, delay)
        local timer = Timer()
        if GetUnitTypeId(unit) ~= DUMMY then
            print("[DummyPool] Error: Trying to recycle a non dummy unit")
        else
            timer:start(delay, false, Map(Array('unit', unit)), function(parameters, this)
                dummies:add(parameters.unit)
                SetUnitX(parameters.unit, WorldBounds.maxX)
                SetUnitY(parameters.unit, WorldBounds.maxY)
                SetUnitOwner(parameters.unit, player, false)
                ShowUnit(parameters.unit, false)
                BlzPauseUnitEx(parameters.unit, true)
                this:finish()
            end)
        end
    end
end

-- Event Generator
do
    EventGenerator = { type = 'eventGenerator' }

    eventGenerators = Map()

    local triggers = Map()

    local function triggerEvent()
        local eventGenerator = triggers[GetTriggeringTrigger()]
        local arguments = Map()
        for k, v in through(eventGenerator.parameters) do
            arguments:set(k, v())
        end
        local events = eventGenerator.events
        for _, v in through(events) do
            if not eventGenerator.directParents[v]() then goto exit end
            local parents = Array()
            if eventGenerator.source == 'unit' then
                parents:unshift(eventGenerator.directParents[v]())
                parents:unshift(GetOwningPlayer(parents[0]))
            else
                parents[0] = eventGenerator.directParents[v]()
            end
            v(parents, arguments)
            ::exit::
        end
    end

    local func = Filter(triggerEvent)

    eventGeneratorMT = { __call = function(this, type, event, parameters)
        if eventGenerators:has(event) then
            return eventGenerators[event]
        end
        local newEventGenerator = {}
        newEventGenerator.event = event
        newEventGenerator.parameters = parameters
        newEventGenerator.trigger = CreateTrigger()
        newEventGenerator.source = type
        triggers:set(newEventGenerator.trigger, newEventGenerator)
        if type == 'unit' then
            TriggerRegisterAnyUnitEventBJ(newEventGenerator.trigger, event)
        else
            TriggerRegisterPlayerEvent(newEventGenerator.trigger, event)
        end
        TriggerAddCondition(newEventGenerator.trigger, func)
        newEventGenerator.events = Set()
        newEventGenerator.directParents = Map()
        setmetatable(newEventGenerator, EventGenerator)
        eventGenerators:set(event, newEventGenerator)
        return newEventGenerator
    end }

    setmetatable(EventGenerator, eventGeneratorMT)

    EventGenerator.__call = function(this, name, directParent)
        local event = Event(name)
        this.events:add(event)
        this.directParents[event] = directParent
        return event
    end
end

-- Internal Events
do
    -- Unit Attack
    EventGenerator('unit', EVENT_PLAYER_UNIT_ATTACKED, Map(Array(Array('source', GetAttacker), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_ATTACKED]('unitAttack', GetAttacker)
    eventGenerators[EVENT_PLAYER_UNIT_ATTACKED]('unitAttacked', GetTriggerUnit)

    -- Unit Killed
    EventGenerator('unit', EVENT_PLAYER_UNIT_DEATH, Map(Array(Array('source', GetKillingUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_DEATH]('unitKill', GetKillingUnit)
    eventGenerators[EVENT_PLAYER_UNIT_DEATH]('unitKilled', GetTriggerUnit)

    -- Unit Construct
    EventGenerator('unit', EVENT_PLAYER_UNIT_CONSTRUCT_START, Map(Array(Array('source', GetTriggerUnit), Array('target', GetConstructingStructure))))
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_START]('unitStartConstruction', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_START]('unitStartConstructed', GetConstructingStructure)
    EventGenerator('unit', EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetCancelledStructure))))
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL]('unitCancelConstruction', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL]('unitCancelConstructed', GetCancelledStructure)
    EventGenerator('unit', EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, Map(Array(Array('source', GetTriggerUnit), Array('target', GetConstructedStructure))))
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_FINISH]('unitFinishConstruction', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_CONSTRUCT_FINISH]('unitFinishConstructed', GetConstructedStructure)

    -- Unit Upgrade
    EventGenerator('unit', EVENT_PLAYER_UNIT_UPGRADE_START, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_UPGRADE_START]('unitStartUpgrade', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_UPGRADE_CANCEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_UPGRADE_CANCEL]('unitCancelUpgrade', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_UPGRADE_FINISH, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_UPGRADE_FINISH]('unitFinishUpgrade', GetTriggerUnit)

    -- Unit Train
    EventGenerator('unit', EVENT_PLAYER_UNIT_TRAIN_START, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('unitType', GetTrainedUnitType))))
    eventGenerators[EVENT_PLAYER_UNIT_TRAIN_START]('unitStartTrain', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_TRAIN_CANCEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('unitType', GetTrainedUnitType))))
    eventGenerators[EVENT_PLAYER_UNIT_TRAIN_CANCEL]('unitCancelTrain', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_TRAIN_FINISH, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTrainedUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_TRAIN_FINISH]('unitFinishTrain', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_TRAIN_FINISH]('unitFinishTrained', GetTrainedUnit)

    -- Unit Research
    EventGenerator('unit', EVENT_PLAYER_UNIT_RESEARCH_START, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('researched', GetResearched))))
    eventGenerators[EVENT_PLAYER_UNIT_RESEARCH_START]('unitStartResearch', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_RESEARCH_CANCEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('researched', GetResearched))))
    eventGenerators[EVENT_PLAYER_UNIT_RESEARCH_CANCEL]('unitCancelResearch', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_RESEARCH_FINISH, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('researched', GetResearched))))
    eventGenerators[EVENT_PLAYER_UNIT_RESEARCH_FINISH]('unitFinishResearch', GetTriggerUnit)

    -- Unit Levelup
    EventGenerator('unit', EVENT_PLAYER_HERO_LEVEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_HERO_LEVEL]('unitLevelUp', GetTriggerUnit)

    -- Unit Learn Ability
    EventGenerator('unit', EVENT_PLAYER_HERO_SKILL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('ability', GetLearnedSkill), Array('abilityLevel', GetLearnedSkillLevel))))
    eventGenerators[EVENT_PLAYER_HERO_SKILL]('unitLearnAbility', GetTriggerUnit)

    -- Unit Revivable
    EventGenerator('unit', EVENT_PLAYER_HERO_REVIVABLE, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_HERO_REVIVABLE]('unitRevivable', GetTriggerUnit)

    -- Unit Revive
    EventGenerator('unit', EVENT_PLAYER_HERO_REVIVE_START, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_HERO_REVIVE_START]('unitStartRevive', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_HERO_REVIVE_CANCEL, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_HERO_REVIVE_CANCEL]('unitCancelRevive', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_HERO_REVIVE_FINISH, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit))))
    eventGenerators[EVENT_PLAYER_HERO_REVIVE_FINISH]('unitFinishRevive', GetTriggerUnit)

    -- Unit Summon
    EventGenerator('unit', EVENT_PLAYER_UNIT_SUMMON, Map(Array(Array('source', GetTriggerUnit), Array('target', GetSummonedUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_SUMMON]('unitSummon', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_SUMMON]('unitSummoned', GetSummonedUnit)

    -- Unit Item
    EventGenerator('unit', EVENT_PLAYER_UNIT_DROP_ITEM, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('item', GetManipulatedItem))))
    eventGenerators[EVENT_PLAYER_UNIT_DROP_ITEM]('unitDropItem', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_PICKUP_ITEM, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('item', GetManipulatedItem))))
    eventGenerators[EVENT_PLAYER_UNIT_PICKUP_ITEM]('unitPickupItem', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_USE_ITEM, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('item', GetManipulatedItem))))
    eventGenerators[EVENT_PLAYER_UNIT_USE_ITEM]('unitUseItem', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_SELL_ITEM, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('item', GetSoldItem))))
    eventGenerators[EVENT_PLAYER_UNIT_SELL_ITEM]('unitSellItem', GetTriggerUnit)

    -- Unit Load
    EventGenerator('unit', EVENT_PLAYER_UNIT_LOADED, Map(Array(Array('source', GetTransportUnit), Array('target', GetLoadedUnit))))
    eventGenerators[EVENT_PLAYER_UNIT_LOADED]('unitLoad', GetTransportUnit)
    eventGenerators[EVENT_PLAYER_UNIT_LOADED]('unitLoaded', GetLoadedUnit)

    -- Unit Change Owner
    EventGenerator('unit', EVENT_PLAYER_UNIT_CHANGE_OWNER, Map(Array(Array('source', GetTriggerUnit), Array('target', GetTriggerUnit), Array('newOwner', GetChangingUnitOwner))))
    eventGenerators[EVENT_PLAYER_UNIT_CHANGE_OWNER]('unitChangeOwner', GetTriggerUnit)
    eventGenerators[EVENT_PLAYER_UNIT_CHANGE_OWNER]('playerUnitOwnershipRecieved', GetChangingUnitOwner)

    -- Unit Spell
    local spellArguments = Map(Array(
        Array('source', GetTriggerUnit),
        Array('target', GetTriggerUnit),
        Array('ability', GetSpellAbility),
        Array('targetX', GetSpellTargetX),
        Array('targetY', GetSpellTargetY),
        Array('targetUnit', GetSpellTargetUnit)
    ))
    EventGenerator('unit', EVENT_PLAYER_UNIT_SPELL_CHANNEL, spellArguments)
    eventGenerators[EVENT_PLAYER_UNIT_SPELL_CHANNEL]('unitSpellChannel', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_SPELL_CAST, spellArguments)
    eventGenerators[EVENT_PLAYER_UNIT_SPELL_CAST]('unitSpellCast', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_SPELL_EFFECT, spellArguments)
    eventGenerators[EVENT_PLAYER_UNIT_SPELL_EFFECT]('unitSpellEffect', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_SPELL_FINISH, spellArguments)
    eventGenerators[EVENT_PLAYER_UNIT_SPELL_FINISH]('unitSpellFinish', GetTriggerUnit)
    EventGenerator('unit', EVENT_PLAYER_UNIT_SPELL_ENDCAST, spellArguments)
    eventGenerators[EVENT_PLAYER_UNIT_SPELL_ENDCAST]('unitSpellEndCast', GetTriggerUnit)

    Event('unitInit')

    init(function()
        local trigger = CreateTrigger()
        local region = CreateRegion()
        local rect = GetWorldBounds()

        RegionAddRect(region, rect)
        RemoveRect(rect)

        TriggerRegisterEnterRegion(trigger, region, nil)
        TriggerAddCondition(trigger, Filter(function()
            if GetUnitAbilityLevel(GetTriggerUnit(), destructableAbility) > 0 then
                destructables:add(GetTriggerUnit())
                return
            end
            if GetUnitAbilityLevel(GetTriggerUnit(), projectileAbility) > 0 then
                projectiles:add(GetTriggerUnit())
                return
            end
            if GetUnitAbilityLevel(GetTriggerUnit(), specialEffectAbility) > 0 then
                specialEffects:add(GetTriggerUnit())
                return
            end
            units:add(GetTriggerUnit())
            events.unitInit(Array(GetOwningPlayer(GetTriggerUnit()), GetTriggerUnit()), Map(Array(Array('source', GetTriggerUnit()), Array('target', GetTriggerUnit()))))
        end))

        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local group = CreateGroup()
            GroupEnumUnitsOfPlayer(group, Player(i), Filter(function()
                if GetUnitAbilityLevel(GetFilterUnit(), destructableAbility) > 0 then
                    destructables:add(GetFilterUnit())
                    return
                end
                if GetUnitAbilityLevel(GetFilterUnit(), projectileAbility) > 0 then
                    projectiles:add(GetFilterUnit())
                    return
                end
                if GetUnitAbilityLevel(GetFilterUnit(), specialEffectAbility) > 0 then
                    specialEffects:add(GetFilterUnit())
                    return
                end
                units:add(GetFilterUnit())
                events.unitInit(Array(GetOwningPlayer(GetFilterUnit()), GetFilterUnit()), Map(Array(Array('source', GetFilterUnit()), Array('target', GetFilterUnit()))))
            end))
            DestroyGroup(group)
        end
    end)
end

-- Internal Valiadors
do
    -- Hero
    Valiador('sourceIsHero', function(arguments)
        return IsUnitType(arguments.source, UNIT_TYPE_HERO)
    end)
    Valiador('targetIsHero', function(arguments)
        return IsUnitType(arguments.target, UNIT_TYPE_HERO)
    end)
    Valiador('sourceIsNonHero', function(arguments)
        return IsUnitType(arguments.source, UNIT_TYPE_HERO) == false
    end)
    Valiador('targetIsNonHero', function(arguments)
        return IsUnitType(arguments.target, UNIT_TYPE_HERO) == false
    end)
end

-- Unit Management
do
    local oldFunc = RemoveUnit

    function RemoveUnit(unit)
        ShowUnit(unit, false)
        units:delete(unit)
        events.unitRemoved(Array(GetOwningPlayer(unit), unit), Map(Array(Array('source', unit), Array('target', unit))))
        local timer = Timer()
        timer:start(1.0, false, Map(Array(Array('source', unit), Array('target', unit))) ,function(parameters, this)
            gameStorage[parameters.target] = nil
            oldFunc(parameters.target)
            this:finish()
        end)
    end

    Effect('unitDecayEffect', function(arguments)
        local timer = Timer()
        timer:start(5.0, false, Map(Array(Array('source', arguments.target), Array('target', arguments.target))) ,function(parameters, this)
            events.unitDecay(Array(GetOwningPlayer(parameters.target), parameters.target), Map(Array(Array('source', parameters.target), Array('target', parameters.target))))
            RemoveUnit(parameters.target)
            this:finish()
        end)
    end)

    effects.unitDecayEffect:addValiador(valiadors.targetIsNonHero)

    events.unitKilled:register('global', effects.unitDecayEffect, 1)

    Event('unitDecay')

    Event('unitRemoved')
end

-- Damage [NOT YET TESTED]
do
    local damageConstants = Array(Array(1.00, 1.00, 1.00, 1.00, 1.00, 0.75, 0.05, 1.00), Array(1.00, 1.50, 1.00, 0.70, 1.00, 1.00, 0.05, 1.00), Array(2.00, 0.75, 1.00, 0.35, 1.00, 0.50, 0.05, 1.50), Array(1.00, 0.50, 1.00, 1.50, 1.00, 0.50, 0.05, 1.50), Array(1.25, 0.75, 2.00, 0.35, 1.00, 0.50, 0.05, 1.00), Array(1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00), Array(1.00, 1.00, 1.00, 0.50, 1.00, 1.00, 0.05, 1.00))
    local ethernalConstants = Array(0, 0, 0, 1.66, 0, 1.66, 0)

    local attackTypeIndexes = Map(Array(Array(ConvertAttackType(0), 0), Array(ConvertAttackType(1), 1), Array(ConvertAttackType(2), 2), Array(ConvertAttackType(3), 3), Array(ConvertAttackType(4), 4), Array(ConvertAttackType(5), 5), Array(ConvertAttackType(6), 6)))

    local function ConvertDamageCategory(damagetype)
        if damagetype == DAMAGE_TYPE_NORMAL then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_ENHANCED then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_FIRE then return "DAMAGE_CAT_FIRE" end
        if damagetype == DAMAGE_TYPE_COLD then return "DAMAGE_CAT_FROST" end
        if damagetype == DAMAGE_TYPE_LIGHTNING then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_POISON then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_DISEASE then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_DIVINE then return "DAMAGE_CAT_DIVINE" end
        if damagetype == DAMAGE_TYPE_MAGIC then return "DAMAGE_CAT_ARCANE" end
        if damagetype == DAMAGE_TYPE_SONIC then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_ACID then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_FORCE then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_DEATH then return 'DAMAGE_CAT_SHADOW' end
        if damagetype == DAMAGE_TYPE_MIND then return 'DAMAGE_CAT_SHADOW' end
        if damagetype == DAMAGE_TYPE_PLANT then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_DEFENSIVE then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_DEMOLITION then return "DAMAGE_CAT_PHYSICAL" end
        if damagetype == DAMAGE_TYPE_SLOW_POISON then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_SPIRIT_LINK then return "DAMAGE_CAT_UNIVERSAL" end
        if damagetype == DAMAGE_TYPE_SHADOW_STRIKE then return "DAMAGE_CAT_NATURAL" end
        if damagetype == DAMAGE_TYPE_UNIVERSAL then return "DAMAGE_CAT_UNIVERSAL" end
        return "DAMAGE_CAT_UNIVERSAL"
    end

    function attackType2Integer(attackType)
        return attackTypeIndexes[attackType]
    end

    Event('unitDamagingStart')
    Event('unitDamagedStart')

    Event('unitDamagingModifier')
    Event('unitDamagedModifier')

    Event('unitDamagingFactor')
    Event('unitDamagedFactor')

    Event('unitDamagingLimit')
    Event('unitDamagedLimit')

    Event('unitDamagingFinal')
    Event('unitDamagedFinal')

    Event('unitDamagingAfter')
    Event('unitDamagedAfter')

    function damageUnit(source, target, value, attackType, damageType, flags)
        local parameters = Map(Array(
            Array('source', source),
            Array('target', target),
            Array('value', value),
            Array('attackType', attackType),
            Array('damageType', damageType),
            Array('flags', flags)
        ))

        events.unitDamagingStart(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedStart(Array(GetOwningPlayer(target), target), parameters)

        if parameters.flags:has('DAMAGE_FLAG_ATTACK') and not parameters.ignoreArmor then
            if BlzGetUnitArmor(parameters.target) > 0 then
                parameters.value = parameters.value * (1.00 - ((BlzGetUnitArmor(parameters.target) * 0.06) / (BlzGetUnitArmor(parameters.target) * 0.06 + 1 )))
            elseif BlzGetUnitArmor(parameters.target) < 0 then
                parameters.value = parameters.value * (2- ( 0.94 ^ (-1 * BlzGetUnitArmor(parameters.target))))
            end
        end
        if not parameters.ignoreDefenseType then
            parameters.value = parameters.value * damageConstants[AttackTypeToInteger(parameters.attackType)][BlzGetUnitIntegerField(parameters.target, UNIT_IF_DEFENSE_TYPE)]
        end
        if IsUnitType(parameters.target, UNIT_TYPE_ETHEREAL) then
            parameters.value = parameters.value * ethernalConstants[AttackTypeToInteger(parameters.attackType)]
        end

        if parameters.value <= 0.00 then return end

        events.unitDamagingModifier(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedModifier(Array(GetOwningPlayer(target), target), parameters)

        events.unitDamagingFactor(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedFactor(Array(GetOwningPlayer(target), target), parameters)

        events.unitDamagingLimit(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedLimit(Array(GetOwningPlayer(target), target), parameters)

        events.unitDamagingFinal(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedFinal(Array(GetOwningPlayer(target), target), parameters)

        if parameters.value <= 0.00 then return end

        UnitDamageTarget(parameters.source, parameters.target, parameters.value, false, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_UNKNOWN, WEAPON_TYPE_WHOKNOWS)

        events.unitDamagingAfter(Array(GetOwningPlayer(source), source), parameters)
        events.unitDamagedAfter(Array(GetOwningPlayer(target), target), parameters)
    end

    init(function()
        local trigger = CreateTrigger()

        TriggerRegisterAnyUnitEventBJ(trigger, EVENT_PLAYER_UNIT_DAMAGED)

        TriggerAddCondition(trigger, Filter(function()
            if GetEventDamage() == 0.00 or BlzGetEventDamageType() == DAMAGE_TYPE_UNKNOWN then
                return
            end

            if GetEventDamage() <= 0.001 then
                BlzSetEventDamage(0.00)
                return
            end

            local flags = Set()
            if BlzGetEventAttackType() == ATTACK_TYPE_NORMAL then
                flags:add("DAMAGE_FLAG_SPELL")
            else
                flags:add("DAMAGE_FLAG_ATTACK")
            end

            flags:add(ConvertDamageCategory(BlzGetEventDamageType()))

            damageUnit(GetEventDamageSource(), GetTriggerUnit(), GetEventDamage(), BlzGetEventAttackType(), BlzGetEventDamageType(), flags)

            BlzSetEventDamage(0.00)
        end))
    end)
end

-- Restore [NOT YET TESTED]
do
    Event('unitRestoringStart')
    Event('unitRestoredStart')

    Event('unitRestoringModifier')
    Event('unitRestoredModifier')

    Event('unitRestoringFactor')
    Event('unitRestoredFactor')

    Event('unitRestoringLimit')
    Event('unitRestoredLimit')

    Event('unitRestoringFinal')
    Event('unitRestoredFinal')

    Event('unitRestoringAfter')
    Event('unitRestoredAfter')

    function restoreUnit(source, target, value, type, flags)
        local parameters = Map(Array(
            Array('source', source),
            Array('target', target),
            Array('value', value),
            Array('restoreType', type),
            Array('flags', flags)
        ))

        events.unitRestoringStart(Array(GetOwningPlayer(source), source), parameters)
        events.unitRestoredStart(Array(GetOwningPlayer(target), target), parameters)

        if parameters.value <= 0 then return end

        events.unitRestoringModifier(Array(GetOwningPlayer(source), source), parameters)
        events.unitRestoredModifier(Array(GetOwningPlayer(target), target), parameters)

        events.unitRestoringFactor(Array(GetOwningPlayer(source), source), parameters)
        events.unitRestoredFactor(Array(GetOwningPlayer(target), target), parameters)

        events.unitRestoringLimit(Array(GetOwningPlayer(source), source), parameters)
        events.unitRestoredLimit(Array(GetOwningPlayer(target), target), parameters)

        events.unitRestoringFinal(Array(GetOwningPlayer(source), source), parameters)
        events.unitRestoredFinal(Array(GetOwningPlayer(target), target), parameters)

        if parameters.value <= 0 then return end

        if parameters.restoreType == 'health' then
            SetUnitLifeBJ(parameters.target, GetUnitState(parameters.target, UNIT_STATE_LIFE) + parameters.value)
        elseif parameters.restoreType == 'mana' then
            SetUnitManaBJ(parameters.target, GetUnitState(parameters.target, UNIT_STATE_MANA) + parameters.value)
        end
    end
end

-- Ability [NOT COMPLETED]
do
    
end