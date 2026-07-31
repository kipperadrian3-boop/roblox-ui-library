# 🌲 99 Nights in the Forest - Admin & Management Suite

Official Roblox Admin Panel & Developer Management Utilities.

## 🚀 How to Execute (1-Line Loader)

Run this single line in your Roblox executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DEIN_NUTZERNAME/DEIN_REPOSITORY/main/main.lua"))()
```

## 📁 Repository File Structure

* **`main.lua`** - Main script logic & features.
* **`lib.lua`** - Custom UI Library with theme rendering support.
* **`themes.lua`** - UI color themes (`royal`, `dark`, `emerald`, `cyber`, `midnight`).
* **`loader.lua`** - 1-Line loader reference.

## 🎨 Themes Supported

You can change the UI theme in `main.lua` (line 17) by passing your favorite theme:
* `"royal"` (Default - Deep Purple / Royal Blue)
* `"dark"` (Sleek Dark Mode)
* `"emerald"` (Forest Emerald Green)
* `"cyber"` (Neon Cyan / Cyberpunk)
* `"midnight"` (Pink / Violet Midnight)

```lua
local int = lib:CreateInterface("99 Nights Admin Panel", "Admin & Management Suite", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal")
```
