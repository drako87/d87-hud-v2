-- ============================================================================
-- 🌐 TRADUCCIÓN
-- ============================================================================
local function _L(key)
    local lang = Config.Locale or 'es'
    if Locales and Locales[lang] and Locales[lang][key] then
        return Locales[lang][key]
    else
        return "LANG_ERROR"
    end
end

-- ============================================================================
-- 🌐 FRAMEWORK BASE (cuentas / trabajo)
-- ============================================================================
local CurrentFramework = nil

local function DetectFramework()
    if Config.Framework ~= 'auto' then CurrentFramework = Config.Framework return end
    if GetResourceState('qbx_core') == 'started' then CurrentFramework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then CurrentFramework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then CurrentFramework = 'esx'
    else CurrentFramework = 'standalone' end
end

local isHudVisible = false
local hudDisabledGlobal = false
local isMenuOpen = false

local currentStress = 0
local stressEffectActive = false
local currentSleep = 0.0
local isSleeping = false
local currentStamina = 100.0

local Directions = { [0] = 'N', [1] = 'NE', [2] = 'E', [3] = 'SE', [4] = 'S', [5] = 'SO', [6] = 'O', [7] = 'NO', [8] = 'N' }

-- ============================================================================
-- 🧩 SISTEMA DE AJUSTES EN VIVO (menú /hudmenu + persistencia KVP)
-- Incluye ajustes del HUD de constantes, de notificaciones y del HUD de armas.
-- Posiciones fijas de waypoint/voz y mecánicas (stamina/sueño/estrés/munición)
-- se siguen leyendo directamente de config.lua.
-- ============================================================================
local DEFAULT_SETTINGS = {
    -- HUD de constantes
    size = Config.Size,
    topRightSize = Config.TopRightSize,
    statsBottom = Config.StatsBottom,
    statsLeft = Config.StatsLeft,
    compassBottom = Config.CompassBottom,
    compassLeft = Config.CompassLeft,
    topMargin = Config.TopMargin,
    rightMargin = Config.RightMargin,
    alertLimit = Config.AlertPercent,
    alertSound = Config.AlertSound,
    alertSoundVolume = Config.AlertSoundVolume,
    theme = Config.Theme,
    compactMode = Config.CompactMode,
    smartFadeOut = Config.SmartFadeOut,
    autoHideArmor = Config.AutoHideArmor,
    showZone = Config.ShowZone,
    distanceUnit = Config.DistanceUnit,
    showHealth = Config.ShowHealth,
    showArmor = Config.ShowArmor,
    showHunger = Config.ShowHunger,
    showThirst = Config.ShowThirst,
    showStress = Config.ShowStress,
    showStamina = Config.ShowStamina,
    showSleep = Config.ShowSleep,
    showVoice = Config.ShowVoice,
    showOxygen = Config.ShowOxygen,
    showCompass = Config.ShowCompass,
    showTime = Config.ShowTime,
    showFuel = Config.ShowFuel,
    showCash = Config.ShowCash,
    showBank = Config.ShowBank,
    showJob = Config.ShowJob,

    -- Notificaciones
    notifyPosition = Config.NotifyPosition,
    notifyDuration = Config.NotifyDefaultDuration,
    notifyMax = Config.NotifyMaxNotifications,

    -- HUD de armas
    weaponsSize = Config.WeaponsSize,
    weaponsBottomMargin = Config.WeaponsBottomMargin,
    weaponsHideWhenUnarmed = Config.WeaponsHideWhenUnarmed,
    weaponsFadeTimeout = Config.WeaponsFadeTimeout,
}

local Settings = {}
for k, v in pairs(DEFAULT_SETTINGS) do Settings[k] = v end

local function LoadSettings()
    if not Config.SaveSettingsPerClient then return end
    local ok, raw = pcall(GetResourceKvpString, 'd87hud_settings')
    if ok and raw and raw ~= "" then
        local decodedOk, decoded = pcall(json.decode, raw)
        if decodedOk and type(decoded) == 'table' then
            for k, v in pairs(decoded) do
                if DEFAULT_SETTINGS[k] ~= nil then Settings[k] = v end
            end
        end
    end
end

local function SaveSettings(newSettings)
    if type(newSettings) ~= 'table' then return end
    for k, v in pairs(newSettings) do
        if DEFAULT_SETTINGS[k] ~= nil then Settings[k] = v end
    end
    if Config.SaveSettingsPerClient then
        pcall(SetResourceKvp, 'd87hud_settings', json.encode(Settings))
    end
