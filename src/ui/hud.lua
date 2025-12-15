local hud = {}

function hud.load(player)
  hud.player = player

  hud.heartFull  = love.graphics.newImage("res/ui/hearth-full.png")
  hud.heartEmpty = love.graphics.newImage("res/ui/hearth-empty.png")
  hud.potion     = love.graphics.newImage("res/ui/potion.png")

  hud.maxHealth = player.health
end

function hud.update() end

function hud.draw()
  local x, y = 10, 10
  local margin = 10
  local spacing = 2

  for i = 1, hud.maxHealth do
    love.graphics.setColor(1, 1, 1, 1)
    if i <= math.floor(hud.player.health) then
      love.graphics.draw(hud.heartFull, x, y)
    else
      love.graphics.draw(hud.heartEmpty, x, y)
    end

    x = x + hud.heartFull:getWidth() + spacing
  end

  local potionY = y + hud.heartFull:getHeight() + 10
  local barWidth = 160
  local barHeight = 18
  local barX = margin + hud.potion:getWidth() - 20
  local barY = potionY + (hud.potion:getHeight() - barHeight) / 2 + 3
  
  love.graphics.setColor(0.2, 0.25, 0.3, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 10)
  love.graphics.setColor(0.12, 0.70, 0.66, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth * 0.35, barHeight, 10)
  love.graphics.setColor(0.05, 0.05, 0.05, 1)
  love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 10)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(hud.potion, margin, potionY)
end

return hud