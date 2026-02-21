--[[
    NOVA Bridge - ESX Server
    Ativo quando ESX está nos ActiveBridges
]]

if not BridgeConfig.ActiveBridges.esx then return end

local Nova = exports['nova_core']:GetObject()
local UsableItems = {}
local ServerCallbacks = {}

-- ============================================================
-- xPLAYER WRAPPER
-- ============================================================

local function WrapPlayer(novaPlayer)
    if not novaPlayer then
        return {
            source = 0, identifier = '', name = '', group = 'user', citizenid = '', variables = {},
            job = { name = 'unemployed', label = 'Desempregado', grade = 0, grade_name = '0', grade_label = '', grade_salary = 0, onDuty = false },
            getMoney = function() return 0 end, getAccount = function() return { name = 'unknown', money = 0, label = '' } end,
            getAccounts = function() return {} end, addMoney = function() end, removeMoney = function() end,
            addAccountMoney = function() end, removeAccountMoney = function() end, setAccountMoney = function() end,
            getJob = function(self) return self.job end, setJob = function() end, getDuty = function() return false end,
            setDuty = function() end, getInventory = function() return {} end, getInventoryItem = function() return nil end,
            addInventoryItem = function() end, removeInventoryItem = function() end, setInventoryItem = function() end,
            getInventoryWeight = function() return 0 end, getMaxWeight = function() return 100 end,
            canCarryItem = function() return true end, canSwapItem = function() return true end,
            getName = function() return '' end, setName = function() end, getIdentifier = function() return '' end,
            getGroup = function() return 'user' end, setGroup = function() end, set = function() end, get = function() return nil end,
            getCoords = function() return vector3(0,0,0) end, kick = function() end, showNotification = function() end,
            showHelpNotification = function() end, triggerEvent = function() end,
        }
    end

    local xPlayer = {}

    xPlayer.source = novaPlayer:GetSource()
    xPlayer.identifier = novaPlayer.identifier
    xPlayer.name = novaPlayer.name
    xPlayer.group = novaPlayer.group
    xPlayer.citizenid = novaPlayer.citizenid
    xPlayer.variables = {}

    local job = novaPlayer:GetJob() or {}
    xPlayer.job = {
        name = job.name or 'unemployed',
        label = job.label or 'Desempregado',
        grade = job.grade or 0,
        grade_name = tostring(job.grade or 0),
        grade_label = job.grade_label or '',
        grade_salary = job.salary or 0,
    }

    local function refreshPlayer()
        return exports['nova_core']:GetPlayer(xPlayer.source)
    end

    -- DINHEIRO

    function xPlayer.getMoney()
        local p = refreshPlayer()
        if p then return p:GetMoney('cash') end
        return 0
    end

    function xPlayer.getAccount(account)
        local p = refreshPlayer()
        if not p then return { name = account, money = 0, label = account } end
        local novaType = ESX.MapAccount(account)
        local amount = p:GetMoney(novaType)
        return {
            name = account,
            money = amount,
            label = account:sub(1, 1):upper() .. account:sub(2),
        }
    end

    function xPlayer.getAccounts()
        local p = refreshPlayer()
        local accounts = {}
        local accountList = {
            { name = 'money', novaType = 'cash' },
            { name = 'bank', novaType = 'bank' },
            { name = 'black_money', novaType = 'black_money' },
            { name = 'gems', novaType = 'gems' },
        }
        for _, acc in ipairs(accountList) do
            local amount = p and p:GetMoney(acc.novaType) or 0
            accounts[#accounts + 1] = {
                name = acc.name, money = amount,
                label = acc.name:sub(1, 1):upper() .. acc.name:sub(2),
            }
        end
        return accounts
    end

    function xPlayer.addMoney(amount, reason)
        local p = refreshPlayer()
        if p then p:AddMoney('cash', amount, reason or 'esx_bridge') end
    end

    function xPlayer.removeMoney(amount, reason)
        local p = refreshPlayer()
        if p then p:RemoveMoney('cash', amount, reason or 'esx_bridge') end
    end

    function xPlayer.addAccountMoney(account, amount, reason)
        local p = refreshPlayer()
        if p then p:AddMoney(ESX.MapAccount(account), amount, reason or 'esx_bridge') end
    end

    function xPlayer.removeAccountMoney(account, amount, reason)
        local p = refreshPlayer()
        if p then p:RemoveMoney(ESX.MapAccount(account), amount, reason or 'esx_bridge') end
    end

    function xPlayer.setAccountMoney(account, amount, reason)
        local p = refreshPlayer()
        if p then p:SetMoney(ESX.MapAccount(account), amount) end
    end

    -- EMPREGO

    function xPlayer.getJob()
        local p = refreshPlayer()
        if not p then return xPlayer.job end
        local j = p:GetJob()
        return {
            name = j.name, label = j.label, grade = j.grade,
            grade_name = tostring(j.grade), grade_label = j.grade_label,
            grade_salary = j.salary or 0,
        }
    end

    function xPlayer.setJob(name, grade)
        local p = refreshPlayer()
        if p then
            p:SetJob(name, grade or 0)
            local j = p:GetJob()
            xPlayer.job = {
                name = j.name, label = j.label, grade = j.grade,
                grade_name = tostring(j.grade), grade_label = j.grade_label,
                grade_salary = j.salary or 0,
            }
        end
    end

    function xPlayer.getDuty()
        local p = refreshPlayer()
        if p then
            local j = p:GetJob()
            return j.duty or false
        end
        return false
    end

    function xPlayer.setDuty(onDuty)
        local p = refreshPlayer()
        if p then
            local j = p:GetJob()
            if j.duty ~= onDuty then p:ToggleDuty() end
        end
    end

    -- INVENTÁRIO

    function xPlayer.getInventory()
        local p = refreshPlayer()
        if not p then return {} end
        local inv = p:GetInventory()
        local result = {}
        for _, item in pairs(inv) do
            result[#result + 1] = {
                name = item.name, label = item.label or item.name,
                count = item.amount or item.count or 0,
                weight = item.weight or 0, metadata = item.metadata or {},
                slot = item.slot,
            }
        end
        return result
    end

    function xPlayer.getInventoryItem(name)
        local p = refreshPlayer()
        if not p then return { name = name, label = name, count = 0 } end
        local count = p:GetItemCount(name)
        local itemData = exports['nova_core']:GetItems()
        local item = itemData and itemData[name]
        return {
            name = name, label = item and item.label or name,
            count = count, weight = item and item.weight or 0,
        }
    end

    function xPlayer.addInventoryItem(name, count, metadata, slot)
        local p = refreshPlayer()
        if p then p:AddItem(name, count, metadata) end
    end

    function xPlayer.removeInventoryItem(name, count, metadata, slot)
        local p = refreshPlayer()
        if p then p:RemoveItem(name, count) end
    end

    function xPlayer.setInventoryItem(name, count, metadata)
        local p = refreshPlayer()
        if not p then return end
        local current = p:GetItemCount(name)
        if count > current then
            p:AddItem(name, count - current, metadata)
        elseif count < current then
            p:RemoveItem(name, current - count)
        end
    end

    function xPlayer.getInventoryWeight()
        local p = refreshPlayer()
        if not p then return 0 end
        local inv = p:GetInventory()
        local weight = 0
        for _, item in pairs(inv) do
            weight = weight + (item.weight or 0) * (item.amount or item.count or 1)
        end
        return weight
    end

    function xPlayer.getMaxWeight()
        return 24000
    end

    function xPlayer.canCarryItem(name, count)
        return true
    end

    function xPlayer.canSwapItem(firstItem, firstCount, testItem, testCount)
        return true
    end

    function xPlayer.hasItem(name, count)
        local p = refreshPlayer()
        if not p then return false end
        return p:GetItemCount(name) >= (count or 1)
    end

    -- ARMAS (stubs compatíveis)

    function xPlayer.getLoadout()
        return {}
    end

    function xPlayer.addWeapon(weaponName, ammo)
        local p = refreshPlayer()
        if p then
            local ped = GetPlayerPed(xPlayer.source)
            if ped and DoesEntityExist(ped) then
                local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
                GiveWeaponToPed(ped, hash, ammo or 100, false, false)
            end
        end
    end

    function xPlayer.removeWeapon(weaponName, ammo)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            RemoveWeaponFromPed(ped, hash)
        end
    end

    function xPlayer.hasWeapon(weaponName)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            return HasPedGotWeapon(ped, hash, false)
        end
        return false
    end

    function xPlayer.getWeapon(weaponName)
        return nil
    end

    function xPlayer.addWeaponComponent(weaponName, componentName)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local wHash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            local cHash = type(componentName) == 'string' and joaat(componentName) or componentName
            GiveWeaponComponentToPed(ped, wHash, cHash)
        end
    end

    function xPlayer.removeWeaponComponent(weaponName, componentName)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local wHash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            local cHash = type(componentName) == 'string' and joaat(componentName) or componentName
            RemoveWeaponComponentFromPed(ped, wHash, cHash)
        end
    end

    function xPlayer.addWeaponAmmo(weaponName, ammoCount)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            SetPedAmmo(ped, hash, ammoCount)
        end
    end

    function xPlayer.removeWeaponAmmo(weaponName, ammoCount)
        -- Não há API nativa directa para isto
    end

    function xPlayer.setWeaponTint(weaponName, tintIndex)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            SetPedWeaponTintIndex(ped, hash, tintIndex)
        end
    end

    function xPlayer.getWeaponTint(weaponName)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local hash = type(weaponName) == 'string' and joaat(weaponName) or weaponName
            return GetPedWeaponTintIndex(ped, hash)
        end
        return 0
    end

    -- METADATA

    function xPlayer.set(key, value)
        if key == 'job' or key == 'job2' then return end
        local p = refreshPlayer()
        if p then p:SetMetadata(key, value) end
        xPlayer.variables[key] = value
    end

    function xPlayer.get(key)
        if key == 'job' then return xPlayer.getJob() end
        if xPlayer.variables[key] ~= nil then return xPlayer.variables[key] end
        local p = refreshPlayer()
        if p then return p:GetMetadata(key) end
        return nil
    end

    function xPlayer.setMeta(key, value, subValue)
        if subValue ~= nil then
            local meta = xPlayer.get(key)
            if type(meta) ~= 'table' then meta = {} end
            meta[value] = subValue
            xPlayer.set(key, meta)
        else
            xPlayer.set(key, value)
        end
    end

    function xPlayer.getMeta(key, subKey)
        local meta = xPlayer.get(key)
        if subKey and type(meta) == 'table' then
            return meta[subKey]
        end
        return meta
    end

    -- INFORMAÇÕES

    function xPlayer.getName()
        local p = refreshPlayer()
        if p then return p:GetFullName() end
        return xPlayer.name
    end

    function xPlayer.getIdentifier()
        return xPlayer.identifier
    end

    function xPlayer.getGroup()
        local p = refreshPlayer()
        if p then return p.group end
        return xPlayer.group
    end

    function xPlayer.setGroup(group)
        local p = refreshPlayer()
        if p then p.group = group; xPlayer.group = group end
    end

    function xPlayer.getCoords(vector)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            if vector then return coords end
            return { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
        end
        return vector and vector3(0, 0, 0) or { x = 0, y = 0, z = 0, heading = 0 }
    end

    function xPlayer.setCoords(coords, heading)
        local ped = GetPlayerPed(xPlayer.source)
        if ped and DoesEntityExist(ped) then
            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
            if heading then SetEntityHeading(ped, heading) end
        end
    end

    -- AÇÕES

    function xPlayer.kick(reason)
        local p = refreshPlayer()
        if p then p:Kick(reason) end
    end

    function xPlayer.ban(reason)
        local p = refreshPlayer()
        if p then p:Ban(reason) end
    end

    function xPlayer.showNotification(msg, flash, saveToBrief, hudColorIndex)
        exports['nova_core']:Notify(xPlayer.source, msg, 'info')
    end

    function xPlayer.showHelpNotification(msg, thisFrame, beep, duration)
        exports['nova_core']:Notify(xPlayer.source, msg, 'info', duration)
    end

    function xPlayer.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, xPlayer.source, ...)
    end

    function xPlayer.save()
        local p = refreshPlayer()
        if p then p:Save() end
    end

    function xPlayer.getPermissions()
        return {}
    end

    function xPlayer.hasPermission(perm)
        return exports['nova_core']:HasPermission(xPlayer.source, perm)
    end

    function xPlayer.getSession()
        return xPlayer.variables
    end

    return xPlayer
