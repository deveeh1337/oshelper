-- JSON configuration service for OS Helper.
local M = {}

local DEFAULT_CFG_PLACEHOLDER = true

local function deepCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k,v in pairs(t) do out[k] = deepCopy(v) end
    return out
end

local function mergeDefaults(target, defaults)
    for k,v in pairs(defaults) do
        if target[k] == nil then
            target[k] = deepCopy(v)
        elseif type(v) == 'table' and type(target[k]) == 'table' then
            mergeDefaults(target[k], v)
        end
    end
    return target
end

local ROOT = getWorkingDirectory() .. '\\OSHelper'
local PATH = ROOT .. '\\config.json'

function M.path()
    return PATH
end

function M.load(defaults)
    if not doesDirectoryExist(ROOT) then
        createDirectory(ROOT)
    end

    local data = nil
    local f = io.open(PATH, 'r')
    if f then
        local raw = f:read('*a')
        f:close()
        if raw and raw ~= '' then
            local ok, decoded = pcall(decodeJson, raw)
            if ok and type(decoded) == 'table' then data = decoded end
        end
    end

    -- One-time migration from the old OSHelper.ini, if present.
    if type(data) ~= 'table' then
        local ok, inicfg = pcall(require, 'inicfg')
        if ok and inicfg then
            local oldOk, oldCfg = pcall(inicfg.load, defaults, 'OSHelper')
            if oldOk and type(oldCfg) == 'table' then
                data = oldCfg
            end
        end
    end

    data = mergeDefaults(type(data) == 'table' and data or {}, defaults)
    M.save(data)
    return data
end

function M.save(data)
    if not doesDirectoryExist(ROOT) then
        createDirectory(ROOT)
    end
    local encoded = encodeJson(data)
    if not encoded then return false end
    local f = io.open(PATH, 'w')
    if not f then return false end
    f:write(encoded)
    f:close()
    return true
end

return M
