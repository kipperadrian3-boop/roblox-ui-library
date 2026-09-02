-- Greedy Growers Executor Script
-- Copy and paste this into your executor to run the suite

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

local success, err = pcall(function()
    loadstring(game:HttpGet(REPO_URL .. "greedy_growers.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success then
    warn("[Executor Error] Failed to load Greedy Growers from GitHub:")
    warn(err)
end
