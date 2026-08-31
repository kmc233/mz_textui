RegisterCommand('testtextui', function()
  exports['mz_textui']:DrawText(' [J] Test Textui')

  SetTimeout(10000, function()
    exports['mz_textui']:HideText()
  end)
end, false)
