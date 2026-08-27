local M = {}
local dlstatus = require('moonloader').download_status

-- Ссылка через jsDelivr CDN (работает стабильно со встроенным загрузчиком MoonLoader)
local UPDATE_MANIFEST_URL = 'https://cdn.jsdelivr.net/gh/deveeh1337/oshelper@master/update.json'

local CHECK_FILE = getWorkingDirectory() .. '\\OSHelper-update.json'
local UPDATE_ROOT = getWorkingDirectory()

local function log(message)
    print('[OS Helper] ' .. tostring(message))
end

local function downloadSync(url, path)
    local finished = false

    downloadUrlToFile(url, path, function(_, status)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD or status == dlstatus.STATUS_ENDDOWNLOADDATA then
            finished = true
        end
    end)

    local timeout = 5000
    while not finished and timeout > 0 do
        wait(50)
        timeout = timeout - 50
    end

    if doesFileExist(path) then
        local file = io.open(path, 'r')
        if file then
            local size = file:seek('end')
            file:close()
            return size > 0
        end
    end

    return false
end

local function readJson(path)
    local file = io.open(path, 'r')
    if not file then return nil end

    local content = file:read('*a')
    file:close()

    local ok, result = pcall(decodeJson, content)
    if ok and type(result) == 'table' then
        return result
    end

    return nil
end

local function normalizeRemotePath(path)
    path = tostring(path or ''):gsub('\\', '/')
    path = path:gsub('^/+', '')

    if path == '' or path == '.' or path == '..' or path:find('%.%.', 1, true) then
        return nil
    end

    if path == 'OSHelper/config.json' then
        return nil
    end

    return path
end

local function getLocalPath(remotePath)
    return UPDATE_ROOT .. '\\' .. remotePath:gsub('/', '\\')
end

local function ensureParentDirectory(path)
    local parent = path:match('^(.*)[\\/][^\\/]+$')
    if parent and not doesDirectoryExist(parent) then
        createDirectory(parent)
    end
end

local function parseVersion(versionStr)
    local major, minor, patch = tostring(versionStr or ''):match('(%d+)%.(%d+)%.(%d+)')
    if major then
        return tonumber(major), tonumber(minor), tonumber(patch)
    end
    major, minor = tostring(versionStr or ''):match('(%d+)%.(%d+)')
    if major then
        return tonumber(major), tonumber(minor), 0
    end
    return 0, 0, 0
end

local function versionToNumber(major, minor, patch)
    return (major or 0) * 10000 + (minor or 0) * 100 + (patch or 0)
end

local function currentVersionCode()
    local script = thisScript()
    local code = tonumber(script and script.version_code)
    if code then return code end

    local version = tostring(script and script.version or '1.0 release')
    local major, minor, patch = parseVersion(version)
    return versionToNumber(major, minor, patch)
end

local function applyManifest(manifest)
    local filesList = manifest.files
    if type(filesList) ~= 'table' or #filesList == 0 then
        return false, 'Список файлов пуст'
    end

    local baseUrl = tostring(manifest.base_url or ''):gsub('/+$', '')
    if baseUrl == '' then
        return false, 'base_url отсутствует'
    end

    for _, rawPath in ipairs(filesList) do
        local path = normalizeRemotePath(rawPath)
        if path then
            local url = baseUrl .. '/' .. path:gsub('\\', '/')
            local destination = getLocalPath(path)

            ensureParentDirectory(destination)
            log('Загрузка: ' .. path)

            if not downloadSync(url, destination) then
                return false, 'Ошибка скачивания: ' .. path
            end
        end
    end

    return true
end

function M.check()
    log('=== Запуск проверки обновлений ===')

    if doesFileExist(CHECK_FILE) then
        os.remove(CHECK_FILE)
    end

    if not downloadSync(UPDATE_MANIFEST_URL, CHECK_FILE) then
        log('ОШИБКА: Не удалось скачать update.json')
        if doesFileExist(CHECK_FILE) then os.remove(CHECK_FILE) end
        return false
    end

    local manifest = readJson(CHECK_FILE)
    os.remove(CHECK_FILE)

    if not manifest or type(manifest) ~= 'table' then
        log('ОШИБКА: Ошибка чтения JSON')
        return false
    end

    local remoteVersionStr = tostring(manifest.latest or '')
    if remoteVersionStr == '' then
        return false
    end

    local rMajor, rMinor, rPatch = parseVersion(remoteVersionStr)
    local remoteCode = versionToNumber(rMajor, rMinor, rPatch)
    local localCode = currentVersionCode()

    log(('Версии: Локальная (%d) | На сервере (%d)'):format(localCode, remoteCode))

    if remoteCode == 0 or remoteCode <= localCode then
        log('У вас установлена актуальная версия.')
        return false
    end

    log('Найдено новое обновление: ' .. remoteVersionStr)

    local ok, err = applyManifest(manifest)
    if not ok then
        log('ОШИБКА при автообновлении: ' .. tostring(err))
        return false
    end

    log('Успешно обновлено до версии ' .. remoteVersionStr .. '! Перезагрузка...')

    lua_thread.create(function()
        wait(1000)
        thisScript():reload()
    end)

    return true
end

return M