local Optimization = require 'OSHelper.functions.optimization'
local function applyCurrentTheme()
    if type(themeSettings) ~= 'function' then return end
    if themeDirty or currentTheme ~= cfg.settings.theme then
        themeSettings(cfg.settings.theme)
        currentTheme = cfg.settings.theme
        themeDirty = false
        if cfg.settings.theme == 0 then color = '{ff4747}'
        elseif cfg.settings.theme == 1 then color = '{00bd5c}'
        elseif cfg.settings.theme == 2 then color = '{007ABE}'
        elseif cfg.settings.theme == 3 then color = '{00C091}'
        elseif cfg.settings.theme == 4 then color = '{C27300}'
        elseif cfg.settings.theme == 5 then color = '{5D00C0}'
        elseif cfg.settings.theme == 6 then color = '{8CBF00}'
        elseif cfg.settings.theme == 7 then color = '{BF0072}'
        elseif cfg.settings.theme == 8 then color = '{755B46}'
        elseif cfg.settings.theme == 9 then color = '{5E5E5E}'
        else
            local rgb = join_rgba(colortheme[1] * 255, colortheme[2] * 255, colortheme[3] * 255, 0)
            color = '{'..('%06X'):format(rgb)..'}'
        end
        cfg.settings.color = color
        cfg.settings.xcolor = color:gsub('{',''):gsub('}','')
    end
end

function imgui.CustomMenu(labels, selected, size, speed, centering, icons)
    local changed = false
    speed = speed or 0.50
    size = size or imgui.ImVec2(165, 34)
    local draw = imgui.GetWindowDrawList()
    if LastActiveTime == nil then LastActiveTime = {} end
    if LastActive == nil then LastActive = {} end

    local function saturate(v)
        if v < 0 then return 0 end
        if v > 1 then return 1 end
        return v
    end

    for i, label in ipairs(labels) do
        local c = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
        local id = '##custom_menu_' .. tostring(i)

        if imgui.InvisibleButton(id, size) then
            selected[0] = i
            LastActiveTime[id] = os.clock()
            LastActive[id] = true
            changed = true
        end

        local p_min = imgui.GetItemRectMin()
        local p_max = imgui.GetItemRectMax()
        local real_size = imgui.ImVec2(p_max.x - p_min.x, p_max.y - p_min.y)

        local selectedNow = selected[0] == i
        local t = selectedNow and 1.0 or 0.0
        if LastActive[id] then
            local elapsed = os.clock() - (LastActiveTime[id] or os.clock())
            if elapsed <= 0.30 then
                local a = saturate(elapsed / speed)
                t = selectedNow and a or 1.0 - a
            else
                LastActive[id] = false
            end
        end

        local accent = imgui.GetStyle().Colors[imgui.Col.CheckMark]
        local textCol = imgui.GetStyle().Colors[imgui.Col.Text]
        local transparent = imgui.ImVec4(0, 0, 0, 0)

        local hoverAlpha = imgui.IsItemHovered() and 0.25 or 0.0
        draw:AddRectFilled(
            imgui.ImVec2(p_min.x - 5, p_min.y),
            p_max,
            imgui.GetColorU32Vec4(imgui.ImVec4(accent.x, accent.y, accent.z, hoverAlpha)),
            0.0 
        )

        if selectedNow then
            local grad_left = p_min.x - 5
            local grad_right = grad_left + real_size.x * (0.45 + 0.55 * t)

            local col_accent = imgui.GetColorU32Vec4(accent)
            local col_trans  = imgui.GetColorU32Vec4(transparent)

            draw:AddRectFilledMultiColor(
                imgui.ImVec2(grad_left, p_min.y),
                imgui.ImVec2(grad_right, p_max.y),
                col_accent,
                col_trans,   
                col_trans,   
                col_accent  
            )
        end

        local textX = c.x + (icons and 42 or 15)
        local textY = c.y + (size.y - imgui.CalcTextSize(label).y) * 0.5
        imgui.SetCursorPos(imgui.ImVec2(textX, textY))
        imgui.TextColored(textCol, label)

        if icons and icons[i] and fa_font then
            imgui.SetCursorPos(imgui.ImVec2(c.x + 14, c.y + (size.y - 16) * 0.5))
            imgui.PushFont(fa_font)
            imgui.Text(icons[i])
            imgui.PopFont()
        end
        imgui.SetCursorPos(imgui.ImVec2(c.x, c.y + size.y))
    end
    return changed
end

function imgui.SendResult(result,name,myfunc)
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link

    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()

    local resultBtn = imgui.InvisibleButton('##'..result..name, size)
    if resultBtn then
        if not myfunc then
            sampSetChatInputText(result)
        end
    end

    imgui.SetCursorPos(p2)

    local hover_col = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
    local normal_col = imgui.GetStyle().Colors[imgui.Col.Button]

    if imgui.IsItemHovered() then
        imgui.TextColored(hover_col, name)
        imgui.GetWindowDrawList():AddLine(
            imgui.ImVec2(p.x, p.y + size.y),
            imgui.ImVec2(p.x + size.x, p.y + size.y),
            imgui.ColorConvertFloat4ToU32(hover_col)
        )
    else
        imgui.TextColored(normal_col, name)
    end

    return resultBtn
end

local function drawCloseXButton(id, width, height)
    width = width or 30
    height = height or 24
    local p = imgui.GetCursorScreenPos()
    local clicked = imgui.InvisibleButton('##close_hit_' .. id, imgui.ImVec2(width, height))
    local draw = imgui.GetWindowDrawList()
    local hovered = imgui.IsItemHovered()
    local active = imgui.IsItemActive()
    local c = hovered and imgui.ImVec4(1.0, 0.4, 0.4, 1) or imgui.GetStyle().Colors[imgui.Col.Text]
    if active then c = imgui.ImVec4(1.0, 0.4, 0.4, 1) end

    -- The main window cross is drawn with DrawList, so ImGui's global alpha
    -- does not affect it automatically. Apply the same fade manually.
    local alpha = mainWindowFade and mainWindowFade.alpha or 1.0
    local fadeCol = imgui.ImVec4(c.x, c.y, c.z, c.w * alpha)
    local u = imgui.ColorConvertFloat4ToU32(fadeCol)
    local pad = 7
    draw:AddLine(imgui.ImVec2(p.x + pad, p.y + pad), imgui.ImVec2(p.x + width - pad, p.y + height - pad), u, 2.0)
    draw:AddLine(imgui.ImVec2(p.x + width - pad, p.y + pad), imgui.ImVec2(p.x + pad, p.y + height - pad), u, 2.0)
    return clicked
end

local RIGHT_CONTROL_WIDTH = 110
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
local function compactCombo(label, value, labels, count, width)
    width = width or RIGHT_CONTROL_WIDTH
    if value[0] < 0 or value[0] >= count then value[0] = 0 end

    rightControlBegin(width)
    local changed = false
    local preview = labels[value[0] + 1] or ''

    -- Use BeginCombo/Selectable instead of imgui.Combo so the third argument
    -- is never a Lua table passed through FFI. This is important for the
    -- Cyrillic active/theme labels on the user's mimgui build.
    if imgui.BeginCombo(label, preview) then
        for i = 0, count - 1 do
            local item = labels[i + 1] or ''
            local selected = value[0] == i
            if imgui.Selectable(item, selected) then
                if value[0] ~= i then
                    value[0] = i
                    changed = true
                    uiDebug('COMBO_CHANGE', label, 'index=', i, 'value=', item)
                end
            end
            if selected then
                imgui.SetItemDefaultFocus()
            end
        end
        imgui.EndCombo()
    end
    rightControlEnd()
    return changed
