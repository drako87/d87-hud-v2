# 📊 D87 HUD

**D87 HUD** es el paquete unificado de interfaz para servidores de rol en FiveM. Reúne en un solo recurso el **HUD de constantes vitales**, las **Notificaciones**, el **HUD de Armas** y el **Velocímetro/Instrumentación Vehicular**, compartiendo detección de framework, sistema de ajustes en vivo y persistencia, todo bajo un único `fxmanifest.lua`.

---

## 🆕 Novedades de la v2.1.0 (fusión con D87 Speedometer)

* **Velocímetro vehicular integrado:** velocidad, marcha, RPM, barra de motor y combustible, cierre centralizado, luces, odómetro, control de crucero, eyección por choque sin cinturón y radares fijos — todo dentro del mismo recurso y del mismo `ui.js`.
* **Nueva pestaña "Vehículo" en `/hudmenu`:** escala, márgenes, unidad de velocidad (KM/H o MPH), visibilidad de RPM/combustible/motor/marchas/nombre del vehículo, umbrales de alerta y activación de radares — todo ajustable en vivo, sin reiniciar el recurso.
* **Config reorganizado:** los ajustes del velocímetro usan el prefijo `Config.Speedo*` para no chocar con los del HUD de constantes (p. ej. `Config.Size` del HUD vs `Config.SpeedoSize` del velocímetro).
* **Un solo `client/main.lua`:** toda la telemetría comparte el mismo sistema de `Settings` y de persistencia (KVP), evitando duplicar hilos o detección de framework entre módulos.

---

## 📁 Estructura del proyecto

```
d87-hud/
├── client/
│   └── main.lua        -- HUD de constantes + Notificaciones + HUD de armas + Velocímetro (cliente)
├── server/
│   └── main.lua         -- Cuentas/trabajo, retransmisión de notificaciones, munición de reserva y versionCheck
├── config/
│   └── config.lua       -- Configuración única de los 4 módulos
├── locales/
│   ├── es.lua / en.lua / fr.lua / de.lua
├── html/
│   ├── ui.html / ui.css / ui.js
│   └── img/logo.png
├── fxmanifest.lua
└── README.md
```

---

## 🌟 Características por módulo

### 📊 HUD de constantes
* Salud, Armadura (auto-ocultable sin chaleco), Hambre, Sed, Estrés, Resistencia, Sueño, Oxígeno al bucear, Micrófono (PMA-Voice), Brújula + hora, distancia a ruta (waypoint) y panel financiero (efectivo/banco/trabajo).
* Smart Fade Out para hambre/sed al estar saciado, alerta parpadeante + sonora configurable, 3 temas de color y modo compacto.
* Multi-framework: auto-detecta **Qbox**, **QBCore** o **ESX Legacy**.

### 🔔 Notificaciones
* Alertas flotantes premium con 6 tipos predefinidos (info, éxito, aviso, error, policía, médica), posición configurable en pantalla y barra de progreso.
* Secuestra automáticamente las notificaciones de `ox_lib`, `QBCore`, `ESX` y las nativas del juego, así no necesitas cambiar el código de otros recursos.

### ⚔️ HUD de armas
* Puntero táctico dinámico, contador de cargador/reserva y barra de durabilidad.
* Multi-inventario: auto-detecta **ox_inventory**, **qb-inventory** o **ESX Legacy** (independiente del framework base).

### 🏎️ Velocímetro / Instrumentación vehicular
* Velocidad (KM/H o MPH), marcha, RPM secuencial, barra de motor y de combustible con alertas parpadeantes.
* Cierre centralizado, estado de luces (cortas/largas), odómetro persistente por vehículo y adaptación automática a motos/barcos/aviones/helicópteros.
* Control de crucero, eyección por choque a alta velocidad sin cinturón, multiplicador de daño de motor configurable y radares fijos con aviso sonoro.
* Asistencia de desvolcado vía `ox_target` (si está instalado).

---

## 🔄 Compatibilidad: fuente de las estadísticas

Salud, Armadura, Hambre y Sed siempre se leen de los valores nativos/del framework, así que no requieren configuración. Estrés y Resistencia son mecánicas propias del script pensadas para servidores sin sistema propio:

```lua
Config.StressSource = 'internal'    -- 'internal' (ganancia por disparos/velocidad/accidentes, por defecto)
                                     -- 'framework' (usa metadata.stress nativo de qbox/qb-core; en ESX no existe y usa 'internal' automáticamente)

Config.StaminaControlEnabled = true -- false = el script deja de forzar SetPlayerStamina (evita
                                     -- conflictos con otro recurso que gestione el sprint)
```

El combustible tiene dos sistemas independientes y configurables por separado:

```lua
Config.HudFuelSystem   = 'native'  -- Alimenta la caja pequeña de combustible del HUD de constantes
Config.SpeedoFuelSystem = 'auto'   -- Alimenta la barra de combustible del velocímetro ('auto' detecta ox_fuel, bazufix-fuel, legacyfuel, qb-fuel)
```

Si tu servidor ya gestiona el estrés, la resistencia o el combustible con otro recurso, ajusta estos valores para evitar conflictos o datos duplicados.

---

## 📥 Instalación

