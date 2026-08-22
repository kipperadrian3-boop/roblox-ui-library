--[[
    TP Location Suite - Safe Loader Script
    Einfach diesen Code in deinen Roblox Executor einfügen!
]]

local url = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/tp_location.lua?v=" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 999999))

local success, code = pcall(function()
    return game:HttpGet(url)
end)

if success and code and not code:find("404: Not Found") and #code > 50 then
    local fn, err = loadstring(code)
    if fn then
        fn()
    else
        warn("[TP Location Error] Syntax-Fehler beim Laden:", err)
    end
else
    warn("[TP Location Error] Konnte tp_location.lua nicht von GitHub laden!")
    warn("--> Grund: Die Datei wurde neu erstellt und muss erst zu GitHub ge-pusht werden (oder kopiere den Inhalt von tp_location.lua direkt in deinen Executor).")
end
