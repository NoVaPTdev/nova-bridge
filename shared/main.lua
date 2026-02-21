--[[
    NOVA Bridge - Shared
    Inicializa os objetos globais baseado no modo configurado.
    Suporta auto-deteção e múltiplos bridges em simultâneo.
]]

-- ============================================================
-- GLOBALS ESSENCIAIS (Creative/vRP compat)
-- ============================================================

SERVER = IsDuplicityVersion()

local function _maxn(t)
    local max = 0
    for k in pairs(t) do
        local n = tonumber(k)
        if n and n > max then max = n end
    end
    return max
end

if not table.maxn then
    local ok = pcall(function() table.maxn = _maxn end)
    if not ok then
        rawset(table, 'maxn', _maxn)
    end
end

local _modules = {}
function module(resource, patchs)
    if patchs == nil or not patchs then
        patchs = resource
        resource = "vrp"
    end

    local key = resource .. patchs
    local cached = _modules[key]
    if cached then
        return cached
    end

    local code = LoadResourceFile(resource, patchs .. ".lua")
    if code then
        local fn = load(code, resource .. "/" .. patchs .. ".lua")
        if fn then
            local ok, result = xpcall(fn, debug.traceback)
            if ok then
                _modules[key] = result
                return result
            else
                print("^1[NOVA Bridge] module error loading " .. resource .. "/" .. patchs .. ": " .. tostring(result) .. "^0")
            end
        end
    end
end

local function _async_wait(self)
    local rets = Citizen.Await(self.p)
    if not rets then
        if self.r then rets = self.r end
    end
    if rets then
        return table.unpack(rets, 1, table.maxn(rets))
    end
end

local function _async_return(self, ...)
    self.r = {...}
    self.p:resolve(self.r)
end

function async(func)
    if func then
        Citizen.CreateThreadNow(func)
    else
        return setmetatable({ wait = _async_wait, p = promise.new() }, { __call = _async_return })
    end
end

function parseInt(Value)
    local Number = tonumber(Value)
    if Number and Number > 0 then
        return math.floor(Number)
    end
    return 0
end

function parseFloat(val)
    return tonumber(val) or 0.0
end

-- ============================================================
-- PARSE MODE → ActiveBridges set
-- ============================================================

BridgeConfig.ActiveBridges = {}

local mode = BridgeConfig.Mode or 'none'

if mode == 'auto' then
    BridgeConfig.ActiveBridges = { esx = true, qbcore = true, creative = true }

elseif mode == 'none' then
    BridgeConfig.ActiveBridges = {}

elseif type(mode) == 'table' then
    for _, m in ipairs(mode) do
        BridgeConfig.ActiveBridges[m] = true
    end

else
    BridgeConfig.ActiveBridges[mode] = true
end

-- Creative is a superset of vRPex: if both requested, only creative runs
if BridgeConfig.ActiveBridges.creative then
    BridgeConfig.ActiveBridges.vrpex = nil
end

-- If vrpex requested without creative, keep it
if BridgeConfig.ActiveBridges.vrpex then
    BridgeConfig.ActiveBridges.creative = nil
end

-- ============================================================
-- ESX GLOBALS
-- ============================================================