end

local function rightInputText(label, buffer, width, hint, flags)
    width = width or RIGHT_CONTROL_WIDTH
    rightControlBegin(width)
    local changed
    if hint ~= nil then
        if flags ~= nil then changed = imgui.InputTextWithHint(label, hint, buffer, ffi.sizeof(buffer), flags)
        else changed = imgui.InputTextWithHint(label, hint, buffer, ffi.sizeof(buffer)) end
    else
        if flags ~= nil then changed = imgui.InputText(label, buffer, ffi.sizeof(buffer), flags)
        else changed = imgui.InputText(label, buffer, ffi.sizeof(buffer)) end
    end
    rightControlEnd()
    return changed
end

local function checkboxWithQuestion(label, bool, question)
    local changed = imgui.Checkbox(label, bool)
    local minp = imgui.GetItemRectMin()
    local maxp = imgui.GetItemRectMax()
    local qSize = 16
    local qx = maxp.x + 7
    local qy = minp.y + (maxp.y - minp.y - qSize) * 0.5
    local draw = imgui.GetWindowDrawList()
    local base = imgui.GetStyle().Colors[imgui.Col.TextDisabled]
    local fade = mainWindowFade and mainWindowFade.alpha or 1.0
    local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(base.x, base.y, base.z, base.w * fade))
    local q1 = imgui.ImVec2(qx, qy)
    local q2 = imgui.ImVec2(qx + qSize, qy + qSize)
    draw:AddText(q1, col, '(?)')
    if imgui.IsMouseHoveringRect(q1, q2, true) then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(500)
        imgui.TextUnformatted(question or '')
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
    return changed
end

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


