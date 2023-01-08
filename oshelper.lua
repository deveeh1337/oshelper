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
local vk = require "vkeys"
local wm = require "windows.message"
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local ffi = require("ffi")
local mem = require "memory"
local as_action = require('moonloader').audiostream_state
ffi.cdef[[
	short GetKeyState(int nVirtKey);
	bool GetKeyboardLayoutNameA(char* pwszKLID);
	int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);
	typedef unsigned long DWORD;
	DWORD GetTickCount();
]]
local resX, resY = getScreenResolution()
local numbermus = 1
local antiafkmode = imgui.ImBool(false)
local radiobutton = imgui.ImInt(0)
local BuffSize = 32
local KeyboardLayoutName = ffi.new("char[?]", BuffSize)
local LocalInfo = ffi.new("char[?]", BuffSize)

limit = 15 				 	-- Кол-во строк лога
col_default = 0xFFAAAAAA 	-- обычный цвет
col_pressed = 0xFFFFFF 	-- цвет нажатия
font_name = "Calibri"		-- Шрифт
font_size = 13				-- Размер

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
            info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                msg('Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion)
                wait(0)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      msg('Скрипт успешно обновился до версии '..updateversion..'.')
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        msg('Не получается обновиться, запускаю старую версию ('..thisScript().version..')')
                        imgui.ShowCursor = true
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              msg('Обновление не требуется.')
              imgui.ShowCursor = true
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
		gunmode = 0,
		bullet = 50,
		time = 0,
		weather = 15,
		cmds = false,
		armor = false,
		hello = true,
		med = false,
		autoeat = false,
		bus = false,
		mine = false,
		farm = false,
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
		mininghelper = false,
		spawn = false,
		prmanager = false,
		vr1 = false,
		automed = false,
		hpmed = 20,
		prstring = false,
		antilomka = false,
		vr2 = false,
		fam = false,
		al = false,
		vrmsg1 = ' ',
		fammsg = ' ',
		admsg1 = ' ',
		bmsg = ' ',
		volume = 5,
		stringmsg = ' ',
		almsg = ' ',
		adbox = false,
		vskin = false,
		adbox2 = false,
		plusw = false,
		bchat = false,
		chathelper = false,
		drift = false,
		calcbox = false,
		balloon = false,
		capcha = false,
		eat = false,
		podarok = false,
		osplayer = false,
		gunmaker = false,
		armortimer = false,
		job = false,
		drugstimer = false,
		open = false,
		vskin = false,
		fish = false,
		infrun = false,
		ztimerstatus = false,
		prsh1 = 0,
		prsh2 = 0,
		prsh3 = 56,
		prsh4 = 1,
		keyboard = false,
		autoscreen = false,
		autopay = false,
		prsh5 = 0,
		buttonjump = 0,
		delay = 30,
		edelay = 0,
		fisheye = false,
		autoprize = false,
		logincard = 123456,
		fov = 101,
	},
	keyboard = {
		kbact = false,
		posx = 10,
		posy = 500,
		move = true,
	},
	keylogger = {
		active = true,
	}
}, "OSHelper")

-- variables
local window = imgui.ImBool(false)
local musicmenu = imgui.ImBool(false)
local prmwindow = imgui.ImBool(false)
local cwindow = imgui.ImBool(false)
local bushelper = imgui.ImBool(false)
local minehelper = imgui.ImBool(false)
local farmhelper = imgui.ImBool(false)
local fishhelper = imgui.ImBool(false)
local kbset = imgui.ImBool(false)
local keyboard = imgui.ImBool(cfg.settings.keyboard)
local kbact = imgui.ImBool(cfg.keyboard.kbact)
local keyboard_pos = imgui.ImVec2(cfg.keyboard.posx, cfg.keyboard.posy)
local job = imgui.ImBool(cfg.settings.job)
local bus = imgui.ImBool(cfg.settings.bus)
local mine = imgui.ImBool(cfg.settings.mine)
local farm = imgui.ImBool(cfg.settings.farm)
local color = cfg.settings.color
local textcolor = '{c7c7c7}'
local capcha = imgui.ImBool(false)
local eat = imgui.ImBool(cfg.settings.eat)
local autoprize = imgui.ImBool(cfg.settings.autoprize)
local drift = imgui.ImBool(cfg.settings.drift)
local active = imgui.ImInt(cfg.settings.active)
local edelay = imgui.ImInt(cfg.settings.edelay)
local gunmode = imgui.ImInt(cfg.settings.gunmode)
local buttonjump = imgui.ImInt(cfg.settings.buttonjump)
local bullet = imgui.ImInt(cfg.settings.bullet)
local time = imgui.ImInt(cfg.settings.time)
local weather = imgui.ImInt(cfg.settings.weather)
local cheatcode = imgui.ImBuffer(''..cfg.settings.cheatcode, 256)
local vrmsg1 = imgui.ImBuffer(''..cfg.settings.vrmsg1, 256)
local vrmsg2 = imgui.ImBuffer(256)
local vr1 = imgui.ImBool(cfg.settings.vr1)
local gunmaker = imgui.ImBool(cfg.settings.gunmaker)
local antilomka = imgui.ImBool(cfg.settings.antilomka)
local vskin = imgui.ImBool(cfg.settings.vskin)
local mininghelper = imgui.ImBool(cfg.settings.mininghelper)
local armortimer = imgui.ImBool(cfg.settings.armortimer)
local drugstimer = imgui.ImBool(cfg.settings.drugstimer)
local vskin = imgui.ImBool(cfg.settings.vskin)
local calcbox = imgui.ImBool(cfg.settings.calcbox)
local vr2 = imgui.ImBool(cfg.settings.vr2)
local fisheye = imgui.ImBool(cfg.settings.fisheye)
local fammsg = imgui.ImBuffer(''..cfg.settings.fammsg, 256)
local prstring = imgui.ImBool(cfg.settings.prstring)
local bchat = imgui.ImBool(cfg.settings.bchat)
local stringmsg = imgui.ImBuffer(''..cfg.settings.stringmsg, 256)
local bmsg = imgui.ImBuffer(''..cfg.settings.bmsg, 256)
local almsg = imgui.ImBuffer(''..cfg.settings.almsg,256)
local adbox = imgui.ImBool(cfg.settings.adbox)
local adbox2 = imgui.ImBool(cfg.settings.adbox2)
local admsg1 = imgui.ImBuffer(''..cfg.settings.admsg1, 256)
local admsg2 = imgui.ImBuffer(256)
local fam = imgui.ImBool(cfg.settings.fam)
local al = imgui.ImBool(cfg.settings.al)
local theme = imgui.ImInt(cfg.settings.theme)
local cmds = imgui.ImBool(cfg.settings.cmds)
local hello = imgui.ImBool(cfg.settings.hello)
local armor = imgui.ImBool(cfg.settings.armor)
local med = imgui.ImBool(cfg.settings.med)
local autopay = imgui.ImBool(cfg.settings.autopay)
local drugs = imgui.ImBool(cfg.settings.drugs)
local rem = imgui.ImBool(cfg.settings.rem)
local balloon = imgui.ImBool(cfg.settings.balloon)
local ballooncolor = imgui.ImBool(false)
local fill = imgui.ImBool(cfg.settings.fill)
local ztimerstatus = imgui.ImBool(cfg.settings.ztimerstatus)
local fov = imgui.ImInt(cfg.settings.fov)
local mask = imgui.ImBool(cfg.settings.mask)
local move = imgui.ImBool(cfg.keyboard.move)
local fmenu = imgui.ImBool(cfg.settings.fmenu)
local finv = imgui.ImBool(cfg.settings.finv)
local lock = imgui.ImBool(cfg.settings.lock)
local autolock = imgui.ImBool(cfg.settings.autolock)
local cardlogin = imgui.ImBool(cfg.settings.cardlogin)
local fish = imgui.ImBool(cfg.settings.fish)
local spawn = imgui.ImBool(cfg.settings.spawn)
local logincard = imgui.ImInt(cfg.settings.logincard)
local hpmed = imgui.ImInt(cfg.settings.hpmed)
local prsh1 = imgui.ImInt(cfg.settings.prsh1)
local prsh2 = imgui.ImInt(cfg.settings.prsh2)
local prsh3 = imgui.ImInt(cfg.settings.prsh3)
local prsh4 = imgui.ImInt(cfg.settings.prsh4)
local prsh5 = imgui.ImInt(cfg.settings.prsh5)
local setskin = 0
local autoeat = imgui.ImBool(cfg.settings.autoeat)
local open = imgui.ImBool(cfg.settings.open)
local automed = imgui.ImBool(cfg.settings.automed)
local delay = imgui.ImInt(cfg.settings.delay)
local plusw = imgui.ImBool(cfg.settings.plusw)
local prmanager = imgui.ImBool(cfg.settings.prmanager)
local timeweather = imgui.ImBool(cfg.settings.timeweather)
local chathelper = imgui.ImBool(cfg.settings.chathelper)
local podarok = imgui.ImBool(cfg.settings.podarok)
local autoscreen = imgui.ImBool(cfg.settings.autoscreen)
local osplayer = imgui.ImBool(cfg.settings.osplayer)
local infrun = imgui.ImBool(cfg.settings.infrun)
local pronoroff = false
local menu = 1
local bhsalary = 0
local bhstop = 0
local bhcases = 0
local bhchert = 0
local mhstone = 0
local mhmetall = 0
local mhbronze = 0
local mhsilver = 0
local mhgold = 0
local fhlyon = 0
local fhhlopok = 0
local fishsalary = 0
local fishcase = 0
local nowTime = os.date("%H:%M:%S", os.time())
local flymode = 0  
local speed = 0.5
local radarHud = 0
local timech = 0
local keyPressed = 0
local miningtool = true
local automining_status = false
local automining_getbtc = 0
local automining_startall = 0
local automining_fillall = 0

