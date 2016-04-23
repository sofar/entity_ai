--[[
- entity programming should use object:method() design.
- creating an entity should use simple methods as follows:

minetest.register_entity("sofar:sheep", {
	object = {},
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
obj:factor_is_near_grass = function(self) end
obj:factor_was_hit = function(self) end
obj:factor_is_near_mate = ...

--]]


local drivers = {}
local factors = {}


local function animation_select(self, phase, segment)
	print("animation: " .. self.name .. ", anim = " .. phase .. ", " .. (segment or 0))
	local state = self.entity_ai_state
	state.phase = phase
	state.factors.anim_ends = nil
	local animname = self.script[state.driver].animations[phase]
	if not segment then
		for i = 1, 3 do
			local animdef = self.script.animations[animname][i]
			if animdef then
				state.segment = i
				-- calculate when to advance to next segment
				if not animdef.frame_loop then
					local animlen = (animdef[1].y - animdef[1].x) / animdef.frame_speed
					state.animttl = animlen
				else
					state.animttl = nil
				end
				self.object:set_animation(animdef[1], animdef.frame_speed, animdef.frame_loop)
				return
			end
		end
	else
		local animdef = self.script.animations[animname][segment]
		if animdef then
			state.segment = segment
			self.object:set_animation(animdef[1], animdef.frame_speed, animdef.frame_loop)
			return
		end
	end
	print("animation_select: can't find animation " .. state.phase .. " for driver " .. state.driver .. " for entity " .. self.name)
end

local function animation_loop(self, dtime)
	local state = self.entity_ai_state

	if state.animttl then
		state.animttl = state.animttl - dtime
		if state.animttl <= 0 then
			state.animttl = nil
			state.factors.anim_ends = true
			animation_select(self, state.phase, state.segment + 1)
		end
	end
end

local function consider_factors(self)
	local state = self.entity_ai_state

	for factor, factordriver in pairs(self.script[state.driver].factors) do
		if state.factors[factor] then
			print("factor " .. factor .. " affects " ..  self.name .. " driver changed to " .. factordriver)
			state.driver = factordriver
			drivers[factordriver].start(self)
		end
	end
end


drivers.roam = {
	start = function(self)
		-- start with moving animation
		animation_select(self, "move")
	end,
	step = function(self, dtime)
		consider_factors(self)
		animation_loop(self, dtime)
	end,
	stop = function(self)
		-- play out remaining animations
	end,
}

drivers.startle = {
	start = function(self)
		-- start with moving animation
		animation_select(self, "startle")
	end,
	step = function(self, dtime)
		consider_factors(self)
		animation_loop(self, dtime)
	end,
	stop = function(self)
		-- play out remaining animations
	end,
}

factors.got_hit = function(self)
	local state = self.entity_ai_state
	return state.factors.got_hit
end

factors.anim_end = function(self)
	local state = self.entity_ai_state
	return state.factors.anim_ends
end

local function entity_ai_on_activate(self, staticdata)
	self.entity_ai_state = {
		factors = {}
	}
	local driver = ""

	if staticdata ~= "" then
		-- load staticdata
		self.entity_ai_state = minetest.deserialize(staticdata)
		if not self.entity_ai_state then
			self.object:remove()
			return
		end
		driver = self.entity_ai_state.driver
		print("loaded: " .. self.name .. ", driver=" .. driver)
	else
		-- set initial mob driver
		driver = self.script.driver
		local state = self.entity_ai_state
		state.driver = driver
		print("activate: " .. self.name .. ", driver=" .. driver)
	end

	drivers[driver].start(self)
end

local function entity_ai_on_step(self, dtime)
	local state = self.entity_ai_state
	local driver = self.script.driver
	drivers[driver].step(self, dtime)
end

local function entity_ai_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	local state = self.entity_ai_state
	state.factors["got_hit"] = {puncher, time_from_last_punch, tool_capabilities, dir}
end

local function entity_ai_on_rightclick(self, clicker)
end

local function entity_ai_get_staticdata(self)
	print("saved: " .. self.name)
	return minetest.serialize(self.entity_ai_state)
end


local sheep_script = {
	-- the start driver. Should be able to spawn a mob with a different driver!
	driver = "roam",
	-- defined animation sets:
	-- "name" = { animationspec1, animationspec2, animationspec3 }
	-- each must be present -> 'nil' required
	-- [1] = head animation, should not loop (when entering this animation cycle)
	-- [2] = body animation, should loop (base loop animation)
	-- [3] = tail animation, should not loop (when leaving this animation cycle)
	--FIXME handle repeats (running animation 5x ?)
	animations = {
		move = {
			{{x = 100, y = 110}, frame_speed = 30, frame_loop = false},
			{{x = 0, y = 40}, frame_speed = 60, frame_loop = true},
			nil
		},
		run = {
			nil,
			{{x = 0, y = 40}, frame_speed = 90, frame_loop = true},
			nil
		},
		idle = {
			nil,
			{{x = 111, y = 119}, frame_speed = 10, frame_loop = true},
			nil
		},
		eat = {
			nil,
			{{x = 41, y = 81}, frame_speed = 30, frame_loop = true},
			nil,
		},
		startle = {
			{{x = 100, y = 110}, frame_speed = 30, frame_loop = false},
			{{x = 111, y = 119}, frame_speed = 30, frame_loop = true},
			nil,
		},
		death = {
			{{x = 82, y = 90}, frame_speed = 15, frame_loop = false},
			{{x = 90, y = 99}, frame_speed = 15, frame_loop = true},
			nil,
		},
	},
	-- mob script states:
	roam = {
		driver = "roaming",
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
			too_far_from_home = "homing",
		},
		animations = {
			move = "move",
			idle = "idle",
		},
	},
	eat = {
		driver = "eat",
		factors = {
			ate_enough = "roam",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
		},
		animations = {
			eat = "eat",
			idle = "idle",
		},
	},
	startle = {
		driver = "startle",
		factors = {
			anim_end = "flee",
		},
		animations = {
			idle = "startle",
		},
	},
	flee = {
		driver = "flee",
		factors = {
			got_hit = "startle",
			fleed_too_long = "roam",
		},
		animations = {
			move = "run",
		},
	},
	attracted = {
		driver = "approach",
		factors = {
			became_fertile = "fertile",
			approached_too_long = "roam",
		},
		animations = {
			move = "move",
			idle = "idle",
		},
	},
	fertile = {
		driver = "mate",
		factors = {
			got_hit = "startle",
		},
		animations = {
			move = "move",
			idle = "idle",
		},
	},
	homing = {
		driver = "homing",
		factors = {
			near_home = "roam",
			got_hit = "startle",
		},
		animations = {
			move = "move",
			idle = "idle",
		},
	},
	death = {
		driver = "death",
		animations = {
			idle = "death",
		},
	},
}

minetest.register_entity("entity_ai:sheep", {
	name = "entity_ai:sheep",
	hp_max = 100,
	physical = true,
	visual = "mesh",
	mesh = "sheep.b3d",
	textures =  {"sheep_fur.png"},
	-- standard stuff
	collisionbox = {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2},
	-- entity_ai stuff
	script = sheep_script,
	-- standard callbacks
	on_activate = entity_ai_on_activate,
	on_step = entity_ai_on_step,
	on_punch = entity_ai_on_punch, -- ?
	on_rightclick = entity_ai_on_rightclick, -- per entity stuff I suppose
	get_staticdata = entity_ai_get_staticdata,
})


minetest.register_on_joinplayer(function(player)
	minetest.add_entity({x=31.0,y=2.0,z=96.0}, "entity_ai:sheep")
end)