local function drawMainWindow()
    if mainWindowFade.alpha <= 0.01 then return end
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, mainWindowFade.alpha)
    local io = imgui.GetIO()
    imgui.SetNextWindowPos(imgui.ImVec2(io.DisplaySize.x / 2, io.DisplaySize.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(540, 420), imgui.Cond.FirstUseEver)
    imgui.Begin('##OSHelperMain', mainWindowOpen, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)

    imgui.BeginChild('##os_header', imgui.ImVec2(0, 48), true, imgui.WindowFlags.NoScrollbar)
        if logo ~= nil then imgui.Image(logo, imgui.ImVec2(30, 30)); imgui.SameLine() end
        imgui.SetCursorPosY(15)
        imgui.Text('OS Helper v'..thisScript().version)
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetWindowWidth() - 36)
        imgui.SetCursorPosY(10)
        if drawCloseXButton('main', 25, 25) then setMainWindowVisible(false) end
    imgui.EndChild()

    imgui.BeginChild('##os_left', imgui.ImVec2(195, 350), true)
        local labels = {}
        local icons = {}
        local selectedIndex = 1
        for i, item in ipairs(menuItems) do
            labels[i] = item.text
            icons[i] = item.icon
            if menu == item.id then selectedIndex = i end
        end
        local selectedMenu = new.int(selectedIndex)
        if imgui.CustomMenu(labels, selectedMenu, imgui.ImVec2(185, 32), 0.3, false, icons) then
            local picked = menuItems and menuItems[selectedMenu[0]]
            if picked then
                menu = picked.id
            end
        end
    imgui.SetCursorPosY(imgui.GetWindowHeight() - 39)
        if imgui.Button(u8'Сохранить', imgui.ImVec2(-1, 28)) then save(); msg('Все настройки сохранены.') end
    imgui.EndChild()
    imgui.SameLine()
    imgui.BeginChild('##os_right', imgui.ImVec2(0, 350), true)
			if menu == 1 then
				character()
			end
			if menu == 2 then
				transport()
			end
            if menu == 10 then
                Optimization.drawUI()
            end

			if menu == 4 then
				if uiToggle(u8'Chat Helper', checkboxes.chathelper, u8'Подсказки и вспомогательные инструменты для работы с чатом. Помогают быстрее выполнять доступные чат-команды и отображают полезную информацию о функциях чата.') then cfg.settings.chathelper = checkboxes.chathelper[0] end
				if uiToggle(u8'Chat Calculator', checkboxes.calcbox, u8'Калькулятор для быстрых вычислений прямо во время ввода сообщения. Поддерживает операции:\nСложение (+): 100+50 = 150\nВычитание (-): 100-50 = 50\nУмножение (*): 100*50 = 5000\nДеление (/): 100/50 = 2\nВозведение в степень (^): 10^2 = 100\nПрибавление процентов (+%): 500+20% = 600\nВычитание процентов (-%): 500-20% = 400\nУмножение с процентом (*%): 500*20% = 100\nДеление с процентом (/%): 500/20% = 2500\nСкобки: 5*(5+5) = 50\nКомбинация операций: 5+5*5 = 30\nПри нажатии на результат автоматически отправляет его в чат.') then cfg.settings.calcbox = checkboxes.calcbox[0] end
				if uiToggle(u8'Сокращенные команды', checkboxes.cmds, u8'Сокращает длинные игровые команды до коротких вариантов, позволяя быстрее вводить и использовать часто применяемые команды.\n\n/biz - /bizinfo\n/car [id] - /fixmycar\n/fh [id] - /findihouse\n/fbiz [id] - /findibiz\n/urc - /unrentcar\n/fin [id] [id biz] - /showbizinfo\n/ss - /setspawn\n/fgar [id] - /findigarage\n/fplot [id] - /findiplot') then cfg.settings.cmds = checkboxes.cmds[0] save() end
				if uiToggle(u8'Chat Editor', checkboxes.chateditor, u8'Настройка количества строк и размера шрифта игрового чата. Позволяет гибко изменить отображение чата под свои предпочтения, а внесённые изменения автоматически сохраняются в конфигурации.') then cfg.settings.chateditor = checkboxes.chateditor[0] end
				local __chatEditorAnim = animatedContentBegin('chatEditor', checkboxes.chateditor[0], 58)
				if __chatEditorAnim then 
					imgui.Text(u8'Количество строк в чате:') imgui.SameLine()
					rightControlBegin(110)
					if imgui.InputInt('##Chatstrings', ints.chatstrings, 1, 1) then 
						if ints.chatstrings[0] < 10 then ints.chatstrings[0] = 10 end
						if ints.chatstrings[0] > 20 then ints.chatstrings[0] = 20 end
						sampProcessChatInput('/pagesize '..ints.chatstrings[0])
						cfg.settings.chatstrings = ints.chatstrings[0] 
					end
					rightControlEnd()
					imgui.Text(u8'Размер шрифта в чате:') imgui.SameLine()
					rightControlBegin(110)
					if imgui.InputInt('##Chatfontsize', ints.chatfontsize, 1, 1) then 
						if ints.chatfontsize[0] < 0 then ints.chatfontsize[0] = 0 end
						if ints.chatfontsize[0] > 5 then ints.chatfontsize[0] = 5 end
						sampProcessChatInput('/fontsize '..ints.chatfontsize[0])
						cfg.settings.chatfontsize = ints.chatfontsize[0] 
					end
					rightControlEnd()
					animatedContentEnd(__chatEditorAnim, 58)
				end
			end
			if menu == 5 then
				if uiToggle(u8'Mining Helper', checkboxes.mininghelper, u8'Помощник для упрощения работы с майнингом криптовалют.') then cfg.settings.mininghelper = checkboxes.mininghelper[0] end
			end
			if menu == 6 then
				imgui.offset(u8'Активация меню: ') 
				if compactCombo('##Активация', ints.active, comboActiveLabels, 2) then cfg.settings.active = ints.active[0] save() end
				if imgui.IsItemHovered() then
					imgui.BeginTooltip()
						imgui.Text(u8'После изменения режима активации, сохраните скрипт.')
					imgui.EndTooltip()
				end
				local __cheatAnim = animatedContentBegin('cheatCode', ints.active[0] == 1, 30)
				if __cheatAnim then
					imgui.offset(u8' Чит-код: ')
					if rightInputText('##cheatcode', buffers.cheatcode, 110) then cfg.settings.cheatcode = ffi.string(buffers.cheatcode) end
					animatedContentEnd(__cheatAnim, 30)
				end
				imgui.offset(u8'Тема: ') 
					if compactCombo(u8'##Тема', ints.theme, comboThemeLabels, 11) then cfg.settings.theme = ints.theme[0] save()
								themeDirty = true
				end
				local __themeColorAnim = animatedContentBegin('themeColor', ints.theme[0] == 10, 30)
				if __themeColorAnim then
					imgui.Text(u8'	Цвет темы: ')
			    imgui.SameLine()
			    if imgui.ColorEdit3('##colortheme', colortheme, imgui.ColorEditFlags.NoInputs) then
			       	color = join_rgba(colortheme[0] * 255, colortheme[1] * 255, colortheme[2] * 255, 0)
					cfg.settings.r, cfg.settings.g, cfg.settings.b = colortheme[0], colortheme[1], colortheme[2]
						themeDirty = true
					cfg.settings.xcolor = ('%06X'):format(color)
			        color = '{'..('%06X'):format(color)..'}'
					cfg.settings.color = color
    			end
					animatedContentEnd(__themeColorAnim, 30)
				end
				if uiToggle(u8'Приветственное сообщение', checkboxes.hello, u8'Отображает приветственное сообщение при запуске OS Helper, уведомляя об успешной загрузке скрипта и его готовности к работе.') then cfg.settings.hello = checkboxes.hello[0] end
				imgui.SetCursorPosX(89)
			end
			if menu == 7 then
				imgui.Text(u8'OS Helper - скрипт, направленный на облегчение\n жизни как простым игрокам, так и крупным\n бизнесменам. \n Данное ПО не выступает в роли чита или стиллера.\n Его основная задача превратить \n однотипные действия в более \n комфортный экспириенс во время игры.')
				imgui.Text('')
				imgui.Text(u8'Разработчики:') imgui.SameLine() imgui.Link('https://vk.com/osprodsamp', 'OS Production')
				imgui.Text(u8'Нашли баг?') imgui.SameLine() imgui.Link('https://vk.com/topic-215734333_49024979', u8'Вам сюда!')
			end
			if menu == 8 then
				if uiToggle(u8'Редактор времени и погоды', checkboxes.timeweather, u8'Позволяет вручную задать игровое время и погодные условия. После включения выбранные значения автоматически применяются и поддерживаются скриптом.') then
                cfg.settings.timeweather = checkboxes.timeweather[0]
                if checkboxes.timeweather[0] then
                    patch_samp_time_set(true)
                    applyTimeWeatherNow()
                    setTimeOfDay(ints.time[0], 0)
                    forceWeatherNow(ints.weather[0])
                                    applyTimeWeatherNow()
                else
                    patch_samp_time_set(false)
                end
            end
				local __timeWeatherAnim = animatedContentBegin('timeWeather', checkboxes.timeweather[0], 58)
				if __timeWeatherAnim then
					imgui.Text(u8'Время: ')
					imgui.SameLine()
					rightControlBegin(110)
					if imgui.InputInt(u8'##time', ints.time) then
						if ints.time[0] > 24 then
							ints.time[0] = 24
							patch_samp_time_set(true)
                            applyTimeWeatherNow()
						elseif ints.time[0] < 0 then
							ints.time[0] = 0
							patch_samp_time_set(true)
                            applyTimeWeatherNow()
						end
						cfg.settings.time = ints.time[0]
                        if checkboxes.timeweather[0] then
                            patch_samp_time_set(true)
                            applyTimeWeatherNow()
                        end
                    end
					rightControlEnd()
					imgui.Text(u8'Погода: ')
					imgui.SameLine()
					rightControlBegin(110)
					if imgui.InputInt(u8'##weather', ints.weather) then
						if ints.weather[0] < 0 then
							ints.weather[0] = 0  
						elseif ints.weather[0] > 45 then
							ints.weather[0] = 45 
						end
						cfg.settings.weather = ints.weather[0]
                        if checkboxes.timeweather[0] then
                            forceWeatherNow(ints.weather[0])
                        applyTimeWeatherNow()
                        end
                    end
					rightControlEnd()
					animatedContentEnd(__timeWeatherAnim, 58)
				end
				if uiToggle(u8'Настройка FOV', checkboxes.fisheye, u8'Изменяет поле зрения камеры, позволяя настроить более узкий или широкий угол обзора.') then cfg.settings.fisheye = checkboxes.fisheye[0] end
				local __fovAnim = animatedContentBegin('fisheye', checkboxes.fisheye[0], 30)
				if __fovAnim then
                    rightControlBegin(300)
					if imgui.SliderInt('##FOV', sliders.fov, 1, 100) then cfg.settings.fov = sliders.fov[0] end
                    rightControlEnd()
                        if imgui.Checkbox(u8'Отключать FOV при прицеливании', checkboxes.fov_aim) then
                            cfg.settings.fov_aim = checkboxes.fov_aim[0]
                            Config.save(cfg)
                        end
					animatedContentEnd(__fovAnim, 58)
				end
			end
            if menu == 8 then
                local dmToggle = uiToggle(u8'Менеджер дальности отображения', checkboxes.distanceManager,
                    u8'Настройка отображения дальности никнеймов, 3D текста, текста над головой игрока, прогрузки.')
                if dmToggle then
                    DistanceManager.setEnabled(checkboxes.distanceManager[0])
                end

                local dmAnim = animatedContentBegin('distanceManager', checkboxes.distanceManager[0], 170)
                if dmAnim then
                    imgui.Text(u8'Отображение никнеймов:') imgui.SameLine()
                    rightControlBegin(120)
                    if imgui.SliderInt('##dmNametags', sliders.dmNametags, 0, 30) then
                        DistanceManager.set('nametags', sliders.dmNametags[0])
                    end
                    rightControlEnd()

                    imgui.Text(u8'3D Текст:') imgui.SameLine()
                    rightControlBegin(120)
                    if imgui.SliderInt('##dm3DText', sliders.dm3DText, 0, 30) then
                        DistanceManager.set('tdtext', sliders.dm3DText[0])
                    end
                    rightControlEnd()

                    imgui.Text(u8'Отображение текста\nнад головой игрока:') imgui.SameLine()
                    rightControlBegin(120)
                    if imgui.SliderInt('##dmChatBubbles', sliders.dmChatBubbles, 0, 30) then
                        DistanceManager.set('chatbubbles', sliders.dmChatBubbles[0])
                    end
                    rightControlEnd()

                    imgui.Text(u8'\xcf\xf0\xee\xe3\xf0\xf3\xe7\xea\xe0:') imgui.SameLine()
                    rightControlBegin(120)
                    if imgui.SliderInt('##dmLods', sliders.dmLods, 0, 300) then
                        DistanceManager.set('lods', sliders.dmLods[0])
                    end
                    rightControlEnd()
                    animatedContentEnd(dmAnim, 170)
                end
            end

			if menu == 9 then
				-- Job Helper is the parent feature; Bus/Mine/Farm/Fish are its subfeatures.
				if uiToggle(u8'Job Helper', checkboxes.job, u8'\xc3\xeb\xe0\xe2\xed\xfb\xe9 \xec\xee\xe4\xf3\xeb\xfc \xef\xee\xec\xee\xf9\xed\xe8\xea\xee\xe2 \xf0\xe0\xe1\xee\xf2. \xc2\xed\xf3\xf2\xf0\xe8 \xee\xf2\xe4\xe5\xeb\xfc\xed\xee \xe2\xea\xeb\xfe\xf7\xe0\xfe\xf2\xf1\xff Bus Helper, Mine Helper, Farm Helper \xe8 Fish Helper.') then cfg.settings.job = checkboxes.job[0]; if not checkboxes.job[0] then frames.bushelper[0]=false; frames.minehelper[0]=false; frames.farmhelper[0]=false; frames.fishhelper[0]=false end end
				local __jobAnim = animatedContentBegin('jobSub', checkboxes.job[0], 112)
				if __jobAnim then
					imgui.Indent(16)
					if checkboxWithQuestion(u8'Bus Helper', checkboxes.bus, u8'Активация: /bus\nПодсчёт заработка на работе автобусника.') then cfg.settings.bus = checkboxes.bus[0] end
					if checkboxWithQuestion(u8'Mine Helper', checkboxes.mine, u8'Активация: /mine\nПодсчёт заработка на работе шахтёра.') then cfg.settings.mine = checkboxes.mine[0] end
					if checkboxWithQuestion(u8'Farm Helper', checkboxes.farm, u8'Активация: /farm\nПодсчёт заработка на работе фермера.') then cfg.settings.farm = checkboxes.farm[0] end
					if checkboxWithQuestion(u8'Fish Helper', checkboxes.fish, u8'Активация: /fish\nПодсчёт заработка на работе рыболова.') then cfg.settings.fish = checkboxes.fish[0] end
					imgui.Unindent(16)
					animatedContentEnd(__jobAnim, 112)
				end

				-- Infoboard is the parent feature; its displayed fields are subfeatures.
				if uiToggle(u8'Infoboard', checkboxes.doppanel, u8'\xce\xf2\xea\xf0\xfb\xe2\xe0\xe5\xf2 \xee\xf2\xe4\xe5\xeb\xfc\xed\xee\xe5 \xe8\xed\xf4\xee\xf0\xec\xe0\xf6\xe8\xee\xed\xed\xee\xe5 \xee\xea\xed\xee \xf1 \xe4\xe0\xed\xed\xfb\xec\xe8 \xef\xe5\xf0\xf1\xee\xed\xe0\xe6\xe0: \xed\xe8\xea, ID, ping, \xe4\xe0\xf2\xe0, \xe2\xf0\xe5\xec\xff, HP \xe8 \xe1\xf0\xee\xed\xff. \xd0\xe0\xe1\xee\xf2\xe0\xe5\xf2 \xed\xe5\xe7\xe0\xe2\xe8\xf1\xe8\xec\xee \xee\xf2 \xe3\xeb\xe0\xe2\xed\xee\xe3\xee \xec\xe5\xed\xfe.') then cfg.infopanel.doppanel = checkboxes.doppanel[0]; frames.mypanel[0] = checkboxes.doppanel[0]; uiDebug('AUX_TOGGLE', 'info=', frames.mypanel[0]) end
				local __infoAnim = animatedContentBegin('infoSub', checkboxes.doppanel[0], 156)
				if __infoAnim then
					imgui.Indent(16)
					if imgui.Checkbox(u8'Отображать никнейм и ID', checkboxes.nickact) then cfg.infopanel.nickact = checkboxes.nickact[0] end
					if imgui.Checkbox(u8'Отображать ping', checkboxes.pingact) then cfg.infopanel.pingact = checkboxes.pingact[0] end
					if imgui.Checkbox(u8'Отображать дату', checkboxes.daysact) then cfg.infopanel.daysact = checkboxes.daysact[0] end
					if imgui.Checkbox(u8'Отображать время', checkboxes.timeact) then cfg.infopanel.timeact = checkboxes.timeact[0] end
					if imgui.Checkbox(u8'Отображать HP', checkboxes.hpact) then cfg.infopanel.hpact = checkboxes.hpact[0] end
					if imgui.Checkbox(u8'Отображать HP бронежилета', checkboxes.armouract) then cfg.infopanel.armouract = checkboxes.armouract[0] end
					imgui.Unindent(16)
					animatedContentEnd(__infoAnim, 156)
				end

				-- Onlineboard is the parent feature; session/day metrics are subfeatures.
				if uiToggle(u8'Onlineboard', checkboxes.activepanel, u8'\xce\xf2\xea\xf0\xfb\xe2\xe0\xe5\xf2 \xee\xf2\xe4\xe5\xeb\xfc\xed\xee\xe5 \xee\xea\xed\xee \xf1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe8 \xee\xed\xeb\xe0\xe9\xed\xe0. \xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xe5\xf2 \xe4\xe0\xed\xed\xfb\xe5 \xe7\xe0 \xf1\xe5\xf1\xf1\xe8\xfe \xe8 \xf2\xe5\xea\xf3\xf9\xe8\xe9 \xe4\xe5\xed\xfc, \xe2\xea\xeb\xfe\xf7\xe0\xff online, AFK \xe8 \xee\xe1\xf9\xe5\xe5 \xe2\xf0\xe5\xec\xff.') then cfg.onlinepanel.activepanel = checkboxes.activepanel[0]; frames.onlinepanel[0] = checkboxes.activepanel[0]; uiDebug('AUX_TOGGLE', 'online=', frames.onlinepanel[0]) end
				local __onlineAnim = animatedContentBegin('onlineSub', checkboxes.activepanel[0], 156)
				if __onlineAnim then
					imgui.Indent(16)
					if imgui.Checkbox(u8'Онлайн за сессию', onlineToggle.sesOnline) then cfg.onlinepanel.sesOnline = onlineToggle.sesOnline[0] end
					if imgui.Checkbox(u8'AFK за сессию', onlineToggle.sesAfk) then cfg.onlinepanel.sesAfk = onlineToggle.sesAfk[0] end
					if imgui.Checkbox(u8'Общий за сессию', onlineToggle.sesFull) then cfg.onlinepanel.sesFull = onlineToggle.sesFull[0] end
					if imgui.Checkbox(u8'Онлайн за день', onlineToggle.dayOnline) then cfg.onlinepanel.dayOnline = onlineToggle.dayOnline[0] end
					if imgui.Checkbox(u8'AFK за день', onlineToggle.dayAfk) then cfg.onlinepanel.dayAfk = onlineToggle.dayAfk[0] end
					if imgui.Checkbox(u8'Общий за день', onlineToggle.dayFull) then cfg.onlinepanel.dayFull = onlineToggle.dayFull[0] end
					imgui.Unindent(16)
					animatedContentEnd(__onlineAnim, 156)
				end
			end

			imgui.EndChild()
		imgui.End()
    imgui.PopStyleVar() -- IMPORTANT: do not leak main-window alpha into auxiliary windows

