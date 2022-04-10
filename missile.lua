
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