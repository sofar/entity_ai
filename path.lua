--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

--
-- Path class - manage and execute an entity path
--


-- Class definition
Path = {}
Path.__index = Path

setmetatable(Path, {
	__call = function(c, ...)
		return c.new(...)
	end,
})

-- constructor
function Path.new(obj)
	local self = setmetatable({}, Path)
	self.object = obj.object
	self.driver = obj.object:get_luaentity().driver
	self.origin = self.object:getpos()
	self.config = {
		distance = 30,
		jump = 1.0,
		fall = 3.0,
		algorithm = "Dijkstra",
	}
	self.path = {}
	return self
end

-- to help serialization
function Path:save()
	return {
		target = self.target,
		config = self.config
	}
end

function Path:find(finder)
	-- select a finder
	if not finder then
		local finders = self.object:get_luaentity().script[self.driver.name].finders
		if not finders then
			print("No finder for driver: " .. self.driver.name)
			return false
		end
		for _, v in ipairs(finders) do
			-- use the finder
			self.target = entity_ai.registered_finders[v](self.object:get_luaentity())
			if self.target then
				break
			end
		end
	else
		self.target = entity_ai.registered_finders[finder](self.object:get_luaentity())
	end
	if not self.target then
		return false
	end

	-- pathing will fail if we're on a ledge. We can fix this by
	-- pathing from the node below instead
	local pos = vector.round(self.origin)
	local onpos = {x = pos.x, y = pos.y - 1, z = pos.z}
	local on = minetest.get_node(onpos)

	if not minetest.registered_nodes[on.name].walkable then
		pos.y = onpos.y
	end

	local config = self.config
	self.path = minetest.find_path(pos, vector.round(self.target), config.distance, config.jump,
			config.fall, config.algorithm)
--[[
	if self.path ~= nil then
		for k, v in pairs(self.path) do
			minetest.add_particle({
				pos = v,
				velocity = vector.new(),
				acceleration = vector.new(),
				expirationtime = 3,
				size = 3,
				collisiondetection = false,
				vertical = false,
				texture = "wool_white.png",
				playername = nil
			})
		end
	end
--]]

	return self.path ~= nil
end

function Path:step(dtime)
	local curspd = self.object:getvelocity()
	local pos = self.object:getpos()
	-- if jumping, let jump finish before making more adjustments
	if curspd.y >= 0 and curspd.y <= 2 then
		local i, v = next(self.path, nil)
		if not i then
			return false
		end
		if vector.distance(pos, v) < 0.3 then
			-- remove one
			--FIXME shouldn't return here
			local _, v2 = next(self.path, i)
			if not v2 then
				return false
			end
		end
		-- prune path more?
		local ii, vv = next(self.path, i)
		local _, vvv = next(self.path, ii)
		if vv and vvv and vvv.y == v.y and vector.distance(vv,v) < 2 then
			-- prune one
			self.path[ii] = nil
		end
		-- done pruning
--[[
		minetest.add_particle({
			pos = {x = v.x, y = v.y + 0.2, z = v.z},
			velocity = vector.new(),
			acceleration = vector.new(),
			expirationtime = 1,
			size = 2,
			collisiondetection = false,
			vertical = false,
			texture = "wool_yellow.png",
			playername = nil
		})
--]]
		local vo = {x = v.x, y = v.y - 0.5, z = v.z}
		local vec = vector.subtract(vo, pos)
		local len = vector.length(vec)
		local vdif = vec.y
		vec.y = 0
		local dir = vector.normalize(vec)
		local spd = vector.multiply(dir, self.driver:get_property("speed"))
		-- don't jump from too far away
		if vdif > 0.1 and len < 1.5 then
			-- jump
			spd = {x = spd.x/4, y = 5, z = spd.z/4}
			self.object:setvelocity(spd)
		elseif vdif < 0 and len <= 1.1 then
			-- drop one path node just to be sure
			self.path[i] = nil
			-- falling down, just let if fall
		else
			spd.y = self.object:getvelocity().y
			-- don't change yaw when jumping
			self.object:setyaw(minetest.dir_to_yaw(spd))
			self.object:setvelocity(spd)
		end
	end

	return true
end

function Path:distance()
	if not self.path then
		return 0
	end
	if not self.target then
		return 0
	end

	return vector.distance(self.object:getpos(), self.target)
end

function Path:length()
	if not self.path then
		return 0
	end

	return #self.path
end

function Path:get_config()
	return self.config
end

function Path:set_config(conf)
	self.config = conf
end

