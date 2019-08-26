
## NAME

The `entity_ai` name is kind of lame, so, I likely will want to
change the name to something that more appropriately represents it's
architecture. There is absolutely nothing AI about this desing, and
it's more of a finite state machine than anything. Not that that
diminishes the project in any way. But despite it's capability of
plugging in a real AI of sorts, it currently doesn't do that.

## LICENSE

Copyright (c) 2016-2019 - Auke Kok <sofar@foo-projects.org>

`entity_ai` is licensed as follows:
- All code is: LGPL-2.1
- All artwork is: CC-BY-SA-4.0

except:
- sound files in the `sounds` folder are licensed according to their
  respective licenses (documented in sounds/readme.md).
- `stone_giant.png` is identical to `default_stone.png` from `minetest_game`
  and licensed as the original.

["code" means everything in lua files, "artwork" means everything else,
including documentation, sounds, textures, 3d models]

## SPLITTING UP THIS PROJECT *

In the future, the core API code will be seperated from the monster
definitions. Each monster will be it's own `mod` permitting users to
disable/enable monsters as they see fit. This organization will help
to keep per-mod specific code out of the core and make core functions
better suited to handle all monsters.
