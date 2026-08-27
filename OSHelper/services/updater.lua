-- OS Helper 2.0 release - GitHub auto-updater
-- Обновляет множество файлов и папок по списку в update.json.
-- Формат update.json:
-- {
--   "latest": "1.5.4 release",
--   "updateurl": "https://raw.githubusercontent.com/deveeh1337/oshelper/master/oshelper.lua",
--   "base_url": "https://raw.githubusercontent.com/deveeh1337/oshelper/master",
--   "files": [
--     "OSHelper.lua",
--     "OSHelper/core/main.lua",
--     "OSHelper/services/input.lua",
--     ...
--   ]
-- }
-- Конфиг пользователя (OSHelper/config.json) никогда не перезаписывается.

local M = {}
local dlstatus = require('moonloader').download_status

-- Ссылка на raw update.json на GitHub
local UPDATE_MANIFEST_URL = 'https://raw.githubusercontent.com/deveeh1337/oshelper/master/update.json'

local CHECK_FILE = getWorkingDirectory() .. '\\OSHelper-update.json'
local UPDATE_ROOT = getWorkingDirectory()

local function log(message)
    if type(msg) == 'function' then
        pcall(msg, '[OS Helper] ' .. tostring(message))
    end
end

local function downloadSync(url, path)
    local finished = false
    local success = false

    downloadUrlToFile(url, path, function(_, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            success = true
            finished = true
        elseif status == dlstatus.STATUSEX_ENDDOWNLOAD then
            finished = true
        end
    end)

    local timeout = 30000
    while not finished and timeout > 0 do
        wait(50)
        timeout = timeout - 50
    end

    return success and doesFileExist(path)
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

    if path == '' or path == '.' or path == '..' then
        return nil
    end

    -- Защита от путей с ".."
    if path:find('%.%.', 1, true) then
        return nil
    end

    -- Никогда не перезаписываем конфиг пользователя
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

    local version = tostring(script and script.version or '2.0 release')
    local major, minor, patch = parseVersion(version)
    return versionToNumber(major, minor, patch)
end

local function applyManifest(manifest)
    local filesList = manifest.files
    if type(filesList) ~= 'table' or #filesList == 0 then
        return false, 'files list is missing or empty'
    end

    local baseUrl = tostring(manifest.base_url or ''):gsub('/+$', '')
    if baseUrl == '' then
        return false, 'base_url is missing'
    end

    local normalizedFiles = {}

    for _, rawPath in ipairs(filesList) do
        local path = normalizeRemotePath(rawPath)
        if path then
            normalizedFiles[#normalizedFiles + 1] = path
        end
    end

    if #normalizedFiles == 0 then
        return false, 'no valid files to update'
    end

    for _, path in ipairs(normalizedFiles) do
        local url = baseUrl .. '/' .. path:gsub('\\', '/')
        local destination = getLocalPath(path)

        ensureParentDirectory(destination)

        if not downloadSync(url, destination) then
            return false, 'download failed: ' .. path
        end
    end

    return true
end

function M.check()
    if UPDATE_MANIFEST_URL:find('deveeh1337', 1, true)
        or UPDATE_MANIFEST_URL:find('YOUR_REPOSITORY', 1, true) then
        return false
    end

    if doesFileExist(CHECK_FILE) then
        os.remove(CHECK_FILE)
    end

    if not downloadSync(UPDATE_MANIFEST_URL, CHECK_FILE) then
        if doesFileExist(CHECK_FILE) then os.remove(CHECK_FILE) end
        return false
    end

    local manifest = readJson(CHECK_FILE)
    os.remove(CHECK_FILE)

    if not manifest or type(manifest) ~= 'table' then
        return false
    end

    local remoteVersionStr = tostring(manifest.latest or '')
    if remoteVersionStr == '' then
        return false
    end

    local rMajor, rMinor, rPatch = parseVersion(remoteVersionStr)
    local remoteCode = versionToNumber(rMajor, rMinor, rPatch)
    local localCode = currentVersionCode()

    if remoteCode == 0 or remoteCode <= localCode then
        return false
    end

    -- updateurl можно игнорировать, если есть files, но оставим для совместимости
    local updateUrl = tostring(manifest.updateurl or '')

    log('Доступна новая версия: ' .. remoteVersionStr)

    local ok, err = applyManifest(manifest)
    if not ok then
        log('Ошибка автообновления: ' .. tostring(err))
        return false
    end

    log('OS Helper обновлён до версии ' .. remoteVersionStr)

    lua_thread.create(function()
        wait(700)
        thisScript():reload()
    end)

    return true
end

return M