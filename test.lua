RegisterCommand('testtextui', function()
  exports['mz_textui']:DrawText(' [E] Test Textui')

  SetTimeout(10000, function()
    exports['mz_textui']:HideText()
  end)
end, false)