local oxladtime = 224 -- Часы, на сколько хватит охлада

local INFO = { 
    0.029999,
    0.059999,
    0.09,
    0.11999,
    0.15,
    0.18,
	0.209999,
	0.239999,
	0.27,
	0.3
} -- Прибыль в час по лвл

local dtext = {}

keyboards = {
	{ -- Без NumPad
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
			{'                              ', 0x20},
			{'Alt', 0xA5},
			{'Win', 0x5C},
			{'Ctrl', 0xA3, 10},
			{'<', 0x25},
			{'\\/', 0x28},
			{'>', 0x27},
		}
	},
	{ -- Только цифры
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
bike = {[481] = true, [509] = true, [510] = true, [10433] = true, [10444] = true, [10445] = true, [10446] = true, [10431] = true, [10430] = true}
moto = {[448] = true, [461] = true, [462] = true, [463] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true, [1823] = true, [1913] = true, [1912] = true, [1947] = true, [1948] = true, [1949] = true, [1950] = true, [1951] = true, [1982] = true, [2006] = true}
chars = {
	["й"] = "q", ["ц"] = "w", ["у"] = "e", ["к"] = "r", ["е"] = "t", ["н"] = "y", ["г"] = "u", ["ш"] = "i", ["щ"] = "o", ["з"] = "p", ["х"] = "[", ["ъ"] = "]", ["ф"] = "a",
	["ы"] = "s", ["в"] = "d", ["а"] = "f", ["п"] = "g", ["р"] = "h", ["о"] = "j", ["л"] = "k", ["д"] = "l", ["ж"] = ";", ["э"] = "'", ["я"] = "z", ["ч"] = "x", ["с"] = "c", ["м"] = "v",
	["и"] = "b", ["т"] = "n", ["ь"] = "m", ["б"] = ",", ["ю"] = ".", ["Й"] = "Q", ["Ц"] = "W", ["У"] = "E", ["К"] = "R", ["Е"] = "T", ["Н"] = "Y", ["Г"] = "U", ["Ш"] = "I",
	["Щ"] = "O", ["З"] = "P", ["Х"] = "{", ["Ъ"] = "}", ["Ф"] = "A", ["Ы"] = "S", ["В"] = "D", ["А"] = "F", ["П"] = "G", ["Р"] = "H", ["О"] = "J", ["Л"] = "K", ["Д"] = "L",
	["Ж"] = ":", ["Э"] = "\"", ["Я"] = "Z", ["Ч"] = "X", ["С"] = "C", ["М"] = "V", ["И"] = "B", ["Т"] = "N", ["Ь"] = "M", ["Б"] = "<", ["Ю"] = ">"
}
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

function number_separator(n) 
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1 '):reverse())..right
end

function nsc_cmd( arg )
	if vskin.v then
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

-- main
function main()
    while not isSampAvailable() do wait(200) end
    if cfg.settings.theme == 0 then themeSettings(1) color = '{ff4747}'
		elseif cfg.settings.theme == 1 then themeSettings(3) cfg.settings.color = '{00bd5c}'
		elseif cfg.settings.theme == 2 then themeSettings(2) color = '{e8a321}'
		else cfg.settings.theme = 0 themeSettings(1) color = '{ff4747}'
		end
    if hello.v then
			if active.v == 0 then
				msg('Авторы: '..color..'deveeh'..textcolor..' и '..color..'casparo'..textcolor..'. Команда активации: '..color..'/oshelper') 
			end
			if active.v == 1 then
				msg('Авторы: '..color..'deveeh'..textcolor..' и '..color..'casparo'..textcolor..'. Чит-код: '..color..cfg.settings.cheatcode) 
			end
		end
    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if not doesFileExist(getWorkingDirectory()..'\\config\\OSHelper.ini') then inicfg.save(cfg, 'OSHelper.ini') msg('Конфигурационный файл OSHelper.ini принудительно загружен') end
    if not doesDirectoryExist('moonloader/OS Helper') then createDirectory('moonloader/OS Helper') end
    if not doesDirectoryExist('moonloader/OS Helper/OS Music') then createDirectory('moonloader/OS Helper/OS Music') end
    --imgbc = imgui.CreateTextureFromFile(getWorkingDirectory()..'moonloader/OS Helper/img/colors.jpg')
    inputHelpText = renderCreateFont("Arial", 9, FCR_BORDER + FCR_BOLD)
	lua_thread.create(inputChat)
	lua_thread.create(showInputHelp)
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
	    sampRegisterChatCommand("skin", nsc_cmd)
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
			else
				msg('У вас включена активация через чит-код ('..cfg.settings.cheatcode..')') 
			end 
		end)
		sampRegisterChatCommand("ss", function() send('/setspawn') end)
		sampRegisterChatCommand("bus", function()
			if job.v then
				if bus.v then 
					bushelper.v = not bushelper.v
				else
					msg('У вас не включена функция Bus Helper.')  
				end
			else
				msg('У вас не включена функция Job Helper.')  
			end
		end)
		sampRegisterChatCommand("fish", function()
			if job.v then
				if fish.v then 
					fishhelper.v = not fishhelper.v
				else
					msg('У вас не включена функция Fish Helper.')  
				end
			else
				msg('У вас не включена функция Job Helper.')  
			end
		end)
		sampRegisterChatCommand("mine", function()
			if job.v then
				if mine.v then 
					minehelper.v = not minehelper.v
				else
					msg('У вас не включена функция Mine Helper.')  
				end
			else
				msg('У вас не включена функция Job Helper.')  
			end
		end)
		sampRegisterChatCommand("farm", function()
			if job.v then
				if farm.v then 
					farmhelper.v = not farmhelper.v
				else
					msg('У вас не включена функция Farm Helper.')  
				end
			else
				msg('У вас не включена функция Job Helper.')  
			end 
		end)
		sampRegisterChatCommand('cg', function() 
			if gunmaker.v then 
				if gunmode.v == 0 then
					send('/sellgun '..id..' deagle '..cfg.settings.bullet)
				elseif gunmode.v == 1 then
					send('/sellgun '..id..' m4 '..cfg.settings.bullet)
				elseif gunmode.v == 2 then
					send('/sellgun '..id..' shotgun '..cfg.settings.bullet)
				end
			else
				msg('Сначала нужно включить функцию крафта оружия.')
			end 
		end)
		sampRegisterChatCommand('prm', function() 
			prmwindow.v = not prmwindow.v  
		end)
		sampRegisterChatCommand('nickname', function() 
			sss = sampGetPlayerNickname(id)
			msg(sss)
		end)
		sampRegisterChatCommand('osmusic', function()
			if osplayer.v then 
				musicmenu.v = not musicmenu.v 
			else
				msg('Сначала включите OS Music в главном меню.')
			end
		end)
		sampRegisterChatCommand('cc', function() 
			clearchat() 
		end)
		sampRegisterChatCommand('camhack', function()
			if flymode == 0 then
					--setPlayerControl(playerchar, false)
					displayRadar(false)
					displayHud(false)	    
					local posX, posY, posZ = getCharCoordinates(playerPed)
					angZ = getCharHeading(playerPed)
					angZ = angZ * -1.0
					setFixedCameraPosition(posX, posY, posZ, 0.0, 0.0, 0.0)
					angY = 0.0
					--freezeCharPosition(playerPed, false)
					--setCharProofs(playerPed, 1, 1, 1, 1, 1)
					--setCharCollision(playerPed, false)
					lockPlayerControl(true)
					flymode = 1
					--	sampSendChat('/anim 35')
				end
		end)
    local ip, port = sampGetCurrentServerAddress()
	if ip == '185.169.134.163' and port == 7777 then serverName = 'Rodina RP | Central District'
	elseif ip == '185.169.134.60' and port == 7777 then serverName = 'Rodina RP | Southern District'
	elseif ip == '185.169.134.62' and port == 7777 then serverName = 'Rodina RP | Northern District'
	elseif ip == '185.169.134.108' and port == 7777 then serverName = 'Rodina RP | Eastern District'
	end
    while true do
        wait(0)
        imgui.Process = window.v or prmwindow.v or cwindow.v or musicmenu.v or bushelper.v or minehelper.v or farmhelper.v or fishhelper.v or calcactive or keyboard.v or kbset.v
        imgui.ShowCursor = kbset.v
        if not keyboard.v then kbact.v = false end if keyboard.v then kbact.v = true end
        timech = timech + 1
        if fisheye.v then
	        if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
							cameraSetLerpFov(fov.v, fov.v, 1000, 1)
					else
						cameraSetLerpFov(fov.v, fov.v, 1000, 1)
					end
				end
        if calcbox.v then
	        calctext = sampGetChatInputText()
	        if calctext:find('%d+') and calctext:find('[-+/*^%%]') and not calctext:find('%a+') and calctext ~= nil then
	            calcactive, number = pcall(load('return '..calctext))
	            result = 'Результат: '..number
	        end
	        if calctext:find('%d+%%%*%d+') then
	            number1, number2 = calctext:match('(%d+)%%%*(%d+)')
	            number = number1*number2/100
	            calcactive, number = pcall(load('return '..number))
	            result = textcolor..'Результат: '..color..number
	        end
	        if calctext:find('%d+%%%/%d+') then
	            number1, number2 = calctext:match('(%d+)%%%/(%d+)')
	            number = number2/number1*100
	            calcactive, number = pcall(load('return '..number))
	            result = 'Результат: '..number
	        end
	        if calctext:find('%d+/%d+%%') then
	            number1, number2 = calctext:match('(%d+)/(%d+)%%')
	            number = number1*100/number2
	            calcactive, number = pcall(load('return '..number))
	            result = 'Результат: '..number..'%'
	        end
	        if calctext == '' then
	            calcactive = false
	      	end
        end
        if(isKeyDown(VK_T) and wasKeyPressed(VK_T))then
					if(not sampIsChatInputActive() and not sampIsDialogActive())then
						sampSetChatInputEnabled(true)
					end
				end
        if timeweather.v then
      		setTimeOfDay(time.v, 0)
      		forceWeatherNow(weather.v)
    		end
        inicfg.save(cfg, 'OSHelper.ini')
        if cfg.settings.cheatcode == '' then cfg.settings.cheatcode = 'oh' cheatcode = imgui.ImBuffer(tostring(cfg.settings.cheatcode), 256) end
    		if active.v == 1 and testCheat(cfg.settings.cheatcode) then window.v = not window.v end
    		if drift.v then
	    		if isCharInAnyCar(playerPed) then 
						local car = storeCarCharIsInNoSave(playerPed)
						local speed = getCarSpeed(car)
						isCarInAirProper(car)
						setCarCollision(car, true)
							if isKeyDown(VK_LSHIFT) and isVehicleOnAllWheels(car) and doesVehicleExist(car) and speed > 5.0 then
							setCarCollision(car, false)
								if isCarInAirProper(car) then setCarCollision(car, true)
								if isKeyDown(VK_A)
								then 
								addToCarRotationVelocity(car, 0, 0, 0.15)
								end
								if isKeyDown(VK_D)
								then 			
								addToCarRotationVelocity(car, 0, 0, -0.15)	
								end
							end
						end
					end
				end
				if infrun.v then mem.setint8(0xB7CEE4, 1) end
        
    -- hotkeys
        if not sampIsCursorActive() then
        	if balloon.v and isKeyDown(0x12) and isKeyDown(0x43) then setVirtualKeyDown(1, true) wait(50) setVirtualKeyDown (1, false) end
        	if mask.v and isKeyDown(0x12) and wasKeyPressed(0x32) then send('/mask') end
        	if spawn.v and wasKeyPressed(0x04) then 
        		if not isCharOnFoot(playerPed) then
                car = storeCarCharIsInNoSave(playerPed)
                _, carid = sampGetVehicleIdByCarHandle(car)
                send('/fixmycar '..carid) 
            	end
			end
	     	if med.v and isKeyDown(0x12) and wasKeyPressed(0x34) then send('/usemed') end
	     	local hpplayer = getCharHealth(PLAYER_PED)
	     	if med.v and automed.v then 
	     		hpcheck = hpmed.v + 1
	     		if hpplayer < hpcheck then send('/usemed') wait(1000) end
	     	end
	     	if eat.v and isKeyDown(0x12) and wasKeyPressed(0x35) then send('/eat') end
	     	if armor.v and isKeyDown(0x12) and wasKeyPressed(0x31) then
	     		local armourlvl = sampGetPlayerArmor(id)
	     		if armourlvl > 89 then 
		     		msg('У вас '..armourlvl..' процентов брони.')
		     	elseif armourlvl < 90 then
		     		if armourlvl > 0 then
			     		lua_thread.create(function() 
			     			send('/armour')
			     			wait(500)
			     			send('/armour')
			     		end)
			     	elseif armourlvl == 0 then
			     		send('/armour')
			     	end
			    end
	     	end
	     	if drugs.v and isKeyDown(0x12) and wasKeyPressed(0x33) then send('/usedrugs 3') end
	     	if rem.v and wasKeyPressed(0x52) then send('/repcar') end
	     	if fill.v and wasKeyPressed(0x42) then send('/fillcar') end
	     	if finv.v and isKeyDown(0x46) and wasKeyPressed(0x31) then local veh, ped = storeClosestEntities(PLAYER_PED) local _, idinv = sampGetPlayerIdByCharHandle(ped) if _ then send('/faminvite '..idinv) end end
	     	if fmenu.v and isKeyDown(0x12) and wasKeyPressed(0x46) then send('/fammenu') end
	     	if lock.v and wasKeyPressed(0x4C) then send('/lock') end
	     	if lock.v and wasKeyPressed(0x4B) then send('/jlock') end
	     	if open.v and wasKeyPressed(0x4F) then send('/open') end
		    if plusw.v then
			    if isCharOnAnyBike(playerPed) and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isKeyDown(0x57) then	-- onBike&onMoto SpeedUP [[LSHIFT]] --
						if bike[getCarModel(storeCarCharIsInNoSave(playerPed))] then
							setGameKeyState(16, 255)
							wait(50)
							setGameKeyState(16, 0)
						elseif moto[getCarModel(storeCarCharIsInNoSave(playerPed))] then
							setGameKeyState(1, -128)
							wait(50)
							setGameKeyState(1, 0)
						end
					end
				end	
				if ztimer == 0 then
					ztimer = ztimer - 1
					msg('Метка особо опасного преступника слетела, можете безопасно выходить из игры.')
					wait(1000)
				end
			end
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
		cfg.keyboard.kbset = keyboard.v
		cfg.keyboard.posx, cfg.keyboard.posy = keyboard_pos.x, keyboard_pos.y
		inicfg.save(cfg, 'OSHelper')
	end
