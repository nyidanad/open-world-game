local Player = require 'src.player'
local Enemy = require 'src.enemy'

local zoom = 1.75

function love.load()
  anim8     = require 'lib/anim8'
  sti       = require 'lib/sti'
  camera    = require 'lib/camera'
  windfield = require 'lib/windfield'

  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("The Last Oath")
  love.window.setMode( 1280, 720 )
  
  -- Map and camera
  gameMap = sti('res/maps/test-map/test-map.lua')
  cam = camera()
  cam:zoomTo(zoom)

  -- Physics world
  world = windfield.newWorld(0, 0)

  -- Enemies
  enemies = 
  {
    enemy1 = Enemy.new("skeleton", world, 550, 200, 550, 200),
    enemy2 = Enemy.new("skeleton", world, 580, 430, 580, 430),
    enemy3 = Enemy.new("skeleton", world, 1100, 150, 1100, 150),
    enemy4 = Enemy.new("skeleton", world, 1080, 425, 1080, 425)
  }

  -- Player
  player = Player.new(world, 845, 250, enemies)

  -- Colliders
  colliders = {}
  if gameMap.layers["Colliders"] then
    for i, obj in pairs(gameMap.layers["Colliders"].objects) do
      local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
      collider:setType('static')
      table.insert(colliders, collider)
    end
  end
end

function love.update(dt)
  local windowWidth = love.graphics.getWidth() / zoom
  local windowHeight = love.graphics.getHeight() / zoom
  local mapWidth = gameMap.width * gameMap.tilewidth
  local mapHeight = gameMap.height * gameMap.tileheight

  for i, enemy in pairs(enemies) do
    enemy:update(dt)
  end

  world:update(dt)
  player:update(dt, mapWidth, mapHeight)
  cam:lookAt(player.x, player.y)

  -- camera borders
  if cam.x < windowWidth/2 then cam.x = windowWidth/2 end
  if cam.y < windowHeight/2 then cam.y = windowHeight/2 end
  if cam.x > (mapWidth - windowWidth/2) then cam.x = (mapWidth - windowWidth/2) end
  if cam.y > (mapHeight - windowHeight/2) then cam.y = (mapHeight - windowHeight/2) end
end

function love.draw()
  cam:attach(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 3)
    gameMap:drawLayer(gameMap.layers['terrain0'])
    gameMap:drawLayer(gameMap.layers['terrain1'])
    gameMap:drawLayer(gameMap.layers['structures'])
    gameMap:drawLayer(gameMap.layers['water'])
    
    for _, enemy in pairs(enemies) do
      enemy:draw()
    end

    player:draw()

    -- world:draw()
  cam:detach()
end

function love.mousepressed(x, y, button)
  if button == 1 then
    player:comboCheck()
  end
end