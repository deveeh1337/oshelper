-- script
script_name('OS Helper')
script_version('1.3 beta')
script_author('deveeh')

-- libraries
require 'lib.moonloader'
local imgui = require('imgui')
local dlstatus = require('moonloader').download_status
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local fa = require 'fAwesome5'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'

function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end

-- cfg
local direct = 'moonloader\\config\\OSHelper.ini'
local cfg = inicfg.load({
	settings = {
		color = '',
		active = 0,
		cheatcode = 'oh',
		theme = 0,
		time = 0,
		weather = 15,
		cmds = false,
		armor = false,
		med = false,
		drugs = false,
		rem = false,
		fill = false,
		mask = false,
		fmenu = false,
		finv = false,
		lock = false,
		autolock = false,
		timeweather = false,
		cardlogin = false,
		spawn = false,
		prmanager = false,
		vr1 = false,
		prstring = false,
		vr2 = false,
		fam = false,
		al = false,
		vrmsg1 = ' ',
		fammsg = ' ',
		admsg1 = ' ',
		stringmsg = ' ',
		adbox = false,
		adbox2 = false,
		plusw = false,
		delay = 30,
		logincard = 123456,
	}
}, "OSHelper")

-- variables
local window = imgui.ImBool(false)
local prmwindow = imgui.ImBool(false)
local color = cfg.settings.color
local textcolor = '{c7c7c7}'
local active = imgui.ImInt(cfg.settings.active)
local time = imgui.ImInt(cfg.settings.time)
local weather = imgui.ImInt(cfg.settings.weather)
local cheatcode = imgui.ImBuffer(''..cfg.settings.cheatcode, 256)
local vrmsg1 = imgui.ImBuffer(''..cfg.settings.vrmsg1, 256)
local vrmsg2 = imgui.ImBuffer(256)
local vr1 = imgui.ImBool(cfg.settings.vr1)
local vr2 = imgui.ImBool(cfg.settings.vr2)
local fammsg = imgui.ImBuffer(''..cfg.settings.fammsg, 256)
local prstring = imgui.ImBool(cfg.settings.prstring)
local stringmsg = imgui.ImBuffer(''..cfg.settings.stringmsg, 256)
local almsg = imgui.ImBuffer(256)
local adbox = imgui.ImBool(cfg.settings.adbox)
local adbox2 = imgui.ImBool(cfg.settings.adbox2)
local admsg1 = imgui.ImBuffer(''..cfg.settings.admsg1, 256)
local admsg2 = imgui.ImBuffer(256)
local fam = imgui.ImBool(cfg.settings.fam)
local al = imgui.ImBool(cfg.settings.al)
local theme = imgui.ImInt(cfg.settings.theme)
local cmds = imgui.ImBool(cfg.settings.cmds)
local armor = imgui.ImBool(cfg.settings.armor)
local med = imgui.ImBool(cfg.settings.med)
local drugs = imgui.ImBool(cfg.settings.drugs)
local rem = imgui.ImBool(cfg.settings.rem)
local fill = imgui.ImBool(cfg.settings.fill)
local mask = imgui.ImBool(cfg.settings.mask)
local fmenu = imgui.ImBool(cfg.settings.fmenu)
local finv = imgui.ImBool(cfg.settings.finv)
local lock = imgui.ImBool(cfg.settings.lock)
local autolock = imgui.ImBool(cfg.settings.autolock)
local cardlogin = imgui.ImBool(cfg.settings.cardlogin)
local spawn = imgui.ImBool(cfg.settings.spawn)
local logincard = imgui.ImInt(cfg.settings.logincard)
local delay = imgui.ImInt(cfg.settings.delay)
local plusw = imgui.ImBool(cfg.settings.plusw)
local prmanager = imgui.ImBool(cfg.settings.prmanager)
local timeweather = imgui.ImBool(cfg.settings.timeweather)
local pronoroff = false
local menu = 1

bike = {[481] = true, [509] = true, [510] = true}
moto = {[448] = true, [461] = true, [462] = true, [463] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true, [1823] = true, [1913] = true, [1912] = true, [1947] = true, [1948] = true, [1949] = true, [1950] = true, [1951] = true, [1982] = true, [2006] = true}

-- functions
function msg(arg)
	sampAddChatMessage(color..'[OS Helper] {FFFFFF}'..textcolor..arg..'', -1)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

