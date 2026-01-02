local QBCore = exports['qb-core']:GetCoreObject()
local function SendWebhookAndKick(src, reason)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local steamID = Player.PlayerData.license
        local discordID = 'Bilinmiyor' 
        if Player.PlayerData.metadata and Player.PlayerData.metadata['discordid'] then
            discordID = Player.PlayerData.metadata['discordid']
        elseif Player.PlayerData.identifiers then
            for _, identifier in ipairs(Player.PlayerData.identifiers) do
                if string.match(identifier, 'discord:') then
                    discordID = string.gsub(identifier, 'discord:', '')
                    break
                end
            end
        end
        local reasonText = Info.Webhook.Mention .. ' **Hile Tespit Edildi**!' .. '\n' ..
                           '**Oyuncu:** ' .. playerName .. ' (ID: ' .. src .. ')' .. '\n' ..
                           '**Lisans/SteamID:** ' .. steamID .. '\n' ..
                           '**Discord ID:** ' .. discordID .. '\n' .. 
                           '**İhlal Nedeni:** ' .. reason
                           
        PerformHttpRequest(Info.Webhook.Url, function(statusCode, text, headers) end, 'POST', json.encode({
            username = 'STA Process Güvenlik',
            content = reasonText,
            embeds = {}
        }), { ['Content-Type'] = 'application/json' })
        
        DropPlayer(src, 'Güvenlik İhlali: ' .. reason .. ' - Ayrıntılar için Discord da Ticket Açınız.')
    end
end
RegisterServerEvent('sta-process:server:giveItem', function()
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local isNear = false
    
    for _, spot in ipairs(Config.HarvestSpots) do
        if #(coords - spot) < 10.0 then 
            isNear = true
            break
        end
    end

    if not isNear then
        return SendWebhookAndKick(src, 'Trigger kullanımı.')
    end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = Config.HarvestSettings.item
    local amount = Config.HarvestSettings.amount
    if item ~= Info.HarvestSafety.AllowedItem or amount ~= Info.HarvestSafety.ExpectedAmount then
        return SendWebhookAndKick(src, 'Harvest (Toplama) ayarlarında hile: İtem/Miktar uyuşmazlığı.')
    end
    if Player then
        if Player.Functions.AddItem(item, amount) then
            TriggerClientEvent('sta-process:client:showUIAlert', src, 'Başarıyla ' .. amount .. ' adet ' .. QBCore.Shared.Items[item].label .. ' topladın!', 'success')
        else
            TriggerClientEvent('sta-process:client:showUIAlert', src, 'Eşya verilirken bir hata oluştu veya envanterin dolu!', 'error')
        end
    end
end)

RegisterServerEvent('sta-process:server:processItem', function()
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local processDist = #(coords - Config.ProcessSpot)

    if processDist > 10.0 then 
        return SendWebhookAndKick(src, 'Trigger Kullanımı.')
    end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local costItem = Config.ProcessSettings.costItem
    local costAmount = Config.ProcessSettings.costAmount
    local resultItem = Config.ProcessSettings.resultItem
    local resultAmount = Config.ProcessSettings.resultAmount
    if costItem ~= Info.ProcessSafety.AllowedCostItem or costAmount ~= Info.ProcessSafety.ExpectedCostAmount or 
       resultItem ~= Info.ProcessSafety.AllowedResultItem or resultAmount ~= Info.ProcessSafety.ExpectedResultAmount then
        return SendWebhookAndKick(src, 'Process (İşleme) ayarlarında hile: Maliyet/Sonuç İtem/Miktar uyuşmazlığı.')
    end 
    if Player then
        if Player.Functions.GetItemByName(costItem) and Player.Functions.GetItemByName(costItem).amount >= costAmount then
            if Player.Functions.RemoveItem(costItem, costAmount) then
                if Player.Functions.AddItem(resultItem, resultAmount) then
                    TriggerClientEvent('sta-process:client:showUIAlert', src, costAmount .. ' ' .. QBCore.Shared.Items[costItem].label .. ' harcadın ve ' .. resultAmount .. ' ' .. QBCore.Shared.Items[resultItem].label .. ' ürettin!', 'success')
                else
                    TriggerClientEvent('sta-process:client:showUIAlert', src, 'Ürün verilirken hata oluştu. Envanterin dolu olabilir.', 'error')
                    Player.Functions.AddItem(costItem, costAmount) 
                end
            else
                TriggerClientEvent('sta-process:client:showUIAlert', src, 'Maliyet eşyası envanterinden düşülemedi.', 'error')
            end
        else
            TriggerClientEvent('sta-process:client:showUIAlert', src, 'Bu işlemi yapmak için yeterli ' .. QBCore.Shared.Items[costItem].label .. ' yok! (İstenen: ' .. costAmount .. ')', 'error')
        end
    end
end)