end

local movablePanels = {
    infopanel = imgui.ImVec2(posX, posY),
    onlinepanel = imgui.ImVec2(onlineposX, onlineposY),
    bushelper = imgui.ImVec2(resX / 2 - 110, resY / 2 - 70),
    minehelper = imgui.ImVec2(resX / 2 - 110, resY / 2 - 85),
    farmhelper = imgui.ImVec2(resX / 2 - 110, resY / 2 - 58),
    fishhelper = imgui.ImVec2(resX / 2 - 110, resY / 2 - 58),
}

local function beginMovablePanel(id, title, pos, minWidth)
    local width = minWidth or 260
    imgui.SetNextWindowPos(pos, imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(width, 0), imgui.Cond.Always)
    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(width, 0), imgui.ImVec2(width, resY - 40))

    local flags = imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoScrollbar
    local opened = imgui.Begin(title .. '##' .. id, nil, flags)
    if not opened then
        imgui.End()
        return false
    end

    local draw = imgui.GetWindowDrawList()
    local winPos = imgui.GetWindowPos()
    local dragW, dragH = math.max(34, width - 44), 24
    imgui.SetCursorScreenPos(imgui.ImVec2(winPos.x + 4, winPos.y + 2))
    local gripPos = imgui.GetCursorScreenPos()
    imgui.InvisibleButton('##drag_' .. id, imgui.ImVec2(dragW, dragH))
    if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
        local delta = imgui.GetIO().MouseDelta
        pos.x = pos.x + delta.x
        pos.y = pos.y + delta.y
    end

    local gripColor = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.TextDisabled])
    for row = 0, 2 do
        for col = 0, 1 do
            local cx = gripPos.x + 8 + col * 6
            local cy = gripPos.y + 7 + row * 5
            draw:AddCircleFilled(imgui.ImVec2(cx, cy), 1.3, gripColor)
        end
    end

    imgui.SetCursorScreenPos(imgui.ImVec2(winPos.x + width - 25, winPos.y + 2))
    if drawCloseXButton(id, 23, 23) then
        if id == 'infopanel' then uiDebug('AUX_CLOSE','info'); frames.mypanel[0] = false; cfg.infopanel.doppanel = false; checkboxes.doppanel[0] = false
        elseif id == 'onlinepanel' then uiDebug('AUX_CLOSE','online'); frames.onlinepanel[0] = false; cfg.onlinepanel.activepanel = false; checkboxes.activepanel[0] = false
        elseif id == 'bushelper' then frames.bushelper[0] = false; checkboxes.bus[0] = false
        elseif id == 'minehelper' then frames.minehelper[0] = false; checkboxes.mine[0] = false
        elseif id == 'farmhelper' then frames.farmhelper[0] = false; checkboxes.farm[0] = false
        elseif id == 'fishhelper' then frames.fishhelper[0] = false; checkboxes.fish[0] = false end
    end

    if pos.x < 0 then pos.x = 0 end
    if pos.y < 0 then pos.y = 0 end
    local maxX = math.max(0, resX - width)
    local maxY = math.max(0, resY - 40)
    if pos.x > maxX then pos.x = maxX end
    if pos.y > maxY then pos.y = maxY end

    local text = title
    local textSize = imgui.CalcTextSize(text)
    local textX = (width - textSize.x) / 2
    textX = math.min(textX, width - 25 - textSize.x)
    textX = math.max(textX, 0)
    imgui.SetCursorPos(imgui.ImVec2(textX, 4))
    imgui.Text(title)
    imgui.SetCursorPosY(25)

    if id == 'infopanel' then
        if cfg.infopanel.x ~= pos.x or cfg.infopanel.y ~= pos.y then
            cfg.infopanel.x, cfg.infopanel.y = pos.x, pos.y
            posX, posY = pos.x, pos.y
        end
    elseif id == 'onlinepanel' then
        if cfg.onlinepanel.x ~= pos.x or cfg.onlinepanel.y ~= pos.y then
            cfg.onlinepanel.x, cfg.onlinepanel.y = pos.x, pos.y
            onlineposX, onlineposY = pos.x, pos.y
        end
    end
    return true
