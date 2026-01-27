# Microlite20 Integration Plan for Cosmic Tree Fighters

## Executive Summary

This plan outlines the integration of Microlite20 (M20) tabletop RPG rules into the existing Cosmic Tree Fighters (CTF) action game. The goal is to add RPG depth (stats, progression, dice rolls) while preserving the real-time action gameplay.

**Key Strategy**: Hybrid approach - keep real-time action gameplay, add M20 mechanics "under the hood" for progression, damage calculation, and skill checks.

**Reference**: See [docs/Microlite20.pdf](docs/Microlite20.pdf) for complete M20 rules.

---

## Implementation Status

**Current Status**: ✅ **Milestone 1 Complete**, ✅ **Milestone 2 Complete**, ✅ **Milestone 3 Complete**

**Completed Work**:
- ✅ All M20 core modules created with full type annotations
- ✅ Player script integrated with M20 stats system
- ✅ Enemy script integrated with M20 stats and XP awards
- ✅ Redundant health properties removed (M20 stats are now single source of truth)
- ✅ XP formula finalized: HD² + HD (quadratic scaling for action gameplay)
- ✅ Spell definitions database created (35+ spells from M20 rules)
- ✅ M20 message types added to constants
- ✅ Class selection UI implemented (Fighter/Rogue/Mage/Cleric)
- ✅ Race selection UI implemented (Human/Elf/Dwarf/Halfling)
- ✅ Stat selection UI implemented (every 3 levels: STR/DEX/MIND choice)
- ✅ Enemy prefabs updated with HD properties
- ✅ Scene flow: Start Menu → Class Selection → Race Selection → Game
- ✅ Spell HP costs integrated (no cooldowns for spells)
- ✅ HUD enhancements complete (HP text, XP bar, Level, AC display, spell HP cost overlays)

**Next Steps**: Milestone 4 - Enemy Improvements (Totem integration, wave HD progression) or Additional Features (Spell DC/Resistance, Floating Combat Text)

---

## Phase 1: Core M20 Systems (Foundation) ✅ COMPLETE

### 1.1 Character Attributes Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_attributes.lua`

**Implemented Features**:
- Stat bonus calculation: (stat - 10) / 2 (rounded down)
- 4d6 drop lowest stat generation for character creation
- Race bonuses (Human, Elf, Dwarf, Halfling)
- Template stats for each class (Fighter, Rogue, Mage, Cleric)
- Monster stat generation from Hit Dice (HD)
- 2x HP multiplier for action gameplay balance
- HP/AC calculation and damage/healing functions
- Spell cost checking utilities

**Integration Complete**:
- ✅ Player: Initialized as Fighter/Human with template stats
- ✅ Enemies: Stats generated from HD property
- ⏸️ Totem: Pending (Milestone 4)

---

### 1.2 Dice Rolling Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_dice.lua`

**Implemented Functions**:
- `roll(sides, count)` - Basic dice rolling
- `roll_separate(sides, count)` - Roll dice separately (for visual feedback)
- `stat_bonus(stat_value)` - Calculate modifier from stat
- `attack_roll(attacker, target)` - d20 + attack bonus vs AC
- `damage_roll(dice_notation, stat_bonus)` - Parse "1d8+3" format
- `parse_notation(notation)` - Parse dice notation strings
- `roll_4d6_drop_lowest()` - Character creation stat rolling
- `skill_check(entity, skill, dc, stat)` - Quick skill checks
- `saving_throw(entity, save_type, dc)` - Fort/Reflex/Will saves
- `spell_dc(caster)` - Calculate spell save DC

**Type Annotations**: Full LuaLS/EmmyLua documentation

---

### 1.3 Combat Resolution Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_combat.lua`

