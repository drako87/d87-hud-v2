# 📊 D87 HUD v2

**D87 HUD v2** es el paquete unificado de interfaz para servidores de rol en FiveM. A partir de la v1.1.0, un único recurso reemplaza a los tres scripts independientes que existían antes (**D87 HUD**, **D87 Notifications** y **D87 Weapons HUD**), compartiendo detección de framework, sistema de ajustes en vivo y persistencia, todo bajo un solo `fxmanifest.lua`.

---

## 🆕 Novedades de esta versión (fusión de los 3 scripts)

* **Un solo recurso `d87-hud v2`** en lugar de `d87-hud` + `d87-notifications` + `d87-weaponshud`. Menos recursos que iniciar, un único `config/config.lua` y una sola carpeta `locales/`.
* **Menú de ajustes en vivo ampliado (`/hudmenu`):** ahora tiene 6 pestañas — Posición, Visibilidad, Alertas, Apariencia, **Notificaciones** y **Armas** — para configurar los tres módulos sin tocar código ni reiniciar el recurso. Los cambios se guardan por jugador (KVP local).
* **Notificaciones integradas:** el HUD reemplaza automáticamente las notificaciones de `ox_lib`, `QBCore:Notify`, `esx:showNotification`/`showAdvancedNotification` y las nativas de FiveM (`feed:showNotification`), mostrándolas con el estilo premium de D87.
* **HUD de armas integrado:** puntero táctico + contador de munición/durabilidad, compatible con `ox_inventory`, `qb-inventory` y `ESX Legacy`, con auto-detección independiente del framework base (ver sección de compatibilidad).
* **Nuevo control de compatibilidad de estadísticas:** opción para elegir si el Estrés usa la mecánica propia del script o el `metadata.stress` nativo de qbox/qb-core, y opción para desactivar el control forzado de Resistencia (`SetPlayerStamina`) si otro recurso ya la gestiona. Salud, Armadura, Hambre y Sed siempre usan los valores nativos del framework detectado.
* **Estructura de carpetas reorganizada:** `client/main.lua`, `server/main.lua`, `config/config.lua`, `locales/*.lua`, `html/`.

---

## 📁 Estructura del proyecto

```
d87-hud/
├── client/
│   └── main.lua        -- HUD de constantes + Notificaciones + HUD de armas (cliente)
├── server/
│   └── main.lua        -- Cuentas/trabajo, retransmisión de notificaciones y munición de reserva
├── config/
│   └── config.lua       -- Configuración única de los 3 módulos
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
* Requiere **ox_lib** (se usa para el callback de munición de reserva en qb/ESX).

---

## 🔄 Compatibilidad: fuente de las estadísticas

Salud, Armadura, Hambre y Sed siempre se leen de los valores nativos/del framework, así que no requieren configuración. Estrés y Resistencia son mecánicas propias del script pensadas para servidores sin sistema propio:

```lua
Config.StressSource = 'internal'    -- 'internal' (ganancia por disparos/velocidad/accidentes, por defecto)
                                     -- 'framework' (usa metadata.stress nativo de qbox/qb-core; en ESX no existe y usa 'internal' automáticamente)

Config.StaminaControlEnabled = true -- false = el script deja de forzar SetPlayerStamina (evita
                                     -- conflictos con otro recurso que gestione el sprint)
```

Si tu servidor ya gestiona el estrés o la resistencia con otro recurso, cambia estos valores para evitar conflictos o datos duplicados.

---

## 📥 Instalación

1. Elimina/deja de iniciar tus antiguas carpetas `d87-hud`, `d87-notifications` y `d87-weaponshud` si las tenías por separado (ya no se usan).
2. Copia la nueva carpeta a tu directorio de recursos, renombrada exactamente **`d87-hud`**.
3. Asegúrate de tener **ox_lib** instalado (dependencia obligatoria del HUD de armas).
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

-- Compatibilidad de estadísticas
Config.StressSource = 'internal'
Config.StaminaControlEnabled = true
```

> La mayoría de estas opciones (posición, escalas, visibilidad, tema, notificaciones y armas) también se pueden ajustar en caliente desde el juego con **`/hudmenu`**, sin tocar `config.lua` ni reiniciar el recurso.

---

## 🧩 Menú de ajustes en vivo (`/hudmenu`)

6 pestañas disponibles:

| Pestaña | Contenido |
|---|---|
| **Posición** | Escalas del HUD y del panel financiero, altura/margen de la columna de estadísticas, brújula y panel financiero |
| **Visibilidad** | Activa/desactiva cada elemento del HUD de constantes individualmente |
| **Alertas** | Umbral de alerta (%), sonido de alerta y volumen |
| **Apariencia** | Tema de color, modo compacto, Smart Fade Out, nombre de zona y unidades de distancia |
| **Notificaciones** | Posición en pantalla, duración y máximo de notificaciones visibles |
| **Armas** | Escala del HUD, margen inferior, ocultar si no hay arma y retardo de ocultado |

Los cambios se previsualizan en vivo. **Guardar y cerrar** los aplica de forma permanente (KVP local, por jugador). **Restaurar por defecto** vuelve a los valores de `config.lua`.

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

## 👤 Autoría y Créditos

* **Recurso:** D87 HUD
* **Autor Oficial:** `Drako87/Dracatt`
* **Ecosistema:** Qbox, QBCore, ESX Legacy & Standalone Project.
