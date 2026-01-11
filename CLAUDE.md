# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cosmic Tree Fighters (CTF)** is a 2D action game built with the Defold game engine. It's a tower defense/skill-based combat game where the player controls a character that spawns followers while defending against enemy waves.

- **Repository:** https://github.com/crewsycrews/ctf
- **Production Build:** https://casiq.itch.io/ctf
- **Engine:** Defold (version 0.1)
- **Language:** Lua 5.1

### Microlite20 (M20) Integration

The game is currently being enhanced with Microlite20 tabletop RPG mechanics for deeper stat-based progression:

- **Implementation Plan**: See [M20_IMPLEMENTATION_PLAN.md](M20_IMPLEMENTATION_PLAN.md) for detailed roadmap
- **M20 Rules Reference**: See [docs/Microlite20.pdf](docs/Microlite20.pdf) for complete M20 rules
- **Current Status**: Milestone 1 complete (core modules), Milestone 2 partial (player/enemy integration)
- **Key Features**: STR/DEX/MIND stats, d20 combat resolution, XP/leveling, 4 character classes, HP-based spell casting

## Build and Development Commands

### Using the Build Script

The project uses a custom bash script at `.vscode/defold.sh` for all build operations:

```bash
# Clean build artifacts
./.vscode/defold.sh clean Linux Linux

# Resolve dependencies (orthographic camera, druid UI, defold-event)
./.vscode/defold.sh resolve Linux Linux

# Debug build
./.vscode/defold.sh build Linux Linux

# Production bundle (Debug or Release variant)
./.vscode/defold.sh bundle Linux Linux Release

# Launch locally (runs dmengine with game.projectc)
./.vscode/defold.sh launch Linux Linux

# Deploy to device (iOS/Android only)
./.vscode/defold.sh deploy Linux Android
```

**Parameters:** `command [host_os] [target_os] [variant]`
- `host_os`: macOS, Linux, or Windows
- `target_os`: iOS, Android, macOS, Windows, Linux, or HTML5
- `variant`: Debug or Release (bundle only)

### Build Configuration

- **Defold Editor Path:** Configured in `.vscode/defold.sh` (line 11)
- **Build Output:** `./build/default/` for debug, `./bundle/{target_os}/` for bundles
- **Email for Dependencies:** Set in `.vscode/defold.sh` (line 22)

## Architecture

### Message-Driven Communication

All game systems communicate through Defold's message passing system. Messages are defined in `main/scripts/modules/constants.lua`:

```lua
MESSAGES = {
  LOAD_LEVEL = "load_level",
  PLAYER = {
    TAKE_DAMAGE = 'player_take_damage',
    SET_HEALTH = 'player_set_health',
    COUNT_SCORE = 'player_count_score'
  },
  TOTEM = { TAKE_DAMAGE = 'totem_take_damage', SET_HEALTH = 'totem_set_health' },
  SKILLS = { COOLDOWN = 'cooldown', NORMAL = 'normal' }
}
```

Use `msg.post(url, hash(MESSAGES.PLAYER.TAKE_DAMAGE), { damage = 10 })` to send messages between components.

### Scene Management with Collection Proxies

The game uses collection proxies for dynamic scene loading (managed by `main/scripts/loader.script`):

1. **Start Menu** (`/loader#menu`) → Initial screen
2. **Level 1** (`/loader#level1`) → Main gameplay
3. **Game Over** (`/loader#game_over`) → End screen

To transition scenes:
```lua
msg.post("/loader#script", hash(MESSAGES.LOAD_LEVEL), { level = 1 })
```

The loader automatically unloads the previous scene before loading the new one.

### Collision System

Physics uses collision groups defined in `constants.lua`:
- `projectiles` - Player spell projectiles
- `ice_barrage` - Ice spell area effect
- `totem` - Defensive towers
- `head` - Player character collision
- `enemies` - Enemy units
- `thunderclap` - Thunder spell area
- `obstacles` - Level geometry

Physics scale is set to `0.02` in `game.project` for Box2D integration.

### Status/Buff System

Entities can have temporary status effects (implemented in `main/scripts/modules/buffs.lua`):
- `invulnerability` - Cannot take damage
- `frozen` - Cannot move
- `slow` - 50% movement speed

Buffs are stored in `entity.buffs` table and managed via timers.

### Microlite20 (M20) System

The game uses the Microlite20 RPG system for character stats, combat resolution, and progression. All entities (player, enemies) have M20 stats:

```lua
entity.m20_stats = {
  -- Core attributes (3-18 typical range)
  STR = 10,  -- Strength (melee attack/damage)
  DEX = 10,  -- Dexterity (AC, ranged attack)
  MIND = 10, -- Mind (spellcasting, magic)

  -- Derived stats
  level = 1,
  xp = 0,
  xp_to_next_level = 10,
  hp_max = 15,      -- Maximum HP
  hp_current = 15,  -- Current HP (source of truth for health)
  ac = 11,          -- Armor Class (10 + DEX bonus)

  -- Metadata
  class = "fighter", -- fighter, rogue, mage, cleric
  race = "human"     -- human, elf, dwarf, halfling
}
```

