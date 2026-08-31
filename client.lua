TextUIConfig = {
  -- "text-right": key on the left, text on the right.
  -- "original": keep the order from the source text, for example [E] Open.
  order = "text-right",

  -- Set this to a control id to override automatic key detection.
  control = nil
}

local activeText = nil
local activeControl = nil
local activeHoldDuration = 1000
local holdStartedAt = nil

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

local function getControlFromText(text)
  if TextUIConfig.control then
    return TextUIConfig.control
  end

  local key = text:match("%[(.-)%]")
  if not key then return nil end

  return controlMap[string.upper(key)]
end

function DrawText(text, hold, duration)
  activeText = tostring(text or "")
  local isHold = hold == true
  activeHoldDuration = math.max(tonumber(duration) or 1000, 1)

  activeControl = isHold and getControlFromText(activeText) or nil
  holdStartedAt = nil

  SendNUIMessage({
    type = 'show',
    text = activeText,
    order = TextUIConfig.order,
    hold = isHold,
    holdDuration = activeHoldDuration,
    control = activeControl
  })
end

exports('DrawText', DrawText)

function HideText()
  activeText = nil
  activeControl = nil
  activeHoldDuration = 1000
  holdStartedAt = nil

  SendNUIMessage({
    type = 'hide'
  })
end

exports('HideText', HideText)

CreateThread(function()
  while true do
    if activeText and activeControl then
      local isPressed = IsControlPressed(0, activeControl)
      local progress = 0

      if isPressed then
        holdStartedAt = holdStartedAt or GetGameTimer()
        progress = math.min(
          (GetGameTimer() - holdStartedAt) / activeHoldDuration,
          1
        )
      else
        holdStartedAt = nil
      end

      SendNUIMessage({
        type = 'progress',
        progress = progress
      })

      Wait(0)
    else
      Wait(250)
    end
  end
end)
