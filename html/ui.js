/* ============================================================================
   📊 HUD DE CONSTANTES VITALES
============================================================================ */
let alertLimit = 20;

let lastState = {};
let lastBlink = {};
let lastFade = {};
let lastOxVisible = null;
let lastWpVisible = null;
let lastVoiceTalking = null;
let lastArmorVisible = null;
let lastFuelVisible = null;

let showArmorFeature = true;
let showOxygenFeature = true;
let showFuelFeature = true;
let smartFadeEnabled = true;
let autoHideArmorFeature = true;
let showZoneFeature = true;
let distanceUnit = 'metric';
let alertSoundEnabled = true;
let alertSoundVolume = 0.4;

let menuStrings = {};
let currentSettings = {};
let factoryDefaults = {};

function setTextIfChanged(id, key, value) {
    if (value === undefined || value === null) return;
    if (lastState[key] === value) return;
    lastState[key] = value;
    const el = document.getElementById(id);
    if (el) el.innerText = value;
}

function toggleAlertBlink(elementId, shouldBlink) {
    if (lastBlink[elementId] === shouldBlink) return;
    lastBlink[elementId] = shouldBlink;
    let el = document.getElementById(elementId);
    if (el) { if (shouldBlink) el.classList.add('blink-hud-alert'); else el.classList.remove('blink-hud-alert'); }
}

function toggleFade(elementId, faded) {
    if (lastFade[elementId] === faded) return;
    lastFade[elementId] = faded;
    let el = document.getElementById(elementId);
    if (el) el.classList.toggle('hud-faded', faded);
}

function setVisibility(id, visible) {
    const el = document.getElementById(id);
    if (el) el.style.display = visible ? 'flex' : 'none';
}

let audioCtx = null;
let lastBeepTime = 0;
const BEEP_COOLDOWN_MS = 6000;

function playAlertBeep() {
    if (!alertSoundEnabled || alertSoundVolume <= 0) return;
    const now = performance.now();
    if (now - lastBeepTime < BEEP_COOLDOWN_MS) return;
    lastBeepTime = now;

    try {
        if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'sine';
        osc.frequency.value = 880;
        gain.gain.value = 0;
        osc.connect(gain);
        gain.connect(audioCtx.destination);

        const t = audioCtx.currentTime;
        gain.gain.setValueAtTime(0, t);
        gain.gain.linearRampToValueAtTime(alertSoundVolume * 0.5, t + 0.02);
        gain.gain.linearRampToValueAtTime(0, t + 0.18);

        osc.start(t);
        osc.stop(t + 0.2);
    } catch (e) { /* AudioContext no disponible: fallamos en silencio */ }
}

function applySettings(s) {
    const container = document.getElementById('d87-hud');
    const finContainer = document.getElementById('d87-finance');
    const compassContainer = document.getElementById('d87-compass-box');
    const wrapper = document.getElementById('d87-hud-wrapper');

    if (s.size) container.style.transform = `scale(${s.size})`;
    if (s.statsBottom !== undefined) container.style.bottom = `${s.statsBottom}px`;
    if (s.statsLeft !== undefined) container.style.left = `${s.statsLeft}%`;

    if (s.compassBottom !== undefined) compassContainer.style.bottom = `${s.compassBottom}px`;
    if (s.compassLeft !== undefined) compassContainer.style.left = `${s.compassLeft}%`;

    if (s.topRightSize) finContainer.style.transform = `scale(${s.topRightSize})`;
    if (s.topMargin !== undefined) finContainer.style.top = `${s.topMargin}px`;
    if (s.rightMargin !== undefined) finContainer.style.right = `${s.rightMargin}px`;

    alertLimit = s.alertLimit !== undefined ? s.alertLimit : alertLimit;
    alertSoundEnabled = !!s.alertSound;
    alertSoundVolume = s.alertSoundVolume !== undefined ? s.alertSoundVolume : alertSoundVolume;
    distanceUnit = s.distanceUnit || 'metric';
    smartFadeEnabled = !!s.smartFadeOut;
    autoHideArmorFeature = !!s.autoHideArmor;
    showZoneFeature = !!s.showZone;
    showOxygenFeature = !!s.showOxygen;
    showArmorFeature = !!s.showArmor;
    showFuelFeature = !!s.showFuel;

    wrapper.classList.remove('theme-blue', 'theme-red');
    if (s.theme === 'blue') wrapper.classList.add('theme-blue');
    else if (s.theme === 'red') wrapper.classList.add('theme-red');
    wrapper.classList.toggle('compact-mode', !!s.compactMode);

    setVisibility('stat-health', s.showHealth);
    setVisibility('stat-hunger', s.showHunger);
    setVisibility('stat-thirst', s.showThirst);
    setVisibility('stat-stress', s.showStress);
    setVisibility('stat-stamina', s.showStamina);
    setVisibility('stat-sleep', s.showSleep);
    setVisibility('stat-voice', s.showVoice);
    setVisibility('fin-cash', s.showCash);
    setVisibility('fin-bank', s.showBank);
    setVisibility('fin-job', s.showJob);
    compassContainer.style.display = (s.showCompass || s.showTime) ? 'flex' : 'none';

    if (!showArmorFeature) {
        setVisibility('stat-armor', false);
        lastArmorVisible = false;
    } else if (!autoHideArmorFeature) {
        setVisibility('stat-armor', true);
        lastArmorVisible = true;
    }
}