end

local function drawAuxiliaryWindows()
    if frames.mypanel[0] then
        if beginMovablePanel('infopanel', u8'Infoboard', movablePanels.infopanel, 180) then
            if cfg.infopanel.nickact then imgui.Text(u8(nick)); imgui.SameLine(); imgui.Text('['..id..']') end
            if cfg.infopanel.pingact then imgui.Text(u8'Ping: '..ping..'ms') end
            if cfg.infopanel.daysact then imgui.Text(os.date('%d.%m.%Y / ')..u8(day_date[tonumber(os.date('%w'))])) end
            if cfg.infopanel.timeact then imgui.Text(u8"Время: "..nowTime) end
            if cfg.infopanel.armouract then imgui.Text(u8"HP бронежилета: "..armour) end
            if cfg.infopanel.hpact then imgui.Text(u8'HP: '..health) end
        imgui.End()
        end
    end

    if frames.onlinepanel[0] then
        if beginMovablePanel('onlinepanel', u8'Onlineboard', movablePanels.onlinepanel, 180) then
            if sampGetGamestate() ~= 3 then
                imgui.CenterText(u8"Подключение: "..get_clock(connectingTime))
            else
                if cfg.onlinepanel.dayOnline then imgui.Text(u8"За день (чистый): "..get_clock(cfg.onDay.online)) end
                if cfg.onlinepanel.dayAfk then imgui.Text(u8"AFK за день: "..get_clock(cfg.onDay.afk)) end
                if cfg.onlinepanel.dayFull then imgui.Text(u8"Онлайн за день: "..get_clock(cfg.onDay.full)) end
                if cfg.onlinepanel.sesOnline or cfg.onlinepanel.sesAfk or cfg.onlinepanel.sesFull then imgui.Separator() end
                if cfg.onlinepanel.sesOnline then imgui.Text(u8"Сессия (чистая): "..get_clock(sesOnline[0])) end
                if cfg.onlinepanel.sesAfk then imgui.Text(u8"AFK за сессию: "..get_clock(sesAfk[0])) end
                if cfg.onlinepanel.sesFull then imgui.Text(u8"Онлайн за сессию: "..get_clock(sesFull[0])) end
            end
        imgui.End()
        end
    end

    if frames.bushelper[0] then jobhelperimgui('bushelper') end
    if frames.minehelper[0] then jobhelperimgui('minehelper') end
    if frames.farmhelper[0] then jobhelperimgui('farmhelper') end
    if frames.fishhelper[0] then jobhelperimgui('fishhelper') end
end

local function updateMainFade()
    local now = os.clock()
    local dt = math.min(now - mainWindowFade.last, 0.05)
    mainWindowFade.last = now
    local k = math.min(1.0, dt * 12.0)
    mainWindowFade.alpha = mainWindowFade.alpha + (mainWindowFade.target - mainWindowFade.alpha) * k
    if math.abs(mainWindowFade.target - mainWindowFade.alpha) < 0.002 then
        mainWindowFade.alpha = mainWindowFade.target
    end
    mainWindowOpen[0] = mainWindowFade.alpha > 0.01 or mainWindowFade.target > 0.5
