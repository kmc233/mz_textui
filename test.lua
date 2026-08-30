RegisterCommand('testtextui', function()
  exports['mz_textui']:DrawText('[E] 测试交互提示')

  SetTimeout(10000, function()
    exports['mz_textui']:HideText()
  end)
end, false)
