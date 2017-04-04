
--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

entity_ai.register_finder("find_habitat", function(self)
	local pos = self.object:getpos()
	local minp, maxp = vector.sort({
		x = math.random(pos.x - 10, pos.x + 10),
		y = pos.y - 5,
		z = math.random(pos.z - 10, pos.z + 10)
		}, {
		x = math.random(pos.x - 10, pos.x + 10),
		y = pos.y + 5,
		z = math.random(pos.z - 10, pos.z + 10)
		})
	local nodes = minetest.find_nodes_in_area_under_air(minp, maxp, self.driver:get_property("habitatnodes"))
	if #nodes == 0 then
		return nil
	end

	local pick = nodes[math.random(1, #nodes)]
	-- find top walkable node
	while true do
		local node = minetest.get_node(pick)
		if not minetest.registered_nodes[node.name].walkable then
			pick.y = pick.y - 1
		else
			-- one up at the end
			pick.y = pick.y + 1
			break
		end
	end
	-- move to the top surface of pick
	if not pick then
		return nil
	end

--[[		minetest.add_particle({
		pos = {x = pick.x, y = pick.y - 0.1, z = pick.z},
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 3,
		size = 6,
		collisiondetection = false,
		vertical = false,
		texture = "wool_red.png",
		playername = nil
	})
--]]
	return pick
end)

entity_ai.register_finder("flee_attacker", function(self)
	local state = self.entity_ai_state
	local from = state.attacked_at
	if state.attacker and state.attacker ~= "" then
		local player = minetest.get_player_by_name(state.attacker)
		if player then
			from = player:getpos()
		end
	end
	if not from then
		from = self.object:getpos()
		state.attacked_at = from
	end

	from = vector.round(from)

	local pos = self.object:getpos()
	local dir = vector.subtract(pos, from)
	dir = vector.normalize(dir)
	dir = vector.multiply(dir, 10)
	local to = vector.add(pos, dir)

	local nodes = minetest.find_nodes_in_area_under_air(
			vector.subtract(to, 4),
			vector.add(to, 4),
			{"group:crumbly", "group:cracky", "group:stone"})

	if #nodes == 0 then
		-- failed to get a target, just run away from attacker?!
		print("No target found, stopped")
		return
	end

	-- find top walkable node
	local pick = nodes[math.random(1, #nodes)]
	while true do
		local node = minetest.get_node(pick)
		if not minetest.registered_nodes[node.name].walkable then
			pick.y = pick.y - 1
		else
			-- one up at the end
			pick.y = pick.y + 1
			break
		end
	end

	-- move to the top surface of pick
	if not pick then
		return false
	end
--[[
	minetest.add_particle({
		pos = {x = pick.x, y = pick.y - 0.1, z = pick.z},
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 3,
		size = 6,
		collisiondetection = false,
		vertical = false,
		texture = "wool_red.png",
		playername = nil
	})
--]]
	return pick
end)
