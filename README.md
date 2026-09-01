<h1 align="center">mz_textui</h1>

<img width="1920" height="1080" alt="textui" src="https://github.com/user-attachments/assets/6c2d64f5-243c-46e9-b966-54a73746bf9b" />

> A universal **RDR2 / GTA VI-style TextUI** for FiveM, supporting multi-key display, single-key hold progress, and completion events.

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

## Compatible Interface

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

## Recommended Interface

`Show` supports configuring independent events for each key:

```lua
exports['mz_textui']:Show({
    text = '[E] Open Garage\n[F] Manage Vehicles',
    hold = 2000,
    controls = {
        { key = 'E', event = 'garage:open' },
        { key = 'F', event = 'garage:manage' }
    }
})
```

`controls` correspond to the order of placeholder keys in the text. Supported default keys include `E`, `F`, `G`, `H`, `X`, `Q`, `R`, `T`, `Y`, `SPACE`, `ENTER`, arrow keys, etc.

## Completion Events

When hold reaches 100%, a generic event triggers once per hold:

```lua
RegisterNetEvent('mz_textui:holdComplete', function(data)
    print(data.key, data.control, data.index)
end)
```

If the control item has an `event` configured, the corresponding business event also triggers:

```lua
RegisterNetEvent('garage:open', function(data)
    -- Open garage
end)
```

Event parameters:

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
- When `hold` is a number, it represents hold duration in milliseconds; `true` uses `holdDuration`, default 1000ms.