end

-- ============================================================
-- FUNÇÕES ESX GLOBAIS
-- ============================================================

function ESX.GetPlayerFromId(source)
    local novaPlayer = exports['nova_core']:GetPlayer(source)
    return WrapPlayer(novaPlayer)
end

function ESX.GetPlayerFromIdentifier(identifier)
    local novaPlayers = exports['nova_core']:GetPlayers()
    for _, data in ipairs(novaPlayers) do
        if data.player and data.player.identifier == identifier then
            return WrapPlayer(data.player)
        end
    end
    return nil
end

function ESX.GetPlayerFromCitizenId(citizenid)
    local novaPlayer = exports['nova_core']:GetPlayerByCitizenId(citizenid)
    return WrapPlayer(novaPlayer)
end

function ESX.GetPlayers()
    local novaPlayers = exports['nova_core']:GetPlayers()
    local sources = {}
    for _, data in ipairs(novaPlayers) do
        sources[#sources + 1] = data.source
    end
    return sources
end

function ESX.GetExtendedPlayers(key, val)
    local novaPlayers = exports['nova_core']:GetPlayers()
    local result = {}
    for _, data in ipairs(novaPlayers) do
        local xPlayer = WrapPlayer(data.player)
        if xPlayer then
            if not key then
                result[#result + 1] = xPlayer
            elseif key == 'job' and xPlayer.job and xPlayer.job.name == val then
                result[#result + 1] = xPlayer
            elseif key == 'group' and xPlayer.group == val then
                result[#result + 1] = xPlayer
            end
        end
    end
    return result
end

function ESX.GetNumPlayers()
    return #ESX.GetPlayers()
end

function ESX.GetPlayerCount()
    return ESX.GetNumPlayers()
end

-- CALLBACKS

function ESX.RegisterServerCallback(name, cb)
    exports['nova_core']:CreateCallback(name, cb)
    ServerCallbacks[name] = cb
end

function ESX.TriggerServerCallback(name, source, cb, ...)
    if ServerCallbacks[name] then
        ServerCallbacks[name](source, cb, ...)
    elseif Nova and Nova.ServerCallbacks and Nova.ServerCallbacks[name] then
        Nova.ServerCallbacks[name](source, cb, ...)
    end
end

-- ITEMS USÁVEIS

function ESX.RegisterUsableItem(name, cb) UsableItems[name] = cb end

function ESX.GetUsableItem(name)
    if UsableItems[name] then
        return { name = name, cb = UsableItems[name] }
    end
    return nil
end

function ESX.UseItem(source, name, ...)
    if UsableItems[name] then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            UsableItems[name](source, name, xPlayer.getInventoryItem(name), ...)
        end
    end
end

function ESX.Trace(msg)
    print('^3[ESX Bridge] ^0' .. tostring(msg))
end

-- SAVE FUNCTIONS

function ESX.SavePlayer(source)
    local p = exports['nova_core']:GetPlayer(source)
    if p then p:Save() end
end

function ESX.SavePlayers()
    local novaPlayers = exports['nova_core']:GetPlayers()
    for _, data in ipairs(novaPlayers) do
        if data.player then
            pcall(function() data.player:Save() end)
        end
    end
end

-- JOBS

function ESX.DoesJobExist(jobName, grade)
    local jobs = exports['nova_core']:GetJobs()
    if not jobs or not jobs[jobName] then return false end
    if grade then
        return jobs[jobName].grades and jobs[jobName].grades[grade] ~= nil
    end
    return true
end

function ESX.GetJobs()
    return exports['nova_core']:GetJobs() or {}
end

-- REGISTER COMMAND (compatibility wrapper)

function ESX.RegisterCommand(name, group, cb, allowConsole, suggestion)
    RegisterCommand(name, function(source, args, rawCommand)
        if source > 0 then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                if group and group ~= 'user' then
                    if not exports['nova_core']:HasPermission(source, group) then
                        return
                    end
                end
                cb(xPlayer, args, function(msg)
                    TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', msg } })
                end)
            end
        elseif allowConsole then
            cb(nil, args, print)
        end
    end, false)
end

-- MISC

function ESX.GetItemLabel(name)
    local items = exports['nova_core']:GetItems()
    if items and items[name] then
        return items[name].label or name
    end
    return name
end

function ESX.CreatePickup(pickupType, name, count, label, source, components, tintIndex)
    -- Stub: pickups não implementados nativamente
    print('^3[NOVA Bridge] ^0ESX.CreatePickup: stub - considere usar nova_inventory drops')
end

function ESX.ClearTimeout(id)
    -- Definido no shared
end

function ESX.SetTimeout(msec, cb)
    -- Definido no shared
    return SetTimeout(msec, cb)
end

-- ============================================================
-- EVENTOS NOVA → ESX
-- ============================================================

AddEventHandler('nova:server:onPlayerLoaded', function(source, novaPlayer)
    local xPlayer = WrapPlayer(novaPlayer)
    if xPlayer then
        ESX.IsReady = true
        TriggerEvent('esx:playerLoaded', source, xPlayer, false)
        TriggerClientEvent('esx:playerLoaded', source, {
            accounts = xPlayer.getAccounts(),
            coords = xPlayer.getCoords(true),
            identifier = xPlayer.identifier,
            inventory = xPlayer.getInventory(),
            job = xPlayer.getJob(),
            loadout = {},
            maxWeight = xPlayer.getMaxWeight(),
            money = xPlayer.getMoney(),
            group = xPlayer.group,
            firstName = novaPlayer.charinfo and novaPlayer.charinfo.firstname or '',
            lastName = novaPlayer.charinfo and novaPlayer.charinfo.lastname or '',
            dateofbirth = novaPlayer.charinfo and novaPlayer.charinfo.dateofbirth or '',
            sex = novaPlayer.charinfo and novaPlayer.charinfo.gender or 0,
            citizenid = xPlayer.citizenid,
        }, false)
    end
end)

AddEventHandler('nova:server:onJobChange', function(source, newJob, oldJob)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local esxJob = xPlayer.getJob()
        local esxOldJob = oldJob and {
            name = oldJob.name, label = oldJob.label, grade = oldJob.grade,
            grade_name = tostring(oldJob.grade), grade_label = oldJob.grade_label or '',
            grade_salary = oldJob.salary or 0,
        } or {}
        TriggerEvent('esx:setJob', source, esxJob, esxOldJob)
        TriggerClientEvent('esx:setJob', source, esxJob, esxOldJob)
    end
end)

AddEventHandler('nova:server:onPlayerDropped', function(source, citizenid, reason)
    TriggerEvent('esx:playerDropped', source, reason)
end)

AddEventHandler('nova:server:onPlayerLogout', function(source, citizenid)
    TriggerEvent('esx:playerLogout', source)
    TriggerClientEvent('esx:onPlayerLogout', source)
end)

AddEventHandler('nova:server:onMoneyChange', function(source, moneyType, action, amount, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local esxAccount = ESX.AccountMapReverse[moneyType] or moneyType
        TriggerEvent('esx:setAccountMoney', source, xPlayer.getAccount(esxAccount))
        TriggerClientEvent('esx:setAccountMoney', source, xPlayer.getAccount(esxAccount))
    end
end)

-- EXPORTS (nova_bridge + alias es_extended)

exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)

AddEventHandler('__cfx_export_es_extended_getSharedObject', function(setCB) setCB(function() return ESX end) end)
AddEventHandler('__cfx_export_es_extended_GetSharedObject', function(setCB) setCB(function() return ESX end) end)

RegisterNetEvent('esx:getSharedObject', function()
    local _source = source
    TriggerClientEvent('esx:getSharedObject', _source)
end)

RegisterNetEvent('esx:useItem', function(name)
    local _source = source
    ESX.UseItem(_source, name)
end)

print('^2[NOVA Bridge] ^0ESX Server bridge carregado')