end


function showInputHelp()
	while true do
		local chat = sampIsChatInputActive()
		if chat and chathelper.v then
			local in1 = sampGetInputInfoPtr()
			local in1 = getStructElement(in1, 0x8, 4)
			local in2 = getStructElement(in1, 0x8, 4)
			local in3 = getStructElement(in1, 0xC, 4)
			fib = in3 + 41
			fib2 = in2 + 10
			local _, pID = sampGetPlayerIdByCharHandle(playerPed)
			local name = sampGetPlayerNickname(pID)
			local score = sampGetPlayerScore(pID)
			local color = sampGetPlayerColor(pID)
			local capsState = ffi.C.GetKeyState(20)
			local success = ffi.C.GetKeyboardLayoutNameA(KeyboardLayoutName)
			local errorCode = ffi.C.GetLocaleInfoA(tonumber(ffi.string(KeyboardLayoutName), 16), 0x00000002, LocalInfo, BuffSize)
			local localName = ffi.string(LocalInfo)
			if cfg.settings.theme == 0 then
				local stringtext = string.format("{c7c7c7}ID: {ff4747}%d, {c7c7c7}Caps: {ff4747}%s, {c7c7c7}Lang: {ff4747}%s{ffffff}", pID, getStrByState(capsState), string.match(localName, "([^%(]*)"))
				renderFontDrawText(inputHelpText, stringtext, fib2, fib, 0xD7FFFFFF)
			end
			if cfg.settings.theme == 1 then
				local stringtext = string.format("{c7c7c7}ID: {00bd5c}%d, {c7c7c7}Caps: {00bd5c}%s, {c7c7c7}Lang: {00bd5c}%s{ffffff}", pID, getStrByState(capsState), string.match(localName, "([^%(]*)"))
				renderFontDrawText(inputHelpText, stringtext, fib2, fib, 0xD7FFFFFF)
			end
			if cfg.settings.theme == 2 then
				local stringtext = string.format("{c7c7c7}ID: {e8a321}%d, {c7c7c7}Caps: {e8a321}%s, {c7c7c7}Lang: {e8a321}%s{ffffff}", pID, getStrByState(capsState), string.match(localName, "([^%(]*)"))
				renderFontDrawText(inputHelpText, stringtext, fib2, fib, 0xD7FFFFFF)
			end
		end
		wait(0)
	end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == 261 and wparam == 13 then consumeWindowMessage(true, true) end