end

local MenuStrings = {}
local function BuildMenuStrings()
    MenuStrings = {
        title = _L('menu_title'),
        tabLayout = _L('menu_tab_layout'),
        tabVisibility = _L('menu_tab_visibility'),
        tabAlerts = _L('menu_tab_alerts'),
        tabAppearance = _L('menu_tab_appearance'),
        tabNotify = _L('menu_tab_notify'),
        tabWeapons = _L('menu_tab_weapons'),
        hudScale = _L('menu_hud_scale'),
        finScale = _L('menu_fin_scale'),
        sectionStats = _L('menu_section_stats'),
        statsBottom = _L('menu_stats_bottom'),
        statsLeft = _L('menu_stats_left'),
        sectionCompass = _L('menu_section_compass'),
        compassBottom = _L('menu_compass_bottom'),
        compassLeft = _L('menu_compass_left'),
        sectionFinance = _L('menu_section_finance'),
        topMargin = _L('menu_top_margin'),
        rightMargin = _L('menu_right_margin'),
        alertPercent = _L('menu_alert_percent'),
        alertSound = _L('menu_alert_sound'),
        alertVolume = _L('menu_alert_volume'),
        theme = _L('menu_theme'),
        themePurple = _L('menu_theme_purple'),
        themeBlue = _L('menu_theme_blue'),
        themeRed = _L('menu_theme_red'),
        compact = _L('menu_compact'),
        smartFade = _L('menu_smart_fade'),
        showZone = _L('menu_show_zone'),
        units = _L('menu_units'),
        unitMetric = _L('menu_unit_metric'),
        unitImperial = _L('menu_unit_imperial'),
        btnReset = _L('menu_btn_reset'),
        btnSave = _L('menu_btn_save'),
        visHealth = _L('menu_vis_health'),
        visArmor = _L('menu_vis_armor'),
        visHunger = _L('menu_vis_hunger'),
        visThirst = _L('menu_vis_thirst'),
        visStress = _L('menu_vis_stress'),
        visStamina = _L('menu_vis_stamina'),
        visSleep = _L('menu_vis_sleep'),
        visVoice = _L('menu_vis_voice'),
        visOxygen = _L('menu_vis_oxygen'),
        visCompass = _L('menu_vis_compass'),
        visTime = _L('menu_vis_time'),
        visFuel = _L('menu_vis_fuel'),
        visCash = _L('menu_vis_cash'),
        visBank = _L('menu_vis_bank'),
        visJob = _L('menu_vis_job'),
        notifyPositionLbl = _L('menu_notify_position'),
        notifyDurationLbl = _L('menu_notify_duration'),
        notifyMaxLbl = _L('menu_notify_max'),
        posTopRight = _L('menu_pos_topright'),
        posTopLeft = _L('menu_pos_topleft'),
        posBottomRight = _L('menu_pos_bottomright'),
        posBottomLeft = _L('menu_pos_bottomleft'),
        posTopCenter = _L('menu_pos_topcenter'),
        weaponsSizeLbl = _L('menu_weapons_size'),
        weaponsBottomLbl = _L('menu_weapons_bottom'),
        weaponsHideUnarmedLbl = _L('menu_weapons_hide_unarmed'),
        weaponsFadeLbl = _L('menu_weapons_fade'),
    }
end

local ExemptJobsSet = {}
local function BuildExemptJobsSet()
    ExemptJobsSet = {}
    for _, job in ipairs(Config.StressExemptJobs or {}) do
        ExemptJobsSet[string.lower(job)] = true
    end
end

CreateThread(function()
    DetectFramework()
    LoadSettings()
    BuildMenuStrings()
    BuildExemptJobsSet()
    print('^4==================================================================^7')
    print('^2' .. _L('init_success') .. '^7')
    print(('^2' .. _L('framework_detected') .. '^7'):format(CurrentFramework))
    print('^4==================================================================^7')
end)