function formatDistance(meters) {
    if (distanceUnit === 'imperial') {
        const feet = Math.round(meters * 3.28084);
        return feet + "ft";
    }
    return meters + "M";
}

function formatCountdown(totalSeconds) {
    const m = Math.floor(totalSeconds / 60);
    const s = totalSeconds % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function showSleepOverlay(duration) {
    const overlay = document.getElementById('d87-sleep-overlay');
    const countdown = document.getElementById('sleep-countdown');
    if (countdown) countdown.innerText = formatCountdown(duration);
    if (overlay) overlay.style.display = 'flex';
}

function updateSleepCountdown(remaining) {
    const countdown = document.getElementById('sleep-countdown');
    if (countdown) countdown.innerText = formatCountdown(remaining);
}

function hideSleepOverlay() {
    const overlay = document.getElementById('d87-sleep-overlay');
    if (overlay) overlay.style.display = 'none';
}

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "hud_show") {
        let wrapper = document.getElementById('d87-hud-wrapper');
        wrapper.style.display = 'block';

        let wpContainer = document.getElementById('stat-waypoint');
        let voiceContainer = document.getElementById('stat-voice');

        if (data.wpBottom) wpContainer.style.bottom = `${data.wpBottom}px`;
        if (data.wpLeft) wpContainer.style.left = `${data.wpLeft}%`;

        if (data.voiceBottom) voiceContainer.style.bottom = `${data.voiceBottom}px`;
        if (data.voiceRight) {
            voiceContainer.style.left = 'auto';
            voiceContainer.style.right = `${data.voiceRight}px`;
        }

        if (data.loadingStreet) document.getElementById('val-street').innerText = data.loadingStreet;

        document.getElementById('stat-id').style.display = 'flex';
        wpContainer.style.display = 'none';

        applySettings(data);
        currentSettings = Object.assign({}, currentSettings, data);

        lastState = {};
        lastBlink = {};
        lastFade = {};
        lastOxVisible = null;
        lastWpVisible = null;
        lastVoiceTalking = null;
    }

    else if (data.action === "hud_hide") {
        document.getElementById('d87-hud-wrapper').style.display = 'none';
    }

    else if (data.action === "hud_update_finance") {
        if (data.cash !== undefined) setTextIfChanged('val-cash', 'cash', "$" + data.cash.toLocaleString('es-ES'));
        if (data.bank !== undefined) setTextIfChanged('val-bank', 'bank', "$" + data.bank.toLocaleString('es-ES'));
        if (data.job) {
            let gradeText = data.grade ? ` (${data.grade})` : "";
            setTextIfChanged('val-job', 'job', data.job + gradeText);
        }
    }

    else if (data.action === "hud_toggleMenu") {
        menuStrings = data.strings || {};
        factoryDefaults = data.defaults || {};
        openSettingsMenu(data.settings || {}, data.open);
    }

    else if (data.action === "hud_sleepStart") {
        showSleepOverlay(data.duration);
    }

    else if (data.action === "hud_sleepTick") {
        updateSleepCountdown(data.remaining);
    }

    else if (data.action === "hud_sleepEnd") {
        hideSleepOverlay();
    }

    else if (data.action === "hud_update_compass") {
        setTextIfChanged('val-compass', 'compass', data.compass);
        setTextIfChanged('val-street', 'street', data.street);
        setTextIfChanged('val-time', 'time', data.time);

        let zoneEl = document.getElementById('val-zone');
        if (zoneEl) {
            if (showZoneFeature && data.zone) {
                setTextIfChanged('val-zone', 'zone', data.zone);
                zoneEl.style.display = 'block';
            } else {
                zoneEl.style.display = 'none';
            }
        }
    }

    else if (data.action === "hud_update") {
        setTextIfChanged('val-id', 'id', data.playerId);

        let wpBox = document.getElementById('stat-waypoint');
        if (wpBox) {
            if (data.wpActive) {
                if (lastWpVisible !== true) { wpBox.style.display = 'flex'; lastWpVisible = true; }
                setTextIfChanged('val-waypoint', 'waypoint', data.wpDistance);
            } else if (lastWpVisible !== false) {
                wpBox.style.display = 'none';
                lastWpVisible = false;
            }
        }

        if (data.voiceDist !== undefined) {
            setTextIfChanged('val-voice', 'voiceDist', formatDistance(data.voiceDist));
            if (lastVoiceTalking !== data.talking) {
                lastVoiceTalking = data.talking;
                let vIcon = document.getElementById('icon-voice');
                if (vIcon) {
                    if (data.talking) vIcon.classList.add('voice-talking-active');
                    else vIcon.classList.remove('voice-talking-active');
                }
            }
        }

        let oxBox = document.getElementById('stat-oxygen');
        if (showOxygenFeature && data.diving) {
            if (lastOxVisible !== true) { oxBox.style.display = 'flex'; lastOxVisible = true; }
            setTextIfChanged('val-oxygen', 'oxygen', data.oxygen);
            let oxAlert = data.oxygen <= 25;
            toggleAlertBlink('stat-oxygen', oxAlert);
            if (oxAlert) playAlertBeep();
        } else if (lastOxVisible !== false) {
            oxBox.style.display = 'none';
            lastOxVisible = false;
        }

        let fuelBox = document.getElementById('stat-fuel');
        if (fuelBox) {
            let shouldShowFuel = showFuelFeature && data.inVehicle && data.fuel !== null && data.fuel !== undefined;
            if (lastFuelVisible !== shouldShowFuel) {
                lastFuelVisible = shouldShowFuel;
                fuelBox.style.display = shouldShowFuel ? 'flex' : 'none';
            }
            if (shouldShowFuel) {
                setTextIfChanged('val-fuel', 'fuel', data.fuel);
                toggleAlertBlink('stat-fuel', data.fuel <= 15);
            }
        }

        setTextIfChanged('val-health', 'health', data.health);
        let healthAlert = data.health <= alertLimit;
        toggleAlertBlink('stat-health', healthAlert);
        if (healthAlert) playAlertBeep();

        setTextIfChanged('val-armor', 'armor', data.armor);
        if (showArmorFeature) {
            let shouldShowArmor = !autoHideArmorFeature || data.armor > 0;
            if (lastArmorVisible !== shouldShowArmor) {
                lastArmorVisible = shouldShowArmor;
                setVisibility('stat-armor', shouldShowArmor);
            }
        }

        setTextIfChanged('val-hunger', 'hunger', data.hunger);
        toggleAlertBlink('stat-hunger', data.hunger <= alertLimit);
        toggleFade('stat-hunger', smartFadeEnabled && data.hunger >= 95);

        setTextIfChanged('val-thirst', 'thirst', data.thirst);
        toggleAlertBlink('stat-thirst', data.thirst <= alertLimit);
        toggleFade('stat-thirst', smartFadeEnabled && data.thirst >= 95);

        setTextIfChanged('val-stress', 'stress', data.stress);
        toggleAlertBlink('stat-stress', data.stress >= 80);

        setTextIfChanged('val-stamina', 'stamina', data.stamina);
        toggleAlertBlink('stat-stamina', data.stamina <= alertLimit);

        setTextIfChanged('val-sleep', 'sleep', data.sleep);
        toggleAlertBlink('stat-sleep', data.sleep >= (100 - alertLimit));
    }
});

