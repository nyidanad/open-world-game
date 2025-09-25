function love.load()
  anim8 = require 'lib/anim8'
  sti = require 'lib/sti'
  camera = require 'lib/camera'
  windfield = require 'lib/windfield'

  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("The Last Oath")
  love.window.setMode( 1280, 720 )
  zoom = 1.75

  -- loading map and camera
  gameMap = sti('res/maps/test-map/test-map.lua')

  cam = camera()
  cam:zoomTo(zoom)

  world = windfield.newWorld(0, 0)

  -- player attributes
  player = {}
  player.x = 0
  player.y = 0
  player.speed = 150
  player.idleSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-idle-sword.png')
  player.walkSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-walk-sword.png')
  player.idle = anim8.newGrid(32, 32, player.idleSpriteSheet:getWidth(), player.idleSpriteSheet:getHeight())
  player.walk = anim8.newGrid(32, 32, player.walkSpriteSheet:getWidth(), player.walkSpriteSheet:getHeight())

  -- player collider
  player.collider = world:newBSGRectangleCollider(845, 250, 40, 56, 6)
  player.collider:setFixedRotation(true)

  -- colliders
  colliders = {}
  if gameMap.layers["Colliders"] then
    for i, obj in pairs(gameMap.layers["Colliders"].objects) do
      local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
      collider:setType('static')
      table.insert(colliders, collider)
    end
  end

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
end

function love.update(dt)
  local isMoving = false
  local vx, vy = 0, 0
  local windowWidth = love.graphics.getWidth() / zoom
  local windowHeight = love.graphics.getHeight() / zoom
  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  if love.keyboard.isDown('d') then
    if player.x < (mapWidth - 32)  then
      vx = player.speed
      player.anim = player.animations.right
      player.lastHorizontal = "right"
      isMoving = true
    end
  end

  if love.keyboard.isDown('a') then
    if player.x > 32 then
      vx = player.speed * -1
      player.anim = player.animations.left
      player.lastHorizontal = "left"
      isMoving = true
    end
  end

  if love.keyboard.isDown('w') then
    if player.y > 32 then
      vy = player.speed * -1
      if player.lastHorizontal == "right" then
        player.anim = player.animations.upRight
      else
        player.anim = player.animations.upLeft
      end
      isMoving = true
    end
  end

  if love.keyboard.isDown('s') then
    if player.y < (mapHeight - 32) then
      vy = player.speed
      if player.lastHorizontal == "right" then
        player.anim = player.animations.downRight
      else
        player.anim = player.animations.downLeft
      end
      isMoving = true
    end
  end

  player.collider:setLinearVelocity(vx, vy)

  if not isMoving then
    player.anim = player.animations.idle
  end

  world:update(dt)
  player.x = player.collider:getX()
  player.y = player.collider:getY()
  player.anim:update(dt)

  cam:lookAt(player.x, player.y)

  -- camera borders
  if cam.x < windowWidth/2 then cam.x = windowWidth/2 end
  if cam.y < windowHeight/2 then cam.y = windowHeight/2 end
  if cam.x > (mapWidth - windowWidth/2) then cam.x = (mapWidth - windowWidth/2) end
  if cam.y > (mapHeight - windowHeight/2) then cam.y = (mapHeight - windowHeight/2) end
end

function love.draw()
  local scale = 1.5
  local ox, oy = 32/2, 32/2

  cam:attach(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 3)
    -- draw map
    gameMap:drawLayer(gameMap.layers['terrain0'])
    gameMap:drawLayer(gameMap.layers['terrain1'])
    gameMap:drawLayer(gameMap.layers['structures'])
    gameMap:drawLayer(gameMap.layers['water'])

    -- draw player
    if player.anim ~= player.animations.idle then
      player.anim:draw(player.walkSpriteSheet, player.x, player.y, 0, scale, scale, ox, oy)
    else
      if player.lastHorizontal == "right" then
        player.anim:draw(player.idleSpriteSheet, player.x, player.y, 0, scale, scale, ox, oy)
      else
        player.anim:draw(player.idleSpriteSheet, player.x, player.y, 0, -scale, scale, ox, oy)
      end
    end

    -- draw hitbox
    -- world:draw()
  cam:detach()
end
