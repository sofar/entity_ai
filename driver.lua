
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

-- constructor
function Driver.new(object, driver)
	local self = setmetatable({}, Driver)
	self.name = driver
	self.driver = drivers[driver]
	self.object = object
	return self
end

function Driver:switch(driver)
	self.name = driver
	self.driver = drivers[driver]
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

