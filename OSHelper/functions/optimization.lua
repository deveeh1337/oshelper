-- GameFixer integration for OS Helper.
-- Only the features explicitly kept by the user are present here.
-- Removed from this module: shadow editor/shadows, radar, HUD/chat/HP/nicks,
-- memory cleaner button, map zoom, SA-MP key blocker, plane line, big HP bar,
-- radio/sounds/interior music/audio stream, taxi light, radar color,
-- interior run, crosshair fix, water fix, black roads, long arm, FPS unlock,
-- dust.

local M = {}
local memory = require 'memory'

local SECTION_ANIM = {}
local function sectionAlpha(id, enabled)
    local now = os.clock()
    local a = SECTION_ANIM[id] or {value = 0, last = now}
    local dt = math.min(now - a.last, 0.05)
    a.last = now
    local target = enabled and 1 or 0
    a.value = a.value + (target - a.value) * math.min(1, dt * 12)
    SECTION_ANIM[id] = a
    if a.value <= 0.01 then return false, 0 end
    return true, a.value
end

local function animatedContentBegin(id, enabled, fullHeight)
    -- Consume the ToggleButton progress from the same frame. This keeps
    -- the button's content (bind button, inputs, combos and text) perfectly
    -- synchronized with the switch animation.
    local toggleAnim = UI_LAST_TOGGLE_ANIM
    UI_LAST_TOGGLE_ANIM = nil
    local visible, alpha
    if toggleAnim then
        alpha = toggleAnim.alpha
        visible = alpha > 0.01
    else
        visible, alpha = sectionAlpha(id, enabled)
    end
    alpha = alpha * (mainWindowFade and mainWindowFade.alpha or 1.0)
    if not visible or alpha <= 0.01 then return false end
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
    return true
end

local function animatedContentEnd(active, fullHeight)
    if active then imgui.PopStyleVar() end
end

local RIGHT_CONTROL_GAP = 5
local function getRightControlX(width)
    width = width or RIGHT_CONTROL_WIDTH

    -- ImGui's content region already knows whether a vertical scrollbar
    -- is present. Do not subtract ScrollbarSize manually.
    if imgui.GetWindowContentRegionMax then
        local regionMax = imgui.GetWindowContentRegionMax()
        local right = regionMax.x - RIGHT_CONTROL_GAP - width
        return math.max(0, right)
    end

    -- Safe fallback for older mimgui builds.
    local style = imgui.GetStyle()
    local winWidth = imgui.GetWindowWidth()
    local pad = style.WindowPadding and style.WindowPadding.x or 8
    return math.max(pad, winWidth - pad - RIGHT_CONTROL_GAP - width)
end

local function alignRightControl(width)
    imgui.SetCursorPosX(getRightControlX(width))
end

local function rightControlBegin(width)
    width = width or RIGHT_CONTROL_WIDTH
    alignRightControl(width)
    if imgui.SetNextItemWidth then imgui.SetNextItemWidth(width) end
    imgui.PushItemWidth(width)
end
local function rightControlEnd()
    imgui.PopItemWidth()
end

local function safe(name, fn)
    local ok, err = pcall(fn)
    if not ok and UI_DEBUG then
        uiDebug('GAMEFIXER_ERROR', name, tostring(err))
    end
    return ok
end

