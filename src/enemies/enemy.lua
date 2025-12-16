local enemyTypes = require('src.enemies.enemyTypes')
local shaders = require('src.utils.shaders')

local enemy = {}
enemy.__index = enemy

function enemy.load(world, x, y, type, initState, initDir, player, enemies)
  local self = setmetatable({}, enemy)
  local data = enemyTypes[type]
  
  -- origin properties
  self.world = world
  self.spawnX = x
  self.spawnY = y
  self.initState = initState
  self.initDir = initDir
  self.initialSpeed = data.speed
  self.player = player
  self.initHealth = data.health

  -- per-type properties
  self.spriteSheet = love.graphics.newImage(data.sprite)
  self.health = data.health
  self.speed = data.speed
  self.damage = data.damage
  self.scale = data.scale

  -- base properties
  self.x = x
  self.y = y
  self.dir = initDir
  self.dirX = 1
  self.dirY = 1
  self.animSpeed = 0.14
  self.wondering = false
  self.wonderingRadius = 120
  self.chasing = false
  self.leashing = false
  self.animTimer = 0
  self.stunned = false
  self.stunnedFlashTimer = 0
  self.stunnedTimer = 0
  self.attackTimer = 0
  self.attackCooldown = 0
  self.onCooldown = false
  self.attackRange = data.attackRange
  self.agroRadius = 100
  self.chaseRadius = 500
  self.attackType = nil
  self.spellCooldown = 2
  self.spellTimer = 0
  self.isSpellcaster = data.isSpellcaster
  self.despawnTimer = 180
  self.knockbackVX = 0
  self.knockbackVY = 0
  self.knockbackForce = 300
  self.LoS = false

  -- 0: idle
  -- 0.1: incombat idle
  -- 1: sit
  -- 2: wondering (stopped)
  -- 2.1: wondering (moving)
  -- 3: chase
  -- 10: stunned
  -- 11: dying
  -- 11.1: dead
  -- 20: alert
  -- 21: attacking
  self.state = initState

  self.grid = anim8.newGrid(128, 128, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())

  self.animations = data.animations(self.grid, anim8)

  self.anim = self.animations.idleDown

  -- collider
  self.collider = world:newBSGRectangleCollider(x, y, 16, 10, 3)
  self.collider:setFixedRotation(true)
  self.collider:setCollisionClass('Enemy')

  self.sfx = {
    sword_swing = {
      love.audio.newSource('res/sounds/sfx/sword-swing-1.mp3', 'static'),
      love.audio.newSource('res/sounds/sfx/sword-swing-2.mp3', 'static'),
    },

    hit = {
      love.audio.newSource('res/sounds/sfx/enemy-hit-1.mp3', 'static'),
      love.audio.newSource('res/sounds/sfx/enemy-hit-2.mp3', 'static'),
      love.audio.newSource('res/sounds/sfx/enemy-hit-3.mp3', 'static'),
    },

    dying = {
      love.audio.newSource('res/sounds/sfx/enemy-dying-1.mp3', 'static'),
      love.audio.newSource('res/sounds/sfx/enemy-dying-2.mp3', 'static'),
      love.audio.newSource('res/sounds/sfx/enemy-dying-3.mp3', 'static'),
    }
  }

  return self
end

