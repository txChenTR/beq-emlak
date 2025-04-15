local QBCore = nil
local Framework = nil
local isUIOpen = false

local function InitializeFramework()
    if beq.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif beq.Framework == 'qbx' then
        QBCore = exports['qbx-core']:GetCoreObject()
        Framework = 'qbx'
    end
end

CreateThread(function()
    InitializeFramework()
end)

function OpenMoneyWashUI()
    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open"
        })
    end
end

function CloseMoneyWashUI()
    if isUIOpen then
        isUIOpen = false
        SetNuiFocus(false, false)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            if IsControlJustPressed(0, 177) then
                CloseMoneyWashUI()
            end
        end
    end
end)

local function HasRequiredJob(jobs)
    local PlayerData
    if Framework == 'qb' then
        PlayerData = QBCore.Functions.GetPlayerData()
    elseif Framework == 'qbx' then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
    
    if not PlayerData then return false end
    
    local playerJob = PlayerData.job
    if jobs[playerJob.name] and playerJob.grade.level >= jobs[playerJob.name] then
        return true
    end
    return false
end

local function CreateLocationBlips()
    for _, v in pairs(beq.Locations) do
        if v.blip and v.blip.enable then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale)
            SetBlipColour(blip, v.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

function NotifyGonderGitsin(message, type)
    if Framework == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif Framework == 'qbx' then
        exports['qbx-core']:Notify(message, type)
    end
end

local function SetupTarget()
    if beq.TargetSystem == 'qb-target' then
        for _, v in pairs(beq.Locations) do
            exports['qb-target']:AddBoxZone("moneywash_" .. _,  v.coords, 1.0, 1.0, {
                name = "moneywash_" .. _,
                heading = 0.0,
                debugPoly = false,
                minZ = v.coords.z - 1.0,
                maxZ = v.coords.z + 1.0
            }, {
                options = {
                    {
                        type = "client",
                        event = "beq:RiseDevOpenUI",
                        icon = "fas fa-money-bill-wave",
                        label = v.targetLabel or Locales['interact_label'],
                        canInteract = function()
                            return HasRequiredJob(v.jobs)
                        end
                    },
                },
                distance = 2.0
            })
        end
    elseif beq.TargetSystem == 'ox_target' then
        for _, v in pairs(beq.Locations) do
            exports.ox_target:addBoxZone({
                coords = v.coords,
                size = vec3(1, 1, 2),
                rotation = 0.0,
                debug = false,
                options = {
                    {
                        name = 'moneywash_' .. _,
                        event = 'beq:RiseDevOpenUI',
                        icon = 'fas fa-money-bill-wave',
                        label = v.targetLabel or "Karapara Dönüştür",
                        canInteract = function()
                            return HasRequiredJob(v.jobs)
                        end
                    }
                }
            })
        end
    end
end

RegisterNetEvent('beq:RiseDevOpenUI', function()
    OpenMoneyWashUI()
end)

CreateThread(function()
    CreateLocationBlips()
    
    if beq.TargetSystem == 'drawtext' then
        while true do
            local sleep = 1000
            local playerPos = GetEntityCoords(PlayerPedId())
            
            for k, v in pairs(beq.Locations) do
                local dist = #(playerPos - v.coords)
                
                if dist < 10.0 and HasRequiredJob(v.jobs) then
                    sleep = 0
                    DrawMarker(2, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 155, false, false, false, true, false, false, false)
                    
                    if dist < 2.0 then
                        if not isUIOpen then
                            DrawText3D(v.coords.x, v.coords.y, v.coords.z + 0.3, '[E] - ' .. (v.targetLabel or "Karapara Dönüştür"))
                            if IsControlJustPressed(0, 38) then
                                OpenMoneyWashUI()
                            end
                        end
                    end
                end
            end
            Wait(sleep)
        end
    else
        SetupTarget()
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNUICallback('washMoney', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        TriggerServerEvent('beq:RiseDevOpen', amount)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end) 