**Implemented Functions**:
- `resolve_attack(attacker, target, damage_dice, type)` - Complete attack resolution
- `melee_attack(attacker, target, damage_dice)` - Melee combat
- `ranged_attack(attacker, target, damage_dice)` - Ranged combat
- `magic_attack(caster, target, damage_dice)` - Spell attacks
- `spell_with_save(caster, target, spell_level, save_type)` - Spell with saving throw
- `aoe_spell(caster, targets, spell_level, damage_dice, save_type)` - Area effect spells

**Integration Status**: Module ready, needs integration with projectile system (Milestone 3)

---

### 1.4 Skills & Checks Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_skills.lua`

**Implemented Features**:
- 4 skills: Physical (STR/DEX), Subterfuge (DEX/MIND), Knowledge (MIND), Communication (MIND)
- Class bonuses: Fighter +3 Physical, Rogue +3 Subterfuge, Mage +3 Knowledge, Cleric +3 Communication
- Skill initialization for players and monsters
- Skill checks with stat synergies
- Skill rank increase on level-up

**Type Annotations**: SkillCheckDetailedResult class with full roll breakdown

---

### 1.5 Experience & Leveling Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_progression.lua`

**Implemented Features**:
- **XP Formula**: `HD² + HD` for individual enemy kills
  - 1 HD = 2 XP (5 kills for level 2)
  - 2 HD = 6 XP (2 kills)
  - 3 HD = 12 XP (1 kill)
  - 4 HD = 20 XP (boss-level reward)
- Level-up threshold: 10 × current level
- Level-up bonuses: +1d6 HP, +1 all attack rolls, +1 all skills
- Stat increase every 3 levels (auto-selected for now, player choice coming in Milestone 2)

**Integration Status**:
- ✅ Player: XP award and level-up messages working
- ✅ Enemies: Award XP on death based on HD

---

### 1.6 Spell System Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_spells.lua`

**Implemented Features**:
- 35+ spell definitions from M20 rules (levels 0-5)
- Spell database with ID, name, level, school, range, duration, description, effect
- CTF spell mappings:
  - `fireball` → Magic Missile (1st level, 1d4+1 auto-hit)
  - `ice_barrage` → Hold Person (2nd level, paralyze)
  - `thunderclap` → Gust of Wind (2nd level, knockback/slow)
  - `windwalk` → Invisibility (1st level, stealth)
- Utility functions: spell lookup, damage calculation, UI formatting

---

### 1.7 Magic Casting Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_magic.lua`

**Implemented Features**:
- HP-based spell casting: cost = 1 + (2 × spell level)
- Signature spells: -1 HP cost reduction
- Can cast spell checks (level requirement, HP availability)
- Spell DC calculation: 10 + caster level + MIND bonus
- Rest mechanics (HP recovery after 8 hours)
- Spell slot calculations for UI display

**Integration Status**: Module ready, needs integration with skill system (Milestone 3)

---

### 1.8 Class System Module ✅ COMPLETE
**File**: `/main/scripts/modules/m20_classes.lua`

**Implemented Classes**:

| Class | Primary Stat | Armor | Special Ability |
|-------|-------------|-------|-----------------|
| Fighter | STR | Any + shields | +3 Physical, +1 attack/damage per 5 levels |
| Rogue | DEX | Light | +3 Subterfuge, sneak attack damage |
| Mage | MIND | None | +3 Knowledge, arcane spells |
| Cleric | MIND | Light/Medium | +3 Communication, divine spells, Turn Undead |

**Implemented Functions**:
- Class feature application (bonuses, special abilities)
- Armor/weapon proficiency checks
- Sneak attack damage calculation
- Turn Undead DC calculation

**Integration Status**:
- ✅ Player: Fighter class applied with bonuses
- ⏸️ Class selection UI: Pending (Milestone 2)

---

## Phase 2: Player & Enemy Integration ✅ COMPLETE

### 2.1 Player Script Integration ✅ COMPLETE
**File**: `main/scripts/player.script`