**Key M20 Mechanics**:
- **Stat Bonus**: (stat - 10) / 2 rounded down (e.g., STR 16 = +3 bonus)
- **XP Formula**: Enemy awards HD² + HD XP (e.g., 2 HD = 6 XP)
- **Level-Up**: Requires 10 × current level XP (level 1→2 = 10 XP)
- **HP System**: M20 stats are the single source of truth (no redundant health properties)
- **Combat**: d20 + attack bonus vs AC, then damage roll on hit
- **Spells**: Cost 1 + (2 × spell level) HP, no cooldowns

**M20 Modules** (`main/scripts/modules/m20_*.lua`):
- `m20_attributes.lua` - Stat management, HP/AC calculation
- `m20_dice.lua` - Dice rolling (d20, d6, etc.), attack/damage rolls
- `m20_combat.lua` - Combat resolution with M20 rules
- `m20_skills.lua` - 4-skill system (Physical, Subterfuge, Knowledge, Communication)
- `m20_progression.lua` - XP tracking, level-up mechanics
- `m20_classes.lua` - Character classes (Fighter, Rogue, Mage, Cleric)
- `m20_magic.lua` - HP-based spell casting
- `m20_spells.lua` - Spell database (35+ spells from M20 rules)

**M20 Messages** (in `constants.lua`):
```lua
MESSAGES.M20 = {
  AWARD_XP = 'm20_award_xp',           -- Award XP to player
  LEVEL_UP = 'm20_level_up',           -- Level-up notification
  SPELL_CAST = 'm20_spell_cast',       -- Spell cast event
  -- ... see constants.lua for full list
}
```

**Integration Status**:
- ✅ Player: Initialized as Fighter/Human, gains XP on kills, levels up automatically
- ✅ Enemies: Stats generated from HD property, award XP on death
- ⏸️ Spells: Modules ready, integration pending (Milestone 3)
- ⏸️ UI: HUD/character sheet pending (Milestone 2)

### Skill System

All player abilities have:
- **Cooldown duration** - Time before reuse (defined in `SKILLS.COOLDOWNS`)
- **Active duration** - How long effect lasts (defined in `SKILLS.DURATIONS`)
- **UI feedback** - Messages to GUI for cooldown indicators

Implemented in `main/scripts/modules/skills.lua`:

| Skill | Cooldown | Duration | Effect |
|-------|----------|----------|--------|
| Dash | 3s | 0.4s | Forward movement + invulnerability |
| Jump | 3s | 0.8s | Scale animation |
| Backward Dash | 3s | 0.4s | Backward movement |
| Ice Barrage | 6s | 3s | Freeze enemies in area |
| Fireball | 0.3s | instant | Fast projectile |
| Thunderclap | 5s | 0.5s | Slow enemies in area |
| Windwalk | 5s | 0.5s | Invisibility |

### Factory-Based Spawning

Dynamic entities use Defold's factory system:
- Spells spawn via `factory.create()` from player collection
- Enemies spawn via factory references in level collections
- Enables object pooling and lifecycle management

### Camera and Coordinate Systems

The game uses the **Orthographic Camera** dependency for rendering and coordinate transformations:
- **Camera ID**: `/camera` - The main camera game object
- **Screen to World Conversion**: Use `camera.screen_to_world(go.get_id("/camera"), screen_pos)` to convert mouse/touch input to world coordinates
- **Module**: `require("orthographic.camera")` provides camera utilities
- **Important**: All mouse/touch input from `on_input()` is in screen space and must be converted to world space for game logic
- **Example**: See `main/scripts/common/get_world_rotation.lua` for proper camera coordinate conversion

## Key Directories

- `main/scripts/` - Game logic (player, enemies, loader)
  - `modules/` - Reusable Lua modules (skills, buffs, followers, constants)
  - `common/` - Utility functions (functional programming, random, rotation)
  - `skills/` - Spell behaviors (projectile, basic_spell, buff_applier)
  - `units/` - Enemy behaviors (bat, bomber, mine)
- `main/prefabs/` - Reusable game objects
  - `players/` - Player character and followers
  - `enemies/` - Enemy prefabs
  - `spells/` - Spell projectiles
  - `buffs/` - Buff effect prefabs
- `main/gui/` - UI screens and HUD
  - `proxy/` - Collection proxy files for scene loading
- `main/atlases/` - Sprite atlases for rendering
- `main/tilesources/` - Tiled sprite sheets
- `assets/` - Raw source files (PNGs, Tiled maps, audio)

## Coding Standards

### Type Annotations (LuaLS/EmmyLua)