function M.apply(feature)
    return safe(feature, function()
        if feature == 'NoBirds' then
            if cfg.gamefixer.nobirds then
                memory.write(5497200, 232, 1, false)
                memory.write(5497201, 1918619, 4, false)
            else
                memory.fill(5497200, 144, 5, false)
            end

        elseif feature == 'NoCloudBig' then
            if cfg.gamefixer.nocloudbig then
                memory.write(5497268, 495044584, 4, false)
                memory.write(5497272, 0, 1, false)
            else
                memory.write(5497268, -1869574000, 4, false)
                memory.write(5497272, 144, 1, false)
            end

        elseif feature == 'NoCloudSmall' then
            if cfg.gamefixer.nocloudsmall then
                memory.write(5497121, 494111464, 4, false)
                memory.write(5497125, 0, 1, false)
            else
                memory.fill(5497121, 144, 5, false)
            end

        elseif feature == 'VehLods' then
            memory.write(5425646, cfg.gamefixer.vehlods and 1 or 0, 1, false)

        elseif feature == 'NoPostfx' then
            if cfg.gamefixer.postfx then
                memory.write(7358318, 1448280247, 4, false)
                memory.write(7358314, -988281383, 4, false)
            else
                memory.write(7358318, 2866, 4, false)
                memory.write(7358314, -380152237, 4, false)
            end

        elseif feature == 'NoEffects' then
            if cfg.gamefixer.effects then
                memory.write(4891712, 1443425411, 4, false)
            else
                memory.write(4891712, 8386, 4, false)
            end

        elseif feature == 'FixSensitivity' then
            if cfg.gamefixer.sensfix then
                memory.write(5382798, 11987996, 4, false)
                memory.write(5311528, 11987996, 4, false)
                memory.write(5316106, 11987996, 4, false)
            else
                memory.write(5382798, 11987992, 4, false)
                memory.write(5311528, 11987992, 4, false)
                memory.write(5316106, 11987992, 4, false)
            end
        elseif feature == 'SunFix' then
            if cfg.gamefixer.sunfix then
                memory.hex2bin('E865041C00', 0x53C136, 5)
            else
                memory.fill(0x53C136, 0x90, 5, true)
            end

        elseif feature == 'TargetBlip' then
            memory.write(5497324, cfg.gamefixer.targetblip and 116 or 235, 1, false)

        elseif feature == 'FPSLimit' then
            memory.write(12216212, cfg.gamefixer.fpslimit_enabled and 1 or 0, 1, true)

        elseif feature == 'ForceAniso' then
            local desired = cfg.gamefixer.forceaniso and 0 or 1
            if readMemory(0x730F9C, 1, false) ~= desired then
                memory.write(0x730F9C, desired, 1, false)
                loadScene(1337, 1337, 1337)
                callFunction(0x40D7C0, 1, 1, -1)
            end

        elseif feature == 'AntiCrasher' then
            if sampGetVersion() == '0.3.7-R1' then
                local base = sampGetBase()
                if cfg.gamefixer.anticrasher then
                    memory.write(base + 0x5CF2C, 0x90909090, 4, true)
                    memory.write(base + 0x5CF2C + 4, 0x90, 1, true)
                    memory.write(base + 0x5CF2C + 4 + 9, 0x90909090, 4, true)
                    memory.write(base + 0x5CF2C + 4 + 9 + 4, 0x90, 1, true)
                else
                    memory.write(base + 0x5CF2C, 7729128, 4, true)
                    memory.write(base + 0x5CF2C + 4, 0, 1, true)
                    memory.write(base + 0x5CF2C + 4 + 9, 2097870979, 4, true)
                    memory.write(base + 0x5CF2C + 4 + 9 + 4, 14, 1, true)
                end
            end
        end
    end)
end

function M.update()
    -- No per-frame optimization feature remains.
end

function M.applyAll()
    M.apply('NoBirds')
    M.apply('NoCloudBig')
    M.apply('NoCloudSmall')
    M.apply('VehLods')
    M.apply('NoPostfx')
    M.apply('NoEffects')
    M.apply('FixSensitivity')
    M.apply('SunFix')
    M.apply('TargetBlip')
    M.apply('FPSLimit')
    M.apply('ForceAniso')
    M.apply('AntiCrasher')
end