**Completed Changes**:
- ✅ M20 module imports added
- ✅ Type annotations for m20_stats, m20_skills, signature_spells, pending_level_up
- ✅ Initialize M20 stats with default Fighter/Human (overridden by class selection)
- ✅ Removed redundant `max_health` and `current_health` properties
- ✅ All health checks now use `self.m20_stats.hp_current` directly
- ✅ Damage handler uses `attrs.take_damage()`
- ✅ XP award message handler with automatic level-up
- ✅ GUI health updates use M20 stats
- ✅ Console logging for M20 events (init, XP, level-up)
- ✅ `set_class` message handler to reinitialize stats with chosen class/race
- ✅ Stat selection logic: automatic for levels 1-2, player choice at 3, 6, 9, etc.
- ✅ `stat_selected` message handler to complete level-up with chosen stat

---

### 2.2 Enemy Script Integration ✅ COMPLETE
**File**: `main/scripts/enemy-common.script`

**Completed Changes**:
- ✅ M20 module imports added
- ✅ `go.property("hd", 1)` for Hit Dice
- ✅ Removed redundant `health` property
- ✅ Initialize M20 stats based on HD
- ✅ All health checks now use `self.m20_stats.hp_current` directly
- ✅ Damage handler uses `attrs.take_damage()`
- ✅ Award XP on death using `progression.calculate_enemy_xp(self.hd)`

---

### 2.3 Enemy Prefab Updates ✅ COMPLETE
**Files**: `main/prefabs/enemies/*.go`

**Completed Changes**:
- ✅ Orc1: HD = 1 (~12 HP, awards 2 XP)
- ✅ Orc2: HD = 2 (~26 HP, awards 6 XP)
- ✅ Orc3: HD = 3 (~36 HP, awards 12 XP)
- ✅ Removed old `health` property from all enemy prefabs

---

### 2.3 Constants Module ✅ COMPLETE
**File**: `main/scripts/modules/constants.lua`

**Added M20 Messages**:
```lua
M20 = {
  AWARD_XP = 'm20_award_xp',
  LEVEL_UP = 'm20_level_up',
  STAT_CHOICE = 'm20_stat_choice',
  ROLL_ATTACK = 'm20_roll_attack',
  ROLL_DAMAGE = 'm20_roll_damage',
  SAVING_THROW = 'm20_saving_throw',
  COMBAT_RESULT = 'm20_combat_result',
  UPDATE_STATS = 'm20_update_stats',
  GOLD_PICKUP = 'm20_gold_pickup',
  SHOP_OPEN = 'm20_shop_open',
  SHOP_CLOSE = 'm20_shop_close',
  BUY_ITEM = 'm20_buy_item',
  SELL_ITEM = 'm20_sell_item',
  EQUIP_ITEM = 'm20_equip_item',
  UNEQUIP_ITEM = 'm20_unequip_item',
  USE_CONSUMABLE = 'm20_use_consumable',
  SPELL_CAST = 'm20_spell_cast',
  SPELL_COST = 'm20_spell_cost'
}
```

---

## Phase 3: Magic System Integration ✅ COMPLETE

### 3.1 Spell HP Cost Integration ✅ COMPLETE
**Status**: Complete

**Implemented Features**:
1. ✅ Modified spell casting in `main/scripts/modules/skills.lua`:
   - Removed cooldown checks for spells (movement skills keep cooldowns)
   - Added HP cost checks using `magic.can_cast_spell()`
   - Deduct HP on cast using `magic.cast_spell()`
   - GUI updates HP display after each spell cast
2. ✅ Added HP cost overlays to all spell icons in GUI
3. ✅ Fixed input handling (added `action.pressed` checks to prevent multi-cast)

**CTF Spell HP Costs** (Implemented):
- Fireball (Magic Missile, 1st): 3 HP
- Ice Barrage (Hold Person, 2nd): 5 HP
- Thunderclap (Gust of Wind, 2nd): 5 HP
- Windwalk (Invisibility, 1st): 3 HP