end

function inputChat()
	while true do
		if sampIsChatInputActive() then
			local getInput = sampGetChatInputText()
			if(oldText ~= getInput and #getInput > 0)then
				local firstChar = string.sub(getInput, 1, 1)
				if(firstChar == "." or firstChar == "/")then
					local cmd, text = string.match(getInput, "^([^ ]+)(.*)")
					local nText = "/" .. translite(string.sub(cmd, 2)) .. text
					local chatInfoPtr = sampGetInputInfoPtr()
					local chatBoxInfo = getStructElement(chatInfoPtr, 0x8, 4)
					local lastPos = mem.getint8(chatBoxInfo + 0x11E)
					sampSetChatInputText(nText)
					mem.setint8(chatBoxInfo + 0x11E, lastPos)
					mem.setint8(chatBoxInfo + 0x119, lastPos)
					oldText = nText
				end
			end
		end
		wait(0)
	end
end
function sampev.onSendEnterVehicle(id, pass)
	if autolock.v then
	    lua_thread.create(function()
	        --while not isCharInAnyCar(PLAYER_PED) do wait(0) end
	        if not isCharInAnyCar(PLAYER_PED) then
	        wait(4000)
	        sampSendChat('/engine')
	        wait(1000)
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

function clearchat()
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
	sampAddChatMessage('', -1)
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
			if pronoroff and al.v then
					send('/al '..u8:decode(almsg.v))
			end
			wait(1000)
			if pronoroff and adbox.v then
				send('/ad 1 '..u8:decode(admsg1.v))
			end
			wait(1000)
			if pronoroff and bchat.v then
				send('/b '..u8:decode(bmsg.v))
			end
			wait(2000)
			if pronoroff and prstring.v then
				send(u8:decode(stringmsg.v))
			end


	end)
end

function getMusicList()
	local files = {}
	local handleFile, nameFile = findFirstFile('moonloader/OS Helper/OS Music/*.mp3')
	while nameFile do
		if handleFile then
			if not nameFile then 
				findClose(handleFile)
			else
				files[#files+1] = nameFile
				nameFile = findNextFile(handleFile)
			end
		end
	end
	return files
end

function sampev.onShowDialog(id, style, title, button1, button0, text)
	if mininghelper.v then
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
				if dtext[d]:find('Полка%s+№%d+%s+|%s+%{BEF781%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+%d+%p%d+%%') then	-- Статус, работает или нет
					automining_status = 1
					automining_statustext = '{BEF781}'
				else
					automining_status = 0
					automining_statustext = '{F78181}'
				end
				local automining_lvl = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+(%d+)%s+уровень%s+%d+%p%d+%%')) -- Уровень видюхи
				local automining_fillstatus = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+уровень%s+(%d+%p%d+)%%')) -- Залито охлада в процентах
				local automining_btcamount = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+(%d+%p%d+)%s+BTC%s+%d+%s+уровень%s+%d+%p%d+%%')) -- Число битков сейчас в видюхе              						
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
                    					
					automining_fillstatushours = math.ceil(oxladtime * (automining_fillstatus / 100)) -- На сколько часов охлада
					automining_fillstatusbtc = automining_fillstatushours * INFO[automining_lvl] -- Сколько видюха еще даст BTC
					automining_btcoverall = automining_btcoverall + automining_fillstatusbtc -- Подсчет сколько всего дадут все видюхи
					automining_btcamountoverall = automining_btcamountoverall + math.floor(automining_btcamount) -- Подсчет сколько доступно для снятия
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
					text = text .. '\n' .. color .. '>> {FFF}На полках нет видеокарт, залить охлаждающую жидкость не получится'
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
						sampSendDialogResponse(270,1,1,nil) -- Да
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
				sampSendDialogResponse(271,1,nil,nil) -- Да
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
	if cardlogin.v and id == 782 then sampSendDialogResponse(782, 1, -1, logincard.v) end
	if ztimerstatus.v then
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
	if autoprize.v then
		if id == 519 and text:find('»» Следующая страница') then 
			sampSendDialogResponse(519, 1, 1, "")
		elseif id == 519 and not text:find('»» Следующая страница') then 
			sampSendDialogResponse(519, 1, 0, "")
			return false
		end
	end
	if id == 520 then 
		sampSendDialogResponse(520, 1, -1, "")
	end
	if autopay.v then 
		if id == 756 then  -- Список бизов
			sampSendDialogResponse(756, 1, 0, "")
		end
		
		if id == 672 then -- Кнопка оплаты
			sampSendDialogResponse(672, 1, -1, "")
			return false
		end
			--if id == 672 then sampSendDialogResponse(672, 1, -1, nil) sampCloseCurrentDialogWithButton(1) return false end
			--if id == 671 then sampSendDialogResponse(671, 1, -1, nil) sampCloseCurrentDialogWithButton(1) return false end
	end
	if autoscreen.v and id == 10044 then
			lua_thread.create(function() 
				wait(400)
				sampSendChat('/time')
				wait(600)
				setVirtualKeyDown(119, true) wait(0) setVirtualKeyDown (119, false)
		end) 
	end
end

function sampev.onSendDialogResponse(id, button, list, input)
	if mininghelper.v then
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
		if drugstimer.v and text:find('Здоровье пополнено на') and not text:find('говорит:') then
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
		if armortimer.v then
			local armourlvl = sampGetPlayerArmor(id)
			local nickname = sampGetPlayerNickname(id)
			if text:find('надел бронежилет') and armourlvl == 100 and not text:find('говорит:') then
				lua_thread.create(function()
					printStringNow(u8'ARM: Timer started.', 5000)
					wait(20000)
					printStringNow(u8'ARM: 40 sec.', 5000)
					wait(20000)
					printStringNow(u8'ARM: 20 sec.', 5000)
					wait(15000)
					printStringNow(u8'ARM: 5 sec.', 3000)
					wait(5000)
					printStringNow(u8'ARM: GO GO GO!', 3000)
				end)
			end
		end
	  if antilomka.v and text:find('У вас началась ломка') and not text:find('говорит:') then
				send('/usedrugs 1')
		end
		bushelpermsg()
		minehelpermsg()
		farmhelpermsg()
end

function sampev.onServerMessage(color, text) --jobhelper
	if bus.v then
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
	if mine.v then
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
	  if farm.v then
			if text:find('Вам добавлено: предмет "Лён". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhlyon = mhlyon + 1
	    elseif text:find('Вам добавлено: предмет "Лён" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhlyon = mhlyon + tonumber(text:match("(%d+) шт"))  
	    end
	    if text:find('Вам добавлено: предмет "Хлопок". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        mhhlopok = mhlopok + 1
	    elseif text:find('Вам добавлено: предмет "Хлопок" +%D(%d+) шт+%D. Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		mhhlopok = mhlopok + tonumber(text:match("(%d+) шт"))  
	  	end
		end
		if fish.v then
			if text:find('Вам добавлено: предмет "Ларец рыболова". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	        fishcase = fishcase + 1
	    elseif text:find('Вам добавлено: предмет "Рыба (%A+)". Чтобы открыть инвентарь,') and not text:find('говорит:') then
	    		fishsalary = fishsalary + 15000 
	    end
		end
end


function eatchips()
		lua_thread.create(function()
			if eat.v and edelay.v > 0 then
				local eatdelay = cfg.settings.edelay * 60000 send('/eat') wait(eatdelay) return true
			end
		end)
end
-- imgui
local volume = imgui.ImInt(5)
function imgui.OnDrawFrame()
	if cfg.settings.theme == 0 then themeSettings(1) color = '{ff4747}'
	elseif cfg.settings.theme == 1 then themeSettings(3) cfg.settings.color = '{00bd5c}'
	elseif cfg.settings.theme == 2 then themeSettings(2) color = '{e8a321}'
	else cfg.settings.theme = 0 themeSettings(1) color = '{ff4747}'
	end
    if window.v then
    		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 325), imgui.Cond.FirstUseEver)
        imgui.Begin('OS Helper v'..thisScript().version, window, imgui.WindowFlags.NoResize)
	        imgui.BeginChild("left", imgui.ImVec2(150, 290), true)
				if imgui.Selectable(fa.ICON_FA_USER..u8' Персонаж', menu == 1) then menu = 1
				elseif imgui.Selectable(fa.ICON_FA_CAR..u8' Транспорт', menu == 2) then menu = 2
				elseif imgui.Selectable(fa.ICON_FA_USERS..u8' Семья', menu == 3) then menu = 3
				elseif imgui.Selectable(fa.ICON_FA_GLOBE..u8' Окружение', menu == 8) then menu = 8
				elseif imgui.Selectable(fa.ICON_FA_COMMENTS..u8' Работа с чатом', menu == 4) then menu = 4
				elseif imgui.Selectable(fa.ICON_FA_WINDOW_MAXIMIZE..u8' Работа с диалогами', menu == 5) then menu = 5
				elseif imgui.Selectable(fa.ICON_FA_TASKS..u8' Дополнения', menu == 9) then menu = 9
				elseif imgui.Selectable(fa.ICON_FA_COG..u8' Настройки', menu == 6) then menu = 6
				elseif imgui.Selectable(fa.ICON_FA_INFO_CIRCLE..u8' Информация', menu == 7) then menu = 7
				end
				imgui.SetCursorPosY(265)
				lua_thread.create(function()
					if updateversion == thisScript().version then
			        	if imgui.Button(u8'Сохранить', imgui.ImVec2(135, 20)) then
			        		save()
									msg('Все настройки сохранены.')
			        	end
			    elseif updateversion ~= thisScript().version then
				        	if imgui.Button(u8'Обновить', imgui.ImVec2(135, 20)) then
				        		imgui.ShowCursor = false
				        		imgui.Process = false
					          autoupdate("https://raw.githubusercontent.com/deveeh/oshelper/master/update.json", '['..string.upper(thisScript().name)..']: ', "")
				        	end
			    end
			  end)
			imgui.EndChild()
			imgui.SameLine()
			imgui.BeginChild('right', imgui.ImVec2(325, 290), true)
			if menu == 1 then
				character()
			end
			if menu == 2 then
				transport()
			end
			if menu == 3 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Семья')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Меню семьи', fmenu) then cfg.settings.fmenu = fmenu.v end
				imgui.TextQuestion(u8'Активация: ALT + F')
				if imgui.Checkbox(u8'Инвайт в семью', finv) then cfg.settings.finv = finv.v end
				imgui.TextQuestion(u8'Активация: F + 1')
			end
			if menu == 4 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Работа с чатом')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Chat Helper', chathelper) then cfg.settings.chathelper = chathelper.v end
				imgui.TextQuestion(u8'Подсказки в чате')
				if imgui.Checkbox(u8'Chat Calculator', calcbox) then cfg.settings.calcbox = calcbox.v end
				imgui.TextQuestion(u8'Активация: 1+1 (в чат)')
				if imgui.Checkbox(u8'PR Manager', prmanager) then cfg.settings.prmanager = prmanager.v end
				imgui.TextQuestion(u8'Меню: /prm')
				if imgui.Checkbox(u8'Сокращенные команды', cmds) then cfg.settings.cmds = cmds.v save() end
				if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                        imgui.Text(u8'/biz - /bizinfo\n/car [id] - /fixmycar\n/fh [id] - /findihouse\n/fbiz [id] - /findibiz\n/urc - /unrentcar\n/fin [id] [id biz] - /showbizinfo\n/ss - /setspawn')
                    imgui.EndTooltip()
                end
			end
			if menu == 5 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Работа с диалогами')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Автологин в банке', cardlogin) then cfg.settings.cardlogin = cardlogin.v end
				imgui.TextQuestion(u8'Не работает с новыми диалогами')
				if cardlogin.v then 
				imgui.Text(u8'	Пин-код:')
				imgui.SameLine()
				imgui.PushItemWidth(54.5) 
				if imgui.InputInt(u8'##логин банк', logincard, 0, 0) then cfg.settings.logincard = logincard.v end
				end
				if imgui.Checkbox(u8'Автооплата налогов', autopay) then cfg.settings.autopay = autopay.v end
				imgui.TextQuestion(u8'Не работает с новыми диалогами')
				if imgui.Checkbox(u8'Автосбор ежедневных призов', autoprize) then cfg.settings.autoprize = autoprize.v end
				imgui.TextQuestion(u8'Автоматически собирает призы в /dw_prizes')
				if imgui.Checkbox(u8'Mining Helper', mininghelper) then cfg.settings.mininghelper = mininghelper.v end
				imgui.TextQuestion(u8'Сбор прибыли, охлаждение видеокарт в пару кликов')
				if imgui.Checkbox(u8'Графическая клавиатура', keyboard) then cfg.settings.keyboard = keyboard.v end
				if imgui.Checkbox(u8'Autoscreen', autoscreen) then cfg.settings.autoscreen = autoscreen.v end
				imgui.TextQuestion(u8'При появлении диалога с предложением, \nавтоматически пишет /time и нажимает F8')
				--[[if imgui.Checkbox(u8'Тренировка капчи', capcha) then cfg.settings.capcha = capcha.v end
				if capcha.v then
				if imgui.InputInt(u8'##активация клавиши', key, 0, 0) then cfg.settings.key = key.v end
				end]]--
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
	                imgui.Text(u8'После изменения режима активации, сохраните скрипт.')
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
					--elseif cfg.settings.theme == 3 then themeSettings(4) color = '{ff4747}'
					else cfg.settings.theme = 0 themeSettings(1) color = '{ff4747}'
					end
				end
				if imgui.Checkbox(u8'Приветственное сообщение', hello) then cfg.settings.hello = hello.v end
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
				imgui.Text(u8'OS Helper - совершенно новый скрипт,\n направленный на облегчение жизни \n как простым игрокам, так и крупным бизнесменам. \n Данное ПО не выступает в роли чита или стиллера.\n Его основная задача превратить \n однотипные действия в более \n комфортный экспириенс во время игры.')
				imgui.Text('')
				imgui.Text(u8'Авторы:') imgui.SameLine() imgui.Link('https://vk.com/deveeh', 'deveeh') imgui.SameLine() imgui.Text(u8'и') imgui.SameLine() imgui.Link('https://t.me/atimohov', 'casparo')
				imgui.Text(u8'Группа ВКонтакте:') imgui.SameLine() imgui.Link('https://vk.com/oshelper_rodina', 'vk.com/oshelper_rodina')
				imgui.Text(u8'Нашли баг?') imgui.SameLine() imgui.Link('https://vk.com/topic-215734333_49024979', u8'Вам сюда!')
			end
			if menu == 8 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Окружение')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Редактор времени и погоды', timeweather) then cfg.settings.timeweather = timeweather.v end
				if timeweather.v then
					imgui.PushItemWidth(75)
					imgui.Text(u8'	Время: ')
					imgui.SameLine()
					imgui.SetCursorPosX(62)
					if imgui.InputInt(u8'##time', time) then
						if time.v > 24 then
							time.v = 24
							patch_samp_time_set(true)
						elseif time.v < 0 then
							time.v = 0
							patch_samp_time_set(true)
						end
						cfg.settings.time = time.v
					end
					imgui.Text(u8'	Погода: ')
					imgui.SameLine()
					if imgui.InputInt(u8'##weather', weather) then
						if weather.v < 0 then
							weather.v = 0  
						elseif weather.v > 45 then
							weather.v = 45 
						end
						cfg.settings.weather = weather.v 
					end
				end
				if imgui.Checkbox(u8'Настройка FOV', fisheye) then cfg.settings.fisheye = fisheye.v end
				if fisheye.v then
					imgui.Text(u8'	FOV:') imgui.SameLine()
					if imgui.SliderInt('##FOV', fov, 1, 100) then cfg.settings.fov = fov.v end
				end
			end
			if menu == 9 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Дополнения')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'OS Music', osplayer) then cfg.settings.osplayer = osplayer.v end
				imgui.TextQuestion(u8'Активация: /osmusic\nЧтобы загрузить свои песни, откройте папку с игрой, \nдалее зайдите в moonloader/OS Helper/OS Music.')
				if imgui.Checkbox(u8'Job Helper', job) then cfg.settings.job = job.v end
				imgui.TextQuestion(u8'Лучший помощник для вашей любимой работы')
				if job.v then
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Bus Helper', bus) then cfg.settings.bus = bus.v end
					imgui.TextQuestion(u8'Активация: /bus\nПодсчёт заработка на работе автобусника')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Mine Helper', mine) then cfg.settings.mine = mine.v end
					imgui.TextQuestion(u8'Активация: /mine\nПодсчёт заработка на работе шахтера')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Farm Helper', farm) then cfg.settings.farm = farm.v end
					imgui.TextQuestion(u8'Активация: /farm\nПодсчёт заработка на работе фермера')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Fish Helper', fish) then cfg.settings.fish = fish.v end
					imgui.TextQuestion(u8'Активация: /fish\nПодсчёт заработка на работе рыболова')
				end
			end
			imgui.EndChild()
        imgui.End()
    end
    if prmwindow.v then
    	imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(300, 400), imgui.Cond.FirstUseEver)
    	imgui.Begin('PR Manager (OS '..thisScript().version..')##prmenu', prmwindow, imgui.WindowFlags.NoResize)
        	if prmanager.v then
	        	if imgui.Checkbox(u8'Реклама в VIP CHAT (/vr)', vr1) then cfg.settings.vr1 = vr1.v end
				if vr1.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##vr1", u8"Работает БК Лыткарино №56!", vrmsg1) then cfg.settings.vrmsg1 = vrmsg1.v end
					end
				if imgui.Checkbox(u8'Реклама в FAMILY CHAT (/fam)', fam) then cfg.settings.fam = fam.v end
				if fam.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##fammsg", u8"Работает БК Эдово №57!", fammsg) then cfg.settings.fammsg = fammsg.v end
				end
				if imgui.Checkbox(u8'Реклама в ALLIANCE CHAT (/al)', al) then cfg.settings.al = al.v end
				if al.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##almsg", u8"Работает БК Лыткарино №56!", almsg) then cfg.settings.almsg = almsg.v end
					end
				if imgui.Checkbox(u8'Реклама в AD (/ad 1)', adbox) then cfg.settings.adbox = adbox.v end
				if adbox.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##admsg1", u8"Работает БК Лыткарино №56!", admsg1) then cfg.settings.admsg1 = admsg1.v end
				end
				if imgui.Checkbox(u8'Реклама в NRP CHAT (/b)', bchat) then cfg.settings.bchat = bchat.v end
				if bchat.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##bmsg", u8"Работает БК Эдово №57!", bmsg) then cfg.settings.bmsg = bmsg.v end
				end
				if imgui.Checkbox(u8'Дополнительная строка', prstring) then cfg.settings.prstring = prstring.v end
				if prstring.v then
					imgui.Text(u8'Сообщение: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##prstring", u8"/vr Работает БК Эдово №57!", stringmsg) then cfg.settings.stringmsg = stringmsg.v end
				end
				imgui.Separator()
				imgui.Text(u8'Задержка: ')
				imgui.SameLine()
				imgui.PushItemWidth(40)
				if imgui.InputInt("##Задержка", delay, 0, 0) then cfg.settings.delay = delay.v end
				imgui.SameLine() 
				imgui.Text(u8'сек.')
				imgui.Text(u8'Активация: /pr')
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
   	local input = sampGetInputInfoPtr()
    local input = getStructElement(input, 0x8, 4)
    local windowPosX = getStructElement(input, 0x8, 4)
    local windowPosY = getStructElement(input, 0xC, 4)
    if sampIsChatInputActive() and calcactive then
	    imgui.SetNextWindowPos(imgui.ImVec2(windowPosX, windowPosY + 30 + 30), imgui.Cond.FirstUseEver)
	    imgui.SetNextWindowSize(imgui.ImVec2(result:len()*10, 30))
        imgui.Begin('Solve', cwindow, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove)
        imgui.CenterText(u8(number_separator(result)))
        imgui.End()
    end
    if musicmenu.v then 
	    osmusic()
		end
		jobhelperimgui()
    if musicmenu.v or prmwindow.v or window.v then
			imgui.ShowCursor = true
		end
		if kbact.v then
		imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(5.0, 2.4)) -- Фикс положения клавиш
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0)) -- Убираем фон
		imgui.SetNextWindowPos(keyboard_pos, imgui.Cond.FirstUseEver, imgui.ImVec2(0, 0))
		imgui.Begin('##keyboard', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + (move.v and 0 or imgui.WindowFlags.NoMove) )
			keyboard_pos = imgui.GetWindowPos()
			for i, line in ipairs(keyboards[0+1]) do
				if (0 == 0 or 0 == 1) and i == 4 then 
					imgui.SetCursorPosY(68) -- fix
				elseif (0 == 0 or 0 == 1) and i == 6 then 
					imgui.SetCursorPosY(112) -- fix
				end
				for key, v in ipairs(line) do
					local size = imgui.CalcTextSize(v[1])
					if isKeyDown(v[2]) then
						imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.GetStyle().Colors[imgui.Col.ButtonActive])
					else
						imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0,0,0,0.4))
					end
					imgui.BeginChild('##'..i..key, imgui.ImVec2(size.x+11, (v[1] == '\n+' or v[1] == '\nE') and size.y + 14 or size.y + 5), true)
						imgui.Text(v[1])
					imgui.EndChild()
					imgui.PopStyleColor()
					if key ~= #line then
						imgui.SameLine()
						if v[3] then imgui.SameLine(imgui.GetCursorPosX()+v[3]) end
					end
				end
			end
		imgui.End()
		imgui.PopStyleColor()
		imgui.PopStyleVar()
	end
