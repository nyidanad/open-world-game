local enemy = {}

function enemy.new(type, world, x, y, ox, oy)
  enemy.x = x
  enemy.y = y
  enemy.ox = ox  -- original x
  enemy.oy = oy  -- original y
  enemy.type = type
  enemy.speed = 40
  enemy.dead = false

  enemy.idleSpriteSheet = love.graphics.newImage('res/sprites/enemies/orc-shielder-1.png')
  -- enemy.walkSpriteSheet = love.graphics.newImage('res/sprites/enemies/orc-elite-5.png')
  enemy.idle = anim8.newGrid(32, 32, enemy.idleSpriteSheet:getWidth(), enemy.idleSpriteSheet:getHeight())
  -- enemy.walk = anim8.newGrid(32, 32, enemy.walkSpriteSheet:getWidth(), enemy.walkSpriteSheet:getHeight())

  -- animations
  enemy.animations = {}
  -- enemy.animations.idle = anim8.newAnimation(enemy.idle('1-2', 1), 0.4)
  -- enemy.animations.right = anim8.newAnimation(enemy.walk('1-4', 1), 0.2)
  -- enemy.animations.left  = anim8.newAnimation(enemy.walk('1-4', 2), 0.2)
  -- enemy.animations.upRight = anim8.newAnimation(enemy.walk('1-4', 3), 0.2)
  -- enemy.animations.upLeft  = anim8.newAnimation(enemy.walk('1-4', 4), 0.2)
  -- enemy.animations.downRight = anim8.newAnimation(enemy.walk('1-4', 1), 0.2)
  -- enemy.animations.downLeft  = anim8.newAnimation(enemy.walk('1-4', 2), 0.2)

  -- starting position
  enemy.anim = enemy.animations.right
  enemy.lastHorizontal = "right"

  -- collider
  enemy.collider = world:newBSGRectangleCollider(x, y, 25, 16, 4)
  enemy.collider:setFixedRotation(true)

  return enemy
end

function enemy:update(dt)
  -- Basic AI: chase if close, else idle
  local dx, dy = player.x - enemy.x, player.y - enemy.y
  local dist = math.sqrt(dx*dx + dy*dy)
  local vx, vy = 0, 0

  if dist < 260 and dist > 45 then
      -- Chase
      vx = (dx/dist) * enemy.speed
      vy = (dy/dist) * enemy.speed
      enemy.state = "chase"
      enemy.anim = enemy.animations.walk
  elseif dist <= 45 then
      -- Attack
      enemy.state = "attack"
      enemy.anim = enemy.animations.attack
      enemy:attack()
  else
      enemy.state = "idle"
      enemy.anim = enemy.animations.idle
  end

  -- Dismiss logic: too far from spawnpoint
  local dxo, dyo = enemy.x - enemy.ox, enemy.y - enemy.oy
  local distFromOrigin = math.sqrt(dxo*dxo + dyo*dyo)
  if distFromOrigin > 625 then
      enemy.collider:setPosition(enemy.ox, enemy.oy)
      vx, vy = 0, 0
      enemy.state = "idle"
  end

  enemy.collider:setLinearVelocity(vx, vy)

  if not isMoving then
    enemy.anim = enemy.animations.idle
  end

  enemy.x = enemy.collider:getX()
  enemy.y = enemy.collider:getY() - 16
  -- enemy.anim:update(dt)
end

function enemy:attack()
  -- TODO
end

function enemy:draw()
  local scale = 1.75
  local ox, oy = 16, 16

  if enemy.dead then return end
    -- enemy.anim:draw(enemy.idleSpriteSheet, enemy.x, enemy.y, 0, scale, scale, ox, oy)
    love.graphics.draw(enemy.idleSpriteSheet, enemy.x, enemy.y, 0, scale, scale, ox, oy)
end

return enemy