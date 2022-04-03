do
    function table.getSize(array)
        if not array[1] then return 0 end
        if not array[2] then return 1 end
        local max = 2
        while array[max + 1] do
            max = max * 2
        end
        if array[max] then return max end
        local min = max / 2
        while array[(max + min) / 2 + 1] or (not array[(max + min) / 2]) do
            if array[(max + min) / 2] then
                min = (max + min) / 2
            else
                max = (max + min) / 2
            end
        end
        return (max + min) / 2
    end

    function isNormalTable(array)
        if type(array) ~= 'table' then return false end
        if array.type then return false end
        return true
    end

    function arguments(...)
        local arg = {...}
        if table.getSize(arg) == 1 and isNormalTable(arg[1]) then arg = arg[1] end
        return arg
    end

    function groupToTable(group)
        local array = {}
        for i = 0, BlzGroupGetSize(group) - 1 do
            table.insert(array, BlzGroupUnitAt(group, i))
        end
        return array
    end
end

do
    data = {}

    function aquireData(fill, ...)
        local arg = arguments(...)
        local n = table.getSize(arg)
        if n == 0 then return data end
        local current = data
        for i = 1, n do
            if not current[arg[i]] then
                if fill then
                    current[arg[i]] = {}
                else
                    return nil
                end
            end
            current = current[arg[i]]
            if type(current) ~= 'table' and i ~= n then return nil end
        end
        return current
    end

    function writeData(val, ...)
        local arg = arguments(...)
        local n = table.getSize(arg)
        if n == 0 then return end
        local array = {}
        for i = 1, n - 1 do
            array[i] = arg[i]
        end
        local pos = aquireData(true, array)
        pos[arg[n]] = val
    end
end

do
    storage = {}
    storage.__index = storage

    function storage:create(...)
        local this = {}
        this.type = 'storage'
        this.length = 0
        setmetatable(this, storage)
        this:add(...)
        return this
    end

    function storage:search(element)
        for i = 1, self.length do
            if self[i] == element then return i end
        end
    end

    function storage:remove(...)
        local arg = {...}
        for i = 1, table.getSize(arg) do
            local n = self:search(arg[i])
            if n then
                table.remove(self, n)
                self.length = self.length - 1
            end
        end
    end

    function storage:add(...)
        local arg = {...}
        for i = 1, table.getSize(arg) do
            if not self:search(arg[i]) then
                self.length = self.length + 1
                self[self.length] = arg[i]
            end
        end
    end
end

do
    valiador = {}
    valiador.__index = valiador
    local array = {}

    function valiador:create(name, code)
        local this = {}
        this.type = "valiador"
        this.name = name
        this.code = code
        setmetatable(this, valiador)
        array[name] = this
        return this
    end

    function valiador:retrieve(name)
        return array[name]
    end

    valiador.__call = function(this, source, target, ...)
        local arg = arguments(...)
        return this.code(source, target, arg)
    end
end

do
    effect = {}
    effect.__index = effect
    local array = {}

    function effect:create(name, code, ...)
        local this = {}
        this.type = "effect"
        this.name = name
        this.code = code
        this.valiadors = storage:create(...)
        setmetatable(this, valiador)
        array[name] = this
        return this
    end

    function effect:retrieve(name)
        return array[name]
    end

    effect.__call = function(this, source, target, ...)
        local arg = arguments(...)
        for i = 1, this.valiadors.length do
            if not this.valiadors[i](this, source, target, ...) then return end
        end
       this.code(source, target, arg)
    end
end

do
    function score(val, ...)
    end
end