-- Empaqueta y envía el estado "show" completo del HUD (usado al abrir el HUD y tras guardar ajustes)
local function PushShowMessage()
    SendNUIMessage({
        action = "hud_show",
        size = Settings.size,
        statsBottom = Settings.statsBottom,
        statsLeft = Settings.statsLeft,
        compassBottom = Settings.compassBottom,
        compassLeft = Settings.compassLeft,
        wpBottom = Config.WaypointBottom,
        wpLeft = Config.WaypointLeft,
        voiceBottom = Config.VoiceBottom,
        voiceRight = Config.VoiceRight,
        topRightSize = Settings.topRightSize,
        topMargin = Settings.topMargin,
        rightMargin = Settings.rightMargin,
        showHealth = Settings.showHealth,
        showArmor = Settings.showArmor,
        showHunger = Settings.showHunger,
        showThirst = Settings.showThirst,
        showStress = Settings.showStress,
        showStamina = Settings.showStamina,
        showSleep = Settings.showSleep,
        showVoice = Settings.showVoice,
        showOxygen = Settings.showOxygen,
        showCash = Settings.showCash,
        showBank = Settings.showBank,
        showJob = Settings.showJob,
        showCompass = Settings.showCompass,
        showTime = Settings.showTime,
        showFuel = Settings.showFuel,
        showZone = Settings.showZone,
        alertLimit = Settings.alertLimit,
        alertSound = Settings.alertSound,
        alertSoundVolume = Settings.alertSoundVolume,
        theme = Settings.theme,
        compactMode = Settings.compactMode,
        smartFadeOut = Settings.smartFadeOut,
        autoHideArmor = Settings.autoHideArmor,
        distanceUnit = Settings.distanceUnit,
        loadingStreet = _L('loading_street')
    })
end

-- COMANDO MULTIFUNCIÓN: Oculta la interfaz web y apaga/enciende el minimapa nativo de GTA V
RegisterCommand('hud', function()
    hudDisabledGlobal = not hudDisabledGlobal
    if hudDisabledGlobal then
        isHudVisible = false
        SendNUIMessage({ action = "hud_hide" })
        DisplayRadar(false)
    else
        DisplayRadar(true)
    end
end, false)

-- 🧩 COMANDO DE MENÚ: abre/cierra el panel de personalización en vivo
RegisterCommand(Config.MenuCommand, function()
    if hudDisabledGlobal then return end
    isMenuOpen = not isMenuOpen
    SetNuiFocus(isMenuOpen, isMenuOpen)
    SendNUIMessage({
        action = "hud_toggleMenu",
        open = isMenuOpen,
        settings = Settings,
        defaults = DEFAULT_SETTINGS,
        strings = MenuStrings
    })
end, false)

RegisterNUICallback('saveSettings', function(data, cb)
    SaveSettings(data)
    isMenuOpen = false
    SetNuiFocus(false, false)
    PushShowMessage()
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('d87-hud:client:updateAccounts', function(cash, bank, jobLabel, gradeLabel)
    if isHudVisible and not hudDisabledGlobal then
        local finalJob = jobLabel or _L('unemployed')
        local finalGrade = gradeLabel or _L('unemployed_grade')

        SendNUIMessage({
            action = "hud_update_finance",
            cash = cash,
            bank = bank,
            job = finalJob,
            grade = finalGrade
        })
    end
end)

-- 😴 Secuencia de sueño forzado al llegar a 100: ojos cerrados con cuenta atrás en pantalla
local function TriggerSleepSequence()
    if isSleeping then return end
    isSleeping = true
    local ped = PlayerPedId()
    DoScreenFadeOut(1000)
    Wait(1000)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    local remaining = math.floor(Config.SleepDuration * 60)
    SendNUIMessage({ action = "hud_sleepStart", duration = remaining })
    while remaining > 0 do
        Wait(1000)
        remaining = remaining - 1
        SendNUIMessage({ action = "hud_sleepTick", remaining = remaining })
    end

    currentSleep = 50
    ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    DoScreenFadeIn(1000)
    SendNUIMessage({ action = "hud_sleepEnd" })
    isSleeping = false
end

-- Hilo para acumulación pasiva de sueño y efectos de estrés
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) or GetEntitySpeed(ped) < 1.0 then Wait(10000) else Wait(4000) end
        if Config.ShowSleep and not hudDisabledGlobal and not isSleeping then
            local sleepGain = (100 / (Config.SleepGainMinutes * 60)) * 4
            currentSleep = currentSleep + sleepGain
            if currentSleep >= 100 then
                currentSleep = 100
                CreateThread(TriggerSleepSequence)
            elseif currentSleep >= 85 and Config.SleepEffectBlur and not IsPauseMenuActive() then
                if math.random(1, 10) <= 3 then DoScreenFadeOut(800) Wait(1500) DoScreenFadeIn(800) end
            end
        end
        if Config.StressEnabled and Config.ShowStress and currentStress >= Config.StressEffectThreshold and currentStress < 100 and Config.StressScreenBlur and not IsPauseMenuActive() then
            if math.random(1, 10) <= 4 then AnimpostfxPlay("ChopVision", 4000, false) Wait(4000) AnimpostfxStop("ChopVision") end
        end
    end
