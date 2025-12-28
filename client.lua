local QBCore = exports['qb-core']:GetCoreObject()
local PlayerHarvestSpots = {}
local IsCollecting = false
Config = Config or {}
Config.Debug = false
local CurrentActivity = nil 
local function ShuffleTable(t)
    local n = #t
    while n >= 2 do
        local k = math.random(n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
end
Citizen.CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        Citizen.Wait(100)
    end 
    PlayerHarvestSpots = ShuffleTable(table.clone(Config.HarvestSpots))
end)
RegisterNetEvent('sta-process:client:showUIAlert', function(message, type)
    SendNUIMessage({ type = 'showNotification', message = message, notificationType = type })
end)
local function DrawCustomMarker(coords)
    DrawMarker(
        1, coords.x, coords.y, coords.z - 1.0, 
        0, 0, 0, 
        0, 0, 0, 
        3.0, 3.0, 2.0, 
        255, 0, 255, 100, 
        false, true, 2, false, nil, nil, false
    )
end
Citizen.CreateThread(function()
    local oldIsNear = false
    local processSpot = Config.ProcessSpot
    while true do
        local wait = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local spot = PlayerHarvestSpots[1]
        local isNear = false
        if not IsCollecting then
            if processSpot then
                local dist = #(plyPos - processSpot)
                if dist < 50.0 then 
                    wait = 4 
                    DrawCustomMarker(processSpot) 
                end
                if dist < 1.5 then 
                    isNear = true
                    SendNUIMessage({ type = 'setText', show = true, text = 'Kokain İşle' })
                    if IsControlJustReleased(0, 38) then
                        StartActivity('Process')
                    end
                end
            end
            if spot and not isNear then 
                local dist = #(plyPos - spot)
                if dist < 50.0 then 
                    wait = 4 
                    DrawMarker(
                        2, spot.x, spot.y, spot.z - 0.5, 0, 0, 0, 0, 0, 0, 
                        0.8, 0.8, 0.3, 0, 255, 0, 150, false, true, 2, false, nil, nil, false
                    )
                end
                if dist < 1.5 then 
                    isNear = true
                    SendNUIMessage({ type = 'setText', show = true, text = 'Kokain Yaprağı Topla' })
                    if IsControlJustReleased(0, 38) then 
                        StartActivity('Harvest') 
                    end
                end
            end
        end
        if oldIsNear and not isNear then
            SendNUIMessage({ type = 'setText', show = false })
        end
        oldIsNear = isNear
        if IsCollecting and IsControlJustReleased(0, 322) then
            StopActivity(true, CurrentActivity)
        end
        Citizen.Wait(wait)
    end
end)
function StopActivity(cancelled, activityType)
    if IsCollecting then
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
        IsCollecting = false
        RemoveAnimDict(Config[activityType .. 'Settings'].animDict)
        SendNUIMessage({ type = 'stopProcess' })
        SetNuiFocus(false, false)
        if cancelled then
             SendNUIMessage({ type = 'showNotification', message = (activityType == 'Harvest' and 'Toplama' or 'İşleme') .. ' işlemi **iptal edildi**.', notificationType = 'error' })
        end
        CurrentActivity = nil
    end
end
function StartActivity(activityType)
    IsCollecting = true
    CurrentActivity = activityType
    local settings = Config[activityType .. 'Settings']
    local duration = settings.time
    local ped = PlayerPedId()
    RequestAnimDict(settings.animDict)
    while not HasAnimDictLoaded(settings.animDict) do
        Citizen.Wait(0)
    end
    local currentPos = GetEntityCoords(ped)
    local groundZ = currentPos.z
    local success, z = GetGroundZAndNormalFor_3dCoord(currentPos.x, currentPos.y, currentPos.z, false)
    if success then
        groundZ = z
    end
    SetEntityCoords(ped, currentPos.x, currentPos.y, groundZ, false, false, false, false)
    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, settings.animDict, settings.animName, 8.0, 8.0, -1, 49, 0, false, false, false)
    SendNUIMessage({ type = 'startProcess', text = settings.label })
    SetNuiFocus(true, false)
    local startTime = GetGameTimer()
    while GetGameTimer() < startTime + duration do
        Citizen.Wait(100)
        if not IsCollecting then
            return
        end
        local elapsed = GetGameTimer() - startTime
        local progress = math.floor((elapsed / duration) * 100)
        SendNUIMessage({ type = 'updateProcess', progress = progress })
    end
    ClearPedTasks(ped)
    IsCollecting = false
    FreezeEntityPosition(ped, false)
    SendNUIMessage({ type = 'stopProcess' })
    SetNuiFocus(false, false)
    
    if activityType == 'Harvest' then
        TriggerServerEvent('sta-process:server:giveItem')
        table.remove(PlayerHarvestSpots, 1)
        if not PlayerHarvestSpots[1] then
             PlayerHarvestSpots = ShuffleTable(table.clone(Config.HarvestSpots))
        end
    elseif activityType == 'Process' then
        TriggerServerEvent('sta-process:server:processItem')
    end

    RemoveAnimDict(settings.animDict)
    CurrentActivity = nil
end