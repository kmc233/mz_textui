TextUIConfig = {
  -- "text-right": key on the left, text on the right.
  -- "original": keep the order from the source text, for example [E] Open.
  order = "text-right",

  -- Set this to a control id to override automatic key detection.
  control = nil,

  -- Enable temporary input diagnostics with /restart mz_textui if needed.
  debug = false
}

local activeText = nil
local activeControls = nil
local activeHoldDuration = 1000
local activeHoldIndex = nil
local holdStartedAt = nil
local lastProgressIndex = nil
local lastProgress = -1
local lastDebugState = nil

local controlMap = {
  E = 38,
  F = 23,
  G = 47,
  H = 74,
  X = 73,
  Q = 44,
  R = 45,
  T = 245,
  Y = 246,
  SPACE = 22,
  ENTER = 191,
  ESC = 322,
  LEFT = 174,
  RIGHT = 175,
  UP = 172,
  DOWN = 173
}

local function getControlsFromText(text)
  local controls = {}

  for key in text:gmatch("%[(.-)%]") do
    -- Keep an entry for every rendered key so Lua and NUI indexes stay aligned,
    -- even when the text contains a key that has no configured control.
    controls[#controls + 1] = {
      name = key,
      control = TextUIConfig.control or controlMap[string.upper(key)]
    }
  end

  return controls
end

local function debugPrint(message)
  if TextUIConfig.debug then
    print(('[mz_textui] %s'):format(message))
  end
end

function DrawText(text, hold, duration)
  activeText = tostring(text or "")
  local isHold = hold == true
  activeHoldDuration = math.max(tonumber(duration) or 1000, 1)

  activeControls = nil
  if isHold then
    local controls = getControlsFromText(activeText)
    local hasMappedControl = false
    for _, key in ipairs(controls) do
      debugPrint(('DrawText key [%s] -> control %s'):format(
        key.name,
        tostring(key.control)
      ))
      if key.control then
        hasMappedControl = true
      end
    end
    if hasMappedControl then
      activeControls = controls
    end
  end
  if isHold and not activeControls then
    debugPrint('DrawText: no mapped controls found')
  end
  activeHoldIndex = nil
  holdStartedAt = nil
  lastProgressIndex = nil
  lastProgress = -1
  lastDebugState = nil

  SendNUIMessage({
    type = 'show',
    text = activeText,
    order = TextUIConfig.order,
    hold = isHold,
    holdDuration = activeHoldDuration
  })
end

exports('DrawText', DrawText)

function HideText()
  activeText = nil
  activeControls = nil
  activeHoldDuration = 1000
  activeHoldIndex = nil
  holdStartedAt = nil
  lastProgressIndex = nil
  lastProgress = -1
  lastDebugState = nil

  SendNUIMessage({
    type = 'hide'
  })
end

exports('HideText', HideText)

CreateThread(function()
  while true do
    if activeText and activeControls and #activeControls > 0 then
      local now = GetGameTimer()
      local pressedIndex = nil
      local pressedStates = TextUIConfig.debug and {} or nil

      if activeHoldIndex then
        -- Once a key owns the hold, only poll that key until it is released.
        local key = activeControls[activeHoldIndex]
        local control = key and key.control
        local isPressed = control and (
          IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
        )
        if pressedStates then
          pressedStates[activeHoldIndex] = not not isPressed
        end
        if not isPressed then
          debugPrint(('release key index %s [%s]'):format(
            tostring(activeHoldIndex),
            key and key.name or '?'
          ))
          activeHoldIndex = nil
          holdStartedAt = nil
        end
      else
        -- With no active key, find the first pressed key in display order.
        for index, key in ipairs(activeControls) do
          local control = key.control
          local isPressed = control and (
            IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
          )
          if pressedStates then
            pressedStates[index] = not not isPressed
          end
          if isPressed then
            pressedIndex = index
            break
          end
        end
      end

      if TextUIConfig.debug then
        local stateParts = {}
        for index, key in ipairs(activeControls) do
          stateParts[#stateParts + 1] = ('%s=%s:%s'):format(
            index,
            key.name,
            pressedStates and pressedStates[index] and 'DOWN' or 'up'
          )
        end
        local debugState = ('%s|candidate=%s|active=%s'):format(
          table.concat(stateParts, ', '),
          tostring(pressedIndex),
          tostring(activeHoldIndex)
        )
        if debugState ~= lastDebugState then
          lastDebugState = debugState
          debugPrint(('controls %s, candidate=%s, active=%s'):format(
            table.concat(stateParts, ', '),
            tostring(pressedIndex),
            tostring(activeHoldIndex)
          ))
        end
      end

      if not activeHoldIndex and pressedIndex then
        activeHoldIndex = pressedIndex
        holdStartedAt = now
        debugPrint(('start hold key index %s [%s]'):format(
          tostring(activeHoldIndex),
          activeControls[activeHoldIndex].name
        ))
      end

      local progress = 0
      if activeHoldIndex and holdStartedAt then
        local rawProgress = math.min((now - holdStartedAt) / activeHoldDuration, 1)
        -- One-percent steps are visually smooth enough and avoid sending
        -- messages for sub-pixel changes every frame.
        progress = math.floor(rawProgress * 100 + 0.5) / 100
      end

      if lastProgressIndex ~= activeHoldIndex or lastProgress ~= progress then
        lastProgressIndex = activeHoldIndex
        lastProgress = progress
        local progresses = {}
        if activeHoldIndex then
          -- String keys force a JSON object, keeping Lua's 1-based indexes
          -- aligned with the NUI data-key-index values.
          progresses[tostring(activeHoldIndex)] = progress
        end
        SendNUIMessage({
          type = 'progress',
          progresses = progresses
        })
      end

      Wait(0)
    else
      Wait(250)
    end
  end
end)