/* ============================================================================
   🧩 MENÚ DE AJUSTES EN VIVO
============================================================================ */
function postNUI(name, payload) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload || {})
    }).catch(() => {});
}

const VISIBILITY_ITEMS = [
    { key: 'showHealth', labelKey: 'visHealth' },
    { key: 'showArmor', labelKey: 'visArmor' },
    { key: 'showHunger', labelKey: 'visHunger' },
    { key: 'showThirst', labelKey: 'visThirst' },
    { key: 'showStress', labelKey: 'visStress' },
    { key: 'showStamina', labelKey: 'visStamina' },
    { key: 'showSleep', labelKey: 'visSleep' },
    { key: 'showVoice', labelKey: 'visVoice' },
    { key: 'showOxygen', labelKey: 'visOxygen' },
    { key: 'showCompass', labelKey: 'visCompass' },
    { key: 'showTime', labelKey: 'visTime' },
    { key: 'showFuel', labelKey: 'visFuel' },
    { key: 'showCash', labelKey: 'visCash' },
    { key: 'showBank', labelKey: 'visBank' },
    { key: 'showJob', labelKey: 'visJob' }
];

const SLIDER_FIELDS = [
    'size', 'topRightSize', 'statsBottom', 'statsLeft',
    'compassBottom', 'compassLeft', 'topMargin', 'rightMargin',
    'alertLimit', 'alertSoundVolume',
    'notifyDuration', 'notifyMax',
    'weaponsSize', 'weaponsBottomMargin', 'weaponsFadeTimeout',
    'speedoSize', 'speedoBottomMargin', 'speedoRightMargin',
    'speedoFuelAlertPercent', 'speedoEngineAlertPercent'
];

const SPEEDO_TOGGLE_FIELDS = [
    'speedoUseMPH', 'speedoShowVehicleName', 'speedoShowRpmBar',
    'speedoShowFuelBar', 'speedoShowEngineBar', 'speedoShowGearBox',
    'speedoEnableRadars'
];

