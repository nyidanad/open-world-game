local Player = require 'src.player'
local menu   = require 'src.ui.menu'
local zoom   = 4
local background = nil

function love.load()
  music = {
    mainmenu = love.audio.newSource('res/sounds/music/main-menu.mp3', 'stream'),
    kaer_morhen = love.audio.newSource('res/sounds/music/kaer-morhen.mp3', 'stream'),
  }
  sfx = {
    open_menu = love.audio.newSource('res/sounds/sfx/open-menu.mp3', 'static'), 
    gameover = love.audio.newSource('res/sounds/sfx/mission-failed.mp3', 'static'), 
  }

  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("The Last Oath")
  love.window.setFullscreen(true)

  background = love.graphics.newImage('res/ui/main-menu-background.png')
  menu.load()
  menu.mainmenu(startGame)
end

function love.update(dt)
  -- checking musics
  if menu.state == 0 then  -- main menu
    music.mainmenu:play()
    music.mainmenu:setVolume(0.5)
  else
    music.mainmenu:stop()
    if menu.state == 1 then  -- running
      music.kaer_morhen:play()
      music.kaer_morhen:setVolume(0.15)
    else
      if menu.state == 2 then  -- puase
        music.kaer_morhen:pause()
      else
        music.kaer_morhen:stop()
      end
    end
  end

  -- check states
  if menu.state == 1 then
    -- game over scene
    if player.state == 11.1 then
      menu.state = 3
      menu.gameOver(startGame)
      sfx.gameover:play()
    end

    local windowWidth = love.graphics.getWidth() / zoom
    local windowHeight = love.graphics.getHeight() / zoom
    local mapWidth = gameMap.width * gameMap.tilewidth
    local mapHeight = gameMap.height * gameMap.tileheight

    world:update(dt)
    player.update(dt, mapWidth, mapHeight)
    cam:lookAt(player.x, player.y)

    -- camera borders
    if cam.x < windowWidth/2 then cam.x = windowWidth/2 end
    if cam.y < windowHeight/2 then cam.y = windowHeight/2 end
    if cam.x > (mapWidth - windowWidth/2) then cam.x = (mapWidth - windowWidth/2) end
    if cam.y > (mapHeight - windowHeight/2) then cam.y = (mapHeight - windowHeight/2) end
  end
end

function love.draw()
  local screenW, screenH
  local videoW, videoH

  if background then
    screenW, screenH = love.graphics.getDimensions()
    videoW, videoH = background:getDimensions()
  end
  
  if menu.state == 0 then
    love.graphics.draw(background, 0, 0, 0, screenW / videoW, screenH / videoH)
    menu.draw("")
  else
    cam:attach(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 3)
      gameMap:drawLayer(gameMap.layers['ground'])
      gameMap:drawLayer(gameMap.layers['grass'])
      gameMap:drawLayer(gameMap.layers['walkway'])
      gameMap:drawLayer(gameMap.layers['water'])
      gameMap:drawLayer(gameMap.layers['grave-yard-rocks'])
      gameMap:drawLayer(gameMap.layers['props-z0'])
      gameMap:drawLayer(gameMap.layers['walls-bottom'])
      gameMap:drawLayer(gameMap.layers['objects-bottom'])
      gameMap:drawLayer(gameMap.layers['props-z1-bottom'])
      gameMap:drawLayer(gameMap.layers['props-z2-bottom'])
      player:draw()
      gameMap:drawLayer(gameMap.layers['walls-top'])
      gameMap:drawLayer(gameMap.layers['objects-top'])
      gameMap:drawLayer(gameMap.layers['props-z1-top'])
      gameMap:drawLayer(gameMap.layers['props-z2-top'])
      
      -- world:draw()
    cam:detach()

    if menu.state == 2 then
      love.graphics.setColor(0, 0, 0, 0.8)
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      menu.draw("PAUSED")

    elseif menu.state == 3 then
      love.graphics.setColor(0, 0, 0, 0.8)
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      menu.draw("GAME OVER")
    end
  end
end

function love.mousepressed(x, y, button)
  if menu.state ~= 1 then
    menu.mousepressed(x, y, button)
  end
end

function love.keypressed(key)
  if key == "escape" then
    if menu.state == 1 then
      menu.state = 2
      menu.pausemenu(startGame)
      sfx.open_menu:play()
      sfx.open_menu:setVolume(0.75)

    elseif menu.state == 2 then
      menu.state = 1
      sfx.open_menu:play()
      sfx.open_menu:setVolume(0.75)
    end
  end
end

function startGame()
  anim8     = require 'lib/anim8'
  sti       = require 'lib/sti'
  camera    = require 'lib/camera'
  windfield = require 'lib/windfield'

  -- Map and camera
  gameMap = sti('res/maps/village/village.lua')
  cam = camera()
  cam:zoomTo(zoom)

  -- Physics world
  world = windfield.newWorld(0, 0)

  -- Player
  player = Player.load(world, 775, 660)

  -- Colliders
  -- colliders = {}
  -- if gameMap.layers["Colliders"] then
  --   for i, obj in pairs(gameMap.layers["Colliders"].objects) do
  --     local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
  --     collider:setType('static')
  --     table.insert(colliders, collider)
  --   end
  -- end

  menu.state = 1
end