local fontsize = nil
function imgui.BeforeDrawFrame()
	if fa_font == nil then
		local font_config = imgui.ImFontConfig()
		font_config.MergeMode = true
		fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0, font_config, fa_glyph_ranges)
	end
	if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 16.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
end

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
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.Button], name)
	end
	return resultBtn
end


function imgui.TextQuestion(text)
	imgui.SameLine()
	imgui.TextDisabled('(?)')
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
	inicfg.save(cfg, 'OSHelper.ini')
end

function imgui.offset(text)
    local offset = 130
    imgui.Text(text)
    imgui.SameLine()
    imgui.SetCursorPosX(offset)
    imgui.PushItemWidth(190)
end
function imgui.prmoffset(text)
    local offset = 87
    imgui.Text(text)
    imgui.SameLine()
    imgui.SetCursorPosX(offset)
    imgui.PushItemWidth(190)
end

function imgui.InputTextWithHint(label, hint, buf, flags, callback, user_data)
    local l_pos = {imgui.GetCursorPos(), 0}
    local handle = imgui.InputText(label, buf, flags, callback, user_data)
    l_pos[2] = imgui.GetCursorPos()
    local t = (type(hint) == 'string' and buf.v:len() < 1) and hint or '\0'
    local t_size, l_size = imgui.CalcTextSize(t).x, imgui.CalcTextSize('A').x
    imgui.SetCursorPos(imgui.ImVec2(l_pos[1].x + 8, l_pos[1].y + 2))
    imgui.TextDisabled((imgui.CalcItemWidth() and t_size > imgui.CalcItemWidth()) and t:sub(1, math.floor(imgui.CalcItemWidth() / l_size)) or t)
    imgui.SetCursorPos(l_pos[2])
    return handle
end

