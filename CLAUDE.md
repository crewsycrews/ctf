# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cosmic Tree Fighters (CTF)** is a 2D action game built with the Defold game engine. It's a tower defense/skill-based combat game where the player controls a character that spawns followers while defending against enemy waves.

- **Repository:** https://github.com/crewsycrews/ctf
- **Production Build:** https://casiq.itch.io/ctf
- **Engine:** Defold (version 0.1)
- **Language:** Lua 5.1

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
