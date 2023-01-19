-- script
script_name('OS Helper')
script_version('1.4.1 pre-final')
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

limit = 15 				 	-- ���-�� ����� ����
col_default = 0xFFAAAAAA 	-- ������� ����
col_pressed = 0xFFFFFF 	-- ���� �������
font_name = "Calibri"		-- �����
font_size = 13				-- ������

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
                msg('���������� ����������. ������� ���������� c '..thisScript().version..' �� '..updateversion)
                wait(0)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('��������� %d �� %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      msg('������ ������� ��������� �� ������ '..updateversion..'.')
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        msg('�� ���������� ����������, �������� ������ ������ ('..thisScript().version..')')
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
              msg('���������� �� ���������.')
              imgui.ShowCursor = true
            end
          end
        else
          print('v'..thisScript().version..': �� ���� ��������� ����������. ��������� ��� ��������� �������������� �� '..url)
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
		xcolor = '',
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
		rgb = 1.0, 1.0, 1.0,
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
		masktimer = false,
		keyboard = false,
		autoscreen = false,
		autopay = false,
		prconnect = false,
		prsh5 = 0,
		buttonjump = 0,
		delay = 30,
		edelay = 0,
		fisheye = false,
		autoprize = false,
		logincard = 123456,
		fov = 100,
		timestate = false,
		autorun = false,
		r = 0.00,
		g = 0.00,
		b = 0.00,
	},
	timestamp = {
        x = 300,
        y = 300,
        fontsize = 12,
	},
	keyboard = {
		kbact = false,
		posx = 10,
		posy = 500,
		move = true,
	},
	keylogger = {
		active = true,
	},
}, "OSHelper")

-- variables
checkboxes = {
	job = imgui.ImBool(cfg.settings.job),
	bus = imgui.ImBool(cfg.settings.bus),
  mine = imgui.ImBool(cfg.settings.mine),
  farm = imgui.ImBool(cfg.settings.farm),
  fish = imgui.ImBool(cfg.settings.fish),
  hello = imgui.ImBool(cfg.settings.hello),
	armor = imgui.ImBool(cfg.settings.armor),
	med = imgui.ImBool(cfg.settings.med),
	autopay = imgui.ImBool(cfg.settings.autopay),
	drugs = imgui.ImBool(cfg.settings.drugs),
	rem = imgui.ImBool(cfg.settings.rem),
	fill = imgui.ImBool(cfg.settings.fill),
	timestate = imgui.ImBool(cfg.settings.timestate),
	eat = imgui.ImBool(cfg.settings.eat),
	autoprize = imgui.ImBool(cfg.settings.autoprize),
	drift = imgui.ImBool(cfg.settings.drift),
}
local window = imgui.ImBool(false)
local musicmenu = imgui.ImBool(false)
local prmwindow = imgui.ImBool(false)
local cwindow = imgui.ImBool(false)
local bushelper = imgui.ImBool(false)
local imw_reconnecting = imgui.ImBool(false)
local minehelper = imgui.ImBool(false)
local farmhelper = imgui.ImBool(false)
local moving = false
local fishhelper = imgui.ImBool(false)
local kbset = imgui.ImBool(false)
local keyboard = imgui.ImBool(cfg.settings.keyboard)
local autorun = imgui.ImBool(cfg.settings.autorun)
local kbact = imgui.ImBool(cfg.keyboard.kbact)
local keyboard_pos = imgui.ImVec2(cfg.keyboard.posx, cfg.keyboard.posy)
local job = imgui.ImBool(cfg.settings.job)
local color = cfg.settings.color
local textcolor = '{c7c7c7}'
local capcha = imgui.ImBool(false)
local active = imgui.ImInt(cfg.settings.active)
local timestamp__fontsize = imgui.ImInt(cfg.timestamp.fontsize)
local edelay = imgui.ImInt(cfg.settings.edelay)
local gunmode = imgui.ImInt(cfg.settings.gunmode)
local masktimer = imgui.ImBool(cfg.settings.masktimer)
local colortheme = imgui.ImFloat3(cfg.settings.r, cfg.settings.g, cfg.settings.b) -- colortheme
--local colortheme = imgui.ImFloat3(0,0,0) -- colortheme
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
local prconnect = imgui.ImBool(cfg.settings.prconnect)
local al = imgui.ImBool(cfg.settings.al)
local theme = imgui.ImInt(cfg.settings.theme)
local cmds = imgui.ImBool(cfg.settings.cmds)
local ztimerstatus = imgui.ImBool(cfg.settings.ztimerstatus)
local fov = imgui.ImInt(cfg.settings.fov)
local mask = imgui.ImBool(cfg.settings.mask)
local move = imgui.ImBool(cfg.keyboard.move)
local fmenu = imgui.ImBool(cfg.settings.fmenu)
local finv = imgui.ImBool(cfg.settings.finv)
local lock = imgui.ImBool(cfg.settings.lock)
local autolock = imgui.ImBool(cfg.settings.autolock)
local cardlogin = imgui.ImBool(cfg.settings.cardlogin)
local spawn = imgui.ImBool(cfg.settings.spawn)
local logincard = imgui.ImInt(cfg.settings.logincard)
local hpmed = imgui.ImInt(cfg.settings.hpmed)
local balloon = imgui.ImBool(cfg.settings.balloon)
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

local oxladtime = 224 -- ����, �� ������� ������ ������

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
} -- ������� � ��� �� ���

local dtext = {}