end


function character()
	imgui.PushFont(fontsize)
        	imgui.CenterText(u8'Персонаж')
        imgui.PopFont()
        imgui.Separator()
        if imgui.Checkbox(u8'Бронежилет', armor) then cfg.settings.armor = armor.v end
				imgui.TextQuestion(u8'Использовать бронежилет: ALT + 1\nНастройка таймера доступна после включения главной функции')
				if armor.v then imgui.Text('	') imgui.SameLine()  if imgui.Checkbox(u8'Армортаймер', armortimer) then cfg.settings.armortimer = armortimer.v end end
				if imgui.Checkbox(u8'Маска', mask) then cfg.settings.mask = mask.v end
				imgui.TextQuestion(u8'Использовать маску: ALT + 2')
				if imgui.Checkbox(u8'Наркотики (3 шт)', drugs) then cfg.settings.drugs = drugs.v end
				imgui.TextQuestion(u8'Использовать нарко: ALT + 3\nНастройка таймера и антиломки доступна после включения главной функции')
				if drugs.v then 
					imgui.Text('	') imgui.SameLine()  
					if imgui.Checkbox(u8'Наркотаймер', drugstimer) then cfg.settings.drugstimer = drugstimer.v end
					imgui.Text('	') imgui.SameLine() 
					if imgui.Checkbox(u8'Антиломка', antilomka) then cfg.settings.antilomka = antilomka.v end  
				end
				if imgui.Checkbox(u8'Аптечка', med) then cfg.settings.med = med.v end
				imgui.TextQuestion(u8'Использовать аптечку: ALT + 4\nНастройка автохилла доступна после включения главной функции')
				if med.v then
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Автохилл', automed) then cfg.settings.automed = automed.v end
					--[[if automed.v then
						imgui.Text('		HP:') imgui.SameLine() 
						imgui.PushItemWidth(73) 
						if imgui.InputInt("##автохилл", hpmed) then 
							if hpmed.v > 99 then
								hpmed.v = 99
							elseif hpmed.v < 1 then
								hpmed.v = 1
							end
							cfg.settings.hpmed = hpmed.v 
							save() 
						end
						imgui.PopItemWidth()
					end]]--
				end
				if imgui.Checkbox(u8'Еда', eat) then cfg.settings.eat = eat.v end
				imgui.TextQuestion(u8'Использовать чипсы: ALT + 5\nНастройка автоеды доступна после включения главной функции')
				if eat.v then
					imgui.Text(u8'	Задержка:')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.InputInt("##edelay", edelay) then cfg.settings.edelay = edelay.v save() 
						if edelay.v > 0 then eatchips() end
					end
					imgui.SameLine()
					imgui.Text(u8'мин.')
					imgui.TextQuestion(u8'При вводе 0 в поле, функция будет выключена')
					imgui.PopItemWidth() 
				end
				if imgui.Checkbox(u8'Z-Timer', ztimerstatus) then cfg.settings.ztimerstatus = ztimerstatus.v end
				imgui.TextQuestion(u8'После выдачи метки Z, начнется отсчёт 600 секунд')
				if imgui.Checkbox(u8'Авто-кликер', balloon) then cfg.settings.balloon = balloon.v end
				imgui.TextQuestion(u8'Активация: ALT + C (зажатие)\nКликер для сборки шара/выкапывания клада и т.п.')
				if imgui.Checkbox(u8'Бесконечный бег', infrun) then cfg.settings.infrun = infrun.v end
				imgui.TextQuestion(u8'Активация: автоматическая\nНе позволяет устать персонажу от бега')
				if imgui.Checkbox(u8'Skin Changer', vskin) then cfg.settings.vskin = vskin.v end 
				imgui.TextQuestion(u8'Активация: /skin [ID]\nСкин виден только вам\nТак же, мы вам не советуем злоупотреблять 92, 99 и 320+ скинами,\nтак как они дают преимущество в беге')
				if imgui.Checkbox(u8'Крафт оружия', gunmaker) then cfg.settings.gunmaker = gunmaker.v end
				imgui.TextQuestion(u8'Скрафтить оружие: /cg')
				if gunmaker.v then
					imgui.Text(u8'	Оружие: ')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.Combo(u8'##Выбор гана', gunmode, {u8'Deagle', u8'M4', u8'Shotgun'}, -1) then cfg.settings.gunmode = gunmode.v save() imgui.PopItemWidth() end
					imgui.Text(u8'	Патроны:')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.InputInt("##Патроны", bullet, 0, 0) then cfg.settings.bullet = bullet.v save() end
					if gunmode.v == 0 then
						ammo = bullet.v * 2
					elseif gunmode.v == 1 then
						ammo = bullet.v * 2
					elseif gunmode.v == 2 then
						ammo = bullet.v * 10
					end
					imgui.Text(u8'	Стоимость крафта: '..ammo..u8' мат.')
					end
