--[[
    NOVA Bridge - QBCore Server
    Ativo quando QBCore está nos ActiveBridges
]]

if not BridgeConfig.ActiveBridges.qbcore then return end

local Nova = exports['nova_core']:GetObject()
local UsableItems = {}
local ServerCallbacks = {}

-- Preencher QBCore.Shared com dados do NOVA
CreateThread(function()
    while not exports['nova_core']:IsFrameworkReady() do Wait(100) end
    Wait(1000)

    local ok, items = pcall(function() return exports['nova_core']:GetItems() end)
    if ok and items then
        for name, item in pairs(items) do
            pcall(function()
                QBCore.Shared.Items[name] = {
                    name = item.name or name, label = item.label or name,
                    weight = item.weight or 0, type = item.type or 'item',
                    image = item.image or (name .. '.png'), unique = item.unique or false,
                    useable = item.useable or false, shouldClose = item.shouldClose or true,
                    description = item.description or '', combinable = item.combinable,
                }
            end)
        end
    end

    local okJ, jobs = pcall(function() return exports['nova_core']:GetJobs() end)
    if okJ and jobs then QBCore.Shared.Jobs = jobs end

    local okG, gangs = pcall(function() return exports['nova_core']:GetGangs() end)
    if okG and gangs then QBCore.Shared.Gangs = gangs end

    QBCore.Config.Server.Uptime = os.time()
end)

-- ============================================================
-- QB PLAYER WRAPPER
-- ============================================================

