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

local function driver_start(self)
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
	self.driver.start(self.object)
end


local function driver_stop(self)
	--print("Calling driver stop for driver " .. self.name)
	self.driver.stop(self.object)
end


--- constructor
function Driver.new(object, driver)
	local self = setmetatable({}, Driver)
	self.object = object
	driver_setup(self, driver)
	return self
end


-- public functions
function Driver:switch(driver)
	driver_stop(self)
	driver_setup(self, driver)
	driver_start(self)
end

function Driver:start()
	driver_start(self)
end

function Driver:step(dtime)
	local script = self.object.script
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
	self.driver.step(self.object, dtime)
end

function Driver:stop()
	driver_stop(self)
end

function Driver:get_property(property)
	return self.properties[property]
end