**All Lua modules MUST include type annotations** using LuaLS (Lua Language Server) / EmmyLua syntax:

**Required Annotations**:
1. **Class definitions** at the top of modules for complex data structures
2. **Function parameters** with `---@param` annotations
3. **Return types** with `---@return` annotations
4. **Optional parameters** marked with `?` suffix (e.g., `---@param count? number`)

**Example**:
```lua
---@class M20Stats
---@field STR number Strength stat
---@field DEX number Dexterity stat
---@field level number Character level

--- Roll a die with specified number of sides
---@param sides number Number of sides on the die
---@param count? number Number of dice to roll (default: 1)
---@return number total Sum of all dice rolled
function M.roll(sides, count)
    count = count or 1
    return math.random(1, sides) * count
end
```

**Benefits**:
- IDE autocomplete and IntelliSense
- Type checking and error detection
- Self-documenting code
- Easier refactoring and maintenance

**Type Annotation Style**:
- Use `---` (three dashes) for LuaLS annotations
- Place `---@class` definitions at the top of the module
- Add function annotations immediately before function declaration
- Use `?` suffix for optional parameters (e.g., `count?`)
- Use `|` for union types (e.g., `string|nil`)
- Use `[]` suffix for arrays (e.g., `number[]`)

## Common Development Patterns

### Adding a New Enemy

1. Create game object in `main/prefabs/enemies/{enemy_name}.go`
2. Add collision object with `enemies` group
3. Attach `main/scripts/enemy-common.script` (handles movement, health, buffs)
4. Set properties: `health`, `speed`, `damage`, `score_points`
5. Create sprite atlas in `main/atlases/{enemy_name}.atlas`
6. Add factory to level collection for spawning

### Adding a New Spell

1. Create game object in `main/prefabs/spells/{spell_name}.go`
2. Add to `main/prefabs/players/snake.collection` as factory component
3. Implement spell logic in `main/scripts/modules/skills.lua`
4. Add cooldown to `SKILLS.COOLDOWNS` in `constants.lua`
5. Add duration to `SKILLS.DURATIONS` if applicable
6. Update UI in `main/gui/player_gui.gui_script` for cooldown indicator

### Reading and Modifying Game State

The game uses `shared_state = 1` in `game.project`, meaning all scripts share global variables. Use this sparingly. Prefer message passing for inter-component communication.

### Player Controller

The player script (`main/scripts/player.script`) handles:
- Movement via WASD input
- Health management (max 100, game over at 0)
- Score tracking (victory at 50 points)
- Skill activation via input handlers
- Camera following
- Sprite animation based on movement direction

## Dependencies

Defined in `game.project`:
1. **Orthographic Camera** - https://github.com/britzl/defold-orthographic/archive/master.zip
   - Custom render pipeline: `/orthographic/render/orthographic.renderc`
2. **Druid UI Framework** - https://github.com/Insality/druid/archive/master.zip
   - Advanced GUI components
3. **Event System** - https://github.com/Insality/defold-event/archive/refs/tags/12.zip
   - Message/event dispatching

Run `./.vscode/defold.sh resolve Linux Linux` to fetch dependencies.

## Graphics Settings

Configured for pixel-perfect rendering:
```ini
[graphics]
default_texture_mag_filter = nearest
default_texture_min_filter = nearest

[sprite]
subpixels = 0
```

Use nearest-neighbor filtering for all textures to maintain sharp pixel art.

## Input Configuration

Defined in `input/game.input_binding`:
- **WASD** - Movement
- **Space** - Dash
- **Q** - Jump
- **E** - Backward Dash
- **Left Click** - Fireball
- **Right Click** - Windwalk
- **Scroll Up** - Thunderclap
- **Scroll Down** - Ice Barrage

## Victory/Defeat Conditions

- **Victory:** Score reaches 50 points → Auto-transition to game over after 5 seconds
- **Defeat:** Player health ≤ 0 → Immediate transition to game over
- Enemies award points (via `score_points` property) when defeated

## Important Notes

- **No formal test suite:** Quality assurance via manual playtesting
- **Follower system disabled:** Code exists but commented out in `player.script`
- **Bat enemy:** `main/scripts/units/bat.script` is empty, relies entirely on `enemy-common.script`
- **Physics quirk:** Using 0.02 scale factor for Box2D - verify collision shapes match this scale
- **Build manifests:** `.der` files in root are build signing keys - do not commit changes

## Project Links

- [Kanban Board](https://github.com/users/crewsycrews/projects/1/views/1)
- [Wiki](https://github.com/crewsycrews/ctf/wiki)
- [Design Boards](https://app.milanote.com/1PrOwX1RFhvIbg/ctf?p=rVxL2CCI5mr)
- [Telegram](https://t.me/+LdamYGZOgy80ZDhi)
- [Meet](https://meet.jit.si/ctfteammeet)
