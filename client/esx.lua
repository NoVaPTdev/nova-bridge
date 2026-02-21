--[[
    NOVA Bridge - ESX Client
    Ativo quando ESX está nos ActiveBridges
]]

if not BridgeConfig.ActiveBridges.esx then return end

local isPlayerLoaded = false
local playerData = {}

CreateThread(function()
    while not exports['nova_core']:IsFrameworkReady() do Wait(100) end
    ESX.IsReady = true
end)

-- FUNÇÕES PRINCIPAIS

function ESX.IsPlayerLoaded()
    local ok, loaded = pcall(function() return exports['nova_core']:IsPlayerLoaded() end)
    return ok and loaded or isPlayerLoaded
end

function ESX.GetPlayerData()
    local ok, data = pcall(function() return exports['nova_core']:GetPlayerData() end)
    if not ok or not data then return playerData end

    local esxData = {
        identifier = data.identifier, name = data.name, group = data.group,
        citizenid = data.citizenid,
        firstName = data.charinfo and data.charinfo.firstname or '',
        lastName = data.charinfo and data.charinfo.lastname or '',
        dateofbirth = data.charinfo and data.charinfo.dateofbirth or '',
        sex = data.charinfo and data.charinfo.gender or 0,
        job = {
            name = data.job and data.job.name or 'desempregado',
            label = data.job and data.job.label or 'Desempregado',
            grade = data.job and data.job.grade or 0,
            grade_name = data.job and tostring(data.job.grade) or '0',
            grade_label = data.job and data.job.grade_label or 'Desempregado',
            grade_salary = data.job and data.job.salary or 0,
        },
        accounts = {
            { name = 'money', money = data.money and data.money.cash or 0, label = 'Money' },
            { name = 'bank', money = data.money and data.money.bank or 0, label = 'Bank' },
            { name = 'black_money', money = data.money and data.money.black_money or 0, label = 'Black Money' },
            { name = 'gems', money = data.money and data.money.gems or 0, label = 'Gems' },
        },
        inventory = {},
        loadout = {},
        maxWeight = 24000,
        metadata = data.metadata or {},
        coords = data.position or vector3(0, 0, 0),
        money = data.money and data.money.cash or 0,
    }
    playerData = esxData
    ESX.PlayerData = esxData
    return esxData
end

function ESX.SetPlayerData(key, val)
    playerData[key] = val
    ESX.PlayerData[key] = val
end

function ESX.GetAccount(accountName)
    local data = ESX.GetPlayerData()
    if data.accounts then
        for _, acc in ipairs(data.accounts) do
            if acc.name == accountName then return acc end
        end
    end
    return nil
end

-- CALLBACKS

function ESX.TriggerServerCallback(name, cb, ...)
    exports['nova_core']:TriggerCallback(name, cb, ...)
end

function ESX.ServerCallback(name, cb, ...)
    ESX.TriggerServerCallback(name, cb, ...)
end

-- NOTIFICAÇÕES

function ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    exports['nova_core']:ClientNotify(msg, 'info')
end

function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    local fullMsg = (sender and sender ~= '') and (sender .. ': ' .. msg) or msg
    exports['nova_core']:ClientNotify(fullMsg, 'info')
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    exports['nova_core']:ClientNotify(msg, 'info', duration or 5000)
end

function ESX.ShowFloatingHelpNotification(msg, coords)
    exports['nova_core']:ClientNotify(msg, 'info')
end

function ESX.TextUI(msg, position)
    exports['nova_core']:ClientNotify(msg, 'info')
end

function ESX.HideUI()
    -- Stub
end

-- ESX.Game

ESX.Game = {}

function ESX.Game.Teleport(entity, coords, heading, cb)
    local x, y, z = coords.x, coords.y, coords.z
    SetEntityCoords(entity, x, y, z, false, false, false, true)
    if heading then SetEntityHeading(entity, heading) end
    if cb then cb() end
end