-- main
function main()
    while not isSampAvailable() do wait(200) end
    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    autoupdate("https://raw.githubusercontent.com/deveeh/oshelper/master/update.json", '['..string.upper(thisScript().name)..']: ', "")
    if not doesFileExist(getWorkingDirectory()..'\\config\\OSHelper.ini') then inicfg.save(cfg, 'OSHelper.ini') end
    imgui.Process = false
    window.v = false  --show window
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
    sampRegisterChatCommand('pr', function()
		if prmanager.v then pronoroff = not pronoroff; msg(pronoroff and 'Реклама включена.' or 'Реклама выключена.') end
		lua_thread.create(function()
			if pronoroff and prmanager.v then piar() local delay = cfg.settings.delay * 1000 wait(delay) return true end 
		end)
	end)
	    sampRegisterChatCommand('fh', function(num)
	    	if cmds.v then 
				sampSendChat('/findihouse '..num) 
			end
		end)
		sampRegisterChatCommand('fbiz', function(num) 
			if cmds.v then 
				sampSendChat('/findibiz '..num) 
			end
		end)
	        sampRegisterChatCommand('biz', function() 
	        if cmds.v then 
				sampSendChat('/bizinfo') 
			end
		end)
		sampRegisterChatCommand('car', function(num)
			if cmds.v then  
				sampSendChat('/fixmycar '..num) 
			end
		end) 
		sampRegisterChatCommand('urc', function(num)
			if cmds.v then  
				sampSendChat('/unrentcar'..num) 
			end
		end)
		sampRegisterChatCommand('fin', function(arg)
			if cmds.v then 
			    if arg:find('(%d+) (%d+)') then
			        arg1, arg2 = arg:match('(.+) (.+)')
			        sampSendChat('/showbizinfo '..arg1..' '..arg2) -- 2+ аргумента
			    else
			        msg('/fin [id игрока] [id бизнеса]', -1)
			    end
			end
		end)
		sampRegisterChatCommand('oshelper', function() 
			if active.v == 0 then 
				window.v = not window.v 
			end 
		end)
		sampRegisterChatCommand('prm', function() 
			prmwindow.v = not prmwindow.v  
		end)
    local ip, port = sampGetCurrentServerAddress()
	if ip == '185.169.134.163' and port == 7777 then serverName = 'Rodina RP | Central District'
	elseif ip == '185.169.134.60' and port == 7777 then serverName = 'Rodina RP | Southern District'
	elseif ip == '185.169.134.62' and port == 7777 then serverName = 'Rodina RP | Northern District'
	elseif ip == '185.169.134.108' and port == 7777 then serverName = 'Rodina RP | Eastern District'
	end
    while true do
        wait(0)
        if timeweather.v then
      		setTimeOfDay(time.v, 0)
      		forceWeatherNow(weather.v)
    	end
        inicfg.save(cfg, 'OSHelper.ini')
        if cfg.settings.cheatcode == '' then cfg.settings.cheatcode = 'oh' cheatcode = imgui.ImBuffer(tostring(cfg.settings.cheatcode), 256) end
    	if active.v == 1 and testCheat(cfg.settings.cheatcode) then window.v = not window.v end
        imgui.Process = window.v or prmwindow.v
        -- hotkeys
        if not sampIsCursorActive() then
        	if mask.v and isKeyDown(0x12) and wasKeyPressed(0x32) then send('/mask') end
        	if spawn.v and wasKeyPressed(0x04) then 
        		if not isCharOnFoot(playerPed) then
                car = storeCarCharIsInNoSave(playerPed)
                _, carid = sampGetVehicleIdByCarHandle(car)
                send('/fixmycar '..carid) 
            	end
			end
	     	if med.v and isKeyDown(0x12) and wasKeyPressed(0x34) then send('/usemed') end
	     	if armor.v and isKeyDown(0x12) and wasKeyPressed(0x31) then
	     		local armourlvl = sampGetPlayerArmor(id)
	     		if armourlvl > 89 then 
		     		msg('У вас '..armourlvl..' процентов брони.')
		     	elseif armourlvl > 0 then
		     		lua_thread.create(function() 
		     			send('/armour')
		     			wait(500)
		     			send('/armour')
		     		end)
		     	elseif armourlvl == 0 then
		     		send('/armour')
		     	end
	     	end
	     	if drugs.v and isKeyDown(0x12) and wasKeyPressed(0x33) then send('/usedrugs 3') end
	     	if rem.v and wasKeyPressed(0x52) then send('/repcar') end
	     	if fill.v and isKeyDown(0x12) and wasKeyPressed(0x52) then send('/fillcar') end
	     	if finv.v and isKeyDown(0x46) and wasKeyPressed(0x31) then local veh, ped = storeClosestEntities(PLAYER_PED) send('/faminvite '..id) end
	     	if fmenu.v and wasKeyPressed(0x4F) then send('/fammenu') end
	     	if lock.v and wasKeyPressed(0x4C) then send('/lock') end
	    end
	    if plusw.v then
		    if isCharOnAnyBike(playerPed) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isKeyDown(0x57) then	-- onBike&onMoto SpeedUP [[LSHIFT]] --
				if bike[getCarModel(storeCarCharIsInNoSave(playerPed))] then
					setGameKeyState(16, 255)
					wait(10)
					setGameKeyState(16, 0)
				elseif moto[getCarModel(storeCarCharIsInNoSave(playerPed))] then
					setGameKeyState(1, -128)
					wait(10)
					setGameKeyState(1, 0)
				end
			end	
		end		
    end
end

-- code
function sampev.onSendEnterVehicle(id, pass)
	if autolock.v then
	    lua_thread.create(function()
	        --while not isCharInAnyCar(PLAYER_PED) do wait(0) end
	        if not isCharInAnyCar(PLAYER_PED) then
	        wait(3000)
	        sampSendChat('/engine')
	        wait(500)
	        sampSendChat('/lock')
	    end
	    end)
	end
end

function sampev.onSendExitVehicle(id)
	idcar = 0
	if autolock.v then
	    lua_thread.create(function()
	        if isCharInAnyCar(PLAYER_PED) then
	        	wait(500)
	        	sampSendChat('/engine') 
	        else 
	            sampAddChatMessage('not in car', -1) 
	        end
	    end)
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

function piar()
	lua_thread.create(function()
			if pronoroff and vr1.v then
				send('/vr '..u8:decode(vrmsg1.v))
			end
			wait(1000)
			if pronoroff and fam.v then
					send('/fam '..u8:decode(fammsg.v))
			end
			wait(1000)
			if pronoroff and adbox.v then
				send('/ad 1 '..u8:decode(admsg1.v))
			end
			wait(3000)
			if pronoroff and prstring.v then
				send(u8:decode(stringmsg.v))
			end


	end)
end

function sampev.onShowDialog(id, style, title, button1, button0, text)
	if cardlogin.v then if id == 991 then sampSendDialogResponse(991, 1, -1, logincard.v) end end