**Note**: Signature spell selection system not yet implemented (future enhancement)

---

### 3.2 Spell DC & Resistance ⏸️ PENDING
**Status**: Not Started (Optional Enhancement)

**Implementation Plan**:
1. Modify `one_time_buff_applier.script`:
   - Add saving throw checks before applying buffs
   - Use `dice.saving_throw()` for enemy resistance
   - Display "Resisted!" floating text on success
2. Update buff application logic with spell DC

---

## Phase 4: Enemy Improvements ⏸️ PENDING

### 4.1 Enemy Prefab Updates
**Status**: Not Started

**Implementation Plan**:
1. Update all enemy prefabs with HD values:
   - Orc1: `hd = 1` (2 XP, ~12 HP with 2x multiplier)
   - Orc2: `hd = 2` (6 XP, ~26 HP)
   - Future enemies: Scale HD based on difficulty
2. Test balance with different HD values
3. Update spawner for wave progression

---

### 4.2 Totem Integration
**Status**: Not Started

**Implementation Plan**:
- Add M20 stats to totem.script
- Use M20 HP system for totem health
- Update GUI to display totem HP from M20 stats

---

## Phase 5: UI & Feedback ✅ MOSTLY COMPLETE

### 5.1 Class Selection UI ✅ COMPLETE
**Files**:
- `/main/gui/class_selection.gui` - Class selection screen UI
- `/main/gui/class_selection.gui_script` - Button handlers
- `/main/class_selection.collection` - Scene collection
- `/main/gui/proxy/class_selection.collectionproxy` - Proxy

**Completed Features**:
- ✅ Beautiful pixel art UI matching game aesthetic
- ✅ 4 class buttons: Fighter, Rogue, Mage, Cleric
- ✅ Class descriptions with stats and abilities
- ✅ Flows to Race Selection on class choice
- ✅ Integrated into main scene flow

---

### 5.2 Race Selection UI ✅ COMPLETE
**Files**:
- `/main/gui/race_selection.gui` - Race selection screen UI
- `/main/gui/race_selection.gui_script` - Button handlers
- `/main/race_selection.collection` - Scene collection
- `/main/gui/proxy/race_selection.collectionproxy` - Proxy

**Completed Features**:
- ✅ Beautiful pixel art UI matching game aesthetic
- ✅ 4 race buttons: Human, Elf, Dwarf, Halfling
- ✅ Race descriptions with stat bonuses
- ✅ Receives class from class_selection via message
- ✅ Sends both class + race to loader
- ✅ Flows to Level 1 on race choice

---

### 5.3 Stat Selection UI ✅ COMPLETE
**Files**:
- `/main/gui/stat_selection.gui` - Stat selection popup overlay
- `/main/gui/stat_selection.gui_script` - Button handlers
- Added to `/main/gui/gui.collection` - In-game HUD overlay

**Completed Features**:
- ✅ Popup overlay during gameplay
- ✅ Appears at levels 3, 6, 9, etc.
- ✅ 3 stat buttons: STR, DEX, MIND
- ✅ Descriptions of each stat's benefits
- ✅ Shows level-up bonuses (+1d6 HP, +1 all attacks, +1 all skills)
- ✅ Sends selected stat back to player
- ✅ Hides after selection

---

### 5.4 Scene Flow Integration ✅ COMPLETE
**Files**:
- `main/scripts/loader.script` - Scene loader with class/race storage
- `main/gui/start_gui.gui_script` - Start menu loads class_selection
- `main/main.collection` - All proxies added

**Completed Flow**:
1. ✅ Start Menu → Class Selection
2. ✅ Class Selection → Race Selection (with class stored)
3. ✅ Race Selection → Level 1 (with class + race stored)
4. ✅ Loader sends class/race to player on level load
5. ✅ Player reinitializes M20 stats with chosen values

---

