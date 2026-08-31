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
local holdStartedAt = {}
local lastProgresses = {}

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
  holdStartedAt = {}
  lastProgresses = {}

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
  holdStartedAt = {}
  lastProgresses = {}

  SendNUIMessage({
    type = 'hide'
  })
end

exports('HideText', HideText)

CreateThread(function()
  while true do
    if activeText and activeControls and #activeControls > 0 then
      local progresses = {}
      local now = GetGameTimer()

      for index, key in ipairs(activeControls) do
        local control = key.control
        local isPressed = control and (
          IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
        )

        -- Starting from the pressed state also handles a key that was already
        -- held when the UI was shown, without relying on a just-pressed edge.
        if isPressed and not holdStartedAt[index] then
          holdStartedAt[index] = now
        end

        if holdStartedAt[index] and isPressed then
          progresses[index] = math.min(
            (now - holdStartedAt[index]) / activeHoldDuration,
            1
          )
        else
          holdStartedAt[index] = nil
          progresses[index] = 0
        end
      end

      local changed = false
      for index, progress in ipairs(progresses) do
        if lastProgresses[index] ~= progress then
          changed = true
          break
        end
      end

      if changed then
        lastProgresses = progresses
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
