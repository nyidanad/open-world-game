local enemyTypes = require('src.enemies.enemyTypes')
local player = require('src.player')

local enemy = {}
enemy.__index = enemy

function enemy.load(world, x, y, type, initState, initDir)
  local self = setmetatable({}, enemy)
  local data = enemyTypes[type]

  -- origin properties
  self.spawnX = x
  self.spawnY = y
  self.initState = initState
  self.initDir = initDir
  self.initialSpeed = data.speed

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
  self.deathTimer = 1.75
  self.damagedBool = 1
  self.damagedFlashTime = 0.05
  self.damagedTimer = 0
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

  return self
end

function enemy:update(dt)
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
  if self.onCooldown then
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
  local ox, oy = 64, 64

  love.graphics.setColor(1, 1, 1, self.damagedBool)
  self.anim:draw(self.spriteSheet, self.x, self.y, 0, self.scale, self.scale, ox, oy)
  love.graphics.setColor(1, 1, 1, 1)
end

-- Handle chasing and leashing logic
-- Note: also here we handle when to attack
function enemy:chase()
  -- distance between agro and player
  local agrX = player.x - self.spawnX
  local agrY = player.y - self.spawnY
  local agroDist = math.sqrt(agrX*agrX + agrY*agrY)

  -- distance between player and enemy
  local dx = player.x - self.x
  local dy = player.y - self.y
  local dist = math.sqrt(dx*dx + dy*dy)

  -- distance between enemy and its spawnpoint
  local sx = self.spawnX - self.x
  local sy = self.spawnY - self.y
  local chaseDist = math.sqrt(sx*sx + sy*sy)

  local vx, vy = 0, 0

  -- checking agro distance
  if not self.chasing and agroDist <= self.agroRadius then
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
  if dist <= self.attackRange then
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
    self.attackCooldown = 2.5
    self.attackTimer = 0.92
  end

  self.onCooldown = true
  self.anim:gotoFrame(1)
end

return enemy