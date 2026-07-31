# 🛠️ Roblox UI Library & Game Script Suite

A modular, themeable Roblox UI Framework (`lib.lua`) and Game Admin Scripts.

## 📁 Repository Structure

* **`lib.lua`** - Reusable Roblox UI Library Framework (supports custom components & themes).
* **`themes.lua`** - Preset UI Color Themes (`royal`, `dark`, `emerald`, `cyber`, `midnight`).
* **`99_nights_admin.lua`** - Official Admin Panel for Roblox Game *"99 Nights in the Forest"*.
* **`loader.lua`** - 1-Line Loader for *99 Nights in the Forest* Admin Panel.

---

## 🌲 99 Nights in the Forest - Quick Execution

Run this 1-line script in your Roblox executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/99_nights_admin.lua"))()
```

---

## 🎨 How to use `lib.lua` for your own Roblox Scripts

You can use this UI library for any of your future Roblox game scripts! Simply load `lib.lua` from this repository:

```lua
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/lib.lua"))()

-- Create Interface with theme ("royal", "dark", "emerald", "cyber", "midnight")
local int = lib:CreateInterface("My Script Title", "Subtitle", "https://discord.gg/...", "bottom left", "royal")
local mainTab = int:CreateTab("Main", "Main Features")

mainTab:CreateCheckbox("Toggle Feature", function(enabled)
    print("Feature state:", enabled)
end)
```
