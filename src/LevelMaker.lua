--[[
    GD50
    Breakout Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Creates randomized levels for our Breakout game. Returns a table of
    bricks that the game can render, based on the current level we're at
    in the game.
]]

-- global patterns (used to make the entire map a certain shape)
NONE = 1
SINGLE_PYRAMID = 2
MULTI_PYRAMID = 3

-- per-row patterns
SOLID = 1           -- all colors the same in this row
ALTERNATE = 2       -- alternate colors
SKIP = 3            -- skip every other block
NONE = 4            -- no blocks this row
LevelMaker = Class{}

--[[
    Creates a table of Bricks to be returned to the main game, with different
    possible ways of randomizing rows and columns of bricks. Calculates the
    brick colors and tiers to choose based on the level passed in.
]]
function LevelMaker.createMap(level)
    local bricks = {}
    local poweruptiers = {
        low = {7,8},
        mid = {3,9,5,6},
        high = {10,4}
    }
    -- randomly choose the number of rows
    local numRows = math.random(1, 5)
    local totalLocked = 0
    local totalKeys = 0
    -- randomly choose the number of columns, ensuring odd
    local numCols = math.random(7, 13)
    numCols = numCols % 2 == 0 and (numCols + 1) or numCols

    -- highest possible spawned brick color in this level; ensure we
    -- don't go above 3
    local highestTier = math.min(3, math.floor(level / 5))

    -- highest color of the highest tier, no higher than 5
    local highestColor = math.min(5, level % 5 + 3)

    -- lay out bricks such that they touch each other and fill the space
    for y = 1, numRows do
        -- whether we want to enable skipping for this row
        local skipPattern = math.random(1, 2) == 1 and true or false

        -- whether we want to enable alternating colors for this row
        local alternatePattern = math.random(1, 2) == 1 and true or false
        -- choose two colors to alternate between
        local alternateColor1 = math.random(1, highestColor)
        local alternateColor2 = math.random(1, highestColor)
        local alternateTier1 = math.random(0, highestTier)
        local alternateTier2 = math.random(0, highestTier)
        
        -- used only when we want to skip a block, for skip pattern
        local skipFlag = math.random(2) == 1 and true or false

        -- used only when we want to alternate a block, for alternate pattern
        local alternateFlag = math.random(2) == 1 and true or false

        -- solid color we'll use if we're not skipping or alternating
        local solidColor = math.random(1, highestColor)
        local solidTier = math.random(0, highestTier)

        for x = 1, numCols do
            -- if skipping is turned on and we're on a skip iteration...
            if skipPattern and skipFlag then
                -- turn skipping off for the next iteration
                skipFlag = not skipFlag

                -- Lua doesn't have a continue statement, so this is the workaround
                goto continue
            else
                -- flip the flag to true on an iteration we don't use it
                skipFlag = not skipFlag
            end

            b = Brick(
                -- x-coordinate
                (x-1)                   -- decrement x by 1 because tables are 1-indexed, coords are 0
                * 32                    -- multiply by 32, the brick width
                + 8                     -- the screen should have 8 pixels of padding; we can fit 13 cols + 16 pixels total
                + (13 - numCols) * 16,  -- left-side padding for when there are fewer than 13 columns
                
                -- y-coordinate
                y * 16                  -- just use y * 16, since we need top padding anyway
            )
            -- if we're alternating, figure out which color/tier we're on
            if alternatePattern and alternateFlag then
                b.color = alternateColor1
                b.tier = alternateTier1
                alternateFlag = not alternateFlag
            else
                b.color = alternateColor2
                b.tier = alternateTier2
                alternateFlag = not alternateFlag
            end

            -- if not alternating and we made it here, use the solid color/tier
            if not alternatePattern then
                b.color = solidColor
                b.tier = solidTier
            end 
            --if b.color == highestColor - math.random(0,1) and b.tier == highestTier - math.random(0,1) then
            --powerup chance 30% chance
            b.haspowerup = math.random(1, 100) < 60 and true or false
            b.locked = math.random(1, 100) < 15 and true or false
            if b.locked then
                b.tier = 3
                b.color = 6
                totalLocked = totalLocked + 1
            elseif b.haspowerup then
                if b.color < 2 then
                    --terary function that checks first if conditon is true then return the first value using this for randonmization of powerup
                    b.powerupindex = math.random(1,100) < 3 and poweruptiers.high[math.random(1,2)] or math.random(1,100) < 10 and poweruptiers.mid[math.random(1,4)] or poweruptiers.low[math.random(1,2)]
                elseif b.color <= 4 then
                    --b.powerupindex = poweruptiers.mid[math.random(1,4)]
                    b.powerupindex = math.random(1,100) < 5 and poweruptiers.high[math.random(1,2)] or math.random(1,100) < 60 and poweruptiers.mid[math.random(1,4)] or poweruptiers.low[math.random(1,2)]
                elseif b.color > 4 then
                    --b.powerupindex = poweruptiers.high[math.random(1,2)]
                    b.powerupindex = math.random(1,100) < 20 and poweruptiers.high[math.random(1,2)] or math.random(1,100) < 80 and poweruptiers.mid[math.random(1,4)] or poweruptiers.low[math.random(1,2)]
                end
            --[[else
                if x == math.random(1,numCols) and not haspicked then
                    b.locked = true
                    b.tier = 3
                    b.color = 5
                    haspicked = true
                end
                --]]
            end

            table.insert(bricks, b)
            local willhavekey = math.random(1, 100) < 15 and true or false
            for k, brick in pairs(bricks) do
                if not brick.locked then
                    if totalKeys < totalLocked then
                        if willhavekey then
                            brick.haspowerup = true
                            brick.powerupindex = 10
                            totalKeys = totalKeys + 1
                        else
                            willhavekey = math.random(1, 100) < 15 and true or false
                        end
                    end
                end       
            end
            -- Lua's version of the 'continue' statement
            ::continue::
        end
    end 

    -- in the event we didn't generate any bricks, try again
    if #bricks == 0 then
        return self.createMap(level)
    else
        return bricks
    end
end