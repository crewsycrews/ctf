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

Enter the garden from the main menu. Plant the supplied **Fire** in an empty
plot and give it **Compost + Minerals**. The tutorial Maple grows immediately
and joins the tail. Later trees need care followed by one successful expedition;
upgrades require a different element, Compost and Minerals, then another
successful expedition. An upgrading tree keeps its original skill until it grows.

Select up to one grown tree of each base element. Click **SPACE / Q / E** in the
garden to cycle the elements assigned to the head's movements. Hover over an
upgrade or a head assignment to read its effect. Tail order is Fire, Water, Air,
Earth. Mouse controls stay tied to those elements.

Defeat enemies and touch their drops to fill the expedition backpack. The totem
opens after **90 seconds**; approach it and press **F** to return. Death or closing
the game loses the backpack and does not grow trees. Existing garden progress is
preserved. Resource rewards, grown trees and losses appear on the result screen.
The prototype uses English UI labels, matching the existing pixel font.

The head creates elemental fields with SPACE (trail), Q (landing area), and E
(area left behind). Fire head + Water tail makes steam; Water + Earth makes mud;
Earth + Air charges a stone burst; Air + Fire creates a fan. Improved followers
keep their base element for these reactions. Secondary effects cannot start new
reaction chains.

Balance and all tree recipes are in `main/scripts/modules/catalog.lua`. Saves
use `sys.get_save_file("cosmic_tree_fighters", "garden_v1")`; they contain the
garden, stored resources and preparation, but no resumable expedition backpack.
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

- Complete first planting, enter an expedition, collect drops and return after
  the exit opens. Confirm loot is deposited once and the result leads to the garden.
- Plant and care for another tree. Lose a run: no loot or growth. Return safely
  on the next run: the tree grows. Upgrade an adult and confirm its old skill
  remains usable until the next successful return.
- Try each base element, all twelve upgrades and each head infusion on all three
  movements. Check fields/marks, overlapping statuses, shield expiry, fan hits,
  projectile expiry and each reaction with an upgraded follower.
- Check map edges and obstacles during movement, dashes, enemy knockback and
  projectiles; check exit direction, mouse aim and GUI at resized window sizes.
- Restart between garden actions and after a completed run; confirm preparation
  persists. Quit during a run and confirm only its backpack is lost.