let menuInitialized = false;
let workingSettings = {};
let snapshotSettings = {};

function initMenuStaticText() {
    const map = {
        'menu-title': 'title', 'tab-layout': 'tabLayout', 'tab-visibility': 'tabVisibility',
        'tab-alerts': 'tabAlerts', 'tab-appearance': 'tabAppearance',
        'tab-notify': 'tabNotify', 'tab-weapons': 'tabWeapons', 'tab-vehicle': 'tabVehicle',
        'lbl-hud-scale': 'hudScale', 'lbl-fin-scale': 'finScale',
        'lbl-section-stats': 'sectionStats', 'lbl-stats-bottom': 'statsBottom', 'lbl-stats-left': 'statsLeft',
        'lbl-section-compass': 'sectionCompass', 'lbl-compass-bottom': 'compassBottom', 'lbl-compass-left': 'compassLeft',
        'lbl-section-finance': 'sectionFinance', 'lbl-top-margin': 'topMargin', 'lbl-right-margin': 'rightMargin',
        'lbl-alert-percent': 'alertPercent', 'lbl-alert-sound': 'alertSound', 'lbl-alert-volume': 'alertVolume',
        'lbl-theme': 'theme', 'lbl-compact': 'compact', 'lbl-smart-fade': 'smartFade',
        'lbl-show-zone': 'showZone', 'lbl-units': 'units',
        'lbl-notify-position': 'notifyPositionLbl', 'lbl-notify-duration': 'notifyDurationLbl', 'lbl-notify-max': 'notifyMaxLbl',
        'lbl-weapons-size': 'weaponsSizeLbl', 'lbl-weapons-bottom': 'weaponsBottomLbl',
        'lbl-weapons-hide-unarmed': 'weaponsHideUnarmedLbl', 'lbl-weapons-fade': 'weaponsFadeLbl',
        'lbl-speedo-size': 'speedoSizeLbl', 'lbl-speedo-bottom': 'speedoBottomLbl', 'lbl-speedo-right': 'speedoRightLbl',
        'lbl-speedo-mph': 'speedoMphLbl', 'lbl-speedo-show-name': 'speedoShowNameLbl', 'lbl-speedo-show-rpm': 'speedoShowRpmLbl',
        'lbl-speedo-show-fuel': 'speedoShowFuelLbl', 'lbl-speedo-show-engine': 'speedoShowEngineLbl', 'lbl-speedo-show-gear': 'speedoShowGearLbl',
        'lbl-speedo-fuel-alert': 'speedoFuelAlertLbl', 'lbl-speedo-engine-alert': 'speedoEngineAlertLbl', 'lbl-speedo-radars': 'speedoRadarsLbl',
        'menu-reset': 'btnReset', 'menu-save': 'btnSave'
    };
    Object.keys(map).forEach(id => {
        const el = document.getElementById(id);
        if (el && menuStrings[map[id]]) el.innerText = menuStrings[map[id]];
    });

    const themeSelect = document.getElementById('opt-theme');
    if (themeSelect && themeSelect.options.length === 3) {
        themeSelect.options[0].text = menuStrings.themePurple || themeSelect.options[0].text;
        themeSelect.options[1].text = menuStrings.themeBlue || themeSelect.options[1].text;
        themeSelect.options[2].text = menuStrings.themeRed || themeSelect.options[2].text;
    }
    const unitSelect = document.getElementById('opt-distanceUnit');
    if (unitSelect && unitSelect.options.length === 2) {
        unitSelect.options[0].text = menuStrings.unitMetric || unitSelect.options[0].text;
        unitSelect.options[1].text = menuStrings.unitImperial || unitSelect.options[1].text;
    }
    const posSelect = document.getElementById('opt-notifyPosition');
    if (posSelect && posSelect.options.length === 5) {
        posSelect.options[0].text = menuStrings.posTopRight || posSelect.options[0].text;
        posSelect.options[1].text = menuStrings.posTopLeft || posSelect.options[1].text;
        posSelect.options[2].text = menuStrings.posBottomRight || posSelect.options[2].text;
        posSelect.options[3].text = menuStrings.posBottomLeft || posSelect.options[3].text;
        posSelect.options[4].text = menuStrings.posTopCenter || posSelect.options[4].text;
    }

    const grid = document.getElementById('visibility-grid');
    if (grid && grid.childElementCount === 0) {
        VISIBILITY_ITEMS.forEach(item => {
            const row = document.createElement('div');
            row.className = 'menu-row menu-row-toggle';
            row.innerHTML = `<label>${menuStrings[item.labelKey] || item.key}</label><input type="checkbox" id="opt-${item.key}">`;
            grid.appendChild(row);
            const input = row.querySelector('input');
            input.addEventListener('change', () => {
                workingSettings[item.key] = input.checked;
                applySettings(workingSettings);
            });
        });
    }

    document.querySelectorAll('.menu-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.menu-tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.menu-panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.querySelector(`.menu-panel[data-panel="${tab.dataset.tab}"]`).classList.add('active');
        });
    });

    SLIDER_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (!input) return;
        input.addEventListener('input', () => {
            const value = parseFloat(input.value);
            workingSettings[key] = value;
            const valEl = document.getElementById(`val-opt-${key}`);
            if (valEl) valEl.innerText = value;
            applySettings(workingSettings);
            if (key.startsWith('speedo')) applySpeedoSettings(workingSettings);
        });
    });

    const themeInput = document.getElementById('opt-theme');
    if (themeInput) themeInput.addEventListener('change', () => {
        workingSettings.theme = themeInput.value;
        applySettings(workingSettings);
    });
    const unitInput = document.getElementById('opt-distanceUnit');
    if (unitInput) unitInput.addEventListener('change', () => {
        workingSettings.distanceUnit = unitInput.value;
        applySettings(workingSettings);
    });
    const notifyPosInput = document.getElementById('opt-notifyPosition');
    if (notifyPosInput) notifyPosInput.addEventListener('change', () => {
        workingSettings.notifyPosition = notifyPosInput.value;
    });

    ['alertSound', 'compactMode', 'smartFadeOut', 'showZone'].forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (!input) return;
        input.addEventListener('change', () => {
            workingSettings[key] = input.checked;
            applySettings(workingSettings);
        });
    });

    const weaponsHideInput = document.getElementById('opt-weaponsHideWhenUnarmed');
    if (weaponsHideInput) weaponsHideInput.addEventListener('change', () => {
        workingSettings.weaponsHideWhenUnarmed = weaponsHideInput.checked;
    });

    SPEEDO_TOGGLE_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (!input) return;
        input.addEventListener('change', () => {
            workingSettings[key] = input.checked;
            applySpeedoSettings(workingSettings);
        });
    });

    document.getElementById('menu-close').addEventListener('click', () => closeSettingsMenu(false));
    document.getElementById('menu-save').addEventListener('click', () => closeSettingsMenu(true));
    document.getElementById('menu-reset').addEventListener('click', () => {
        workingSettings = Object.assign({}, factoryDefaults);
        populateMenuInputs(workingSettings);
        applySettings(workingSettings);
        applySpeedoSettings(workingSettings);
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && document.getElementById('d87-menu-overlay').style.display !== 'none') {
            closeSettingsMenu(false);
        }
    });

    menuInitialized = true;
}