function ESX.Game.SpawnVehicle(modelName, coords, heading, cb, networked)
    local model = type(modelName) == 'string' and joaat(modelName) or modelName
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10); timeout = timeout + 10
        if timeout > 10000 then if cb then cb(nil) end return end
    end
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, networked ~= false, false)
    SetModelAsNoLongerNeeded(model)
    if cb then cb(vehicle) end
    return vehicle
end

function ESX.Game.SpawnLocalVehicle(modelName, coords, heading, cb)
    return ESX.Game.SpawnVehicle(modelName, coords, heading, cb, false)
end

function ESX.Game.DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then SetEntityAsMissionEntity(vehicle, true, true); DeleteVehicle(vehicle) end
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    local vehicles, result = GetGamePool('CVehicle'), {}
    for _, v in ipairs(vehicles) do if #(coords - GetEntityCoords(v)) <= maxDistance then result[#result+1] = v end end
    return result
end

function ESX.Game.GetVehicles()
    return GetGamePool('CVehicle')
end

function ESX.Game.GetPedsInArea(coords, maxDistance)
    local peds, result = GetGamePool('CPed'), {}
    for _, p in ipairs(peds) do if #(coords - GetEntityCoords(p)) <= maxDistance then result[#result+1] = p end end
    return result
end

function ESX.Game.GetPeds(onlyOtherPeds)
    local peds = GetGamePool('CPed')
    if onlyOtherPeds then
        local myPed = PlayerPedId()
        local result = {}
        for _, p in ipairs(peds) do
            if p ~= myPed then result[#result + 1] = p end
        end
        return result
    end
    return peds
end

function ESX.Game.GetObjects()
    return GetGamePool('CObject')
end

function ESX.Game.GetPlayers(onlyOtherPlayers, returnPeds, returnCoords)
    local players = GetActivePlayers()
    local myPed = PlayerPedId()
    local result = {}
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if not onlyOtherPlayers or ped ~= myPed then
            local entry = pid
            if returnPeds then
                entry = { id = pid, ped = ped }
                if returnCoords then
                    entry.coords = GetEntityCoords(ped)
                end
            end
            result[#result + 1] = entry
        end
    end
    return result
end

function ESX.Game.GetClosestVehicle(coords, maxDistance)
    local vehicles = GetGamePool('CVehicle')
    local closest, closestDist = nil, maxDistance or 100.0
    for _, v in ipairs(vehicles) do
        local dist = #(coords - GetEntityCoords(v))
        if dist < closestDist then closest, closestDist = v, dist end
    end
    return closest, closestDist
end

function ESX.Game.GetClosestPed(coords, maxDistance)
    local peds = GetGamePool('CPed')
    local closest, closestDist, myPed = nil, maxDistance or 100.0, PlayerPedId()
    for _, p in ipairs(peds) do
        if p ~= myPed then
            local dist = #(coords - GetEntityCoords(p))
            if dist < closestDist then closest, closestDist = p, dist end
        end
    end
    return closest, closestDist
end

function ESX.Game.GetClosestPlayer(coords, maxDistance)
    local players = GetActivePlayers()
    local closest, closestDist, myPed = -1, maxDistance or 100.0, PlayerPedId()
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if ped ~= myPed and coords then
            local dist = #(coords - GetEntityCoords(ped))
            if dist < closestDist then closest, closestDist = pid, dist end
        end
    end
    return closest, closestDist
end

function ESX.Game.GetClosestObject(coords, maxDistance, modelFilter)
    local objects = GetGamePool('CObject')
    local closest, closestDist = nil, maxDistance or 100.0
    for _, obj in ipairs(objects) do
        if not modelFilter or GetEntityModel(obj) == modelFilter then
            local dist = #(coords - GetEntityCoords(obj))
            if dist < closestDist then closest, closestDist = obj, dist end
        end
    end
    return closest, closestDist
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    local players, result = GetActivePlayers(), {}
    for _, pid in ipairs(players) do
        if #(coords - GetEntityCoords(GetPlayerPed(pid))) <= maxDistance then result[#result+1] = pid end
    end
    return result
end

function ESX.Game.IsSpawnPointClear(coords, maxDistance)
    return #ESX.Game.GetVehiclesInArea(coords, maxDistance or 3.0) == 0
end

function ESX.Game.SpawnObject(modelName, coords, cb, networked)
    local model = type(modelName) == 'string' and joaat(modelName) or modelName
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10); timeout = timeout + 10
        if timeout > 10000 then if cb then cb(nil) end return end
    end
    local obj = CreateObject(model, coords.x, coords.y, coords.z, networked ~= false, false, false)
    SetModelAsNoLongerNeeded(model)
    if cb then cb(obj) end
    return obj
end

function ESX.Game.DeleteObject(object)
    if DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, true, true)
        DeleteObject(object)
    end
