local Player = {}

function Player.new(world, x, y)
  Player.x = x
  Player.y = y
  Player.speed = 150

  Player.idleSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-idle.png')
  Player.walkSpriteSheet = love.graphics.newImage('res/sprites/main-character/main-character-walk.png')
  Player.idle = anim8.newGrid(32, 32, Player.idleSpriteSheet:getWidth(), Player.idleSpriteSheet:getHeight())
  Player.walk = anim8.newGrid(32, 32, Player.walkSpriteSheet:getWidth(), Player.walkSpriteSheet:getHeight())

  -- animations
  Player.animations = {}
  Player.animations.idle = anim8.newAnimation(Player.idle('1-2', 1), 0.4)
  Player.animations.right = anim8.newAnimation(Player.walk('1-4', 1), 0.2)
  Player.animations.left  = anim8.newAnimation(Player.walk('1-4', 2), 0.2)
  Player.animations.upRight = anim8.newAnimation(Player.walk('1-4', 3), 0.2)
  Player.animations.upLeft  = anim8.newAnimation(Player.walk('1-4', 4), 0.2)
  Player.animations.downRight = anim8.newAnimation(Player.walk('1-4', 1), 0.2)
  Player.animations.downLeft  = anim8.newAnimation(Player.walk('1-4', 2), 0.2)

  -- starting position
  Player.anim = Player.animations.right
  Player.lastHorizontal = "right"

  -- collider
  Player.collider = world:newBSGRectangleCollider(x, y, 40, 56, 6)
  Player.collider:setFixedRotation(true)

  return Player
end

function Player:update(dt, mapWidth, mapHeight)
  local vx, vy = 0, 0
  local isMoving = false

  if love.keyboard.isDown('d') then
    if Player.x < (mapWidth - 32)  then
      vx = Player.speed
      Player.anim = Player.animations.right
      Player.lastHorizontal = "right"
      isMoving = true
    end
  end

  if love.keyboard.isDown('a') then
    if Player.x > 32 then
      vx = Player.speed * -1
      Player.anim = Player.animations.left
      Player.lastHorizontal = "left"
      isMoving = true
    end
  end

  if love.keyboard.isDown('w') then
    if Player.y > 32 then
      vy = Player.speed * -1
      if Player.lastHorizontal == "right" then
        Player.anim = Player.animations.upRight
      else
        Player.anim = Player.animations.upLeft
      end
      isMoving = true
    end
  end

  if love.keyboard.isDown('s') then
    if Player.y < (mapHeight - 32) then
      vy = Player.speed
      if Player.lastHorizontal == "right" then
        Player.anim = Player.animations.downRight
      else
        Player.anim = Player.animations.downLeft
      end
      isMoving = true
    end
  end

  Player.collider:setLinearVelocity(vx, vy)

  if not isMoving then
    Player.anim = Player.animations.idle
  end

  Player.x = Player.collider:getX()
  Player.y = Player.collider:getY()
  Player.anim:update(dt)
end

function Player:draw()
  local scale = 1.5
  local ox, oy = 16, 16

  if Player.anim ~= Player.animations.idle then
    Player.anim:draw(Player.walkSpriteSheet, Player.x, Player.y, 0, scale, scale, ox, oy)
  else
    if Player.lastHorizontal == "right" then
      Player.anim:draw(Player.idleSpriteSheet, Player.x, Player.y, 0, scale, scale, ox, oy)
    else
      Player.anim:draw(Player.idleSpriteSheet, Player.x, Player.y, 0, -scale, scale, ox, oy)
    end
  end
end

return Player