1. Elimina/deja de iniciar tus antiguas carpetas `d87-hud` (v1.x), `d87-notifications`, `d87-weaponshud` y `d87-speedometer` si las tenías por separado (ya no se usan).
2. Copia la nueva carpeta a tu directorio de recursos, renombrada exactamente **`d87-hud`**.
3. Asegúrate de tener **ox_lib** instalado (dependencia obligatoria del HUD de armas y del comprobador de versiones).
4. Copia tu `logo.png` a `html/img/logo.png` si usas uno personalizado (no se incluye por defecto).
5. En tu `server.cfg`, inicia el recurso **debajo** de tu framework y de tu inventario:
   ```cfg
   ensure ox_lib
   ensure qbx_core        -- o qb-core / es_extended, según tu servidor
   ensure ox_inventory     -- o qb-inventory / es_extended
   ensure d87-hud
   ```
6. Reinicia el servidor o ejecuta `/start d87-hud`.
7. Revisa `config/config.lua` y ajusta lo que necesites (ver siguiente sección).

---

## ⚙️ Configuración básica (`config/config.lua`)

```lua
Config.Framework = 'auto'          -- Framework base (cuentas/trabajo): 'auto', 'qbox', 'qb-core', 'esx'
Config.Locale = 'es'               -- 'es', 'en', 'fr', 'de'

-- HUD de constantes
Config.Size = 1.05
Config.Theme = 'purple'            -- 'purple', 'blue', 'red'
Config.CompactMode = false
Config.MenuCommand = 'hudmenu'     -- Comando para abrir el menú de ajustes en vivo

-- Notificaciones
Config.NotifyPosition = 'top-center'
Config.NotifyDefaultDuration = 5000
Config.NotifyMaxNotifications = 5

-- HUD de armas
Config.WeaponsFramework = 'auto'   -- Framework de inventario: 'auto', 'ox', 'qb', 'esx'
Config.WeaponsSize = 1.0
Config.WeaponsHideWhenUnarmed = true

-- Velocímetro vehicular
Config.SpeedoSize = 1.0
Config.SpeedoUseMPH = false
Config.SpeedoEnableRadars = false
Config.SpeedoVehicleDamageMultiplier = 0.3   -- 1.0 = daño normal | 0.3 = triple aguante | 0.2 = tanques

-- Compatibilidad de estadísticas
Config.StressSource = 'internal'
Config.StaminaControlEnabled = true
```

> La mayoría de estas opciones (posición, escalas, visibilidad, tema, notificaciones, armas y velocímetro) también se pueden ajustar en caliente desde el juego con **`/hudmenu`**, sin tocar `config.lua` ni reiniciar el recurso.

---

## 🧩 Menú de ajustes en vivo (`/hudmenu`)

7 pestañas disponibles:

| Pestaña | Contenido |
|---|---|
| **Posición** | Escalas del HUD y del panel financiero, altura/margen de la columna de estadísticas, brújula y panel financiero |
| **Visibilidad** | Activa/desactiva cada elemento del HUD de constantes individualmente |
| **Alertas** | Umbral de alerta (%), sonido de alerta y volumen |
| **Apariencia** | Tema de color, modo compacto, Smart Fade Out, nombre de zona y unidades de distancia |
| **Notificaciones** | Posición en pantalla, duración y máximo de notificaciones visibles |
| **Armas** | Escala del HUD, margen inferior, ocultar si no hay arma y retardo de ocultado |
| **Vehículo** | Escala y márgenes del velocímetro, unidad de velocidad (MPH/KM-H), visibilidad de RPM/combustible/motor/marchas/nombre, umbrales de alerta y activación de radares |

Los cambios se previsualizan en vivo. **Guardar y cerrar** los aplica de forma permanente (KVP local, por jugador). **Restaurar por defecto** vuelve a los valores de `config.lua`.

> Las teclas físicas (motor, cinturón, crucero) y la física del vehículo (multiplicador de daño, velocidad mínima de eyección, distancia y lista de radares) solo se configuran desde `config.lua`, ya que requieren reiniciar el recurso.

---

## 🛠️ Exports (uso desde otros recursos)

```lua
-- Notificaciones
exports['d87-hud']:SendAlert('success', 'Mensaje de ejemplo', 5000, 'Título opcional')

-- Estrés y sueño del HUD de constantes
exports['d87-hud']:ModifyStress(10)
exports['d87-hud']:ModifySleep(-20)
```

También puedes disparar notificaciones vía evento de red desde el servidor:

```lua
TriggerEvent('d87-notifications:server:SendAlert', source, 'warning', 'Mensaje', 5000)  -- a un jugador
TriggerEvent('d87-notifications:server:BroadcastAlert', 'police', 'Aviso a todo el servidor', 7000)  -- global
```

---

## ⌨️ Teclas por defecto (velocímetro)

| Acción | Tecla | Config |
|---|---|---|
| Encender/apagar motor | `M` | `Config.SpeedoEngineKey` |
| Poner/quitar cinturón | `B` | `Config.SpeedoSeatbeltKey` |
| Activar/desactivar crucero | `Y` | `Config.SpeedoCruiseKey` |

Reasignables desde Ajustes de FiveM → Teclas → Controles de este recurso.

---

## 👤 Autoría y Créditos

* **Recurso:** D87 HUD
* **Autor Oficial:** `Drako87/Dracatt`
* **Ecosistema:** Qbox, QBCore, ESX Legacy & Standalone Project.
