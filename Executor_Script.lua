--[[
    99 Nights Admin Panel - Executor Loader
    Einfach diesen gesamten Code kopieren und in deinen Executor einfügen!
]]
local scriptFunc, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/99_nights_admin.lua?t=" .. tick()))
if scriptFunc then
    scriptFunc()
else
    warn("[Loader Error] Failed to load 99_nights_admin.lua:", err)
end