function populateMenuInputs(s) {
    SLIDER_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (input && s[key] !== undefined) {
            input.value = s[key];
            const valEl = document.getElementById(`val-opt-${key}`);
            if (valEl) valEl.innerText = s[key];
        }
    });
    VISIBILITY_ITEMS.forEach(item => {
        const input = document.getElementById(`opt-${item.key}`);
        if (input) input.checked = !!s[item.key];
    });
    ['alertSound', 'compactMode', 'smartFadeOut', 'showZone'].forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (input) input.checked = !!s[key];
    });
    const themeInput = document.getElementById('opt-theme');
    if (themeInput) themeInput.value = s.theme || 'purple';
    const unitInput = document.getElementById('opt-distanceUnit');
    if (unitInput) unitInput.value = s.distanceUnit || 'metric';
    const notifyPosInput = document.getElementById('opt-notifyPosition');
    if (notifyPosInput) notifyPosInput.value = s.notifyPosition || 'top-center';
    const weaponsHideInput = document.getElementById('opt-weaponsHideWhenUnarmed');
    if (weaponsHideInput) weaponsHideInput.checked = !!s.weaponsHideWhenUnarmed;

    SPEEDO_TOGGLE_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (input) input.checked = !!s[key];
    });
}

function openSettingsMenu(settings, open) {
    const overlay = document.getElementById('d87-menu-overlay');
    if (!open) {
        overlay.style.display = 'none';
        return;
    }
    if (!menuInitialized) initMenuStaticText();

    snapshotSettings = Object.assign({}, currentSettings, settings);
    workingSettings = Object.assign({}, snapshotSettings);
    populateMenuInputs(workingSettings);
    overlay.style.display = 'flex';
}

function closeSettingsMenu(save) {
    const overlay = document.getElementById('d87-menu-overlay');
    if (save) {
        postNUI('saveSettings', workingSettings);
        currentSettings = Object.assign({}, workingSettings);
    } else {
        applySettings(snapshotSettings);
        applySpeedoSettings(snapshotSettings);
        postNUI('closeMenu', {});
    }
    overlay.style.display = 'none';
}

/* ============================================================================
   🔔 NOTIFICACIONES
============================================================================ */
window.addEventListener('message', function(event) {
    let data = event.data;
    if (data.action !== "notify") return;
    createNotification(data);
});

