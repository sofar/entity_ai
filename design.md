
--[[

       THIS DOCUMENT IS OBSOLETE, AND ONLY A GUIDELINE

--]]

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

sheep_script = {
	"roam" = {
		driver = "roaming",
		factors = {
			got_hit = "startle",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
			too_far_from_home = "homing",
		},
	}
	"eat" = {
		driver = "eat",
		factors = {
			ate_enough = "roam",
			became_fertile = "fertile",
			attractor_nearby = "attracted",
		}
	},
	"startle" = {
		driver = "startle",
		factors = {
			got_hit = "flee",
		},
	"flee" = {
		driver = "flee",
		factors = {
			got_hit = "startle",
			fleed_too_long = "roam",
		},
	},
	"attracted" = {
		driver = "approach",
		factors = {
			became_fertile = "fertile",
			approached_too_long = "roam",
		}
	},
	"fertile" = {
		driver = "mate",
		factors = {
			got_hit = "startle",
		}
	"homing" = {
		driver = "homing",
		factors = {
			near_home = "roam",
			got_hit = "startle",
		}
	},
	"death" = {
		driver = "death",
	}
}

