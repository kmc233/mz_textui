# mz_textui

通用的 RDR2，gta6 风格 TextUI，支持多按键显示、单键长按进度和完成事件。

## 安装

在 `server.cfg` 中加载资源：

```cfg
ensure mz_textui
```

## 兼容接口

显示普通提示：

```lua
exports['mz_textui']:DrawText('[E] 打开车库')
```

显示长按提示：

```lua
exports['mz_textui']:DrawText('[E] 打开车库', true, 2000)
```

隐藏提示：

```lua
exports['mz_textui']:HideText()
```

## 推荐接口

`Show` 支持为每个按键配置独立事件：

```lua
exports['mz_textui']:Show({
    text = '[E] 打开车库\n[F] 管理车辆',
    hold = 2000,
    controls = {
        { key = 'E', event = 'garage:open' },
        { key = 'F', event = 'garage:manage' }
    }
})
```

`controls` 按文本中占位键的顺序对应。支持的默认按键包括 `E`、`F`、`G`、`H`、`X`、`Q`、`R`、`T`、`Y`、`SPACE`、`ENTER`、方向键等。

## 完成事件

长按达到 100% 时，每次 Hold 只触发一次通用事件：

```lua
RegisterNetEvent('mz_textui:holdComplete', function(data)
    print(data.key, data.control, data.index)
end)
```

如果控制项配置了 `event`，还会触发对应业务事件：

```lua
RegisterNetEvent('garage:open', function(data)
    -- 打开车库
end)
```

事件参数：

```lua
{
    key = 'E',
    control = 38,
    index = 1,
    progress = 1,
    args = ...
}
```

## 状态查询

```lua
local holding = exports['mz_textui']:IsHolding()
local state = exports['mz_textui']:GetState()
```

`GetState()` 返回 `visible`、`holding`、`key`、`control`、`index` 和 `progress`。

## 行为说明

- 可以同时显示多个按键，但同一时间只允许一个按键进入 Hold。
- 当前 Hold 按键释放后，其他仍按住的按键才会接管。
- 长按期间只检测当前活动按键。
- `hold` 为数字时表示长按毫秒数；`true` 使用 `holdDuration`，默认 1000ms。
