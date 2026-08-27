if type(imgui.InputTextWithHint) ~= 'function' then
    function imgui.InputTextWithHint(label, hint, buf, flags, callback, user_data)
        local l_pos = imgui.GetCursorPos()
        local handle = imgui.InputText(label, buf, flags, callback, user_data)
        if type(hint) == 'string' and ffi.string(buf):len() < 1 then
            local t_size = imgui.CalcTextSize(hint).x
            local item_width = imgui.CalcItemWidth()
            imgui.SetCursorPos(imgui.ImVec2(l_pos.x + 8, l_pos.y + 2))
            imgui.TextDisabled((t_size > item_width and hint:sub(1, math.max(1, math.floor(item_width / math.max(1, imgui.CalcTextSize('A').x)))) or hint))
            imgui.SetCursorPos(l_pos)
        end
        return handle
    end
end

function nsc_cmd( arg )
	if checkboxes.vskin[0] then
		if #arg == 0 then 
			sampAddChatMessage("/skin ID",-1)
		else
			local skinid = tonumber(arg)
			if skinid == 0 then 
				setskin = 0
			else
				setskin = skinid
				_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
				set_player_skin(id, setskin)
			end
		end
	else
		msg('Функция Skin Changer не включена в главном меню.')
	end
end

function getStrByState(keyState)
	if keyState == 0 then
		return "OFF"
	end
	return "ON"
end
function translite(text)
	for k, v in pairs(chars) do
		text = string.gsub(text, k, v)
	end
	return text
end

function onScriptTerminate(s)
	if s == thisScript() then
		cfg.keyboard.kbset = checkboxes.keyboard[0]
		cfg.keyboard.posx, cfg.keyboard.posy = checkboxes.keyboard_pos.x, checkboxes.keyboard_pos.y
		Config.save(cfg)
	end
end

function join_rgba(r, g, b, a)
    local rgba = b  -- b
    rgba = bit.bor(rgba, bit.lshift(g, 8))  -- g
    rgba = bit.bor(rgba, bit.lshift(r, 16)) -- r
    rgba = bit.bor(rgba, bit.lshift(a, 24)) -- a
    return rgba
end

function showInputHelp()
	while true do
		local chat = sampIsChatInputActive()
		if chat and checkboxes.chathelper[0] then
			local in1 = sampGetInputInfoPtr()
			local in1 = getStructElement(in1, 0x8, 4)
			local in2 = getStructElement(in1, 0x8, 4)
			local in3 = getStructElement(in1, 0xC, 4)
			fib = in3 + 53
			fib2 = in2 + 150
			local _, pID = sampGetPlayerIdByCharHandle(playerPed)
			local name = sampGetPlayerNickname(pID)
			local score = sampGetPlayerScore(pID)
			local color = sampGetPlayerColor(pID)
			local capsState = ffi.C.GetKeyState(20)
			local success = ffi.C.GetKeyboardLayoutNameA(KeyboardLayoutName)
			local errorCode = ffi.C.GetLocaleInfoA(tonumber(ffi.string(KeyboardLayoutName), 16), 0x00000002, LocalInfo, BuffSize)
			local localName = ffi.string(LocalInfo)
			local stringtext = string.format("{c7c7c7}ID: {"..cfg.settings.xcolor.."}%d, {c7c7c7}Caps: {"..cfg.settings.xcolor.."}%s, {c7c7c7}Lang: {"..cfg.settings.xcolor.."}%s{ffffff}", pID, getStrByState(capsState), string.match(localName, "([^%(]*)"))
			renderFontDrawText(inputHelpText, stringtext, fib2, fib, 0xD7FFFFFF)
		end
		wait(0)
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == 261 and wparam == 13 then consumeWindowMessage(true, true) end
end

function inputChat()
    -- SA:MP owns its chat input/caret. Do not rewrite text every frame.
    while true do
        wait(50)
    end
end

