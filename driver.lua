--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

--
-- Driver class - manage driver execution
--


-- Class definition
Driver = {}
Driver.__index = Driver

setmetatable(Driver, {
	__call = function(c, ...)
		return c.new(...)
	end,
})


-- private functions
local function driver_setup(self, driver)
	self.name = driver
	self.driver = entity_ai.registered_drivers[driver]
	self.properties = table.copy(self.object.script.properties)
	local driver_script = self.object.script[driver]
	if driver_script.properties then
		for k, v in pairs(driver_script.properties) do
			self.properties[k] = v
		end
	end
end


--- constructor
function Driver.new(object, driver)
	local self = setmetatable({}, Driver)
	self.object = object
	driver_setup(self, driver)
	return self
end


-- public methods
function Driver:switch(driver, factordata)
	self:stop()
	driver_setup(self, driver)
	self:start(factordata)
end

function Driver:start(factordata)
	-- sounds
	local script = self.object.script
	local sounds = script[self.name].sounds
	if sounds and sounds.start then
		local sound = script.sounds[sounds.start]
		if sound then
			local params = {max_hear_distance = sound[2].max_hear_distance,
				object = self.object.object}
			minetest.sound_play(sound[1], params)
		else
			minetest.log("error", "unknown sound '" .. sounds.start
				.. "' from " .. self.name .. " driver")
		end
	end
	--print("Calling driver start for driver " .. self.name)
	self.driver.start(self.object, factordata)
end


function Driver:stop()
	self.driver.stop(self.object)
end

function Driver:get_property(property)
	return self.properties[property]
end

function Driver:factor(name, data)
	-- valid factor for current driver?
	local script = self.object.script
	local driver = script[self.name].factors[name]
	if not driver then
		-- not valid for current driver!
		print("notice: invalid factor " .. name .. " for driver " .. self.name)
		return
	end
	self:switch(driver, {[name] = data})
end

function Driver:step(dtime)
	-- factor handling
	local script = self.object.script
	for factor, factordriver in pairs(script[self.name].factors) do
		-- do we have a test we need to run?
		local factordata = nil
		if entity_ai.registered_factors[factor] and not factordata then
			factordata = entity_ai.registered_factors[factor](self.object, dtime)
		end
		-- check results
		if factordata then
			print("factor " .. factor .. " affects " ..  self.name .. " driver changed to " .. factordriver)
			self:switch(factordriver, {[factor] = factordata})
			return
		end
	end

	-- animation handling
	local state = self.object.entity_ai_state

	if state.animttl then
		state.animttl = state.animttl - dtime
		if state.animttl <= 0 then
			state.animttl = nil
			self:animation(state.animation, state.segment + 1)
			self:factor("anim_end", true)
		end
	end

	-- sound handling
	local sounds = script[self.name].sounds
	if math.random(1, 200) == 1 and sounds and sounds.random then
		local sound = script.sounds[sounds.random]
		if sound then
			local params = {max_hear_distance = sound[2].max_hear_distance,
					object = self.object.object}
			minetest.sound_play(sound[1], params)
		else
			minetest.log("error", "unknown sound '" .. sounds.random
				.. "' from " .. self.name .. " driver")
		end
	end

	-- execute driver specific step code
	self.driver.step(self.object, dtime)
end

function Driver:animation(animation, segment)
	local state = self.object.entity_ai_state
	state.animation = animation
	--print(self.name .. ": driver = " .. self.driver.name .. ", animation = " ..
	--		animation .. ", segment = " .. (segment or 0))
	if not segment then
		local animations = self.object.script.animations[animation]
		if not animations then
			print(self.object.name .. ": no animations for " .. animation ..
					", segment = " .. (segment or 0))
			return
		end
		for i = 1, 3 do
			local animdef = animations[i]
			if animdef then
				state.segment = i
				-- calculate when to advance to next segment
				if not animdef.frame_loop then
					local animlen = (animdef[1].y - animdef[1].x) / animdef.frame_speed
					state.animttl = animlen
				else
					state.animttl = nil
				end
				self.object.object:set_animation(animdef[1], animdef.frame_speed, animdef.frame_loop)
				return
			end
		end
	else
		local animdef = self.object.script.animations[animation][segment]
		if animdef then
			state.segment = segment
			self.object.object:set_animation(animdef[1], animdef.frame_speed, animdef.frame_loop)
			return
		end
	end
	print("animation_select: can't find animation " .. state.animation .. " for driver " ..
			state.driver .. " for entity " .. self.object.name)
end