end

function ESX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwdVector = GetEntityForwardVector(ped)
    local fwdCoords = coords + fwdVector * 5.0
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, fwdCoords.x, fwdCoords.y, fwdCoords.z, 10, ped, 0)
    local _, hit, _, _, vehicle = GetShapeTestResult(rayHandle)
    if hit == 1 and vehicle and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2 then
        return vehicle
    end
    return nil
end

function ESX.Game.GetVehicleLabel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    local name = GetLabelText(GetDisplayNameFromVehicleModel(hash))
    if name == 'NULL' then
        name = GetDisplayNameFromVehicleModel(hash)
    end
    return name
end

function ESX.Game.IsVehicleEmpty(vehicle)
    if not DoesEntityExist(vehicle) then return true end
    local passengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for i = -1, passengers do
        if not IsVehicleSeatFree(vehicle, i) then
            return false
        end
    end
    return true
end

function ESX.Game.GetPedMugshot(ped, transparent)
    if transparent then
        return RegisterPedheadshot_3(ped)
    else
        return RegisterPedheadshot(ped)
    end
end

function ESX.Game.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    if props.color1 and props.color2 then SetVehicleColours(vehicle, props.color1, props.color2) end
    if props.pearlescentColor and props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor) end
    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
    if props.neonEnabled then for i=1,4 do SetVehicleNeonLightEnabled(vehicle, i-1, props.neonEnabled[i]) end end
    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1] or 0, props.neonColor[2] or 0, props.neonColor[3] or 0) end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1] or 0, props.tyreSmokeColor[2] or 0, props.tyreSmokeColor[3] or 0) end
    local mods = {[0]='modSpoilers',[1]='modFrontBumper',[2]='modRearBumper',[3]='modSideSkirt',[4]='modExhaust',[5]='modFrame',[6]='modGrille',[7]='modHood',[8]='modFender',[9]='modRightFender',[10]='modRoof',[11]='modEngine',[12]='modBrakes',[13]='modTransmission',[14]='modHorns',[15]='modSuspension',[16]='modArmor',[23]='modFrontWheels',[24]='modBackWheels'}
    for slot, key in pairs(mods) do if props[key] then SetVehicleMod(vehicle, slot, props[key], false) end end
    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end
    if props.xenonColor ~= nil then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
    if props.modLivery then SetVehicleMod(vehicle, 48, props.modLivery, false); SetVehicleLivery(vehicle, props.modLivery) end
    if props.extras then
        for k, v in pairs(props.extras) do
            local id = tonumber(k)
            if id and DoesExtraExist(vehicle, id) then
                SetVehicleExtra(vehicle, id, not v)
            end
        end
    end
end

function ESX.Game.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local r1, g1, b1 = GetVehicleNeonLightsColour(vehicle)
    local r2, g2, b2 = GetVehicleTyreSmokeColor(vehicle)

    local props = {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        tankHealth = GetVehiclePetrolTankHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        color1 = colorPrimary, color2 = colorSecondary,
        pearlescentColor = pearlescentColor, wheelColor = wheelColor,
        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColour(vehicle),
        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3)
        },
        neonColor = { r1, g1, b1 },
        tyreSmokeColor = { r2, g2, b2 },
        modSpoilers = GetVehicleMod(vehicle, 0), modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2), modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4), modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6), modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8), modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10), modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12), modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14), modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),
        modTurbo = IsToggleModOn(vehicle, 18), modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),
        modFrontWheels = GetVehicleMod(vehicle, 23), modBackWheels = GetVehicleMod(vehicle, 24),
        modLivery = GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
        extras = {},
    }

    for i = 0, 14 do
        if DoesExtraExist(vehicle, i) then
            props.extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    return props