end)

-- 🌀 Efecto de pantalla PERMANENTE mientras el estrés esté al máximo (100). Se apaga en cuanto baja.
CreateThread(function()
    while true do
        Wait(500)
        local shouldBeActive = Config.StressEnabled and Config.ShowStress and Config.StressScreenBlur
            and currentStress >= 100 and not hudDisabledGlobal and not IsPauseMenuActive()

        if shouldBeActive and not stressEffectActive then
            stressEffectActive = true
            AnimpostfxPlay("ChopVision", 0, true)
        elseif not shouldBeActive and stressEffectActive then
            stressEffectActive = false
            AnimpostfxStop("ChopVision")
        end
    end
end)

-- Caches para evitar recalcular datos costosos (calle, zona, hambre/sed) cada tick
local cachedStreetName = _L('loading_street')
local cachedZoneName = ""
local cachedHunger, cachedThirst = 100, 100
local cachedJobName = ""

local function IsStressExemptJob()
    if cachedJobName == "" then return false end
    return ExemptJobsSet[string.lower(cachedJobName)] == true
end
local lastSlowUpdate = 0
local SLOW_INTERVAL = 2000
local cachedPlayerServerId = nil
local lastStressGain = 0
local lastSpeedStressGain = 0
local lastAccidentStressGain = 0
local lastVehicleSpeed = 0

-- Formatea la distancia del waypoint respetando la unidad elegida (métrico/imperial)
local function FormatWaypointDistance(distanceMeters)
    if Settings.distanceUnit == 'imperial' then
        local feet = distanceMeters * 3.28084
        if feet >= 5280 then
            return string.format("%.1fmi", feet / 5280)
        else
            return string.format("%dft", math.floor(feet))
        end
    else
        if distanceMeters >= 1000 then
            return string.format("%.1fK", distanceMeters / 1000)
        else
            return string.format("%dM", math.floor(distanceMeters))
        end
    end
end

-- ============================================================================
-- ⛽ COMBUSTIBLE — abstrae distintos sistemas para no acoplarse a un recurso concreto
-- ============================================================================
local function GetVehicleFuel(vehicle)
    if Config.FuelSystem == 'none' or not Settings.showFuel then return nil end

    if Config.FuelSystem == 'LegacyFuel' then
        local ok, fuel = pcall(function() return exports['LegacyFuel']:GetFuel(vehicle) end)
        return ok and fuel or nil
    elseif Config.FuelSystem == 'ps-fuel' then
        local ok, fuel = pcall(function() return exports['ps-fuel']:GetFuel(vehicle) end)
        return ok and fuel or nil
    elseif Config.FuelSystem == 'cdn-fuel' then
        local ok, fuel = pcall(function() return exports['cdn-fuel']:GetFuel(vehicle) end)
        return ok and fuel or nil
    else -- 'native': usa el getter nativo de FiveM, sin dependencias externas
        local ok, fuel = pcall(function() return GetVehicleFuelLevel(vehicle) end)
        return ok and fuel or nil
    end
end

-- ============================================================================
-- ⚡ DELTA-CHECK — compara contra el último payload enviado y solo actualiza
-- las claves que cambiaron en la caché; devuelve true si hay algo que enviar.
-- Evita llamar a SendNUIMessage (y por tanto reflow/paint en el NUI) cuando
-- nada ha cambiado realmente entre un tick y el siguiente.
-- ============================================================================
local function SyncAndCheckChanged(cache, newValues)
    local changed = false
    for k, v in pairs(newValues) do
        if cache[k] ~= v then
            cache[k] = v
            changed = true
        end
    end
    return changed
end

local lastFastPayload = {}
local lastCompassPayload = {}

