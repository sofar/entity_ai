
--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

entity_ai.register_driver("roam", {
	start = function(self)
		-- start with idle animation unless we get a path
		self.driver:animation("idle")
		local state = self.entity_ai_state
		state.roam_ttl = math.random(3, 9)

		self.path = Path(self)
		if not self.path:find() then
			--print("Unable to calculate path")
			self.driver:switch("idle")
			return
		end

		-- done, roaming mode good!
		self.driver:animation("move")
	end,
	step = function(self, dtime)
		-- handle movement stuff
		local state = self.entity_ai_state
		if state.roam_ttl and state.roam_ttl <= 0 then
			self.driver:switch("idle")
			return
		end
		state.roam_ttl = state.roam_ttl - dtime

		-- do path movement
		if not self.path or self.path:distance() < 0.7 or
				not self.path:step(dtime) then
			self.driver:switch("idle")
			return
		end
	end,
	stop = function(self)
		local state = self.entity_ai_state
		state.roam_ttl = nil
	end,
})

entity_ai.register_driver("idle", {
	start = function(self)
		self.driver:animation("idle")
		self.object:setvelocity(vector.new())
		local state = self.entity_ai_state
		state.idle_ttl = math.random(2, 20)
		-- sanity checks
		check_trapped_and_escape(self)
	end,
	step = function(self, dtime)
		local state = self.entity_ai_state
		state.idle_ttl = state.idle_ttl - dtime
		if state.idle_ttl <= 0 then
			self.driver:switch("roam")
			return
		end
	end,
	stop = function(self)
		local state = self.entity_ai_state
		state.idle_ttl = nil
	end,
})

entity_ai.register_driver("startle", {
	start = function(self, factordata)
		-- startle animation
		self.driver:animation("startle")
		self.object:setvelocity(vector.new())
		-- collect info we want to use in this driver
		local state = self.entity_ai_state
		if factordata and factordata["got_hit"] then
			state.attacker = factordata["got_hit"][1]
			state.attacked_at = factordata["got_hit"][5]
		end
	end,
	step = function(self, dtime)
	end,
	stop = function(self)
		-- play out remaining animations
	end,
})

entity_ai.register_driver("eat", {
	start = function(self, factordata)
		self.driver:animation("eat")
		self.object:setvelocity(vector.new())
		-- collect info we want to use in this driver
		local state = self.entity_ai_state
		state.eat_ttl = math.random(30, 60)
		if factordata and factordata.near_foodnode then
			state.food = factordata.near_foodnode
		end
	end,
	step = function(self, dtime)
		local state = self.entity_ai_state
		if state.eat_ttl > 0 then
			state.eat_ttl = state.eat_ttl - dtime
			return
		end
		state.ate_enough = math.random(200, 300)
		self.driver:switch("eat_end")
	end,
	stop = function(self)
		local state = self.entity_ai_state
		state.eat_ttl = nil
		-- increase HP
		local hp = self.object:get_hp()
		if hp < self.driver:get_property("hp_max") then
			self.object:set_hp(hp + 1)
		end

		-- eat foodnode
		local food = state.food
		if not food then
			return
		end

		local node = minetest.get_node(food)
		minetest.sound_play(minetest.registered_nodes[node.name].sounds.dug, {pos = food, max_hear_distance = 18})
		if node.name == "default:dirt_with_grass" or node.name == "default:dirt_with_dry_grass" then
			minetest.set_node(food, {name = "default:dirt"})
		--elseif node.name == "default:grass_1" or node.name == "default:dry_grass_1" then
		--	minetest.remove_node(food)
		elseif node.name == "default:grass_2" then
			minetest.set_node(food, {name = "default:grass_1"})
		elseif node.name == "default:grass_3" then
			minetest.set_node(food, {name = "default:grass_2"})
		elseif node.name == "default:grass_4" then
			minetest.set_node(food, {name = "default:grass_3"})
		elseif node.name == "default:grass_5" then
			minetest.set_node(food, {name = "default:grass_4"})
		elseif node.name == "default:dry_grass_2" then
			minetest.set_node(food, {name = "default:dry_grass_1"})
		elseif node.name == "default:dry_grass_3" then
			minetest.set_node(food, {name = "default:dry_grass_2"})
		elseif node.name == "default:dry_grass_4" then
			minetest.set_node(food, {name = "default:dry_grass_3"})
		elseif node.name == "default:dry_grass_5" then
			minetest.set_node(food, {name = "default:dry_grass_4"})
		end

		state.food = nil
	end,
})

entity_ai.register_driver("eat_end", {
	start = function(self)
		self.driver:animation("eat")
		self.object:setvelocity(vector.new())
	end,
	step = function(self, dtime)
	end,
	stop = function(self)
	end,
})


entity_ai.register_driver("flee", {
	start = function(self)
		self.driver:animation("move")
		local state = self.entity_ai_state
		state.flee_start = minetest.get_us_time()
	end,
	step = function(self, dtime)
		-- check timer ourselves
		local state = self.entity_ai_state
		if (minetest.get_us_time() - state.flee_start) > (15 * 1000000) then
			state.flee_start = nil
			self.driver:switch("roam")
			return
		end

		-- are we fleeing yet?
		if self.path and self.path.distance then
			-- stop fleeing if we're at a safe distance
			-- execute flee path
			if self.path:distance() < 2.0 then
				-- get a new flee path
				self.path = {}
			else
				-- follow path
				if not self.path:step() then
					self.path = {}
				end
			end
		else
			self.path = Path(self)
			if not self.path:find() then
				--print("Unable to calculate path")
				return
			end

			-- done, flee path good!
			self.driver:animation("move")
		end
	end,
	stop = function(self)
		-- play out remaining animations
	end,
})

entity_ai.register_driver("death", {
	start = function(self)
		-- start with moving animation
		self.driver:animation("idle")
	end,
	step = function(self, dtime)
	end,
	stop = function(self)
		-- play out remaining animations
	end,
})