keyboards = {
	{ -- ��� NumPad
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
	{ -- ������ �����
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
	["�"] = "q", ["�"] = "w", ["�"] = "e", ["�"] = "r", ["�"] = "t", ["�"] = "y", ["�"] = "u", ["�"] = "i", ["�"] = "o", ["�"] = "p", ["�"] = "[", ["�"] = "]", ["�"] = "a",
	["�"] = "s", ["�"] = "d", ["�"] = "f", ["�"] = "g", ["�"] = "h", ["�"] = "j", ["�"] = "k", ["�"] = "l", ["�"] = ";", ["�"] = "'", ["�"] = "z", ["�"] = "x", ["�"] = "c", ["�"] = "v",
	["�"] = "b", ["�"] = "n", ["�"] = "m", ["�"] = ",", ["�"] = ".", ["�"] = "Q", ["�"] = "W", ["�"] = "E", ["�"] = "R", ["�"] = "T", ["�"] = "Y", ["�"] = "U", ["�"] = "I",
	["�"] = "O", ["�"] = "P", ["�"] = "{", ["�"] = "}", ["�"] = "A", ["�"] = "S", ["�"] = "D", ["�"] = "F", ["�"] = "G", ["�"] = "H", ["�"] = "J", ["�"] = "K", ["�"] = "L",
	["�"] = ":", ["�"] = "\"", ["�"] = "Z", ["�"] = "X", ["�"] = "C", ["�"] = "V", ["�"] = "B", ["�"] = "N", ["�"] = "M", ["�"] = "<", ["�"] = ">"
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
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 16.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- ������ 30 ����� ������ ������
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
		msg('������� Skin Changer �� �������� � ������� ����.')
	end
end

-- main
function main()
    while not isSampAvailable() do wait(200) end
    if cfg.settings.theme == 0 then themeSettings(0) color = '{ff4747}'
		elseif cfg.settings.theme == 1 then themeSettings(1) color = '{00bd5c}'
		elseif cfg.settings.theme == 2 then themeSettings(2) color = '{007ABE}'
		elseif cfg.settings.theme == 3 then themeSettings(3) color = '{00C091}'
		elseif cfg.settings.theme == 4 then themeSettings(4) color = '{C27300}'
		elseif cfg.settings.theme == 5 then themeSettings(5) color = '{5D00C0}'
		elseif cfg.settings.theme == 6 then themeSettings(6) color = '{8CBF00}'
		elseif cfg.settings.theme == 7 then themeSettings(7) color = '{BF0072}'
		elseif cfg.settings.theme == 8 then themeSettings(8) color = '{755B46}'
		elseif cfg.settings.theme == 9 then themeSettings(9) color = '{5E5E5E}'
		elseif cfg.settings.theme == 10 then themeSettings(10)
		end
    if checkboxes.hello.v then
			if active.v == 0 then
				msg('������: '..color..'deveeh'..textcolor..' � '..color..'casparo'..textcolor..'. ������� ���������: '..color..'/oshelper') 
			end
			if active.v == 1 then
				msg('������: '..color..'deveeh'..textcolor..' � '..color..'casparo'..textcolor..'. ���-���: '..color..cfg.settings.cheatcode) 
			end
		end
    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if not doesFileExist(getWorkingDirectory()..'\\config\\OSHelper.ini') then inicfg.save(cfg, 'OSHelper.ini') msg('���������������� ���� OSHelper.ini ������������� ��������') end
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
		if prmanager.v then pronoroff = not pronoroff; msg(pronoroff and '������� ��������.' or '������� ���������.') end
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
			        sampSendChat('/showbizinfo '..arg1..' '..arg2) -- 2+ ���������
			    else
			        msg('/fin [id ������] [id �������]', -1)
			    end
			end
		end)
		sampRegisterChatCommand('oshelper', function() 
			if active.v == 0 then 
				window.v = not window.v
			else
				msg('� ��� �������� ��������� ����� ���-��� ('..cfg.settings.cheatcode..')') 
			end 
		end)
		sampRegisterChatCommand("ss", function() send('/setspawn') end)
		sampRegisterChatCommand("bus", function()
			if checkboxes.job.v then
				if checkboxes.bus.v then 
					bushelper.v = not bushelper.v
				else
					msg('� ��� �� �������� ������� Bus Helper.')  
				end
			else
				msg('� ��� �� �������� ������� Job Helper.')  
			end
		end)
		sampRegisterChatCommand("fish", function()
			if checkboxes.job.v then
				if checkboxes.fish.v then 
					fishhelper.v = not fishhelper.v
				else
					msg('� ��� �� �������� ������� Fish Helper.')  
				end
			else
				msg('� ��� �� �������� ������� Job Helper.')  
			end
		end)
		sampRegisterChatCommand("mine", function()
			if checkboxes.job.v then
				if checkboxes.mine.v then 
					minehelper.v = not minehelper.v
				else
					msg('� ��� �� �������� ������� Mine Helper.')  
				end
			else
				msg('� ��� �� �������� ������� Job Helper.')  
			end
		end)
		sampRegisterChatCommand("farm", function()
			if checkboxes.job.v then
				if checkboxes.farm.v then 
					farmhelper.v = not farmhelper.v
				else
					msg('� ��� �� �������� ������� Farm Helper.')  
				end
			else
				msg('� ��� �� �������� ������� Job Helper.')  
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
				msg('������� ����� �������� ������� ������ ������.')
			end 
		end)
		sampRegisterChatCommand('prm', function() 
			prmwindow.v = not prmwindow.v  
		end)
		sampRegisterChatCommand('osmusic', function()
			if osplayer.v then 
				musicmenu.v = not musicmenu.v 
			else
				msg('������� �������� OS Music � ������� ����.')
			end
		end)
		sampRegisterChatCommand('cc', function() 
			clearchat() 
		end)
	font = renderCreateFont("Arial", cfg.timestamp.fontsize, 5)
    while true do
        wait(0)
        imgui.Process = window.v or prmwindow.v or cwindow.v or musicmenu.v or bushelper.v or minehelper.v or farmhelper.v or fishhelper.v or calcactive or keyboard.v or kbset.v
        imgui.ShowCursor = kbset.v
        if not keyboard.v then kbact.v = false end if keyboard.v then kbact.v = true end
        timech = timech + 1
		if checkboxes.timestate.v  or moving then
			if moving then
				sampToggleCursor(true)
				local x, y = getCursorPos()
				cfg.timestamp.x = x
				cfg.timestamp.y = y
				if isKeyJustPressed(0x01) then
					moving = false
					sampToggleCursor(false)
					inicfg.save(cfg, 'OSHelper.ini')
				end
			end
			local date_table = os.date("*t")
			local hour, minute, second = date_table.hour, date_table.min, date_table.sec
			local result = string.format("%02d:%02d:%02d", hour, minute, second)

			renderFontDrawText(font, result, cfg.timestamp.x, cfg.timestamp.y, "0xFF"..cfg.settings.xcolor)
		end
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
	            result = '���������: '..number
	        end
	        if calctext:find('%d+%%%*%d+') then
	            number1, number2 = calctext:match('(%d+)%%%*(%d+)')
	            number = number1*number2/100
	            calcactive, number = pcall(load('return '..number))
	            result = textcolor..'���������: '..color..number
	        end
	        if calctext:find('%d+%%%/%d+') then
	            number1, number2 = calctext:match('(%d+)%%%/(%d+)')
	            number = number2/number1*100
	            calcactive, number = pcall(load('return '..number))
	            result = '���������: '..number
	        end
	        if calctext:find('%d+/%d+%%') then
	            number1, number2 = calctext:match('(%d+)/(%d+)%%')
	            number = number1*100/number2
	            calcactive, number = pcall(load('return '..number))
	            result = '���������: '..number..'%'
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
    		if checkboxes.drift.v then
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
				if autorun.v and isCharOnFoot(playerPed) and isKeyDown(0xA0) then 
					wait(10)				
					setGameKeyState(16, 0)
				end
        
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
	     	if checkboxes.med.v and isKeyDown(0x12) and wasKeyPressed(0x34) then send('/usemed') end
	     	local hpplayer = getCharHealth(PLAYER_PED)
	     	if checkboxes.med.v and automed.v then 
	     		hpcheck = hpmed.v + 1
	     		if hpplayer < hpcheck then send('/usemed') wait(1000) end
	     	end
	     	if checkboxes.eat.v and isKeyDown(0x12) and wasKeyPressed(0x35) then send('/eat') end
	     	if checkboxes.armor.v and isKeyDown(0x12) and wasKeyPressed(0x31) then
	     		local armourlvl = sampGetPlayerArmor(id)
	     		if armourlvl > 89 then 
		     		msg('� ��� '..armourlvl..' ��������� �����.')
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
	     	if checkboxes.drugs.v and isKeyDown(0x12) and wasKeyPressed(0x33) then send('/usedrugs 3') end
	     	if checkboxes.rem.v and wasKeyPressed(0x52) then send('/repcar') end
	     	if checkboxes.fill.v and wasKeyPressed(0x42) then send('/fillcar') end
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
					msg('����� ����� �������� ����������� �������, ������ ��������� �������� �� ����.')
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
	        wait(1000)
	        setVirtualKeyDown(74, true)
	        setVirtualKeyDown(74, false)
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

function createTextdraw()
	sampTextdrawCreate(1215, '', tonumber(134.33334350586), tonumber(365.79998779297))
	sampTextdrawSetLetterSizeAndColor(1215, tonumber(0.3), tonumber(1.2), '0xFF'..cfg.settings.xcolor)
	sampTextdrawSetOutlineColor(1215, 0.5, 0xFF000000)
	sampTextdrawSetAlign(1215, 2)
	sampTextdrawSetStyle(1215, 1)
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
	    if id == 269 or id == 0 and title:find('����� ���� ���������') or title:find('�������� ����������') then
			local automining_btcoverall = 0
			local automining_btcoverallph = 0
			local automining_btcamountoverall = 0
			local automining_videocards = 0
			local automining_videocardswork = 0
			for line in text:gmatch("[^\n]+") do
                dtext[#dtext+1] = line 
            end
			
			if dtext[1]:find('%(BTC%)') then
			    dtext[1] = dtext[1]:gsub('%(BTC%)', '%1 | �� 9 BTC')
			end
			
			for d = 1, #dtext do
				if dtext[d]:find('�����%s+�%d+%s+|%s+%{BEF781%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+%d+%p%d+%%') then	-- ������, �������� ��� ���
					automining_status = 1
					automining_statustext = '{BEF781}'
				else
					automining_status = 0
					automining_statustext = '{F78181}'
				end
				local automining_lvl = tonumber(dtext[d]:match('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+(%d+)%s+�������%s+%d+%p%d+%%')) -- ������� ������
				local automining_fillstatus = tonumber(dtext[d]:match('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%%')) -- ������ ������ � ���������
				local automining_btcamount = tonumber(dtext[d]:match('�����%s+�%d+%s+|%s+%{......%}%W+%s+(%d+%p%d+)%s+BTC%s+%d+%s+�������%s+%d+%p%d+%%')) -- ����� ������ ������ � ������              						
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
                    					
					automining_fillstatushours = math.ceil(oxladtime * (automining_fillstatus / 100)) -- �� ������� ����� ������
					automining_fillstatusbtc = automining_fillstatushours * INFO[automining_lvl] -- ������� ������ ��� ���� BTC
					automining_btcoverall = automining_btcoverall + automining_fillstatusbtc -- ������� ������� ����� ����� ��� ������
					automining_btcamountoverall = automining_btcamountoverall + math.floor(automining_btcamount) -- ������� ������� �������� ��� ������
					if automining_fillstatus > 0 and automining_status == 1 then
						automining_btcoverallph = automining_btcoverallph + INFO[automining_lvl]
					end
					dtext[d] = dtext[d]:gsub('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+'..automining_lvl..'%s+�������', '%1 | '..automining_statustext..INFO[automining_lvl]..'/���')
					if automining_fillstatus > 0 then
						dtext[d] = dtext[d]:gsub('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+|%s+%{......%}%d+%p%d+/���%s+'..automining_fillstatus..'%A+', '%1 '..tostring(automining_status and '{BEF781}' or '{F78181}')..'- [~'..automining_fillstatushours..' ���(��)] {FFFFFF}|{81DAF5} [~'..string.format("%.1f", automining_fillstatusbtc)..' BTC]')
					else
						dtext[d] = dtext[d]:gsub('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+|%s+%{......%}%d+%p%d+/���%s+'..automining_fillstatus..'%A+', '%1 {F78181}(!)')
					end
					dtext[d] = dtext[d]:gsub('�����%s+�%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+BTC', '%1 '..tostring(automining_btcamountinfo and '{BEF781}�' or '{F78181}�')..' {ffffff}| '..automining_statustext..'~'..automining_btctimetofull..'�')
				end				
			end
			
		if id == 269 and title:find('�������� ����������') then
            if worktread ~= nil then
                worktread:terminate()
            end			
		    local automining_fillstatus1 = tonumber(text:match('����� �1 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%A'))
			local automining_fillstatus2 = tonumber(text:match('����� �2 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%A'))
			local automining_fillstatus3 = tonumber(text:match('����� �3 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%A'))
			local automining_fillstatus4 = tonumber(text:match('����� �4 |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%A'))
			
			local automining_getbtcstatus1 = tonumber(text:match('����� �1 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+�������%s+%d+.'))
			local automining_getbtcstatus2 = tonumber(text:match('����� �2 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+�������%s+%d+.'))
			local automining_getbtcstatus3 = tonumber(text:match('����� �3 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+�������%s+%d+.'))
			local automining_getbtcstatus4 = tonumber(text:match('����� �4 |%s+%{......%}%W+%s+(%d+)%p%d+%s+BTC%s+%d+%s+�������%s+%d+.'))				
			
			for i = 1, 4 do
			    local automining_lvl = tonumber(text:match('����� �'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+(%d+)%s+�������%s+%d+.'))
				local automining_fillstatus = tonumber(text:match('����� �'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+(%d+%p%d+)%A'))
			    if automining_fillstatus ~= nil then
					if automining_fillstatus > 0 and automining_lvl ~= nil then
						automining_fillstatushours =  math.ceil(224 * (automining_fillstatus / 100))
						text = text:gsub('����� �'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������%s+%d+%p%d+%A', '%1 {BEF781}- [~'..automining_fillstatushours..' ���(��)]')	
					end				
					if automining_lvl > 0 then
						text = text:gsub('����� �'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+BTC%s+%d+%s+�������', '%1 | '..INFO[automining_lvl]..'/���')
					end
                end				
			end					
			
            if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				if automining_getbtc == 1 then
				    if automining_getbtcstatus1 ~= nil then
						if automining_getbtcstatus1 < 1 then
							automining_getbtc = 2
						elseif text:find('����� �1 | ��������') then
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
						elseif text:find('����� �2 | ��������') then
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
						elseif text:find('����� �3 | ��������') then
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
							msg('��� ������� ��� �������.')
							worktread = lua_thread.create(PressAlt)
						elseif text:find('����� �4 | ��������') then
							automining_getbtc = 10
							msg('��� ������� ��� �������.')
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
				    if text:find('����� �1 | {BEF781}��������') then
						automining_startall = 2
					elseif text:find('����� �1 | ��������') then
					    automining_startall = 2
					end
				end
				if automining_startall == 2 then
				    if text:find('����� �2 | {BEF781}��������') then
				        automining_startall = 3
					elseif text:find('����� �2 | ��������') then
					    automining_startall = 3
					end
				end
				if automining_startall == 3 then
				    if text:find('����� �3 | {BEF781}��������') then
				        automining_startall = 4
					elseif text:find('����� �3 | ��������') then
					    automining_startall = 4
					end
				end
				if automining_startall == 4 then
				    if text:find('����� �4 | {BEF781}��������') then
				        automining_startall = 10
						msg('��� ���������� ��� ��������.')
					    worktread = lua_thread.create(PressAlt)
					elseif text:find('����� �4 | ��������') then
					    automining_startall = 10
					    msg('��� ���������� ��� ��������.')
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
						elseif text:find('����� �1 | ��������') then
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
						elseif text:find('����� �2 | ��������') then
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
						elseif text:find('����� �3 | ��������') then
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
							msg('� ����������� ����� 75% ��������.')
							worktread = lua_thread.create(PressAlt)
						elseif text:find('����� �4 | ��������') then
							automining_fillall = 10
							msg('� ����������� ����� 75% ��������.')
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
		text = text .. '\n' .. color .. '����������\t' .. color .. '�������� �����\t' .. color .. '������� � ���\t' .. color .. '������� ��������������'
		text = text .. '\n' .. '{FFFFFF}�����: '..automining_videocards..' | {FFFFFF}��������: '..automining_videocardswork..'\t{FFFFFF}'..string.format("%.0f", automining_btcamountoverall)..' BTC\t{FFFFFF}'..automining_btcoverallph..' {FFFFFF}BTC\t{FFFFFF}'..string.format("%.1f", automining_btcoverall)..' {FFFFFF}BTC' 
			if title:find('�������� ����������') then	
				if text:find('����� �1 | ��������') and text:find('����� �2 | ��������') and text:find('����� �3 | ��������') and text:find('����� �4 | ��������') then
					text = text .. '\n' .. ' '
					text = text .. '\n' .. color .. '>> {FFFFFF}�� ������ ��� ���������, ������� ������� �� ���������'
					text = text .. '\n' .. color .. '>> {FFFFFF}�� ������ ��� ���������, �������� ���������� �� ���������'
					text = text .. '\n' .. color .. '>> {FFFFFF}�� ������ ��� ���������, ������ ����������� �������� �� ���������'
				else
					text = text .. '\n' .. ' '
					text = text .. '\n' .. color .. '>> {FFFFFF}������� �������'
					text = text .. '\n' .. color .. '>> {FFFFFF}��������� ����������'
					text = text .. '\n' .. color .. '>> {FFFFFF}������ ����������� �������� (�� 1 ��.)'
				end
			end
		automining_btcoverall = 0
	    automining_btcoverallph = 0        		
		return {id, style, title, button1, button0, text}
		end
		
		if id == 270 then	    
		    if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				if title:find('������ �%d+%s+| ����� �'..automining_getbtc..'') then	
					local automining_btcamount = tonumber(text:match('������� ������� %((%d+).%d+ '))
					if automining_btcamount ~= 0 then
						sampSendDialogResponse(270,1,1,nil) -- ��
					else
						automining_getbtc = automining_getbtc + 1
						sampSendDialogResponse(270,0,nil,nil)
						if automining_getbtc == 5 then
							msg('������� ��������� ��� � ���������.')
							automining_getbtc = 10
						end
					end
				else
				    sampSendDialogResponse(270,0,nil,nil)
					worktread = lua_thread.create(PressAlt)
				end
			end
			
		    if automining_startall == 1 or automining_startall == 2 or automining_startall == 3 or automining_startall == 4 then
				if text:find('��������� ����������') and title:find('������ �%d+%s+| ����� �'..automining_startall..'') then
				    sampSendDialogResponse(270,1,0,nil)
				    automining_startall = automining_startall + 1
				    sampSendDialogResponse(270,0,nil,nil)
				else
				    sampSendDialogResponse(270,0,nil,nil)
				end
				if automining_startall == 5 then
					msg('��� ���������� ��������.')
					automining_startall = 10
				end
			end

		    if automining_fillall == 1 or automining_fillall == 2 or automining_fillall == 3 or automining_fillall == 4 then
				if title:find('������ �%d+%s+| ����� �'..automining_fillall..'') then
				    sampSendDialogResponse(270,1,2,nil)
				    automining_fillall = automining_fillall + 1
				    worktread = lua_thread.create(PressAlt)
				else
				    worktread = lua_thread.create(PressAlt)
				end
				if automining_filltall == 5 then
					msg('�������� ������� ������.')
					sampSendDialogResponse(270,0,nil,nil)
					automining_startall = 10
					worktread = lua_thread.create(PressAlt)
				end
			end
	    end
		
	    if id == 271 and title:find('����� ������� ����������') then
     		if automining_getbtc == 1 or automining_getbtc == 2 or automining_getbtc == 3 or automining_getbtc == 4 then
				automining_getbtc = automining_getbtc + 1
				sampSendDialogResponse(271,1,nil,nil) -- ��
				worktread = lua_thread.create(PressAlt)
					if automining_getbtc == 5 then
						msg('������� ��������� ��� � ���������.')
						automining_getbtc = 10
					end
				return false
				end
	    end			
		end
	end
	if cardlogin.v and id == 782 then sampSendDialogResponse(782, 1, -1, logincard.v) end
	if ztimerstatus.v then
		if id == 0 and title:find('��������!') then
				lua_thread.create(function() 
				msg('�� �������� ��� ������� ����������, ������ 10 ����� �����.')
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
	if checkboxes.autoprize.v then
		if id == 519 and text:find('�� ��������� ��������') then 
			sampSendDialogResponse(519, 1, 1, "")
		elseif id == 519 and not text:find('�� ��������� ��������') then 
			sampSendDialogResponse(519, 1, 0, "")
			return false
		end
	end
	if id == 520 then 
		sampSendDialogResponse(520, 1, -1, "")
	end
	if checkboxes.autopay.v then 
		if id == 756 then  -- ������ �����
			sampSendDialogResponse(756, 1, 0, "")
		end
		
		if id == 672 or id == 671 then -- ������ ������
			sampSendDialogResponse(id, 1, -1, nil) 
			sampCloseCurrentDialogWithButton(1)
			return false
		end
	end
	if autoscreen.v and id == 44 then
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
			msg('���� �������, ��������...')
		end
		if id == 269 and list == 9 and button == 1 then
		    automining_startall = 1
	        worktread = lua_thread.create(PressAlt)
			msg('���������� �����������, ��������...')
		end
		if id == 269 and list == 10 and button == 1 then
		    automining_fillall = 1
	        worktread = lua_thread.create(PressAlt)
			msg('������� ���������� ������������ �� 50%, ��������...')
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
		if drugstimer.v and text:find('�������� ��������� ��') and not text:find('�������:') then
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
			if text:find('����� ����������') and armourlvl == 100 and not text:find('�������:') then
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
	  if antilomka.v and text:find('� ��� �������� �����') and not text:find('�������:') then
				send('/usedrugs 1')
		end
		bushelpermsg()
		minehelpermsg()
		farmhelpermsg()
end

function sampev.onServerMessage(color, text) --jobhelper
	if checkboxes.bus.v then
			if text:find('^������ �� ������� ����������:') and not text:find('�������:') then
	        local premia = text:match('(%d+)')
	        bhsalary = bhsalary + premia
	    elseif text:find('��� ���������: ������� "����� �������� ��������". ����� ������� ���������,') and not text:find('�������:') then
	        bhcases = bhcases + 1
	    elseif text:find('��� ���������: ������� "����� �������". ����� ������� ���������,') and not text:find('�������:') then
	        bhchert = bhchert + 1
	    elseif text:find('������� �� ��������') and not text:find('�������:') then
	        bhstop = bhstop + 1
	    end
	end
	if checkboxes.mine.v then
			if text:find('��� ���������: ������� "������". ����� ������� ���������,') and not text:find('�������:') then
	        mhstone = mhstone + 1
	    elseif text:find('��� ���������: ������� "������" +%D(%d+) ��+%D. ����� ������� ���������,') and not text:find('�������:') then
	    		mhstone = mhstone + tonumber(text:match("(%d+) ��"))  
	    end
	    if text:find('��� ���������: ������� "������". ����� ������� ���������,') and not text:find('�������:') then
	        mhmetall = mhmetall + 1
	    elseif text:find('��� ���������: ������� "������" +%D(%d+) ��+%D. ����� ������� ���������,') and not text:find('�������:') then
	    		mhmetall = mhmetall + tonumber(text:match("(%d+) ��"))  
	    end
	    if text:find('��� ���������: ������� "������". ����� ������� ���������,') and not text:find('�������:') then
	        mhmetall = mhbronze + 1
	    elseif text:find('��� ���������: ������� "������" +%D(%d+) ��+%D. ����� ������� ���������,') and not text:find('�������:') then
	    		mhbronze = mhbronze + tonumber(text:match("(%d+) ��"))  
	    end
	    if text:find('��� ���������: ������� "�������". ����� ������� ���������,') and not text:find('�������:') then
	        mhmetall = mhsilver + 1
	    elseif text:find('��� ���������: ������� "�������" +%D(%d+) ��+%D. ����� ������� ���������,') and not text:find('�������:') then
	    		mhmetall = mhsilver + tonumber(text:match("(%d+) ��"))  
	    end
	    if text:find('��� ���������: ������� "������". ����� ������� ���������,') and not text:find('�������:') then
	        mhgold = mhgold + 1
	    elseif text:find('��� ���������: ������� "������" +%D(%d+) ��+%D. ����� ������� ���������,') and not text:find('�������:') then
	    		mhgold = mhgold + tonumber(text:match("(%d+) ��"))  
	    end
	  end
	  if checkboxes.farm.v then
			if text:find('^��� ���������: ������� "˸�". ����� ������� ���������,') then
	        fhlyon = fhlyon + 1
	    elseif text:find('^��� ���������: �������� "˸�" %((%d+) ��%). ����� ������� ���������,') or text:find('^��� ���������: ��������� "˸�" %((%d+) ��%). ����� ������� ���������,') then
	    		fhlyon = fhlyon + tonumber(text:match("(%d+) ��"))  
	    end
	    if text:find('^��� ���������: ������� "������". ����� ������� ���������,') and not text:find('�������:') then
	        fhhlopok = fhhlopok + 1
	    elseif text:find('^��� ���������: �������� "������" %((%d+) ��%). ����� ������� ���������,') or text:find('^��� ���������: ��������� "������" %((%d+) ��%). ����� ������� ���������,') then
	    		fhhlopok = fhhlopok + tonumber(text:match("(%d+) ��"))  
	  	end
		end
		if checkboxes.fish.v then
			if text:find('��� ���������: ������� "����� ��������". ����� ������� ���������,') and not text:find('�������:') then
	        fishcase = fishcase + 1
	    elseif text:find('��� ���������: ������� "���� (%A+)". ����� ������� ���������,') and not text:find('�������:') then
	    		fishsalary = fishsalary + 15000 
	    end
		end
end


function eatchips()
		lua_thread.create(function()
			if checkboxes.eat.v and edelay.v > 0 then
				local eatdelay = cfg.settings.edelay * 60000 send('/eat') wait(eatdelay) return true
			end
		end)
end
-- imgui
local volume = imgui.ImInt(5)
function imgui.OnDrawFrame()
	if cfg.settings.theme == 0 then themeSettings(0) cfg.settings.color = '{ff4747}' cfg.settings.xcolor = 'FF4747'
	elseif cfg.settings.theme == 1 then themeSettings(1) cfg.settings.color = '{00bd5c}' cfg.settings.xcolor = '00bd5c'
	elseif cfg.settings.theme == 2 then themeSettings(2) cfg.settings.color = '{007ABE}' cfg.settings.xcolor = '007ABE'
	elseif cfg.settings.theme == 3 then themeSettings(3) cfg.settings.color = '{00C091}' cfg.settings.xcolor = '00C091'
	elseif cfg.settings.theme == 4 then themeSettings(4) cfg.settings.color = '{C27300}' cfg.settings.xcolor = 'C27300'
	elseif cfg.settings.theme == 5 then themeSettings(5) cfg.settings.color = '{5D00C0}' cfg.settings.xcolor = '5D00C0'
	elseif cfg.settings.theme == 6 then themeSettings(6) cfg.settings.color = '{8CBF00}' cfg.settings.xcolor = '8CBF00'
	elseif cfg.settings.theme == 7 then themeSettings(7) cfg.settings.color = '{BF0072}' cfg.settings.xcolor = 'BF0072'
	elseif cfg.settings.theme == 8 then themeSettings(8) cfg.settings.color = '{755B46}' cfg.settings.xcolor = '755B46'
	elseif cfg.settings.theme == 9 then themeSettings(9) cfg.settings.color = '{5E5E5E}' cfg.settings.xcolor = '5E5E5E'
	elseif cfg.settings.theme == 10 then themeSettings(10)
	end
    if window.v then
    		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 325), imgui.Cond.FirstUseEver)
        imgui.Begin('OS Helper v'..thisScript().version, window, imgui.WindowFlags.NoResize)
	        imgui.BeginChild("left", imgui.ImVec2(150, 290), true)
				if imgui.Selectable(fa.ICON_FA_USER..u8' ��������', menu == 1) then menu = 1
				elseif imgui.Selectable(fa.ICON_FA_CAR..u8' ���������', menu == 2) then menu = 2
				elseif imgui.Selectable(fa.ICON_FA_USERS..u8' �����', menu == 3) then menu = 3
				elseif imgui.Selectable(fa.ICON_FA_GLOBE..u8' ���������', menu == 8) then menu = 8
				elseif imgui.Selectable(fa.ICON_FA_COMMENTS..u8' ������ � �����', menu == 4) then menu = 4
				elseif imgui.Selectable(fa.ICON_FA_WINDOW_MAXIMIZE..u8' ������ � ���������', menu == 5) then menu = 5
				elseif imgui.Selectable(fa.ICON_FA_TASKS..u8' ����������', menu == 9) then menu = 9
				elseif imgui.Selectable(fa.ICON_FA_COG..u8' ���������', menu == 6) then menu = 6
				elseif imgui.Selectable(fa.ICON_FA_INFO_CIRCLE..u8' ����������', menu == 7) then menu = 7
				end
				imgui.SetCursorPosY(265)
				lua_thread.create(function()
					if updateversion == thisScript().version then
			        	if imgui.Button(u8'���������', imgui.ImVec2(135, 20)) then
			        		save()
									msg('��� ��������� ���������.')
			        	end
			    elseif updateversion ~= thisScript().version then
				        	if imgui.Button(u8'��������', imgui.ImVec2(135, 20)) then
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
        			imgui.CenterText(u8'�����')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'���� �����', fmenu) then cfg.settings.fmenu = fmenu.v end
				imgui.TextQuestion(u8'���������: ALT + F')
				if imgui.Checkbox(u8'������ � �����', finv) then cfg.settings.finv = finv.v end
				imgui.TextQuestion(u8'���������: F + 1')
			end
			if menu == 4 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'������ � �����')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'Chat Helper', chathelper) then cfg.settings.chathelper = chathelper.v end
				imgui.TextQuestion(u8'��������� � ����')
				if imgui.Checkbox(u8'Chat Calculator', calcbox) then cfg.settings.calcbox = calcbox.v end
				imgui.TextQuestion(u8'���������: 1+1 (� ���)')
				if imgui.Checkbox(u8'PR Manager', prmanager) then cfg.settings.prmanager = prmanager.v end
				imgui.TextQuestion(u8'����: /prm')
				if imgui.Checkbox(u8'����������� �������', cmds) then cfg.settings.cmds = cmds.v save() end
				if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                        imgui.Text(u8'/biz - /bizinfo\n/car [id] - /fixmycar\n/fh [id] - /findihouse\n/fbiz [id] - /findibiz\n/urc - /unrentcar\n/fin [id] [id biz] - /showbizinfo\n/ss - /setspawn')
                    imgui.EndTooltip()
                end
			end
			if menu == 5 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'������ � ���������')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'��������� � �����', cardlogin) then cfg.settings.cardlogin = cardlogin.v end
				imgui.TextQuestion(u8'�� �������� � ������ ���������')
				if cardlogin.v then 
				imgui.Text(u8'	���-���:')
				imgui.SameLine()
				imgui.PushItemWidth(54.5) 
				if imgui.InputInt(u8'##����� ����', logincard, 0, 0) then cfg.settings.logincard = logincard.v end
				end
				if imgui.Checkbox(u8'���������� �������', checkboxes.autopay) then cfg.settings.autopay = checkboxes.autopay.v end
				imgui.TextQuestion(u8'�� �������� � ������ ���������')
				if imgui.Checkbox(u8'�������� ���������� ������', checkboxes.autoprize) then cfg.settings.autoprize = checkboxes.autoprize.v end
				imgui.TextQuestion(u8'������������� �������� ����� � /dw_prizes')
				if imgui.Checkbox(u8'Mining Helper', mininghelper) then cfg.settings.mininghelper = mininghelper.v end
				imgui.TextQuestion(u8'���� �������, ���������� ��������� � ���� ������')
				if imgui.Checkbox(u8'����������� ����������', keyboard) then cfg.settings.keyboard = keyboard.v end
				if imgui.Checkbox(u8'����� �� ������', checkboxes.timestate) then cfg.settings.timestate = checkboxes.timestate.v end
				if checkboxes.timestate then
					imgui.Text(u8'	������ ������:')
					imgui.SameLine()
					imgui.PushItemWidth(72.5)  
					if imgui.InputInt('##Fontsize', timestamp__fontsize, 1, 1) then 
						if timestamp__fontsize.v < 1 then 
							timestamp__fontsize.v = 1 
						elseif timestamp__fontsize.v > 25 then
							timestamp__fontsize.v = 25 
						end 
						cfg.timestamp.fontsize = timestamp__fontsize.v
						font = renderCreateFont("Arial", cfg.timestamp.fontsize, 5) 
					end
					imgui.PopItemWidth()
					imgui.Text(u8'	�������� ������������:')
					imgui.SameLine()
					if imgui.Button('X', imgui.ImVec2(17.5, 20)) then moving = true end
					imgui.TextQuestion(u8'��� ��������� ������� ������� ���')
				end
				if imgui.Checkbox(u8'Autoscreen', autoscreen) then cfg.settings.autoscreen = autoscreen.v end
				imgui.TextQuestion(u8'��� ��������� ������� � ������������, \n������������� ����� /time � �������� F8')
				--[[if imgui.Checkbox(u8'���������� �����', capcha) then cfg.settings.capcha = capcha.v end
				if capcha.v then
				if imgui.InputInt(u8'##��������� �������', key, 0, 0) then cfg.settings.key = key.v end
				end]]--
				--imgui.TextQuestion(u8'���������: ALT + F')
			end
			if menu == 6 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'���������')
        		imgui.PopFont()
				imgui.Separator()
				imgui.offset(u8'��������� ����: ') 
			if imgui.Combo(u8'##���������', active, {u8'�������', u8'���-���'}, -1) then cfg.settings.active = active.v save() end
			if imgui.IsItemHovered() then
	            imgui.BeginTooltip()
	                imgui.Text(u8'����� ��������� ������ ���������, ��������� ������.')
	            imgui.EndTooltip()
            end
				if active.v == 1 then
					imgui.offset(u8' ���-���: ')
					--if imgui.InputText(u8'##���-���', cheatcode) then cfg.settings.cheatcode = cheatcode.v save() end
					if imgui.InputTextWithHint(u8"##��� ���", cfg.settings.cheatcode, cheatcode) then cfg.settings.cheatcode = cheatcode.v end
				end
				--if cheatcode.v == '' then cheatcode.v = 'oh' cfg.settings.cheatcode = 'oh' end
				imgui.offset(u8'����: ') 
					if imgui.Combo(u8'##����', theme, {u8'�������', u8'�������', u8'�����', u8'���������', u8'���������', u8'����������', u8'���������', u8'�������', u8'����������', u8'�����', u8'�����������������'}, -1) then cfg.settings.theme = theme.v save()
						if cfg.settings.theme == 0 then themeSettings(0) color = '{ff4747}'
						elseif cfg.settings.theme == 1 then themeSettings(1) color = '{00b052}'
						elseif cfg.settings.theme == 2 then themeSettings(2) color = '{007ABE}'
						elseif cfg.settings.theme == 3 then themeSettings(3) color = '{00C091}'
						elseif cfg.settings.theme == 4 then themeSettings(4) color = '{C27300}'
						elseif cfg.settings.theme == 5 then themeSettings(5) color = '{5D00C0}'
						elseif cfg.settings.theme == 6 then themeSettings(6) color = '{8CBF00}'
						elseif cfg.settings.theme == 7 then themeSettings(7) color = '{BF0072}'
						elseif cfg.settings.theme == 8 then themeSettings(8) color = '{755B46}'
						elseif cfg.settings.theme == 9 then themeSettings(9) color = '{5E5E5E}'
					end
				end
				if theme.v == 10 then
					imgui.Text(u8'	���� ����: ')
			    imgui.SameLine()
			    if imgui.ColorEdit3('##colortheme', colortheme, imgui.ColorEditFlags.NoInputs) then
			       	color = join_rgba(colortheme.v[1] * 255, colortheme.v[2] * 255, colortheme.v[3] * 255, 0)
					cfg.settings.r, cfg.settings.g, cfg.settings.b = colortheme.v[1], colortheme.v[2], colortheme.v[3]
					cfg.settings.xcolor = ('%06X'):format(color)
			        color = '{'..('%06X'):format(color)..'}'
					cfg.settings.color = color
    			end
				end
				if imgui.Checkbox(u8'�������������� ���������', checkboxes.hello) then cfg.settings.hello = checkboxes.hello.v end
				imgui.SetCursorPosX(89)
				--[[if imgui.Button(u8'RELOAD', imgui.ImVec2(150, 20)) then
					showCursor(false, false)
           			thisScript():reload()
        		end]]--
			end
			if menu == 7 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'����������')
        		imgui.PopFont()
				imgui.Separator()
				imgui.Text(u8'OS Helper - ���������� ����� ������,\n ������������ �� ���������� ����� \n ��� ������� �������, ��� � ������� �����������. \n ������ �� �� ��������� � ���� ���� ��� ��������.\n ��� �������� ������ ���������� \n ���������� �������� � ����� \n ���������� ���������� �� ����� ����.')
				imgui.Text('')
				imgui.Text(u8'������:') imgui.SameLine() imgui.Link('https://vk.com/deveeh', 'deveeh') imgui.SameLine() imgui.Text(u8'�') imgui.SameLine() imgui.Link('https://t.me/atimohov', 'casparo')
				imgui.Text(u8'������ ���������:') imgui.SameLine() imgui.Link('https://vk.com/oshelper_rodina', 'vk.com/oshelper_rodina')
				imgui.Text(u8'����� ���?') imgui.SameLine() imgui.Link('https://vk.com/topic-215734333_49024979', u8'��� ����!')
			end
			if menu == 8 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'���������')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'�������� ������� � ������', timeweather) then cfg.settings.timeweather = timeweather.v end
				if timeweather.v then
					imgui.PushItemWidth(75)
					imgui.Text(u8'	�����: ')
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
					imgui.Text(u8'	������: ')
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
				if imgui.Checkbox(u8'��������� FOV', fisheye) then cfg.settings.fisheye = fisheye.v end
				if fisheye.v then
					imgui.Text(u8'	FOV:') imgui.SameLine()
					if imgui.SliderInt('##FOV', fov, 1, 100) then cfg.settings.fov = fov.v end
				end
			end
			if menu == 9 then
				imgui.PushFont(fontsize)
        			imgui.CenterText(u8'����������')
        		imgui.PopFont()
				imgui.Separator()
				if imgui.Checkbox(u8'OS Music', osplayer) then cfg.settings.osplayer = osplayer.v end
				imgui.TextQuestion(u8'���������: /osmusic\n����� ��������� ���� �����, �������� ����� � �����, \n����� ������� � moonloader/OS Helper/OS Music.')
				if imgui.Checkbox(u8'Job Helper', checkboxes.job) then cfg.settings.job = checkboxes.job.v end
				imgui.TextQuestion(u8'������ �������� ��� ����� ������� ������')
				if checkboxes.job.v then
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Bus Helper', checkboxes.bus) then cfg.settings.bus = checkboxes.bus.v end
					imgui.TextQuestion(u8'���������: /bus\n������� ��������� �� ������ �����������')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Mine Helper', checkboxes.mine) then cfg.settings.mine = checkboxes.mine.v end
					imgui.TextQuestion(u8'���������: /mine\n������� ��������� �� ������ �������')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Farm Helper', checkboxes.farm) then cfg.settings.farm = checkboxes.farm.v end
					imgui.TextQuestion(u8'���������: /farm\n������� ��������� �� ������ �������')
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'Fish Helper', checkboxes.fish) then cfg.settings.fish = checkboxes.fish.v end
					imgui.TextQuestion(u8'���������: /fish\n������� ��������� �� ������ ��������')
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
	        	if imgui.Checkbox(u8'������� � VIP CHAT (/vr)', vr1) then cfg.settings.vr1 = vr1.v end
				if vr1.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##vr1", u8"�������� �� ��������� �56!", vrmsg1) then cfg.settings.vrmsg1 = vrmsg1.v end
					end
				if imgui.Checkbox(u8'������� � FAMILY CHAT (/fam)', fam) then cfg.settings.fam = fam.v end
				if fam.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##fammsg", u8"�������� �� ����� �57!", fammsg) then cfg.settings.fammsg = fammsg.v end
				end
				if imgui.Checkbox(u8'������� � ALLIANCE CHAT (/al)', al) then cfg.settings.al = al.v end
				if al.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##almsg", u8"�������� �� ��������� �56!", almsg) then cfg.settings.almsg = almsg.v end
					end
				if imgui.Checkbox(u8'������� � AD (/ad 1)', adbox) then cfg.settings.adbox = adbox.v end
				if adbox.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##admsg1", u8"�������� �� ��������� �56!", admsg1) then cfg.settings.admsg1 = admsg1.v end
				end
				if imgui.Checkbox(u8'������� � NRP CHAT (/b)', bchat) then cfg.settings.bchat = bchat.v end
				if bchat.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##bmsg", u8"�������� �� ����� �57!", bmsg) then cfg.settings.bmsg = bmsg.v end
				end
				if imgui.Checkbox(u8'�������������� ������', prstring) then cfg.settings.prstring = prstring.v end
				if prstring.v then
					imgui.Text(u8'���������: ')
					imgui.SameLine()
					if imgui.InputTextWithHint(u8"##prstring", u8"/vr �������� �� ����� �57!", stringmsg) then cfg.settings.stringmsg = stringmsg.v end
				end
				imgui.Separator()
				imgui.Text(u8'��������: ')
				imgui.SameLine()
				imgui.PushItemWidth(40)
				if imgui.InputInt("##��������", delay, 0, 0) then cfg.settings.delay = delay.v end
				imgui.SameLine() 
				imgui.Text(u8'���.')
				imgui.Text(u8'���������: /pr')
		    else
		    	imgui.CenterText(u8'�������� � ������� ���� ������� PR Manager.')
		    end
		    imgui.SetCursorPos(imgui.ImVec2(5, 375))
		    if imgui.Button(u8'���������', imgui.ImVec2(290, 20)) then
		        save()
		        msg('��� ��������� ���������.')
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
		imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(5.0, 2.4)) -- ���� ��������� ������
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0)) -- ������� ���
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
        	imgui.CenterText(u8'��������')
        imgui.PopFont()
        imgui.Separator()
        if imgui.Checkbox(u8'����������', checkboxes.armor) then cfg.settings.armor = checkboxes.armor.v end
				imgui.TextQuestion(u8'������������ ����������: ALT + 1\n��������� ������� �������� ����� ��������� ������� �������')
				if checkboxes.armor.v then imgui.Text('	') imgui.SameLine()  if imgui.Checkbox(u8'�����������', armortimer) then cfg.settings.armortimer = armortimer.v end end
				if imgui.Checkbox(u8'�����', mask) then cfg.settings.mask = mask.v end
				imgui.TextQuestion(u8'������������ �����: ALT + 2')
				if imgui.Checkbox(u8'��������� (3 ��)', checkboxes.drugs) then cfg.settings.drugs = checkboxes.drugs.v end
				imgui.TextQuestion(u8'������������ �����: ALT + 3\n��������� ������� � ��������� �������� ����� ��������� ������� �������')
				if checkboxes.drugs.v then 
					imgui.Text('	') imgui.SameLine()  
					if imgui.Checkbox(u8'�����������', drugstimer) then cfg.settings.drugstimer = drugstimer.v end
					imgui.Text('	') imgui.SameLine() 
					if imgui.Checkbox(u8'���������', antilomka) then cfg.settings.antilomka = antilomka.v end  
				end
				if imgui.Checkbox(u8'�������', checkboxes.med) then cfg.settings.med = checkboxes.med.v end
				imgui.TextQuestion(u8'������������ �������: ALT + 4\n��������� ��������� �������� ����� ��������� ������� �������')
				if checkboxes.med.v then
					imgui.Text('	') imgui.SameLine()
					if imgui.Checkbox(u8'��������', automed) then cfg.settings.automed = automed.v end
					if automed.v then
						imgui.Text('		HP:') imgui.SameLine() 
						imgui.PushItemWidth(73) 
						if imgui.InputInt("##��������", hpmed) then 
							if hpmed.v > 99 then
								hpmed.v = 99
							elseif hpmed.v < 1 then
								hpmed.v = 1
							end
							cfg.settings.hpmed = hpmed.v 
							save() 
						end
						imgui.PopItemWidth()
					end
				end
				if imgui.Checkbox(u8'�������������', autorun) then cfg.settings.autorun = autorun.v end
				imgui.TextQuestion(u8'��� ������� �� ������ ����, �������� ��������� �� ������� ���')
				if imgui.Checkbox(u8'���', checkboxes.eat) then cfg.settings.eat = checkboxes.eat.v end
				imgui.TextQuestion(u8'������������ �����: ALT + 5\n��������� ������� �������� ����� ��������� ������� �������')
				if checkboxes.eat.v then
					imgui.Text(u8'	��������:')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.InputInt("##edelay", edelay) then cfg.settings.edelay = edelay.v save() 
						if edelay.v > 0 then eatchips() end
					end
					imgui.SameLine()
					imgui.Text(u8'���.')
					imgui.TextQuestion(u8'��� ����� 0 � ����, ������� ����� ���������')
					imgui.PopItemWidth() 
				end
				if imgui.Checkbox(u8'Z-Timer', ztimerstatus) then cfg.settings.ztimerstatus = ztimerstatus.v end
				imgui.TextQuestion(u8'����� ������ ����� Z, �������� ������ 600 ������')
				if imgui.Checkbox(u8'����-������', balloon) then cfg.settings.balloon = balloon.v end
				imgui.TextQuestion(u8'���������: ALT + C (�������)\n������ ��� ������ ����/����������� ����� � �.�.')
				if imgui.Checkbox(u8'����������� ���', infrun) then cfg.settings.infrun = infrun.v end
				imgui.TextQuestion(u8'��������� ��������������\n�� ��������� ������ ��������� �� ����')
				if imgui.Checkbox(u8'Skin Changer', vskin) then cfg.settings.vskin = vskin.v end 
				imgui.TextQuestion(u8'���������: /skin [ID]\n���� ����� ������ ���\n��� ��, �� ��� �� �������� �������������� 92, 99 � 320+ �������,\n��� ��� ��� ���� ������������ � ����')
				if imgui.Checkbox(u8'����� ������', gunmaker) then cfg.settings.gunmaker = gunmaker.v end
				imgui.TextQuestion(u8'���������: /cg')
				if gunmaker.v then
					imgui.Text(u8'	������: ')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.Combo(u8'##����� ����', gunmode, {u8'Deagle', u8'M4', u8'Shotgun'}, -1) then cfg.settings.gunmode = gunmode.v save() imgui.PopItemWidth() end
					imgui.Text(u8'	�������:')
					imgui.SameLine()
					imgui.PushItemWidth(75)
					if imgui.InputInt("##�������", bullet, 0, 0) then cfg.settings.bullet = bullet.v save() end
					if gunmode.v == 0 then
						ammo = bullet.v * 2
					elseif gunmode.v == 1 then
						ammo = bullet.v * 2
					elseif gunmode.v == 2 then
						ammo = bullet.v * 10
					end
					imgui.Text(u8'	��������� ������: '..ammo..u8' ���.')
					end
