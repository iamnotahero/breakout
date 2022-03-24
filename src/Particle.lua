Particle = Class{}

-- small display circle class
local PARTICLE_SIZE = 5
local PARTICLE_SIZE_MIN = 1

function Particle:new(x, y)
	local p = {}
	self.__index = self
	p.x = x
	p.y = y
	p.size = PARTICLE_SIZE
	p.alpha = 1
	return setmetatable(p, Particle)
end

function Particle:update()
	self.size = self.size - 0.2
	self.alpha = self.alpha - 0.05
end

function Particle:draw()
	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.circle('fill', self.x, self.y, self.size)
end

-- trailing particle effect on mouse cursor
