# Microlite20 Integration Plan for Cosmic Tree Fighters

## Executive Summary

This plan outlines the integration of Microlite20 (M20) tabletop RPG rules into CTF. The goal is to add RPG depth (stats, progression, equipment, combat mechanics) while preserving real-time action gameplay.

**Reference**: [docs/Microlite20.pdf](docs/Microlite20.pdf)

---

## Implementation Status

**Current Status**: ✅ **Core M20 Complete**, ✅ **Shop POC Complete**

**Completed Work**:
- ✅ M20 core modules (attributes, dice, combat, skills, progression, classes, magic, spells)
- ✅ Player/Enemy M20 integration (stats, XP, leveling, HP system)
- ✅ Class/Race/Stat selection UI with scene flow
- ✅ HP-based spell casting (no cooldowns for spells)
- ✅ Full HUD (HP/XP/Level/AC, spell costs)
- ✅ Shop POC (UI, buy/sell logic, inventory display, gold system)

**Next Priority**: Weapon Attack Types & Equipment System

---

## Current Focus: Weapon Attack Types

### Overview
Implement M20-style weapon mechanics with different attack types (melee, ranged, magic) that modify player damage and use stat-based bonuses.

### Weapon Categories

**3 Core Weapons** (one per primary stat):

1. **Longsword** (STR-based, Melee)
   - Damage: 1d8 + STR bonus
   - Range: Short (melee hitbox)
   - Speed: Medium
   - Best for: Fighter class

2. **Longbow** (DEX-based, Ranged)
   - Damage: 1d8 + DEX bonus
   - Range: Long (projectile)
   - Speed: Medium
   - Best for: Rogue class

3. **Staff** (MIND-based, Magic)
   - Damage: 1d8 + MIND bonus
   - Range: Medium (spell projectile)
   - Speed: Medium
   - Best for: Mage/Cleric classes

### Implementation Plan

#### 1. Weapon Module (`m20_weapons.lua`)
**Status**: ✅ Complete

**Features to Implement**:
```lua
---@class Weapon
---@field id string Weapon identifier
---@field name string Display name
---@field damage_dice string Damage notation (e.g., "1d8")
---@field attack_type string "melee"|"ranged"|"magic"
---@field attack_stat string "STR"|"DEX"|"MIND"
---@field range number Attack range in pixels
---@field speed number Attack speed multiplier
---@field two_handed boolean Requires both hands

-- Core functions:
-- create_weapon(weapon_id) -> Weapon
-- get_weapon_damage(weapon, stats) -> number
-- get_weapon_attack_bonus(weapon, stats) -> number
-- can_use_weapon(class, weapon) -> boolean
```

**Weapon Database**:
- 3 weapons total (one per stat: STR, DEX, MIND)
- All deal 1d8 + stat bonus damage for balance
- Each weapon type plays differently (melee hitbox, ranged projectile, magic projectile)

#### 2. Player Attack Integration
**Status**: ✅ Complete

**Completed**:
- ✅ Updated [weapon_attacks.lua](main/scripts/modules/weapon_attacks.lua) to use simplified 3-weapon system
- ✅ Updated attack type fields from "behavior" to "attack_type"
- ✅ `skills.melee_attack()` already exists and calls weapon_attacks
- ✅ Player input already bound to "touch" for melee attacks
- ✅ M20 combat dice rolls integrated (d20 + attack bonus vs AC, damage dice + stat bonus)
- ✅ Player starts with no weapon (must purchase from shop)

**Attack System**:
- Uses `weapon_attacks.melee_attack()` for all weapon types
- Different visual effects planned for melee/ranged/magic (TODO: implement projectiles)
- Attack arc detection currently placeholder (TODO: implement physics queries)

#### 3. Equipment System Integration
**Status**: Partially Complete (Shop POC exists)

**Next Steps**:
- Add weapon slot to inventory system
- Equip/unequip weapons via shop or inventory UI
- Display equipped weapon in HUD
- Weapon stat bonuses apply to player stats
- Visual: Show equipped weapon on player sprite

#### 4. Combat Formula Integration
**Status**: Not Started

**Implementation**:
- Use `m20_combat.resolve_attack()` for weapon attacks
- d20 + attack bonus vs enemy AC
- On hit: roll weapon damage dice + stat bonus
- Display floating combat text (optional enhancement)

#### 5. Shop Weapon Inventory
**Status**: ✅ Complete

