-- ==========================================
-- Auto Find World Script by Elgato91169
-- ==========================================

local Gui = load(makeRequest("https://raw.githubusercontent.com/404Store/Lua-ImGui-Builder/refs/heads/main/imgui", "GET").content)()

local visitedWorlds = {}
local isShortcutEnabled = false
local nameLength = 5
local includeNumber = false
local useCustomWord = false
local customWord = ""
local customWordPos = 0 

function createRandomName()
    local text = not includeNumber and 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' or 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local result = {}
    
    for i = 1, nameLength do
        local idx = math.random(1, #text)
        table.insert(result, text:sub(idx, idx))
    end
    
    local rand = table.concat(result)
    
    if useCustomWord and customWord ~= "" then
        local w = customWord:gsub("%s+", ""):upper()
        if w ~= "" then
            if customWordPos == 0 then
                return w .. rand
            else
                return rand .. w
            end
        end
    end
    return rand
end

function elgatoLog(msg)
    -- Watermark diubah menjadi nama kamu
    local prefix = "`0[`5Elgato Finder`0] "
    logToConsole(prefix .. msg)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = prefix .. msg
    })
end

local mainWindow = Gui.New({
    theme = "dark",
    title = "Elgato World Finder", -- Judul menu diubah
    size = {380, 470},
    OnRender = function(crt)
        crt:Button((isShortcutEnabled and "DISABLE" or "ENABLE").." SHORTCUT", function() 
            isShortcutEnabled = not isShortcutEnabled
        end, -1, 0)
        
        crt:Button("FIND WORLD", function() 
            elgatoLog("Generating random world...")
            sendPacket(3, "action|join_request\nname|" .. createRandomName() .. "\ninvitedWorld|0")
        end, -1, 0)
        
        crt:Child("MAIN", -1, -1, nil, function()
            nameLength = crt:InputInt("Length", nameLength)
            includeNumber = crt:Checkbox("With Number", includeNumber)
            crt:SameLine()
            useCustomWord = crt:Checkbox("Enable Custom Word", useCustomWord)
            
            if useCustomWord then
                customWord = crt:InputText("Custom Word", "ex: MBUD", customWord)
                customWordPos = crt:Combo('Position', customWordPos, {'FRONT', 'BACK'})
            end
            
            ImGui.BeginGroupPanel("World List")
            crt:Child("LIST", -1, -1, true, function()
                crt:Table({"No", "Name"}, function()
                    for i = #visitedWorlds, 1, -1 do
                        local name = visitedWorlds[i]
                        crt:TableRow({i, name})
                    end
                end)
            end)
            ImGui.EndGroupPanel()
        end)
    end
})

local shortcutWindow = Gui.New({
    theme = "dark",
    title = "NONE",
    size = {100, 75},
    flags = ImGui.WindowFlags.NoTitleBar,
    OnRender = function(crt)
        crt:Child("MAIN", -1, -1, nil, function()
            crt:Button("FIND", function() 
                elgatoLog("Generating random world...")
                sendPacket(3, "action|join_request\nname|" .. createRandomName() .. "\ninvitedWorld|0")
            end, -1, 0)
        end)
    end
})

AddHook("OnRender", "Elgato_GUI", function()
    mainWindow:Render()
    if isShortcutEnabled then shortcutWindow:Render() end
end)

AddHook("OnVarlist", "Elgato_WorldLogger", function(var)
    if var[0] == "OnConsoleMessage" and var[1]:find("entered.") then
        local world = getWorld().name or 'NONE'
        elgatoLog(world.." Added into list.")
        table.insert(visitedWorlds, world)
    end
end)
