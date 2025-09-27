local Enemy = {}

function Enemy.new(type, world, x, y, ox, oy)
  Enemy.x = x
  Enemy.y = y
  Enemy.ox = ox  -- original x
  Enemy.oy = oy  -- original y
  Enemy.type = type
  Enemy.speed = 40
  Enemy.dead = false

  Enemy.idleSpriteSheet = love.graphics.newImage('res/sprites/enemies/orc-shielder-1.png')
  -- Enemy.walkSpriteSheet = love.graphics.newImage('res/sprites/enemies/orc-elite-5.png')
  Enemy.idle = anim8.newGrid(32, 32, Enemy.idleSpriteSheet:getWidth(), Enemy.idleSpriteSheet:getHeight())
  -- Enemy.walk = anim8.newGrid(32, 32, Enemy.walkSpriteSheet:getWidth(), Enemy.walkSpriteSheet:getHeight())

  -- animations
  Enemy.animations = {}
  -- Enemy.animations.idle = anim8.newAnimation(Enemy.idle('1-2', 1), 0.4)
  -- Enemy.animations.right = anim8.newAnimation(Enemy.walk('1-4', 1), 0.2)
  -- Enemy.animations.left  = anim8.newAnimation(Enemy.walk('1-4', 2), 0.2)
  -- Enemy.animations.upRight = anim8.newAnimation(Enemy.walk('1-4', 3), 0.2)
  -- Enemy.animations.upLeft  = anim8.newAnimation(Enemy.walk('1-4', 4), 0.2)
  -- Enemy.animations.downRight = anim8.newAnimation(Enemy.walk('1-4', 1), 0.2)
  -- Enemy.animations.downLeft  = anim8.newAnimation(Enemy.walk('1-4', 2), 0.2)

  -- starting position
  Enemy.anim = Enemy.animations.right
  Enemy.lastHorizontal = "right"

  -- collider
  Enemy.collider = world:newBSGRectangleCollider(x, y, 40, 56, 6)
  Enemy.collider:setFixedRotation(true)

  return Enemy
end

function Enemy:update(dt)
  -- Basic AI: chase if close, else idle
  local dx, dy = player.x - Enemy.x, player.y - Enemy.y
  local dist = math.sqrt(dx*dx + dy*dy)
  local vx, vy = 0, 0

  if dist < 280 and dist > 50 then
      -- Chase
      vx = (dx/dist) * Enemy.speed
      vy = (dy/dist) * Enemy.speed
      Enemy.state = "chase"
      Enemy.anim = Enemy.animations.walk
  elseif dist <= 50 then
      -- Attack
      Enemy.state = "attack"
      Enemy.anim = Enemy.animations.attack
      Enemy:attack()
  else
      Enemy.state = "idle"
      Enemy.anim = Enemy.animations.idle
  end

  -- Dismiss logic: too far from spawnpoint
  local dxo, dyo = Enemy.x - Enemy.ox, Enemy.y - Enemy.oy
  local distFromOrigin = math.sqrt(dxo*dxo + dyo*dyo)
  if distFromOrigin > 625 then
      Enemy.collider:setPosition(Enemy.ox, Enemy.oy)
      vx, vy = 0, 0
      Enemy.state = "idle"
  end

  Enemy.collider:setLinearVelocity(vx, vy)

  if not isMoving then
    Enemy.anim = Enemy.animations.idle
  end

  Enemy.x = Enemy.collider:getX()
  Enemy.y = Enemy.collider:getY()
  -- Enemy.anim:update(dt)
end

function Enemy:attack()
  -- TODO
end

function Enemy:draw()
  local scale = 1.75
  local ox, oy = 16, 16

  if Enemy.dead then return end
    -- Enemy.anim:draw(Enemy.idleSpriteSheet, Enemy.x, Enemy.y, 0, scale, scale, ox, oy)
    love.graphics.draw(Enemy.idleSpriteSheet, Enemy.x, Enemy.y, 0, scale, scale, ox, oy)
end

return Enemy