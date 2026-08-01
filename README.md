# 🛠️ Roblox UI Library & Game Script Suite

A modular, themeable Roblox UI Framework (`lib.lua`), Remote Event Inspector (`remote_spy.lua`), and Game Admin Scripts.

## 📁 Repository Structure

* **`lib.lua`** - Reusable Roblox UI Library Framework (supports custom components & themes).
* **`themes.lua`** - Preset UI Color Themes (`royal`, `dark`, `emerald`, `cyber`, `midnight`).
* **`grow_a_garden.lua`** - Official Shop & Purchaser Suite for Roblox Game *"Grow a Garden"*.
* **`99_nights_admin.lua`** - Official Admin Panel for Roblox Game *"99 Nights in the Forest"*.
* **`remote_spy.lua`** - Advanced Remote Event Inspector with `[K]` Toggle, Copy Code, and Event Blocking.

---

## 🌻 Grow a Garden - Shop Suite

Run this 1-line script in your Roblox executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/grow_a_garden.lua"))()
```

### Features:
- **Seed Shop**: Dropdown to select and auto-buy any seed, or toggle `Auto Buy ALL Seeds`.
- **Gear Shop**: Dropdown to select and auto-buy any gear, or toggle `Auto Buy ALL Gears`.
- **Egg Shop**: Dropdown to select and auto-buy any pet egg, or toggle `Auto Buy ALL Pet Eggs`.
- **Dynamic Remote Finder**: Automatically scans `ReplicatedStorage` for `BuySeedStock`, `BuyGearShop`, `BuyPetEgg`, etc.

---

## 📡 Advanced Remote Spy

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/remote_spy.lua"))()
```

---

## 🌲 99 Nights in the Forest - Quick Execution

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/99_nights_admin.lua"))()
```