end
-- imgui
function imgui.OnDrawFrame()
	local resX, resY = getScreenResolution()
	local sizeX, sizeY = 500.0, 325.0
	if cfg.settings.theme == 0 then themeSettings(1) color = '{ff4747}'
	elseif cfg.settings.theme == 1 then themeSettings(3) cfg.settings.color = '{00bd5c}'
	elseif cfg.settings.theme == 2 then themeSettings(2) color = '{e8a321}'
	else cfg.settings.theme = 4 themeSettings(1) color = '{ff4747}'
	end
    if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 325), imgui.Cond.FirstUseEver)
        imgui.Begin('OS Helper', window, imgui.WindowFlags.NoResize)
	        imgui.BeginChild("left", imgui.ImVec2(150, 290), true)
				if imgui.Selectable(fa.ICON_FA_USER..u8' Персонаж', menu == 1) then menu = 1
				elseif imgui.Selectable(fa.ICON_FA_CAR..u8' Транспорт', menu == 2) then menu = 2
				elseif imgui.Selectable(fa.ICON_FA_USERS..u8' Семья', menu == 3) then menu = 3
				elseif imgui.Selectable(fa.ICON_FA_GLOBE..u8' Окружение', menu == 8) then menu = 8
				elseif imgui.Selectable(fa.ICON_FA_COMMENTS..u8' Работа с чатом', menu == 4) then menu = 4
				elseif imgui.Selectable(fa.ICON_FA_WINDOW_MAXIMIZE..u8' Работа с диалогами', menu == 5) then menu = 5
				elseif imgui.Selectable(fa.ICON_FA_COG..u8' Настройки', menu == 6) then menu = 6
				elseif imgui.Selectable(fa.ICON_FA_INFO_CIRCLE..u8' Информация', menu == 7) then menu = 7
				end
				imgui.SetCursorPosY(265)
		        if updateversion ~= thisScript().version then
		        	lua_thread.create(function()
			        	if imgui.Button(u8'Обновить', imgui.ImVec2(135, 20)) then
				               	autoupdate("https://raw.githubusercontent.com/deveeh/oshelper/master/update.json", '['..string.upper(thisScript().name)..']: ', "")
				                    msg("Скрипт успешно обновлен до версии "..updateversion.."!" , -1)
				                    thisScript():reload()
			        	end
		        	end)
		        else
		        	if imgui.Button(u8'Сохранить', imgui.ImVec2(135, 20)) then
		        		save()
						msg('Все настройки сохранены.')
		        	end
		        end
			imgui.EndChild()
			imgui.SameLine()
			imgui.BeginChild('right', imgui.ImVec2(325, 290), true)
			if menu == 1 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Персонаж')
        		imgui.PopFont()
        		imgui.Separator()
        		if imgui.Checkbox(u8'Умный бронежилет', armor) then cfg.settings.armor = armor.v end
				imgui.TextQuestion(u8'Описание:\nОбновляет бронежилет, если у вас меньше 90 хп\nИспользовать бронежилет: ALT + 1')
				if imgui.Checkbox(u8'Маска', mask) then cfg.settings.mask = mask.v end
				imgui.TextQuestion(u8'Использовать нарко: ALT + 2')
				if imgui.Checkbox(u8'Наркотики (3 шт)', drugs) then cfg.settings.drugs = drugs.v end
				imgui.TextQuestion(u8'Использовать нарко: ALT + 3')
				if imgui.Checkbox(u8'Аптечка', med) then cfg.settings.med = med.v end
				imgui.TextQuestion(u8'Использовать аптечку: ALT + 4')
			end
			if menu == 2 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Транспорт')
        		imgui.PopFont()
        		imgui.Separator()
				if imgui.Checkbox(u8'AutoCar', autolock) then cfg.settings.autolock = autolock.v end
				imgui.TextQuestion(u8'Активация: сесть в машину\nАвтоматическое закрытие дверей + включение двигателя')
				if imgui.Checkbox(u8'Открыть/Закрыть двери', lock) then cfg.settings.lock = lock.v end
				imgui.TextQuestion(u8'Активация: L')
				if imgui.Checkbox(u8'Ремкомплект', rem) then cfg.settings.rem = fill.v end
				imgui.TextQuestion(u8'Использовать ремкомплект: R')
				if imgui.Checkbox(u8'Канистра', fill) then cfg.settings.fill = fill.v end
				imgui.TextQuestion(u8'Использовать канистру: ALT + R')
				if imgui.Checkbox(u8'Спавн транспорта', spawn) then cfg.settings.spawn = spawn.v end
				imgui.TextQuestion(u8'Использование: Колесико Мыши (нажатие)')
				if imgui.Checkbox(u8'+W moto/bike', plusw) then cfg.settings.plusw = plusw.v end
				imgui.TextQuestion(u8'Использование: W (зажатие)\nКликер для велосипедов и мотоциклов')

			end
			if menu == 3 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Семья')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Меню семьи', fmenu) then cfg.settings.fmenu = fmenu.v end
				imgui.TextQuestion(u8'Активация: O')
				if imgui.Checkbox(u8'Инвайт в семью', finv) then cfg.settings.finv = finv.v end
				imgui.TextQuestion(u8'Активация: F + 1')
			end
			if menu == 4 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Работа с чатом')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'PR Manager', prmanager) then cfg.settings.prmanager = prmanager.v end
				imgui.TextQuestion(u8'Меню: /prm')
				if imgui.Checkbox(u8'Сокращенные команды', cmds) then cfg.settings.cmds = cmds.v save() end
				if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                        imgui.Text(u8'/biz - /bizinfo\n/car [id] - /fixmycar\n/fh [id] - /findihouse\n/fbiz [id] - /findibiz\n/urc - /unrentcar\n/fin [id] [id biz] - /showbizinfo')
                    imgui.EndTooltip()
                end
			end
			if menu == 5 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Работа с диалогами')
        		imgui.PopFont()
        			imgui.CenterText(u8'Не работает с новыми диалогами!')
				imgui.Separator()
				if imgui.Checkbox(u8'Автологин в банке', cardlogin) then cfg.settings.cardlogin = cardlogin.v end
				if cardlogin.v then 
				imgui.Text(u8'Пин-код:')
				imgui.SameLine()
				imgui.PushItemWidth(54.5) 
				if imgui.InputInt(u8'##логин банк', logincard, 0, 0) then cfg.settings.logincard = logincard.v end
				end
				--imgui.TextQuestion(u8'Активация: ALT + F')
			end
			if menu == 6 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Настройки')
        		imgui.PopFont()
				imgui.Separator()
				imgui.offset(u8'Активация меню: ') 
			if imgui.Combo(u8'##Активация', active, {u8'Команда', u8'Чит-код'}, -1) then cfg.settings.active = active.v save() end
			if imgui.IsItemHovered() then
	            imgui.BeginTooltip()
	                imgui.Text(u8'После изменения режима активации, сохраните и перезагрузите скрипт.')
	            imgui.EndTooltip()
            end
				if active.v == 1 then
					imgui.offset(u8' Чит-код: ')
					--if imgui.InputText(u8'##Чит-код', cheatcode) then cfg.settings.cheatcode = cheatcode.v save() end
					if imgui.InputTextWithHint(u8"##Чит Код", cfg.settings.cheatcode, cheatcode) then cfg.settings.cheatcode = cheatcode.v end
				end
				--if cheatcode.v == '' then cheatcode.v = 'oh' cfg.settings.cheatcode = 'oh' end
				imgui.offset(u8'Цвет темы: ') 
					if imgui.Combo(u8'##Тема', theme, {u8'Красный', u8'Зеленый', u8'Желтый'}, -1) then cfg.settings.theme = theme.v save()
					if cfg.settings.theme == 0 then themeSettings(1) color = '{ff4747}'
					elseif cfg.settings.theme == 1 then themeSettings(3) color = '{00b052}'
					elseif cfg.settings.theme == 2 then themeSettings(2) color = '{e8a321}'
					else cfg.settings.theme = 3 themeSettings(1) color = '{ff4747}' 
					end
				end
				imgui.SetCursorPosX(89)
				--[[if imgui.Button(u8'RELOAD', imgui.ImVec2(150, 20)) then
					showCursor(false, false)
           			thisScript():reload()
        		end]]--
			end
			if menu == 7 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Информация')
        		imgui.PopFont()
				imgui.Separator()
				imgui.Text(fa.ICON_FA_ADDRESS_CARD..u8' Авторы:') imgui.SameLine() imgui.Link('https://vk.com/deveeh', 'deveeh') imgui.SameLine() imgui.Text(u8'и') imgui.SameLine() imgui.Link('https://t.me/atimohov', 'casparo')
			end
			if menu == 8 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Окружение')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Редактор времени и погоды', timeweather) then cfg.settings.timeweather = timeweather.v end
				if timeweather.v then
					imgui.PushItemWidth(75)
					imgui.Text(u8'Время: ')
					imgui.SameLine()
					imgui.SetCursorPosX(62)
					if imgui.InputInt(u8'##time', time) then
						if time.v > 24 then
							time.v = 24
							cfg.settings.time = time.v 
							patch_samp_time_set(true)
						elseif time.v < 0 then
							time.v = 0
							cfg.settings.time = time.v 
							patch_samp_time_set(true)
						end
					end
					imgui.Text(u8'Погода: ')
					imgui.SameLine()
					if imgui.InputInt(u8'##weather', weather) then
						if weather.v < 0 then
							weather.v = 0 
							cfg.settings.weather = weather.v 
						elseif weather.v > 45 then
							weather.v = 45 
							cfg.settings.weather = weather.v
						end

					end
				end
			end
			imgui.EndChild()
        imgui.End()
    end
    if prmwindow.v then
    	imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(300, 400), imgui.Cond.FirstUseEver)
    	imgui.Begin('OS Helper##prmenu', prmwindow, imgui.WindowFlags.NoResize)
    		imgui.PushFont(fontsize)
        			imgui.CenterText(u8'PR Manager | Menu')
        			imgui.CenterText(u8'Активация /prааааа')
        	imgui.PopFont()
        	imgui.Separator()
        	if prmanager.v then
	        	if imgui.Checkbox(u8'Реклама в VIP CHAT (/vr)', vr1) then cfg.settings.vr1 = vr1.v end
				if vr1.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##vr1", u8"Работает БК Лыткарино №56!", vrmsg1) then cfg.settings.vrmsg1 = vrmsg1.v end
					end
				if imgui.Checkbox(u8'Реклама в FAMILY CHAT (/fam, /al)', fam) then cfg.settings.fam = fam.v end
				if fam.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##fammsg", u8"Работает Ломбард №240!", fammsg) then cfg.settings.fammsg = fammsg.v end
					end
				if imgui.Checkbox(u8'Реклама в AD (/ad 1)', adbox) then cfg.settings.adbox = adbox.v end
				if adbox.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##admsg1", u8"Работает БК Лыткарино №56!", admsg1) then cfg.settings.admsg1 = admsg1.v end
					end
				if imgui.Checkbox(u8'Дополнительная строка', prstring) then cfg.settings.prstring = prstring.v end
				if prstring.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##prstring", u8"/vr Работает Ломбард №240!", stringmsg) then cfg.settings.stringmsg = stringmsg.v end
					end
				imgui.Separator()
				imgui.Text(u8'					Задержка: ')
				imgui.SameLine()
				imgui.PushItemWidth(40)
				if imgui.InputInt("##Задержка", delay, 0, 0) then cfg.settings.delay = delay.v end
				imgui.SameLine() 
				imgui.Text(u8'сек.')			
		    else
		    	imgui.CenterText(u8'Включите в главном меню функцию PR Manager.')
		    end
		    imgui.SetCursorPos(imgui.ImVec2(5, 375))
		    if imgui.Button(u8'Сохранить', imgui.ImVec2(290, 20)) then
		        save()
		        msg('Все настройки сохранены.')
		    end

    	imgui.End()
   	end
