
This is a summary of high-level features that are still missing,
not a detailed bug list.


1 - Monster persistence

Monsters should be persistent in the world: The default assumption
is that a world is generated by mapgen and is then mostly finished,
and any modification to the world afterwards is persistent.

For monsters, this means that mapgen should add monsters to the
mapblocks. If these monsters should die, they are in principle removed
from the world forever.

A `/clearobjects` call should not affect this. We can get this behavior
by using ABM's to respawn missing monsters. This may replace normal
block saving entirely, which is the default method to save/load entities.

Initial monster addition to the world should be done using generic
algorithms that use e.g. perlin noise to place monsters in the proper
locations, density and type.

Additonal spawning algorithms (e.g. respawning, or randomly spawning
more mobs after a while) should be optional and possibly done by
an external mod.


2 - Finish the Sheep

Various "basic" things about sheep are not implemented. This includes
gender and reproduction, shearing/wool, handling drops.


3 - Finish the Stone Monster

Missing fighting sequence, initial trapped state, drops etc..


4 - Decide on additional monsters to be implemented

Ideally, we add 1 swimmer and 1 flyer, just so that we cover all of the
movement types and implement all the needed path finding codes to support
them. I'm declaring a 5-monster maximum for now - the API is open enough
that additional monsters can become modules.
