fx_version 'cerulean'
game 'gta5'

author 'Drako87/Dracatt'
description 'D87 HUD v2- Sistema modular unificado (Constantes, Notificaciones y HUD de Armas)'
version '2.0.0'

-- ox_lib es necesario para el callback framework-agnóstico de munición de reserva del HUD de armas
shared_script '@ox_lib/init.lua'

ui_page 'html/ui.html'

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

files {
    'html/ui.html',
    'html/ui.css',
    'html/ui.js',
    'html/img/logo.png'
}

exports {
    'SendAlert'
}
