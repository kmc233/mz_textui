RegisterCommand('testtextui', function()
  exports['mz_textui']:DrawText(' [E] Test Textui' ,true)
  -- exports['mz_textui']:DrawText('[E] ABCDEFG')

  SetTimeout(10000, function()
    exports['mz_textui']:HideText()
  end)
end, false)
