function love.load()
    math.randomseed(os.time())

    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.jpg')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.zombie = love.graphics.newImage('sprites/zombie.png')

    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = 180

    myFont = love.graphics.newFont(30)

    zombies = {}
    bullets = {}

    gameState = 1 -- Main menu
    --[[
        Main Menu: gameState = 1
        Game Start: gameState = 2
        Injured State: gameState = 3
    ]]

    score = 0
    lives = 2
    maxTime = 2
    timer = maxTime
    -- tempRotation = 0
end

function love.update(dt)

    -- To move the player
    if gameState ~= 1 then
        if love.keyboard.isDown('d') and player.x < love.graphics.getWidth() - 23 then
            player.x = player.x + player.speed*dt
        end
        if love.keyboard.isDown('a') and player.x > 24 then
            player.x = player.x - player.speed*dt
        end
        if love.keyboard.isDown('w') and player.y > 24 then
            player.y = player.y - player.speed*dt
        end
        if love.keyboard.isDown('s') and player.y < love.graphics.getHeight() - 23 then
            player.y = player.y + player.speed*dt
        end
    end

    if gameState == 2 then
        player.speed = 180
    elseif gameState == 3 then
        player.speed = 360
    end

    -- To move the zombies
    for i, z in ipairs(zombies) do
        z.x = z.x + math.cos(zombiePlayerAngle(z)) * z.speed * dt
        z.y = z.y + math.sin(zombiePlayerAngle(z)) * z.speed * dt

        -- To check if zombie comes close ennough to hit the player / Player gets caught for 1st time
        if distanceBetween(z.x, z.y, player.x, player.y) < 30 and gameState == 2 then -- Goes to Injured State
            for i, z in ipairs(zombies) do
                -- zombies[i] = nil
                gameState = 3
                player.x = love.graphics.getWidth() / 2
                player.y = love.graphics.getHeight() / 2
                lives = 1
            end
        end
        -- To check if zombie comes close ennough to hit the player / Player gets caught for 2nd time
        if distanceBetween(z.x, z.y, player.x, player.y) < 30 and gameState == 3 then -- Goes to Start Menu from Injured State
            for i, z in ipairs(zombies) do
                zombies[i] = nil
                gameState = 1
                player.x = love.graphics.getWidth() / 2
                player.y = love.graphics.getHeight() / 2
                lives = 2
            end
        end
    end

    -- To move the bullets
    for i, b in ipairs(bullets) do
        b.x = b.x + math.cos(b.direction) * b.speed * dt
        b.y = b.y + math.sin(b.direction) * b.speed * dt
    end

    -- To remove the bullets which go off-screen
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    -- Nested loop for collision of zombies and bullets
    for i,z in ipairs(zombies) do
        for j, b in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
            end
        end
    end

    -- Collision of zombies and player
    if gameState == 3 then
        for i,z in ipairs(zombies) do
            if distanceBetween(z.x, z.y, player.x, player.y) < 20 then
                z.dead = true
            end
        end
    end


    -- To remove zombies after collision with bullets
    for i = #zombies, 1, -1 do
        local z = zombies[i]
        if z.dead == true then
            table.remove(zombies, i)
        end
    end

    -- To remove bullets after collision with zombies
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.dead == true then
            table.remove(bullets, i)
        end
    end

    -- To set timer after each zombie spawn
    if gameState == 2 or gameState == 3 then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            maxTime = maxTime * 0.95
            timer = maxTime
        end
    end

    -- tempRotation = tempRotation + 0.01
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == 1 then
        math.randomseed(os.time())
        love.graphics.setFont(myFont)
        love.graphics.printf('Click anywhere to begin!!!', 0, 50, love.graphics.getWidth(), 'center')
    end

    love.graphics.setFont(love.graphics.newFont(35))
    love.graphics.printf('Score: ' .. score, 0, love.graphics.getHeight()-100, love.graphics.getWidth(), 'center')
    
    love.graphics.setFont(love.graphics.newFont(25))
    love.graphics.printf('Live: ' .. lives, 0, love.graphics.getHeight()-50, love.graphics.getWidth(), 'center')


    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), 50/sprites.player:getWidth(), 50/sprites.player:getHeight(), sprites.player:getWidth()/2, sprites.player:getHeight()/2)

    -- Draw zombies
    for i, z in ipairs(zombies) do 
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), 50/sprites.zombie:getWidth(), 50/sprites.zombie:getHeight(), sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    -- Draw bullets
    for i, b in ipairs(bullets) do 
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 30/sprites.bullet:getWidth(), 30/sprites.bullet:getHeight(), sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
    end
end

-- function love.keypressed(key)
--     if key == 'space' then
--         spawnZombie()
--     end
-- end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 3 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

function playerMouseAngle()
    return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(enemy)
    return math.atan2(player.y - enemy.y, player.x - enemy.x)
end

function spawnZombie()
    local zombie = {}
    zombie.x = 0
    zombie.y = 0
    zombie.speed = 100
    zombie.dead = false

    local side = math.random(1, 4)
    if side == 1 then     -- Left side of screen
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then -- Right side of screen
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then -- Top side of screen
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -30
    else                  -- Bottom side of screen
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 30
    end

    table.insert(zombies, zombie)
end

function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.dead = false
    bullet.direction = playerMouseAngle()
    table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end