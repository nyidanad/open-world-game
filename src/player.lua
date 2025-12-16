local player = {}

function player.load(world, x, y, enemies)
  player.x = x
  player.y = y
  player.dir = "down"
  player.dirX = 1
  player.dirY = 1
  player.scale = 0.65
  player.speed = 65
  player.animSpeed = 0.14
  player.walking = false
  player.animTimer = 0
  player.health = 6
  player.damage = 1
  player.damagedTimer = 0
  player.damageDelayTimer = 0
  player.damagedBool = 1
  player.damagedFlashTime = 0.1
  player.attacked = false
  player.attackTimer = 0
  player.attackRange = 40
  player.deathTimer = 1.75
  player.invulnerable = false
  player.invulnerableTimer = 0

  -- 0: idle
  -- 1: walking
  -- 2: swing sword
  -- 10: stunned
  -- 11: dying
  -- 11.1: dead
  player.state = 0

  player.spriteSheet = love.graphics.newImage('res/sprites/player/geralt-silver.png')

  player.grid = anim8.newGrid(128, 128, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

  player.animations = {}
  player.animations.spellcastUp    = anim8.newAnimation(player.grid('1-7', 1), player.animSpeed)
  player.animations.spellcastLeft  = anim8.newAnimation(player.grid('1-7', 2), player.animSpeed)
  player.animations.spellcastDown  = anim8.newAnimation(player.grid('1-7', 3), player.animSpeed)
  player.animations.spellcastRight = anim8.newAnimation(player.grid('1-7', 4), player.animSpeed)
  player.animations.walkUp    = anim8.newAnimation(player.grid('1-9', 5), player.animSpeed)
  player.animations.walkLeft  = anim8.newAnimation(player.grid('1-9', 6), player.animSpeed)
  player.animations.walkDown  = anim8.newAnimation(player.grid('1-9', 7), player.animSpeed)
  player.animations.walkRight = anim8.newAnimation(player.grid('1-9', 8), player.animSpeed)
  player.animations.death = anim8.newAnimation(player.grid('1-6', 9), 0.2, "pauseAtEnd")
  player.animations.idleUp    = anim8.newAnimation(player.grid('1-2', 10), 0.8)
  player.animations.idleLeft  = anim8.newAnimation(player.grid('1-2', 11), 0.8)
  player.animations.idleDown  = anim8.newAnimation(player.grid('1-2', 12), 0.8)
  player.animations.idleRight = anim8.newAnimation(player.grid('1-2', 13), 0.8)
  player.animations.incombatUp    = anim8.newAnimation(player.grid('1-2', 22), 0.3)
  player.animations.incombatLeft  = anim8.newAnimation(player.grid('1-2', 23), 0.3)
  player.animations.incombatDown  = anim8.newAnimation(player.grid('1-2', 24), 0.3)
  player.animations.incombatRight = anim8.newAnimation(player.grid('1-2', 25), 0.3)
  player.animations.attack1Up    = anim8.newAnimation(player.grid('1-6', 26), 0.09)
  player.animations.attack1Left  = anim8.newAnimation(player.grid('1-6', 27), 0.09)
  player.animations.attack1Down  = anim8.newAnimation(player.grid('1-6', 28), 0.09)
  player.animations.attack1Right = anim8.newAnimation(player.grid('1-6', 29), 0.09)
  player.animations.attack3Up    = anim8.newAnimation(player.grid('1-13', 30), 0.1)
  player.animations.attack3Left  = anim8.newAnimation(player.grid('1-13', 31), 0.1)
  player.animations.attack3Down  = anim8.newAnimation(player.grid('1-13', 32), 0.1)
  player.animations.attack3Right = anim8.newAnimation(player.grid('1-13', 33), 0.1)
  player.animations.attack2Up    = anim8.newAnimation(player.grid('1-6', 34), 0.11)
  player.animations.attack2Left  = anim8.newAnimation(player.grid('1-6', 35), 0.11)
  player.animations.attack2Down  = anim8.newAnimation(player.grid('1-6', 36), 0.11)
  player.animations.attack2Right = anim8.newAnimation(player.grid('1-6', 37), 0.11)

  player.anim = player.animations.idleRight

  -- collider
  player.collider = world:newBSGRectangleCollider(x, y, 16, 10, 3)
  player.collider:setFixedRotation(true)
  player.collider:setCollisionClass('Player')

  player.sfx = {
    sword_swing_1 = love.audio.newSource('res/sounds/sfx/sword-swing-1.mp3', 'static'),
    sword_swing_2 = love.audio.newSource('res/sounds/sfx/sword-swing-2.mp3', 'static'),
    sword_swing_3 = love.audio.newSource('res/sounds/sfx/sword-swing-3.mp3', 'static'),
    sword_swing_4 = love.audio.newSource('res/sounds/sfx/sword-swing-4.mp3', 'static'),
    sword_swing_5 = love.audio.newSource('res/sounds/sfx/sword-swing-5.mp3', 'static'),
    dying = love.audio.newSource('res/sounds/sfx/dying.mp3', 'static'),
  }

  return player
end

function player.update(dt, mapWidth, mapHeight)
  local vx, vy = 0, 0
  player.walking = false

  -- checking while dying
  if player.health == 0 then
    if player.state ~= 11 then
      player.state = 11
      player.anim = player.animations.death
      player.sfx.dying:play()
    end

    player.deathTimer = player.deathTimer - dt
    player.collider:setLinearVelocity(0, 0)
    player.anim:update(dt)

    if player.deathTimer <= 0 then
      player.sfx.dying:stop()
      player.state = 11.1  -- trigger gameover scene after deathTimer is over
    end

    return  -- stops update here so player cannot move while dead
  end

  -- checking while swinging sword
  if math.floor(player.state) == 2 then
    player.attackTimer = player.attackTimer - dt
    player.damageDelayTimer = player.damageDelayTimer - dt
    player.collider:setLinearVelocity(0, 0)
    player.anim:update(dt)

    -- light attack
    if player.state == 2.1 then
      player.damage = 1
    
    -- heavy attack
    elseif player.state == 2.2 then
      player.damage = 2

    -- group attack
    elseif player.state == 2.3 then
      player.damage = 1
      if player.attackTimer <= 0.5 then
        player.sfx.sword_swing_4:play()
      else
        player.sfx.sword_swing_5:play()
      end
    end

    if player.damageDelayTimer <= 0 then
      if player.attacked then
        player:dealDamage(enemies)
        player.attacked = false
      end
    end

    if player.attackTimer <= 0 then
      player.state = 0
    end

    return  -- stops update here so player cannot move while attacking
  end

  -- checking if player get hurt
  if player.invulnerable then
    player.invulnerableTimer = player.invulnerableTimer - dt
    player.damagedTimer = player.damagedTimer - dt

    -- blinking logic while player invulnerable
    if player.damagedTimer <= 0 then
      if player.damagedBool == 1 then
        player.damagedBool = 0.3
      else
        player.damagedBool = 1
      end

      player.damagedTimer = player.damagedFlashTime
    end
    
    if player.invulnerableTimer <= 0 then
      player.invulnerable = false
      player.damagedBool = 1
    end
  end

  -- TEMPORARY KEYBINDINGS
  if love.keyboard.isDown('9') then
    player.health = 0
  end

  -- movement animation updates
  -- Note: only able to walk if not swinging sword or not dead
  if love.keyboard.isDown('d') then
    if player.x < (mapWidth - 64)  then
      player.state = 1
      player.walking = true
      player.dir = "right"
      player.anim = player.animations.walkRight
      vx = player.speed
    end
  end
  if love.keyboard.isDown('a') then
    if player.x > 64 then
      player.state = 1
      player.walking = true
      player.dir = "left"
      player.anim = player.animations.walkLeft
      vx = player.speed * -1
    end
  end
  if love.keyboard.isDown('w') then
    if player.y > 64 then
      player.state = 1
      player.walking = true
      player.dir = "up"
      player.anim = player.animations.walkUp
      vy = player.speed * -1
    end
  end
  if love.keyboard.isDown('s') then
    if player.y < (mapHeight - 64) then
      player.state = 1
      player.walking = true
      player.dir = "down"
      player.anim = player.animations.walkDown
      vy = player.speed
    end
  end

  -- attack animation updates
  if love.keyboard.isDown("j") then
    if player.state ~= 2 then        -- prevents spamming
      player.state = 2.1
      player.attackTimer = 0.55
      player.damageDelayTimer = 0.25
      player.attacked = true
      if     player.dir == "up"    then player.anim = player.animations.attack1Up
      elseif player.dir == "left"  then player.anim = player.animations.attack1Left
      elseif player.dir == "down"  then player.anim = player.animations.attack1Down
      elseif player.dir == "right" then player.anim = player.animations.attack1Right
      end
      player.anim:gotoFrame(1)
      player.sfx.sword_swing_2:play()
    end
  end
  if love.keyboard.isDown("k") then
    if player.state ~= 2 then        -- prevents spamming
      player.state = 2.2
      player.attackTimer = 0.6
      player.damageDelayTimer = 0.22
      player.attacked = true
      if     player.dir == "up"    then player.anim = player.animations.attack2Up
      elseif player.dir == "left"  then player.anim = player.animations.attack2Left
      elseif player.dir == "down"  then player.anim = player.animations.attack2Down
      elseif player.dir == "right" then player.anim = player.animations.attack2Right
      end
      player.anim:gotoFrame(1)
      player.sfx.sword_swing_1:play()
    end
  end
  if love.keyboard.isDown("l") then
    if player.state ~= 2 then        -- prevents spamming
      player.state = 2.3
      player.attackTimer = 1
      player.damageDelayTimer = 0.4
      player.attacked = true
      if     player.dir == "up"    then player.anim = player.animations.attack3Up
      elseif player.dir == "left"  then player.anim = player.animations.attack3Left
      elseif player.dir == "down"  then player.anim = player.animations.attack3Down
      elseif player.dir == "right" then player.anim = player.animations.attack3Right
      end
      player.anim:gotoFrame(1)
    end
  end

  -- ability (sings) animation updates
  -- Note: <u>: Aard
  --       <i>: Quen
  --       <o>: Igni
  --       <p>: Axii

  player.collider:setLinearVelocity(vx, vy)
  
  -- checking when to IDLE
  if not player.walking and player.state < 2 then
    player.state = 0
    if     player.dir == "up"    then player.anim = player.animations.idleUp
    elseif player.dir == "left"  then player.anim = player.animations.idleLeft
    elseif player.dir == "down"  then player.anim = player.animations.idleDown
    elseif player.dir == "right" then player.anim = player.animations.idleRight
    end
  end

  player.x = player.collider:getX()
  player.y = player.collider:getY() - 14
  
  player.anim:update(dt)
end

function player.draw()
  local ox, oy = 64, 64

  love.graphics.setColor(1, 1, 1, player.damagedBool)
  player.anim:draw(player.spriteSheet, player.x, player.y, 0, player.scale, player.scale, ox, oy)
  love.graphics.setColor(1, 1, 1, 1)
end

function player:dealDamage(enemies)
  for _, enemy in ipairs(enemies) do
    local dx, dy = enemy.x - player.x, enemy.y - player.y
    local dist = math.sqrt(dx*dx + dy*dy)
  
    if dist <= player.attackRange then
      -- check if enemy is dead
      if math.floor(enemy.state) ~= 11 then
        -- check if enemy is front of player on light and heavy attack
        if self.state == 2.1 or self.state == 2.2 then
          if     player.dir == "up"    and dy < 0 then enemy:hurt(player.damage)
          elseif player.dir == "down"  and dy > 0 then enemy:hurt(player.damage)
          elseif player.dir == "left"  and dx < 0 then enemy:hurt(player.damage)
          elseif player.dir == "right" and dx > 0 then enemy:hurt(player.damage)
          end
        -- dont check direction on group attack
        elseif self.state == 2.3 then
          enemy:hurt(player.damage)
        end
      end
    end
  end
end

function player:hurt(amount)
  player.invulnerable = true
  player.invulnerableTimer = 3
  player.damagedTimer = 0.1
  player.health = player.health - amount
end

return player