-- 🚀 HILO RÁPIDO: salud, armadura, estrés, resistencia, sueño, oxígeno, voz, waypoint y combustible.
-- Es el único que necesita reaccionar rápido (daño, disparos, etc.), por eso corre a Config.HudFastInterval.
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local isPauseOpen = IsPauseMenuActive() or IsRadarHidden() or hudDisabledGlobal

        if not isPauseOpen then
            sleep = Config.HudFastInterval or 150
            if not cachedPlayerServerId then cachedPlayerServerId = GetPlayerServerId(PlayerId()) end
            local playerServerId = cachedPlayerServerId

            local waypointActive = IsWaypointActive()
            local waypointStr = ""

            if waypointActive then
                local waypointBlip = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypointBlip) then
                    local coords = GetEntityCoords(ped)
                    local blipCoords = GetBlipInfoIdCoord(waypointBlip)
                    local distance = #(vec2(coords.x, coords.y) - vec2(blipCoords.x, blipCoords.y))
                    waypointStr = FormatWaypointDistance(distance)
                else
                    waypointActive = false
                end
            end

            if not isHudVisible then
                isHudVisible = true
                PushShowMessage()
                TriggerServerEvent('d87-hud:server:requestUpdate')
            end

            local rawHealth = GetEntityHealth(ped)
            local health = (rawHealth > 100) and math.floor(rawHealth - 100) or math.floor(rawHealth)
            if health < 0 then health = 0 elseif health > 100 then health = 100 end
            local armor = math.floor(GetPedArmour(ped))

            local now = GetGameTimer()

            local vehicle = GetVehiclePedIsIn(ped, false)
            local isDriver = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped

            if Config.ShowStamina and Config.StaminaControlEnabled then
                if IsPedSprinting(ped) or IsPedRunning(ped) then currentStamina = currentStamina - (Config.StaminaDrainSprint * 0.1) else currentStamina = currentStamina + (Config.StaminaRegenRest * 0.1) end
                if currentStamina < 0 then currentStamina = 0 elseif currentStamina > 100 then currentStamina = 100 end
                SetPlayerStamina(PlayerId(), currentStamina)
            end

            -- 🔄 El estrés nativo (qbox/qb-core) solo existe en esos dos frameworks: en ESX no hay
            -- equivalente, así que aunque Config.StressSource sea 'framework' se sigue usando la
            -- mecánica interna del script para no dejar el estrés inutilizado.
            local useInternalStress = (Config.StressSource == 'internal') or (CurrentFramework == 'esx')

            if useInternalStress and Config.StressEnabled and Config.ShowStress and not IsStressExemptJob() and IsPedShooting(ped) and (now - lastStressGain) >= Config.StressShootCooldown then
                currentStress = math.min(100, currentStress + Config.StressGainOnShoot)
                if CurrentFramework == 'qbox' or CurrentFramework == 'qb-core' then TriggerServerEvent('hud:server:GainStress', Config.StressGainOnShoot) end
                lastStressGain = now
            end

            if useInternalStress and Config.StressEnabled and Config.ShowStress and not IsStressExemptJob() then
                if isDriver then
                    local speedKmh = GetEntitySpeed(vehicle) * 3.6

                    if speedKmh >= Config.StressSpeedThreshold and (now - lastSpeedStressGain) >= Config.StressSpeedInterval then
                        currentStress = math.min(100, currentStress + Config.StressGainSpeed)
                        lastSpeedStressGain = now
                    end

                    if (lastVehicleSpeed - speedKmh) >= Config.StressAccidentSpeedDrop and (now - lastAccidentStressGain) >= Config.StressAccidentCooldown then
                        currentStress = math.min(100, currentStress + Config.StressGainAccident)
                        lastAccidentStressGain = now
                    end

                    lastVehicleSpeed = speedKmh
                else
                    lastVehicleSpeed = 0
                end
            end

            local isDiving, oxygenPct = false, 100
            if Settings.showOxygen then
                isDiving = IsPedSwimmingUnderWater(ped) or false
                oxygenPct = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10.0)
                if oxygenPct > 100 then oxygenPct = 100 elseif oxygenPct < 0 then oxygenPct = 0 end
            end

            local voiceTalking, voiceProximity = false, 0
            if Settings.showVoice then
                voiceTalking = NetworkIsPlayerTalking(PlayerId()) or false
                if GetResourceState('pma-voice') == 'started' then
                    local proximityState = LocalPlayer.state.proximity
                    if proximityState and proximityState.distance then
                        voiceProximity = proximityState.distance
                    end
                end
            end

            local inVehicle = vehicle ~= 0
            local fuelPct = nil
            if inVehicle then
                local fuel = GetVehicleFuel(vehicle)
                if fuel then fuelPct = math.floor(fuel) end
            end

            local fastPayload = {
                playerId = playerServerId,
                health = health,
                armor = armor,
                hunger = math.floor(cachedHunger),
                thirst = math.floor(cachedThirst),
                stress = math.floor(currentStress),
                stamina = math.floor(currentStamina),
                sleep = math.floor(currentSleep),
                diving = isDiving,
                oxygen = oxygenPct,
                talking = voiceTalking,
                voiceDist = math.floor(voiceProximity),
                wpActive = waypointActive,
                wpDistance = waypointStr,
                inVehicle = inVehicle,
                fuel = fuelPct
            }

            if SyncAndCheckChanged(lastFastPayload, fastPayload) then
                fastPayload.action = "hud_update"
                SendNUIMessage(fastPayload)
            end
        else
            if isHudVisible then
                isHudVisible = false
                SendNUIMessage({ action = "hud_hide" })
            end
            sleep = 1000
        end
        Wait(sleep)
    end
