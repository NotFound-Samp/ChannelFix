local sampev = require 'lib.samp.events'

local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local channel = imgui.new.int()
local active = imgui.new.bool(true)

local channelState = false

local inicfg = require 'inicfg'
local directIni = 'ChannelFix.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        int = 1,
        active = true
    },
}, directIni))
inicfg.save(ini, directIni)

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
end)

local radio = {
    ['One Channel'] = 1,
    ['Two Channel'] = 2
}

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local ChatPos = imgui.ImVec2(GetChatInputPos())
        imgui.SetNextWindowPos(imgui.ImVec2(ChatPos.x, ChatPos.y), imgui.Cond.Always, imgui.ImVec2(0, 0))
        imgui.Begin('Main Window', renderWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
        if imgui.Checkbox('', active) then
            ini.main.active = active[0]
        end
        imgui.SameLine()
        for name, value in pairs(radio) do
            if imgui.RadioButtonIntPtr(name, channel, value) then
                channel[0] = value
            end
            imgui.SameLine()
        end
        imgui.End()
    end
)

function main()
    while not isSampAvailable() do wait(0) end
    channel[0] = tonumber(ini.main.int)
    sampRegisterChatCommand('channel', function()
        channelState = not channelState
    end)
    while true do
        wait(0)
        renderWindow[0] = (sampIsChatInputActive() and channelState)
    end
end

function sampev.onServerMessage(color, text)
    if color == -825307393 and text:find('1%-чат организации, 2%-рабочий чат') then
        channel[0] = 2
    end
    if color == -65281 and text:find('Поздравляем! {66CC00}') then
        channel[0] = 2
    end
    if color == -10092289 and text:find('уволил Вас из организации') then
        channel[0] = 1
    end
    if color == 1724645631 and text:find('Поздравляем! Вы вступили в организацию') then
        channel[0] = 2
    end
    if color == -65281 and text:find('Вы покинули организацию') then
        channel[0] = 1
    end
end

function sampev.onShowDialog(id, style, title, b1, b2, text)
    if id == 0 and text:find('{FFFFFF}Вы уволились с работы. Выбрать другую всегда можно в мэрии вашего города') then
        channel[0] = 1
        ini.main.int = 1
        inicfg.save(ini, directIni)
    end
end

function sampev.onSendCommand(command)
    if command:find('/f%s.+') and active[0] then
        local text = command:match('^/f%s(.+)')
        if channel[0] == 1 and text ~= nil then
            command = '/f '..text
        elseif channel[0] == 2 and text ~= nil then
            command = '/f 1 '..text
        end 
    end
    if command:find('/fn%s.+') and active[0] then
        local text = command:match('^/fn%s(.+)')
        if channel[0] == 1 and text ~= nil then
            command = '/f (( '..text..' ))'
        elseif channel[0] == 2 and text ~= nil then
            command = '/f 1 (( '..text..' ))'
        end
    end
    if command:find('/j%s.+') and active[0] then
        local text = command:match('^/j%s(.+)')
        if text ~= nil then
            command  ='/f 2 '..text
        end
    end
    if command:find('/jn%s.+') and active[0] then
        local text = command:match('^/jn%s(.+)')
        if text ~= nil then
            command = '/f 2 (( '..text..' ))'
        end
    end
    if command:find('/rn%s.+') then
        local text = command:match('^/rn%s(.+)')
        if text ~= nil then
            command = '/r (( '..text..' ))'
        end
    end
    return {command}
end

function onScriptTerminate(s) 
	if s == thisScript() then 
        ini.main.int = channel[0]
        inicfg.save(ini, directIni)
    end
end

function GetChatInputPos()
    if isSampAvailable() then
        local ChatPtr = sampGetInputInfoPtr()
	    local pizda = getStructElement(ChatPtr, 0x8, 4)
	    local posX = getStructElement(pizda, 0x8, 4)
        local posY = getStructElement(pizda, 0xC, 4)
	    return posX, posY + 45
    else
        return 0, 0
    end
end