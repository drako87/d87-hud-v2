fx_version 'cerulean'
game 'gta5'

author 'Drako87/Dracatt'
description 'D87 HUD - Sistema modular unificado (Constantes, Notificaciones, HUD de Armas y Velocímetro Vehicular)'
version '2.1.0'

-- ox_lib: callback de munición de reserva (HUD de armas) y versionCheck (GitHub)
shared_script '@ox_lib/init.lua'

shared_scripts {
    'locales/*.lua',
    'config/config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/ui.css',
    'html/ui.js',
    'html/img/logo.png'
}

exports {
    'SendAlert'
}