end

local function numberToString(num)
    if num == math.floor(num) then
        -- целое число
        return string.format("%.0f", num)
    else
        -- дробное: 8 знаков максимум, лишние нули убираем
        return string.format("%.8f", num):gsub("%.?0+$", "")
    end
end

local function drawCalculatorOverlay()
    if not checkboxes.calcbox[0] or not sampIsChatInputActive() then return end
    if not calcactive or result == nil then return end

    local input = sampGetInputInfoPtr()
    input = getStructElement(input, 0x8, 4)
    local windowPosX = getStructElement(input, 0x8, 4)
    local windowPosY = getStructElement(input, 0xC, 4)

    -- Форматируем число без экспоненты
    local resultStr = numberToString(result)

    -- Добавляем пробелы в целую часть: 1 000 000
    local calcDisplay = resultStr:gsub('^([%-]?%d+)(%.%d+)$', function(a, b)
        return a:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '') .. b
    end):gsub('^([%-]?%d+)$', function(a)
        return a:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
    end)

    -- Используем именно calcDisplay, чтобы пробелы сохранялись
    local fullResult = calctext .. " = " .. calcDisplay

    local labelText = u8'Результат: ' .. fullResult
    local textWidth = labelText:len() * 3.5

    local margin = 5
    local windowWidth = textWidth + 2 * margin

    imgui.SetNextWindowPos(
        imgui.ImVec2(windowPosX, windowPosY + 80),
        imgui.Cond.FirstUseEver
    )
    imgui.SetNextWindowSize(imgui.ImVec2(windowWidth, 30))

    imgui.Begin(
        '##OSHelperCalculatorOverlay',
        nil,
        imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
    )

    imgui.Text(u8'Результат:')
    imgui.SameLine()

    imgui.SendResult(fullResult, calcDisplay)

    imgui.End()
end

-- One permanent ImGui frame. The main menu and all auxiliary windows are
-- rendered by the same active callback, but their state is independent.
local uiFrameLastLog = 0
local uiFrame = imgui.OnFrame(
    function() return true end,
    function(self)
        updateMainFade()
        applyCurrentTheme()

        local mainVisible = frames.window[0]
            or mainWindowFade.alpha > 0.01
            or frames.colors[0]
            or frames.cwindow[0]
            or frames.kbset[0]

        local auxEnabled = frames.mypanel[0]
            or frames.onlinepanel[0]
            or frames.bushelper[0]
            or frames.minehelper[0]
            or frames.farmhelper[0]
            or frames.fishhelper[0]
        -- Auxiliary windows remain independent from the main menu.
        local auxVisible = auxEnabled

        if UI_DEBUG and (not uiFrameLastLog or os.clock() - uiFrameLastLog > 1.0) then
            uiFrameLastLog = os.clock()
            uiDebug("FRAME", "main=", mainVisible, "alpha=", mainWindowFade.alpha, "aux=", auxVisible,
                "online=", frames.onlinepanel[0], "info=", frames.mypanel[0],
                "bus=", frames.bushelper[0], "mine=", frames.minehelper[0],
                "farm=", frames.farmhelper[0], "fish=", frames.fishhelper[0])
        end

        -- ImGui never owns or draws the mouse cursor.
        -- Native cursor visibility is handled only by setMainWindowVisible().
        self.HideCursor = true

        if mainVisible then
            drawMainWindow()
            if frames.colors[0] then
                imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
                imgui.SetNextWindowSize(imgui.ImVec2(500, 325), imgui.Cond.FirstUseEver)
                imgui.Begin('Colors Menu (OS '..thisScript().version..')', frames.colors, imgui.WindowFlags.NoResize)
                    if colorslist then imgui.Image(colorslist, imgui.ImVec2(480, 1400)) end
                imgui.End()
            end
        end

        if auxVisible then
            drawAuxiliaryWindows()
        end
        drawCalculatorOverlay()

    end
)


