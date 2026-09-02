<h1 align="center">mz_textui</h1>

<img width="1920" height="1080" alt="textui" src="https://github.com/user-attachments/assets/6c2d64f5-243c-46e9-b966-54a73746bf9b" />

> A universal **RDR2 / GTA VI-style TextUI** for FiveM, supporting multi-key display, independent row-based hold durations, and central event handling.

<p align="center">
  <a href="https://muziscripts.com/">
    <img src="https://img.shields.io/badge/Store-muziscripts.com-blue?style=for-the-badge" alt="Store">
  </a>
  <a href="https://discord.com/invite/Yp8ukQvsJv">
    <img src="https://img.shields.io/badge/Discord-Join%20Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
  </a>
</p>

<p align="center">
  <b>Lightweight</b> •
  <b>Modern</b> •
  <b>Performance Optimized</b>
</p>

---

## Installation

Load the resource in `server.cfg`:

```cfg
ensure mz_textui
```

## Legacy Interface (`DrawText`)

Display normal hint:

```lua
exports['mz_textui']:DrawText('[E] Open Garage')
```

Display hold hint:

```lua
exports['mz_textui']:DrawText('[E] Open Garage', true, 2000)
```

Hide hint:

```lua
exports['mz_textui']:HideText()
```

## Recommended Interface (`Show`)

`Show` supports a fully structured `controls` list where each row has independent properties, individual hold durations, and custom event mapping:

```lua
exports['mz_textui']:Show({
    controls = {
        { text = "Accept", key = "E", event = "my_script:actionAccept", hold = 2000 },
        { text = "Cancel", key = "G", event = "my_script:actionCancel", hold = 1000 }
    }
})
```

Supported default keys include `E`, `F`, `G`, `H`, `X`, `Q`, `R`, `T`, `Y`, `SPACE`, `ENTER`, arrow keys, etc.

## Completion Events

When a hold reaches 100%, individual business events or a shared centralized event will trigger:

```lua
-- Register your events globally
RegisterNetEvent('my_script:actionAccept', function(data)
    print('Accepted with key ' .. data.key .. '!')
end)

```

Event parameters table (`data`):

```lua
{
    key = 'E',
    control = 38,
    index = 1,
    progress = 1,
    args = ...
}
```

## State Query

```lua
local holding = exports['mz_textui']:IsHolding()
local state = exports['mz_textui']:GetState()
```

`GetState()` returns `visible`, `holding`, `key`, `control`, `index`, and `progress`.

## Behavior Notes

- Multiple keys can be displayed simultaneously, but only one key is allowed to enter Hold at a time.
- After the current Hold key is released, other pressed keys will take over.
- Only the currently active key is detected during hold.
- Each structured control item can define its individual hold duration via `hold` or `holdDuration` in milliseconds (defaults to 1000ms).