### 5.5 HUD Enhancements ✅ COMPLETE
**Status**: Complete
**Files**:
- `main/gui/player_gui.gui` - GUI layout with M20 UI elements
- `main/gui/player_gui.gui_script` - Script with M20 stat update handlers

**Implemented Features**:
- ✅ XP bar with level indicator (displays "Lvl X" and XP progress)
- ✅ Display current/max HP numbers (format: "HP: 45/60")
- ✅ Display AC value (format: "AC\n14")
- ✅ Spell HP cost overlays on all spell icons (red text: "3HP" or "5HP")
- ✅ Real-time updates after spell casts, damage, XP gains, level-ups

---

### 5.4 Character Sheet UI
**Status**: Not Started
**Files**: `/main/gui/character_sheet.gui` + `.gui_script`

**Implementation Plan**:
1. Create character sheet screen (accessible via pause menu)
2. Display STR, DEX, MIND scores and bonuses
3. Display level, XP, HP, AC
4. Display class, skills, attack bonuses
5. Display equipment (when equipment system added)

---

### 5.5 Floating Combat Text
**Status**: Not Started
**Files**: `/main/prefabs/ui/floating_text.go` + `.script`

**Implementation Plan**:
1. Create floating text prefab
2. Spawn on combat events with dice roll results
3. Show: "d20: 18 + 5 = 23 (Hit!)"
4. Show damage: "1d8+3 = 7 damage"
5. Show resists: "Save successful! (15 vs DC 14)"

---

## Phase 6: Shop & Equipment System ⏸️ PENDING

### 6.1 Equipment Module
**Status**: Not Started
**File**: `/main/scripts/modules/m20_equipment.lua`

**Implementation Plan**:
- Equipment slots: armor, weapon, shield, consumables[]
- Functions: equip_item(), unequip_item(), use_consumable()
- AC/damage calculation from equipment

---

### 6.2 Shop System
**Status**: Not Started
**Files**:
- `/main/scripts/modules/m20_shop.lua` - Shop logic
- `/main/gui/shop.gui` + `.gui_script` - Shop UI
- `/main/prefabs/pickups/gold_coin.go` + `.script` - Gold drops

**Implementation Plan**:
1. Gold currency system (drops from enemies: 1d6 × HD gold)
2. Shop UI near totem with inventory categories
3. Buy/sell items with gold
4. Equipment from M20 rules (armor, weapons, shields)
5. Consumables (HP potions, scrolls)

---

## Phase 7: Balance & Testing ⏸️ PENDING

### 7.1 Wave Difficulty Tuning
**Status**: Not Started
**File**: `main/scripts/units/spawner.script`

**Implementation Plan**:
- Wave 1: 1 HD enemies (EL 1)
- Wave 2: Mix of 1-2 HD (EL 2-3)
- Wave 3: 2-3 HD (EL 3-4)
- Wave 4: 3-4 HD + special abilities (EL 5-6)
- Wave 5: Boss fight (5+ HD, elite stats)

---

### 7.2 Integration Testing
**Test Cases**:
1. ✅ XP award on enemy death
2. ✅ Level-up when XP threshold reached
3. ✅ HP gain on level-up
4. ⏸️ Stat increase every 3 levels
5. ⏸️ Class bonuses applied correctly
6. ⏸️ Spell HP costs deducted
7. ⏸️ Enemies resist spells based on saves
8. ⏸️ Combat uses M20 attack/damage rolls

---

## Design Decisions ✅ FINALIZED

### 1. Real-Time Combat
**Decision**: Auto-roll dice in background, show results as floating text
- Preserves action gameplay feel
- No combat pauses or slow-motion

### 2. Spell System
**Decision**: Pure M20 HP cost, no cooldowns
- HP cost = 1 + (2 × spell level)
- Signature spells cost -1 HP
- Players manage resources via HP potions from shop

### 3. Enemy HP Scaling
**Decision**: 2x multiplier for action gameplay
- 1 HD enemy: ~12 HP (survives 2-3 hits early game)
- Balances M20 turn-based values with real-time combat