function createNotification(data) {
    const container = document.getElementById('d87-notify-container');

    container.className = data.position || 'top-center';

    if (container.children.length >= (data.maxNotifications || 5)) {
        container.removeChild(container.firstChild);
    }

    const notifyBox = document.createElement('div');
    notifyBox.className = 'notify-box';
    notifyBox.style.borderLeft = `3px solid ${data.color}`;

    notifyBox.innerHTML = `
        <div class="notify-icon">${data.icon || '💡'}</div>
        <div class="notify-content">
            <div class="notify-title" style="color: ${data.color}">${data.title}</div>
            <div class="notify-message">${data.message}</div>
        </div>
        <div class="progress-bar-bg">
            <div class="progress-bar-fill" style="background-color: ${data.color}; width: 100%;"></div>
        </div>
    `;

    if (data.position === 'top-center') {
        container.insertBefore(notifyBox, container.firstChild);
    } else {
        container.appendChild(notifyBox);
    }

    const progressBarFill = notifyBox.querySelector('.progress-bar-fill');
    const duration = data.duration || 5000;
    const intervalTime = 10;
    let timeLeft = duration;

    const progressInterval = setInterval(() => {
        timeLeft -= intervalTime;
        let percentage = (timeLeft / duration) * 100;

        if (percentage <= 0) {
            percentage = 0;
            clearInterval(progressInterval);
        }

        progressBarFill.style.width = `${percentage}%`;
    }, intervalTime);

    setTimeout(() => {
        clearInterval(progressInterval);
        notifyBox.style.animation = 'fadeOut 0.4s forwards';
        setTimeout(() => {
            if (notifyBox.parentNode === container) {
                container.removeChild(notifyBox);
            }
        }, 400);
    }, duration);
}

/* ============================================================================
   ⚔️ HUD DE ARMAS
============================================================================ */
let lastClipValue = -1;
const weaponsEls = {};

window.addEventListener('DOMContentLoaded', function () {
    weaponsEls.crosshair = document.getElementById('d87-crosshair');
    weaponsEls.crosshairDot = document.querySelector('.crosshair-dot');
    weaponsEls.container = document.getElementById('d87-weapon');
    weaponsEls.weaponName = document.getElementById('weapon-name');
    weaponsEls.clip = document.getElementById('ammo-clip');
    weaponsEls.reserve = document.getElementById('ammo-reserve');
    weaponsEls.divider = document.querySelector('.ammo-divider');
    weaponsEls.ammoContainer = document.querySelector('.ammo-container');
    weaponsEls.durabilityBar = document.getElementById('durability-bar');
});

window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.action) {
        case 'weapons_show':
            weaponsHandleShow(data);
            break;
        case 'weapons_hide':
            weaponsHandleHide();
            break;
        case 'weapons_toggle_crosshair':
            weaponsHandleToggleCrosshair(data);
            break;
        case 'weapons_update':
            weaponsHandleUpdate(data);
            break;
    }
});

function weaponsHandleShow(data) {
    weaponsEls.container.style.display = 'flex';

    if (data.bottom) weaponsEls.container.style.bottom = `${data.bottom}px`;

    const scale = data.size ? data.size : 1.0;
    weaponsEls.container.style.transform = `translateX(-50%) scale(${scale})`;
    lastClipValue = -1;
}

function weaponsHandleHide() {
    weaponsEls.container.style.display = 'none';
    weaponsEls.crosshair.style.display = 'none';
    lastClipValue = -1;
}

function weaponsHandleToggleCrosshair(data) {
    weaponsEls.crosshair.style.display = data.status ? 'flex' : 'none';
}

function weaponsHandleUpdate(data) {
    if (data.weapon) {
        weaponsEls.weaponName.innerText = data.weapon;
    }

    if (data.isSpecial) {
        weaponsEls.ammoContainer.style.display = 'none';
        if (weaponsEls.crosshairDot) weaponsEls.crosshairDot.classList.remove('crosshair-critical');
    } else {
        weaponsEls.ammoContainer.style.display = 'flex';

        if (data.reloading) {
            weaponsUpdateReloadingState();
            if (weaponsEls.crosshairDot) weaponsEls.crosshairDot.classList.add('crosshair-critical');
        } else {
            weaponsUpdateAmmoState(data);
        }
    }

    weaponsUpdateDurability(data.durability);
}

function weaponsUpdateReloadingState() {
    weaponsEls.clip.innerText = "RECARGANDO...";
    weaponsEls.clip.className = "reloading-text blink-reload";
    weaponsEls.reserve.style.display = 'none';
    weaponsEls.divider.style.display = 'none';
}

