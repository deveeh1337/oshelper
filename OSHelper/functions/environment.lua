-- Time / weather service.
-- No SA-MP machine-code patching: correct the actual game state only when needed.

local lastEnabled = false

local function setServerTimeRPC(hour)
    hour = math.max(0, math.min(23, tonumber(hour) or 0))
    local ok = pcall(function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, hour)
        raknetEmulRpcReceiveBitStream(29, bs)
        raknetDeleteBitStream(bs)
    end)
    return ok
end

function patch_samp_time_set(enable)
    -- Compatibility shim for the old UI. The new implementation does not
    -- patch SA-MP memory; the scheduler corrects the actual clock state.
    lastEnabled = enable and true or false
    if not enable then
        lastEnabled = false
    end
end

function weatherLoop()
    if weatherLoopRunning then return end
    weatherLoopRunning = true

    while true do
        if sampGetGamestate() == 3 and checkboxes.timeweather[0] then
            -- Keep selected time stable without writing executable memory.
            local currentTime = tonumber(readMemory(0xB70153, 1, true)) or -1
            local targetTime = tonumber(ints.time[0]) or 0
            if currentTime ~= targetTime then
                setServerTimeRPC(targetTime)
            end

            -- Weather is corrected only when the actual game value differs.
            local currentWeather = tonumber(readMemory(0xC81320, 2, true)) or -1
            local targetWeather = tonumber(ints.weather[0]) or 0
            if currentWeather ~= targetWeather then
                pcall(forceWeatherNow, targetWeather)
            end
            lastEnabled = true
        elseif lastEnabled then
            lastEnabled = false
        end

        wait(0)
    end
end

function applyTimeWeatherNow()
    if not checkboxes.timeweather[0] then return end
    local targetTime = tonumber(ints.time[0]) or 0
    local targetWeather = tonumber(ints.weather[0]) or 0
    if (tonumber(readMemory(0xB70153,1,true)) or -1) ~= targetTime then
        setServerTimeRPC(targetTime)
    end
    if (tonumber(readMemory(0xC81320,2,true)) or -1) ~= targetWeather then
        pcall(forceWeatherNow, targetWeather)
    end
end




local memory = require 'memory'

local sampev = require 'lib.samp.events'

local ffi = require 'ffi'

local DistanceManager = {}

-- Сохраняем исходную структуру настроек менеджера дистанций.
-- Старые значения из cfg.distance подхватываются автоматически.
if type(cfg.distanceManager) ~= 'table' then
    local old = type(cfg.distance) == 'table' and cfg.distance or {}
    cfg.distanceManager = {
        enabled = true,
        nametags = tonumber(old.nametags) or 8,
        tdtext = tonumber(old.tdtext) or 30,
        chatbubbles = tonumber(old.chatbubbles) or 30,
        lods = tonumber(old.lods) or 352,
    }
    Config.save(cfg)
end

local dm = cfg.distanceManager
dm.enabled = dm.enabled ~= false
dm.nametags = math.max(0, math.min(30, tonumber(dm.nametags) or 8))
dm.tdtext = math.max(0, math.min(30, tonumber(dm.tdtext) or 30))
dm.chatbubbles = math.max(0, math.min(30, tonumber(dm.chatbubbles) or 30))
dm.lods = math.max(0, math.min(300, tonumber(dm.lods) or 150))

local ptr = nil
local lods_ptr = ffi.cast('float *', 0x00858FD8)
local NAMETAG_MAX = 30
local sn = new.int(dm.nametags)
local st = new.int(dm.tdtext)
local sb = new.int(dm.chatbubbles)
local sl = new.int(dm.lods)

local function syncPtr()
    if sampGetGamestate() ~= 3 then return end
    local ok, p = pcall(sampGetServerSettingsPtr)
    if ok and p then ptr = p + 39 end
end

function DistanceManager.init()
    if dm.enabled then DistanceManager.update() end
end

function DistanceManager.setEnabled(value)
    dm.enabled = value and true or false
    if dm.enabled then DistanceManager.update() end
    Config.save(cfg)
end

function DistanceManager.set(k, v)
    v = tonumber(v)
    if not v then return false end
    if k == 'nametags' then
        v = math.max(0, math.min(v, NAMETAG_MAX))
        dm.nametags = v
        syncPtr()
        if ptr and dm.enabled then pcall(memory.setfloat, ptr, v) end
    elseif k == 'tdtext' then
        v = math.max(0, math.min(v, 30))
        dm.tdtext = v
        if dm.enabled then
            for i = 0, 2048 do
                if sampIs3dTextDefined(i) then
                    local text, col, x, y, z, dist, los, plid, vehid = sampGet3dTextInfoById(i)
                    pcall(sampCreate3dTextEx, i, text, col, x, y, z, v, los, plid, vehid)
                end
            end
        end
    elseif k == 'chatbubbles' then
        dm.chatbubbles = math.max(0, math.min(v, 30))
    elseif k == 'lods' then
        dm.lods = math.max(0, math.min(v, 300))
        if dm.enabled then pcall(function() lods_ptr[0] = dm.lods end) end
    else
        return false
    end
    Config.save(cfg)
    return true
end

function DistanceManager.update()
    if not dm.enabled then return end
    syncPtr()
    if ptr then
        pcall(memory.setfloat, ptr, math.max(0, math.min(tonumber(dm.nametags) or 8, NAMETAG_MAX)))
    end
    pcall(function()
        local current = tonumber(lods_ptr[0])
        if current ~= tonumber(dm.lods) then lods_ptr[0] = math.max(0, math.min(tonumber(dm.lods) or 150, 300)) end
    end)
end

function DistanceManager.onCreate3DText(id, col, pos, allowed_dist, los, plid, vehid, text)
    if not dm.enabled then return nil end
    local d = tonumber(dm.tdtext) or 30
    if d < allowed_dist then return {id, col, pos, d, los, plid, vehid, text} end
end

function DistanceManager.onPlayerChatBubble(id, col, allowed_dist, dur, text)
    if not dm.enabled then return nil end
    local d = tonumber(dm.chatbubbles) or 30
    if d < allowed_dist then return {id, col, d, dur, text} end
end

_G.DistanceManager = DistanceManager
local old3d = sampev.onCreate3DText
local oldbubble = sampev.onPlayerChatBubble
sampev.onCreate3DText = function(...) return DistanceManager.onCreate3DText(...) or (old3d and old3d(...)) end
sampev.onPlayerChatBubble = function(...) return DistanceManager.onPlayerChatBubble(...) or (oldbubble and oldbubble(...)) end
return {DistanceManager = DistanceManager}
