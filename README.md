# 🛠️ Roblox UI Library & Game Script Suite

A modular, themeable Roblox UI Framework (`lib.lua`), Remote Event Inspector (`remote_spy.lua`), and Game Admin Scripts.

## 📁 Repository Structure

* **`lib.lua`** - Reusable Roblox UI Library Framework (supports Glassmorphism & custom themes).
* **`themes.lua`** - Preset UI Color Themes (`royal`, `dark`, `emerald`, `cyber`, `midnight`).
* **`rokopia.lua`** - Keyless Rokopia Suite (Build Random Holes Troll Feature).
* **`keyboard_escape.lua`** - Keyless Keyboard Escape Suite (Summer Coins & Secret Keys Auto Teleport Farm).
* **`blade_ball.lua`** - Safe Keyless Blade Ball Suite (Humanized Auto Parry & Controls).
* **`grow_a_garden.lua`** - Official Shop & Purchaser Suite for Roblox Game *"Grow a Garden"*.
* **`99_nights_admin.lua`** - Official Admin Panel for Roblox Game *"99 Nights in the Forest"*.
* **`remote_spy.lua`** - Advanced Remote Event Inspector with `[K]` Toggle, Copy Code, and Event Blocking.

---

## 🟩 Rokopia - Quick Execution

Run this 1-line script in your Roblox executor (No Key Required):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/rokopia.lua"))()
```

### Features:
- **Troll Tab**:
  - `Build Random Holes` (Toggle Switch On/Off)
  - Wählt zufällige Blöcke in deiner Umgebung und gräbt automatisch vertikale Löcher/Schächte nach unten ab.
  - `Hole Radius` (Slider 5 bis 40 Blöcke)
  - `Hole Depth` (Slider 5 bis 30 Blöcke tief)

---

## ⌨️ Keyboard Escape - Quick Execution

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/keyboard_escape.lua"))()
```

---

## ⚔️ Blade Ball - Quick Execution

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/blade_ball.lua"))()
```

---

## 📍 TP Location Suite - Quick Execution

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/tp_location.lua"))()
```

### Features:
- **Draggable Right GUI**: Platziert die GUI rechts am Bildschirm und lässt sich per Maus/Touch überall hinziehen.
- **📍 Set Location**: Speichert deine aktuelle Position & Ausrichtung (CFrame) inkl. Koordinatenanzeige.
- **🚀 TP Location**: Teleportiert dich sofort zur gespeicherten Position (unbegrenzt oft verwendbar).
- **⚡ Auto TP (0.1s)**: ON/OFF Toggle, der dich automatisch alle 0.1 Sekunden zur gespeicherten Position teleportiert.
- **⌨️ Keybind & Minimize**: Drücke `[K]` oder klicke auf `-`, um die GUI zu minimieren oder ein-/auszubleben.

