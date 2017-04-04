--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

--[[
General API design ideas:
	-- spawning a new entity
	obj = Entity({name = "sheep", state = {}})

	-- drivers
	self.driver:switch(self, driver)
	self.driver:step()
	self.driver:start()
	self.driver:stop()

- entity programming should use object:method() design.
- creating an entity should use simple methods as follows:

minetest.register_entity("sofar:sheep", {
	...,
	on_activate = entity_ai:on_activate,
	on_step = entity_ai:on_step,
	on_punch = entity_ai:on_punch,
	on_rightclick = entity_ai:on_rightclick,
	get_staticdata = entity_ai:get_staticdata,
})

entity activity is a structure organized as a graph:

events may cause:
  -> [flee]
  -> [defend]
  -> [dead]
  -> [return]
initial states
[roam]
[guard]
[hunt]

etc..

Each state may have several substates

[idle] -> { idle.1, idle.2, idle.3 }

Each state has a "driver". This is the algorithm that makes the entity do
stuff. "do stuff" can mean "stand still", "move to a pos", "attack something" or
a combination of any of these, including "use a node", "place a node" etc.

-- returns: nil
obj:driver_eat_grass = function(self) end
obj:driver_idle = function(self) end
obj:driver_find_food = function(self) end
obj:driver_defend = ...
obj:driver_death = ...
obj:driver_mate = ...

Each state has several "factors". These are conditions that may be met at any
point in time. Factors can be "A node is nearby that can be grazed on", "close to water",
"fertile", "was hit recently", "took damage recently", "a hostile faction is nearby"

-- returns: bool
obj:factor_is_fertile = function(self) end
obj:factor_is_near_foodnode = function(self) end
obj:factor_was_hit = function(self) end
obj:factor_is_near_mate = ...

--]]

--
-- misc functions
--


function check_trapped_and_escape(self)
	local pos = vector.round(self.object:getpos())
	local node = minetest.get_node(pos)
	if minetest.registered_nodes[node.name].walkable then
		-- stuck, can we go up?
		local p2 = {x = pos.x, y = pos.y + 1, z = pos.z}
		local n2 = minetest.get_node(p2)
		if not minetest.registered_nodes[n2.name].walkable then
			--print("monster trapped, escaped upward!")
			self.object:setpos({x = pos.x, y = p2.y + 0.5, z = pos.z})
		else
			print("monster trapped but can't escape upward!", minetest.pos_to_string(pos))
		end
	end
end

--
-- globals
--
entity_ai = {}

entity_ai.registered_drivers = {}
function entity_ai.register_driver(name, def)
	assert(not entity_ai.registered_drivers[name])
	entity_ai.registered_drivers[name] = def
end

entity_ai.registered_factors = {}
function entity_ai.register_factor(name, func)
	assert(not entity_ai.registered_factors[name])
	entity_ai.registered_factors[name] = func
end

entity_ai.registered_finders = {}
function entity_ai.register_finder(name, func)
	assert(not entity_ai.registered_finders[name])
	entity_ai.registered_finders[name] = func
end


--
-- includes
--
local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. "/path.lua")
dofile(modpath .. "/driver.lua")

--
-- standard entity methods
--

local function entity_ai_on_activate(self, staticdata)
	self.entity_ai_state = {}

	local driver

	if staticdata ~= "" then
		-- load staticdata
		self.entity_ai_state = minetest.deserialize(staticdata)
		if not self.entity_ai_state then
			print("entity_ai entity without saved state, removing")
			self.object:remove()
			return
		end

		local state = self.entity_ai_state

		-- driver class, has to come before path
		if state.driver_save then
			driver = state.driver_save
			state.driver_save = nil
		else
			driver = self.script.driver
		end
		self.driver = Driver(self, driver)
		state.driver_save = nil

		-- path class
		if self.script[driver].finders then
			if state.path_save then
				self.path = Path(self, state.path_save.target)
				self.path:set_config(state.path_save.config)
				self.path:find()
				state.path_save = {}
			end
		end

		--print("loaded: " .. self.name .. ", driver=" .. driver )
	else
		-- set initial monster driver
		driver = self.script.driver
		self.driver = Driver(self, driver)
		--print("activate: " .. self.name .. ", driver=" .. driver)
	end

	-- properties
	self.object:set_hp(self.driver:get_property("hp_max"))

	-- gravity
	self.object:setacceleration({x = 0, y = -9.81, z = 0})

	-- init driver
	self.driver:start()
end

local function entity_ai_on_step(self, dtime)
	self.driver:step(dtime)
end

local function entity_ai_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	-- sounds?
	minetest.sound_play("on_punch", {object = self.object})

	-- hp dmg
	if self.object:get_hp() == 0 then
		--FIXME
		print("death")
		self.driver:switch("death")
		return
	end

	-- factor
	self.driver:factor("got_hit", {
		puncher:get_player_name(),
		time_from_last_punch,
		tool_capabilities,
		dir,
		self.object:getpos()
	})
end

local function entity_ai_on_rightclick(self, clicker)
end

local function entity_ai_get_staticdata(self)
	--print("saved: " .. self.name)
	local state = self.entity_ai_state
	state.driver_save = self.driver.name
	if self.path and self.path.save then
		state.path_save = self.path:save()
	end
	return minetest.serialize(state)
end


function entity_ai.register_entity(name, def)
	-- FIXME add some sort of entity registration table
	-- FIXME handle spawning and reloading?
	def.name = name
	def.physical = def.physical or true
	def.visual = def.visual or "mesh"
	def.makes_footstep_sound = def.makes_footstep_sound or true
	def.stepheight = def.stepheight or 0.55
	def.collisionbox = def.collisionbox or {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2}
	-- entity_ai callbacks
	def.on_activate = entity_ai_on_activate
	def.on_step = entity_ai_on_step
	def.on_punch = entity_ai_on_punch
	def.on_rightclick = entity_ai_on_rightclick
	def.get_staticdata = entity_ai_get_staticdata

	minetest.register_entity(name, def)
end

-- load builtin registrations
dofile(modpath .. "/finders.lua")
dofile(modpath .. "/factors.lua")
dofile(modpath .. "/drivers.lua")

-- load entities
dofile(modpath .. "/sheep.lua")
dofile(modpath .. "/stone_giant.lua")


-- misc.
--minetest.register_on_joinplayer(function(player)
--	minetest.add_entity({x=31.0,y=2.0,z=96.0}, "entity_ai:stone_giant")
--end)
