function bindModifierDown(bind, vk)
    return bind and bind[vk] and isKeyDown(bind[vk])
end

function customBindPressed(bind)
    if not bind or not bind.key or bind.key == 0 then return false end
    if bind.alt and not isKeyDown(0x12) then return false end
    if bind.ctrl and not (isKeyDown(0xA2) or isKeyDown(0xA3)) then return false end
    if bind.shift and not (isKeyDown(0xA0) or isKeyDown(0xA1)) then return false end
    return wasKeyPressed(bind.key)
end

function customBindDown(bind)
    if not bind or not bind.key or bind.key == 0 then return false end
    if bind.alt and not isKeyDown(0x12) then return false end
    if bind.ctrl and not (isKeyDown(0xA2) or isKeyDown(0xA3)) then return false end
    if bind.shift and not (isKeyDown(0xA0) or isKeyDown(0xA1)) then return false end
    return isKeyDown(bind.key)
end

function getBindLabel(bind)
    if not bind or not bind.key or bind.key == 0 then return 'Не назначено' end
    local parts = {}
    if bind.ctrl then parts[#parts + 1] = 'CTRL' end
    if bind.alt then parts[#parts + 1] = 'ALT' end
    if bind.shift then parts[#parts + 1] = 'SHIFT' end

    local names = {
        [0x04] = 'MOUSE4', [0x05] = 'MOUSE5', [0x06] = 'MOUSE5',
        [0x08] = 'BACKSPACE', [0x10] = 'SHIFT', [0x11] = 'CTRL', [0x12] = 'ALT', [0xA0] = 'SHIFT', [0xA1] = 'SHIFT', [0x09] = 'TAB', [0x0D] = 'ENTER', [0x1B] = 'ESC',
        [0x20] = 'SPACE', [0x21] = 'PAGEUP', [0x22] = 'PAGEDOWN', [0x23] = 'END', [0x24] = 'HOME',
        [0x25] = 'LEFT', [0x26] = 'UP', [0x27] = 'RIGHT', [0x28] = 'DOWN',
        [0x2D] = 'INSERT', [0x2E] = 'DELETE',
    }
    local keyName = names[bind.key]
    if not keyName then
        if bind.key >= 0x30 and bind.key <= 0x39 then
            keyName = string.char(bind.key)
        elseif bind.key >= 0x41 and bind.key <= 0x5A then
            keyName = string.char(bind.key)
        elseif bind.key >= 0x60 and bind.key <= 0x69 then
            keyName = 'NUM' .. tostring(bind.key - 0x60)
        elseif bind.key >= 0x70 and bind.key <= 0x87 then
            keyName = 'F' .. tostring(bind.key - 0x6F)
        else
            local buf = ffi.new('char[64]')
            local scanCode = bit.lshift(bind.key, 16)
            local len = ffi.C.GetKeyNameTextA(scanCode, buf, 64)
            if len and len > 0 then keyName = ffi.string(buf, len) end
        end
    end
    parts[#parts + 1] = keyName or ('VK_' .. tostring(bind.key))
    return table.concat(parts, ' + ')
end

function tryCaptureBind(name)
    if bindCapture.name ~= name then return false end
    if os.clock() - bindCapture.started < 0.15 then return false end

    -- ESC cancels capture and must never become the new bind.
    if wasKeyPressed(0x1B) then
        bindCapture.name = nil
        return true
    end

    -- Allow a modifier key itself (plain Shift) to be used as the bind.
    if wasKeyPressed(0xA0) then
        cfg.binds[name] = {key = 0xA0, ctrl = false, alt = false, shift = false}
        bindCapture.name = nil
        save()
        return true
    elseif wasKeyPressed(0xA1) then
        cfg.binds[name] = {key = 0xA1, ctrl = false, alt = false, shift = false}
        bindCapture.name = nil
        save()
        return true
    end

    local modifiers = {
        ctrl = isKeyDown(0xA2) or isKeyDown(0xA3),
        alt = isKeyDown(0x12),
        shift = isKeyDown(0xA0) or isKeyDown(0xA1),
    }
    for vkCode = 1, 0xA5 do
        if vkCode ~= 0x10 and vkCode ~= 0x11 and vkCode ~= 0x12 and vkCode ~= 0xA0 and vkCode ~= 0xA1 and vkCode ~= 0xA2 and vkCode ~= 0xA3 and vkCode ~= 0xA4 and vkCode ~= 0xA5 and wasKeyPressed(vkCode) then
            cfg.binds[name] = {key = vkCode, ctrl = modifiers.ctrl, alt = modifiers.alt, shift = modifiers.shift}
            bindCapture.name = nil
            save()
            return true
        end
    end
    return false
end

function processCustomBinds()
    if bindCapture.name then
        tryCaptureBind(bindCapture.name)
        if bindCapture.name then return end
    end
    if frames.window[0] or frames.colors[0] or frames.cwindow[0] or frames.kbset[0] then return end
    if sampIsChatInputActive() or sampIsDialogActive() or isSampfuncsConsoleActive() then return end

    if checkboxes.mask[0] and customBindPressed(cfg.binds.mask) then send('/mask') end
    if checkboxes.spawn[0] and customBindPressed(cfg.binds.spawn) and not isCharOnFoot(playerPed) then
        local car = storeCarCharIsInNoSave(playerPed)
        local _, carid = sampGetVehicleIdByCarHandle(car)
        if carid then send('/fixmycar '..carid) end
    end
    if checkboxes.med[0] and customBindPressed(cfg.binds.med) then send('/usemed') end
    if checkboxes.eat[0] and customBindPressed(cfg.binds.eat) then send('/eat') end
    if checkboxes.armor[0] and customBindPressed(cfg.binds.armor) then
        local armourlvl = sampGetPlayerArmor(id)
        local lockArmor = tonumber(cfg.settings.bindArmorLimit) or 90
        if armourlvl >= lockArmor then
            msg('У вас '..armourlvl..' процентов брони.')
        elseif armourlvl > 0 then
            lua_thread.create(function() send('/armour'); wait(500); send('/armour') end)
        else
            send('/armour')
        end
    end
    if checkboxes.drugs[0] and customBindPressed(cfg.binds.drugs) then send('/usedrugs 3') end
    if checkboxes.rem[0] and customBindPressed(cfg.binds.rem) then send('/repcar') end
    if checkboxes.fill[0] and customBindPressed(cfg.binds.fill) then send('/fillcar') end
    if checkboxes.jack[0] and customBindPressed(cfg.binds.jack) then send('/jack') end
    if checkboxes.lock[0] and customBindPressed(cfg.binds.lock) then send('/lock') end
    if checkboxes.lock[0] and customBindPressed(cfg.binds.jlock) then send('/jlock') end
end
