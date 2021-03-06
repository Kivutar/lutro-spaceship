require "collisions"

local scientist = {}
scientist.__index = scientist

function newScientist()
	local n = {}
	n.width = 12
	n.height = 24
	n.xspeed = 0
	n.yspeed = 0
	n.xaccel = 0.05
	n.yaccel = 0.05
	n.x = (SCREEN_WIDTH - n.width) / 2
	n.y = (SCREEN_HEIGHT - n.height) / 2
	n.direction = "left"
	n.stance = "stand"
	n.DO_JUMP = 0
	n.DO_SABER = 0
	n.sab = 0
	n.hit = 0
	n.hp = 3
	n.maxhp = 3
	n.batteries = 0
	n.type = "scientist"
	n.saber = nil

	n.animations = {
		stand = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_stand_left.png"),  48, 48, 1, 1),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_stand_right.png"), 48, 48, 1, 1)
		},
		hit = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_hit_left.png"),  48, 48, 1, 60),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_hit_right.png"), 48, 48, 1, 60)
		},
		fall = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_fall_left.png"),  48, 48, 1, 1),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_fall_right.png"), 48, 48, 1, 1)
		},
		jump = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_jump_left.png"),  48, 48, 1, 1),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_jump_right.png"), 48, 48, 1, 1)
		},
		run = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_run_left.png"),  48, 48, 2, 10),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_run_right.png"), 48, 48, 2, 10)
		},
		sword = {
			left  = newAnimation(lutro.graphics.newImage(
				"assets/scientist_sword_left.png"),  48, 48, 1, 30),
			right = newAnimation(lutro.graphics.newImage(
				"assets/scientist_sword_right.png"), 48, 48, 1, 30)
		},
	}

	n.anim = n.animations[n.stance][n.direction]

	return setmetatable(n, scientist)
end

function scientist:on_the_ground()
	return solid_at(self.x + 1, self.y+24, self)
		or solid_at(self.x + 11, self.y+24, self)
end



function scientist:update(dt)
	if self.hit > 0 then
		self.hit = self.hit - 1
	end

	if self.sab > 0 then
		self.sab = self.sab - 1
	else
		self.sab = 0
		for i=1, #entities do
			if entities[i] == self.saber then
				table.remove(entities, i)
			end
		end
	end

	local JOY_LEFT  = lutro.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_LEFT)
	local JOY_RIGHT = lutro.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_RIGHT)
	local JOY_Y     = lutro.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_Y)
	local JOY_B     = lutro.joystick.isDown(1, RETRO_DEVICE_ID_JOYPAD_B)

	-- gravity
	if not self:on_the_ground() then
		self.yspeed = self.yspeed + self.yaccel
		self.y = self.y + self.yspeed
	end

	-- jumping
	if JOY_B then
		self.DO_JUMP = self.DO_JUMP + 1
	else
		self.DO_JUMP = 0
	end

	-- saber
	if JOY_Y then
		self.DO_SABER = self.DO_SABER + 1
	else
		self.DO_SABER = 0
	end

	if self.DO_SABER == 1 then
		self.sab = 15
		lutro.audio.play(sfx_saber)
		self.saber = newSaber({holder = self})
		table.insert(entities, self.saber)
	end

	if self.DO_JUMP == 1 and self:on_the_ground() then
		self.y = self.y - 1
		self.yspeed = -1.5
		lutro.audio.play(sfx_jump)
	end

	if self.DO_JUMP > 0 and self.DO_JUMP < 20 and self.yspeed < -1.4 then
		self.yspeed = -1.5
	end

	-- moving
	if JOY_LEFT then
		self.xspeed = self.xspeed - self.xaccel;
		if self.xspeed < -1.5 then
			self.xspeed = -1.5
		end
		self.direction = "left";
	end

	if JOY_RIGHT then
		self.xspeed = self.xspeed + self.xaccel;
		if self.xspeed > 1.5 then
			self.xspeed = 1.5
		end
		self.direction = "right";
	end

	-- apply speed
	self.x = self.x + self.xspeed

	-- decelerating
	if not (JOY_RIGHT and self.xspeed > 0)
	and not (JOY_LEFT  and self.xspeed < 0)
	and self:on_the_ground()
	or (self.DO_SABER > 0 and self.DO_SABER < 8 and self:on_the_ground())
	then
		if self.xspeed > 0 then
			self.xspeed = self.xspeed - 0.1
			if self.xspeed < 0 then
				self.xspeed = 0
			end
		elseif self.xspeed < 0 then
			self.xspeed = self.xspeed + 0.1
			if self.xspeed > 0 then
				self.xspeed = 0
			end
		end
	end

	-- animations
	if self:on_the_ground() then
		if self.xspeed == 0 then
			self.stance = "stand"
		else
			self.stance = "run"
		end
	else
		if self.yspeed > 0 then
			self.stance = "fall"
		else
			self.stance = "jump"
		end
	end

	if self.sab > 0 then
		self.stance = "sword"
	else

	end

	if self.hit > 0 then
		self.stance = "hit"
	end

	local anim = self.animations[self.stance][self.direction]
	-- always animate from first frame 
	if anim ~= self.anim then
		anim.timer = 0
	end
	self.anim = anim;

	self.anim:update(1/60)