function enemy:update(dt)
  local list = self.sfx.dying
  local sfx = list[math.random(#list)]

  -- checking if enemy dead
  if self.health <= 0 then
    if self.state ~= 11 then
      self.state = 11
      self.anim = self.animations.death
      sfx:play()
    end

    self.despawnTimer = self.despawnTimer - dt
    self.collider:setLinearVelocity(0, 0)
    self.anim:update(dt)
    
    if self.despawnTimer <= 0 then
      for i, e in ipairs(enemies) do
        if e == self then
          self.collider:destroy()
          table.remove(enemies, i)
          break
        end
      end
    end

    return  -- stops update here so enemy cannot move while dead
  end

  -- checking if stunned
  if self.stunned then
    self.stunnedTimer = self.stunnedTimer - dt
    self.stunnedFlashTimer = self.stunnedFlashTimer - dt

    -- knockback damping
    local damping = 6
    self.knockbackVX = self.knockbackVX - self.knockbackVX * damping * dt
    self.knockbackVY = self.knockbackVY - self.knockbackVY * damping * dt

    self.collider:setLinearVelocity(self.knockbackVX, self.knockbackVY)

    self.x = self.collider:getX()
    self.y = self.collider:getY() - 14

    if self.stunnedTimer <= 0 then
      self.stunned = false
      self.knockbackVX = 0
      self.knockbackVY = 0
      self.collider:setLinearVelocity(self.knockbackVX, self.knockbackVY)
    end

    self.anim:update(dt)
    return
  end

  -- idle animations
  if math.floor(self.state) == 0 then
    -- normal idle animations
    if self.state == 0 then
      if     self.dir == "up"    then self.anim = self.animations.idleUp
      elseif self.dir == "left"  then self.anim = self.animations.idleLeft
      elseif self.dir == "down"  then self.anim = self.animations.idleDown
      elseif self.dir == "right" then self.anim = self.animations.idleRight
      end
      
    -- incombat idle animations
    elseif self.state == 0.1 then
      if     self.dir == "up"    then self.anim = self.animations.inCombatUp
      elseif self.dir == "left"  then self.anim = self.animations.inCombatLeft
      elseif self.dir == "down"  then self.anim = self.animations.inCombatDown
      elseif self.dir == "right" then self.anim = self.animations.inCombatRight
      end
    end
  end

  -- sit animations
  if self.state == 1 then
    if     self.dir == "up"    then self.anim = self.animations.sitUp
    elseif self.dir == "left"  then self.anim = self.animations.sitLeft
    elseif self.dir == "down"  then self.anim = self.animations.sitDown
    elseif self.dir == "right" then self.anim = self.animations.sitRight
    end
  end
  
  -- chasing animations
  if self.state == 3 then
    if     self.dir == "up"    then self.anim = self.animations.walkUp
    elseif self.dir == "left"  then self.anim = self.animations.walkLeft
    elseif self.dir == "down"  then self.anim = self.animations.walkDown
    elseif self.dir == "right" then self.anim = self.animations.walkRight
    end
  end

  -- attack animations
  if self.state == 21 then
    -- mage attack animations
    if self.isSpellcaster then
      if self.attackType == 1 then
        if     self.dir == "up"    then self.anim = self.animations.spell1Up
        elseif self.dir == "left"  then self.anim = self.animations.spell1Left
        elseif self.dir == "down"  then self.anim = self.animations.spell1Down
        elseif self.dir == "right" then self.anim = self.animations.spell1Right
        end
      end
      if self.attackType == 2 then
        if     self.dir == "up"    then self.anim = self.animations.spell2Up
        elseif self.dir == "left"  then self.anim = self.animations.spell2Left
        elseif self.dir == "down"  then self.anim = self.animations.spell2Down
        elseif self.dir == "right" then self.anim = self.animations.spell2Right
        end
      end
      if self.attackType == 3 then
        if     self.dir == "up"    then self.anim = self.animations.spell3Up
        elseif self.dir == "left"  then self.anim = self.animations.spell3Left
        elseif self.dir == "down"  then self.anim = self.animations.spell3Down
        elseif self.dir == "right" then self.anim = self.animations.spell3Right
        end
      end

    -- normal attack animations
    else
      if     self.dir == "up"    then self.anim = self.animations.attackUp
      elseif self.dir == "left"  then self.anim = self.animations.attackLeft
      elseif self.dir == "down"  then self.anim = self.animations.attackDown
      elseif self.dir == "right" then self.anim = self.animations.attackRight
      end
    end
  end

  -- checking cooldown
  if not self.stunned and self.onCooldown then
    self.attackCooldown = self.attackCooldown - dt
    self.attackTimer = self.attackTimer - dt
    self.anim:update(dt)

    if self.attackTimer <= 0 then
      self.state = 0.1

      if self.attackCooldown <= 0 then
        self.onCooldown = false
        self.state = 21
      end
    end

    return
  end

  -- checking chase
  self:chase()

  self.x = self.collider:getX()
  self.y = self.collider:getY() - 14

  self.anim:update(dt)
end

function enemy:draw()
  if self.health > 0 and self.stunned and self.stunnedFlashTimer > 0 then
    love.graphics.setShader(shaders.whiteout)
  end
  
  -- enemy sprite
  self.anim:draw(self.spriteSheet, self.x, self.y, 0, self.scale, self.scale, 64, 64)
  love.graphics.setShader()

  -- HP bar position
  local barWidth = self.initHealth * 8
  local barHeight = 1
  local x = self.x - barWidth/2
  local y = self.y - 20
  
  local healthPercent = self.health / self.initHealth
  local hpWidth = barWidth * healthPercent

  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", x, y, barWidth, barHeight)
  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.rectangle("fill", x, y, hpWidth, barHeight)
  love.graphics.setColor(1, 1, 1, 1)
end

-- Handle chasing and leashing logic
-- Note: also here we handle when to attack
function enemy:chase()
  self:checkLoS()

  -- distance between agro and player
  local agrX = self.player.x - self.spawnX
  local agrY = self.player.y - self.spawnY
  local agroDist = math.sqrt(agrX*agrX + agrY*agrY)

  -- distance between player and enemy
  local dx = self.player.x - self.x
  local dy = self.player.y - self.y
  local dist = math.sqrt(dx*dx + dy*dy)

  -- distance between enemy and its spawnpoint
  local sx = self.spawnX - self.x
  local sy = self.spawnY - self.y
  local chaseDist = math.sqrt(sx*sx + sy*sy)

  local vx, vy = 0, 0

  -- checking agro distance
  if not self.chasing and agroDist <= self.agroRadius and self.LoS then
    self.chasing = true
    self.state = 3
  end

  -- checking chase distance
  if self.chasing and chaseDist < self.chaseRadius then
    -- chasing
    vx = (dx / dist) * self.speed
    vy = (dy / dist) * self.speed
  elseif self.chasing and chaseDist >= self.chaseRadius then
    -- leashing
    self.speed = 200
    self.chasing = false
    self.leashing = true
  end

  -- checking if player in range of attack
  if dist <= self.attackRange and self.LoS then
    vx, vy = 0, 0
    self.chasing = false
    self.state = 21

    if not self.onCooldown then
      self:attack()
    end
  end

  -- checking if player leaves attack range
  if self.state == 21 and dist >= self.attackRange then
    self.chasing = true
    self.state = 3
  end

  -- leashing enemy
  if self.leashing then
    if chaseDist > 5 then
      vx = (sx / chaseDist) * self.speed
      vy = (sy / chaseDist) * self.speed
    else
      -- reached spawnpoint
      vx, vy = 0, 0
      self.leashing = false
      self.dir = self.initDir
      self.state = self.initState
      self.speed = self.initialSpeed
      self.collider:setPosition(self.spawnX, self.spawnY)
    end
  end

  -- check direction
  if math.abs(vx) > math.abs(vy) then
    if vx > 0 then self.dir = "right"
    elseif vx < 0 then self.dir = "left"
    end
  else
    if vy < 0 then self.dir = "up"
    elseif vy > 0 then self.dir = "down"
    end
  end

  self.collider:setLinearVelocity(vx, vy)
end

function enemy:attack()
  local list = self.sfx.sword_swing
  local sfx = list[math.random(#list)]
  -- mage attacks
  if self.isSpellcaster then
    self.attackType = math.random(1, 3)

    if self.attackType == 1 then
      self.attackCooldown = 6
      self.attackTimer = 1.1
    elseif self.attackType == 2 then
      self.attackCooldown = 3
      self.attackTimer = 0.92
    elseif self.attackType == 3 then
      self.attackCooldown = 3
      self.attackTimer = 0.92
    end
  
  -- fighters attack
  else
    self.attackCooldown = 1.5
    self.attackTimer = 0.92
    sfx:play()
    
    if not player.invulnerable then player:hurt(self.damage) end
  end

  self.onCooldown = true
  self.anim:gotoFrame(1)
end

function enemy:hurt(amount)
  local list = self.sfx.hit
  local sfx = list[math.random(#list)]

  self.stunned = true
  self.stunnedTimer = 0.25        -- stun ideje
  self.stunnedFlashTimer = 0.1

  -- direction towards the player
  local dx = self.x - self.player.x
  local dy = self.y - self.player.y
  local dist = math.sqrt(dx*dx + dy*dy)

  if dist ~= 0 then
    dx = dx / dist
    dy = dy / dist
  end

  -- knockback velocity
  self.knockbackVX = dx * self.knockbackForce
  self.knockbackVY = dy * self.knockbackForce

  self.health = math.max(0, self.health - amount)
  sfx:play()
end

function enemy:checkLoS()
  local ex, ey = self.x, self.y
  local px, py = self.player.x, self.player.y
  local block = false

  self.world:rayCast(ex, ey, px, py, function(fixture, hx, hy, nx, ny, fraction)
    local col = fixture:getUserData()
    if col and col.collision_class == 'Obstacle' then
      block = true
      return 0  -- stopping rayCast because we hit an object
    end
    return -1 -- ignore everything else
  end)

  self.LoS = not block
end

return enemy