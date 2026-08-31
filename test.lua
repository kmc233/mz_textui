RegisterCommand('testtextui', function()
  -- exports['mz_textui']:DrawText(' [E] Test Textui' ,true, 2000)
  -- exports['mz_textui']:DrawText('[E] ABCDEFG\nDrop [G]')
  exports['mz_textui']:DrawText('Use [E]\nDrop [G]', true, 2000)

  SetTimeout(10000, function()
    exports['mz_textui']:HideText()
  end)
end, false)