end

function transport()
					imgui.PushFont(fontsize)
        			imgui.CenterText(u8'Транспорт')
        		imgui.PopFont()
        		imgui.Separator()
				if imgui.Checkbox(u8'AutoCar', autolock) then cfg.settings.autolock = autolock.v end
				imgui.TextQuestion(u8'Активация: сесть в машину\nАвтоматическое закрытие дверей + включение двигателя')
				if imgui.Checkbox(u8'Открыть/Закрыть двери', lock) then cfg.settings.lock = lock.v end
				imgui.TextQuestion(u8'Активация: L, K (аренд. т/с)')
				if imgui.Checkbox(u8'Ремкомплект', rem) then cfg.settings.rem = rem.v end
				imgui.TextQuestion(u8'Использовать ремкомплект: R')
				if imgui.Checkbox(u8'Канистра', fill) then cfg.settings.fill = fill.v end
				imgui.TextQuestion(u8'Использовать канистру: B')
				if imgui.Checkbox(u8'Спавн транспорта', spawn) then cfg.settings.spawn = spawn.v end
				imgui.TextQuestion(u8'Использование: Колесико Мыши (нажатие)')
				if imgui.Checkbox(u8'Открытие шлагбаума', open) then cfg.settings.open = open.v end
				imgui.TextQuestion(u8'Открыть шлагбаум: O')
				if imgui.Checkbox(u8'+W moto/bike', plusw) then cfg.settings.plusw = plusw.v end
				imgui.TextQuestion(u8'Использование: W (зажатие)\nКликер для велосипедов и мотоциклов')
				if imgui.Checkbox(u8'Дрифт', drift) then cfg.settings.drift = drift.v end
				imgui.TextQuestion(u8'Активация: LSHIFT (зажатие)\nУправление заносом')
				--[[if imgui.Checkbox(u8'Цвета покраски', ballooncolor) then balloncolor = not balloncolor if ballooncolor then 
						imgui.Image(imgbc, imgui.ImVec2(200, 200)) 
				end 
			end]]--
