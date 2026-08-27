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
