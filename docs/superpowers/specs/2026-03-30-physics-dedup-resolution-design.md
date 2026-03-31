# Physics, Deduplication & Dynamic Resolution

## Summary

Three related improvements to the arcade hub:
1. Extract a `BaseGame` class to deduplicate meta.json parsing and coin awarding
2. Switch dodge's collision detection from manual AABB to Godot's Area2D physics
3. Replace hardcoded screen dimensions with dynamic viewport queries

## 1. BaseGame Class

**File:** `games/base_game.gd` (extends `Node2D`)

**Provides:**
- `time_played: float` — accumulated in `_process()`
- `coin_rate: float` — loaded from `meta.json`
- `meta: Dictionary` — full parsed meta.json contents
- `_load_meta() -> void` — parses `meta.json` from the scene's directory
- `award_coins() -> int` — computes `int(time_played * coin_rate)`, calls `CurrencyManager.add_coins()`, returns amount

**Impact:**
- `games/_template/game.gd` becomes a thin subclass of `BaseGame`
- `games/dodge/game.gd` extends `BaseGame`, calls `super._ready()` / `super._process(delta)`, uses `award_coins()` in `_game_over()`

## 2. Physics Collision (Dodge)

**Current:** Manual AABB rect intersection loop each frame via `_check_collisions()`.

**New:** Spawned blocks become `Area2D` nodes with a `CollisionShape2D` (60x60 RectangleShape2D). The player's existing `CharacterBody2D` + `CollisionShape2D` detects overlap via the Area2D's `body_entered` signal.

**Changes:**
- `_spawn_block()` creates `Area2D` + `CollisionShape2D` + `ColorRect` (instead of `Node2D` + `ColorRect`)
- Connect `body_entered` signal to `_on_block_hit()` on the game script
- Remove `_check_collisions()` entirely
- `_update_blocks()` still moves blocks by position (Area2D is for overlap detection only)
- Remove `BLOCK_SIZE` constant (shape size defined inline, visual size stays)

## 3. Dynamic Screen Resolution

**Project settings change:** Add `window/stretch/aspect="keep_width"` to `project.godot`. Width stays at 720, height adjusts to device aspect ratio.

**Code changes:**
- Remove `SCREEN_WIDTH` / `SCREEN_HEIGHT` constants from dodge
- Replace with `get_viewport_rect().size` queries:
  - Player clamping: `get_viewport_rect().size.x`
  - Block spawn x-range: `get_viewport_rect().size.x`
  - Block cleanup y-threshold: `get_viewport_rect().size.y`
  - Player start position: derive from viewport
- Background ColorRect in `game.tscn`: set to full-rect anchors so it fills any viewport height