end

-- ESX.Streaming

ESX.Streaming = {}

function ESX.Streaming.RequestModel(model, cb)
    if type(model) == 'string' then model = joaat(model) end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimDict(dict, cb)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimSet(set, cb)
    RequestAnimSet(set)
    local timeout = 0
    while not HasAnimSetLoaded(set) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestNamedPtfxAsset(asset, cb)
    RequestNamedPtfxAsset(asset)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(asset) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestTexture(dict, cb)
    RequestStreamedTextureDict(dict)
    local timeout = 0
    while not HasStreamedTextureDictLoaded(dict) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb() end
end

function ESX.Streaming.RequestScaleformMovie(scaleform, cb)
    local handle = RequestScaleformMovie(scaleform)
    local timeout = 0
    while not HasScaleformMovieLoaded(handle) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if cb then cb(handle) end
    return handle
end

-- ESX.UI (stubs)

ESX.UI = {}; ESX.UI.Menu = {}; ESX.UI.Menu.Opened = {}
ESX.UI.HUD = {}

function ESX.UI.Menu.Open(menuType, namespace, name, data, submit, cancel)
    print('^3[NOVA Bridge] ^0ESX.UI.Menu nao suportado - usa ox_lib')
end
function ESX.UI.Menu.Close(menuType, namespace, name) end
function ESX.UI.Menu.CloseAll() end
function ESX.UI.Menu.GetOpened(menuType, namespace, name) return nil end
function ESX.UI.Menu.GetOpenedMenus() return {} end
function ESX.UI.Menu.IsOpen(menuType, namespace, name) return false end
function ESX.UI.Menu.RegisterType(menuType, open, close) end

function ESX.UI.HUD.RegisterElement(name, index, priority, html, data) end
function ESX.UI.HUD.RemoveElement(name) end
function ESX.UI.HUD.SetDisplay(opacity) end
function ESX.UI.HUD.UpdateElement(name, data) end

-- EVENTOS NOVA → ESX

RegisterNetEvent('nova:client:onPlayerLoaded', function(data)
    isPlayerLoaded = true
    ESX.PlayerLoaded = true
    playerData = ESX.GetPlayerData()
    ESX.PlayerData = playerData
    TriggerEvent('esx:playerLoaded', playerData, false)
end)

RegisterNetEvent('nova:client:onLogout', function()
    isPlayerLoaded = false
    ESX.PlayerLoaded = false
    playerData = {}
    ESX.PlayerData = {}
    TriggerEvent('esx:onPlayerLogout')
end)

RegisterNetEvent('nova:client:updatePlayerData', function(data)
    playerData = ESX.GetPlayerData()
    ESX.PlayerData = playerData

    if data and data.type == 'job' then
        TriggerEvent('esx:setJob', playerData.job)
    elseif data and data.type == 'money' then
        if playerData.accounts then
            for _, acc in ipairs(playerData.accounts) do
                TriggerEvent('esx:setAccountMoney', acc)
            end
        end
    elseif data and data.type == 'gang' then
        -- ESX não tem evento nativo de gang, mas atualiza os dados
    end
end)

RegisterNetEvent('esx:getSharedObject', function() end)
AddEventHandler('esx:getSharedObject', function(cb) if cb and type(cb) == 'function' then cb(ESX) end end)

exports('getSharedObject', function() return ESX end)
exports('GetSharedObject', function() return ESX end)

AddEventHandler('__cfx_export_es_extended_getSharedObject', function(setCB) setCB(function() return ESX end) end)
AddEventHandler('__cfx_export_es_extended_GetSharedObject', function(setCB) setCB(function() return ESX end) end)

print('^2[NOVA Bridge] ^0ESX Client bridge carregado')
