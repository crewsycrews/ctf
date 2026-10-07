# Cosmic Tree Fighters

## Run from VS Code

Install the recommended **Defold Kit** and **Local Lua Debugger** extensions.
Set `defoldKit.general.editorPath` to the actual Defold installation directory
(for Steam on macOS, use the app under `~/Library/Application Support/Steam/steamapps/common/Defold`, not the shortcut in `~/Applications`).

After changing dependencies, run the **Resolve** task from **Terminal → Run Task**.
In **Run and Debug**, select **Build & Run** and press **F5** to build and launch
with the Lua debugger. **Just Run** launches the last VS Code build without
rebuilding. **Ctrl/Cmd+Shift+B** builds without launching.

VS Code uses `build/defoldkit`; the Defold Editor's `build/default` output is separate.

*We place the seeds 
and grow the trees
They reinforce us
To reach out peace*

[Kanban](https://github.com/users/crewsycrews/projects/1/views/1) | [Вики](https://github.com/crewsycrews/ctf/wiki) | [Boards](https://app.milanote.com/1PrOwX1RFhvIbg/ctf?p=rVxL2CCI5mr) | [Prod](https://casiq.itch.io/ctf) | [Telegram](https://t.me/+LdamYGZOgy80ZDhi) | [Meet](https://meet.jit.si/ctfteammeet)

## Expedition and garden prototype

The garden is a top-down world. Move the druid with **WASD**, approach one of
16 soil plots and press **F**. Plant the supplied **Fire**, then interact again
and provide **Compost + Minerals**. The tutorial Maple grows immediately and
joins the tail. Later trees grow after care and one level victory. Only an adult
base tree can accept another element; its upgrade also needs materials and a
victory. Trees, seedlings and selected followers are visible in the world.
**F / Esc** closes an interaction; movement pauses while its panel is open.

Visit grown trees to choose up to one follower of each base element. Walk to the
expedition gate at the south-center of the garden and press **F** to prepare.
Click **SPACE / Q / E** assignments to cycle free head elements or None. Every
head assignment or tail follower reserves **one grown tree of its base element**
from the same pool. For example, two grown Fire trees support one Fire follower
and one Fire head skill. Seedlings do not count; upgrading trees still count once
as their base element. The preparation panel shows used/total trees per element.
Release an assignment to reuse its capacity; trees are never consumed. Tail order
stays Fire, Water, Air, Earth, with at most one follower per element. Hover over an
upgrade or assignment to read its effect.

Old saves are migrated to format 2 in the same save file. Trees, resources and
tail choices are preserved. Excess head assignments are cleared in order of
priority: keep Dash first, then Jump, then Backstep, as capacity allows. A notice
explains this in the garden; a failed migration save can be retried.

Levels finish **automatically** once the monster quota is met. Level 1 requires
12 kills; each next level adds 4, capped at 60. Every fifth level also requires a
guardian (an enlarged existing bomber, with extra health and recurring contact
damage). Enemies killed by touching the head do not advance the objective and
are replaced. There is no per-enemy loot or timed totem extraction.

Victory on levels 1–5 grants **one elemental resource, one Compost and one
Minerals**. Elements rotate **Fire → Water → Air → Earth → Fire** by level:
level 1 rewards Fire, level 2 Water, level 3 Air, level 4 Earth, and so on. The gate
shows the exact reward before departure. Only victory advances the rotation;
death, quitting and restarting keep the same reward for the current level.
Existing saves continue from their stored level (level 1 for older saves without
level progress). No trees or stored resources are reset.

Every five levels the quantity increases by one, up to five of each; all elemental
units from a level have the same type. Rewards are paid once on victory,
regardless of surplus kills. Random enemy spawn directions are unchanged.
Victory grows prepared trees and unlocks the next level. Death or quitting pays
nothing and does not advance levels or growth. Earlier garden progress remains
safe. Existing saves retain all trees/resources and start the new level sequence
at level 1. UI labels use English to match the existing pixel font.

Combat HUD shows health, level objective, a compact skill row, and transient
reactions. Boss health appears only during the boss encounter.

Tail skills use their original animation assets: the Fire projectile, the Water
ice stream, Earth's expanding explosion and Air's flying follower image. Wheel
down casts a 3-second ice stream toward the cursor (300 units long), following
the Water follower and its aim. Targets in the forward cone take 10 damage once
per cast and freeze for 2 seconds. The cooldown remains 6 seconds. Animated
objects are presentation only; the combat model owns hits, movement and expiry.

The head creates elemental fields with SPACE (trail), Q (landing area), and E
(area left behind). Fire head + Water tail makes steam; Water + Earth makes mud;
Earth + Air charges a stone burst; Air + Fire creates a fan. Improved followers
keep their base element for these reactions. Secondary effects cannot start new
reaction chains.

Balance and all tree recipes are in `main/scripts/modules/catalog.lua`. Saves
use `sys.get_save_file("cosmic_tree_fighters", "garden_v1")`; they contain the
garden, stored resources, preparation and next level, but no resumable combat.
A failed save blocks further transactions and exposes a retry button.

### Checks

Run the pure Lua rules and GUI/controller adapter checks from the repository root:

```sh
lua tests/run.lua
lua tests/adapters.lua
```

The modules use Lua 5.1-compatible syntax; the same tests can run with LuaJIT.
Adapter checks mock Defold APIs and do not replace testing in the engine.

Manual acceptance with **Build & Run**:

- Walk between plots, plant and care with F, and check trunks, world labels and
  camera movement. Visit the gate, prepare, then complete the kill quota. Confirm
  automatic victory pays one element plus materials exactly once.
- Complete level 5: the guardian must appear only after the quota, survive contact,
  and block victory until defeated. Level 6 should reward two units of one element.
- Plant and care for another tree. Lose a run: no loot or growth. Return safely
  on the next run: the tree grows. Upgrade an adult and confirm its old skill
  remains usable until the next successful return.
- Try each base element, all twelve upgrades and each head infusion on all three
  movements. Check fields/marks, overlapping statuses, shield expiry, fan hits,
  projectile expiry and each reaction with an upgraded follower.
- Check map edges and obstacles during movement, dashes, enemy knockback and
  projectiles; check mouse aim and the compact HUD at resized window sizes.
- Restart between garden actions and after a completed run; confirm preparation
  and unlocked level persist. Quit during a run: no reward, level advance or growth.
