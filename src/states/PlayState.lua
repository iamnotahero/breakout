--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level
    self.balls = params.balls
    self.poweruplist = params.poweruplist
    self.hardballcounter = 0
    self.keys = params.keys
    self.recoverPoints = params.recoverPoints
    --debug
    self.testpowerupnumber = 0;
    -- give ball random starting velocity
    for k, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
end

function PlayState:update(dt)
    if self.hardballcounter > 0 then
        self.hardballcounter = self.hardballcounter - dt
    end
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    


    for k, ball in pairs(self.balls) do 
            ball:update(dt)
            if ball:collides(self.paddle) then
                -- raise ball above paddle in case it goes below it, then reverse dy
                ball.y = self.paddle.y - 8
                ball.dy = -ball.dy

                --
                -- tweak angle of bounce based on where it hits the paddle
                --

                -- if we hit the paddle on its left side while moving left...
                if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                    ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
                
                -- else if we hit the paddle on its right side while moving right...
                elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                    ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
                end

                gSounds['paddle-hit']:play()
            end
        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                if brick.locked and self.keys > 0 then
                    self.keys = self.keys - 1
                    brick.inPlay = false
                    --brick.locked = false
                    self.score = self.score + (brick.tier * 1000 + brick.color * 25)
                elseif not brick.locked then
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                    --adds powerup to table
                    if brick.haspowerup then
                        table.insert(self.poweruplist, Powerup(brick.x,brick.y,brick.powerupindex))
                        -- chance of still having a powerup in the brick
                        -- math.random(1, 2) == 1 and true or false
                        gSounds['victory']:play()
                        brick.haspowerup = false
                    end
                    -- trigger the brick's hit function, which removes it from play
                    --ok repeat this code to simulate stronger ball
                    brick:hit()
                end
                -- if we have enough points, recover a point of health                
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)
                    --paddle size
                    self.paddle.size = math.min(self.paddle.size + 1, 4)
                    self.paddle.width = math.min(self.paddle.width + 32, 128)
                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        balls = self.balls,
                        keys = self.keys,
                        poweruplist = self.poweruplist,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                ---[[
                if self.hardballcounter == 0 then
                    if ball.x + 2 < brick.x and ball.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif ball.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y + 16
                    end
                end
                --]]
                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball goes below bounds, revert to serve state and decrease health
        -- now it will only go to serve state if balls in the table is zero 
        if ball.y >= VIRTUAL_HEIGHT then
            --self.health = self.health - 1
            --remove the ball beyond the screen 
            table.remove(self.balls, k)
            gSounds['hurt']:play()
            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                if #self.balls == 0 then
                    self.health = self.health - 1
                    --paddle size reduction
                    self.paddle.size = math.max(1 ,self.paddle.size - 1)
                    self.paddle.width = math.max(self.paddle.width - 32, 32)
                    gSounds['hurt']:play()
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        keys = self.keys,
                        poweruplist = self.poweruplist,
                        recoverPoints = self.recoverPoints
                    })
                end
            end
        end
    end
    for k, powerup in pairs(self.poweruplist) do
        if powerup:collides(self.paddle) then
            --max of 2 balls
            if not powerup.consumed then
                if powerup.powerup == 9 then
                    if #self.balls < 2 then
                        self.ball = Ball(math.random(7))
                        self.ball.dx = math.random(-200, 200)
                        self.ball.dy = math.random(-50, -60)
                        self.ball.x = self.paddle.x + (self.paddle.width / 2) - 4
                        self.ball.y = self.paddle.y - 8
                        table.insert(self.balls, self.ball)
                    else
                        --make a if statement for the what powerup is it? and choose a correspoding point
                        self.score = self.score + 100 --+1 ball quiv
                    end
                elseif powerup.powerup == 8 then
                    if self.hardballcounter < 60 then
                        self.hardballcounter = self.hardballcounter + 20
                    else
                        self.score = self.score + 100
                    end
                elseif powerup.powerup == 10 then
                    if self.keys < 5 then
                        self.keys = self.keys + 1 
                    else
                        self.score = self.score + 100
                    end
                elseif powerup.powerup == 3 then
                    if self.health < 3 then
                        self.health = math.min(3, self.health + 1)
                    else
                        self.score = self.score + 100 
                    end
                elseif powerup.powerup == 4 then
                    if self.health < 3  then
                        self.health = 3
                    else
                        self.score = self.score + 100
                    end
                elseif powerup.powerup == 5 then
                    if self.paddle.size < 4 then
                        self.paddle.size = math.min(self.paddle.size + 1, 4)
                        self.paddle.width = math.min(self.paddle.width + 32, 128)
                    else
                        self.score = self.score + 100
                    end
                else -- placeholder score adding only for other powerups
                    self.score = self.score + 500
                end
                --debug powerupindex
                self.testpowerupnumber = powerup.powerup 
                gSounds['recover']:play()
                powerup.consumed = true
            end
        end
        powerup:update(dt)
    end
    --clean the powerups if consumed remove it or if below the screen
    for k, powerup in pairs(self.poweruplist) do
        if powerup.consumed or powerup.y >= VIRTUAL_HEIGHT then
            table.remove(self.poweruplist, k)
        end
    end
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()

    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end
    for k, powerup in pairs(self.poweruplist) do
        powerup:render()
    end
    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:renderParticles()
    end

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    if self.hardballcounter > 0 then
        renderCounter(self.hardballcounter)
    end
    if self.keys > 0 then
        renderKeys(self.keys)
    end
    -- debug text
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("Current Powerup: " .. tostring(self.testpowerupnumber), 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    love.graphics.printf("Current RecoverPoints: " .. tostring(self.recoverPoints), 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay and not brick.locked then
            return false
        --elseif brick.powerup add for powerupcheck if its a locked brick
        end 
    end

    return true
end
