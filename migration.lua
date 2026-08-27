script_name('OS Helper Migration')
script_version('2.0.0')
script_author('OS Production')

require 'lib.moonloader'

local dlstatus = require('moonloader').download_status

local BASE_URL = 'https://raw.githubusercontent.com/deveeh1337/oshelper/master/'
local INSTALL_ROOT = getWorkingDirectory()

-- Файлы новой версии OS Helper 2.0.
-- config.json специально НЕ скачивается и НЕ заменяется.
local FILES = {
    'OSHelper.lua',

    'OSHelper/core/bootstrap.lua',
    'OSHelper/core/config.lua',
    'OSHelper/core/context.lua',
    'OSHelper/core/main.lua',

    'OSHelper/features/events.lua',

    'OSHelper/functions/environment.lua',
    'OSHelper/functions/optimization.lua',

    'OSHelper/services/input.lua',
    'OSHelper/services/session.lua',
    'OSHelper/services/time_weather.lua',
    'OSHelper/services/vehicle.lua',
    'OSHelper/services/updater.lua',

    'OSHelper/ui/main.lua',
    'OSHelper/ui/widgets.lua'
}

local function msg(text)
    print('[OS Helper] ' .. tostring(text))
end

local function getDirectory(path)
    return path:match('^(.*)[/\\]')
end

local function ensureDirectory(path)
    if path == nil or path == '' then
        return true
    end

    if doesDirectoryExist(path) then
        return true
    end

    local parent = getDirectory(path)

    if parent and parent ~= path then
        ensureDirectory(parent)
    end

    return os.execute('mkdir "' .. path .. '" >nul 2>&1')
end

local function downloadFile(url, path)
    local done = false
    local success = false
    local errorText = nil

    msg('Скачивание: ' .. url)

    local result = downloadUrlToFile(url, path, function(id, status, p1, p2)
        if status == dlstatus.STATUS_DOWNLOADINGDATA then
            -- Ничего не делаем, просто ждём.
        elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
            success = true
            done = true
        elseif status == dlstatus.STATUSEX_ENDDOWNLOAD then
            -- Некоторые версии MoonLoader используют расширенный callback.
            success = true
            done = true
        else
            -- Не считаем промежуточные состояния ошибкой.
        end
    end)

    -- Если downloadUrlToFile сразу вернул false/nil.
    if result == false then
        return false, 'downloadUrlToFile вернул false'
    end

    while not done do
        wait(50)
    end

    if success and doesFileExist(path) then
        return true
    end

    errorText = 'Файл не был скачан: ' .. path
    return false, errorText
end

local function install()
    msg('Начинаю переход на OS Helper 2.0 release.')

    -- На всякий случай создаём основную папку.
    ensureDirectory(INSTALL_ROOT .. '\\OSHelper')

    for _, relativePath in ipairs(FILES) do
        local localPath = INSTALL_ROOT .. '\\' .. relativePath
        local directory = getDirectory(localPath)
        local remoteUrl = BASE_URL .. relativePath:gsub('\\', '/')

        if directory then
            ensureDirectory(directory)
        end

        local ok, err = downloadFile(remoteUrl, localPath)

        if not ok then
            msg('ОШИБКА: ' .. tostring(err))
            return false
        end

        msg('Установлен: ' .. relativePath)
    end

    msg('Все файлы OS Helper 2.0 успешно установлены.')
    return true
end

local function waitAndStartNewScript()
    lua_thread.create(function()
        wait(1500)

        local oldScriptPath = thisScript().path
        local newScriptPath = INSTALL_ROOT .. '\\OSHelper.lua'

        msg('Завершение старого скрипта...')

        -- Пытаемся выгрузить старый migration/oshelper.lua.
        pcall(function()
            thisScript():unload()
        end)

        wait(500)

        -- В некоторых сборках MoonLoader есть script.load.
        if type(script) == 'table' and type(script.load) == 'function' then
            local ok, result = pcall(function()
                return script.load(newScriptPath)
            end)

            if ok and result then
                msg('OS Helper 2.0 запущен.')
                return
            end
        end

        -- Если script.load недоступен, новый OSHelper.lua уже установлен.
        -- Старый файл останется только до следующего перезапуска MoonLoader.
        msg('OS Helper 2.0 установлен. Перезапусти MoonLoader.')
    end)
end

function main()
    while not isSampAvailable() do
        wait(100)
    end

    wait(1000)

    msg('Запущен мигратор 1.x -> 2.0 release.')

    local ok = install()

    if not ok then
        msg('Миграция НЕ завершена.')
        msg('Проверь подключение к интернету и доступность GitHub.')
        return
    end

    waitAndStartNewScript()

    while true do
        wait(1000)
    end
end