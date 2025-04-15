local QBCore = nil
local Framework = nil

Locales = {}

local function InitializeFramework()
    if beq.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif beq.Framework == 'qbx' then
        QBCore = exports['qbx-core']:GetCoreObject()
        Framework = 'qbx'
    end
end

local function LoadLocales()
    local locale = beq.Locale or 'tr'
    local localeFile = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. locale .. '.lua')
    
    if localeFile then
        local func, err = load(localeFile)
        if func then
            func()
        else
            print('^1Debug Yarram Yüklenemedi Amk: ^7' .. err)
        end
    else
        print('^1Locale Yarra Yüklendi: ^7locales/' .. locale .. '.lua')
    end
end

CreateThread(function()
    InitializeFramework()
    LoadLocales()
end)

local function GetPlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    if Framework == 'qb' then
        return {
            source = source,
            identifier = Player.PlayerData.citizenid,
            job = Player.PlayerData.job,
            money = Player.PlayerData.money
        }
    elseif Framework == 'qbx' then
        return {
            source = source,
            identifier = Player.PlayerData.citizenid,
            job = Player.PlayerData.job,
            money = Player.PlayerData.money
        }
    end
end

local function GetInventorySystem()
    if beq.InventoryType == 'ox_inventory' then
        return 'ox'
    elseif beq.InventoryType == 'qb-inventory' then
        return 'qb'
    elseif beq.InventoryType == 'qbx-inventory' then
        return 'qbx'
    end
end

local function HasItem(source, item, amount)
    local InventoryType = GetInventorySystem()
    
    if InventoryType == 'ox' then
        local count = exports.ox_inventory:GetItem(source, item, nil, true)
        return count >= amount
    else
        local Player = QBCore.Functions.GetPlayer(source)
        local item = Player.Functions.GetItemByName(item)
        return item and item.amount >= amount
    end
end

local function RemoveBlackMoney(source, amount)
    local InventoryType = GetInventorySystem()
    
    if InventoryType == 'ox' then
        if exports.ox_inventory:RemoveItem(source, beq.BlackMoneyItem, amount) then
            return true
        end
        return false
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.Functions.RemoveItem(beq.BlackMoneyItem, amount) then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[beq.BlackMoneyItem], "remove")
            return true
        end
        return false
    end
end

local function GetBlackMoneyAmount(source)
    local InventoryType = GetInventorySystem()
    
    if InventoryType == 'ox' then
        local count = exports.ox_inventory:GetItem(source, beq.BlackMoneyItem, nil, true)
        return count or 0
    else
        local Player = QBCore.Functions.GetPlayer(source)
        local blackMoney = Player.Functions.GetItemByName(beq.BlackMoneyItem)
        return blackMoney and blackMoney.amount or 0
    end
end

local function AddCleanMoney(source, amount)
    local InventoryType = GetInventorySystem()
    local cleanAmount = amount * beq.ConversionRate
    
    if InventoryType == 'ox' then
        if exports.ox_inventory:AddItem(source, 'money', cleanAmount) then
            return true
        end
    else
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.AddMoney('cash', cleanAmount)
        return true
    end
    return false
end

local function NotifyGonderGitsin(source, message, type)
    if Framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif Framework == 'qbx' then
        TriggerClientEvent('qbx-core:Notify', source, message, type)
    end
end

