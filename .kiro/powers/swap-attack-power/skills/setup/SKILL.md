# Swap Attack — Project Setup Skill

## Purpose
This skill gives Kiro the context needed to scaffold, extend, and debug the Swap Attack Godot 4.7.2 project correctly from the first prompt.

## Stack
- **Engine**: Godot 4.7.2 (standard build — no Mono/C#)
- **Language**: GDScript only (`.gd` files)
- **Scene format**: `.tscn` / `.tres`
- **Target**: Desktop (Windows / macOS / Linux)

## Key project conventions

### File ownership
| Concern | File |
|---|---|
| Shared constants and enums | `scripts/Constants.gd` (Autoload) |
| Score / chain / combo state | `scripts/GameState.gd` (Autoload) |
| Grid data + match / gravity algorithms | `scripts/Grid.gd` |
| Player input + cursor movement | `scripts/Cursor.gd` |
| Per-block visual state | `scripts/Block.gd` |
| HUD display | `scripts/HUD.gd` |
| Scene transitions + state machine | `scenes/GameScene.tscn` attached script |

### Coordinate system
- Row 0 = **top** of the board; Row 11 = **bottom**
- Column 0 = left edge
- Cursor `col` = **left** cell of its 2-cell span; valid range `[0, 4]` (= `[0, COLS-2]`)

### Cross-node communication
Always use **signals** — never direct method calls across unrelated scene branches.
Key signals: `block_cleared`, `chain_updated`, `game_over`, `state_changed`, `swap_requested`, `moved`

### Input
Register all controls in the **Input Map** inside `project.godot`.
Action names: `ui_left`, `ui_right`, `ui_up`, `ui_down`, `swap`
Never hard-code `KEY_*` constants in scripts.

### Constants
Never define grid size, timing, or scoring values outside `Constants.gd`.
Key values: `COLS=6`, `ROWS=12`, `BLOCK_PX=48`, `BASE_POINTS=10`, `FLASH_DURATION=0.5`

## How to run
1. Open Godot 4.7.2 → Import → select `project.godot` at repo root
2. Press **F5** to run from `scenes/Main.tscn`
3. Arrow keys / WASD to move cursor; Space or X to swap
