function drawBindButton(name, label)
    local bind = cfg.binds[name]
    local displayText
    if bindCapture.name == name then
        displayText = u8'\xcd\xe0\xe6\xec\xe8\xf2\xe5 \xf1\xee\xf7\xe5\xf2\xe0\xed\xe8\xe5...'
    else
        -- label is already UTF-8 (passed through u8() from the UI),
        -- while getBindLabel returns UTF-8 for localized text.
        displayText = label .. ': ' .. getBindLabel(bind)
    end
    local avail = imgui.GetContentRegionAvail and imgui.GetContentRegionAvail().x or (imgui.GetWindowWidth() - imgui.GetCursorPosX())
    local buttonWidth = math.max(1, avail - 5)
    local clicked = imgui.Button(displayText, imgui.ImVec2(buttonWidth, 22))
    if clicked then bindCapture.name = name; bindCapture.started = os.clock() end
    if bindCapture.name == name then
        imgui.TextDisabled(u8'\xcd\xe0\xe6\xec\xe8\xf2\xe5 \xed\xf3\xe6\xed\xf3\xfe \xea\xeb\xe0\xe2\xe8\xf8\xf3 \xe8\xeb\xe8 \xf1\xee\xf7\xe5\xf2\xe0\xed\xe8\xe5.\nESC \x97 \xee\xf2\xec\xe5\xed\xe0.')
        if wasKeyPressed(0x1B) then bindCapture.name = nil end
    end
    return clicked
end

-- main

uiToggle = function(label, bool, question)
    return imgui.ToggleButton(label, bool, imgui.ImVec2(40, 20), question)
end