end

-- theme
function themeSettings(theme)
 imgui.SwitchContext()
 local style = imgui.GetStyle()
 local ImVec2 = imgui.ImVec2

 style.WindowPadding = imgui.ImVec2(8, 8)
 style.WindowRounding = 6
 style.ChildWindowRounding = 5
 style.FramePadding = imgui.ImVec2(5, 3)
 style.FrameRounding = 3.0
 style.ItemSpacing = imgui.ImVec2(5, 4)
 style.ItemInnerSpacing = imgui.ImVec2(4, 4)
 style.IndentSpacing = 21
 style.ScrollbarSize = 10.0
 style.ScrollbarRounding = 13
 style.GrabMinSize = 8
 style.GrabRounding = 1
 style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
 style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	 if theme == 1 or nil then
	 	local style = imgui.GetStyle()
		local colors = style.Colors
		local clr = imgui.Col
		local ImVec4 = imgui.ImVec4
		colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
		colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
		colors[clr.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
		colors[clr.ChildWindowBg]          = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
		colors[clr.Border]                 = ImVec4(0.14, 0.14, 0.14, 1.00);
		colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
		colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
		colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
		colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
		colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
		colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
		colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
		colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
		colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
		colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.Button]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
		colors[clr.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
		colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
		colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
		colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
		colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
		colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
		colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
		colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
		colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
		colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
		colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
		colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
		colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
		colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
		colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
	elseif theme == 2 then
		local style = imgui.GetStyle()
	    local colors = style.Colors
	    local clr = imgui.Col
	    local ImVec4 = imgui.ImVec4
	    colors[clr.Text]                 = ImVec4(0.92, 0.92, 0.92, 1.00)
	    colors[clr.TextDisabled]         = ImVec4(0.44, 0.44, 0.44, 1.00)
	    colors[clr.WindowBg]             = ImVec4(0.06, 0.06, 0.06, 1.00)
	    colors[clr.ChildWindowBg]        = ImVec4(0.00, 0.00, 0.00, 0.00)
	    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
	    colors[clr.ComboBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
	    colors[clr.Border]               = ImVec4(0.51, 0.36, 0.15, 1.00)
	    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	    colors[clr.FrameBg]              = ImVec4(0.11, 0.11, 0.11, 1.00)
	    colors[clr.FrameBgHovered]       = ImVec4(0.51, 0.36, 0.15, 1.00)
	    colors[clr.FrameBgActive]        = ImVec4(0.78, 0.55, 0.21, 1.00)
	    colors[clr.TitleBg]              = ImVec4(0.51, 0.36, 0.15, 1.00)
	    colors[clr.TitleBgActive]        = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
	    colors[clr.MenuBarBg]            = ImVec4(0.11, 0.11, 0.11, 1.00)
	    colors[clr.ScrollbarBg]          = ImVec4(0.06, 0.06, 0.06, 0.53)
	    colors[clr.ScrollbarGrab]        = ImVec4(0.21, 0.21, 0.21, 1.00)
	    colors[clr.ScrollbarGrabHovered] = ImVec4(0.47, 0.47, 0.47, 1.00)
	    colors[clr.ScrollbarGrabActive]  = ImVec4(0.81, 0.83, 0.81, 1.00)
	    colors[clr.CheckMark]            = ImVec4(0.78, 0.55, 0.21, 1.00)
	    colors[clr.SliderGrab]           = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.SliderGrabActive]     = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.Button]               = ImVec4(0.51, 0.36, 0.15, 1.00)
	    colors[clr.ButtonHovered]        = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.ButtonActive]         = ImVec4(0.78, 0.55, 0.21, 1.00)
	    colors[clr.Header]               = ImVec4(0.51, 0.36, 0.15, 1.00)
	    colors[clr.HeaderHovered]        = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.HeaderActive]         = ImVec4(0.93, 0.65, 0.14, 1.00)
	    colors[clr.Separator]            = ImVec4(0.21, 0.21, 0.21, 1.00)
	    colors[clr.SeparatorHovered]     = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.SeparatorActive]      = ImVec4(0.78, 0.55, 0.21, 1.00)
	    colors[clr.ResizeGrip]           = ImVec4(0.21, 0.21, 0.21, 1.00)
	    colors[clr.ResizeGripHovered]    = ImVec4(0.91, 0.64, 0.13, 1.00)
	    colors[clr.ResizeGripActive]     = ImVec4(0.78, 0.55, 0.21, 1.00)
	    colors[clr.CloseButton]          = ImVec4(0.47, 0.47, 0.47, 1.00)
	    colors[clr.CloseButtonHovered]   = ImVec4(0.98, 0.39, 0.36, 1.00)
	    colors[clr.CloseButtonActive]    = ImVec4(0.98, 0.39, 0.36, 1.00)
	    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
	    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
	    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
	    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	    colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
	    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
	elseif theme == 3 then
		local style = imgui.GetStyle()
		local colors = style.Colors
		local clr = imgui.Col
		local ImVec4 = imgui.ImVec4
	    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
	    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
	    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
	    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
	    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
	    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
	    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
	    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
	    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
	    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
	    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
	    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
	    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
	    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
	    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
	    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
	    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
	    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
	    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
	    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
	    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
	    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
	    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
	    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
	    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
	    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
	    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
	    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
	    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
	    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
	    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
	    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
	    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
	    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
	    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
	end
end
themeSettings()