local function WrapPlayer(novaPlayer)
    if not novaPlayer then return nil end

    local Player = {}
    Player.Functions = {}
    Player.Offline = false

    local function refreshPlayer()
        return exports['nova_core']:GetPlayer(novaPlayer:GetSource())
    end

    local job = novaPlayer:GetJob()
    local gang = novaPlayer:GetGang()

    Player.PlayerData = {
        source = novaPlayer:GetSource(),
        citizenid = novaPlayer:GetCitizenId(),
        name = novaPlayer.name,
        license = novaPlayer.identifier,
        cid = 1,
        charinfo = {
            firstname = novaPlayer.charinfo and novaPlayer.charinfo.firstname or '',
            lastname = novaPlayer.charinfo and novaPlayer.charinfo.lastname or '',
            birthdate = novaPlayer.charinfo and novaPlayer.charinfo.dateofbirth or '',
            gender = novaPlayer.charinfo and novaPlayer.charinfo.gender or 0,
            nationality = novaPlayer.charinfo and novaPlayer.charinfo.nationality or '',
            phone = novaPlayer.charinfo and novaPlayer.charinfo.phone or '',
            account = novaPlayer.charinfo and novaPlayer.charinfo.account or '0000000000',
            backstory = novaPlayer.charinfo and novaPlayer.charinfo.backstory or '',
        },
        money = {
            cash = novaPlayer:GetMoney('cash'),
            bank = novaPlayer:GetMoney('bank'),
            crypto = novaPlayer:GetMoney('black_money'),
            gems = novaPlayer:GetMoney('gems'),
        },
        job = {
            name = job.name, label = job.label, type = job.type,
            onduty = job.duty, payment = job.salary or 0, isboss = job.is_boss or false,
            grade = { name = tostring(job.grade), level = job.grade },
        },
        gang = {
            name = gang.name, label = gang.label, isboss = gang.is_boss or false,
            grade = { name = tostring(gang.grade), level = gang.grade },
        },
        metadata = novaPlayer:GetMetadata() or {},
        position = novaPlayer:GetPosition(),
        items = {},
        optin = true,
    }

    local inv = novaPlayer:GetInventory()
    if inv then
        for i, item in pairs(inv) do
            Player.PlayerData.items[i] = {
                name = item.name, label = item.label or item.name,
                amount = item.amount or item.count or 0,
                weight = item.weight or 0, info = item.metadata or {},
                type = item.type or 'item', slot = item.slot or i,
                image = item.image or (item.name .. '.png'),
                unique = item.unique or false,
                useable = item.useable or false,
                shouldClose = item.shouldClose or true,
                description = item.description or '',
            }
        end
    end

    -- Player.Functions

    function Player.Functions.UpdatePlayerData()
        local p = refreshPlayer()
        if not p then return end
        Player.PlayerData.money = {
            cash = p:GetMoney('cash'), bank = p:GetMoney('bank'),
            crypto = p:GetMoney('black_money'), gems = p:GetMoney('gems'),
        }
        local j = p:GetJob()
        Player.PlayerData.job = {
            name = j.name, label = j.label, type = j.type,
            onduty = j.duty, payment = j.salary or 0, isboss = j.is_boss or false,
            grade = { name = tostring(j.grade), level = j.grade },
        }
        local g = p:GetGang()
        Player.PlayerData.gang = {
            name = g.name, label = g.label, isboss = g.is_boss or false,
            grade = { name = tostring(g.grade), level = g.grade },
        }
        Player.PlayerData.metadata = p:GetMetadata() or {}
        Player.PlayerData.position = p:GetPosition()

        TriggerClientEvent('QBCore:Player:SetPlayerData', Player.PlayerData.source, Player.PlayerData)
    end

    function Player.Functions.SetPlayerData(key, val)
        Player.PlayerData[key] = val
    end

    function Player.Functions.GetMoney(moneyType)
        local p = refreshPlayer()
        if not p then return 0 end
        local novaType = moneyType == 'crypto' and 'black_money' or moneyType
        return p:GetMoney(novaType)
    end

    function Player.Functions.AddMoney(moneyType, amount, reason)
        local p = refreshPlayer()
        if not p then return false end
        local novaType = moneyType == 'crypto' and 'black_money' or moneyType
        local success = p:AddMoney(novaType, amount, reason)
        if success then
            Player.PlayerData.money[moneyType] = p:GetMoney(novaType)
            TriggerClientEvent('QBCore:Client:OnMoneyChange', Player.PlayerData.source, moneyType, amount, 'add', reason or '')
        end
        return success ~= false
    end

    function Player.Functions.RemoveMoney(moneyType, amount, reason)
        local p = refreshPlayer()
        if not p then return false end
        local novaType = moneyType == 'crypto' and 'black_money' or moneyType
        local success = p:RemoveMoney(novaType, amount, reason)
        if success then
            Player.PlayerData.money[moneyType] = p:GetMoney(novaType)
            TriggerClientEvent('QBCore:Client:OnMoneyChange', Player.PlayerData.source, moneyType, amount, 'remove', reason or '')
        end
        return success ~= false
    end

    function Player.Functions.SetMoney(moneyType, amount, reason)
        local p = refreshPlayer()
        if not p then return false end
        local novaType = moneyType == 'crypto' and 'black_money' or moneyType
        local success = p:SetMoney(novaType, amount)
        if success then
            Player.PlayerData.money[moneyType] = amount
            TriggerClientEvent('QBCore:Client:OnMoneyChange', Player.PlayerData.source, moneyType, amount, 'set', reason or '')
        end
        return success ~= false
    end

    function Player.Functions.SetJob(jobName, grade)
        local p = refreshPlayer()
        if not p then return false end
        local success = p:SetJob(jobName, grade or 0)
        if success then
            Player.Functions.UpdatePlayerData()
            TriggerEvent('QBCore:Server:OnJobUpdate', Player.PlayerData.source, Player.PlayerData.job)
            TriggerClientEvent('QBCore:Client:OnJobUpdate', Player.PlayerData.source, Player.PlayerData.job)
        end
        return success ~= false
    end

    function Player.Functions.SetGang(gangName, grade)
        local p = refreshPlayer()
        if not p then return false end
        local success = p:SetGang(gangName, grade or 0)
        if success then
            Player.Functions.UpdatePlayerData()
            TriggerEvent('QBCore:Server:OnGangUpdate', Player.PlayerData.source, Player.PlayerData.gang)
            TriggerClientEvent('QBCore:Client:OnGangUpdate', Player.PlayerData.source, Player.PlayerData.gang)
        end
        return success ~= false
    end

    function Player.Functions.SetMetaData(key, value)
        local p = refreshPlayer()
        if p then p:SetMetadata(key, value); Player.PlayerData.metadata[key] = value end
        TriggerClientEvent('QBCore:Player:SetPlayerData', Player.PlayerData.source, Player.PlayerData)
    end

    function Player.Functions.GetMetaData(key)
        local p = refreshPlayer()
        if p then return p:GetMetadata(key) end
        return Player.PlayerData.metadata and Player.PlayerData.metadata[key]
    end

    function Player.Functions.AddItem(item, amount, slot, info)
        local p = refreshPlayer()
        if not p then return false end
        local success = p:AddItem(item, amount, info)
        if success then
            Player.Functions.UpdatePlayerData()
            TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[item], 'add', amount)
        end
        return success ~= false
    end

    function Player.Functions.RemoveItem(item, amount, slot)
        local p = refreshPlayer()
        if not p then return false end
        local success = p:RemoveItem(item, amount)
        if success then
            Player.Functions.UpdatePlayerData()
            TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[item], 'remove', amount)
        end
        return success ~= false
    end

    function Player.Functions.HasItem(item, amount)
        local p = refreshPlayer()
        if not p then return false end
        return p:HasItem(item, amount or 1)
    end

    function Player.Functions.GetItemByName(item)
        local p = refreshPlayer()
        if not p then return nil end
        local count = p:GetItemCount(item)
        if count > 0 then
            local itemData = QBCore.Shared.Items[item]
            return {
                name = item, label = itemData and itemData.label or item,
                amount = count, info = {}, type = itemData and itemData.type or 'item',
                weight = itemData and itemData.weight or 0,
                image = itemData and itemData.image or (item .. '.png'),
            }
        end
        return nil
    end

    function Player.Functions.GetItemsByName(item)
        local result = {}
        local single = Player.Functions.GetItemByName(item)
        if single then result[#result + 1] = single end
        return result
    end

    function Player.Functions.GetItemCount(item)
        local p = refreshPlayer()
        if not p then return 0 end
        return p:GetItemCount(item)
    end

    function Player.Functions.ClearInventory(filterItems)
        -- Stub: requer implementação completa via nova_inventory
    end

    function Player.Functions.SetInventory(items, dontUpdateClient)
        Player.PlayerData.items = items
        if not dontUpdateClient then
            Player.Functions.UpdatePlayerData()
        end
    end

    function Player.Functions.SetJobDuty(onDuty)
        local p = refreshPlayer()
        if p then
            local j = p:GetJob()
            if j.duty ~= onDuty then p:ToggleDuty() end
        end
        Player.Functions.UpdatePlayerData()
    end

    function Player.Functions.Save()
        local p = refreshPlayer()
        if p then p:Save() end
    end

    function Player.Functions.Logout()
        local p = refreshPlayer()
        if p then p:Logout() end
    end

    function Player.Functions.Notify(text, nType, duration, subTitle, notifyId, style)
        if type(text) == 'table' then
            exports['nova_core']:Notify(Player.PlayerData.source, text.text or text.caption or '', text.type or nType or 'info', duration)
        else
            exports['nova_core']:Notify(Player.PlayerData.source, text, nType or 'info', duration)
        end
    end

    function Player.Functions.Kick(reason)
        local p = refreshPlayer()
        if p then p:Kick(reason or 'Kicked') end
    end

    function Player.Functions.Ban(reason, duration)
        local p = refreshPlayer()
        if p then p:Ban(reason or 'Banned') end
    end

    function Player.Functions.GetCitizenId()
        return Player.PlayerData.citizenid
    end

    function Player.Functions.SetCreditCard(number)
        Player.PlayerData.charinfo.account = number
    end

    return Player
end

-- ============================================================
-- FUNÇÕES QBCORE GLOBAIS
-- ============================================================

function QBCore.Functions.GetPlayer(source)
    local novaPlayer = exports['nova_core']:GetPlayer(source)
    return WrapPlayer(novaPlayer)
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local novaPlayer = exports['nova_core']:GetPlayerByCitizenId(citizenid)
    return WrapPlayer(novaPlayer)
end

function QBCore.Functions.GetPlayerByPhone(phone)
    local novaPlayers = exports['nova_core']:GetPlayers()
    for _, data in ipairs(novaPlayers) do
        if data.player and data.player.charinfo and data.player.charinfo.phone == phone then
            return WrapPlayer(data.player)
        end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    local novaPlayers = exports['nova_core']:GetPlayers()
    local sources = {}
    for _, data in ipairs(novaPlayers) do sources[#sources + 1] = data.source end
    return sources
end

function QBCore.Functions.GetQBPlayers()
    local novaPlayers = exports['nova_core']:GetPlayers()
    local result = {}
    for _, data in ipairs(novaPlayers) do
        local wrapped = WrapPlayer(data.player)
        if wrapped then result[data.source] = wrapped end
    end
    return result
end

function QBCore.Functions.GetPlayersOnDuty(job)
    local novaPlayers = exports['nova_core']:GetPlayers()
    local result = {}
    for _, data in ipairs(novaPlayers) do
        if data.player then
            local pJob = data.player:GetJob()
            if pJob.name == job and pJob.duty then result[#result + 1] = data.source end
        end
    end
    return result
end

function QBCore.Functions.GetDutyCount(job)
    return #QBCore.Functions.GetPlayersOnDuty(job)
end

function QBCore.Functions.GetBucketObjects()
    return {}
end

-- CALLBACKS

function QBCore.Functions.CreateCallback(name, cb)
    exports['nova_core']:CreateCallback(name, cb)
    ServerCallbacks[name] = cb
end

function QBCore.Functions.TriggerCallback(name, source, cb, ...)
    if ServerCallbacks[name] then
        ServerCallbacks[name](source, cb, ...)
    elseif Nova and Nova.ServerCallbacks and Nova.ServerCallbacks[name] then
        Nova.ServerCallbacks[name](source, cb, ...)
    end
end

-- ITEMS USÁVEIS

function QBCore.Functions.CreateUseableItem(name, cb) UsableItems[name] = cb end
function QBCore.Functions.CanUseItem(name) return UsableItems[name] ~= nil end

function QBCore.Functions.UseItem(source, name)
    if UsableItems[name] then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then UsableItems[name](source, Player.Functions.GetItemByName(name)) end
    end
end

-- NOTIFICAÇÕES

function QBCore.Functions.Notify(source, text, nType, duration)
    if type(text) == 'table' then
        local msg = text.text or text.caption or ''
        local typ = text.type or nType or 'info'
        exports['nova_core']:Notify(source, msg, typ, duration or text.duration)
    else
        if nType == 'primary' then nType = 'info' end
        exports['nova_core']:Notify(source, text, nType or 'info', duration)
    end
end

-- PERMISSÕES

function QBCore.Functions.HasPermission(source, permission)
    if permission == 'god' then
        return exports['nova_core']:IsAdmin(source)
    end
    return exports['nova_core']:HasPermission(source, permission)
end

function QBCore.Functions.AddPermission(source, permission)
    -- Stub: gestão de permissões é do nova_core
end

function QBCore.Functions.RemovePermission(source, permission)
    -- Stub
end

function QBCore.Functions.IsPlayerBanned(source)
    return false
end

function QBCore.Functions.IsLicenseInUse(license)
    return false
end

function QBCore.Functions.IsOptin(source)
    return true
end

function QBCore.Functions.ToggleOptin(source)
    -- Stub
end

function QBCore.Functions.IsPlayerAdmin(source)
    return exports['nova_core']:IsAdmin(source)
end

function QBCore.Functions.IsWhitelisted(source)
    return true
end

-- UTILIDADES

function QBCore.Functions.GetIdentifier(source, idType)
    local identifiers = GetPlayerIdentifiers(source)
    idType = idType or 'license'
    for _, id in ipairs(identifiers) do
        if string.find(id, idType .. ':') then return id end
    end
    return nil
end

function QBCore.Functions.GetSource(identifier)
    local novaPlayers = exports['nova_core']:GetPlayers()
    for _, data in ipairs(novaPlayers) do
        if data.player and data.player.identifier == identifier then return data.source end
    end
    return 0
end

function QBCore.Functions.GetCoords(entity)
    if entity and DoesEntityExist(entity) then
        return GetEntityCoords(entity)
    end
    return vector3(0, 0, 0)
end

function QBCore.Functions.SpawnVehicle(source, model, coords, warp)
    local hash = type(model) == 'string' and joaat(model) or model
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    while not DoesEntityExist(vehicle) do Wait(10) end
    if warp then
        local ped = GetPlayerPed(source)
        if ped and DoesEntityExist(ped) then
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
        end
    end
    return vehicle
end

function QBCore.Functions.Kick(source, reason, setKickReason, deferrals)
    local p = exports['nova_core']:GetPlayer(source)
    if p then p:Kick(reason or 'Kicked') end
end

function QBCore.Functions.IsServer()
    return true
end

-- COMMANDS

function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
    RegisterCommand(name, function(source, args, rawCommand)
        if source > 0 then
            if permission and permission ~= 'user' then
                if not exports['nova_core']:HasPermission(source, permission) then return end
            end
            callback(source, args)
        end
    end, false)
end

function QBCore.Commands.Refresh(source)
    -- Stub
end

-- ============================================================
-- EVENTOS NOVA → QBCORE
-- ============================================================

AddEventHandler('nova:server:onPlayerLoaded', function(source, novaPlayer)
    local Player = WrapPlayer(novaPlayer)
    if Player then
        QBCore.Players[source] = Player
        TriggerEvent('QBCore:Server:OnPlayerLoaded', Player)
        TriggerClientEvent('QBCore:Client:OnPlayerLoaded', source)
    end
end)

AddEventHandler('nova:server:onPlayerDropped', function(source, citizenid, reason)
    QBCore.Players[source] = nil
    TriggerEvent('QBCore:Server:OnPlayerUnload', source)
end)

AddEventHandler('nova:server:onPlayerLogout', function(source, citizenid)
    QBCore.Players[source] = nil
    TriggerEvent('QBCore:Server:OnPlayerUnload', source)
    TriggerClientEvent('QBCore:Client:OnPlayerUnload', source)
end)

AddEventHandler('nova:server:onJobChange', function(source, newJob, oldJob)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        TriggerEvent('QBCore:Server:OnJobUpdate', source, Player.PlayerData.job)
        TriggerClientEvent('QBCore:Client:OnJobUpdate', source, Player.PlayerData.job)
    end
end)

AddEventHandler('nova:server:onGangChange', function(source, newGang, oldGang)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        TriggerEvent('QBCore:Server:OnGangUpdate', source, Player.PlayerData.gang)
        TriggerClientEvent('QBCore:Client:OnGangUpdate', source, Player.PlayerData.gang)
    end
end)

AddEventHandler('nova:server:onMoneyChange', function(source, moneyType, action, amount, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local qbType = moneyType == 'black_money' and 'crypto' or moneyType
        local currentAmount = Player.Functions.GetMoney(qbType)
        TriggerClientEvent('QBCore:Client:OnMoneyChange', source, qbType, currentAmount, action or 'change', reason or '')
    end
end)

RegisterNetEvent('QBCore:Server:UseItem', function(item)
    local _source = source
    if item and item.name and UsableItems[item.name] then
        UsableItems[item.name](_source, item)
    end
end)

RegisterNetEvent('QBCore:ToggleDuty', function()
    local _source = source
    local Player = QBCore.Functions.GetPlayer(_source)
    if Player then
        Player.Functions.SetJobDuty(not Player.PlayerData.job.onduty)
    end
end)

RegisterNetEvent('QBCore:UpdatePlayer', function()
    local _source = source
    local Player = QBCore.Functions.GetPlayer(_source)
    if Player then
        Player.Functions.UpdatePlayerData()
    end
end)

-- EXPORTS (nova_bridge + alias qb-core)

exports('GetCoreObject', function() return QBCore end)

AddEventHandler('__cfx_export_qb-core_GetCoreObject', function(setCB) setCB(function() return QBCore end) end)
AddEventHandler('__cfx_export_qb-core_GetSharedObject', function(setCB) setCB(function() return QBCore end) end)

print('^2[NOVA Bridge] ^0QBCore Server bridge carregado')