end

function transport()
					imgui.PushFont(fontsize)
        			imgui.CenterText(u8'���������')
        		imgui.PopFont()
        		imgui.Separator()
				if imgui.Checkbox(u8'AutoCar', autolock) then cfg.settings.autolock = autolock.v end
				imgui.TextQuestion(u8'���������: ����� � ������\n�������������� �������� ������, ������������� � ��������� ���������')
				if imgui.Checkbox(u8'�������/������� �����', lock) then cfg.settings.lock = lock.v end
				imgui.TextQuestion(u8'���������: L, K (�����. �/�)')
				if imgui.Checkbox(u8'�����������', checkboxes.rem) then cfg.settings.rem = checkboxes.rem.v end
				imgui.TextQuestion(u8'������������ �����������: R')
				if imgui.Checkbox(u8'��������', checkboxes.fill) then cfg.settings.fill = checkboxes.fill.v end
				imgui.TextQuestion(u8'������������ ��������: B')
				if imgui.Checkbox(u8'����� ����������', spawn) then cfg.settings.spawn = spawn.v end
				imgui.TextQuestion(u8'�������������: �������� ���� (�������)')
				if imgui.Checkbox(u8'�������� ���������', open) then cfg.settings.open = open.v end
				imgui.TextQuestion(u8'������� ��������: O')
				if imgui.Checkbox(u8'+W moto/bike', plusw) then cfg.settings.plusw = plusw.v end
				imgui.TextQuestion(u8'�������������: W (�������)\n������ ��� ����������� � ����������')
				if imgui.Checkbox(u8'�����', checkboxes.drift) then cfg.settings.drift = checkboxes.drift.v end
				imgui.TextQuestion(u8'���������: LSHIFT (�������)\n���������� �������')
				--[[if imgui.Checkbox(u8'����� ��������', ballooncolor) then balloncolor = not balloncolor if ballooncolor then 
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
						imgui.Text(u8'���������:')
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
            imgui.Text(u8'�������� ���������: '..bhsalary..u8' ���.')
            imgui.Text(u8'���������� ���������: '..bhstop..u8' ���.')
            imgui.Text(u8'������ ������: '..bhcases..u8' ���.')
            imgui.Text(u8'������ ��������: '..bhchert..u8' ����.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'�������� ����������', imgui.ImVec2(205, 20)) then
                bhsalary = 0
                bhstop = 0
                bhcases = 0
                bhchert = 0
            end
            if imgui.Button(u8'������ ������', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if minehelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 170), imgui.Cond.FirstUseEver)
        imgui.Begin('Mine Helper (OS v'..thisScript().version..')##minehelper', minehelper, imgui.WindowFlags.NoResize)
            imgui.Text(u8'������: '..mhstone..u8' ��.')
            imgui.Text(u8'������: '..mhmetall..u8' ��.')
            imgui.Text(u8'������: '..mhbronze..u8' ��.')
            imgui.Text(u8'�������: '..mhsilver..u8' ��.')
            imgui.Text(u8'������: '..mhgold..u8' ��.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'�������� ����������', imgui.ImVec2(205, 20)) then
                mhstone = 0
                mhmetall = 0
                mhbronze = 0
                mhsilver = 0
                mhgold = 0
            end
            if imgui.Button(u8'������ ������', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if farmhelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 115), imgui.Cond.FirstUseEver)
        imgui.Begin('Farm Helper (OS v'..thisScript().version..')##farmhelper', farmhelper, imgui.WindowFlags.NoResize)
            imgui.Text(u8'˸�: '..fhlyon..u8' ��.')
            imgui.Text(u8'������: '..fhhlopok..u8' ��.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'�������� ����������', imgui.ImVec2(205, 20)) then
                fhlyon = 0
                fhhlopok = 0
            end
            if imgui.Button(u8'������ ������', imgui.ImVec2(205, 20)) then
                imgui.ShowCursor = false
            end
        imgui.End()
    end
    if fishhelper.v then
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 , resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(220, 115), imgui.Cond.FirstUseEver)
        imgui.Begin('Fish Helper (OS v'..thisScript().version..')##fishhelper', fishhelper, imgui.WindowFlags.NoResize)
            imgui.Text(u8'���������: '..fishsalary..u8' ���.')
            imgui.TextQuestion(u8'��������� �������������, 1 ���� = 15.000���')
            imgui.Text(u8'�����: '..fishcase..u8' ��.')
            --imgui.SetCursorPos(imgui.ImVec2(300, 382.5))
            if imgui.Button(u8'�������� ����������', imgui.ImVec2(205, 20)) then
                fishsalary = 0
                fishcase = 0
            end
            if imgui.Button(u8'������ ������', imgui.ImVec2(205, 20)) then
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
	 if theme == 0 or nil then
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
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
	elseif theme == 1 then -- �������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.87, 0.42, 1.00);
		colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00);
		colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00);
	  colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57);
	  colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89);
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
	elseif theme == 2 then -- �����
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.00, 0.48, 0.75, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.00, 0.48, 0.75, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.46, 0.71, 1.00);
		colors[clr.Button]                 = ImVec4(0.00, 0.48, 0.75, 1.00);
		colors[clr.ButtonHovered]          = ImVec4(0.00, 0.71, 0.94, 1.00);
		colors[clr.ButtonActive]           = ImVec4(0.00, 0.46, 0.71, 1.00);
		colors[clr.Header]                 = ImVec4(0.00, 0.48, 0.75, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.00, 0.71, 0.94, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.00, 0.46, 0.71, 1.00);
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
	elseif theme == 3 then -- ���������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.00, 0.75, 0.57, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.00, 0.75, 0.57, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.71, 0.46, 1.00);
		colors[clr.Button]                 = ImVec4(0.00, 0.75, 0.57, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.00, 0.94, 0.60, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.00, 0.71, 0.46, 1.00);
		colors[clr.Header]                 = ImVec4(0.00, 0.75, 0.57, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.00, 0.94, 0.60, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.00, 0.71, 0.46, 1.00);
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
	elseif theme == 4 then -- ���������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.76, 0.45, 0.00, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.76, 0.45, 0.00, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.71, 0.38, 0.00, 1.00);
		colors[clr.Button]                 = ImVec4(0.76, 0.45, 0.00, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.94, 0.45, 0.00, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.71, 0.38, 0.00, 1.00);
		colors[clr.Header]                 = ImVec4(0.76, 0.45, 0.00, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.94, 0.45, 0.00, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.71, 0.38, 0.00, 1.00);
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
	elseif theme == 5 then -- ����������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.37, 0.00, 0.75, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.37, 0.00, 0.75, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.31, 0.00, 0.71, 1.00);
		colors[clr.Button]                 = ImVec4(0.37, 0.00, 0.75, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.47, 0.00, 0.94, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.31, 0.00, 0.71, 1.00);
		colors[clr.Header]                 = ImVec4(0.37, 0.00, 0.75, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.47, 0.00, 0.94, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.31, 0.00, 0.71, 1.00);
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
	elseif theme == 6 then -- ���������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.55, 0.75, 0.00, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.55, 0.75, 0.00, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.49, 0.71, 0.00, 1.00);
		colors[clr.Button]                 = ImVec4(0.55, 0.75, 0.00, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.64, 0.94, 0.00, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.49, 0.71, 0.00, 1.00);
		colors[clr.Header]                 = ImVec4(0.55, 0.75, 0.00, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.64, 0.94, 0.00, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.49, 0.71, 0.00, 1.00);
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
	elseif theme == 7 then -- �������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.75, 0.000, 0.45, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.75, 0.000, 0.45, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.71, 0.00, 0.51, 1.00);
		colors[clr.Button]                 = ImVec4(0.75, 0.000, 0.45, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.94, 0.00, 0.73, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.71, 0.00, 0.51, 1.00);
		colors[clr.Header]                 = ImVec4(0.75, 0.000, 0.45, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.94, 0.00, 0.73, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.71, 0.00, 0.51, 1.00);
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
	elseif theme == 8 then -- ����������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.46, 0.36, 0.28, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.46, 0.36, 0.28, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.42, 0.33, 0.26, 1.00);
		colors[clr.Button]                 = ImVec4(0.46, 0.36, 0.28, 1.00);
	  colors[clr.ButtonHovered]          = ImVec4(0.58, 0.46, 0.37, 1.00);
	  colors[clr.ButtonActive]           = ImVec4(0.42, 0.33, 0.26, 1.00);
		colors[clr.Header]                 = ImVec4(0.46, 0.36, 0.28, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.58, 0.46, 0.37, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.42, 0.33, 0.26, 1.00);
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
	elseif theme == 9 then -- �����
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
		colors[clr.CheckMark]              = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.SliderGrab]             = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(0.33, 0.33, 0.33, 1.00);
		colors[clr.Button]                 = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.ButtonHovered]          = ImVec4(0.46, 0.46, 0.46, 1.00);
		colors[clr.ButtonActive]           = ImVec4(0.33, 0.33, 0.33, 1.00);
		colors[clr.Header]                 = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.HeaderHovered]          = ImVec4(0.46, 0.46, 0.46, 1.00);
		colors[clr.HeaderActive]           = ImVec4(0.33, 0.33, 0.33, 1.00);
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
	elseif theme == 10 then -- ���������
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
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.12, 0.12, 0.12, 1.00);
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.36, 0.36, 0.36, 1.00);
		colors[clr.ComboBg]                = ImVec4(0.02, 0.02, 0.02, 0.39);
		colors[clr.CheckMark]              = ImVec4(colortheme.v[1], colortheme.v[2], colortheme.v[3], 1.00);
		colors[clr.SliderGrab]             = ImVec4(colortheme.v[1], colortheme.v[2], colortheme.v[3], 1.00);
		colors[clr.SliderGrabActive]       = ImVec4(colortheme.v[1] / (1/0.75), colortheme.v[2] / (1/0.75), colortheme.v[3] / (1/0.75), 1.00);
		colors[clr.Button]                 = ImVec4(colortheme.v[1], colortheme.v[2], colortheme.v[3], 1.00);
		colors[clr.ButtonHovered]          = ImVec4(colortheme.v[1] / (1/2), colortheme.v[2] / (1/2), colortheme.v[3] / (1/2), 1.00);
		colors[clr.ButtonActive]           = ImVec4(colortheme.v[1] / (1/0.75), colortheme.v[2] / (1/0.75), colortheme.v[3] / (1/0.75), 1.00);
		colors[clr.Header]                 = ImVec4(colortheme.v[1], colortheme.v[2], colortheme.v[3], 1.00);
		colors[clr.HeaderHovered]          = ImVec4(colortheme.v[1] / (1/2), colortheme.v[2] / (1/2), colortheme.v[3] / (1/2), 1.00);
		colors[clr.HeaderActive]           = ImVec4(colortheme.v[1] / (1/0.75), colortheme.v[2] / (1/0.75), colortheme.v[3] / (1/0.75), 1.00);
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