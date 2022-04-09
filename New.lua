-- Debug
do
    debugCount = 0
    displayValue = true
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

    TICK = 0.03125

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

    function Timer:pause()
        activeTimers:delete(self)
        return self
    end

    function Timer:resume()
        if not self.status then return end
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
            score(newBehavior.target, 'buffs', newBehavior.linkedBuff, 1)
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
            score(self.target, 'buffs', self.linkedBuff, -1)
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

    specialEffectAbility = FourCC('A002')
    specialEffects = Set()
end

-- Arcing Floating Text
do
    local SIZE_MIN        = 0.016         -- Minimum size of text
    local SIZE_BONUS      = 0.008         -- Text size increase
    local TIME_LIFE       = 0.75           -- How long the text lasts
    local TIME_FADE       = 0.5           -- When does the text start to fade
    local Z_OFFSET        = 50            -- Height above unit
    local Z_OFFSET_BON    = 50            -- How much extra height the text gains
    local VELOCITY        = 2.0           -- How fast the text move in x/y plane
    local TMR             = Timer()

    ArcingTextTag = { type ='arcingTextTag' }
    arcingTextTags = Set()

    arcingTextTagMT = { __call = function(this, string, unit, minSize, sizeBonus, duration, fadePoint)
        local newArcingTextTag = {}
        newArcingTextTag.duration = duration or TIME_LIFE
        newArcingTextTag.fadePoint = fadePoint or TIME_FADE
        newArcingTextTag.x = GetUnitX(unit)
        newArcingTextTag.y = GetUnitY(unit)
        newArcingTextTag.string = string
        local a = GetRandomReal(0, 2*bj_PI)
        newArcingTextTag.sin = Sin(a)*VELOCITY
        newArcingTextTag.cos = Cos(a)*VELOCITY
        newArcingTextTag.height = 0.
        newArcingTextTag.minSize = minSize or SIZE_MIN
        newArcingTextTag.sizeBonus = sizeBonus or SIZE_BONUS
        if IsUnitVisible(unit, GetLocalPlayer()) then
            newArcingTextTag.tag = CreateTextTag()
            SetTextTagText(newArcingTextTag.tag, string, newArcingTextTag.minSize)
            SetTextTagPermanent(newArcingTextTag.tag, true)
            SetTextTagLifespan(newArcingTextTag.tag, newArcingTextTag.duration)
            SetTextTagFadepoint(newArcingTextTag.tag, newArcingTextTag.fadePoint)
            SetTextTagPos(newArcingTextTag.tag, newArcingTextTag.x, newArcingTextTag.y, Z_OFFSET)
        end
        setmetatable(newArcingTextTag, ArcingTextTag)
        arcingTextTags:add(newArcingTextTag)
        if arcingTextTags.size == 1 then
            if TMR.status then
                TMR:resume()
            else
                TMR:start(0, true, Map(), function()
                    local tags = arcingTextTags:values()
                    for _, v in through(tags) do
                        local p = Sin(bj_PI * v.duration)
                        v.duration = v.duration - TICK
                        v.x = v.x + v.cos
                        v.y = v.y + v.sin
                        if v.tag then
                            SetTextTagPos(v.tag, v.x, v.y, Z_OFFSET + Z_OFFSET_BON * p)
                            SetTextTagText(v.tag, v.string, v.minSize + v.sizeBonus * p)
                        end
                        if v.duration <= 0.0 then
                            if v.tag then DestroyTextTagBJ(v.tag) end
                            arcingTextTags:delete(v)
                        end
                    end
                    if arcingTextTags.size == 0 then
                        TMR:pause()
                    end
                end)
            end
        end
        return newArcingTextTag
    end }

    setmetatable(ArcingTextTag, arcingTextTagMT)
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
        dummies:add(unit)
        SetUnitX(unit, WorldBounds.maxX)
        SetUnitY(unit, WorldBounds.maxY)
        SetUnitOwner(unit, player, false)
        ShowUnit(unit, false)
        BlzPauseUnitEx(unit, true)
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
        if IsUnitType(arguments.target, UNIT_TYPE_SUMMONED) then
            timer:start(3.0, false, Map(Array(Array('source', arguments.target), Array('target', arguments.target))) ,function(parameters, this)
                events.unitDecay(Array(GetOwningPlayer(parameters.target), parameters.target), Map(Array(Array('source', parameters.target), Array('target', parameters.target))))
                RemoveUnit(parameters.target)
                this:finish()
            end)
            return
        end
        if IsUnitType(arguments.target, UNIT_TYPE_STRUCTURE) then
            timer:start(28.0, false, Map(Array(Array('source', arguments.target), Array('target', arguments.target))) ,function(parameters, this)
                events.unitDecay(Array(GetOwningPlayer(parameters.target), parameters.target), Map(Array(Array('source', parameters.target), Array('target', parameters.target))))
                RemoveUnit(parameters.target)
                this:finish()
            end)
            return
        end
        timer:start(88.0, false, Map(Array(Array('source', arguments.target), Array('target', arguments.target))) ,function(parameters, this)
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

-- Damage
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

    local damageDisplayBaseAmount = 100.0
    local damageDisplayBaseSize = 0.020

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

        if parameters.value <= 0.00 then return end

        if parameters.flags:has('DAMAGE_FLAG_ATTACK') and not parameters.ignoreArmor then
            if BlzGetUnitArmor(parameters.target) > 0 then
                parameters.value = parameters.value * (1.00 - ((BlzGetUnitArmor(parameters.target) * 0.06) / (BlzGetUnitArmor(parameters.target) * 0.06 + 1 )))
            elseif BlzGetUnitArmor(parameters.target) < 0 then
                parameters.value = parameters.value * (2- ( 0.94 ^ (-1 * BlzGetUnitArmor(parameters.target))))
            end
        end
        if not parameters.ignoreDefenseType then
            parameters.value = parameters.value * damageConstants[attackType2Integer(parameters.attackType)][BlzGetUnitIntegerField(parameters.target, UNIT_IF_DEFENSE_TYPE)]
        end
        if IsUnitType(parameters.target, UNIT_TYPE_ETHEREAL) then
            parameters.value = parameters.value * ethernalConstants[attackType2Integer(parameters.attackType)]
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

        local damageSize = damageDisplayBaseSize
        local damageFac = parameters.value / damageDisplayBaseAmount

        if not displayValue then goto skip end

        if damageFac < 1 then
            damageSize = damageSize * (1.25 ^ damageFac - 0.25)
        elseif damageFac > 1 then
            damageSize = damageSize * (1.5 - 0.5 / damageFac)
        end

        if parameters.flags:has('DAMAGE_FLAG_ATTACK') then
            ArcingTextTag("|cffff0000" .. I2S(R2I(parameters.value)) .. "|r", parameters.target, damageSize, damageSize * 0.50)
        else
            ArcingTextTag("|cffff00ff" .. I2S(R2I(parameters.value)) .. "|r", parameters.target, damageSize, damageSize * 0.50)
        end

        ::skip::

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

-- Restore
do
    local restoreDisplayBaseAmount = 200.0
    local restoreDisplayBaseSize = 0.020

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

        local restoreSize = restoreDisplayBaseSize
        local restoreFac = parameters.value / restoreDisplayBaseAmount

        if not displayValue then goto skip end

        if restoreFac < 1 then
            restoreSize = restoreSize * (1.25 ^ restoreFac - 0.25)
        elseif restoreFac > 1 then
            restoreSize = restoreSize * (1.5 - 0.5 / restoreFac)
        end

        if parameters.restoreType == 'health' then
            ArcingTextTag("|cff00ff00" .. I2S(R2I(parameters.value)) .. "|r", parameters.target, restoreSize, restoreSize * 0.50)
        elseif parameters.restoreType == 'mana' then
            ArcingTextTag("|cff00ffff" .. I2S(R2I(parameters.value)) .. "|r", parameters.target, restoreSize, restoreSize * 0.50)
        end

        ::skip::

        if parameters.restoreType == 'health' then
            SetUnitLifeBJ(parameters.target, GetUnitState(parameters.target, UNIT_STATE_LIFE) + parameters.value)
        elseif parameters.restoreType == 'mana' then
            SetUnitManaBJ(parameters.target, GetUnitState(parameters.target, UNIT_STATE_MANA) + parameters.value)
        end
    end
end

-- Missile Effect by Chopinski
do
    MissileEffect = setmetatable({}, {})
    local mt = getmetatable(MissileEffect)
    mt.__index = mt

    function mt:destroy()
        local size = #self.array

        for i = 1, size do
            local this = self.array[i]
            DestroyEffect(this.effect)
            this = nil
        end
        DestroyEffect(self.effect)

        self = nil
    end

    function mt:scale(effect, scale)
        self.size = scale
        BlzSetSpecialEffectScale(effect, scale)
    end

    function mt:orient(yaw, pitch, roll)
        self.yaw   = yaw
        self.pitch = pitch
        self.roll  = roll
        BlzSetSpecialEffectOrientation(self.effect, yaw, pitch, roll)

        for i = 1, #self.array do
            local this = self.array[i]

            this.yaw   = yaw
            this.pitch = pitch
            this.roll  = roll
            BlzSetSpecialEffectOrientation(this.effect, yaw, pitch, roll)
        end
    end

    function mt:move(x, y, z)
        if not (x > WorldBounds.maxX or x < WorldBounds.minX or y > WorldBounds.maxY or y < WorldBounds.minY) then
            BlzSetSpecialEffectPosition(self.effect, x, y, z)
            for i = 1, #self.array do
                local this = self.array[i]
                BlzSetSpecialEffectPosition(this.effect, x - this.x, y - this.y, z - this.z)
            end

            return true
        end
        return false
    end

    function mt:attach(model, dx, dy, dz, scale)
        local this = {}

        this.x = dx
        this.y = dy
        this.z = dz
        this.yaw = 0
        this.pitch = 0
        this.roll = 0
        this.path = model
        this.size = scale
        this.effect = AddSpecialEffect(model, dx, dy)
        BlzSetSpecialEffectZ(this.effect, dz)
        BlzSetSpecialEffectScale(this.effect, scale)
        BlzSetSpecialEffectPosition(this.effect, BlzGetLocalSpecialEffectX(this.effect) - dx, BlzGetLocalSpecialEffectY(this.effect) - dy, BlzGetLocalSpecialEffectZ(this.effect) - dz)

        table.insert(self.array, this)

        return this.effect
    end

    function mt:detach(effect)
        for i = 1, #self.array do
            local this = self.array[i]
            if this.effect == effect then
                table.remove(self.array, i)
                DestroyEffect(effect)
                this = nil
                break
            end
        end
    end

    function mt:setColor(red, green, blue)
        BlzSetSpecialEffectColor(self.effect, red, green, blue)
    end

    function mt:timeScale(real)
        BlzSetSpecialEffectTimeScale(self.effect, real)
    end

    function mt:alpha(integer)
        BlzSetSpecialEffectAlpha(self.effect, integer)
    end

    function mt:playerColor(integer)
        BlzSetSpecialEffectColorByPlayer(self.effect, Player(integer))
    end

    function mt:animation(integer)
        BlzPlaySpecialEffect(self.effect, ConvertAnimType(integer))
    end

    function mt:create(x, y, z)
        local this = {}
        setmetatable(this, mt)

        this.path = ""
        this.size = 1
        this.yaw = 0
        this.pitch = 0
        this.roll = 0
        this.array = {}
        this.effect = AddSpecialEffect("", x, y)
        BlzSetSpecialEffectZ(this.effect, z)

        return this
    end
end

-- Missile Utils by Chopinski
do
    -- -------------------------------------------------------------------------- --
    --                                   System                                   --
    -- -------------------------------------------------------------------------- --
    MissileGroup = setmetatable({}, {})
    local mt = getmetatable(MissileGroup)
    mt.__index = mt

    function mt:destroy()
        self.group = nil
        self.set = nil
        self = nil
    end

    function mt:missileAt(i)
        if #self.group > 0 and i <= #self.group - 1 then
            return self.group[i + 1]
        else
            return 0
        end
    end

    function mt:remove(missile)
        for i = 1, #self.group do
            if self.group[i] == missile then
                self.set[missile] = nil
                table.remove(self.group, i)
                break
            end
        end
    end

    function mt:insert(missile)
        table.insert(self.group, missile)
        self.set[missile] = missile
    end

    function mt:clear()
        local size = #self.group

        for i = 1, size do
            self.set[i] = nil
            self.group[i] = nil
        end
    end

    function mt:contains(missile)
        return self.set[missile] ~= nil
    end

    function mt:addGroup(this)
        for i = 1, #this.group do
            if not self:contains(this.group[i]) then
                self:insert(this.group[i])
            end
        end
    end

    function mt:removeGroup(this)
        for i = 1, #this.group do
            if self:contains(this.group[i]) then
                self:remove(this.group[i])
            end
        end
    end

    function mt:create()
        local this = {}
        setmetatable(this, mt)

        this.group = {}
        this.set = {}

        return this
    end

    -- -------------------------------------------------------------------------- --
    --                                   LUA API                                  --
    -- -------------------------------------------------------------------------- --
    function CreateMissileGroup()
        return MissileGroup:create()
    end

    function DestroyMissileGroup(group)
        if group then
            group:destroy()
        end
    end

    function MissileGroupGetSize(group)
        if group then
            return #group.group
        else
            return 0
        end
    end

    function GroupMissileAt(group, position)
        if group then
            return group:missileAt(position)
        else
            return nil
        end
    end

    function ClearMissileGroup(group)
        if group then
            group:clear()
        end
    end

    function IsMissileInGroup(missile, group)
        if group and missile then
            if #group.group > 0 then
                return group:contains(missile)
            else
                return false
            end
        else
            return false
        end
    end

    function GroupRemoveMissile(group, missile)
        if group and missile then
            if #group.group > 0 then
                group:remove(missile)
            end
        end
    end

    function GroupAddMissile(group, missile)
        if group and missile then
            if not group:contains(missile) then
                group:insert(missile)
            end
        end
    end

    function GroupPickRandomMissile(group)
        if group then
            if #group.group > 0 then
                return group:missileAt(GetRandomInt(0, #group.group - 1))
            else
                return nil
            end
        else
            return nil
        end
    end

    function FirstOfMissileGroup(group)
        if group then
            if #group.group > 0 then
                return group.group[1]
            else
                return nil
            end
        else
            return nil
        end
    end

    function GroupAddMissileGroup(source, destiny)
        if source and destiny then
            if #source.group > 0 and source ~= destiny then
                destiny:addGroup(source)
            end
        end
    end

    function GroupRemoveMissileGroup(source, destiny)
        if source and destiny then
            if source == destiny then
                source:clear()
            elseif #source.group > 0 then
                destiny:removeGroup(source)
            end
        end
    end

    function GroupEnumMissilesOfType(group, type)
        if group then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    if missile.type == type then
                        group:insert(missile)
                    end
                end
            end
        end
    end

    function GroupEnumMissilesOfTypeCounted(group, type, amount)
        local i = 0
        local j = amount

        if group then
            if Missiles.count > -1 then

                if #group.group > 0 then
                    group:clear()
                end

                while i <= Missiles.count and j > 0 do
                    local missile = Missiles.collection[i]
                    if missile.type == type then
                        group:insert(missile)
                    end

                    j = j - 1
                    i = i + 1
                end
            end
        end
    end

    function GroupEnumMissilesOfPlayer(group, player)
        if group then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    if missile.owner == player then
                        group:insert(missile)
                    end
                end
            end
        end
    end

    function GroupEnumMissilesOfPlayerCounted(group, player, amount)
        local i = 0
        local j = amount

        if group then
            if Missiles.count > -1 then

                if #group.group > 0 then
                    group:clear()
                end

                while i <= Missiles.count and j > 0 do
                    local missile = Missiles.collection[i]
                    if missile.owner == player then
                        group:insert(missile)
                    end

                    j = j - 1
                    i = i + 1
                end
            end
        end
    end

    function GroupEnumMissilesInRect(group, rect)
        if group and rect then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    if GetRectMinX(rect) <= missile.x and missile.x <= GetRectMaxX(rect) and GetRectMinY(rect) <= missile.y and missile.y <= GetRectMaxY(rect) then
                        group:insert(missile)
                    end
                end
            end
        end
    end

    function GroupEnumMissilesInRectCounted(group, rect, amount)
        local i = 0
        local j = amount

        if group and rect then
            if Missiles.count > -1 then

                if #group.group > 0 then
                    group:clear()
                end

                while i <= Missiles.count and j > 0 do
                    local missile = Missiles.collection[i]
                    if GetRectMinX(rect) <= missile.x and missile.x <= GetRectMaxX(rect) and GetRectMinY(rect) <= missile.y and missile.y <= GetRectMaxY(rect) then
                        group:insert(missile)
                    end

                    j = j - 1
                    i = i + 1
                end
            end
        end
    end

    function GroupEnumMissilesInRangeOfLoc(group, location, radius)
        if group and location and radius > 0 then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    local dx = missile.x - GetLocationX(location)
                    local dy = missile.y - GetLocationY(location)

                    if SquareRoot(dx*dx + dy*dy) <= radius then
                        group:insert(missile)
                    end
                end
            end
        end
    end

    function GroupEnumMissilesInRangeOfLocCounted(group, location, radius, amount)
        local i = 0
        local j = amount

        if group and location and radius > 0 then
            if Missiles.count > -1 then

                if #group.group > 0 then
                    group:clear()
                end

                while i <= Missiles.count and j > 0 do
                    local missile = Missiles.collection[i]
                    local dx = missile.x - GetLocationX(location)
                    local dy = missile.y - GetLocationY(location)

                    if SquareRoot(dx*dx + dy*dy) <= radius then
                        group:insert(missile)
                    end

                    j = j - 1
                    i = i + 1
                end
            end
        end
    end

    function GroupEnumMissilesInRange(group, x, y, radius)
        if group and radius > 0 then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    local dx = missile.x - x
                    local dy = missile.y - y

                    if SquareRoot(dx*dx + dy*dy) <= radius then
                        group:insert(missile)
                    end
                end
            end
        end
    end

    function GroupEnumMissilesInRangeCounted(group, x, y, radius, amount)
        local i = 0
        local j = amount

        if group and radius > 0 then
            if Missiles.count > -1 then
                if #group.group > 0 then
                    group:clear()
                end

                while i <= Missiles.count and j > 0 do
                    local missile = Missiles.collection[i]
                    local dx = missile.x - x
                    local dy = missile.y - x

                    if SquareRoot(dx*dx + dy*dy) <= radius then
                        group:insert(missile)
                    end

                    j = j - 1
                    i = i + 1
                end
            end
        end
    end
end

-- Missile by Chopinski
do
    -- -------------------------------------------------------------------------- --
    --                                Configuration                               --
    -- -------------------------------------------------------------------------- --
    -- The update period of the system
    local PERIOD = 0.03125
    -- The max amount of Missiles processed in a PERIOD
    -- You can play around with both these values to find
    -- your sweet spot. If equal to 0, the system will
    -- process all missiles at once every period.
    local SWEET_SPOT = 600
    -- the avarage collision size compensation when detecting collisions
    local COLLISION_SIZE = 128.
    -- item size used in z collision
    local ITEM_SIZE  = 16.
    -- Raw code of the dummy unit used for vision
    local DUMMY = FourCC('U000')
    -- Needed, dont touch. Seriously, dont touch!
    local location = Location(0., 0.)
    local rect = Rect(0., 0., 0., 0.)

    local function GetLocZ(x, y)
        MoveLocation(location, x, y)
        return GetLocationZ(location)
    end

    local function GetUnitZ(unit)
        return GetLocZ(GetUnitX(unit), GetUnitY(unit)) + GetUnitFlyHeight(unit)
    end

    local function SetUnitZ(unit, z)
        SetUnitFlyHeight(unit, z - GetLocZ(GetUnitX(unit), GetUnitY(unit)), 0)
    end

    local function GetMapCliffLevel()
        return GetTerrainCliffLevel(WorldBounds.maxX, WorldBounds.maxY)
    end

    do
        Pool = setmetatable({}, {})
        local mt = getmetatable(Pool)
        mt.__index = mt

        local player = Player(PLAYER_NEUTRAL_PASSIVE)
        local group = CreateGroup()

        function mt:recycle(unit)
            if GetUnitTypeId(unit) == DUMMY then
                GroupAddUnit(group, unit)
                SetUnitX(unit, WorldBounds.maxX)
                SetUnitY(unit, WorldBounds.maxY)
                SetUnitOwner(unit, player, false)
                PauseUnit(unit, true)
            end
        end

        function mt:retrieve(x, y, z, face)
            if BlzGroupGetSize(group) > 0 then
                bj_lastCreatedUnit = FirstOfGroup(group)
                PauseUnit(bj_lastCreatedUnit, false)
                GroupRemoveUnit(group, bj_lastCreatedUnit)
                SetUnitX(bj_lastCreatedUnit, x)
                SetUnitY(bj_lastCreatedUnit, y)
                SetUnitZ(bj_lastCreatedUnit, z)
                BlzSetUnitFacingEx(bj_lastCreatedUnit, face)
            else
                bj_lastCreatedUnit = CreateUnit(player, DUMMY, x, y, face)
                SetUnitZ(bj_lastCreatedUnit, z)
                UnitRemoveAbility(bj_lastCreatedUnit, FourCC('Amrf'))
            end

            return bj_lastCreatedUnit
        end

        function mt:recycleTimed(unit, delay)
            if GetUnitTypeId(unit) == DUMMY then
                local timer = Timer()
                timer:start(delay, false, Map(), function(parameters, this)
                    Pool:recycle(unit)
                    this:finish()
                end)
            end
        end

        init(function()
            local timer = CreateTimer()

            TimerStart(timer, 0, false, function()
                for i = 0, SWEET_SPOT do
                    local unit = CreateUnit(player, DUMMY, WorldBounds.maxX, WorldBounds.maxY, 0)
                    PauseUnit(unit, false)
                    GroupAddUnit(group, unit)
                    UnitRemoveAbility(unit, FourCC('Amrf'))
                end
                PauseTimer(timer)
                DestroyTimer(timer)
            end)
        end)
    end

    do
        Coordinates = setmetatable({}, {})
        local mt = getmetatable(Coordinates)
        mt.__index = mt

        function mt:destroy()
            self = nil
        end

        function mt:math(a, b)
            local dx
            local dy

            while true do
                dx = b.x - a.x
                dy = b.y - a.y
                dx = dx * dx + dy * dy
                dy = SquareRoot(dx)
                if dx ~= 0. and dy ~= 0. then
                    break
                end
                b.x = b.x + .01
                b.z = b.z - GetLocZ(b.x - .01, b.y) + GetLocZ(b.x, b.y)
            end

            a.square = dx
            a.distance = dy
            a.angle = Atan2(b.y - a.y, b.x - a.x)
            a.slope = (b.z - a.z) / dy
            a.alpha = Atan(a.slope)
            -- Set b.
            if b.ref == a then
                b.angle = a.angle + bj_PI
                b.distance = dy
                b.slope = -a.slope
                b.alpha = -a.alpha
                b.square = dx
            end
        end

        function mt:link(a, b)
            a.ref = b
            b.ref = a
            self:math(a, b)
        end

        function mt:move(toX, toY, toZ)
            self.x = toX
            self.y = toY
            self.z = toZ + GetLocZ(toX, toY)
            if self.ref ~= self then
                self:math(self, self.ref)
            end
        end

        function mt:create(x, y, z)
            local c = {}
            setmetatable(c, mt)

            c.ref = c
            c:move(x, y, z)
            return c
        end
    end

    -- -------------------------------------------------------------------------- --
    --                                  Missiles                                  --
    -- -------------------------------------------------------------------------- --
    Missiles = setmetatable({}, {})
    local mt = getmetatable(Missiles)
    mt.__index = mt

    Missiles.collection = {}
    Missiles.count = -1

    local timer = Timer()
    local group = CreateGroup()
    local id = -1
    local pid = -1
    local last = 0
    local dilation = 1
    local array = {}
    local missiles = {}
    local missilesSet = Set()
    local frozen = {}
    local keys = {}
    local index = 1
    local yaw = 0
    local pitch = 0
    local travelled = 0

    function mt:OnHit()
        if self.onHit then
            if self.allocated and self.collision > 0 then
                GroupEnumUnitsInRange(group, self.x, self.y, self.collision + COLLISION_SIZE, nil)
                local unit = FirstOfGroup(group)
                while unit do
                    if array[self][unit] == nil then
                        if IsUnitInRangeXY(unit, self.x, self.y, self.collision) then
                            if self.collideZ then
                                local dx = GetLocZ(GetUnitX(unit), GetUnitY(unit)) + GetUnitFlyHeight(unit)
                                local dy = BlzGetUnitCollisionSize(unit)
                                if dx + dy >= self.z - self.collision and dx <= self.z + self.collision then
                                    array[self][unit] = true
                                    if self.allocated and self.onHit(unit) then
                                        self:terminate()
                                        break
                                    end
                                end
                            else
                                array[self][unit] = true
                                if self.allocated and self.onHit(unit) then
                                    self:terminate()
                                    break
                                end
                            end
                        end
                    end
                    GroupRemoveUnit(group, unit)
                    unit = FirstOfGroup(group)
                end
            end
        end
    end

    function mt:OnMissile()
        if self.onMissile then
            if self.allocated and self.collision > 0 then
                for i = 0, Missiles.count do
                    local missile = Missiles.collection[i]
                    if missile ~= self then
                        if array[self][missile] == nil then
                            local dx = missile.x - self.x
                            local dy = missile.y - self.y
                            if SquareRoot(dx*dx + dy*dy) <= self.collision then
                                array[self][missile] = true
                                if self.allocated and self.onMissile(missile) then
                                    self:terminate()
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function mt:OnDestructable()
        if self.onDestructable then
            if self.allocated and self.collision > 0 then
                local dx = self.collision
                SetRect(rect, self.x - dx, self.y - dx, self.x + dx, self.y + dx)
                EnumDestructablesInRect(rect, nil, function()
                    local destructable = GetEnumDestructable()
                    if array[self][destructable] == nil then
                        if self.collideZ then
                            local dz = GetLocZ(GetWidgetX(destructable), GetWidgetY(destructable))
                            local tz = GetDestructableOccluderHeight(destructable)
                            if dz + tz >= self.z - self.collision and dz <= self.z + self.collision then
                                array[self][destructable] = true
                                if self.allocated and self.onDestructable(destructable) then
                                    self:terminate()
                                    return
                                end
                            end
                        else
                            array[self][destructable] = true
                            if self.allocated and self.onDestructable(destructable) then
                                self:terminate()
                                return
                            end
                        end
                    end
                end)
            end
        end
    end

    function mt:OnItem()
        if self.onItem then
            if self.allocated and self.collision > 0 then
                local dx = self.collision
                SetRect(rect, self.x - dx, self.y - dx, self.x + dx, self.y + dx)
                EnumItemsInRect(rect, nil, function()
                    local item = GetEnumItem()
                    if array[self][item] == nil then
                        if self.collideZ then
                            local dz = GetLocZ(GetItemX(item), GetItemY(item))
                            if dz + ITEM_SIZE >= self.z - self.collision and dz <= self.z + self.collision then
                                array[self][item] = true
                                if self.allocated and self.onItem(item) then
                                    self:terminate()
                                    return
                                end
                            end
                        else
                            array[self][item] = true
                            if self.allocated and self.onItem(item) then
                                self:terminate()
                                return
                            end
                        end
                    end
                end)
            end
        end
    end

    function mt:OnCliff()
        if self.onCliff then
            local dx = GetTerrainCliffLevel(self.nextX, self.nextY)
            local dy = GetTerrainCliffLevel(self.x, self.y) 
            if dy < dx and self.z  < (dx - GetMapCliffLevel())*bj_CLIFFHEIGHT then
                if self.allocated and self.onCliff() then
                    self:terminate()
                end
            end
        end
    end

    function mt:OnTerrain()
        if self.onTerrain then
            if GetLocZ(self.x, self.y) > self.z then
                if self.allocated and self.onTerrain() then
                    self:terminate()
                end
            end
        end
    end


    function mt:OnTileset()
        if self.onTileset then
            local type = GetTerrainType(self.x, self.y)
            if type ~= self.tileset then
                if self.allocated and self.onTileset(type) then
                    self:terminate()
                end
            end
            self.tileset = type
        end
    end

    function mt:OnPeriod()
        if self.onPeriod then
            if self.allocated and self.onPeriod() then
                self:terminate()
            end
        end
    end

    function mt:OnOrient()
        local a

        -- Homing or not
        if self.target and GetUnitTypeId(self.target) ~= 0 then
            self.impact:move(GetUnitX(self.target), GetUnitY(self.target), GetUnitFlyHeight(self.target) + self.toZ)
            local dx = self.impact.x - self.nextX
            local dy = self.impact.y - self.nextY
            a = Atan2(dy, dx)
            self.travel = self.origin.distance - SquareRoot(dx*dx + dy*dy)
        else
            a = self.origin.angle
            self.target = nil
        end

        -- turn rate
        if self.turn ~= 0 and not (Cos(self.cA - a) >= Cos(self.turn)) then
            if Sin(a - self.cA) >= 0 then
                self.cA = self.cA + self.turn
            else
                self.cA = self.cA - self.turn
            end
        else
            self.cA = a
        end

        local vel = self.veloc*dilation
        yaw = self.cA
        travelled = self.travel + vel
        self.veloc = self.veloc + self.acceleration
        self.travel = travelled
        pitch = self.origin.alpha
        self.prevX = self.x
        self.prevY = self.y
        self.prevZ = self.z
        self.x = self.nextX
        self.y = self.nextY
        self.z = self.nextZ
        self.nextX = self.x + vel*Cos(yaw)
        self.nextY = self.y + vel*Sin(yaw)

        -- arc calculation
        local s = travelled
        local d = self.origin.distance
        local h = self.height
        if h ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4*h*s*(d-s)/(d*d) + self.origin.slope*s + self.origin.z
            pitch = pitch - Atan(((4*h)*(2*s - d))/(d*d))
        end

        -- curve calculation
        local c = self.open
        if c ~= 0 then
            local dx = 4 * c * s * (d - s) / (d * d)
            a = yaw + bj_PI / 2
            self.x = self.x + dx * Cos(a)
            self.y = self.y + dx * Sin(a)
            yaw = yaw + Atan(-((4 * c) * (2 * s - d)) / (d * d))
        end
    end

    function mt:OnFinish()
        if travelled >= self.origin.distance - 0.0001 then
            self.finished = true
            if self.onFinish then
                if self.allocated and self.onFinish() then
                    self:terminate()
                else
                    if self.travel > 0 and not self.paused then
                        self:terminate()
                    end
                end
            else
                self:terminate()
            end
        else
            if not self.roll then
                self.effect:orient(yaw, -pitch, 0)
            else
                self.effect:orient(yaw, -pitch, Atan2(self.open, self.height))
            end
        end
    end

    function mt:OnBoundaries()
        if not self.effect:move(self.x, self.y, self.z) then
            if self.onBoundaries then
                if self.allocated and self.onBoundaries() then
                    self:terminate()
                end
            end
        else
            if self.dummy then
                SetUnitX(self.dummy, self.x)
                SetUnitY(self.dummy, self.y)
            end
        end
    end

    function mt:OnPause()
        pid = pid + 1
        self.pkey = pid
        frozen[pid] = self

        if self.onPause then
            if self.allocated and self.onPause() then
                self:terminate()
            end
        end
    end

    function mt:OnResume(flag)
        local this

        self.paused = flag
        if not self.paused and self.pkey ~= -1 then
            id = id + 1
            missiles[id] = self
            this = frozen[pid]
            this.pkey = self.pkey
            frozen[self.pkey] = frozen[pid]
            pid = pid - 1
            self.pkey = -1

            if id + 1 > SWEET_SPOT and SWEET_SPOT > 0 then
                dilation = (id + 1)/SWEET_SPOT
            else
                dilation = 1.
            end

            if id == 0 then
                if timer.status then
                    timer:resume()
                else
                    timer:start(0, true, Map(), function()
                        Missiles:move()
                    end)
                end
            end

             if self.onResume then
                if self.allocated and self.onResume() then
                    self:terminate()
                else
                    if self.finished then
                        self:terminate()
                    end
                end
            else
                if self.finished then
                    self:terminate()
                end
            end
        end
    end

    function mt:OnRemove()
        local this

        if self.allocated and self.launched then
            self.allocated = false

            if self.pkey ~= -1 then
                this = frozen[pid]
                this.pkey = self.pkey
                frozen[self.pkey] = frozen[pid]
                pid = pid - 1
                self.pkey = -1
            end

            if self.onRemove then
                self.onRemove()
            end

            if self.dummy then
                Pool:recycle(self.dummy)
            end

            this = Missiles.collection[Missiles.count]
            this.index = self.index
            Missiles.collection[self.index] = Missiles.collection[Missiles.count]
            Missiles.count = Missiles.count - 1
            self.index = -1

            self.origin:destroy()
            self.impact:destroy()
            self.effect:destroy()
            self:reset()
            array[self] = nil
        end
    end


    -- -------------------------- Model of the missile -------------------------- --
    function mt:model(effect)
        DestroyEffect(self.effect.effect)
        self.effect.path = effect
        self.Model = effect
        self.effect.effect = AddSpecialEffect(effect, self.origin.x, self.origin.y)
        BlzSetSpecialEffectZ(self.effect.effect, self.origin.z)
        BlzSetSpecialEffectYaw(self.effect.effect, self.cA)
    end

    -- ----------------------------- Curved movement ---------------------------- --
    function mt:curve(value)
        self.open = Tan(value * bj_DEGTORAD) * self.origin.distance
        self.Curve = value
    end

    -- ----------------------------- Arced Movement ----------------------------- --
    function mt:arc(value)
        self.height = Tan(value * bj_DEGTORAD) * self.origin.distance / 4
        self.Arc = value
    end

    -- ------------------------------ Effect scale ------------------------------ --
    function mt:scale(value)
        self.effect.size = value
        self.effect:scale(self.effect.effect, value)
        self.Scale = value
    end

    -- ------------------------------ Missile Speed ----------------------------- --
    function mt:speed(value)
        self.veloc = value * PERIOD
        self.Speed = value

        local vel = self.veloc*dilation
        local s = self.travel + vel
        local d = self.origin.distance
        self.nextX = self.x + vel*Cos(self.cA)
        self.nextY = self.y + vel*Sin(self.cA)

        if self.height ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4*self.height*s*(d-s)/(d*d) + self.origin.slope*s + self.origin.z
            self.z = self.nextZ
        end
    end

    -- ------------------------------- Flight Time ------------------------------ --
    function mt:duration(value)
        self.veloc = RMaxBJ(0.00000001, (self.origin.distance - self.travel) * PERIOD / RMaxBJ(0.00000001, value))
        self.Duration = value

        local vel = self.veloc*dilation
        local s = self.travel + vel
        local d = self.origin.distance
        self.nextX = self.x + vel*Cos(self.cA)
        self.nextY = self.y + vel*Sin(self.cA)

        if self.height ~= 0 or self.origin.slope ~= 0 then
            self.nextZ = 4*self.height*s*(d-s)/(d*d) + self.origin.slope*s + self.origin.z
            self.z = self.nextZ
        end
    end

    -- ------------------------------- Sight Range ------------------------------ --
    function mt:vision(sightRange)
        self.Vision = sightRange

        if self.dummy then
            SetUnitOwner(self.dummy, self.owner, false)
            BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
        else
            if not self.owner then
                if self.source then
                    self.dummy = Pool:retrieve(self.x, self.y, self.z, 0)
                    SetUnitOwner(self.dummy, GetOwningPlayer(self.source), false)
                    BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
                end
            else
                self.dummy = Pool:retrieve(self.x, self.y, self.z, 0)
                SetUnitOwner(self.dummy, self.owner, false)
                BlzSetUnitRealField(self.dummy, UNIT_RF_SIGHT_RADIUS, sightRange)
            end
        end
    end

    -- ------------------------------- Time Scale ------------------------------- --
    function mt:timeScale(real)
        self.TimeScale = real
        self.effect:timeScale(real)
    end

    -- ---------------------------------- Alpha --------------------------------- --
    function mt:alpha(integer)
        self.Alpha = integer
        self.effect:alpha(integer)
    end

    -- ------------------------------ Player Color ------------------------------ --
    function mt:playerColor(integer)
        self.playercolor = integer
        self.effect:playerColor(integer)
    end

    -- -------------------------------- Animation ------------------------------- --
    function mt:animation(integer)
        self.Animation = integer
        self.effect:animation(integer)
    end

    -- --------------------------- Bounce and Deflect --------------------------- --
    function mt:bounce()
        self.origin:move(self.x, self.y, self.z - GetLocZ(self.x, self.y))

        travelled = 0
        self.travel = 0
        self.finished = false
    end

    function mt:deflect(tx, ty, tz)
        local locZ = GetLocZ(self.x, self.y) 

        if self.z < locZ then
            self.nextX = self.prevX
            self.nextY = self.prevY
            self.nextZ = self.prevZ
        end

        self.toZ = tz
        self.target = nil
        self.impact:move(tx, ty, tz)
        self.origin:move(self.x, self.y, self.z - locZ)

        travelled = 0
        self.travel = 0
        self.finished = false
    end

    function mt:deflectTarget(unit)
        self:deflect(GetUnitX(unit), GetUnitY(unit), self.toZ)
        self.target = unit
    end

    -- ---------------------------- Flush hit targets --------------------------- --
    function mt:flushAll()
        array[self] = nil
    end

    function mt:flush(widget)
        if widget then
            array[self][widget] = nil
        end
    end

    function mt:hitted(widget)
        return array[self][widget]
    end

    -- ----------------------- Missile attachment methods ----------------------- --
    function mt:attach(model, dx, dy, dz, scale)
        return self.effect:attach(model, dx, dy, dz, scale)
    end

    function mt:detach(effect)
        if effect then
            self.effect:detach(effect)
        end
    end

    -- ------------------------------ Missile Pause ----------------------------- --
    function mt:pause(flag)
        self:OnResume(flag)
    end

    -- ---------------------------------- Color --------------------------------- --
    function mt:color(red, green, blue)
        self.effect:setColor(red, green, blue)
    end

    -- ------------------------------ Reset members ----------------------------- --
    function mt:reset()
        self.launched = false
        self.collideZ = false
        self.finished = false
        self.paused = false
        self.roll = false
        self.source = nil
        self.target = nil
        self.owner = nil
        self.dummy = nil
        self.open = 0.
        self.height = 0.
        self.veloc = 0.
        self.acceleration = 0.
        self.collision = 0.
        self.damage = 0.
        self.travel = 0.
        self.turn = 0.
        self.data = 0.
        self.type = 0
        self.tileset = 0
        self.pkey = -1
        self.index = -1
        self.Model = ""
        self.Duration = 0
        self.Scale = 1
        self.Speed = 0
        self.Arc = 0
        self.Curve = 0
        self.Vision = 0
        self.TimeScale = 0.
        self.Alpha = 0
        self.playercolor = 0
        self.Animation = 0
        self.onHit = nil
        self.onMissile = nil
        self.onDestructable = nil
        self.onItem = nil
        self.onCliff = nil
        self.onTerrain = nil
        self.onTileset = nil
        self.onFinish = nil
        self.onBoundaries = nil
        self.onPause = nil
        self.onResume = nil
        self.onRemove = nil
    end

    -- -------------------------------- Terminate ------------------------------- --
    function mt:terminate()
        self:OnRemove()
    end

    -- -------------------------- Destroys the missile -------------------------- --
    function mt:remove(i)
        if self.paused then
            self:OnPause()
        else
            self:OnRemove()
        end

        missiles[i] = missiles[id]
        id = id - 1

        if id + 1 > SWEET_SPOT and SWEET_SPOT > 0 then
            dilation = (id + 1) / SWEET_SPOT
        else
            dilation = 1
        end

        if id == -1 then
            timer:pause()
        end

        if not self.allocated then
            table.insert(keys, self.key)
            self = nil
        end

        return i - 1
    end

    -- ---------------------------- Missiles movement --------------------------- --
    function mt:move()
        local i = 0
        local j = 0

        if SWEET_SPOT > 0 then
            i = last
        else
            i = 0
        end

        while not ((j >= SWEET_SPOT and SWEET_SPOT > 0) or j > id) do
            local this = missiles[i]

            if this.allocated and not this.paused then
                this:OnHit()
                this:OnMissile()
                this:OnDestructable()
                this:OnItem()
                this:OnCliff()
                this:OnTerrain()
                this:OnTileset()
                this:OnPeriod()
                this:OnOrient()
                this:OnFinish()
                this:OnBoundaries()
            else
                i = this:remove(i)
                j = j - 1
            end
            i = i + 1
            j = j + 1

            if i > id and SWEET_SPOT > 0 then
                i = 0
            end
        end
        last = i
    end

    -- --------------------------- Launch the Missile --------------------------- --
    function mt:launch()
        if not self.launched and self.allocated then
            self.launched = true
            id = id + 1
            missiles[id] = self
            Missiles.count = Missiles.count + 1
            self.index = Missiles.count
            Missiles.collection[Missiles.count] = self

            if id + 1 > SWEET_SPOT and SWEET_SPOT > 0 then
                dilation = (id + 1) / SWEET_SPOT
            else
                dilation = 1.
            end

            if id == 0 then
                if timer.status then
                    timer:resume()
                else
                    timer:start(0, true, Map(), function()
                        Missiles:move()
                    end)
                end
            end
        end
    end

    -- --------------------------- Main Creator method -------------------------- --
    function mt:create(x, y, z, toX, toY, toZ)
        local this = {}
        setmetatable(this, mt)
        array[this] = {}

        if #keys > 0 then
            this.key = keys[#keys]
            keys[#keys] = nil
        else
            this.key = index
            index = index + 1
        end

        this:reset()
        this.origin = Coordinates:create(x, y, z)
        this.impact = Coordinates:create(toX, toY, toZ)
        this.effect = MissileEffect:create(x, y, this.origin.z)
        Coordinates:link(this.origin, this.impact)
        this.allocated = true
        this.cA = this.origin.angle
        this.x = x
        this.y = y
        this.z = this.impact.z
        this.prevX = x
        this.prevY = y
        this.prevZ = this.impact.z
        this.nextX = x
        this.nextY = y
        this.nextZ = this.impact.z
        this.toZ = toZ

        missilesSet:add(this)
        return this
    end
end