end

function scientist:draw()
	self.anim:draw(self.x - 10 - 8, self.y - 8-16)
end

function scientist:on_collide(e1, e2, dx, dy)
	if e2.type == "ground" then
		if math.abs(dy) < math.abs(dx) and dy ~= 0 then
			self.yspeed = 0
			self.y = self.y + dy
			--lutro.audio.play(sfx_step)
		end

		if math.abs(dx) < math.abs(dy) and dx ~= 0 then
			self.xspeed = 0
			self.x = self.x + dx
		end
	elseif e2.type == "door" then
		map = tiled_load("assets/" .. e2.properties.to)
		entities = {self}
		tiled_load_objects(map, add_entity_from_map)
		if e2.properties.x then
			self.x = tonumber(e2.properties.x)
		end
		self.y = self.y + tonumber(e2.properties.y)
	elseif e2.type == "laser" then
		lutro.audio.play(sfx_laserhit)
		screen_shake = 0.25
		self.xspeed = - self.xspeed
		self.x = self.x + dx
		if self.hit == 0 then
			self.hp = self.hp - 1
		end
		self.hit = 30
	elseif e2.type == "biglaser" and e2.stance == "on" and self.hit == 0 then
		lutro.audio.play(sfx_laserhit)
		screen_shake = 0.25
		self.hit = 30
		self.xspeed = - self.xspeed
		self.x = self.x + dx
		self.hp = self.hp - 2
	elseif e2.type == "crab" and self.hit == 0 and e2.die == 0 then
		lutro.audio.play(sfx_hit)
		screen_shake = 0.25
		self.hit = 30
		if dx > 0 then
			self.xspeed = 1.2
		else
			self.xspeed = -1.2
		end
		self.y = self.y - 1
		self.yspeed = -1
		self.hp = self.hp - 0.5
	elseif e2.type == "walker" and self.hit == 0 and e2.die == 0 then
		lutro.audio.play(sfx_hit)
		screen_shake = 0.25
		self.hit = 30
		if dx > 0 then
			self.xspeed = 1.2
		else
			self.xspeed = -1.2
		end
		self.y = self.y - 1
		self.yspeed = -1
		self.hp = self.hp - 0.5
	elseif e2.type == "ball" and self.hit == 0 and e2.die == 0 then
		lutro.audio.play(sfx_hit)
		screen_shake = 0.25
		self.hit = 30
		if dx > 0 then
			self.xspeed = 1.2
		else
			self.xspeed = -1.2
		end
		self.y = self.y - 1
		self.yspeed = -1
		self.x = self.x + dx
		self.hp = self.hp - 0.5
	elseif e2.type == "battery" then
		lutro.audio.play(sfx_pickup_battery)
		self.batteries = self.batteries + 1
		for i=1, #entities do
			if entities[i] == e2 then
				table.remove(entities, i)
			end
		end
	end
end
