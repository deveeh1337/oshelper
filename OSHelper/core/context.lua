-- OS Helper 2.0 context / shared runtime
require 'lib.moonloader'

local _imgui = require 'mimgui'
_G.imgui = _imgui
_G.new = _imgui.new
_G.dlstatus = require('moonloader').download_status
_G.fa = require 'fAwesome6'
_G.vk = require 'vkeys'
_G.wm = require 'windows.message'
_G.sampev = require 'lib.samp.events'
_G.ffi = require 'ffi'
_G.mem = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
_G.u8 = encoding.UTF8

imgui.Process = false
imgui.ShowCursor = false

ffi.cdef[[
    short GetKeyState(int nVirtKey);
    bool GetKeyboardLayoutNameA(char* pwszKLID);
    int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);
    int GetKeyNameTextA(long lParam, char* lpString, int cchSize);
    typedef unsigned long DWORD;
    DWORD GetTickCount();
]]

function FfiBuffer(value, size)
    size = tonumber(size) or 64
    if size < 2 then size = 2 end
    local buf = ffi.new('char[?]', size)
    if value ~= nil then
        local text = tostring(value)
        if text ~= '' then
            ffi.copy(buf, text, math.min(#text, size - 1))
        end
    end
    return buf
end
local DEFAULT_CFG = {
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
		jack = false,
		mask = false,
		lock = false,
		timeweather = false,
		cardlogin = false,
		mininghelper = false,
		spawn = false,
        bindArmorLimit = 90,
		antilomka = false,
		al = false,
		vskin = false,
		adbox = false,
		adbox2 = false,
		plusw = false,
		chathelper = false,
		drift = false,
		calcbox = false,
		vr2 = false,
		balloon = false,
		eat = false,
		podarok = false,
		gunmaker = false,
		job = false,
		drugstimer = false,
		fish = false,
		infrun = false,
		chateditor = false,
		ztimerstatus = false,
		prsh1 = 0,
		prsh2 = 0,
		prsh3 = 56,
		prsh4 = 1,
		keyboard = false,
		autopay = false,
		prsh5 = 0,
		buttonjump = 0,
		delay = 30,
		autoclickerDelay = 50,
		edelay = 0,
		fisheye = false,
		logincard = 123456,
		fov = 100,
		fov_aim = false,
		autorun = false,
		r = 0.00,
		g = 0.00,
		b = 0.00,
		chatstrings = 10,
		chatfontsize = 0,
	},
	keyboard = {
		kbact = false,
		posx = 10,
		posy = 500,
		move = false,
	},
	keylogger = {
		active = false,
	},
	infopanel = {
		doppanel = false,
		x = 0,
		y = 0,		
		nickact = false,
		timeact = false,
		daysact = false,
		fpsact = false,
		pingact = false,
		skinact = false,
		armouract = false,
		hpact = false,
	},
	onlinepanel = {
		activepanel = false,
		x = 0,
		y = 0,
		sesOnline = false,
		sesAfk = false,
		sesFull = false,
		dayOnline = false,
  		dayAfk = false,
  		dayFull = false,
	},
	onDay = {
		today = os.date("%a"),
		online = 0,
		afk = 0,
		full = 0
	},

	gamefixer = {
		nobirds = true,
		nocloudbig = true,
		nocloudsmall = true,
		vehlods = false,
		postfx = true,
		effects = true,
		sensfix = false,
		sunfix = true,
		targetblip = true,
		fpslimit = 60,
		fpslimit_enabled = false,
		unlimitfps = false,
		forceaniso = false,
		anticrasher = false,
	},
	distanceManager = {enabled = false, nametags = 8, tdtext = 8, chatbubbles = 6, fog = 0, lods = 150},
	distance = {nametags = 8, tdtext = 8, chatbubbles = 6, lods = 150},
}local Config = require 'OSHelper.core.config'
_G.Config = Config

_G.cfg = Config.load(DEFAULT_CFG)

-- Safe defaults for UI before the first game-state tick.
id, nick, ping, lvl, fps, skinid = 0, '', 0, 0, 0, 0
health, armour = 0, 0
nowTime = ''
connectingTime = 0
startTime = os.time()
onDay = false
result = ''
calctext = ''
calcactive = false
-- Custom hotkeys. Each bind stores a main VK and optional modifiers.
DEFAULT_BINDS = {
    armor = {key = 0x31, alt = true, ctrl = false, shift = false},
    mask  = {key = 0x32, alt = true, ctrl = false, shift = false},
    drugs = {key = 0x33, alt = true, ctrl = false, shift = false},
    med   = {key = 0x34, alt = true, ctrl = false, shift = false},
    eat   = {key = 0x35, alt = true, ctrl = false, shift = false},
    rem   = {key = 0x52, alt = false, ctrl = false, shift = false},
    fill  = {key = 0x42, alt = false, ctrl = false, shift = false},
    jack  = {key = 0x4A, alt = false, ctrl = false, shift = false},
    balloon = {key = 0x06, alt = false, ctrl = false, shift = false},
    autorun = {key = 0xA0, alt = false, ctrl = false, shift = false},
    lock  = {key = 0x4C, alt = false, ctrl = false, shift = false},
    jlock = {key = 0x4B, alt = false, ctrl = false, shift = false},
    spawn = {key = 0x04, alt = false, ctrl = false, shift = false},
}

cfg.binds = cfg.binds or {}
for bindName, def in pairs(DEFAULT_BINDS) do
    local b = cfg.binds[bindName]
    if type(b) ~= 'table' then
        cfg.binds[bindName] = {key = def.key, alt = def.alt, ctrl = def.ctrl, shift = def.shift}
    else
        if b.key == nil then b.key = def.key end
        if b.alt == nil then b.alt = def.alt end
        if b.ctrl == nil then b.ctrl = def.ctrl end
        if b.shift == nil then b.shift = def.shift end
    end
end


-- DEBUG: UI lifecycle trace (disable by setting UI_DEBUG=false)
UI_DEBUG = true
UI_DEBUG_PATH = getWorkingDirectory() .. "\\OSHelper\\OSHelper_ui_debug.log"
function uiDebug(tag, ...)
    if not UI_DEBUG then return end
    local parts = { os.date("[%H:%M:%S]"), tag }
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    local f = io.open(UI_DEBUG_PATH, "a")
    if f then
        f:write(table.concat(parts, " "), "\n")
        f:close()
    end
end
uiDebug("BOOT", "UI debug enabled")

if cfg.settings.autoclickerDelay == nil then cfg.settings.autoclickerDelay = cfg.settings.clickerDelay or 50 end

-- variables
frames = {
	window = new.bool(false),
	cwindow = new.bool(false),
	bushelper = new.bool(false),
	minehelper = new.bool(false),
	farmhelper = new.bool(false),
	fishhelper = new.bool(false),
	kbset = new.bool(false),
	colors = new.bool(false),
	mypanel = new.bool(cfg.infopanel.doppanel),
	onlinepanel = new.bool(cfg.onlinepanel.activepanel),
}
checkboxes = {
	job = new.bool(cfg.settings.job),
	bus = new.bool(cfg.settings.bus),
	mine = new.bool(cfg.settings.mine),
	farm = new.bool(cfg.settings.farm),
	fish = new.bool(cfg.settings.fish),
	hello = new.bool(cfg.settings.hello),
	armor = new.bool(cfg.settings.armor),
	med = new.bool(cfg.settings.med),
	autopay = new.bool(cfg.settings.autopay),
	drugs = new.bool(cfg.settings.drugs),
	rem = new.bool(cfg.settings.rem),
	jack = new.bool(cfg.settings.jack),
	fill = new.bool(cfg.settings.fill),
	eat = new.bool(cfg.settings.eat),
	drift = new.bool(cfg.settings.drift),
	keyboard = new.bool(cfg.settings.keyboard),
	autorun = new.bool(cfg.settings.autorun),
	kbact = new.bool(cfg.keyboard.kbact),
	keyboard_pos = imgui.ImVec2(cfg.keyboard.posx, cfg.keyboard.posy),
	autoeat = new.bool(cfg.settings.autoeat),
	delay = new.int(cfg.settings.delay),
	plusw = new.bool(cfg.settings.plusw),
	timeweather = new.bool(cfg.settings.timeweather),
	chathelper = new.bool(cfg.settings.chathelper),
	podarok = new.bool(cfg.settings.podarok),
	infrun = new.bool(cfg.settings.infrun),
	chateditor = new.bool(cfg.settings.chateditor),
	gunmaker = new.bool(cfg.settings.gunmaker),
	antilomka = new.bool(cfg.settings.antilomka),
	vskin = new.bool(cfg.settings.vskin),
	mininghelper = new.bool(cfg.settings.mininghelper),
	drugstimer = new.bool(cfg.settings.drugstimer),
	calcbox = new.bool(cfg.settings.calcbox),
	vr2 = new.bool(cfg.settings.vr2),
	fisheye = new.bool(cfg.settings.fisheye),
	fov_aim = new.bool(cfg.settings.fov_aim == true),
	mask = new.bool(cfg.settings.mask),
	move = new.bool(cfg.keyboard.move),
	lock = new.bool(cfg.settings.lock),
	cardlogin = new.bool(cfg.settings.cardlogin),
	spawn = new.bool(cfg.settings.spawn),
	balloon = new.bool(cfg.settings.balloon),
	al = new.bool(cfg.settings.al),
	cmds = new.bool(cfg.settings.cmds),
	ztimerstatus = new.bool(cfg.settings.ztimerstatus),
	adbox = new.bool(cfg.settings.adbox),
	adbox2 = new.bool(cfg.settings.adbox2),
	doppanel = new.bool(cfg.infopanel.doppanel),
	nickact = new.bool(cfg.infopanel.nickact),
	timeact = new.bool(cfg.infopanel.timeact),
	daysact = new.bool(cfg.infopanel.daysact),
	fpsact = new.bool(cfg.infopanel.fpsact),
	pingact = new.bool(cfg.infopanel.pingact),
	skinact = new.bool(cfg.infopanel.skinact),
	armouract = new.bool(cfg.infopanel.armouract),
	hpact = new.bool(cfg.infopanel.hpact),
	activepanel = new.bool(cfg.onlinepanel.activepanel),
	distanceManager = new.bool((cfg.distanceManager and cfg.distanceManager.enabled) == true),

	gf_nobirds = new.bool((cfg.gamefixer and cfg.gamefixer.nobirds) == true),
	gf_nocloudbig = new.bool((cfg.gamefixer and cfg.gamefixer.nocloudbig) == true),
	gf_nocloudsmall = new.bool((cfg.gamefixer and cfg.gamefixer.nocloudsmall) == true),
	gf_vehlods = new.bool((cfg.gamefixer and cfg.gamefixer.vehlods) == true),
	gf_postfx = new.bool((cfg.gamefixer and cfg.gamefixer.postfx) ~= false),
	gf_effects = new.bool((cfg.gamefixer and cfg.gamefixer.effects) == true),
	gf_sensfix = new.bool((cfg.gamefixer and cfg.gamefixer.sensfix) ~= false),
	gf_sunfix = new.bool((cfg.gamefixer and cfg.gamefixer.sunfix) == true),
	gf_targetblip = new.bool((cfg.gamefixer and cfg.gamefixer.targetblip) ~= false),
	gf_fpslimit_enabled = new.bool((cfg.gamefixer and cfg.gamefixer.fpslimit_enabled) == true),
	gf_forceaniso = new.bool((cfg.gamefixer and cfg.gamefixer.forceaniso) == true),
	gf_anticrasher = new.bool((cfg.gamefixer and cfg.gamefixer.anticrasher) ~= false),
}
sliders = {
	fov = new.int(cfg.settings.fov),
	fpslimit = new.int(math.max(20, tonumber((cfg.gamefixer or {}).fpslimit) or 60)),
	dmNametags = new.int(math.max(0, math.min(30, tonumber((cfg.distanceManager or {}).nametags) or 8))),
	dm3DText = new.int(math.max(0, math.min(30, tonumber((cfg.distanceManager or {}).tdtext) or 8))),
	dmChatBubbles = new.int(math.max(0, math.min(30, tonumber((cfg.distanceManager or {}).chatbubbles) or 6))),
	dmLods = new.int(math.max(0, math.min(300, tonumber((cfg.distanceManager or {}).lods) or 150))),
}
ints = {
	theme = new.int(cfg.settings.theme),
	logincard = new.int(cfg.settings.logincard),
	bindArmorLimit = new.int(cfg.settings.bindArmorLimit or 90),
	prsh1 = new.int(cfg.settings.prsh1),
	prsh2 = new.int(cfg.settings.prsh2),
	prsh3 = new.int(cfg.settings.prsh3),
	prsh4 = new.int(cfg.settings.prsh4),
	prsh5 = new.int(cfg.settings.prsh5),
	buttonjump = new.int(cfg.settings.buttonjump),
	bullet = new.int(cfg.settings.bullet),
	time = new.int(cfg.settings.time),
	weather = new.int(cfg.settings.weather),
	active = new.int(cfg.settings.active),
	edelay = new.int(cfg.settings.edelay),
	autoclickerDelay = new.int(cfg.settings.autoclickerDelay),
	gunmode = new.int(cfg.settings.gunmode),
	chatstrings = new.int(cfg.settings.chatstrings),
	chatfontsize = new.int(cfg.settings.chatfontsize),
}
comboActiveLabels = {u8'Команда', u8'Чит-код'}
comboThemeLabels = {
    u8'Красный', u8'Зеленый', u8'Синий', u8'Салатовый', u8'Оранжевый', u8'Фиолетовый',
    u8'Токсичный', u8'Розовый', u8'Коричневая', u8'Серая', u8'Кастомизированная'
}
comboGunLabels = {'Deagle', 'M4', 'Shotgun'}

uiDebug("COMBO_INIT", "active=", #comboActiveLabels, "theme=", #comboThemeLabels, "gun=", table.concat(comboGunLabels, '|'))

buffers = {
    cheatcode = FfiBuffer(cfg.settings.cheatcode, 64),
}
-- [ Others ] --
day_date = {
    [0] = 'Воскресенье',
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота'
}

colorslist = nil

posX, posY = cfg.infopanel.x, cfg.infopanel.y
onlineposX, onlineposY = cfg.onlinepanel.x, cfg.onlinepanel.y
color = cfg.settings.color
textcolor = '{c7c7c7}'

if type(_G.msg) ~= 'function' then
    function msg(arg)
        sampAddChatMessage(color..'[OS Helper] {FFFFFF}'..textcolor..tostring(arg), -1)
    end
end
moving = false
colortheme = new.float[3](cfg.settings.r, cfg.settings.g, cfg.settings.b) -- colortheme
setskin = 0
pronoroff = false
menu = 1
bhsalary = 0
bhstop = 0
bhcases = 0
bhchert = 0
mhstone = 0
mhmetall = 0
mhbronze = 0
mhsilver = 0
mhgold = 0
fhlyon = 0
fhhlopok = 0
fishsalary = 0
fishcase = 0
nowTime = os.date("%H:%M:%S", os.time())
calcactive = false
result = nil
calctext = ''
flymode = 0  
speed = 0.5
radarHud = 0
timech = 0
keyPressed = 0
bindCapture = {name = nil, started = 0}
uiCursorVisible = false
uiCursorInitialized = false
weatherLoopRunning = false
miningtool = true
automining_status = false
automining_getbtc = 0
automining_startall = 0
automining_fillall = 0

sesOnline = new.int(0)
sesAfk = new.int(0)
sesFull = new.int(0)
dayFull = new.int(cfg.onDay.full)

onlineToggle = {
    sesOnline = new.bool(cfg.onlinepanel.sesOnline),
    sesAfk = new.bool(cfg.onlinepanel.sesAfk),
    sesFull = new.bool(cfg.onlinepanel.sesFull),
    dayOnline = new.bool(cfg.onlinepanel.dayOnline),
    dayAfk = new.bool(cfg.onlinepanel.dayAfk),
    dayFull = new.bool(cfg.onlinepanel.dayFull)
}

resX, resY = getScreenResolution()
BuffSize = 32
KeyboardLayoutName = ffi.new("char[?]", BuffSize)
LocalInfo = ffi.new("char[?]", BuffSize)

oxladtime = 224 --     ,                         

INFO = { 
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
} --                     

dtext = {}

-- [ Others ] -- 
bike = {[481] = true, [509] = true, [510] = true, [10433] = true, [10444] = true, [10445] = true, [10446] = true, [10431] = true, [10430] = true}
moto = {[448] = true, [461] = true, [462] = true, [463] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true, [1823] = true, [1913] = true, [1912] = true, [1947] = true, [1948] = true, [1949] = true, [1950] = true, [1951] = true, [1982] = true, [2006] = true}
chars = {
	["й"] = "q", ["ц"] = "w", ["у"] = "e", ["к"] = "r", ["е"] = "t", ["н"] = "y", ["г"] = "u", ["ш"] = "i", ["щ"] = "o", ["з"] = "p", ["х"] = "[", ["ъ"] = "]", ["ф"] = "a",
	["ы"] = "s", ["в"] = "d", ["а"] = "f", ["п"] = "g", ["р"] = "h", ["о"] = "j", ["л"] = "k", ["д"] = "l", ["ж"] = ";", ["э"] = "'", ["я"] = "z", ["ч"] = "x", ["с"] = "c", ["м"] = "v",
	["и"] = "b", ["т"] = "n", ["ь"] = "m", ["б"] = ",", ["ю"] = ".", ["Й"] = "Q", ["Ц"] = "W", ["У"] = "E", ["К"] = "R", ["Е"] = "T", ["Н"] = "Y", ["Г"] = "U", ["Ш"] = "I",
	["Щ"] = "O", ["З"] = "P", ["Х"] = "{", ["Ъ"] = "}", ["Ф"] = "A", ["Ы"] = "S", ["В"] = "D", ["А"] = "F", ["П"] = "G", ["Р"] = "H", ["О"] = "J", ["Л"] = "K", ["Д"] = "L",
	["Ж"] = ":", ["Э"] = "\"", ["Я"] = "Z", ["Ч"] = "X", ["С"] = "C", ["М"] = "V", ["Ч"] = "B", ["Т"] = "N", ["Ь"] = "M", ["Б"] = "<", ["Ю"] = ">"
}

-- main window animation state
mainWindowOpen = new.bool(false)
mainWindowFade = { alpha = 0.0, target = 0.0, last = os.clock() }

-- Shared navigation model: defined before ui/main.lua is required.
menuItems = {
    {id = 1, icon = "\xEF\x80\x87", text = u8' \xcf\xe5\xf0\xf1\xee\xed\xe0\xe6'},
    {id = 2, icon = "\xEF\x86\xB9", text = u8' \xd2\xf0\xe0\xed\xf1\xef\xee\xf0\xf2'},
    {id = 8, icon = "\xEF\x82\xAC", text = u8' \xce\xea\xf0\xf3\xe6\xe5\xed\xe8\xe5'},
    {id = 10, icon = "\xEF\x84\xAD", text = u8' \xce\xef\xf2\xe8\xec\xe8\xe7\xe0\xf6\xe8\xff'},
    {id = 4, icon = "\xEF\x82\x86", text = u8' \xd0\xe0\xe1\xee\xf2\xe0 \xf1 \xf7\xe0\xf2\xee\xec'},
    {id = 5, icon = "\xEF\x8B\x90", text = u8' \xd0\xe0\xe1\xee\xf2\xe0 \xf1 \xe4\xe8\xe0\xeb\xee\xe3\xe0\xec\xe8'},
    {id = 9, icon = "\xEF\x84\xAE", text = u8' \xc4\xee\xef\xee\xeb\xed\xe5\xed\xe8\xff'},
    {id = 6, icon = "\xEF\x80\x93", text = u8' \xcd\xe0\xf1\xf2\xf0\xee\xe9\xea\xe8'},
    {id = 7, icon = "\xEF\x81\x9A", text = u8' \xc8\xed\xf4\xee\xf0\xec\xe0\xf6\xe8\xff'},
} 

-- One-time cursor reset; no per-frame cursor ownership.
uiCursorVisible = false
uiCursorInitialized = true
pcall(function()
    showCursor(false, false)
    sampSetCursorMode(0)
end)

function setMainWindowVisible(state)
    uiDebug("MAIN_VIS", "state=", state)

    local nextState = state and true or false
    local changed = frames.window[0] ~= nextState

    frames.window[0] = nextState
    if nextState then
        mainWindowOpen[0] = true
    end

    mainWindowFade.target = nextState and 1.0 or 0.0
    mainWindowFade.last = os.clock()

    -- The auxiliary feature states are independent from the main window.
    -- We only hide them visually while the main menu is closed.
    if changed then
        uiCursorVisible = nextState
        uiCursorInitialized = true

        if nextState then
            showCursor(true, true)
        else
            showCursor(false, false)
            sampSetCursorMode(0)
        end
    end
end

-- Background weather cycle. Never block the main/UI loop with weather updates.
lastWeatherValue = nil
lastTimeValue = nil
lastTimeWeatherEnabled = false

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
    if checkboxes.lock[0] and customBindPressed(cfg.binds.lock) then send('/lock') end
    if checkboxes.lock[0] and customBindPressed(cfg.binds.jlock) then send('/jlock') end
end

function drawBindButton(name, label)
    local bind = cfg.binds[name]
    local text = bindCapture.name == name and 'Нажмите сочетание...' or (label..': '..getBindLabel(bind))
    local clicked = imgui.Button(text, imgui.ImVec2(-1, 22))
    if clicked then bindCapture.name = name; bindCapture.started = os.clock() end
    if bindCapture.name == name then
        imgui.TextDisabled(u8'Нажмите нужную клавишу или сочетание. ESC — отмена.')
        if wasKeyPressed(0x1B) then bindCapture.name = nil end
    end
    return clicked
end

-- main
