# Arcade Hub

A collection of mini-games built with Godot 4.5 + GDScript.

## Project Structure
- core/ — autoload singletons (game_registry, currency_manager, save_manager, unlock_manager, scene_transition)
- hub/ — main menu and game browser
- games/ — each mini-game is a self-contained folder
- shared/ — reusable components (themes, audio, UI widgets)
- export/ — export presets and configs

## Adding a New Game
1. Copy games/_template/ to games/your_game/
2. Edit meta.json with game details
3. Build your game in game.tscn + game.gd
4. The hub auto-discovers it via GameRegistry

## meta.json Format
{id, name, description, icon, coin_rate, unlock_cost, tags, min_version}

## Conventions
- GDScript 4.x with typed variables
- Touch input: each game handles its own, shared helpers in core/
- Pause button: top-right, always present
- Back to hub: via pause menu only (no accidental exits)
- Coins: time_played_seconds × coin_rate × streak_multiplier
- All persistence via SaveManager (ConfigFile-based)

## GDScript Style
- Use snake_case for variables and functions
- Use PascalCase for classes and nodes
- Use UPPER_CASE for constants
- Prefer static typing: var x: int = 0
- Use signals for decoupled communication

## When writing GDScript
- Read .claude/docs/gdscript.md for language reference
- Read .claude/docs/quirks.md for known gotchas