function imgui.ToggleButton(name, bool, size, question)
    local function bringFloatTo(from, to, start_time, duration)
        local timer = os.clock() - start_time
        if timer >= 0.00 and timer <= duration then
            local count = timer / (duration / 100)
            return from + (count * (to - from) / 100), true
        end
        return (timer > duration) and to or from, false
    end

    local rounding = 1
    size = size or imgui.ImVec2(60, 25)
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local cursor = imgui.GetCursorPos()
    local fade = (imgui.GetStyle().Alpha or 1.0)

    if UI_CUSTOM_TOGGLEBUTTON == nil then UI_CUSTOM_TOGGLEBUTTON = {} end
    if UI_CUSTOM_TOGGLEBUTTON[name] == nil then
        UI_CUSTOM_TOGGLEBUTTON[name] = {
            argument = bool[0],
            bool = false,
            alignment = {bool[0] and size.x / 1.5 - 5 or 0, true},
            clock = 0
        }
    end

    local state = UI_CUSTOM_TOGGLEBUTTON[name]
    if state.argument ~= bool[0] then
        state.argument = bool[0]
        state.bool = true
        state.clock = os.clock()
    end

    local base_col4 = bool[0]
        and imgui.GetStyle().Colors[imgui.Col.CheckMark]
        or imgui.GetStyle().Colors[imgui.Col.TextDisabled]

    local color_u32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
        base_col4.x, base_col4.y, base_col4.z, base_col4.w * fade
    ))

    -- Full row is clickable; the visual toggle itself is aligned to the far right.
    local hit = imgui.InvisibleButton('##toggle_' .. name, imgui.ImVec2(math.max(size.x, imgui.GetContentRegionAvail().x), size.y))
    local changed = false
    if hit then
        state.bool = true
        state.clock = os.clock()
        bool[0] = not bool[0]
        state.argument = bool[0]
        changed = true
    end

    if imgui.IsItemHovered() then
        local hover_col4 = imgui.GetStyle().Colors[imgui.Col.CheckMark]
        color_u32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
            hover_col4.x, hover_col4.y, hover_col4.z, hover_col4.w * fade
        ))
    end
    if imgui.IsItemActive() then
        local active_col4 = imgui.GetStyle().Colors[imgui.Col.CheckMark]
        color_u32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(
            active_col4.x, active_col4.y, active_col4.z, active_col4.w * fade
        ))
    end

    if state.bool then
        state.alignment = {
            bringFloatTo(
                (bool[0] and 0 or size.x / 1.5 - 5),
                (bool[0] and size.x / 1.5 - 5 or 0),
                state.clock,
                0.2
            )
        }
        if state.alignment[2] == false then
            state.bool = false
        end
    else
        state.alignment = {bool[0] and size.x / 1.5 - 5 or 0, true}
    end

    local style = imgui.GetStyle()
    local winPos = imgui.GetWindowPos()
    local rightEdge
    if imgui.GetWindowContentRegionMax then
        rightEdge = winPos.x + imgui.GetWindowContentRegionMax().x
    else
        rightEdge = winPos.x + imgui.GetWindowWidth() - (style.WindowPadding.x or 8)
    end
    local toggleX = rightEdge - (RIGHT_CONTROL_GAP or 5) - size.x
    local togglePos = imgui.ImVec2(toggleX, p.y)
    local textSize = imgui.CalcTextSize(name)
    local labelPos = imgui.ImVec2(p.x, p.y + (size.y - textSize.y) * 0.5)

    dl:AddText(labelPos, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.95, 0.96, 0.98, fade)), name)

    if question and question ~= '' then
        local qSize = 16
        local qx = labelPos.x + textSize.x + 7
        local qy = p.y + (size.y - qSize) * 0.5
        local q1 = imgui.ImVec2(qx, qy)
        local q2 = imgui.ImVec2(qx + qSize, qy + qSize)
        local qBase = imgui.GetStyle().Colors[imgui.Col.TextDisabled]
        local qCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(qBase.x, qBase.y, qBase.z, qBase.w * fade))
        dl:AddText(q1, qCol, '(?)')
        if imgui.IsMouseHoveringRect(q1, q2, true) then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(500)
            imgui.TextUnformatted(question)
            imgui.PopTextWrapPos()
            imgui.EndTooltip()
        end
    end

    dl:AddRect(
        togglePos,
        imgui.ImVec2(togglePos.x + size.x, togglePos.y + size.y),
        color_u32,
        rounding,
        nil,
        2
    )
    dl:AddRectFilled(
        imgui.ImVec2(togglePos.x + 5 + state.alignment[1], togglePos.y + 5),
        imgui.ImVec2(togglePos.x + size.x - size.x / 1.5 + state.alignment[1], togglePos.y + size.y - 5),
        color_u32,
        rounding
    )


    imgui.SetCursorPos(imgui.ImVec2(cursor.x, cursor.y + size.y + 7))
    return changed
end

function autoSave()
	while true do 
		wait(60000) --                   60       
		Config.save(cfg)
	end
end

-- theme
local THEME_ACCENTS = {
    [0] = {1.00, 0.28, 0.28}, [1] = {0.00, 0.74, 0.35}, [2] = {0.00, 0.48, 0.75},
    [3] = {0.00, 0.75, 0.57}, [4] = {0.76, 0.45, 0.00}, [5] = {0.36, 0.00, 0.75},
    [6] = {0.55, 0.75, 0.00}, [7] = {0.75, 0.00, 0.45}, [8] = {0.46, 0.36, 0.27}, [9] = {0.37, 0.37, 0.37},
}

local function clamp01(v) return math.max(0.0, math.min(1.0, v)) end