function clearchat()
	for i = 1, 50 do
		sampAddChatMessage('', -1)
	end
end

function patch_samp_time_set(enable)
	if enable and default == nil then
		default = readMemory(sampGetBase() + 0x9C0A0, 4, true)
		writeMemory(sampGetBase() + 0x9C0A0, 4, 0x000008C2, true)
	elseif enable == false and default ~= nil then
		writeMemory(sampGetBase() + 0x9C0A0, 4, default, true)
		default = nil
	end
end

function sampev.onShowDialog(id, style, title, button1, button0, text)
	if checkboxes.mininghelper[0] then
    if miningtool then
	    if id == 269 or id == 0 and title:find('Обзор всех видеокарт') or title:find('Выберите видеокарту') then
			local automining_btcoverall = 0
			local automining_btcoverallph = 0
			local automining_btcamountoverall = 0
			local automining_videocards = 0
			local automining_videocardswork = 0
			for line in text:gmatch("[^\n]+") do
                dtext[#dtext+1] = line 
            end
			
			if dtext[1]:find('%(BTC%)') then
			    dtext[1] = dtext[1]:gsub('%(BTC%)', '%1 | До 9 BTC')
			end
			
			for d = 1, #dtext do
				if dtext[d]:find('Полка%s+№%d+%s+|%s+%{BEF781%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+%d+%p%d+%%') then	--       ,                 
					automining_status = 1
					automining_statustext = '{BEF781}'
				else
					automining_status = 0
					automining_statustext = '{F78181}'
				end
				local automining_lvl = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+(%d+)%s+уровень%s+%d+%p%d+%%')) --               
				local automining_fillstatus = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%%')) --                          
				local automining_btcamount = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+(%d+%p%d+)%s+BTC%s+%d+%s+уровень%s+%d+%p%d+%%')) --                                           						
				if automining_lvl ~= nil and automining_fillstatus ~= nil and automining_btcamount ~= nil then					    						
					automining_videocards = automining_videocards + 1
					automining_btctimetofull = math.ceil((9 - automining_btcamount) / INFO[automining_lvl])
					if automining_status == 1 then 
						automining_videocardswork = automining_videocardswork + 1
					end
					if automining_btcamount >= 1 then 
						automining_btcamountinfo = true	
					else 
						automining_btcamountinfo = false 
					end
                    					
					automining_fillstatushours = math.ceil(oxladtime * (automining_fillstatus / 100)) --                        
					automining_fillstatusbtc = automining_fillstatushours * INFO[automining_lvl] --                         BTC
					automining_btcoverall = automining_btcoverall + automining_fillstatusbtc --                                       
					automining_btcamountoverall = automining_btcamountoverall + math.floor(automining_btcamount) --                                    
					if automining_fillstatus > 0 and automining_status == 1 then
						automining_btcoverallph = automining_btcoverallph + INFO[automining_lvl]
					end
					dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+'..automining_lvl..'%s+уровень', '%1 | '..automining_statustext..INFO[automining_lvl]..'/Час')
					if automining_fillstatus > 0 then
						dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+|%s+%{......%}%d+%p%d+/Час%s+'..automining_fillstatus..'%A+', '%1 '..tostring(automining_status and '{BEF781}' or '{F78181}')..'- [~'..automining_fillstatushours..' Час(ов)] {FFFFFF}|{81DAF5} [~'..string.format("%.1f", automining_fillstatusbtc)..' BTC]')
					else
						dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+|%s+%{......%}%d+%p%d+/Час%s+'..automining_fillstatus..'%A+', '%1 {F78181}(!)')
					end
					dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC', '%1 '..tostring(automining_btcamountinfo and '{BEF781}•' or '{F78181}•')..' {ffffff}| '..automining_statustext..'~'..automining_btctimetofull..'ч')
				end				
			end
			
		if id == 269 and title:find('Выберите видеокарту') then
            if worktread ~= nil then
                worktread:terminate()
            end			
		    local automining_fillstatus1 = tonumber(text:match('Полка №1 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus2 = tonumber(text:match('Полка №2 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus3 = tonumber(text:match('Полка №3 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus4 = tonumber(text:match('Полка №4 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			
			local automining_getbtcstatus1 = tonumber(text:match('Полка №1 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus2 = tonumber(text:match('Полка №2 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus3 = tonumber(text:match('Полка №3 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus4 = tonumber(text:match('Полка №4 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+уровень%s+%d+.'))				
			
			for i = 1, 4 do
			    local automining_lvl = tonumber(text:match('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+(%d+)%s+уровень%s+%d+.'))
				local automining_fillstatus = tonumber(text:match('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			    if automining_fillstatus ~= nil then
					if automining_fillstatus > 0 and automining_lvl ~= nil then
						automining_fillstatushours =  math.ceil(224 * (automining_fillstatus / 100))
						text = text:gsub('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+%d+%p%d+%A', '%1 {BEF781}- [~'..automining_fillstatushours..' Час(ов)]')	
					end				
					if automining_lvl > 0 then
						text = text:gsub('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень', '%1 | '..INFO[automining_lvl]..'/Час')
					end
                end				
			end					
			
            if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				if automining_getbtc == 1 then
				    if automining_getbtcstatus1 ~= nil then
						if automining_getbtcstatus1 < 1 then
							automining_getbtc = 2
						elseif text:find('Полка №1 | Свободна') then
							automining_getbtc = 2
						end
					else
					    automining_getbtc = 2
					end
				end
				if automining_getbtc == 2 then
				    if automining_getbtcstatus2 ~= nil then
						if automining_getbtcstatus2 < 1 then
							automining_getbtc = 3
						elseif text:find('Полка №2 | Свободна') then
							automining_getbtc = 3
						end
					else
					    automining_getbtc = 3
					end
				end
				if automining_getbtc == 3 then
					if automining_getbtcstatus3 ~= nil then
						if automining_getbtcstatus3 < 1 then
							automining_getbtc = 4
						elseif text:find('Полка №3 | Свободна') then
							automining_getbtc = 4
						end
					else
					    automining_getbtc = 4
					end
				end
				if automining_getbtc == 4 then
					if automining_getbtcstatus4 ~= nil then
						if automining_getbtcstatus4 < 1 then
							automining_getbtc = 10
							msg('Вся прибыль уже собрана.')
							worktread = lua_thread.create(PressAlt)
						elseif text:find('Полка №4 | Свободна') then
							automining_getbtc = 10
							msg('Вся прибыль уже собрана.')
							worktread = lua_thread.create(PressAlt)
						end
					else
					    automining_getbtc = 10					
					end
				end
				adID = automining_getbtc - 1
			    sampSendDialogResponse(269,1,adID,nil)				
            end				
			
			if automining_startall == 1 or automining_startall == 2 or automining_startall == 3 or automining_startall == 4 then
				if automining_startall == 1 then
				    if text:find('Полка №1 | {BEF781}Работает') then
						automining_startall = 2
					elseif text:find('Полка №1 | Свободна') then
					    automining_startall = 2
					end
				end
				if automining_startall == 2 then
				    if text:find('Полка №2 | {BEF781}Работает') then
				        automining_startall = 3
					elseif text:find('Полка №2 | Свободна') then
					    automining_startall = 3
					end
				end
				if automining_startall == 3 then
				    if text:find('Полка №3 | {BEF781}Работает') then
				        automining_startall = 4
					elseif text:find('Полка №3 | Свободна') then
					    automining_startall = 4
					end
				end
				if automining_startall == 4 then
				    if text:find('Полка №4 | {BEF781}Работает') then
				        automining_startall = 10
						msg('Все видеокарты уже запущены.')
					    worktread = lua_thread.create(PressAlt)
					elseif text:find('Полка №4 | Свободна') then
					    automining_startall = 10
					    msg('Все видеокарты уже запущены.')
					    worktread = lua_thread.create(PressAlt)
					end
				end			
				adID = automining_startall - 1
			    sampSendDialogResponse(269,1,adID,nil)
			end
			
            if automining_fillall == 1 or automining_fillall == 2 or automining_fillall == 3 or automining_fillall == 4 then
				if automining_fillall == 1 then
				    if automining_fillstatus1 ~= nil then
						if automining_fillstatus1 > 51 then
							automining_fillall = 2
						elseif text:find('Полка №1 | Свободна') then
							automining_fillall = 2
						end
					else
					    automining_fillall = 2
					end
				end
				if automining_fillall == 2 then
				  if automining_fillstatus2 ~= nil then
						if automining_fillstatus2 > 51 then
							automining_fillall = 3
						elseif text:find('Полка №2 | Свободна') then
							automining_fillall = 3
						end
					else
					    automining_fillall = 3
					end
				end
				if automining_fillall == 3 then
					if automining_fillstatus3 ~= nil then
						if automining_fillstatus3 > 51 then
							automining_fillall = 4
						elseif text:find('Полка №3 | Свободна') then
							automining_fillall = 4
						end
					else
					    automining_fillall = 4
					end
				end
				if automining_fillall == 4 then
					if automining_fillstatus4 ~= nil then
						if automining_fillstatus4 > 75 then
							automining_fillall = 10
							msg('В видеокартах более 75% жидкости.')
							worktread = lua_thread.create(PressAlt)
						elseif text:find('Полка №4 | Свободна') then
							automining_fillall = 10
							msg('В видеокартах более 75% жидкости.')
							worktread = lua_thread.create(PressAlt)
						end
					else
					    automining_fillall = 10
					end
				end			
				adID = automining_fillall - 1
			    sampSendDialogResponse(269,1,adID,nil)
			end			
		end
		
		text = table.concat(dtext,'\n')
        dtext = {}
        text = text .. '\n' .. ' '
		text = text .. '\n' .. color .. 'Информация\t' .. color .. 'Доступно снять\t' .. color .. 'Прибыль в час\t' .. color .. 'Прибыль прогнозируемая'
		text = text .. '\n' .. '{FFFFFF}Всего: '..automining_videocards..' | {FFFFFF}Работают: '..automining_videocardswork..'\t{FFFFFF}'..string.format("%.0f", automining_btcamountoverall)..' BTC\t{FFFFFF}'..automining_btcoverallph..' {FFFFFF}BTC\t{FFFFFF}'..string.format("%.1f", automining_btcoverall)..' {FFFFFF}BTC' 
			if title:find('Выберите видеокарту') then	
				if text:find('Полка №1 | Свободна') and text:find('Полка №2 | Свободна') and text:find('Полка №3 | Свободна') and text:find('Полка №4 | Свободна') then
					text = text .. '\n' .. ' '
					text = text .. '\n' .. color .. '>> {FFFFFF}На полках нет видеокарт, забрать прибыль не получится'
					text = text .. '\n' .. color .. '>> {FFFFFF}На полках нет видеокарт, включить видеокарты не получится'
					text = text .. '\n' .. color .. '>> {FFFFFF}На полках нет видеокарт, залить охлаждающую жидкость не получится'
				else
					text = text .. '\n' .. ' '
					text = text .. '\n' .. color .. '>> {FFFFFF}Собрать прибыль'
					text = text .. '\n' .. color .. '>> {FFFFFF}Запустить видеокарты'
					text = text .. '\n' .. color .. '>> {FFFFFF}Залить охлаждающую жидкость (по 1 шт.)'
				end
			end
		automining_btcoverall = 0
	    automining_btcoverallph = 0        		
		return {id, style, title, button1, button0, text}
		end
		
		if id == 270 then	    
		    if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				if title:find('Стойка №%d+%s+| Полка №'..automining_getbtc..'') then	
					local automining_btcamount = tonumber(text:match('Забрать прибыль %((%d+).%d+ '))
					if automining_btcamount ~= 0 then
						sampSendDialogResponse(270,1,1,nil) --   
					else
						automining_getbtc = automining_getbtc + 1
						sampSendDialogResponse(270,0,nil,nil)
						if automining_getbtc == 5 then
							msg('Прибыль добавлена вам в инвентарь.')
							automining_getbtc = 10
						end
					end
				else
				    sampSendDialogResponse(270,0,nil,nil)
					worktread = lua_thread.create(PressAlt)
				end
			end
			
		    if automining_startall == 1 or automining_startall == 2 or automining_startall == 3 or automining_startall == 4 then
				if text:find('Запустить видеокарту') and title:find('Стойка №%d+%s+| Полка №'..automining_startall..'') then
				    sampSendDialogResponse(270,1,0,nil)
				    automining_startall = automining_startall + 1
				    sampSendDialogResponse(270,0,nil,nil)
				else
				    sampSendDialogResponse(270,0,nil,nil)
				end
				if automining_startall == 5 then
					msg('Все видеокарты запущены.')
					automining_startall = 10
				end
			end

		    if automining_fillall == 1 or automining_fillall == 2 or automining_fillall == 3 or automining_fillall == 4 then
				if title:find('Стойка №%d+%s+| Полка №'..automining_fillall..'') then
				    sampSendDialogResponse(270,1,2,nil)
				    automining_fillall = automining_fillall + 1
				    worktread = lua_thread.create(PressAlt)
				else
				    worktread = lua_thread.create(PressAlt)
				end
				if automining_filltall == 5 then
					msg('Жидкость успешно залита.')
					sampSendDialogResponse(270,0,nil,nil)
					automining_startall = 10
					worktread = lua_thread.create(PressAlt)
				end
			end
	    end
		
	    if id == 271 and title:find('Вывод прибыли видеокарты') then
     		if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				automining_getbtc = automining_getbtc + 1
				sampSendDialogResponse(271,1,nil,nil) --   
				worktread = lua_thread.create(PressAlt)
					if automining_getbtc == 5 then
						msg('Прибыль добавлена вам в инвентарь.')
						automining_getbtc = 10
					end
				return false
				end
	    end			
		end
	end
	if checkboxes.cardlogin[0] and id == 782 then sampSendDialogResponse(782, 1, -1, ints.logincard[0]) end
	if checkboxes.ztimerstatus[0] then
		if id == 0 and title:find('Внимание!') then
				lua_thread.create(function() 
				msg('Вы помечены как опасный преступник, отсчёт 10 минут пошёл.')
				ztimer = 600
					while ztimer > 0 do
						printStringNow(u8'Z-Timer: ~r~~h~'..ztimer..' ~w~sec.', 1500) 
						ztimer = ztimer - 1
						wait(1000)
					end
				end)
				return false
		end
	end
	if id == 520 then 
		sampSendDialogResponse(520, 1, -1, "")
	end
	if checkboxes.autopay[0] then 
		if id == 756 then  --             
			sampSendDialogResponse(756, 1, 0, "")
		end
		
		if id == 672 or id == 671 then --              
			sampSendDialogResponse(id, 1, -1, nil) 
			sampCloseCurrentDialogWithButton(1)
			return false
		end
	end
end

function sampev.onSendDialogResponse(id, button, list, input)
	if checkboxes.mininghelper[0] then
	  if id == 269 and list == 8 and button == 1 then
		    automining_getbtc = 1
	        worktread = lua_thread.create(PressAlt)
			msg('Сбор прибыли, ожидайте...')
		end
		if id == 269 and list == 9 and button == 1 then
		    automining_startall = 1
	        worktread = lua_thread.create(PressAlt)
			msg('Видеокарты запускаются, ожидайте...')
		end
		if id == 269 and list == 10 and button == 1 then
		    automining_fillall = 1
	        worktread = lua_thread.create(PressAlt)
			msg('Система охлаждения восполняется по 50%, ожидайте...')
		end	
	end
end

function PressAlt()
    time = os.time()
	repeat wait(500)
		local _, idplayer = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local data = allocateMemory(68)
		sampStorePlayerOnfootData(idplayer, data)
		setStructElement(data, 4, 2, 1024, false)
		sampSendOnfootData(data)
		freeMemory(data)
    until os.time() >= time+5
end

function sampev.onServerMessage(color, text)
		if checkboxes.drugstimer[0] and text:find('Здоровье пополнено на') and not text:find('говорит:') then
				lua_thread.create(function() 
				printStringNow(u8'DRUGS: Timer started.', 5000)
				wait(20000)
				printStringNow(u8'DRUGS: 40 sec.', 5000)
				wait(20000)
				printStringNow(u8'DRUGS: 20 sec.', 5000)
				wait(15000)
				printStringNow(u8'DRUGS: 5 sec.', 3000)
				wait(5000)
				printStringNow(u8'DRUGS: GO GO GO!', 3000)
				end)
		end
		if checkboxes.antilomka[0] and text:find('У вас началась ломка') and not text:find('говорит:') then
			send('/usedrugs 1')
		end
		bushelpermsg()
		minehelpermsg()
		farmhelpermsg()
end

function sampev.onServerMessage(color, text) --jobhelper
	if checkboxes.bus[0] then
			if text:find('^Премия за посадку пассажиров:') and not text:find('говорит:') then
	        local premia = text:match('(%d+)')
	        bhsalary = bhsalary + premia
	    elseif text:find('Вам добавлено: предмет "Ларец водителя автобуса". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        bhcases = bhcases + 1
	    elseif text:find('Вам добавлено: предмет "Кусок чертежа". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        bhchert = bhchert + 1
	    elseif text:find('Автобус по маршруту') and not text:find('говорит:') then
	        bhstop = bhstop + 1
	    end
	end
	if checkboxes.mine[0] then
			if text:find('Вам добавлено: предмет "Камень". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhstone = mhstone + 1
	    elseif text:find('Вам добавлено: предмет "Камень" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhstone = mhstone + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('Вам добавлено: предмет "Металл". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhmetall = mhmetall + 1
	    elseif text:find('Вам добавлено: предмет "Металл" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhmetall = mhmetall + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('Вам добавлено: предмет "Бронза". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhmetall = mhbronze + 1
	    elseif text:find('Вам добавлено: предмет "Бронза" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhbronze = mhbronze + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('Вам добавлено: предмет "Серебро". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhmetall = mhsilver + 1
	    elseif text:find('Вам добавлено: предмет "Серебро" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhmetall = mhsilver + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('Вам добавлено: предмет "Золото". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhgold = mhgold + 1
	    elseif text:find('Вам добавлено: предмет "Золото" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhgold = mhgold + tonumber(text:match("(%d+) шт"))  
	    end
	  end
	  if checkboxes.farm[0] then
			if text:find('^Вам добавлено: предмета "Хлопок" %((%d+) шт%). Чтобы открыть инвентарь,') then
	        fhlyon = fhlyon + 1
	    elseif text:find('^Вам добавлено: предметов "Хлопок" %((%d+) шт%). Чтобы открыть инвентарь,') or text:find('^Вам добавлено: предмета "Лён" %((%d+) шт%). Чтобы открыть инвентарь,') then
	    		fhlyon = fhlyon + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('^Вам добавлено: предмет "Хлопок". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        fhhlopok = fhhlopok + 1
	    elseif text:find('^Вам добавлено: предмета "Хлопок" %((%d+) шт%). Чтобы открыть инвентарь,') or text:find('^Вам добавлено: предметов "Хлопок" %((%d+) шт%). Чтобы открыть инвентарь,') then
	    		fhhlopok = fhhlopok + tonumber(text:match("(%d+) шт"))  
	  	end
		end
		if checkboxes.fish[0] then
			if text:find('Вам добавлено: предмет "Ларец рыболова". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        fishcase = fishcase + 1
	    elseif text:find('Вам добавлено: предмет "Рыба (%A+)". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		fishsalary = fishsalary + 15000 
	    end
	end
end


keyboards = {
	{ --     NumPad
		{
			{'Esc', 0x1B},
			{'F1', 0x70},
			{'F2', 0x71},
			{'F3', 0x72},
			{'F4', 0x73},
			{'F5', 0x74},
			{'F6', 0x75},
			{'F7', 0x76},
			{'F8', 0x77},
			{'F9', 0x78},
			{'F10', 0x79},
			{'F11', 0x7A},
			{'F12', 0x7B},
		},
		{
			{'`', 0xC0},
			{'1', 0x31},
			{'2', 0x32},
			{'3', 0x33},
			{'4', 0x34},
			{'5', 0x35},
			{'6', 0x36},
			{'7', 0x37},
			{'8', 0x38},
			{'9', 0x39},
			{'0', 0x30},
			{'-', 0xBD},
			{'+', 0xBB},
			{'<-', 0x08},
			{'Ins', 0x2D},
			{'Home', 0x24},
			{'PU', 0x21},
		},
		{
			{'Tab', 0x09},
			{'Q', 0x51},
			{'W', 0x57},
			{'E', 0x45},
			{'R', 0x52},
			{'T', 0x54},
			{'Y', 0x59},
			{'U', 0x55},
			{'I', 0x49},
			{'O', 0x4F},
			{'P', 0x50},
			{'[', 0xDB},
			{']', 0xDD},
			{'\\', 0xDC},
			{'Del', 0x2E},
			{'End', 0x23},
			{'PD', 0x22},
		},
		{
			{'Caps ', 0x14},
			{'A', 0x41},
			{'S', 0x53},
			{'D', 0x44},
			{'F', 0x46},
			{'G', 0x47},
			{'H', 0x48},
			{'J', 0x4A},
			{'K', 0x4B},
			{'L', 0x4C},
			{';', 0xBA},
			{'\'', 0xDE},
			{' Enter ', 0x0D},
		},
		{
			{' LShift  ', 0xA0},
			{'Z', 0x5A},
			{'X', 0x58},
			{'C', 0x43},
			{'V', 0x56},
			{'B', 0x42},
			{'N', 0x4E},
			{'M', 0x4D},
			{',', 0xBC},
			{'.', 0xBE},
			{'/', 0xBF},
			{' RShift  ', 0xA1, 33},
			{'/\\', 0x26},
		},
		{
			{'Ctrl', 0xA2},
			{'Win', 0x5B},
			{'Alt', 0xA4},
			{'                              ', 0x20}, -- ??
			{'Alt', 0xA5},
			{'Win', 0x5C},
			{'Ctrl', 0xA3, 10},
			{'<', 0x25},
			{'\\/', 0x28},
			{'>', 0x27},
		}
	},
	{ --             
		{
			{'1', 0x31},
			{'2', 0x32},
			{'3', 0x33},
			{'4', 0x34},
			{'5', 0x35},
			{'6', 0x36},
			{'7', 0x37},
			{'8', 0x38},
			{'9', 0x39},
			{'0', 0x30},
		},
		{
			{'N', 0x4E},
			{' Enter ', 0x0D},
		}
	}
}


function sampev.onCreate3DText(id, col, pos, allowed_dist, los, plid, vehid, text)
    if DistanceManager then
        return DistanceManager.onCreate3DText(id, col, pos, allowed_dist, los, plid, vehid, text)
    end
end

function sampev.onPlayerChatBubble(id, col, allowed_dist, dur, text)
    if DistanceManager then
        return DistanceManager.onPlayerChatBubble(id, col, allowed_dist, dur, text)
    end
end
