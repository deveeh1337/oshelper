script_name('OS Helper')
script_version('2.0 release')
script_author('OS Production')

require 'lib.moonloader'

local updater = require('OSHelper.services.updater')
updater.check()

local requiredLibs = {
    {name = 'Mimgui', module = 'mimgui'},
    {name = 'SAMP Events', module = 'lib.samp.events'},
    {name = 'fAwesome6', module = 'fAwesome6'},
    {name = 'vkeys', module = 'vkeys'},
    {name = 'windows.message', module = 'windows.message'},
    {name = 'FFI', module = 'ffi'},
    {name = 'Memory', module = 'memory'},
    {name = 'Encoding', module = 'encoding'},
}

local missingLibs = {}
for _, item in ipairs(requiredLibs) do
    local ok = pcall(require, item.module)
    if not ok then missingLibs[#missingLibs + 1] = item.name end
end

local dependenciesReady = (#missingLibs == 0)

if dependenciesReady then
    require 'OSHelper.core.context'
    require 'OSHelper.services.input'
    require 'OSHelper.services.vehicle'
    require 'OSHelper.services.time_weather'
    require 'OSHelper.services.session'
    require 'OSHelper.ui.main'
    require 'OSHelper.ui.widgets'
    require 'OSHelper.features.events'
    require 'OSHelper.core.main'
end

local Bootstrap = dependenciesReady and require 'OSHelper.core.bootstrap' or nil

function main()
    while not isSampAvailable() do wait(100) end
    if not dependenciesReady then
        local lines = {}
        for _, name in ipairs(missingLibs) do lines[#lines + 1] = '{DFDDDE}>> {DC4747}' .. name end
        local text = '{DFDDDE}OS Helper не может запуститьс€, потому что\n' ..
                     '{DFDDDE}не найдены необходимые зависимости:\n\n' ..
                     table.concat(lines, '\n') ..
                     '\n\n{DFDDDE}”становите недостающие библиотеки и перезапустите игру.'
        sampShowDialog(1488, '{006EAD}OS Helper', text, '«акрыть', '', 0)
        thisScript():unload()
        return
    end
    Bootstrap.start()
end