end

function osmusic()
			local musiclist = getMusicList()
			imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
			imgui.SetNextWindowSize(imgui.ImVec2(320, 400), imgui.Cond.FirstUseEver)
			imgui.Begin(u8'OS Music | OS Helper '..thisScript().version..'##music', musicmenu, imgui.WindowFlags.NoResize)
			local btn_size = imgui.ImVec2(-0.1, 0)
				imgui.BeginChild('##high', imgui.ImVec2(300, 325), true)
				for nummus, name, numbermus in pairs(musiclist) do
					local name = name:gsub('.mp3', '')
					if imgui.RadioButton(u8(name), radiobutton, nummus) then selected = nummus status = true end
				end
				imgui.EndChild()
				imgui.BeginChild('##low', imgui.ImVec2(300, 35), true)
				imgui.SameLine()
					for nummus, name in pairs(musiclist) do
						if nummus == selected then
							imgui.Text('		  ')			
							imgui.SameLine()
								if status then
									if imgui.Button(fa.ICON_FA_PLAY..'') then
										if playsound ~= nil then setAudioStreamState(playsound, as_action.STOP) playsound = nil end
										playsound = loadAudioStream('moonloader/OS Helper/OS Music/'..name)
										setAudioStreamState(playsound, as_action.PLAY)
										pause = false
										status = false
										lua_thread.create(function()
											while true do
												setAudioStreamVolume(playsound, math.floor(volume.v))
												wait(0)
											end
										end)
									end
								elseif status == false then 
									if not pause then if imgui.Button(fa.ICON_FA_PAUSE..u8'') then pause = true if playsound ~= nil then setAudioStreamState(playsound, as_action.PAUSE)  end end
									imgui.SameLine(nil, 3)
									elseif pause then if imgui.Button(fa.ICON_FA_PLAY..u8'') then pause = false if playsound ~= nil then setAudioStreamState(playsound, as_action.RESUME) end end 
									end
								end
						
						imgui.SameLine()
						imgui.Text(u8'Громкость:')
						imgui.SameLine()
						imgui.PushItemWidth(70)
						if imgui.InputInt('', volume) then
							if volume.v > 10 then
								volume.v = 10
							elseif volume.v  < 0 then
								volume.v  = 0
							end
							cfg.settings.volume = volume.v
							save()
						end 
					end 
				end
					if playsound ~= nil then setAudioStreamVolume(playsound, math.floor(volume.v)) end
				imgui.EndChild()
			imgui.End()
