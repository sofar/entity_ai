
--[[

Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

* entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

A Contributor License Agreement exists, please read:
- https://github.com/sofar/entity_ai/readme.md.

--]]

--
-- stone giant entity AI script
--

local stone_giant_script = {
	-- the start driver. Should be able to spawn a monster with a different driver!
	driver = "roam",
	-- default properties
	properties = {
		speed = 0.666,
		hp_max = 20,
		habitatnodes = {
			"group:stone",
			"group:cracky",
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
			{{x = 216, y = 240}, frame_speed = 24, frame_loop = false},
			{{x = 240, y = 320}, frame_speed = 24, frame_loop = true},
		},
		idle = {
			{{x = 120, y = 216}, frame_speed = 24, frame_loop = true},
		},
		punch = {
			{{x = 329, y = 367}, frame_speed = 24, frame_loop = false},
		},
		smash = {
			{{x = 367, y = 420}, frame_speed = 24, frame_loop = false},
		},
		death = {
			{{x = 420, y = 453}, frame_speed = 24, frame_loop = false},
		},
	},
	-- sound samples
	sounds = {
	},
	-- monster script states:
	roam = {
		finders = {
			"find_habitat",
		},
		factors = {},
	},
	idle = {
		factors = {},
	},
	death = {
		sounds = {
			start = "hurt",
		},
	},
}

entity_ai.register_entity("entity_ai:stone_giant", {
	script = stone_giant_script,
	mesh = "stone_giant.b3d",
	textures = {"stone_giant.png"},
	makes_footstep_sound = true,
	collisionbox = {-1/2, -1/2, -1/2, 1/2, 1, 1/2},
})