function character()
	if uiToggle(u8'Бронежилет', checkboxes.armor, u8'Функция позволяет по нажатию назначенной клавиши автоматически надевать бронежилет. Пользователь самостоятельно устанавливает минимальный порог прочности: если количество HP текущего бронежилета ниже заданного значения, скрипт блокирует его использование, предотвращая необоснованный расход экипировки.') then cfg.settings.armor = checkboxes.armor[0] end
		local __armorAnim = animatedContentBegin('armor', checkboxes.armor[0], 62)
		if __armorAnim then
            drawBindButton('armor', u8'Бинд бронежилета')
            imgui.Text(u8'Порог использования\nбронежилета:')
            imgui.SameLine()
            rightControlBegin(110)
            if imgui.InputInt('##bindArmorLimit', ints.bindArmorLimit, 1, 5) then
                if ints.bindArmorLimit[0] < 1 then ints.bindArmorLimit[0] = 1 end
                if ints.bindArmorLimit[0] > 1000 then ints.bindArmorLimit[0] = 1000 end
                cfg.settings.bindArmorLimit = ints.bindArmorLimit[0]
                save()
            end
            rightControlEnd()
            animatedContentEnd(__armorAnim, 62)
        end
		if uiToggle(u8'Маска', checkboxes.mask, u8'Функция позволяет при нажатии назначенной клавиши надеть маску.') then cfg.settings.mask = checkboxes.mask[0] end
		local __maskAnim = animatedContentBegin('maskBind', checkboxes.mask[0], 30)
		if __maskAnim then
		    drawBindButton('mask', u8'Бинд маски')
		    animatedContentEnd(__maskAnim, 30)
		end
		if uiToggle(u8'Наркотики', checkboxes.drugs, u8'Функция позволяет при нажатии назначенной клавиши автоматически использовать три наркотика.') then cfg.settings.drugs = checkboxes.drugs[0] end
		local __drugsAnim = animatedContentBegin('drugsBind', checkboxes.drugs[0], 30)
		if __drugsAnim then
		    drawBindButton('drugs', u8'Бинд наркотиков')
		    animatedContentEnd(__drugsAnim, 30)
		end
		if uiToggle(u8'Аптечка', checkboxes.med, u8'Функция позволяет при нажатии назначенной клавиши автоматически использовать аптечку, восстанавливая здоровье персонажа без необходимости открывать инвентарь.') then cfg.settings.med = checkboxes.med[0] end
		local __medAnim = animatedContentBegin('medBind', checkboxes.med[0], 30)
		if __medAnim then
		    drawBindButton('med', u8'Бинд аптечки')
		    animatedContentEnd(__medAnim, 30)
		end
		if uiToggle(u8'Автоускорение', checkboxes.autorun, u8'Функция автоматически имитирует частые нажатия кнопки бега при её удержании, помогая поддерживать максимальную скорость спринта без необходимости многократно нажимать клавишу вручную.') then cfg.settings.autorun = checkboxes.autorun[0] end
        local __autorunAnim = animatedContentBegin('autorunBind', checkboxes.autorun[0], 30)
        if __autorunAnim then
            drawBindButton('autorun', u8'Бинд бега')
            animatedContentEnd(__autorunAnim, 30)
        end
		if uiToggle(u8'Z-Timer', checkboxes.ztimerstatus, u8'После получения метки Z функция автоматически запускает обратный отсчёт длительностью 600 секунд, позволяя отслеживать оставшееся время до завершения заданного интервала.') then cfg.settings.ztimerstatus = checkboxes.ztimerstatus[0] end
		if uiToggle(u8'Авто-кликер', checkboxes.balloon, u8'При зажатии назначенной клавиши функция автоматически нажимает левую кнопку мыши с заданной интенсивностью и частотой, выполняя роль автокликера. При отпускании клавиши автоматические нажатия прекращаются.') then cfg.settings.balloon = checkboxes.balloon[0] end
        local __balloonAnim = animatedContentBegin('balloon', checkboxes.balloon[0], 62)
        if __balloonAnim then
            drawBindButton('balloon', u8'Бинд авто-кликера')
			imgui.Text(u8'Интенсивность\nв миллисекундах:')
			imgui.SameLine()
			rightControlBegin(110)
			if imgui.InputInt('##autoclickerDelay', ints.autoclickerDelay, 1, 10) then
				if ints.autoclickerDelay[0] < 1 then ints.autoclickerDelay[0] = 1 end
				if ints.autoclickerDelay[0] > 1000 then ints.autoclickerDelay[0] = 1000 end
				cfg.settings.autoclickerDelay = ints.autoclickerDelay[0]
				save()
			end
			rightControlEnd()
            animatedContentEnd(__balloonAnim, 62)
		end
		if uiToggle(u8'Бесконечный бег', checkboxes.infrun, u8'Функция предотвращает снижение выносливости персонажа во время спринта, позволяя сохранять максимальную скорость бега.') then cfg.settings.infrun = checkboxes.infrun[0] end
		if uiToggle(u8'Skin Changer', checkboxes.vskin, u8'Функция позволяет изменить внешний вид персонажа локально — изменения видны только вам. Для смены скина используется команда /skin [ID], где вместо [ID] необходимо указать идентификатор желаемого скина.') then cfg.settings.vskin = checkboxes.vskin[0] end 
		if uiToggle(u8'Крафт оружия', checkboxes.gunmaker, u8'Функция обеспечивает быстрый крафт оружия с помощью команды /cg, сокращая количество ручных действий и ускоряя процесс создания необходимого вооружения.') then cfg.settings.gunmaker = checkboxes.gunmaker[0] end
		local __gunAnim = animatedContentBegin('gunmaker', checkboxes.gunmaker[0], 92)
		if __gunAnim then
			imgui.Text(u8'Оружие: ')
			imgui.SameLine()
			alignRightControl(110)
			if compactCombo('##CraftGun', ints.gunmode, comboGunLabels, 3) then cfg.settings.gunmode = ints.gunmode[0] save() end
			imgui.Text(u8'Патроны:')
			imgui.SameLine()
			rightControlBegin(110)
			if imgui.InputInt("##Патроны", ints.bullet, 1, 10) then 
				if ints.bullet[0] < 1 then ints.bullet[0] = 1 end
				if ints.bullet[0] > 1000 then ints.bullet[0] = 1000 end
				cfg.settings.bullet = ints.bullet[0] 
				save() end
                    rightControlEnd()
			if ints.gunmode[0] == 0 then
				ammo = ints.bullet[0] * 2
			elseif ints.gunmode[0] == 1 then
				ammo = ints.bullet[0] * 2
			elseif ints.gunmode[0] == 2 then
				ammo = ints.bullet[0] * 10
			end
			imgui.Text(u8'Стоимость крафта: ')
			imgui.SameLine()
			alignRightControl(110)
			imgui.Text(ammo..u8' мат.')
            animatedContentEnd(__gunAnim, 92)
		end
end

function transport()
	if uiToggle(u8'Ремкомплект', checkboxes.rem, u8'Функция позволяет быстро чинить транспорт с помощью ремкомплекта при нажатии на назначенную клавишу, значительно упрощая процесс ремонта и экономя время.') then cfg.settings.rem = checkboxes.rem[0] end
	local __remAnim = animatedContentBegin('remBind', checkboxes.rem[0], 30)
	if __remAnim then
	    drawBindButton('rem', u8'Бинд ремкомплекта')
	    animatedContentEnd(__remAnim, 30)
	end
    if uiToggle(u8'Домкрат', checkboxes.jack, u8'При нажатии на назначенную клавишу на транспорт автоматически применяется домкрат, позволяя быстро восстановить его положение и продолжить движение без лишних действий.') then cfg.settings.jack = checkboxes.jack[0] end
    local __jackAnim = animatedContentBegin('jackBind', checkboxes.jack[0], 30)
    if __jackAnim then
        drawBindButton('jack', u8'Бинд домкрата')
        animatedContentEnd(__jackAnim, 30)
    end
	if uiToggle(u8'Канистра', checkboxes.fill, u8'При нажатии на назначенную клавишу автоматически заправляет транспорт с использованием канистры, позволяя быстро восстановить уровень топлива и продолжить движение без лишних действий.') then cfg.settings.fill = checkboxes.fill[0] end
	local __fillAnim = animatedContentBegin('fillBind', checkboxes.fill[0], 30)
	if __fillAnim then
	    drawBindButton('fill', u8'Бинд канистры')
	    animatedContentEnd(__fillAnim, 30)
	end
	if uiToggle(u8'+W moto/bike', checkboxes.plusw, u8'При зажатии W сидя на велосипеде/мотоцикле, начинает спамить этой клавишей для развития максимальной скорости') then cfg.settings.plusw = checkboxes.plusw[0] end
	if uiToggle(u8'Дрифт', checkboxes.drift, u8'Использует назначенную клавишу для управления заносом. По умолчанию используется LSHIFT, но клавишу можно переназначить.') then cfg.settings.drift = checkboxes.drift[0] end
end