if BridgeConfig.ActiveBridges.esx then
    ESX = {}
    ESX.PlayerData = {}
    ESX.PlayerLoaded = false
    ESX.IsReady = false

    ESX.AccountMap = {
        money = 'cash',
        cash = 'cash',
        bank = 'bank',
        black_money = 'black_money',
        dirty_money = 'black_money',
        gems = 'gems',
    }

    ESX.AccountMapReverse = {
        cash = 'money',
        bank = 'bank',
        black_money = 'black_money',
        gems = 'gems',
    }

    function ESX.MapAccount(account)
        return ESX.AccountMap[account] or account
    end

    function ESX.GetSharedObject()
        return ESX
    end

    ESX.OneSync = {
        State = GetConvar('onesync', 'off') ~= 'off',
    }

    ESX.Math = {}

    function ESX.Math.Round(value, numDecimalPlaces)
        if numDecimalPlaces then
            local power = 10 ^ numDecimalPlaces
            return math.floor((value * power) + 0.5) / power
        end
        return math.floor(value + 0.5)
    end

    function ESX.Math.GroupDigits(value)
        local left, num, right = string.match(tostring(value), '^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
    end

    function ESX.Math.Trim(value)
        if not value then return '' end
        return (string.gsub(tostring(value), '^%s*(.-)%s*$', '%1'))
    end

    ESX.Table = {}

    function ESX.Table.SizeOf(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end

    function ESX.Table.Set(t)
        local set = {}
        for _, v in ipairs(t) do set[v] = true end
        return set
    end

    function ESX.Table.IndexOf(t, value)
        for i, v in ipairs(t) do
            if v == value then return i end
        end
        return -1
    end

    function ESX.Table.LastIndexOf(t, value)
        for i = #t, 1, -1 do
            if t[i] == value then return i end
        end
        return -1
    end

    function ESX.Table.Find(t, cb)
        for i, v in ipairs(t) do
            if cb(v) then return v end
        end
        return nil
    end

    function ESX.Table.FindIndex(t, cb)
        for i, v in ipairs(t) do
            if cb(v) then return i end
        end
        return -1
    end

    function ESX.Table.Filter(t, cb)
        local result = {}
        for i, v in ipairs(t) do
            if cb(v) then result[#result + 1] = v end
        end
        return result
    end

    function ESX.Table.Map(t, cb)
        local result = {}
        for i, v in ipairs(t) do
            result[#result + 1] = cb(v, i)
        end
        return result
    end

    function ESX.Table.Reverse(t)
        local result = {}
        for i = #t, 1, -1 do result[#result + 1] = t[i] end
        return result
    end

    function ESX.Table.Clone(t)
        if type(t) ~= 'table' then return t end
        local result = {}
        for k, v in pairs(t) do result[k] = ESX.Table.Clone(v) end
        return setmetatable(result, getmetatable(t))
    end

    function ESX.Table.Concat(t1, t2)
        local result = {}
        for _, v in ipairs(t1) do result[#result + 1] = v end
        for _, v in ipairs(t2) do result[#result + 1] = v end
        return result
    end

    function ESX.Table.Join(t, sep)
        return table.concat(t, sep or ', ')
    end

    function ESX.Table.Contains(t, value)
        for _, v in pairs(t) do
            if v == value then return true end
        end
        return false
    end

    function ESX.Table.Every(t, cb)
        for _, v in ipairs(t) do
            if not cb(v) then return false end
        end
        return true
    end

    function ESX.Table.Some(t, cb)
        for _, v in ipairs(t) do
            if cb(v) then return true end
        end
        return false
    end

    function ESX.Table.Sort(t, sortFunction)
        table.sort(t, sortFunction)
    end

    local timeoutCount = 0
    local timeouts = {}

    function ESX.SetTimeout(msec, cb)
        timeoutCount = timeoutCount + 1
        local id = timeoutCount
        timeouts[id] = true
        SetTimeout(msec, function()
            if timeouts[id] then
                timeouts[id] = nil
                cb()
            end
        end)
        return id
    end

    function ESX.ClearTimeout(id)
        timeouts[id] = nil
    end
end

-- ============================================================
-- QBCORE GLOBALS
-- ============================================================

if BridgeConfig.ActiveBridges.qbcore then
    QBCore = {}
    QBCore.Functions = {}
    QBCore.Players = {}
    QBCore.Player = {}
    QBCore.Config = {}
    QBCore.Commands = {}
    QBCore.Commands.List = {}
    QBCore.Commands.Refresh = function() end

    QBCore.Config.Money = {
        MoneyTypes = { cash = 'cash', bank = 'bank', crypto = 'black_money', gems = 'gems' },
        DefaultMoney = { cash = 5000, bank = 10000, crypto = 0, gems = 0 },
        DontAllowMinus = { 'cash', 'bank', 'gems' },
    }

    QBCore.Config.Server = {
        PVP = true,
        Closed = false,
        ClosedReason = 'Server Closed',
        Uptime = 0,
        Whitelist = false,
        WhitelistPermission = 'admin',
        Discord = '',
        CheckDuplicateLicense = true,
    }

    QBCore.Config.Player = {
        HungerRate = 4.2,
        ThirstRate = 3.8,
        Bloodtypes = {'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'},
    }

    QBCore.Config.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)

    QBCore.Shared = {}
    QBCore.Shared.Items = {}
    QBCore.Shared.Jobs = {}
    QBCore.Shared.Gangs = {}
    QBCore.Shared.Vehicles = {}
    QBCore.Shared.Weapons = {}
    QBCore.Shared.Locations = {}
    QBCore.Shared.StarterItems = {}
    QBCore.Shared.ForceJobDefaultDutyAtLogin = true
    QBCore.Shared.EnablePeacetime = false

    QBCore.Shared.SplitStr = function(str, sep)
        local result = {}
        for part in string.gmatch(str, '([^' .. sep .. ']+)') do
            result[#result + 1] = part
        end
        return result
    end

    QBCore.Shared.RandomStr = function(length)
        local result = ''
        local chars = 'abcdefghijklmnopqrstuvwxyz'
        for i = 1, length do
            local idx = math.random(1, #chars)
            result = result .. chars:sub(idx, idx)
        end
        return result
    end

    QBCore.Shared.RandomInt = function(length)
        local result = ''
        for i = 1, length do
            result = result .. tostring(math.random(0, 9))
        end
        return tonumber(result)
    end

    QBCore.Shared.Round = function(value, numDecimalPlaces)
        if numDecimalPlaces then
            local power = 10 ^ numDecimalPlaces
            return math.floor((value * power) + 0.5) / power
        end
        return math.floor(value + 0.5)
    end

    QBCore.Shared.MathRound = QBCore.Shared.Round

    QBCore.Shared.ChangeVehicleExtra = function(vehicle, extra, enable)
        if DoesExtraExist(vehicle, extra) then
            SetVehicleExtra(vehicle, extra, not enable)
        end
    end

    QBCore.Shared.SetDefaultVehicleExtras = function(vehicle, config)
        for i = 0, 20 do
            if DoesExtraExist(vehicle, i) then
                local enable = config and config[tostring(i)] or false
                SetVehicleExtra(vehicle, i, not enable)
            end
        end
    end

    function QBCore.GetCoreObject()
        return QBCore
    end

    function QBCore.Debug(resource, obj, depth)
        local prefix = '^3[QBCore Debug]^0 [' .. (resource or 'unknown') .. '] '
        if type(obj) == 'table' then
            print(prefix .. json.encode(obj, {indent = true}))
        else
            print(prefix .. tostring(obj))
        end
    end
end

-- ============================================================
-- vRPex / CREATIVE GLOBALS
-- ============================================================

if BridgeConfig.ActiveBridges.vrpex or BridgeConfig.ActiveBridges.creative then
    -- Proxy/Tunnel initialized by server/client bridge files
end

-- ============================================================
-- PRINT ACTIVE BRIDGES
-- ============================================================

local activeList = {}
for bridge, _ in pairs(BridgeConfig.ActiveBridges) do
    activeList[#activeList + 1] = bridge
end

if #activeList > 0 then
    table.sort(activeList)
    print('^2[NOVA Bridge] ^0Bridges ativos: ^3' .. table.concat(activeList, ', ') .. '^0')
else
    print('^3[NOVA Bridge] ^0Nenhum bridge ativo')
end