function themeSettings(theme)
    local style, c, clr = imgui.GetStyle(), imgui.GetStyle().Colors, imgui.Col
    local a = THEME_ACCENTS[theme] or {colortheme[0], colortheme[1], colortheme[2]}
    local h = {clamp01(a[1]+0.18), clamp01(a[2]+0.18), clamp01(a[3]+0.18)}
    local ac = {clamp01(a[1]*0.80), clamp01(a[2]*0.80), clamp01(a[3]*0.80)}
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 3.5
    style.FramePadding, style.FrameRounding = imgui.ImVec2(7, 5), 1.5
    style.ItemSpacing, style.ItemInnerSpacing = imgui.ImVec2(7, 6), imgui.ImVec2(5, 5)
    style.IndentSpacing, style.ScrollbarSize, style.ScrollbarRounding = 21, 10, 13
    style.GrabMinSize, style.GrabRounding = 8, 4
    style.WindowTitleAlign, style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5), imgui.ImVec2(0.5, 0.5)
    c[clr.Text] = imgui.ImVec4(0.95,0.96,0.98,1); c[clr.TextDisabled] = imgui.ImVec4(0.50,0.50,0.52,0.8)
    c[clr.WindowBg] = imgui.ImVec4(0.055,0.065,0.08,0.98); c[clr.ChildBg] = imgui.ImVec4(0.075,0.085,0.10,0.5)
    c[clr.PopupBg] = imgui.ImVec4(0.045,0.05,0.065,0.98); c[clr.Border] = imgui.ImVec4(0.18,0.20,0.24,0); c[clr.BorderShadow] = imgui.ImVec4(0,0,0,0)
    c[clr.FrameBg] = imgui.ImVec4(0.12,0.13,0.16,1); c[clr.FrameBgHovered] = imgui.ImVec4(0.16,0.18,0.22,1); c[clr.FrameBgActive] = imgui.ImVec4(0.19,0.21,0.26,1)
    c[clr.TitleBg] = imgui.ImVec4(0.055,0.065,0.08,1); c[clr.TitleBgActive] = imgui.ImVec4(0.065,0.075,0.09,1); c[clr.TitleBgCollapsed] = imgui.ImVec4(0.03,0.035,0.04,0.9)
    c[clr.MenuBarBg] = imgui.ImVec4(0.06,0.07,0.085,1); c[clr.ScrollbarBg] = imgui.ImVec4(0.03,0.035,0.045,0.7)
    c[clr.ScrollbarGrab] = imgui.ImVec4(0.26,0.28,0.33,1); c[clr.ScrollbarGrabHovered] = imgui.ImVec4(0.34,0.36,0.42,1); c[clr.ScrollbarGrabActive] = imgui.ImVec4(0.40,0.42,0.48,1)
    c[clr.CheckMark] = imgui.ImVec4(a[1],a[2],a[3],0.8); c[clr.SliderGrab] = imgui.ImVec4(a[1],a[2],a[3],1); c[clr.SliderGrabActive] = imgui.ImVec4(ac[1],ac[2],ac[3],1)
    c[clr.Button] = imgui.ImVec4(a[1],a[2],a[3],1); c[clr.ButtonHovered] = imgui.ImVec4(h[1],h[2],h[3],1); c[clr.ButtonActive] = imgui.ImVec4(ac[1],ac[2],ac[3],1)
    c[clr.Header] = imgui.ImVec4(a[1],a[2],a[3],1); c[clr.HeaderHovered] = imgui.ImVec4(h[1],h[2],h[3],1); c[clr.HeaderActive] = imgui.ImVec4(ac[1],ac[2],ac[3],1)
    c[clr.ResizeGrip] = imgui.ImVec4(a[1],a[2],a[3],1); c[clr.ResizeGripHovered] = imgui.ImVec4(h[1],h[2],h[3],1); c[clr.ResizeGripActive] = imgui.ImVec4(ac[1],ac[2],ac[3],1)
    c[clr.PlotLines] = imgui.ImVec4(0.61,0.61,0.61,1); c[clr.PlotLinesHovered] = imgui.ImVec4(h[1],h[2],h[3],1)
    c[clr.PlotHistogram] = imgui.ImVec4(ac[1],ac[2],ac[3],1); c[clr.PlotHistogramHovered] = imgui.ImVec4(h[1],h[2],h[3],1)
    c[clr.TextSelectedBg] = imgui.ImVec4(a[1],a[2],a[3],0.35)
end

function set_player_skin(id, skin)
	local BS = raknetNewBitStream()
	raknetBitStreamWriteInt32(BS, id)
	raknetBitStreamWriteInt32(BS, skin)
	raknetEmulRpcReceiveBitStream(153, BS)
	raknetDeleteBitStream(BS)
end