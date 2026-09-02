-- Configuration settings for the TextUI
TextUIConfig = {
  order = "text-right",
  control = nil,
  debug = false
}

-- Global state variables
local activeText = nil
local activeControls = nil
local activeHoldDuration = 1000
local activeHoldIndex = nil
local currentHoldId = 0
local holdComplete = false

-- Mapping table linking key names to FiveM control indexes
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
  K = 311,
  L = 182,
  M = 244,
  N = 249,
  SPACE = 22,
  ENTER = 191,
  LEFT = 174,
  RIGHT = 175,
  UP = 172,
  DOWN = 173
}

-- Helper function to extract and parse controls embedded in text strings via brackets
local function getControlsFromText(text, configuredControls)
  local controls = {}
  local configuredIndex = 0

  for key in text:gmatch("%[(.-)%]") do
    configuredIndex = configuredIndex + 1
    local configured = configuredControls and configuredControls[configuredIndex] or nil
    local configuredKey = configured and configured.key or key
    local upperKey = string.upper(configuredKey)

    controls[#controls + 1] = {
      name = configuredKey,
      control = TextUIConfig.control or (configured and configured.control) or controlMap[upperKey],
      event = configured and configured.event or nil,
      args = configured and configured.args or nil,
      holdDuration = math.max(tonumber(configured and (configured.holdDuration or configured.hold)) or 1000, 1)
    }
  end

  return controls
end

-- Helper function to reset active UI states and invalidate ongoing timers
local function resetState()
  activeText = nil
  activeControls = nil
  activeHoldIndex = nil
  holdComplete = false
  currentHoldId = currentHoldId + 1
end

-- Hides the UI and resets all associated variables
function HideText()
  resetState()
  SendNUIMessage({ type = 'hide' })
end

exports('HideText', HideText)

-- Register commands and key mappings for 0ms idle optimization
for keyName, _ in pairs(controlMap) do
  local cmdKey = string.lower(keyName)
  local defaultKey = cmdKey == "space" and "space" or (cmdKey == "enter" and "return" or cmdKey)

  -- Command triggered when the key is pressed down (+)
  RegisterCommand('+' .. 'mz_textui_' .. cmdKey, function()
    if not activeControls or activeHoldIndex ~= nil then return end

    for index, keyData in ipairs(activeControls) do
      if string.upper(keyData.name) == keyName then
        activeHoldIndex = index
        holdComplete = false
        currentHoldId = currentHoldId + 1
        local capturedHoldId = currentHoldId

        -- Notify NUI to start progress tracking using the individual hold duration
        SendNUIMessage({
          type = 'progress_start',
          index = index,
          duration = keyData.holdDuration
        })

        -- Set timeout matching the specific key's hold duration
        SetTimeout(keyData.holdDuration, function()
          if activeHoldIndex == index and currentHoldId == capturedHoldId and not holdComplete then
            holdComplete = true
            local data = {
              key = keyData.name,
              control = keyData.control,
              index = index,
              progress = 1,
              args = keyData.args
            }
            TriggerEvent('mz_textui:holdComplete', data)
            if type(keyData.event) == 'string' and keyData.event ~= '' then
              TriggerEvent(keyData.event, data)
            end
            HideText()
          end
        end)
        break
      end
    end
  end, false)

  -- Command triggered when the key is released (-)
  RegisterCommand('-' .. 'mz_textui_' .. cmdKey, function()
    if not activeControls or activeHoldIndex == nil then return end
    local keyData = activeControls[activeHoldIndex]
    if keyData and string.upper(keyData.name) == keyName then
      currentHoldId = currentHoldId + 1
      activeHoldIndex = nil
      holdComplete = false

      SendNUIMessage({
        type = 'progress_reset',
        index = activeHoldIndex
      })
    end
  end, false)

  pcall(function()
    RegisterKeyMapping('+' .. 'mz_textui_' .. cmdKey, 'TextUI: ' .. keyName, 'keyboard', defaultKey)
  end)
end

-- Helper function to parse structured controls passed via export (flat rows with individual holds)
local function getControlsFromStructured(controlsList)
  local controls = {}
  local constructedText = ""

  for i, item in ipairs(controlsList) do
    local keyName = item.key or "E"
    local upperKey = string.upper(keyName)

    if i > 1 then
      constructedText = constructedText .. "\n"
    end

    constructedText = constructedText .. (item.text or "") .. " [" .. keyName .. "]"

    controls[#controls + 1] = {
      name = keyName,
      control = TextUIConfig.control or item.control or controlMap[upperKey],
      event = item.event or nil,
      args = item.args or nil,
      holdDuration = math.max(tonumber(item.holdDuration or item.hold) or 1000, 1)
    }
  end

  return constructedText, controls
end

-- Main function to display text UI supporting both structured controls and standard text strings
function Show(options)
  options = options or {}

  local isHold = false
  local controls = nil
  local textToRender = options.text

  -- Handle structured control tables with individual row properties
  if options.controls and type(options.controls) == "table" then
    isHold = true
    textToRender, controls = getControlsFromStructured(options.controls)
    activeControls = controls
  else
    activeText = tostring(options.text or "")
    isHold = options.hold == true or tonumber(options.hold) ~= nil
    activeHoldDuration = math.max(tonumber(options.holdDuration or options.hold) or 1000, 1)

    activeControls = nil
    if isHold then
      local parsedControls = getControlsFromText(activeText, options.controls)
      if options.event and #parsedControls > 0 then
        for _, ctrl in ipairs(parsedControls) do
          ctrl.event = options.event
          ctrl.args = options.args
          ctrl.holdDuration = activeHoldDuration
        end
      end
      activeControls = #parsedControls > 0 and parsedControls or nil
    end
  end

  activeText = textToRender
  activeHoldIndex = nil
  holdComplete = false
  currentHoldId = currentHoldId + 1

  SendNUIMessage({
    type = 'show',
    text = activeText,
    order = TextUIConfig.order,
    hold = isHold,
    holdDuration = activeHoldDuration
  })
end

exports('Show', Show)

-- Legacy helper wrapper for simple text rendering
function DrawText(text, hold, duration)
  return Show({ text = text, hold = hold, holdDuration = duration })
end

exports('DrawText', DrawText)

-- Checks if a key hold interaction is currently active
function IsHolding()
  return activeHoldIndex ~= nil
end

exports('IsHolding', IsHolding)

-- Returns the current state information of the TextUI interface
function GetState()
  local key = activeHoldIndex and activeControls and activeControls[activeHoldIndex] or nil
  return {
    visible = activeText ~= nil,
    holding = IsHolding(),
    key = key and key.name or nil,
    control = key and key.control or nil,
    index = activeHoldIndex,
    progress = holdComplete and 1 or 0
  }
end

exports('GetState', GetState)