local FEATURES = {
    NoBirds = { key = 'nobirds', text = u8'Птицы', tip = u8'Отображение птиц.' },
    NoCloudBig = { key = 'nocloudbig', text = u8'Высокие облака', tip = u8'Отображение высоких облаков.' },
    NoCloudSmall = { key = 'nocloudsmall', text = u8'Низкие облака', tip = u8'Отображение низких облаков.' },
    VehLods = { key = 'vehlods', text = u8'Оптимизация моделей транспорта', tip = u8'Изменяет обработку моделей транспорта.' },
    NoPostfx = { key = 'postfx', text = u8'Пост-эффекты', tip = u8'Убирает часть пост-эффектов GTA.' },
    NoEffects = { key = 'effects', text = u8'Визуальные эффекты', tip = u8'Убирает часть визуальных эффектов GTA.' },
    FixSensitivity = { key = 'sensfix', text = u8'Исправление чувствительности', tip = u8'Исправляет обработку чувствительности мыши по осям X и Y во время стрельбы.' },
    SunFix = { key = 'sunfix', text = u8'Солнце', tip = u8'Отображение солнца.' },
    TargetBlip = { key = 'targetblip', text = u8'Маркер цели', tip = u8'Отображение маркера цели.' },
    FPSLimit = { key = 'fpslimit_enabled', text = u8'Ограничитель FPS', tip = u8'Ограничивает частоту кадров через команду /fpslimit.' },
    ForceAniso = { key = 'forceaniso', text = u8'Анизотропная фильтрация', tip = u8'Принудительно включает анизотропную фильтрацию текстур.' },
    AntiCrasher = { key = 'anticrasher', text = u8'Антикрашер SA-MP', tip = u8'Защищает от известного крашера SA-MP 0.3.7-R1.' },
}


local function applyBool(key, value, feature)
    cfg.gamefixer[key] = value and true or false
    Config.save(cfg)
    M.apply(feature)
end

function M.setBool(key, value)
    local feature
    for name, item in pairs(FEATURES) do
        if item.key == key then feature = name break end
    end
    if feature then applyBool(key, value, feature) end
end

function M.drawUI()
    -- NoBirds
    do
        local item = FEATURES.NoBirds
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'NoBirds')
        end
    end

    -- NoCloudBig
    do
        local item = FEATURES.NoCloudBig
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'NoCloudBig')
        end
    end

    -- NoCloudSmall
    do
        local item = FEATURES.NoCloudSmall
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'NoCloudSmall')
        end
    end

    -- VehLods
    do
        local item = FEATURES.VehLods
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'VehLods')
        end
    end

    -- NoPostfx
    do
        local item = FEATURES.NoPostfx
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'NoPostfx')
        end
    end

    -- NoEffects
    do
        local item = FEATURES.NoEffects
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'NoEffects')
        end
    end

    -- FixSensitivity
    do
        local item = FEATURES.FixSensitivity
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'FixSensitivity')
        end
    end

    -- SunFix
    do
        local item = FEATURES.SunFix
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'SunFix')
        end
    end

    -- TargetBlip
    do
        local item = FEATURES.TargetBlip
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'TargetBlip')
        end
    end

    -- FPSLimit
    do
        local item = FEATURES.FPSLimit
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'FPSLimit')
        end
        -- FPS Limiter (анимированный блок)
        local __fpsLimiterAnim = animatedContentBegin('fpsLimiter', checkboxes.gf_fpslimit_enabled[0], 58)
        if __fpsLimiterAnim then
            imgui.Text(u8'Частота кадров в секунду:') imgui.SameLine()
            rightControlBegin(93.5)
            if imgui.InputInt('##fpslimit', sliders.fpslimit, 1, 1) then
                if sliders.fpslimit[0] < 20 then
                    sliders.fpslimit[0] = 20
                end
                if sliders.fpslimit[0] > 999 then
                    sliders.fpslimit[0] = 999
                end
                cfg.gamefixer.fpslimit = sliders.fpslimit[0]
                sampProcessChatInput('/fpslimit ' .. tostring(sliders.fpslimit[0]))
                Config.save(cfg)
            end
            rightControlEnd()
            animatedContentEnd(__fpsLimiterAnim, 58)
        end
    end

    -- ForceAniso
    do
        local item = FEATURES.ForceAniso
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'ForceAniso')
        end
    end

    -- AntiCrasher
    do
        local item = FEATURES.AntiCrasher
        local box = checkboxes['gf_' .. item.key]
        if box and uiToggle(item.text, box, item.tip) then
            applyBool(item.key, box[0], 'AntiCrasher')
        end
    end
end

return M
