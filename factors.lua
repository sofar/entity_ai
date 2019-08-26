
--[[

Copyright (c) 2016-2019 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: LGPL-2.1
- All artwork is: CC-BY-SA-4.0

--]]

entity_ai.register_factor("near_foodnode", function(self, dtime)
	local state = self.entity_ai_state

	-- still fed?
	if state.ate_enough and state.ate_enough > 0 then
		state.ate_enough = state.ate_enough - dtime
		return
	end
	state.ate_enough = nil

	-- don't check too often
	if state.near_foodnode_ttl and state.near_foodnode_ttl > 0 then
		state.near_foodnode_ttl = state.near_foodnode_ttl - dtime
		return
	end
	state.near_foodnode_ttl = 2.0

	local pos = vector.round(self.object:getpos())
	local yaw = self.object:getyaw()
	self.yaw = yaw
	local offset = minetest.yaw_to_dir(yaw)
	local maxp = vector.add(pos, offset)
	local minp = vector.subtract(maxp, {x = 0, y = 1, z = 0 })
	local nodes = minetest.find_nodes_in_area(minp, maxp, self.driver:get_property("foodnodes"))

	if #nodes == 0 then
		return
	end

--[[	minetest.add_particle({
		pos = maxp,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 3,
		size = 6,
		collisiondetection = false,
		vertical = false,
		texture = "wool_pink.png",
		playername = nil
	})
--]]

	-- store grass node in our factor result - take topmost in list
	return nodes[#nodes]
end)

