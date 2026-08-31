TextUIConfig = {
  -- "text-right": key on the left, text on the right.
  -- "original": keep the order from the source text, for example [E] Open.
  order = "text-right",

  -- Set this to a control id to override automatic key detection.
  control = nil
}

local activeText = nil
local activeControls = nil
local activeHoldDuration = 1000
local activeHoldIndex = nil
local holdStartedAt = nil
local lastProgressIndex = nil
local lastProgress = -1

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

function DrawText(text, hold, duration)
  activeText = tostring(text or "")
  local isHold = hold == true
  activeHoldDuration = math.max(tonumber(duration) or 1000, 1)

  activeControls = nil
  if isHold then
    local controls = getControlsFromText(activeText)
    for _, key in ipairs(controls) do
      if key.control then
        activeControls = controls
        break
      end
    end
  end
  activeHoldIndex = nil
  holdStartedAt = nil
  lastProgressIndex = nil
  lastProgress = -1

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

      -- Pick the first pressed key only when no key is currently holding.
      -- Once selected, that key owns the hold until it is released.
      for index, key in ipairs(activeControls) do
        local control = key.control
        local isPressed = control and (
          IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
        )
        if isPressed then
          pressedIndex = index
          break
        end
      end

      if activeHoldIndex then
        local key = activeControls[activeHoldIndex]
        local control = key and key.control
        local stillPressed = control and (
          IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
        )
        if not stillPressed then
          activeHoldIndex = nil
          holdStartedAt = nil
        end
      end

      if not activeHoldIndex and pressedIndex then
        activeHoldIndex = pressedIndex
        holdStartedAt = now
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
          progresses[activeHoldIndex] = progress
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