function jobhelperimgui(onlyId)
	if frames.bushelper[0] and (onlyId == nil or onlyId == 'bushelper') then
        if beginMovablePanel('bushelper', u8'Bus Helper', movablePanels.bushelper, 220) then
            imgui.Text(u8'Денежный заработок: '..bhsalary..u8' руб.')
            imgui.Text(u8'Количество остановок: '..bhstop..u8' ост.')
            imgui.Text(u8'Выпало ларцов: '..bhcases..u8' лар.')
            imgui.Text(u8'Выпало чертежей: '..bhchert..u8' черт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                bhsalary = 0
                bhstop = 0
                bhcases = 0
                bhchert = 0
            end
        imgui.End()
        end
    end
    if frames.minehelper[0] and (onlyId == nil or onlyId == 'minehelper') then
        if beginMovablePanel('minehelper', u8'Mine Helper', movablePanels.minehelper, 220) then
            imgui.Text(u8'Камень: '..mhstone..u8' шт.')
            imgui.Text(u8'Металл: '..mhmetall..u8' шт.')
            imgui.Text(u8'Бронза: '..mhbronze..u8' шт.')
            imgui.Text(u8'Серебро: '..mhsilver..u8' шт.')
            imgui.Text(u8'Золото: '..mhgold..u8' шт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                mhstone = 0
                mhmetall = 0
                mhbronze = 0
                mhsilver = 0
                mhgold = 0
            end
        imgui.End()
        end
    end
    if frames.farmhelper[0] and (onlyId == nil or onlyId == 'farmhelper') then
        if beginMovablePanel('farmhelper', u8'Farm Helper', movablePanels.farmhelper, 220) then
            imgui.Text(u8' шт.'..fhlyon..u8' шт.')
            imgui.Text(u8'Хлопок: '..fhhlopok..u8' шт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                fhlyon = 0
                fhhlopok = 0
            end
        imgui.End()
        end
    end
    if frames.fishhelper[0] and (onlyId == nil or onlyId == 'fishhelper') then
        if beginMovablePanel('fishhelper', u8'Fish Helper', movablePanels.fishhelper, 220) then
            imgui.Text(u8'Заработок: '..fishsalary..u8' руб.')
            imgui.TextQuestion(u8'Заработок приблизителен, 1 рыба = 15.000руб')
            imgui.Text(u8'Ларцы: '..fishcase..u8' шт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                fishsalary = 0
                fishcase = 0
            end
        imgui.End()
        end
    end
end


local function isValidUtf8(s)
    local i = 1
    while i <= #s do
        local c = s:byte(i)
        if c < 0x80 then
            i = i + 1
        elseif c >= 0xC2 and c <= 0xDF then
            local c2 = s:byte(i + 1)
            if not c2 or c2 < 0x80 or c2 > 0xBF then return false end
            i = i + 2
        elseif c >= 0xE0 and c <= 0xEF then
            local c2, c3 = s:byte(i + 1), s:byte(i + 2)
            if not c2 or not c3 or c2 < 0x80 or c2 > 0xBF or c3 < 0x80 or c3 > 0xBF then return false end
            i = i + 3
        elseif c >= 0xF0 and c <= 0xF4 then
            local c2, c3, c4 = s:byte(i + 1), s:byte(i + 2), s:byte(i + 3)
            if not c2 or not c3 or not c4 or c2 < 0x80 or c2 > 0xBF or c3 < 0x80 or c3 > 0xBF or c4 < 0x80 or c4 > 0xBF then return false end
            i = i + 4
        else
            return false
        end
    end
    return true
end

function msg(arg)
    local text = tostring(arg)
    if isValidUtf8(text) and u8 and u8.decode then
        text = u8:decode(text)
    end
    sampAddChatMessage(color..'[OS Helper] {FFFFFF}'..textcolor..text, -1)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

local fontsize = nil
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local io = imgui.GetIO()
    fontsize = io.Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\tahoma.ttf', 15.0, nil, io.Fonts:GetGlyphRangesCyrillic())
    local fontConfig = imgui.ImFontConfig()
    fontConfig.MergeMode = true
    fontConfig.PixelSnapH = true
    local iconRanges = new.ImWchar[3](fa.min_range, fa.max_range, 0)
    fa_font = nil

    local okBase85, base85 = pcall(function()
        return fa.get_font_data_base85('solid')
    end)
    if okBase85 and base85 then
        local okFont, loaded = pcall(function()
            return io.Fonts:AddFontFromMemoryCompressedBase85TTF(base85, 18.0, fontConfig, iconRanges)
        end)
        if okFont and loaded then fa_font = loaded end
    end

    if fa_font == nil then
        local candidates = {
            getWorkingDirectory() .. '\\resource\\fa-solid-900.ttf',
            getWorkingDirectory() .. '\\resource\\fa-solid-900.ttf',
            getGameDirectory() .. '\\moonloader\\resource\\fonts\\fa-solid-900.ttf',
            getWorkingDirectory() .. '\\fa-solid-900.ttf',
            getGameDirectory() .. '\\moonloader\\fa-solid-900.ttf',
        }
        for _, path in ipairs(candidates) do
            if doesFileExist(path) then
                local okFont, loaded = pcall(function()
                    return io.Fonts:AddFontFromFileTTF(path, 18.0, fontConfig, iconRanges)
                end)
                if okFont and loaded then fa_font = loaded break end
            end
        end
    end
logo = imgui.CreateTextureFromFileInMemory(new('const char*', logo_b2c), #logo_b2c)
    local colorsPath = getWorkingDirectory() .. '/OS Helper/colors.png'
    if doesFileExist(colorsPath) then
        colorslist = imgui.CreateTextureFromFile(colorsPath)
    end
    -- Style is safe here: mimgui has initialized its renderer/context.
    applyCurrentTheme()
end)

function imgui.Link(link,name,myfunc)
    myfunc = type(name) == 'boolean' and name or myfunc or false
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link

    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()

    local resultBtn = imgui.InvisibleButton('##'..link..name, size)
    if resultBtn then
        if not myfunc then
            os.execute('explorer '..link)
        end
    end

    imgui.SetCursorPos(p2)

    local hover_col = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
    local normal_col = imgui.GetStyle().Colors[imgui.Col.Button]

    if imgui.IsItemHovered() then
        imgui.TextColored(hover_col, name)
        imgui.GetWindowDrawList():AddLine(
            imgui.ImVec2(p.x, p.y + size.y),
            imgui.ImVec2(p.x + size.x, p.y + size.y),
            imgui.ColorConvertFloat4ToU32(hover_col)
        )
    else
        imgui.TextColored(normal_col, name)
    end

    return resultBtn
end

function sampev.onSetInterior(interior)
    if interior == 10 then
        msg('ID цветов для покраски машин - /colors')
    end
end

local _lastToggleRow = nil

function imgui.TextQuestion(text)
    local row = _lastToggleRow
    if row then
        local draw = imgui.GetWindowDrawList()
        local qx = row.questionX
        local qy = row.questionY
        local qSize = 16
        local q1 = imgui.ImVec2(qx, qy)
        local q2 = imgui.ImVec2(qx + qSize, qy + qSize)

        -- TextQuestion is also DrawList text, so explicitly follow the
        -- main-window fade just like ToggleButton and the close icon.
        local base = imgui.GetStyle().Colors[imgui.Col.TextDisabled]
        -- Style alpha already contains the main-window fade and, when inside
        -- animatedContentBegin(), the section fade as well.
        local styleAlpha = (imgui.GetStyle().Alpha or 1.0)
        local col = imgui.ColorConvertFloat4ToU32(
            imgui.ImVec4(base.x, base.y, base.z, base.w * styleAlpha)
        )
        draw:AddText(q1, col, '(?)')
        if imgui.IsMouseHoveringRect(q1, q2, true) then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(450)
            imgui.TextUnformatted(text)
            imgui.PopTextWrapPos()
            imgui.EndTooltip()
        end
        _lastToggleRow = nil
        return
    end

    -- Fallback for calls outside a ToggleButton row.
    local cursor = imgui.GetCursorScreenPos()
    local tqFade = (imgui.GetStyle().Alpha or 1.0)
    imgui.PushStyleColor(imgui.Col.TextDisabled,
        imgui.ImVec4(
            imgui.GetStyle().Colors[imgui.Col.TextDisabled].x,
            imgui.GetStyle().Colors[imgui.Col.TextDisabled].y,
            imgui.GetStyle().Colors[imgui.Col.TextDisabled].z,
            imgui.GetStyle().Colors[imgui.Col.TextDisabled].w * tqFade
        )
    )
    imgui.SetCursorScreenPos(cursor)
    imgui.TextDisabled('(?)')
    imgui.PopStyleColor()
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function send(text)
	sampSendChat(text)
end

function save()
	Config.save(cfg)
end

function imgui.offset(text, width)
    width = width or 150
    imgui.Text(text)
    imgui.SameLine()
    local x = math.max(0, imgui.GetWindowWidth() - width - 8)
    imgui.SetCursorPosX(x)
    if imgui.SetNextItemWidth then imgui.SetNextItemWidth(width) end
end


