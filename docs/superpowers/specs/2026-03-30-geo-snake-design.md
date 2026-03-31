# Geo Snake — Design Spec

## Concept

A snake.io-style game on a large scrolling map with a geometric twist. Eat scattered food to grow longer. Your snake is made of geometric shapes that evolve through tiers as you eat — starting as triangles, then squares, pentagons, hexagons, etc. Each segment keeps the shape it was when eaten, so your snake becomes a visual timeline of your run. Game ends when you eat yourself, hit the wall, or clear the map.

Inspired by snake.io (free-roaming snake on a big map), hole.io/Donut County (satisfying growth progression), and Particle Mace (neon aesthetic, particle effects, juice).

## Map & Camera

- Large map, ~5x viewport in each direction (3600x6400 with 720-wide viewport). Tunable.
- Camera2D follows the snake head with light position smoothing.
- Map boundary is a visible colored line/wall. Hitting it = death (same as self-collision).
- Dark background with a subtle dot grid pattern so the player can feel movement.

## Snake Movement

- Snake moves continuously at a constant speed in the current direction.
- **Floating joystick:** touch anywhere to anchor joystick origin at that point. Drag to steer — snake turns toward the drag direction. Release = joystick disappears, snake continues in last direction.
- Joystick is a simple visual: transparent circle at touch origin, smaller filled circle at drag position.
- Snake body is a chain of segments that follow the head's path — smooth curves, not grid-locked. Each segment tracks the position history of the head and follows at segment-width intervals.

## Shape Evolution (Tiers)

Each segment keeps the shape/tier it was when the food was eaten. The head is always the current tier.

| Segments eaten | Shape    | Sides | Segment radius | Color  |
|----------------|----------|-------|----------------|--------|
| 0 (start)      | Triangle | 3     | 15px           | Cyan   |
| 10             | Square   | 4     | 18px           | Green  |
| 20             | Pentagon | 5     | 21px           | Yellow |
| 30             | Hexagon  | 6     | 24px           | Orange |
| 40             | Heptagon | 7     | 27px           | Red    |
| 50+            | Octagon  | 8     | 30px           | Purple |

- Segments grow slightly larger at each tier, which naturally increases self-collision difficulty as you progress.
- Shapes are drawn as filled polygons with a bright outline (1-2px).
- Head segment is slightly larger than body segments of the same tier (1.2x scale).

## Food / Collectibles

- ~120 food items scattered across the map at game start.
- Food does not respawn — finite supply, map can be cleared.
- Eating one adds a segment to the tail at the current tier.

### Food Shapes & Sizes

Food items are non-uniform, concave/irregular shapes to contrast with the snake's clean polygons:
- **Small:** rectangles, parallelograms, small stars (~10-15px). Available from the start.
- **Medium:** larger stars, crosses, irregular quadrilaterals (~20-30px). Appear mixed in with small.
- **Large:** big stars, elongated shapes (~35-45px). Scattered sparingly.

Each food item has a size value. The snake can eat food whose size is at or below its current tier radius + a grace margin (~30% larger than the snake's segment radius). This means:
- Triangle tier (15px radius): can eat food up to ~20px
- Square tier (18px radius): can eat food up to ~23px
- Pentagon tier (21px radius): can eat food up to ~27px
- ...and so on

Food that's too large to eat is drawn with a subtle lock/dim effect. As you tier up, previously locked food "unlocks" visually (brightens, maybe a subtle pulse). This creates the hole.io "oh NOW I can eat that" moment.

Larger food is worth more segments (small = 1, medium = 2, large = 3), so eating bigger things accelerates growth.

## Collision & End Conditions

- **Self-collision:** head overlaps any body segment = game over.
- **Wall collision:** head hits map boundary = game over.
- **Map cleared:** all food eaten = victory screen with bonus coins.
- Collision detection uses the snake head's radius against body segment radii (circle-circle overlap, simple and reliable for smooth-path snake).

## Coin Rewards

- Base: `segments_eaten * coin_rate` (coin_rate from meta.json, default 1.0).
- Map clear bonus: 2x multiplier on the base reward.
- Awarded on game end (death or victory).

## Visual Effects (Particle Mace inspiration)

- **Eat burst:** small particle explosion (8-12 particles) in the tier color when food is consumed.
- **Head trail:** subtle particle trail behind the snake head — small fading dots in the head's color.
- **Tier-up flash:** brief screen flash + larger particle burst when crossing a tier threshold (10, 20, 30...). Camera shake (small, ~3px, ~0.2s).
- **Death shatter:** on game over, all snake segments explode outward into particles. Satisfying destruction.
- Particles are simple: small colored circles/squares that fade out over 0.3-0.5s with velocity.

## Architecture

All files live in `games/snake/`:

- `game.gd` — extends BaseGame. Main game logic: spawning food, managing the snake, input handling, game state.
- `game.tscn` — scene with Camera2D, map background, UI overlay (score label, pause button).
- `snake.gd` — the snake entity. Manages the segment chain, movement, path history, growth, and self-collision detection.
- `joystick.gd` — floating joystick input handler. Emits direction vectors.
- `meta.json` — standard game metadata.

The snake manages its own segment array and draws them via `_draw()`. Food items are simple Node2D children. No physics engine needed — movement is manual, collision is circle-circle math.

## Controls Summary

| Input | Action |
|-------|--------|
| Touch + drag anywhere | Steer snake toward drag direction |
| Release touch | Snake continues in last direction |
| Arrow keys | Steer snake (desktop/browser fallback) |
| Pause button (top-right) | Opens pause menu |

## Hub Preview

A lightweight `preview.tscn` / `preview.gd` scene that shows a scripted demo of the snake game. Uses the same drawing/visual code as the real game but with a pre-scripted movement path and food spawning — no input handling. The hub card embeds this via SubViewport. This follows the pattern established for all games (see brad-richardson/arcade#1).

## Out of Scope (v1)

- Multiplayer / AI snakes.
- Power-ups or special abilities.
- Sound effects / music (can add later).