end)

-- 🧭 HILO LIGERO: brújula, hora, calle y zona. No necesita reaccionar al instante,
-- así que corre a Config.HudCompassInterval (>200ms) para no parpadear ni gastar CPU de más.
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local isPauseOpen = IsPauseMenuActive() or IsRadarHidden() or hudDisabledGlobal

        if not isPauseOpen and isHudVisible then
            sleep = Config.HudCompassInterval or 300

            local now = GetGameTimer()
            local doSlowUpdate = (now - lastSlowUpdate) >= SLOW_INTERVAL

            if doSlowUpdate then
                if CurrentFramework == 'qbox' then
                    cachedHunger = LocalPlayer.state.hunger or cachedHunger
                    cachedThirst = LocalPlayer.state.thirst or cachedThirst
                    cachedJobName = (LocalPlayer.state.job and LocalPlayer.state.job.name) or cachedJobName
                    if Config.StressSource == 'framework' then
                        currentStress = LocalPlayer.state.stress or currentStress
                    end
                elseif CurrentFramework == 'qb-core' then
                    local playerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
                    if playerData and playerData.metadata then
                        cachedHunger = playerData.metadata['hunger'] or cachedHunger
                        cachedThirst = playerData.metadata['thirst'] or cachedThirst
                        if Config.StressSource == 'framework' then
                            currentStress = playerData.metadata['stress'] or currentStress
                        end
                    end
                    if playerData and playerData.job then cachedJobName = playerData.job.name or cachedJobName end
                elseif CurrentFramework == 'esx' then
                    TriggerEvent('esx_status:getStatus', 'hunger', function(status) if status then cachedHunger = status.val / 10000 end end)
                    TriggerEvent('esx_status:getStatus', 'thirst', function(status) if status then cachedThirst = status.val / 10000 end end)
                    local esxOk, esxObj = pcall(function() return exports['es_extended']:getSharedObject() end)
                    if esxOk and esxObj and esxObj.GetPlayerData then
                        local pData = esxObj.GetPlayerData()
                        if pData and pData.job then cachedJobName = pData.job.name or cachedJobName end
                    end
                end

                local coords = GetEntityCoords(ped)
                local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                if streetHash and streetHash ~= 0 then
                    cachedStreetName = GetStreetNameFromHashKey(streetHash) or _L('unknown_street')
                else
                    cachedStreetName = _L('unknown_street')
                end

                if Settings.showZone then
                    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
                    local label = GetLabelText(zoneHash)
                    cachedZoneName = (label and label ~= "NULL" and label ~= "") and label or ""
                else
                    cachedZoneName = ""
                end

                lastSlowUpdate = now
            end

            local cardinalDir = "N"
            if Settings.showCompass then
                local heading = GetEntityHeading(ped)
                local headingIndex = math.floor((heading + 22.5) / 45) % 8
                cardinalDir = Directions[headingIndex] or "N"
            end

            local timeStr = ""
            if Settings.showTime then
                timeStr = string.format("%02d:%02d", GetClockHours(), GetClockMinutes())
            end

            local compassPayload = {
                compass = cardinalDir,
                street = cachedStreetName,
                zone = cachedZoneName,
                time = timeStr
            }

            if SyncAndCheckChanged(lastCompassPayload, compassPayload) then
                compassPayload.action = "hud_update_compass"
                SendNUIMessage(compassPayload)
            end
        else
            sleep = 1000
        end
        Wait(sleep)
    end
end)

AddEventHandler('playerSpawned', function() cachedPlayerServerId = nil end)

exports('ModifySleep', function(amount) currentSleep = currentSleep + amount if currentSleep < 0 then currentSleep = 0 elseif currentSleep > 100 then currentSleep = 100 end end)
exports('ModifyStress', function(amount)
    if amount > 0 and not Config.StressFromJobs then return end
    currentStress = currentStress + amount
    if currentStress < 0 then currentStress = 0 elseif currentStress > 100 then currentStress = 100 end
end)

