
Copyright (c) 2016 - Auke Kok <sofar@foo-projects.org>

entity_ai is licensed as follows:
- All code is: GNU Affero General Public License, Version 3.0 (AGPL-3.0)
- All artwork is: CC-BY-ND-4.0

except:
- sound files in the `sounds` folder are licensed according to their
  respective licenses (documented in sounds/readme.md).
- stone_giant.png is identical to default_stone.png from minetest_game
  and licensed as the original.

["code" means everything in lua files, "artwork" means everything else,
including documentation, sounds, textures, 3d models]

The implications of this are:

1) you can re-distribute the artwork, but only if you:
  a) properly attribute
  b) do not modify the artwork

2) If you deploy the code on a server, you must provide the source code
   on request to any player on your server.

Any violations of these license clauses terminates your rights to use
the software in this matter, and you may no longer operate this software
on a server or redistribute it.


```
 Contributor License Agreement

  By submitting code to the github project, you agree to the following:

  (1) you expressly guarantee that you are the sole author of all
  parts of the contribution.

  (2) you expressly permit the author, Auke Kok, of entity_ai to
  relicense all (your) contributions to LGPL-2.1+ (for code) and
  CC-BY-SA-4.0 (for all artwork) FOR THE SOLE PURPOSE OF MERGING THIS
  CODE INTO MINETEST_GAME[1] SHOULD THIS MERGE OCCUR AND BE ACCEPTED.

[1] https://github.com/minetest/minetest_game
```

This CLA is present here to (1) make sure this code doesn't
fragment and (2) is distributed in a compatible way in the future in
minetest_game should this be wanted or preferred. This gives maximum
reassurance that contributions to this project are going to be used
in the best interest of the minetest_game, and that people who make
valuable changes to this project are required to give changes back
until such a merge happens. If the merge occurs in the future, all
contributions will become available under a permissive license to
everyone, encouraging everyone to help with making this code mergable.


* NOTICE FOR MONSTER ADDITIONS *

The license for any monster using the exported API has to be compatible
with the license of the API itself. That means that any custom monster
code has to be AGPL-3.0 until it gets merged in minetest_game[1],
after which it has to be LGPL-2.1+ or compatible with that. You may
choose to license your artwork in any way you see fit, however.


* SPLITTING UP THIS PROJECT *

In the future, the core API code will be seperated from the monster
definitions. Each monster will be it's own `mod` permitting users to
disable/enable monsters as they see fit. This organization will help to
keep per-mod specific code out of the core and make core functions
better suited to handle all monsters.
