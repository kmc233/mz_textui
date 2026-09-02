-- 1. Register a single centralized global event to handle any menu interaction dynamically
RegisterNetEvent('my_script:onMenuAction', function(data)
  -- Check which row/option was completed using its unique index
  if data.index == 1 then
    print('Accepted using key: ' .. data.key)
    -- Add your custom logic for the first option (Accept) here
  elseif data.index == 2 then
    print('Cancelled using key: ' .. data.key)
    -- Add your custom logic for the second option (Cancel) here
  end
end)

-- 2. Test command showcasing the structured controls export with independent hold durations and a shared event
RegisterCommand('testmultitextui', function()
  exports['mz_textui']:Show({
    controls = {
      -- First row option pointing to the shared event with a 2-second hold requirement
      { text = "Accept", key = "E", event = "my_script:onMenuAction", hold = 2000 },
      -- Second row option pointing to the same shared event with a 1-second hold requirement
      { text = "Cancel", key = "G", event = "my_script:onMenuAction", hold = 1000 }
    }
  })
end, false)
