--[[
    GD50
    Breakout Remake

    -- Ball Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a ball which will bounce back and forth between the sides
    of the world space, the player's paddle, and the bricks laid out above
    the paddle. The ball can have a skin, which is chosen at random, just
    for visual variety.
]]

Powerup = Class{}

function Powerup:init(x,y,powerup)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.consumed = false
    --speed of the powerup downward
    self.dy = 50
    self.dx = 0
    self.x = x
    self.y = y
    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this
    self.powerup = powerup
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]
function Powerup:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dx = 0
    self.dy = 0
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt  
end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerup'][self.powerup],
        self.x, self.y)
end