### 4. Character Creation
**Decision**: Template stats for initial launch, custom rolling later
- Fighter: STR 16, DEX 12, MIND 10
- Rogue: STR 12, DEX 16, MIND 10
- Mage: STR 10, DEX 12, MIND 16
- Cleric: STR 12, DEX 14, MIND 14

### 5. Death Mechanics
**Decision**: Permadeath (game over on HP = 0)
- Consistent with current CTF behavior
- Revival mechanics can be added later

### 6. XP System
**Decision**: Quadratic formula HD² + HD for individual kills
- Rewards fighting tougher enemies exponentially
- Player reaches level 3-4 in typical session
- Level 1→2: 10 XP (~5 weak or ~2 medium enemies)

---

## Critical Files Reference

### ✅ Completed Files
1. ✅ `/main/scripts/modules/m20_attributes.lua` - Character stats
2. ✅ `/main/scripts/modules/m20_dice.lua` - Dice rolling
3. ✅ `/main/scripts/modules/m20_combat.lua` - Combat resolution
4. ✅ `/main/scripts/modules/m20_skills.lua` - 4-skill system
5. ✅ `/main/scripts/modules/m20_progression.lua` - XP & leveling
6. ✅ `/main/scripts/modules/m20_classes.lua` - Character classes
7. ✅ `/main/scripts/modules/m20_magic.lua` - Spell casting
8. ✅ `/main/scripts/modules/m20_spells.lua` - Spell database
9. ✅ `main/scripts/player.script` - M20 integration
10. ✅ `main/scripts/enemy-common.script` - M20 integration
11. ✅ `main/scripts/modules/constants.lua` - M20 messages

### ⏸️ Pending Files
1. ⏸️ `/main/scripts/modules/m20_equipment.lua` - Equipment system
2. ⏸️ `/main/scripts/modules/m20_shop.lua` - Shop logic
3. ⏸️ `/main/gui/character_sheet.gui` + `.gui_script` - Character sheet UI
4. ⏸️ `/main/gui/class_selection.gui` + `.gui_script` - Class selection UI
5. ⏸️ `/main/gui/shop.gui` + `.gui_script` - Shop UI
6. ⏸️ `/main/prefabs/ui/floating_text.go` + `.script` - Floating combat text
7. ⏸️ `/main/prefabs/pickups/gold_coin.go` + `.script` - Gold pickup
8. ⏸️ `main/scripts/totem.script` - M20 stats integration
9. ⏸️ `main/scripts/modules/skills.lua` - Spell HP cost integration
10. ⏸️ `main/scripts/skills/one_time_buff_applier.script` - Saving throws
11. ⏸️ `main/scripts/units/spawner.script` - Wave HD progression
12. ⏸️ `main/gui/player_gui.gui_script` - HUD enhancements

---

## Testing Strategy

### Manual Testing Checklist
- [ ] Create new game, verify player starts as Fighter with correct stats
- [ ] Kill enemy, verify XP award and console log
- [ ] Kill enough enemies to reach level 2, verify level-up
- [ ] Verify HP increase on level-up
- [ ] Verify GUI health bar updates correctly
- [ ] Take damage, verify M20 HP decreases correctly
- [ ] Reach 0 HP, verify game over

### Integration Testing (After UI Complete)
- [ ] Test class selection UI
- [ ] Test stat selection on level 3, 6, 9
- [ ] Test spell HP costs (when implemented)
- [ ] Test enemy saving throws (when implemented)
- [ ] Test shop system (when implemented)

---

## Next Session Action Items

**Immediate Tasks**:
1. **Test current integration**: Build and launch game, verify XP/level-up works
2. **Fix any runtime errors**: Check console for M20-related errors
3. **Begin Milestone 2 UI work**: Start with class selection or HUD enhancements
4. **Update enemy prefabs**: Add HD properties to existing enemies

