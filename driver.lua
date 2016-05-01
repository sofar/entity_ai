
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

local function driver_setup(self, driver)
	self.name = driver
	self.driver = drivers[driver]
	self.properties = table.copy(self.object.script.properties)
	local driver_script = self.object.script[driver]
	if driver_script.properties then
		for k, v in pairs(driver_script.properties) do
			self.properties[k] = v
		end
	end
end

-- constructor
function Driver.new(object, driver)
	local self = setmetatable({}, Driver)
	self.object = object
	driver_setup(self, driver)
	return self
end

function Driver:switch(driver)
	driver_setup(self, driver)
	self.driver.start(self.object)
end

function Driver:start()
	self.driver.start(self.object)
end

function Driver:step(dtime)
	self.driver.step(self.object, dtime)
end

function Driver:stop()
	self.driver.stop(self.object)
end

function Driver:get_property(property)
	return self.properties[property]
end
