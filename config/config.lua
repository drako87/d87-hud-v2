Config = {}

-- ============================================================================
-- 🌐 GENERAL
-- ============================================================================
Config.Framework = 'auto'      -- Framework base (cuentas/trabajo): 'auto', 'qbox', 'qb-core', 'esx'
Config.Locale = 'es'           -- 'es', 'en', 'fr', 'de'
Config.GitHubRepo = 'https://github.com/drako87/d87-hud-v2'

-- ============================================================================
-- 📊 HUD DE CONSTANTES VITALES
-- ============================================================================
Config.Size = 1.05
Config.BottomMargin = 15
Config.LeftMargin = 16.5

-- Posición de la columna de constantes (Flanco Derecho)
Config.StatsBottom = 35
Config.StatsLeft = 16.5

-- Brújula
Config.CompassBottom = 220
Config.CompassLeft = 2.2

-- Caja de ruta (waypoint)
Config.WaypointBottom = 188
Config.WaypointLeft = 12.3

-- Micrófono PMA-Voice
Config.VoiceBottom = 20
Config.VoiceRight = 20

-- Panel financiero (arriba a la derecha)
Config.TopRightSize = 1.0
Config.TopMargin = 40
Config.RightMargin = 40

-- Visibilidad de columnas
Config.ShowHealth = true
Config.ShowArmor = true
Config.ShowHunger = true
Config.ShowThirst = true
Config.ShowStress = true
Config.ShowStamina = true
Config.ShowSleep = true

Config.ShowVoice = true
Config.ShowOxygen = true
Config.ShowCompass = true
Config.ShowTime = true
Config.ShowFuel = true

-- ============================================================================
-- ⚡ RENDIMIENTO (resmon) — frecuencias de actualización de los hilos del HUD
-- ============================================================================
Config.HudFastInterval = 150     -- ms — hilo "crítico": salud, armadura, estrés, resistencia, sueño, oxígeno, voz, waypoint, combustible
Config.HudCompassInterval = 300  -- ms — hilo "ligero": brújula y hora (>200ms recomendado para evitar parpadeos y ahorrar CPU)

-- ⛽ SISTEMA DE COMBUSTIBLE — usado por la caja de combustible del HUD (solo visible dentro de un vehículo)
Config.FuelSystem = 'native'     -- 'native' (GetVehicleFuelLevel nativo de FiveM, no requiere recursos externos)
                                  -- 'LegacyFuel', 'ps-fuel', 'cdn-fuel' (usa el export GetFuel del recurso correspondiente)
                                  -- 'none' (desactiva la lectura de combustible aunque Config.ShowFuel esté activo)


Config.ShowCash = true
Config.ShowBank = true
Config.ShowJob = true

-- Mecánicas
Config.AlertPercent = 20
Config.StressGainOnShoot = 2
Config.StressScreenBlur = true
Config.StaminaDrainSprint = 1.5
Config.StaminaRegenRest = 2.0
Config.SleepGainMinutes = 45
Config.SleepEffectBlur = true
Config.SleepDuration = 5

Config.StressEnabled = true
Config.StressEffectThreshold = 80
Config.StressShootCooldown = 500
Config.StressSpeedThreshold = 140
Config.StressGainSpeed = 1
Config.StressSpeedInterval = 3000
Config.StressAccidentSpeedDrop = 40
Config.StressGainAccident = 15
Config.StressAccidentCooldown = 4000
Config.StressFromJobs = true
Config.StressExemptJobs = {
    'police',
    'sheriff',
    'ambulance',
}

-- ============================================================================
-- 🔄 COMPATIBILIDAD: FUENTE DE LAS ESTADÍSTICAS
-- Salud, Armadura, Hambre y Sed siempre usan los valores nativos/del framework
-- (no requieren opción). Estrés y Resistencia son mecánicas propias del script
-- pensadas para servidores sin un sistema propio: si tu servidor ya gestiona
-- alguna de ellas con otro recurso, cambia aquí la fuente para evitar
-- conflictos o valores duplicados.
-- ============================================================================
Config.StressSource = 'internal'    -- 'internal' (mecánica propia del script, ganancia por disparos/velocidad/accidentes)
                                     -- 'framework' (usa el metadata.stress nativo de qbox/qb-core; en ESX no existe y se usa 'internal' automáticamente)