**Questions to Resolve**:
- Should we add class selection UI first, or keep Fighter as default and add UI later?
- Do we want to enable stat selection on level-up, or keep auto-select for now?
- Should we start Milestone 3 (spell HP costs) before finishing Milestone 2 UI?

---

## References

- **M20 Rules**: [docs/Microlite20.pdf](docs/Microlite20.pdf)
- **CTF Codebase**: `/home/crewsycrews/gamedev/CTF/`
- **Defold Docs**: https://defold.com/manuals/
- **Lua 5.1 Reference**: https://www.lua.org/manual/5.1/

---

**Plan Version**: 5.0
**Created**: 2026-01-11
**Last Updated**: 2026-01-27
**Status**: ✅ **Milestone 3 Complete** - Full M20 integration with HP-based spell casting and complete HUD

## Changelog

### Version 5.0 (2026-01-27)
- ✅ **Milestone 3 marked complete**: HP-based spell casting and HUD enhancements fully implemented
- 🎮 **Spell HP Costs**: All 4 spells (fireball, ice_barrage, thunderclap, windwalk) use M20 HP costs (3 HP for level 1, 5 HP for level 2)
- 🎨 **HUD Complete**: HP text (current/max), XP bar, Level display, AC display, spell HP cost overlays
- ⚡ **Real-time Updates**: GUI updates after each spell cast, damage, XP gain, and level-up
- 🔧 **Input Fix**: Added `action.pressed` checks to prevent spell multi-casting
- 🎯 **Movement Skills**: Dash, jump, backward_dash retain cooldowns as intended (not HP-based)
- 📝 **Plan Updated**: Marked Phase 3 complete, Phase 5 mostly complete
- 🚀 **Next Steps**: Phase 4 (Enemy improvements, Totem integration) or additional features (Spell DC/Resistance, Floating Combat Text, Character Sheet)

### Version 4.0 (2026-01-12 - Evening Session)
- ✅ **Milestone 2 marked complete**: Full UI integration for character creation and progression
- 🎨 **Class Selection UI**: Complete screen with Fighter/Rogue/Mage/Cleric choice
- 🎨 **Race Selection UI**: Complete screen with Human/Elf/Dwarf/Halfling choice
- 🎨 **Stat Selection UI**: Popup overlay for level 3, 6, 9 stat increases
- 🔄 **Scene Flow**: Start Menu → Class → Race → Level 1 fully functional
- 🏗️ **Loader Integration**: Class/race storage and passing to player
- 👾 **Enemy Prefabs**: All 3 orc types updated with HD properties
- 📝 **Updated plan structure**: Separated UI sections, added completion status
- 🎮 **Next milestone**: HUD enhancements (XP bar, HP display, AC) and Spell HP costs

### Version 3.0 (2026-01-12 - Morning Session)
- ✅ **Milestone 1 marked complete**: All core M20 modules created
- ✅ **Milestone 2 partial complete**: Player and enemy scripts integrated
- 🔧 **Simplified health system**: Removed redundant properties, M20 stats are single source of truth
- 📊 **Updated XP formula documentation**: HD² + HD with detailed balancing rationale
- 📚 **Added spell database**: m20_spells.lua with 35+ spell definitions
- 📋 **Reorganized plan**: Clearer progress tracking with ✅/⏸️ status indicators
- 📄 **Copied to repo**: Plan now stored in `/CTF/M20_IMPLEMENTATION_PLAN.md`
- 📖 **Added PDF reference**: Microlite20.pdf copied to `/CTF/docs/`

### Version 2.0 (2026-01-11)
- ✅ **Design decisions finalized**
- ✨ **New Milestone 5**: Shop & Equipment System
- 📝 **Updated Milestone 3**: Removed cooldowns entirely, added signature spells
- ⏱️ **Timeline adjusted**: 7 milestones over 11 weeks