**Completed Features**:
- ✅ 3 weapons displayed in shop (Longsword, Longbow, Staff)
- ✅ Weapon stats shown (damage, stat bonus, special property)
- ✅ Buy weapons with gold (50g each)
- ✅ Button states update (BUY/EQUIPPED/grayed when can't afford)

---

## Completed Phases (Summary)

### Phase 1: Core M20 Systems ✅
**Files**: `m20_attributes.lua`, `m20_dice.lua`, `m20_combat.lua`, `m20_skills.lua`, `m20_progression.lua`, `m20_classes.lua`, `m20_magic.lua`, `m20_spells.lua`

**Key Features**:
- Stat bonus calculation: (stat - 10) / 2
- Dice rolling with d20 attack rolls and damage rolls
- 4 classes (Fighter, Rogue, Mage, Cleric) with bonuses
- XP formula: HD² + HD (enemy awards based on difficulty)
- HP-based spell casting: 1 + (2 × spell level) HP cost
- 35+ spell database from M20 rules

### Phase 2: Player & Enemy Integration ✅
**Files**: [player.script](main/scripts/player.script), [enemy-common.script](main/scripts/enemy-common.script)

**Key Features**:
- M20 stats as single source of truth for health
- XP awards on enemy death
- Automatic level-up with HP/skill increases
- Stat increases every 3 levels (player choice)

### Phase 3: Magic System ✅
**Key Features**:
- 4 spells mapped to M20 rules (Fireball=Magic Missile, Ice Barrage=Hold Person, etc.)
- HP costs deducted on cast (3 HP for level 1, 5 HP for level 2)
- Real-time HP bar updates
- Movement skills (dash, jump) retain cooldowns

### Phase 4: UI & Scene Flow ✅
**Files**: [class_selection.gui](main/gui/class_selection.gui), [race_selection.gui](main/gui/race_selection.gui), [stat_selection.gui](main/gui/stat_selection.gui), [player_gui.gui](main/gui/player_gui.gui)

**Key Features**:
- Scene flow: Start → Class → Race → Game
- In-game stat selection popup at levels 3, 6, 9
- HUD displays: HP text (current/max), XP bar, Level, AC, spell HP costs

### Phase 5: Shop System POC ✅
**Files**: [shop.gui](main/gui/shop.gui), shop logic in player script

**Key Features**:
- Shop UI with buy/sell tabs
- Gold currency system
- Inventory display
- Basic item transactions

---

## Future Enhancements (Lower Priority)

### Armor & Shields
- Light/Medium/Heavy armor (AC bonuses)
- Shields (+1 to +3 AC)
- Class restrictions (Mage can't wear armor)

### Consumables
- Health potions (restore HP)
- Stat boost potions (temp STR/DEX/MIND increase)
- Spell scrolls (cast spell without HP cost)

### Advanced Features
- Spell DC & Resistance (saving throws for enemies)
- Floating combat text (show dice rolls)
- Character sheet UI (full stat display)
- Totem M20 integration
- Wave difficulty progression (HD scaling)
- Equipment visual representation on sprites

---

## Design Decisions

### Combat Balance
- **2x HP Multiplier**: Enemies have double M20 HP for action gameplay feel
- **Real-time Auto-rolls**: Dice rolled in background, no combat pauses
- **Weapon Speed**: Fast weapons = more DPS, slow weapons = burst damage

### Equipment Philosophy
- **Simple Slot System**: Weapon, Armor, Shield, 3 Consumable slots
- **No Durability**: Weapons don't break (reduces micromanagement)
- **Level Gates**: Powerful weapons require minimum level

### Progression Curve
- **XP Formula**: HD² + HD keeps progression moderate
- **Level 1→2**: ~10 XP (~5 weak enemies or 2 medium)
- **Level 5+**: Requires fighting tougher enemies for efficient leveling

---

## Critical Files Reference

### ✅ Completed
1. `/main/scripts/modules/m20_*.lua` - All 8 M20 modules
2. [player.script](main/scripts/player.script) - M20 integration
3. [enemy-common.script](main/scripts/enemy-common.script) - M20 integration
4. [constants.lua](main/scripts/modules/constants.lua) - M20 messages
5. All selection UI files (class, race, stat)
6. [player_gui.gui](main/gui/player_gui.gui) + script - Enhanced HUD
7. [shop.gui](main/gui/shop.gui) + script - Shop POC

### 🎯 Next to Create/Modify
1. `/main/scripts/modules/m20_weapons.lua` - Weapon system (NEW)
2. `/main/scripts/modules/m20_equipment.lua` - Equipment slots (NEW)
3. [skills.lua](main/scripts/modules/skills.lua) - Add weapon attack skill
4. [player.script](main/scripts/player.script) - Weapon equip/attack logic
5. Shop script - Add weapon inventory items

---

## Next Session Action Items

**Completed Tasks**:
1. ✅ Review shop POC implementation
2. ✅ Design weapon database (3 weapons: Longsword/Longbow/Staff)
3. ✅ Simplify `m20_weapons.lua` module to 3 weapon definitions
4. ✅ Add weapon items to shop GUI
5. ✅ Update weapon attack system for new 3-weapon model
6. ✅ Connect player input to weapon attacks ("touch" binding)

**Next Tasks**:
1. ✅ Weapon purchase handler exists in player.script
2. 🎯 **Build and test the game!** Verify shop → purchase → equip workflow
3. 🎯 Create weapon attack projectiles/hitboxes for visual feedback (enhancement)
4. 🎯 Implement physics-based enemy detection for attacks (enhancement)

**Known Limitations** (to be addressed later):
- Enemy detection in `weapon_attacks.lua` is currently a placeholder (returns empty list)
- No visual projectiles/effects for weapon attacks yet
- All weapons use fixed 60° attack arc

**Testing Checklist**:
- [ ] Equip weapon from shop
- [ ] Perform weapon attack with correct damage calculation
- [ ] Verify STR/DEX/MIND bonuses apply correctly
- [ ] Test different weapon types (melee, ranged, magic)
- [ ] Verify weapon requirements (level, class)

---

**Plan Version**: 6.0
**Last Updated**: 2026-01-30
**Status**: ✅ **Core M20 + Shop POC Complete** | 🎯 **Focus: Weapon Attack Types**

## Changelog

### Version 6.0 (2026-01-30)
- ✅ **Shop POC marked complete**: UI and basic transaction logic implemented
- 🎯 **New focus**: Weapon Attack Types & Equipment System
- 📉 **Plan condensed**: Removed excessive detail from completed phases
- 🗡️ **Weapon design**: 3 attack types (melee/ranged/magic), stat-based damage, 15 weapon database
- 📋 **Simplified structure**: Focused on active work, archived completed details