-- ============================================================================
-- 🔔 NOTIFICACIONES
-- ============================================================================
function SendAlert(type, message, duration, customTitle)
    local alertType = Config.NotifyTypes[type] and type or 'info'
    local alertDuration = duration or Settings.notifyDuration or Config.NotifyDefaultDuration
    local finalTitle = customTitle or _L('title_' .. alertType)

    SendNUIMessage({
        action = "notify",
        type = alertType,
        title = finalTitle:upper(),
        message = message,
        duration = alertDuration,
        color = Config.NotifyTypes[alertType].color,
        icon = Config.NotifyTypes[alertType].icon,
        position = Settings.notifyPosition or Config.NotifyPosition,
        maxNotifications = Settings.notifyMax or Config.NotifyMaxNotifications
    })
end

exports('SendAlert', SendAlert)

RegisterNetEvent('d87-notifications:client:SendAlert', function(type, message, duration, customTitle)
    SendAlert(type, message, duration, customTitle)
end)

-- 🔥 SECUESTRO DE NOTIFICACIONES EXTERNAS 🔥

-- OX_LIB (estándar de Qbox)
if GetResourceState('ox_lib') == 'started' then
    RegisterNetEvent('ox_lib:notify', function(data)
        if data and data.description then
            SendAlert(data.type or 'info', data.description, data.duration, data.title)
        end
    end)
end

-- QBX_CORE / QB-CORE
RegisterNetEvent('QBCore:Notify', function(text, type, length)
    if text then
        SendAlert(type or 'info', text, length)
    end
end)

-- NOTIFICACIONES NATIVAS DE GTA V / FIVEM
RegisterNetEvent('feed:showNotification', function(text)
    if text then SendAlert('info', text) end
end)

RegisterNetEvent('esx:showNotification', function(text, type, length)
    if text then SendAlert(type or 'info', text, length) end
end)

RegisterNetEvent('esx:showAdvancedNotification', function(sender, subject, msg, textureDict, iconType, messageType)
    if msg then SendAlert('info', msg, 5000, sender .. " - " .. subject) end
end)

-- ============================================================================
-- ⚔️ HUD DE ARMAS
-- ============================================================================
local isWeaponEquipped = false
local currentWeaponData = nil -- solo se llena vía evento ox_inventory:currentWeapon
local isSpecialWeapon = false
local lastClipCount = -1
local isAiming = false
local hideTimer = nil

local WeaponsInventory = 'none'

local reserveAmmoCache = 0
local lastReserveFetch = 0
local reserveFetchInFlight = false

local SpecialWeapons = {
    [`WEAPON_STUNGUN`] = true,
    [`WEAPON_STUNGUN_MP`] = true,
    [`WEAPON_RAYPISTOL`] = true,
    [`WEAPON_RAYCARBINE`] = true,
    [`WEAPON_RAYMINIGUN`] = true,
}

CreateThread(function()
    if Config.WeaponsFramework ~= 'auto' then
        WeaponsInventory = Config.WeaponsFramework
    elseif GetResourceState('ox_inventory') == 'started' then
        WeaponsInventory = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then
        WeaponsInventory = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        WeaponsInventory = 'esx'
    else
        WeaponsInventory = 'none'
    end
end)

local function GetReserveAmmoOx(ammoType)
    if not ammoType then return 0 end
    if GetResourceState('ox_inventory') ~= 'started' then return 0 end

    local ok, count = pcall(function()
        return exports.ox_inventory:Search('count', ammoType)
    end)

    return (ok and count) or 0
end

local function GetReserveAmmoRemote(ammoType)
    if not ammoType then return 0 end

    local now = GetGameTimer()
    if reserveFetchInFlight or (now - lastReserveFetch) < (Config.WeaponsReserveAmmoPollInterval or 1000) then
        return reserveAmmoCache
    end

    lastReserveFetch = now
    reserveFetchInFlight = true

    lib.callback('d87-hud:getReserveAmmo', false, function(count)
        reserveAmmoCache = count or 0
        reserveFetchInFlight = false
    end, ammoType)

    return reserveAmmoCache
end

local function ResolveAmmoType(weaponHash, weaponData)
    if WeaponsInventory == 'ox' and weaponData then
        local ammoType = weaponData.ammo
        if not ammoType and weaponData.metadata then
            ammoType = weaponData.metadata.ammo
        end
        return ammoType
    end

    return Config.WeaponsAmmoTypeMap and Config.WeaponsAmmoTypeMap[weaponHash]
