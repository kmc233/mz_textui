# mz_textui

A universal RDR2/GTA6-style TextUI, supporting multi-key display, single-key hold progress, and completion events.

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