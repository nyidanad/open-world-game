function love.load()
  anim8 = require 'lib/anim8'

  love.graphics.setDefaultFilter("nearest", "nearest")

  player = {}
  player.x = love.graphics.getWidth() / 2
  player.y = love.graphics.getHeight() / 2
  player.speed = 3
  player.spriteSheet = love.graphics.newImage('res/sprites/main-sheet.png')
  player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

  player.animations = {}
  player.animations.down  = anim8.newAnimation( player.grid('1-4', 1), 0.2 )
  player.animations.left  = anim8.newAnimation( player.grid('1-4', 2), 0.2 )
  player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
  player.animations.up    = anim8.newAnimation( player.grid('1-4', 4), 0.2 )

  player.anim = player.animations.right
end

function love.update(dt)
  local isMoving = false

  if love.keyboard.isDown('d') then
    if player.x < (love.graphics.getWidth()) then
      player.x = player.x + player.speed
      player.anim = player.animations.right
      isMoving = true
    end
  end

  if love.keyboard.isDown('a') then
    if player.x > 0 then
      player.x = player.x - player.speed
      player.anim = player.animations.left
      isMoving = true
    end
  end

  if love.keyboard.isDown('w') then
    if player.y > 0 then
      player.y = player.y - player.speed
      player.anim = player.animations.up
      isMoving = true
    end
  end

  if love.keyboard.isDown('s') then
    if player.y < (love.graphics.getHeight()) then
      player.y = player.y + player.speed
      player.anim = player.animations.down
      isMoving = true
    end
  end

  if isMoving == false then
    player.anim:gotoFrame(2)
  end

  player.anim:update(dt)
end

function love.draw()
  player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5)
end