end

local function GetReserveAmmo(weaponHash, weaponData)
    local ammoType = ResolveAmmoType(weaponHash, weaponData)

    if WeaponsInventory == 'ox' then
        return GetReserveAmmoOx(ammoType)
    end

    return GetReserveAmmoRemote(ammoType)
end

local function GetNativeWeaponData(ped)
    local weaponHash = GetSelectedPedWeapon(ped)
    if weaponHash == `WEAPON_UNARMED` then return nil end

    return {
        hash = weaponHash,
        label = (Config.WeaponsLabels and Config.WeaponsLabels[weaponHash]) or "ARMA",
        durability = 100,
    }
end

local function CancelPendingHide()
    if hideTimer then
        hideTimer = false
    end
end

local function HideWeaponsHud()
    if not isWeaponEquipped then return end

    isWeaponEquipped = false
    lastClipCount = -1
    isAiming = false

    if not Settings.weaponsHideWhenUnarmed then
        SendNUIMessage({ action = "weapons_hide" })
        return
    end

    local myTimer = {}
    hideTimer = myTimer

    SetTimeout(Settings.weaponsFadeTimeout or 0, function()
        if hideTimer == myTimer then
            SendNUIMessage({ action = "weapons_hide" })
            hideTimer = nil
        end
    end)
end

-- Solo se dispara si ox_inventory está corriendo
RegisterNetEvent('ox_inventory:currentWeapon', function(weaponData)
    currentWeaponData = weaponData
    if not weaponData then
        HideWeaponsHud()
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        local isPauseOpen = IsPauseMenuActive()
        local isInvOpen = LocalPlayer.state.invOpen or false

        local weaponData = nil
        local weaponHash = nil

        if WeaponsInventory == 'ox' then
            weaponData = currentWeaponData
            weaponHash = weaponData and weaponData.hash
        else
            weaponData = GetNativeWeaponData(ped)
            weaponHash = weaponData and weaponData.hash
        end

        if weaponData and not isPauseOpen and not isInvOpen then
            sleep = 50 -- Aceleramos para que la detección de apuntado sea instantánea

            local weaponGroup = GetWeapontypeGroup(weaponHash)
            isSpecialWeapon = SpecialWeapons[weaponHash] or (weaponGroup == `GROUP_MELEE`) or false

            local isCurrentlyAiming = false
            if not isSpecialWeapon or weaponHash == `WEAPON_STUNGUN` or weaponHash == `WEAPON_RAYPISTOL` then
                HideHudComponentThisFrame(14)

                if IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25) then
                    isCurrentlyAiming = true
                end
            end

            if isCurrentlyAiming ~= isAiming then
                isAiming = isCurrentlyAiming
                SendNUIMessage({ action = "weapons_toggle_crosshair", status = isAiming })
            end

            local ammoInClip = 0
            local isReloading = false

            if not isSpecialWeapon then
                _, ammoInClip = GetAmmoInClip(ped, weaponHash)
                isReloading = IsPedReloading(ped)

                if ammoInClip == 0 and lastClipCount > 0 then
                    PlaySoundFrontend(-1, "FACTION_TEAM_MENU_SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end
                lastClipCount = ammoInClip
            end

            local durabilityPct = 100
            if WeaponsInventory == 'ox' and weaponData then
                if weaponData.metadata and weaponData.metadata.durability then
                    durabilityPct = math.floor(weaponData.metadata.durability)
                else
                    durabilityPct = math.floor(weaponData.durability or 100)
                end
            else
                durabilityPct = math.floor(weaponData.durability or 100)
            end

            local ammoInReserve = 0
            if not isSpecialWeapon then
                ammoInReserve = GetReserveAmmo(weaponHash, weaponData)
            end

            if not isWeaponEquipped then
                isWeaponEquipped = true
                CancelPendingHide()
                SendNUIMessage({
                    action = "weapons_show",
                    size = Settings.weaponsSize,
                    bottom = Settings.weaponsBottomMargin
                })
            end

            SendNUIMessage({
                action = "weapons_update",
                weapon = weaponData.label or "ARMA",
                clip = ammoInClip,
                reserve = ammoInReserve,
                durability = durabilityPct,
                isSpecial = isSpecialWeapon,
                reloading = isReloading
            })
        else
            if isWeaponEquipped then
                HideWeaponsHud()
            end
            if isPauseOpen or isInvOpen then
                sleep = 250
            end
        end
        Wait(sleep)
    end
end)
