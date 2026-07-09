-- ============================================================================
-- 🌐 DETECCIÓN DE FRAMEWORK BASE (cuentas / trabajo) — usado por el HUD
-- ============================================================================
local CurrentFramework = nil

local function DetectFramework()
    if Config.Framework ~= 'auto' then CurrentFramework = Config.Framework return end
    if GetResourceState('qbx_core') == 'started' then CurrentFramework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then CurrentFramework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then CurrentFramework = 'esx'
    else CurrentFramework = 'standalone' end
end

-- ============================================================================
-- 🎒 DETECCIÓN DE FRAMEWORK DE INVENTARIO — usado por el HUD de armas
-- ============================================================================
local DetectedInventory = nil

local function DetectInventory()
    if DetectedInventory then return DetectedInventory end

    if Config.WeaponsFramework ~= 'auto' then
        DetectedInventory = Config.WeaponsFramework
        return DetectedInventory
    end

    if GetResourceState('ox_inventory') == 'started' then
        DetectedInventory = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then
        DetectedInventory = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        DetectedInventory = 'esx'
    else
        DetectedInventory = 'none'
    end

    return DetectedInventory
end

CreateThread(function()
    DetectFramework()
    Wait(1000) -- da tiempo a que otros recursos terminen de iniciar
    print(('^2[D87 HUD]^7 Framework base: ^3%s^7 | Inventario de armas: ^3%s^7'):format(CurrentFramework, DetectInventory()))
end)

-- ============================================================================
-- 📊 CUENTAS Y TRABAJO (HUD de constantes)
-- ============================================================================
local function UpdatePlayerAccounts(source)
    local cash, bank, jobLabel, gradeLabel = 0, 0, nil, nil

    if CurrentFramework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            cash = player.PlayerData.money['cash'] or 0
            bank = player.PlayerData.money['bank'] or 0
            jobLabel = player.PlayerData.job.label
            gradeLabel = player.PlayerData.job.grade.name
        end
    elseif CurrentFramework == 'qb-core' and GetResourceState('qb-core') == 'started' then
        local player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
        if player then
            cash = player.PlayerData.money['cash'] or 0
            bank = player.PlayerData.money['bank'] or 0
            jobLabel = player.PlayerData.job.label
            gradeLabel = player.PlayerData.job.grade.name
        end
    elseif CurrentFramework == 'esx' and GetResourceState('es_extended') == 'started' then
        local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(source)
        if xPlayer then
            cash = xPlayer.getMoney()
            bank = xPlayer.getAccount('bank').money
            jobLabel = xPlayer.getJob().label
            gradeLabel = xPlayer.getJob().grade_label
        end
    end

    TriggerClientEvent('d87-hud:client:updateAccounts', source, cash, bank, jobLabel, gradeLabel)
end

RegisterNetEvent('d87-hud:server:requestUpdate', function()
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('qbx_core:server:onMoneyUpdate', function(playerData)
    if playerData and playerData.source then UpdatePlayerAccounts(playerData.source) end
end)

RegisterNetEvent('QBCore:Server:OnMoneyChange', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('qbx_core:server:onJobUpdate', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source)
    UpdatePlayerAccounts(source)
end)

RegisterNetEvent('esx:setAccountMoney', function(source) UpdatePlayerAccounts(source) end)
RegisterNetEvent('esx:setJob', function(source) UpdatePlayerAccounts(source) end)

-- ============================================================================
-- 🔔 NOTIFICACIONES
-- ============================================================================
-- Envía una notificación a un jugador específico por ID de servidor
-- Uso desde servidor: TriggerEvent('d87-notifications:server:SendAlert', source, 'success', 'Texto', 5000)
RegisterNetEvent('d87-notifications:server:SendAlert', function(target, type, message, duration, customTitle)
    local src = source
    local targetPlayer = target

    if targetPlayer == -1 or targetPlayer == nil then
        targetPlayer = src
    end

    TriggerClientEvent('d87-notifications:client:SendAlert', targetPlayer, type, message, duration, customTitle)
end)

-- Retransmite un anuncio masivo a todo el servidor a la vez
RegisterNetEvent('d87-notifications:server:BroadcastAlert', function(type, message, duration, customTitle)
    TriggerClientEvent('d87-notifications:client:SendAlert', -1, type, message, duration, customTitle)
end)

-- ============================================================================
-- ⚔️ HUD DE ARMAS — munición de reserva (framework-agnóstico)
-- Solo se consulta desde el cliente cuando NO está corriendo ox_inventory,
-- ya que ox_inventory se consulta de forma directa y síncrona en el cliente.
-- ============================================================================
lib.callback.register('d87-hud:getReserveAmmo', function(source, ammoType)
    if not ammoType then return 0 end

    local inventory = DetectInventory()

    if inventory == 'qb' then
        local ok, count = pcall(function()
            return exports['qb-inventory']:GetItemCount(source, ammoType)
        end)
        return (ok and count) or 0
    end

    if inventory == 'esx' then
        local ok, count = pcall(function()
            local ESX = exports['es_extended']:getSharedObject()
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return 0 end
            local item = xPlayer.getInventoryItem(ammoType)
            return item and item.count or 0
        end)
        return (ok and count) or 0
    end

    if inventory == 'ox' then
        local ok, count = pcall(function()
            return exports.ox_inventory:Search(source, 'count', ammoType)
        end)
        return (ok and count) or 0
    end

    return 0
end)
