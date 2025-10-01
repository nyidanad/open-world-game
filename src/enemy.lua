local enemy = {}
enemy.__index = enemy

function enemy.new(type, world, x, y, ox, oy)
  local self = setmetatable({}, enemy)

  self.x = x
  self.y = y
  self.ox = ox  -- original x
  self.oy = oy  -- original y
  self.type = type
  self.speed = 60
  self.dead = false
  self.canAttack = true
  self.lastAttack = 0
  self.attackCooldown = 1.5  -- 1.5 second delay between attacks

  self.idleSpriteSheet  = love.graphics.newImage('res/sprites/enemies/skeleton-idle.png')
  self.walkSpriteSheet  = love.graphics.newImage('res/sprites/enemies/skeleton-walk.png')
  self.swordSpriteSheet = love.graphics.newImage('res/sprites/enemies/skeleton-attack.png')

  self.idle  = anim8.newGrid(64, 64, self.idleSpriteSheet:getWidth(), self.idleSpriteSheet:getHeight())
  self.walk  = anim8.newGrid(64, 64, self.walkSpriteSheet:getWidth(), self.walkSpriteSheet:getHeight())
  self.sword = anim8.newGrid(64, 64, self.swordSpriteSheet:getWidth(), self.swordSpriteSheet:getHeight())

  -- animations
  self.animations = {}
  self.animations.idle  = anim8.newAnimation(self.idle('1-2', 1), 0.6)
  self.animations.walk  = anim8.newAnimation(self.walk('1-2', 1), 0.4)
  self.animations.sword = anim8.newAnimation(self.sword('1-3', 1), 0.2)

  -- starting position
  self.state = "idle"
  self.anim = self.animations.right
  self.direction = "right"

  -- collider
  self.collider = world:newBSGRectangleCollider(x, y, 25, 16, 4)
  self.collider:setFixedRotation(true)

  return self
end

function enemy:update(dt)
  -- Basic AI: chase if close, else idle
  local dx, dy = player.x - self.x, player.y - self.y
  local dist = math.sqrt(dx*dx + dy*dy)
  local vx, vy = 0, 0
  local timer = love.timer.getTime()

  -- Cooldown between attacks
  if (timer - self.lastAttack) >= self.attackCooldown and not self.canAttack then
    self.canAttack = true
  end

  if self.state == "attack" and (timer - self.lastAttack) >= 0.5 and not self.canAttack then
    self.anim:gotoFrame(1)
    self.state = "idle"
    self.anim = self.animations.idle
  end

  if dist < 260 and dist > 45 then
      -- Chase
      vx = (dx/dist) * self.speed
      vy = (dy/dist) * self.speed
      self.state = "chase"
      self.anim = self.animations.walk

  elseif dist <= 45 then
    if self.canAttack then
      -- Attack
      self.state = "attack"
      self.anim = self.animations.sword
      self.lastAttack = timer
      self.canAttack = false
      self:attack()
    end

  else
      self.state = "idle"
      self.anim = self.animations.idle
  end

  -- Dismiss logic: too far from spawnpoint
  local dxo, dyo = self.x - self.ox, self.y - self.oy
  local distFromOrigin = math.sqrt(dxo*dxo + dyo*dyo)
  if distFromOrigin > 625 then
      self.collider:setPosition(self.ox, self.oy)
      vx, vy = 0, 0
      self.state = "idle"
  end

  -- Determine direction
  if vx > 0 then
    self.direction = "right"
  elseif vx < 0 then
    self.direction = "left"
  end

  self.collider:setLinearVelocity(vx, vy)

  self.x = self.collider:getX()
  self.y = self.collider:getY() - 16
  self.anim:update(dt)
end

function enemy:attack()
  -- TODO
end

function enemy:draw()
  local scale = 1.3
  local ox, oy = 32, 32
  local sx = (self.direction == "left") and -scale or scale

  if self.state == "idle" then
    self.anim:draw(self.idleSpriteSheet, self.x, self.y, 0, sx, scale, ox, oy)
  elseif self.state == "chase" then
    self.anim:draw(self.walkSpriteSheet, self.x, self.y, 0, sx, scale, ox, oy)
  elseif self.state == "attack" then
    self.anim:draw(self.swordSpriteSheet, self.x, self.y, 0, sx, scale, ox, oy)
  end
end

return enemy