Config.StaminaControlEnabled = true -- false = el script deja de forzar SetPlayerStamina, evitando conflictos con otros
                                     -- recursos que gestionen el sprint/resistencia (la caja de HUD dejará de animarse)

Config.AlertSound = true
Config.AlertSoundVolume = 0.4
Config.AlertSoundCooldown = 6

Config.ShowZone = true
Config.DistanceUnit = 'metric'  -- 'metric' o 'imperial'

Config.Theme = 'purple'         -- 'purple', 'blue', 'red'
Config.CompactMode = false

Config.SmartFadeOut = false
Config.AutoHideArmor = false

Config.MenuCommand = 'hudmenu'
Config.SaveSettingsPerClient = true

-- ============================================================================
-- 🔔 NOTIFICACIONES (D87 Notifications)
-- ============================================================================
Config.NotifyDefaultDuration = 5000   -- ms
Config.NotifyMaxNotifications = 5     -- alertas visibles a la vez
Config.NotifyPosition = 'top-center'  -- 'top-right','top-left','bottom-right','bottom-left','top-center'

Config.NotifyTypes = {
    ['info']    = { color = '#3b82f6', icon = '💡' },
    ['success'] = { color = '#10b981', icon = '✅' },
    ['warning'] = { color = '#f59e0b', icon = '⚠️' },
    ['error']   = { color = '#ef4444', icon = '❌' },
    ['police']  = { color = '#1e40af', icon = '🚓' },
    ['medical'] = { color = '#ec4899', icon = '🚑' }
}

-- ============================================================================
-- ⚔️ HUD DE ARMAS (D87 Weapons HUD)
-- ============================================================================
Config.WeaponsFramework = 'auto' -- Framework de inventario: 'auto', 'ox', 'qb', 'esx'

Config.WeaponsSize = 1.0
Config.WeaponsBottomMargin = 40

Config.WeaponsHideWhenUnarmed = true
Config.WeaponsFadeTimeout = 3000

-- Solo se usa cuando WeaponsFramework no es 'ox' (ox_inventory ya trae la munición en la metadata)
Config.WeaponsReserveAmmoPollInterval = 1000

Config.WeaponsAmmoTypeMap = {
    [`WEAPON_PISTOL`]         = 'pistol_ammo',
    [`WEAPON_COMBATPISTOL`]   = 'pistol_ammo',
    [`WEAPON_APPISTOL`]       = 'pistol_ammo',
    [`WEAPON_PISTOL50`]       = 'pistol_ammo',
    [`WEAPON_SMG`]            = 'smg_ammo',
    [`WEAPON_MICROSMG`]       = 'smg_ammo',
    [`WEAPON_ASSAULTRIFLE`]   = 'rifle_ammo',
    [`WEAPON_CARBINERIFLE`]   = 'rifle_ammo',
    [`WEAPON_SPECIALCARBINE`] = 'rifle_ammo',
    [`WEAPON_PUMPSHOTGUN`]    = 'shotgun_ammo',
    [`WEAPON_SAWNOFFSHOTGUN`] = 'shotgun_ammo',
    [`WEAPON_SNIPERRIFLE`]    = 'rifle_ammo',
}

Config.WeaponsLabels = {
    [`WEAPON_PISTOL`]         = 'Pistola',
    [`WEAPON_COMBATPISTOL`]   = 'Pistola de Combate',
    [`WEAPON_APPISTOL`]       = 'Pistola AP',
    [`WEAPON_PISTOL50`]       = 'Pistola .50',
    [`WEAPON_SMG`]            = 'Subfusil',
    [`WEAPON_MICROSMG`]       = 'Micro Subfusil',
    [`WEAPON_ASSAULTRIFLE`]   = 'Rifle de Asalto',
    [`WEAPON_CARBINERIFLE`]   = 'Carabina',
    [`WEAPON_SPECIALCARBINE`] = 'Carabina Especial',
    [`WEAPON_PUMPSHOTGUN`]    = 'Escopeta de Bombeo',
    [`WEAPON_SAWNOFFSHOTGUN`] = 'Escopeta Recortada',
    [`WEAPON_SNIPERRIFLE`]    = 'Rifle de Francotirador',
    [`WEAPON_KNIFE`]          = 'Cuchillo',
    [`WEAPON_BAT`]            = 'Bate',
}
