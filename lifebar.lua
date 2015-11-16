local lifebar = {}
lifebar.__index = lifebar

function newLifeBar()
	local n = {}
	n.heart_full  = lutro.graphics.newImage("assets/heart_full.png")
	n.heart_half  = lutro.graphics.newImage("assets/heart_half.png")
	n.heart_empty = lutro.graphics.newImage("assets/heart_empty.png")

	return setmetatable(n, lifebar)
end

function lifebar:update(dt)
end

function lifebar:draw()
	local hp = scientist.hp
	for i=1,scientist.maxhp do
		local heart
		if hp >= 1 then
			heart = self.heart_full
		elseif hp == 0.5 then
			heart = self.heart_half
		else
			heart = self.heart_empty
		end
		lutro.graphics.draw(heart, 8 + i * 8, 8)
		hp = hp - 1
	end

	lutro.graphics.printf("bx" .. scientist.batteries , -8, 8, SCREEN_WIDTH, "right")
end

function lifebar:on_collide(e1, e2, dx, dy)
end