end

function jobhelperimgui()
		if bushelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 150), imgui.Cond.FirstUseEver)
        imgui.Begin('Bus Helper (OS v'..thisScript().version..')##bushelper', bushelper, imgui.WindowFlags.NoResize)
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
            if imgui.Button(u8'Убрать курсор', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if minehelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 170), imgui.Cond.FirstUseEver)
        imgui.Begin('Mine Helper (OS v'..thisScript().version..')##minehelper', minehelper, imgui.WindowFlags.NoResize)
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
            if imgui.Button(u8'Убрать курсор', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if farmhelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 115), imgui.Cond.FirstUseEver)
        imgui.Begin('Farm Helper (OS v'..thisScript().version..')##farmhelper', farmhelper, imgui.WindowFlags.NoResize)
            imgui.Text(u8'Лён: '..fhlyon..u8' шт.')
            imgui.Text(u8'Хлопок: '..fhhlopok..u8' шт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                fhlyon = 0
                fhhlopok = 0
            end
            if imgui.Button(u8'Убрать курсор', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if fishhelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 115), imgui.Cond.FirstUseEver)
        imgui.Begin('Fish Helper (OS v'..thisScript().version..')##fishhelper', fishhelper, imgui.WindowFlags.NoResize)
            imgui.Text(u8'Заработок: '..fishsalary..u8' руб.')
            imgui.TextQuestion(u8'Заработок приблизителен, 1 рыба = 15.000руб')
            imgui.Text(u8'Ларцы: '..fishcase..u8' шт.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'Очистить статистику', imgui.ImVec2(205, 20)) then
                fishsalary = 0
                fishcase = 0
            end
            if imgui.Button(u8'Убрать курсор', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
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

-- raknet
function set_player_skin(id, skin)
	local BS = raknetNewBitStream()
	raknetBitStreamWriteInt32(BS, id)
	raknetBitStreamWriteInt32(BS, skin)
	raknetEmulRpcReceiveBitStream(153, BS)
	raknetDeleteBitStream(BS)
end