local player = {}

function player.new(world, x, y)
  player.x = x
  player.y = y
  player.speed = 150

  -- combat
  player.combo = 1
  player.lastAttack = 0
  player.comboWindow = 1.5

  player.idleSpriteSheet  = love.graphics.newImage('res/sprites/player/player-idle-sword.png')
  player.walkSpriteSheet  = love.graphics.newImage('res/sprites/player/player-walk-sword.png')
  player.swordSpriteSheet = love.graphics.newImage('res/sprites/player/player-attack-sword.png')

  player.idle  = anim8.newGrid(64, 64, player.idleSpriteSheet:getWidth(), player.idleSpriteSheet:getHeight())
  player.walk  = anim8.newGrid(64, 64, player.walkSpriteSheet:getWidth(), player.walkSpriteSheet:getHeight())
  player.sword = anim8.newGrid(64, 64, player.swordSpriteSheet:getWidth(), player.swordSpriteSheet:getHeight())

  -- animations
  player.animations = {}
  player.animations.idle    = anim8.newAnimation(player.idle('1-2', 1), 0.4)
  player.animations.walk    = anim8.newAnimation(player.walk('1-4', 1), 0.2)
  player.animations.walkUp  = anim8.newAnimation(player.walk('1-4', 2), 0.2)
  player.animations.attack1 = anim8.newAnimation(player.sword('1-2', 1), 0.2)
  player.animations.attack2 = anim8.newAnimation(player.sword('1-2', 2), 0.3)

  -- starting position
  player.state = "idle"
  player.anim = player.animations.idle
  player.lastHorizontal = "right"

  -- collider
  player.collider = world:newBSGRectangleCollider(x, y, 25, 16, 4)
  player.collider:setFixedRotation(true)

  return player
end


function player:attack()
  local timer = love.timer.getTime()
  local dif = timer - player.lastAttack

  -- first attack
  if player.combo == 1 then
    player.state = "attack"
    player.anim = player.animations.attack1
    player.lastAttack = timer
    if (player.lastAttack >= 0.2) then
      player.combo = 2
      player.anim:gotoFrame(1)
    end

  -- second attack
  elseif player.combo == 2 and dif <= player.comboWindow and dif >= 0.2 then
    player.state = "attack"
    player.anim = player.animations.attack2
    player.lastAttack = timer
    if (player.lastAttack >= 0.8) then
      player.combo = 3
    end
  
  -- remove attack state
  elseif player.combo == 3  and dif >= 0.6 then
    player.state = "idle"
    player.anim = player.animations.idle
    player.anim:gotoFrame(1)
    player.combo = 1
  end
end


function player:update(dt, mapWidth, mapHeight)
  local vx, vy = 0, 0
  local isMoving = false
  local timer = love.timer.getTime()
  local dif = timer - player.lastAttack

  -- cancel combo
  if player.state == "attack" then
    if player.combo == 2 and dif >= 0.4 then
      player.combo = 1
      player.anim:gotoFrame(1)
      player.state = "idle"
      player.anim = player.animations.idle
    end
  
    if player.combo == 3 and dif >= 0.4 then
      player.combo = 1
      player.anim:gotoFrame(1)
      player.state = "idle"
      player.anim = player.animations.idle
    end
  
  end
  
  if dif >= player.comboWindow then
    player.combo = 1
    if player.state == "attack" then
      player.state = "idle"
      player.anim = player.animations.idle
    end
  end

  if player.state ~= "attack" then
    if love.keyboard.isDown('d') then
      if player.x < (mapWidth - 32)  then
        vx = player.speed
        player.state = "walk"
        player.anim = player.animations.walk
        player.lastHorizontal = "right"
        isMoving = true
      end
    end
  
    if love.keyboard.isDown('a') then
      if player.x > 32 then
        vx = player.speed * -1
        player.state = "walk"
        player.anim = player.animations.walk
        player.lastHorizontal = "left"
        isMoving = true
      end
    end
  
    if love.keyboard.isDown('w') then
      if player.y > 32 then
        vy = player.speed * -1
        player.state = "walk"
        player.anim = player.animations.walkUp
        isMoving = true
      end
    end
  
    if love.keyboard.isDown('s') then
      if player.y < (mapHeight - 32) then
        vy = player.speed
        player.state = "walk"
        player.anim = player.animations.walk
        isMoving = true
      end
    end
  end

  player.collider:setLinearVelocity(vx, vy)

  if not isMoving and player.state ~= "attack" then
    player.state = "idle"
    player.anim = player.animations.idle
  end

  player.x = player.collider:getX()
  player.y = player.collider:getY() - 16
  player.anim:update(dt)
end


function player:draw()
  local scale = 1.5
  local ox, oy = 32, 32
  local sx = (player.lastHorizontal == "left") and -scale or scale

  if player.state == "idle" then
    player.anim:draw(player.idleSpriteSheet, player.x, player.y, 0, sx, scale, ox, oy)
  elseif player.state == "walk" then
    player.anim:draw(player.walkSpriteSheet, player.x, player.y, 0, sx, scale, ox, oy)
  elseif player.state == "attack" then
    player.anim:draw(player.swordSpriteSheet, player.x, player.y, 0, sx, scale, ox, oy)
  end
end

return player