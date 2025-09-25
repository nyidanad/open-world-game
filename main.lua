function love.load()
  anim8 = require 'lib/anim8'
  sti = require 'lib/sti'
  camera = require 'lib/camera'

  love.graphics.setDefaultFilter("nearest", "nearest")

  -- player attributes
  player = {}
  player.x = love.graphics.getWidth() / 2
  player.y = love.graphics.getHeight() / 2
  player.speed = 2
  player.idleSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-idle-sword.png')
  player.walkSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-walk-sword.png')
  player.idle = anim8.newGrid(32, 32, player.idleSpriteSheet:getWidth(), player.idleSpriteSheet:getHeight())
  player.walk = anim8.newGrid(32, 32, player.walkSpriteSheet:getWidth(), player.walkSpriteSheet:getHeight())

  -- player animations
  player.animations = {}
  player.animations.idle = anim8.newAnimation(player.idle('1-2', 1), 0.4)

  player.animations.right = anim8.newAnimation(player.walk('1-4', 1), 0.2)
  player.animations.left  = anim8.newAnimation(player.walk('1-4', 2), 0.2)
  player.animations.upRight = anim8.newAnimation(player.walk('1-4', 3), 0.2)
  player.animations.upLeft  = anim8.newAnimation(player.walk('1-4', 4), 0.2)
  player.animations.downRight = anim8.newAnimation(player.walk('1-4', 1), 0.2)
  player.animations.downLeft  = anim8.newAnimation(player.walk('1-4', 2), 0.2)

  -- starting position
  player.anim = player.animations.right
  player.lastHorizontal = "right"

  -- loading map and camera
  gameMap = sti('res/maps/map01/map01.lua')
  cam = camera()
end

function love.update(dt)
  local isMoving = false

  if love.keyboard.isDown('d') then
    if player.x < love.graphics.getWidth() then
      player.x = player.x + player.speed
      player.anim = player.animations.right
      player.lastHorizontal = "right"
      isMoving = true
    end
  end

  if love.keyboard.isDown('a') then
    if player.x > 0 then
      player.x = player.x - player.speed
      player.anim = player.animations.left
      player.lastHorizontal = "left"
      isMoving = true
    end
  end

  if love.keyboard.isDown('w') then
    if player.y > 0 then
      player.y = player.y - player.speed
      if player.lastHorizontal == "right" then
        player.anim = player.animations.upRight
      else
        player.anim = player.animations.upLeft
      end
      isMoving = true
    end
  end

  if love.keyboard.isDown('s') then
    if player.y < love.graphics.getHeight() then
      player.y = player.y + player.speed
      if player.lastHorizontal == "right" then
        player.anim = player.animations.downRight
      else
        player.anim = player.animations.downLeft
      end
      isMoving = true
    end
  end

  if not isMoving then
    player.anim = player.animations.idle
  end

  player.anim:update(dt)

  cam:lookAt(player.x, player.y)

  -- camera borders
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  if cam.x < windowWidth/2 then cam.x = windowWidth/2 end
  if cam.y < windowHeight/2 then cam.y = windowHeight/2 end
  if cam.x > (mapWidth - windowWidth/2) then cam.x = (mapWidth - windowWidth/2) end
  if cam.y > (mapHeight - windowHeight/2) then cam.y = (mapHeight - windowHeight/2) end
end

function love.draw()
  cam:attach()
    gameMap:drawLayer(gameMap.layers['terrain0'])
    gameMap:drawLayer(gameMap.layers['terrain1'])
    gameMap:drawLayer(gameMap.layers['walls'])
    gameMap:drawLayer(gameMap.layers['stairs'])

    if player.anim ~= player.animations.idle then
      player.anim:draw(player.walkSpriteSheet, player.x, player.y, nil, 2, nil, 6, 9)
    else
      if player.lastHorizontal == "right" then
        player.anim:draw(player.idleSpriteSheet, player.x, player.y, 0, 2, 2, 6, 9)
      else
        player.anim:draw(player.idleSpriteSheet, player.x, player.y, 0, -2, 2, 26, 9)
      end
    end
  cam:detach()
end
