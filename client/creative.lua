--[[
    NOVA Bridge - Creative Client
    Ativo quando Creative está nos ActiveBridges
    
    Implementa a API Creative client-side mapeada para o NOVA Framework.
    Scripts acedem via Tunnel.getInterface("vRP").
]]

if not BridgeConfig.ActiveBridges.creative then return end

local isReady = false

CreateThread(function()
    while not exports['nova_core']:IsFrameworkReady() do Wait(100) end
    isReady = true
end)

-- ============================================================
-- CARREGAR LIBS CREATIVE
-- ============================================================

local Proxy = module("vrp", "lib/Proxy")
local Tunnel = module("vrp", "lib/Tunnel")

-- ============================================================
-- vRP CLIENT INTERFACE (TUNNEL - chamada pelo server)
-- ============================================================

local vRPclient = {}

function vRPclient.teleport(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
end

function vRPclient.isInside()
    return GetInteriorFromEntity(PlayerPedId()) ~= 0
end

function vRPclient.getCamDirection()
    local heading = GetGameplayCamRelativeHeading()
    local pitch = GetGameplayCamRelativePitch()
    local x = -math.sin(heading * math.pi / 180.0) * math.abs(math.cos(pitch * math.pi / 180.0))
    local y = math.cos(heading * math.pi / 180.0) * math.abs(math.cos(pitch * math.pi / 180.0))
    local z = math.sin(pitch * math.pi / 180.0)
    return x, y, z
end

function vRPclient.getNearestPlayers(radius)
    radius = radius or 10.0
    local result = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if ped ~= myPed then
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist <= radius then
                result[GetPlayerServerId(pid)] = dist
            end
        end
    end
    return result
end

function vRPclient.getNearestPlayer(radius)
    radius = radius or 10.0
    local nearest = nil
    local nearestDist = radius
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if ped ~= myPed then
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < nearestDist then
                nearest = GetPlayerServerId(pid)
                nearestDist = dist
            end
        end
    end
    return nearest
end

function vRPclient.playAnim(upper, seq, looping)
    if type(seq) ~= 'table' then return end
    local ped = PlayerPedId()
    for _, anim in ipairs(seq) do
        if anim[1] and anim[2] then
            RequestAnimDict(anim[1])
            local timeout = 0
            while not HasAnimDictLoaded(anim[1]) and timeout < 5000 do
                Wait(10)
                timeout = timeout + 10
            end
            if HasAnimDictLoaded(anim[1]) then
                local flags = looping and 1 or 0
                if upper then flags = flags + 48 end
                TaskPlayAnim(ped, anim[1], anim[2], 8.0, -8.0, -1, flags, 0, false, false, false)
            end
        end
    end
end

function vRPclient.stopAnim(upper)
    local ped = PlayerPedId()
    if upper then
        ClearPedSecondaryTask(ped)
    else
        ClearPedTasks(ped)
    end
end

function vRPclient.playSound(dict, name)
    PlaySoundFrontend(-1, name, dict, true)
end

function vRPclient.playScreenEffect(effect, duration)
    StartScreenEffect(effect, 0, false)
    if duration and duration > 0 then
        SetTimeout(duration, function()
            StopScreenEffect(effect)
        end)
    end
end

function vRPclient.setHandcuffed(state)
    local ped = PlayerPedId()
    if state then
        SetEnableHandcuffs(ped, true)
        DisablePlayerFiring(ped, true)
    else
        SetEnableHandcuffs(ped, false)
        DisablePlayerFiring(ped, false)
    end
end

function vRPclient.setFreeze(state)
    FreezeEntityPosition(PlayerPedId(), state)
end

function vRPclient.setCapuz(state)
    -- Stub: capuz (hood)
end

function vRPclient.notify(msg)
    exports['nova_core']:ClientNotify(msg, 'info')
end

function vRPclient.getPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return coords.x, coords.y, coords.z
end

function vRPclient.getSpeed()
    return GetEntitySpeed(PlayerPedId()) * 3.6
end

function vRPclient.getHealth()
    return GetEntityHealth(PlayerPedId())
end

function vRPclient.setArmour(amount)
    SetPedArmour(PlayerPedId(), amount)
end

function vRPclient.getArmour()
    return GetPedArmour(PlayerPedId())
end

function vRPclient.setVisible(state)
    SetEntityVisible(PlayerPedId(), state, false)
end

function vRPclient.setInvincible(state)
    SetEntityInvincible(PlayerPedId(), state)
end

function vRPclient.setModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if HasModelLoaded(hash) then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
    end
end

function vRPclient.getWeapons()
    local ped = PlayerPedId()
    local weapons = {}
    local weaponHashes = {
        'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50',
        'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_ASSAULTSMG', 'WEAPON_COMBATPDW',
        'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE',
        'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN', 'WEAPON_BULLPUPSHOTGUN',
        'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_MARKSMANRIFLE',
        'WEAPON_MINIGUN', 'WEAPON_RPG', 'WEAPON_GRENADELAUNCHER',
        'WEAPON_KNIFE', 'WEAPON_NIGHTSTICK', 'WEAPON_HAMMER', 'WEAPON_BAT',
        'WEAPON_STUNGUN', 'WEAPON_FLASHLIGHT',
    }
    for _, name in ipairs(weaponHashes) do
        local hash = joaat(name)
        if HasPedGotWeapon(ped, hash, false) then
            weapons[name] = { ammo = GetAmmoInPedWeapon(ped, hash) }
        end
    end
    return weapons
end

function vRPclient.giveWeapons(weapons, clear)
    local ped = PlayerPedId()
    if clear then RemoveAllPedWeapons(ped, true) end
    for name, data in pairs(weapons) do
        GiveWeaponToPed(ped, joaat(name), data.ammo or 100, false, false)
    end
end

function vRPclient.replaceWeapons(weapons)
    vRPclient.giveWeapons(weapons, true)
end

function vRPclient.removeWeapons()
    RemoveAllPedWeapons(PlayerPedId(), true)
end

function vRPclient.removeWeapon(name)
    RemoveWeaponFromPed(PlayerPedId(), joaat(name))
end

-- tvRP callbacks (server→client via tunnel)
function vRPclient.invUpdate(items)
    -- Stub: inventário é gerido pelo nova_inventory
end

function vRPclient.Foods(hunger, thirst, stress)
    TriggerEvent('hud:updateNeeds', {
        hunger = hunger or 100,
        thirst = thirst or 100,
        stress = stress or 0,
    })
end

function vRPclient.CreatePed(model, x, y, z, heading, freeze, invincible)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if HasModelLoaded(hash) then
        local ped = CreatePed(4, hash, x, y, z, heading or 0.0, true, true)
        if freeze then FreezeEntityPosition(ped, true) end
        if invincible then SetEntityInvincible(ped, true) end
        SetModelAsNoLongerNeeded(hash)
        return ped
    end
    return nil
end

function vRPclient.CreateObject(model, x, y, z, heading)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 10000 do Wait(10); timeout = timeout + 10 end
    if HasModelLoaded(hash) then
        local obj = CreateObject(hash, x, y, z, true, false, false)
        if heading then SetEntityHeading(obj, heading) end
        SetModelAsNoLongerNeeded(hash)
        return obj
    end
    return nil
end

function vRPclient.revive(health)
    local ped = PlayerPedId()
    SetEntityHealth(ped, health or 200)
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    ClearPedBloodDamage(ped)
end

local currentProp = nil
local currentAnimDict = nil

function vRPclient.createObjects(animDict, animName, prop, bone, flag, ox, oy, oz, rx, ry, rz)
    local ped = PlayerPedId()

    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, -1, flag or 49, 0, false, false, false)
        currentAnimDict = animDict
    end

    if prop then
        local hash = type(prop) == 'string' and joaat(prop) or prop
        RequestModel(hash)
        timeout = 0
        while not HasModelLoaded(hash) and timeout < 5000 do Wait(10); timeout = timeout + 10 end
        if HasModelLoaded(hash) then
            local coords = GetEntityCoords(ped)
            currentProp = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(currentProp, ped, GetPedBoneIndex(ped, bone or 28422),
                ox or 0.0, oy or 0.0, oz or 0.0, rx or 0.0, ry or 0.0, rz or 0.0,
                true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(hash)
        end
    end
end

function vRPclient.removeObjects()
    local ped = PlayerPedId()

    if currentProp and DoesEntityExist(currentProp) then
        DetachEntity(currentProp, false, false)
        DeleteEntity(currentProp)
        currentProp = nil
    end

    if currentAnimDict then
        StopAnimTask(ped, currentAnimDict, '', 1.0)
        currentAnimDict = nil
    end

    ClearPedTasks(ped)
end

-- Registar interfaces Creative (formato real)
Tunnel.bindInterface("vRP", vRPclient)
Proxy.addInterface("vRP", vRPclient)

-- ============================================================
-- EVENTOS BRIDGE
-- ============================================================

RegisterNetEvent('vRP:bridge:teleport')
AddEventHandler('vRP:bridge:teleport', function(x, y, z)
    vRPclient.teleport(x, y, z)
end)

RegisterNetEvent('vRP:bridge:playAnim')
AddEventHandler('vRP:bridge:playAnim', function(upper, seq, looping)
    vRPclient.playAnim(upper, seq, looping)
end)

RegisterNetEvent('vRP:bridge:stopAnim')
AddEventHandler('vRP:bridge:stopAnim', function(upper)
    vRPclient.stopAnim(upper)
end)

RegisterNetEvent('vRP:bridge:playSound')
AddEventHandler('vRP:bridge:playSound', function(dict, name)
    vRPclient.playSound(dict, name)
end)

RegisterNetEvent('vRP:bridge:setArmour')
AddEventHandler('vRP:bridge:setArmour', function(amount)
    vRPclient.setArmour(amount)
end)

RegisterNetEvent('vRP:bridge:characterChosen')
AddEventHandler('vRP:bridge:characterChosen', function(user_id, model, locate)
    TriggerEvent('spawn:Show', user_id)
end)

RegisterNetEvent('vRP:bridge:revive')
AddEventHandler('vRP:bridge:revive', function(health)
    vRPclient.revive(health)
end)

-- ============================================================
-- EVENTOS NOVA → Creative/vRP
-- ============================================================

RegisterNetEvent('nova:client:onPlayerLoaded', function(data)
    TriggerEvent('Active')
    TriggerEvent('vRP:playerSpawned')
    TriggerEvent('spawn:Show')
end)

RegisterNetEvent('nova:client:onLogout', function()
    TriggerEvent('vRP:playerLogout')
end)

RegisterNetEvent('nova:client:updatePlayerData', function(data)
    if data and data.type == 'metadata' then
        -- Atualizar HUD de necessidades
        local ok, pData = pcall(function() return exports['nova_core']:GetPlayerData() end)
        if ok and pData and pData.metadata then
            TriggerEvent('hud:updateNeeds', {
                hunger = pData.metadata.hunger or 100,
                thirst = pData.metadata.thirst or 100,
                stress = pData.metadata.stress or 0,
            })
        end
    end
end)

print('^2[NOVA Bridge] ^0Creative Client bridge carregado')