function weaponsUpdateAmmoState(data) {
    weaponsEls.reserve.style.display = 'inline';
    weaponsEls.divider.style.display = 'inline';

    const clipStr = data.clip.toString().padStart(2, '0');
    const reserveStr = data.reserve.toString().padStart(3, '0');

    weaponsEls.clip.innerText = clipStr;
    weaponsEls.reserve.innerText = reserveStr;

    if (lastClipValue !== -1 && data.clip < lastClipValue) {
        weaponsEls.container.classList.remove('recoil-animation');
        void weaponsEls.container.offsetWidth;
        weaponsEls.container.classList.add('recoil-animation');
    }
    lastClipValue = data.clip;

    if (data.clip <= 5) {
        weaponsEls.clip.className = "ammo-critical";
        if (weaponsEls.crosshairDot) weaponsEls.crosshairDot.classList.add('crosshair-critical');
    } else {
        weaponsEls.clip.className = "";
        if (weaponsEls.crosshairDot) weaponsEls.crosshairDot.classList.remove('crosshair-critical');
    }
}

function weaponsUpdateDurability(durability) {
    if (!weaponsEls.durabilityBar || durability === undefined) return;

    weaponsEls.durabilityBar.style.width = durability + "%";

    if (durability > 60) {
        weaponsEls.durabilityBar.style.backgroundColor = "#4ade80";
        weaponsEls.durabilityBar.classList.remove('blink-critical');
    } else if (durability > 25) {
        weaponsEls.durabilityBar.style.backgroundColor = "#facc15";
        weaponsEls.durabilityBar.classList.remove('blink-critical');
    } else {
        weaponsEls.durabilityBar.style.backgroundColor = "#ef4444";
        weaponsEls.durabilityBar.classList.add('blink-critical');
    }
}

/* ============================================================================
   🏎️ VELOCÍMETRO / INSTRUMENTACIÓN VEHICULAR
============================================================================ */
let speedoFuelLimit = 20;
let speedoEngineLimit = 30;
let speedoStoredVehicleName = "Cargando...";

// Aplica en vivo escala/márgenes/visibilidad/umbrales sin esperar a un nuevo "speedo_show"
function applySpeedoSettings(s) {
    if (!s) return;
    const container = document.getElementById('d87-speedo');
    if (!container) return;

    if (s.speedoSize) container.style.transform = `scale(${s.speedoSize})`;
    if (s.speedoBottomMargin !== undefined) container.style.bottom = `${s.speedoBottomMargin}px`;
    if (s.speedoRightMargin !== undefined) container.style.right = `${s.speedoRightMargin}px`;

    if (s.speedoFuelAlertPercent !== undefined) speedoFuelLimit = s.speedoFuelAlertPercent;
    if (s.speedoEngineAlertPercent !== undefined) speedoEngineLimit = s.speedoEngineAlertPercent;

    const vehicleContainer = document.getElementById('vehicle-container');
    const rpmBar = document.querySelector('.rpm-heavy-bar');
    const fuelBlock = document.getElementById('fuel-status-block');
    const engineBlock = document.getElementById('engine-status-block');
    const gearContainer = document.querySelector('.gear-container');

    if (vehicleContainer) vehicleContainer.style.display = s.speedoShowVehicleName ? 'flex' : 'none';
    if (rpmBar) rpmBar.style.display = s.speedoShowRpmBar ? 'flex' : 'none';
    if (fuelBlock) fuelBlock.style.display = s.speedoShowFuelBar ? 'flex' : 'none';
    if (engineBlock) engineBlock.style.display = s.speedoShowEngineBar ? 'flex' : 'none';
    if (gearContainer) gearContainer.style.display = s.speedoShowGearBox ? 'flex' : 'none';
}

