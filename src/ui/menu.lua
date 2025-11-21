local menu = {}

function menu.load()
  menu.buttons = {}

  -- 0: main menu
  -- 1: running
  -- 2: pause
  -- 3: game over
  menu.state = 0

  menu.sfx = {
    button = love.audio.newSource('res/sounds/sfx/main-menu-button-press.mp3', 'static')
  }
end

function menu.mainmenu(startGame)
  local screenWidth = love.graphics.getWidth()
  local btnWidth = 200
  local centerX = (screenWidth / 2) - (btnWidth / 2)

  menu.buttons = {
    {text = "Play",  x = centerX, y = 340, w = btnWidth, h = 50, action = startGame},
    {text = "Exit",  x = centerX, y = 410, w = btnWidth, h = 50, action = function() love.event.quit() end}
  }
end

function menu.pausemenu(startGame)
  local screenWidth = love.graphics.getWidth()
  local btnWidth = 200
  local centerX = (screenWidth / 2) - (btnWidth / 2)

  menu.buttons = {
    {text = "Resume",       x = centerX, y = 250, w = btnWidth, h = 50, action = function() menu.state = 1 end},
    {text = "Restart",      x = centerX, y = 320, w = btnWidth, h = 50, action = startGame},
    {text = "Exit to menu", x = centerX, y = 460, w = btnWidth, h = 50, action = function() menu.state = 0; menu.mainmenu(startGame) end},
  }
end

function menu.gameOver(startGame)
  local screenWidth = love.graphics.getWidth()
  local btnWidth = 200
  local centerX = (screenWidth / 2) - (btnWidth / 2)

  menu.buttons = {
    {text = "Restart",      x = centerX, y = 340, w = btnWidth, h = 50, action = startGame},
    {text = "Exit to menu", x = centerX, y = 410, w = btnWidth, h = 50, action = function() menu.state = 0; menu.mainmenu(startGame) end}
  }
end

function menu.draw(title)
  local fontSize = love.graphics.newFont(32)
  love.graphics.setFont(fontSize)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(title, 0, 150, love.graphics.getWidth(), "center")

  for _, btn in ipairs(menu.buttons) do
    local fontSize = love.graphics.newFont(18)
    love.graphics.setFont(fontSize)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10)
    love.graphics.printf(btn.text, btn.x, btn.y + 15, btn.w, "center")
  end
end

function menu.mousepressed(x, y, button)
  if button ~= 1 then return end

  for _, btn in ipairs(menu.buttons) do
    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
      menu.sfx.button:play()

      if btn.action then btn.action() end
      return
    end
  end
end



return menu