local function SendDiscordWebhook(source, amount, cleanAmount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    local playerName = GetPlayerName(source)
    local playerIP = GetPlayerEndpoint(source)
    local steamHex = player.PlayerData.license
    local citizenid = player.PlayerData.citizenid
    local identifiers = GetPlayerIdentifiers(source)
    
    local steamIdentifier = "Bulunamadı"
    for _, id in ipairs(identifiers) do
        if string.find(id, "steam") then
            steamIdentifier = id
            break
        end
    end

    local isSuspicious = cleanAmount >= beqServer.Security.suspiciousAmounts.min

    local embedData = {
        {
            ["title"] = isSuspicious and beqServer.Webhooks.moneyWashLogs.suspiciousTitle or beqServer.Webhooks.moneyWashLogs.title,
            ["color"] = isSuspicious and beqServer.Webhooks.moneyWashLogs.suspiciousColor or beqServer.Webhooks.moneyWashLogs.color,
            ["fields"] = {
                {
                    ["name"] = "👤 Oyuncu Bilgileri",
                    ["value"] = string.format(
                        "**İsim:** %s\n**ID:** %s\n**Citizen ID:** %s\n**IP:** %s\n**Steam Hex:** %s",
                        playerName, source, citizenid, playerIP, steamIdentifier
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "💰 İşlem Detayları",
                    ["value"] = string.format(
                        "**Karapara:** $%s\n**Temiz Para:** $%s\n**Dönüşüm Oranı:** %s",
                        amount, cleanAmount, beq.ConversionRate
                    ),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = beqServer.Webhooks.moneyWashLogs.footer
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    if beqServer.Webhooks.enabled and beqServer.Webhooks.url then
        PerformHttpRequest(beqServer.Webhooks.url, function(err, text, headers) end, 'POST', json.encode({
            username = beqServer.Webhooks.moneyWashLogs.username,
            embeds = embedData
        }), { ['Content-Type'] = 'application/json' })
    end
end

local function IsPlayerNearLocation(source)
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    
    for _, location in pairs(beq.Locations) do
        local distance = #(playerCoords - location.coords)
        if distance <= beqServer.Security.radius then
            return true
        end
    end
    return false
end

local function HandleSecurityViolation(source)
    if beqServer.Security.banSystem == "fiveguard" then
        exports[beqServer.Security.banResource][beqServer.Security.banFunction](source, beqServer.Security.banMessage, "")
    else
        DropPlayer(source, beqServer.Security.banMessage)
    end
    
    if beqServer.Webhooks.enabled then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            local playerName = GetPlayerName(source)
            local playerIP = GetPlayerEndpoint(source)
            local steamHex = player.PlayerData.license
            local citizenid = player.PlayerData.citizenid
            
            local embedData = {
                {
                    ["title"] = beqServer.Webhooks.securityLogs.title,
                    ["color"] = beqServer.Webhooks.securityLogs.color,
                    ["fields"] = {
                        {
                            ["name"] = "👤 Oyuncu Bilgileri",
                            ["value"] = string.format(
                                "**İsim:** %s\n**ID:** %s\n**Citizen ID:** %s\n**IP:** %s\n**Steam Hex:** %s",
                                playerName, source, citizenid, playerIP, steamHex
                            ),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "⚠️ İhlal Detayı",
                            ["value"] = "Oyuncu izinsiz lokasyondan karapara dönüştürmeye çalıştı.",
                            ["inline"] = false
                        }
                    },
                    ["footer"] = {
                        ["text"] = beqServer.Webhooks.securityLogs.footer
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }

            PerformHttpRequest(beqServer.Webhooks.url, function(err, text, headers) end, 'POST', json.encode({
                username = beqServer.Webhooks.securityLogs.username,
                embeds = embedData
            }), { ['Content-Type'] = 'application/json' })
        end
    end
end

RegisterNetEvent('beq:RiseDevOpen', function(amount)
    local src = source
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        NotifyGonderGitsin(src, 'Geçersiz miktar!', 'error')
        return
    end
    
    if amount < beqServer.Conversion.minAmount then
        NotifyGonderGitsin(src, 'Minimum ' .. beqServer.Conversion.minAmount .. '$ dönüştürebilirsiniz!', 'error')
        return
    end
    
    if amount > beqServer.Conversion.maxAmount then
        NotifyGonderGitsin(src, 'Maksimum ' .. beqServer.Conversion.maxAmount .. '$ dönüştürebilirsiniz!', 'error')
        return
    end
    
    if not IsPlayerNearLocation(src) then
        HandleSecurityViolation(src)
        return
    end
    
    local Player = GetPlayerData(src)
    if not Player then return end
    
    if not HasItem(src, beq.BlackMoneyItem, amount) then
        NotifyGonderGitsin(src, Locales['not_enough_black_money'], 'error')
        return
    end
    
    if RemoveBlackMoney(src, amount) then
        local cleanAmount = amount * beq.ConversionRate
        if AddCleanMoney(src, amount) then
            NotifyGonderGitsin(src, string.format(Locales['money_washed_success'], amount), 'success')
            
            if beqServer.Webhooks.enabled then
                SendDiscordWebhook(src, amount, cleanAmount)
            end
        else
            if GetInventorySystem() == 'ox' then
                exports.ox_inventory:AddItem(src, beq.BlackMoneyItem, amount)
            else
                local Player = QBCore.Functions.GetPlayer(src)
                Player.Functions.AddItem(beq.BlackMoneyItem, amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[beq.BlackMoneyItem], "add")
            end
            NotifyGonderGitsin(src, 'İşlem başarısız oldu!', 'error')
        end
    end
end) 