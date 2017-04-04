
--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

--
-- sheep entity AI script
--

local sheep_script = {
	-- the start driver. Should be able to spawn a monster with a different driver!
	driver = "roam",
	-- default properties
	properties = {
		speed = 2.0,
		hp_max = 20,
		foodnodes = {
			"group:grass",
			"default:dirt_with_grass",
			"default:dirt_with_dry_grass",
			"default:grass_1",
			"default:grass_2",
			"default:grass_3",
			"default:grass_4",
			"default:grass_5",
			"default:dry_grass_1",
			"default:dry_grass_2",
			"default:dry_grass_3",
			"default:dry_grass_4",
			"default:dry_grass_5",
		},
		habitatnodes = {
			"group:flora",
			"group:snappy",
			"group:dirt",
			"group:soil",
			"group:crumbly",
			"group:grass",
			"default:dirt_with_grass",
			"default:dirt_with_dry_grass",
			"default:sand"
		,}
	},
	-- defined animation sets:
	-- "name" = { animationspec1, animationspec2, animationspec3 .. }
	-- each must be present -> 'nil' required
	-- last animation should have 'frame_loop = true'
	--FIXME handle repeats (running animation 5x ?)
	animations = {
		move = {
			{{x = 0, y = 40}, frame_speed = 60, frame_loop = true},
		},
		run = {
			{{x = 0, y = 40}, frame_speed = 90, frame_loop = true},
		},
		idle = {
			{{x = 111, y = 129}, frame_speed = 10, frame_loop = true},
		},
		eat = {
			{{x = 41, y = 47}, frame_speed = 15, frame_loop = false},
			{{x = 47, y = 75}, frame_speed = 15, frame_loop = true},
		},
		eat_end = {
			{{x = 75, y = 81}, frame_speed = 15, frame_loop = false},
		},
		startle = {
			{{x = 100, y = 110}, frame_speed = 30, frame_loop = false},
			{{x = 111, y = 119}, frame_speed = 30, frame_loop = true},
		},
		death = {
			{{x = 82, y = 90}, frame_speed = 15, frame_loop = false},
			{{x = 90, y = 99}, frame_speed = 15, frame_loop = true},
		},
	},
	-- sound samples
	sounds = {
		chatter = {{name = "sheep_chatter", gain = 0.2}, {max_hear_distance = 12}},
		footsteps = {{name = "sheep_steps", gain = 0.2}, {max_hear_distance = 12}},
		hurt = {{name = "sheep_hurt", gain = 0.5}, {max_hear_distance = 18}},
	},
	-- monster script states:
	roam = {
		finders = {
			"find_habitat",
		},
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
		},
		sounds = {
			random = "footsteps",
		},
	},
	idle = {
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
			too_far_from_home = "homing",
			near_foodnode = "eat",
		},
		sounds = {
			random = "chatter",
		},
	},
	eat = {
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
		},
		sounds = {
			random = "chatter",
		},
	},
	eat_end = {
		factors = {
			anim_end = "idle",
		}
	},
	startle = {
		factors = {
			anim_end = "flee",
		},
		sounds = {
			start = "hurt",
		},
	},
	flee = {
		finders = {
			"flee_attacker",
		},
		properties = {
			speed = 4.0,
		},
		factors = {
			got_hit = "startle",
		},
		sounds = {
			random = "footsteps",
		},
	},
	attracted = {
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			approached_too_long = "roam",
		},
		sounds = {
			random = "chatter",
		},
	},
	fertile = {
		factors = {
			got_hit = "startle",
		},
		sounds = {
			random = "chatter",
		},
	},
	homing = {
		factors = {
			near_home = "roam",
			got_hit = "startle",
		},
		sounds = {
			random = "chatter",
		},
	},
	death = {
		sounds = {
			start = "hurt",
		},
	},
}

entity_ai.register_entity("entity_ai:sheep", {
	script = sheep_script,
	mesh = "sheep.b3d",
	textures = {"sheep_fur.png"},
	makes_footstep_sound = true,
	collisionbox = {-5/16, -1/2, -5/16, 5/16, 4/16, 5/16},
})

