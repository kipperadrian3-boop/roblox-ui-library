--[[
    Mine a Mountain Suite - Executor Script
    Einfach diesen gesamten Code kopieren und in deinen Executor einfügen!
]]
local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or queue_to_teleport or (Fluxus and Fluxus.queue_on_teleport)
if queueTeleport then
    pcall(function()
        queueTeleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/mine_a_mountain.lua?v=" .. tostring(os.time())))()
        ]])
    end)
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/mine_a_mountain.lua?v=" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 999999))))()
