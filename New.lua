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
        return Array(table.unpack(self._values, 1, self.length))
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
        return table.unpack(self._values, 1, self.length)
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
    local storage = Map()

    function getStorage(fill, fallback, ...)
        local arguments = Array(...)
        local current = storage
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
        for _, v in through(array) do
            v:destroy()
        end
        if garbageBin.size > 0 then goto recycle end
    end

    function Timer:destroy()
        self = nil
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
        for _, v in through(self.finishEffects) do
            v(self)
        end
        EVENT_BEHAVIOR_REMOVE(Array(GetOwningPlayer(self.source), self.source), self)
        EVENT_BEHAVIOR_REMOVED(Array(GetOwningPlayer(self.target), self.target), self)
        self = nil
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
        timer:start(0, true, Map(), function(parameters)
            Behavior:recycle()
            local array = behaviors:entries()
            for _, i in through(array) do
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

    destructables = Set()

    projectiles = Set()

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
    Dummy = setmetatable({}, { __call = function(this, unit, ability, order, level)
        local dummy = Dummy:retrieve(GetOwningPlayer(unit), 0, 0, 0, 0)
        UnitAddAbility(dummy, ability)
        SetUnitAbilityLevel(dummy, ability, level)
        IssueTargetOrder(dummy, order, unit)
        UnitRemoveAbility(dummy, ability)
        Dummy:recycle(dummy)
    end })

    dummies = Set()

    local player = Player(PLAYER_NEUTRAL_PASSIVE)
    local DUMMY = FourCC('U000')

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
    EventGenerator = { type = 'event generator' }

    eventGenerators = Map()

    local triggers = Map()

    eventGeneratorMT = { __call = function(this, type, event, parameters)
        if eventGenerators:has(event) then return eventGenerators[event] end
        local newEventGenerator = {}
        newEventGenerator.event = event
        newEventGenerator.parameters = parameters
        newEventGenerator.trigger = CreateTrigger()
        newEventGenerator.source = type
        triggers:set(newEventGenerator.trigger, newEventGenerator)
        if type == 'unit' then
            RegisterAnyUnitEvent(newEventGenerator.trigger, event)
        else
            RegisterPlayerEvent(newEventGenerator.trigger, event)
        end
        TriggerAddAction(newEventGenerator.trigger, function()
            local eventGenerator = triggers[GetTriggeringTrigger()]
            local arguments = Map()
            for k, v in through(eventGenerator.parameters) do
                arguments:set(k, v())
            end
            local events = eventGenerator.events
            for _, v in through(events) do
                local parents = Array()
                if eventGenerator.source == 'unit' then
                    parents:unshift(eventGenerator.directParents[v]())
                    parents:unshift(GetOwningPlayer(parents[0]))
                else
                    parents[0] = eventGenerator.directParents[v]()
                end
                v(parents, arguments)
            end
        end)
        newEventGenerator.events = Set()
        newEventGenerator.directParents = Map()
        setmetatable(newEventGenerator, EventGenerator)
        eventGenerators:set(event, newEventGenerator)
        return newEventGenerator
    end }

    EventGenerator.__call = function(this, name, directParent)
        local event = Event(name)
        this.events:add(event)
        this.directParents[event] = directParent
        return event
    end
end