window.addEventListener('message', function (event) {
    let data = event.data;

    if (data.action === "speedo_show") {
        let container = document.getElementById('d87-speedo');
        container.style.display = 'flex';

        if (data.size) container.style.transform = `scale(${data.size})`;
        if (data.bottom) container.style.bottom = `${data.bottom}px`;
        if (data.right) container.style.right = `${data.right}px`;

        if (data.fuelLimit !== undefined) speedoFuelLimit = data.fuelLimit;
        if (data.engineLimit !== undefined) speedoEngineLimit = data.engineLimit;

        document.getElementById('vehicle-container').style.display = data.showName ? 'flex' : 'none';
        document.querySelector('.rpm-heavy-bar').style.display = data.showRpm ? 'flex' : 'none';
        document.getElementById('fuel-status-block').style.display = data.showFuel ? 'flex' : 'none';
        document.getElementById('engine-status-block').style.display = data.showEngine ? 'flex' : 'none';
        document.querySelector('.gear-container').style.display = data.showGear ? 'flex' : 'none';

        if (data.vehicleName) {
            speedoStoredVehicleName = data.vehicleName;
            document.getElementById('vehicle-name').innerText = speedoStoredVehicleName;
        }

        let sbIcon = document.getElementById('icon-seatbelt');
        sbIcon.style.display = data.hideSeatbelt ? 'none' : 'inline-block';
    }

    else if (data.action === "speedo_configure") {
        applySpeedoSettings({
            speedoSize: data.size,
            speedoBottomMargin: data.bottom,
            speedoRightMargin: data.right,
            speedoShowVehicleName: data.showName,
            speedoShowRpmBar: data.showRpm,
            speedoShowFuelBar: data.showFuel,
            speedoShowEngineBar: data.showEngine,
            speedoShowGearBox: data.showGear,
            speedoFuelAlertPercent: data.fuelLimit,
            speedoEngineAlertPercent: data.engineLimit
        });
    }

    else if (data.action === "speedo_hide") {
        document.getElementById('d87-speedo').style.display = 'none';
    }

    else if (data.action === "speedo_seatbelt") {
        let sbIcon = document.getElementById('icon-seatbelt');
        if (data.status) {
            sbIcon.innerText = "⧮";
            sbIcon.className = "mid-icon text-on";
        } else {
            sbIcon.innerText = "⧯";
            sbIcon.className = "mid-icon text-off blink-active";
        }
    }

    else if (data.action === "speedo_cruise") {
        let cruiseIcon = document.getElementById('icon-cruise');
        cruiseIcon.className = data.status ? "mid-icon text-cruise-active" : "mid-icon text-off-neutral";
    }

    else if (data.action === "speedo_update") {
        let speedEl = document.getElementById('speed');
        speedEl.innerText = data.speed.toString().padStart(3, '0');
        speedEl.classList.toggle('speed-active', data.speed > 0);

        let sbIcon = document.getElementById('icon-seatbelt');
        if (data.vehType === "plane" || data.vehType === "heli" || data.vehType === "boat" || data.vehType === "bike") {
            document.querySelector('.gear-container').style.opacity = (data.vehType === "bike") ? '1' : '0';
            sbIcon.style.display = 'none';
        } else {
            document.querySelector('.gear-container').style.opacity = '1';
            sbIcon.style.display = 'inline-block';
        }

        if (data.odo !== undefined) {
            document.getElementById('odo-value').innerText = data.odo.toString().padStart(6, '0');
        }
        if (data.unit) {
            document.querySelector('.unit').innerText = data.unit;
            document.querySelector('.odo-unit').innerText = data.unit.split('/')[0];
        }

        document.getElementById('gear').innerText = data.gear;

        let adjustedRpm = data.rpm;
        if (data.rpm > 0 && data.rpm <= 25) {
            adjustedRpm = 10;
        } else if (data.rpm === 0) {
            adjustedRpm = 0;
        }

        for (let i = 1; i <= 20; i++) {
            let block = document.getElementById('rpm-' + i);
            if (block) {
                if (adjustedRpm > 0 && adjustedRpm >= (i * 5)) {
                    block.className = (i <= 10) ? "rpm-block rpm-low" : (i <= 16) ? "rpm-block rpm-medium" : "rpm-block rpm-high";
                } else {
                    block.className = "rpm-block";
                }
            }
        }

        let lockIcon = document.getElementById('icon-lock');
        if (data.locked) {
            lockIcon.innerText = "🔒";
            lockIcon.className = "mid-icon text-off";
        } else {
            lockIcon.innerText = "🔓";
            lockIcon.className = "mid-icon text-on blink-active";
        }

        let lIcon = document.getElementById('icon-lights');
        if (data.lights === "high") {
            lIcon.className = "mid-icon text-highbeams";
        } else if (data.lights === "normal") {
            lIcon.className = "mid-icon text-on";
        } else {
            lIcon.className = "mid-icon text-off-neutral";
        }

        let nameEl = document.getElementById('vehicle-name');
        if (data.radar) {
            nameEl.innerText = `RADAR: MAX ${data.radarSpeed}`;
            nameEl.className = "text-radar-alert blink-active";
        } else {
            nameEl.innerText = speedoStoredVehicleName;
            nameEl.className = "";
        }

        for (let i = 1; i <= 6; i++) {
            let bar = document.getElementById('fb-' + i);
            if (bar) {
                bar.classList.toggle('f-bar-active', data.fuel >= (i * 16.6) - 5);
            }
        }

        let fuelContainer = document.getElementById('fb-6')?.parentElement;
        if (fuelContainer) {
            fuelContainer.classList.toggle('blink-active', data.fuel <= speedoFuelLimit);
        }

        for (let i = 1; i <= 6; i++) {
            let bar = document.getElementById('eb-' + i);
            if (bar) {
                bar.className = "eng-bar";
                if (data.engine >= (i * 16.6) - 5) {
                    if (data.engine > 60) {
                        bar.classList.add('eng-bar-active-green');
                    } else if (data.engine > 30) {
                        bar.classList.add('eng-bar-active-yellow');
                    } else {
                        bar.classList.add('eng-bar-active-red');
                    }
                }
            }
        }

        let engineContainer = document.getElementById('eb-6')?.parentElement;
        if (engineContainer) {
            engineContainer.classList.toggle('blink-active', data.engine <= speedoEngineLimit);
        }
    }
});
