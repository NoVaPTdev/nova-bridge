--[[
    NOVA Bridge - vRP Utils Library
    Compatível com o ecossistema Creative/vRP.
    Carregado por scripts via @vrp/lib/utils.lua
]]

SERVER = IsDuplicityVersion()

-----------------------------------------------------------------------------------------------------------------------------------------
-- TABLE.MAXN (removido no Lua 5.4, necessário pelo vRP)
-----------------------------------------------------------------------------------------------------------------------------------------
if not table.maxn then
    local function _maxn(t)
        local max = 0
        for k in pairs(t) do
            local n = tonumber(k)
            if n and n > max then max = n end
        end
        return max
    end
    local ok = pcall(function() table.maxn = _maxn end)
    if not ok then
        rawset(table, 'maxn', _maxn)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- MODULE
-----------------------------------------------------------------------------------------------------------------------------------------
local modules = {}
function module(resource, patchs)
    if patchs == nil or not patchs then
        patchs = resource
        resource = "vrp"
    end

    local key = resource .. patchs
    local checkModule = modules[key]
    if checkModule then
        return checkModule
    else
        local code = LoadResourceFile(resource, patchs .. ".lua")
        if code then
            local floats = load(code, resource .. "/" .. patchs .. ".lua")
            if floats then
                local resAccept, resUlts = xpcall(floats, debug.traceback)
                if resAccept then
                    modules[key] = resUlts
                    return resUlts
                end
            end
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- ASYNC (usado pelo Proxy/Tunnel)
-----------------------------------------------------------------------------------------------------------------------------------------
local function wait(self)
    local rets = Citizen.Await(self.p)
    if not rets then
        if self.r then rets = self.r end
    end
    return table.unpack(rets, 1, table.maxn(rets))
end

local function areturn(self, ...)
    self.r = {...}
    self.p:resolve(self.r)
end

function async(func)
    if func then
        Citizen.CreateThreadNow(func)
    else
        return setmetatable({ wait = wait, p = promise.new() }, { __call = areturn })
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PARSEINT
-----------------------------------------------------------------------------------------------------------------------------------------
function parseInt(Value)
    local Result = 0
    local Number = tonumber(Value)
    if Number ~= nil then
        if Number > 0 then
            Result = math.floor(Number)
        end
    end
    return Result
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PARSEFLOAT
-----------------------------------------------------------------------------------------------------------------------------------------
function parseFloat(val)
    return tonumber(val) or 0.0
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FORMATNUMBER / PARSEFORMAT
-----------------------------------------------------------------------------------------------------------------------------------------
function formatNumber(n)
    if not n then return '0' end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

function parseFormat(number)
    local left, num, right = string.match(parseInt(number), "^([^%d]*%d)(%d*)(.-)$")
    if not left then return tostring(number) end
    return left .. (num:reverse():gsub("(%d%d%d)", "%1."):reverse()) .. right
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SPLITSTRING
-----------------------------------------------------------------------------------------------------------------------------------------
function splitString(str, symbol)
    local number = 1
    local tableResult = {}
    if symbol == nil then symbol = "-" end
    for s in string.gmatch(str, "([^" .. symbol .. "]+)") do
        tableResult[number] = s
        number = number + 1
    end
    return tableResult
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- CLASSWORK / CLASSCATEGORY
-----------------------------------------------------------------------------------------------------------------------------------------
function ClassWork(work)
    return work or 'Unknown'
end

function ClassCategory(Number)
    local Category = "B"
    if Number >= 100 and Number <= 200 then Category = "B+"
    elseif Number >= 201 and Number <= 350 then Category = "A"
    elseif Number >= 351 and Number <= 500 then Category = "A+"
    elseif Number >= 501 and Number <= 1000 then Category = "S"
    elseif Number >= 1001 then Category = "S+"
    end
    return Category
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- BLOODTYPES
-----------------------------------------------------------------------------------------------------------------------------------------
function bloodTypes(Number)
    local Types = { [1] = "A+", [2] = "B+", [3] = "A-", [4] = "B-" }
    return Types[Number]
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SANITIZESTRING
-----------------------------------------------------------------------------------------------------------------------------------------
local sanitize_tmp = {}
function sanitizeString(str, strchars, allow_policy)
    local r = ""
    local chars = sanitize_tmp[strchars]
    if chars == nil then
        chars = {}
        for i = 1, string.len(strchars) do
            chars[string.sub(strchars, i, i)] = true
        end
        sanitize_tmp[strchars] = chars
    end
    for i = 1, string.len(str) do
        local char = string.sub(str, i, i)
        if (allow_policy and chars[char]) or (not allow_policy and not chars[char]) then
            r = r .. char
        end
    end
    return r
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- COMPLETETIMERS / MINIMALTIMERS
-----------------------------------------------------------------------------------------------------------------------------------------
function completeTimers(Seconds)
    local Days = math.floor(Seconds / 86400)
    Seconds = Seconds - Days * 86400
    local Hours = math.floor(Seconds / 3600)
    Seconds = Seconds - Hours * 3600
    local Minutes = math.floor(Seconds / 60)
    Seconds = Seconds - Minutes * 60
    if Days > 0 then return string.format("<b>%d Dias</b>, <b>%d Horas</b>, <b>%d Minutos</b>", Days, Hours, Minutes)
    elseif Hours > 0 then return string.format("<b>%d Horas</b>, <b>%d Minutos</b> e <b>%d Segundos</b>", Hours, Minutes, Seconds)
    elseif Minutes > 0 then return string.format("<b>%d Minutos</b> e <b>%d Segundos</b>", Minutes, Seconds)
    elseif Seconds > 0 then return string.format("<b>%d Segundos</b>", Seconds)
    end
end

function minimalTimers(Seconds)
    local Days = math.floor(Seconds / 86400)
    Seconds = Seconds - Days * 86400
    local Hours = math.floor(Seconds / 3600)
    Seconds = Seconds - Hours * 3600
    local Minutes = math.floor(Seconds / 60)
    Seconds = Seconds - Minutes * 60
    if Days > 0 then return string.format("%d Dias, %d Horas", Days, Hours)
    elseif Hours > 0 then return string.format("%d Horas, %d Minutos", Hours, Minutes)
    elseif Minutes > 0 then return string.format("%d Minutos", Minutes)
    elseif Seconds > 0 then return string.format("%d Segundos", Seconds)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- MATHLEGTH
-----------------------------------------------------------------------------------------------------------------------------------------
function mathLegth(n)
    return math.ceil(n * 100) / 100
end
