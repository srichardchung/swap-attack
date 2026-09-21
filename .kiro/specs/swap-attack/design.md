# Swap Attack — Design

> **Engine**: Godot 4.7.2 · **Language**: GDScript
> Row 0 = top, row 11 = bottom, column 0 = left edge (0-indexed throughout).

---

## 1. Technology Stack

| Concern | Choice | Rationale |
|---|---|---|
| Engine | Godot 4.7.2 | Built-in 2D renderer, scene tree, input system, signals, and export pipeline — no additional runtime dependencies |
| Language | GDScript | Native Godot scripting; hot-reload in editor; no compile step |
| Scene format | `.tscn` (text scenes) + `.tres` (resources) | Human-readable, diff-friendly, version-control friendly |
| Export | Godot export presets | Desktop (Windows / macOS / Linux); one-click build from editor |

---

## 2. Repository and Project Layout

```
swap-attack/
├── project.godot              ← Godot project file; sets Main.tscn as entry scene
│                                and declares all Input Map actions
├── scenes/
│   ├── Main.tscn              ← thin root scene; loads GameScene on start
│   ├── GameScene.tscn         ← main play field (Grid, Cursor, HUD, timer nodes)
│   ├── Block.tscn             ← single reusable block node (Sprite2D + Label)
│   └── GameOverScene.tscn     ← final score and restart UI
├── scripts/
│   ├── Constants.gd           ← Autoload: all shared numeric constants
│   ├── GameState.gd           ← Autoload: reactive score / chain / combo state
│   ├── Grid.gd                ← board data array + match / clear / gravity logic
│   ├── Cursor.gd              ← cursor position + key-repeat input handling
│   ├── Block.gd               ← per-block visual state (colour, flash, fall tween)
│   ├── HUD.gd                 ← score / chain / combo Label nodes
│   └── AudioManager.gd        ← Autoload stub (audio out of scope for Phase 0)
├── assets/
│   ├── sprites/               ← 6 colour PNGs + flash-frame PNG
│   └── fonts/                 ← .ttf or bitmap font for HUD
└── README.md
```

---

## 3. Data Model (GDScript)

### 3.1 Block colours

Defined in `Constants.gd`:

```gdscript
enum BlockColor { RED, BLUE, GREEN, YELLOW, PURPLE, TEAL }
const COLOR_COUNT := 6
const ALL_COLORS := [
    BlockColor.RED, BlockColor.BLUE, BlockColor.GREEN,
    BlockColor.YELLOW, BlockColor.PURPLE, BlockColor.TEAL
]
```

### 3.2 Block state

```gdscript
enum BlockState { IDLE, FLASHING, FALLING, EMPTY }
```

### 3.3 Grid cell dictionary

Each cell in `Grid._data` is either `null` (empty) or a `Dictionary`:

```gdscript
# Example occupied cell
{
    "color": BlockColor.RED,   # int enum value
    "state": BlockState.IDLE,  # int enum value
}
```

### 3.4 Grid data array

```gdscript
# Grid._data: Array[Array]  — _data[row][col]
# row 0 = top, row ROWS-1 = bottom
# col 0 = left, col COLS-1 = right
```

Dimensions in `Constants.gd`:

```gdscript
const COLS := 6
const ROWS := 12
```

### 3.5 Cursor state

Stored inside `Cursor.gd`:

```gdscript
var row: int  # clamped [0, ROWS-1]
var col: int  # clamped [0, COLS-2]  — left cell of 2-wide span
```

### 3.6 GameState fields (Autoload)

```gdscript
var score:         int  = 0
var chain_level:   int  = 1   # minimum valid value is 1
var highest_combo: int  = 0
var is_game_over:  bool = false
```

### 3.7 CellCoord helper

```gdscript
# Used as a lightweight value type — passed as Dictionary or Vector2i
# { "row": int, "col": int }
# or equivalently Vector2i(col, row) where x=col, y=row
```

Design uses `Vector2i(col, row)` throughout for compactness.

### 3.8 SceneState enum

Defined in `GameScene.gd`:

```gdscript
enum SceneState {
    IDLE,
    CHECK_MATCHES,
    FLASHING,
    CLEARING,      # one-frame state: calls clear_flashing(), then → FALLING
    FALLING,
    RISING,
    GAME_OVER
}
```

---

## 4. Constants (`Constants.gd` Autoload)

```gdscript
const COLS             := 6
const ROWS             := 12
const BLOCK_PX         := 48        # pixel size of one cell
const COLOR_COUNT      := 6
const FLASH_DURATION   := 0.5       # seconds blocks flash before clearing
const FALL_STEP_SEC    := 0.05      # seconds per gravity tick
const RISE_SPEED_SEC   := 3.0       # seconds per full row rise (normal speed)
const BASE_POINTS      := 10
const INPUT_DELAY_SEC  := 0.15      # initial key-repeat delay
const INPUT_REPEAT_SEC := 0.08      # subsequent key-repeat interval
```

Derived layout (also in `Constants.gd`):

```gdscript
const CANVAS_W         := 800
# CANVAS_H = HUD_HEIGHT + ROWS * BLOCK_PX = 80 + 12 * 48 = 656
const CANVAS_H         := 656
const HUD_HEIGHT       := 80
const GRID_ORIGIN_X    := (CANVAS_W - COLS * BLOCK_PX) / 2   # = 256
const GRID_ORIGIN_Y    := HUD_HEIGHT                          # = 80
```

---

## 5. Input Map (`project.godot`)

| Action name | Default keys |
|---|---|
| `ui_left`   | Arrow Left, A |
| `ui_right`  | Arrow Right, D |
| `ui_up`     | Arrow Up, W |
| `ui_down`   | Arrow Down, S |
| `swap`      | Space, X |

Scripts reference these action names only via `Input.is_action_just_pressed("swap")` etc.

---

## 6. Scene Design

### 6.1 `Main.tscn`

Minimal root scene. On `_ready()` calls `get_tree().change_scene_to_file("res://scenes/GameScene.tscn")`.

### 6.2 `GameScene.tscn` — node hierarchy

```
GameScene (Node2D)
├── Grid          (Node2D)  ← attach Grid.gd; owns _data array + block sprites
├── CursorNode    (Node2D)  ← attach Cursor.gd; draws the 2-cell highlight rect
├── HUD           (CanvasLayer)
│   └── HUDScript (attach HUD.gd)
│       ├── ScoreLabel       (Label)
│       ├── ChainLabel       (Label)
│       ├── ComboLabel       (Label)
│       └── HighComboLabel   (Label)
├── FlashTimer    (Timer)   ← one-shot; duration = FLASH_DURATION
├── FallTimer     (Timer)   ← repeating; wait_time = FALL_STEP_SEC
└── RiseTimer     (Timer)   ← repeating; wait_time = RISE_SPEED_SEC
```

### 6.3 `Block.tscn` — node hierarchy

```
Block (Node2D)
├── Sprite2D      ← displays colour or flash texture
└── (no children required for Phase 1)
```

`Block.gd` exposes:

```gdscript
func set_color(c: int) -> void    # BlockColor enum value
func play_flash() -> void         # switches to flash texture
func set_empty() -> void          # hides sprite
```

### 6.4 `GameOverScene.tscn`

```
GameOverScene (Control)
├── FinalScoreLabel  (Label)
├── HighComboLabel   (Label)
└── RestartButton    (Button) ← on pressed: change_scene GameScene
```

---

## 7. Script Design

### 7.1 `Grid.gd`

Owns `_data: Array[Array]` and all mutation logic. Emits signals to `GameScene`.

**Signals**:
```gdscript
signal matches_found(coords: Array)   # Array of Vector2i(col,row)
signal gravity_settled                # emitted when apply_gravity() moves nothing
signal row_risen(game_over: bool)     # emitted after rise_row()
```

**Public API**:
```gdscript
func initialize() -> void
    # Fill rows 6–11 with random colours; no 3-in-a-row on init.

func swap(row: int, col: int) -> void
    # Swap _data[row][col] ↔ _data[row][col+1].
    # Validates: col in [0, COLS-2]; row in [0, ROWS-1].
    # No-op if both cells are null (REQ-2.6).

func find_matches() -> Array:
    # Returns Array of Vector2i(col,row) — deduplicated union of
    # horizontal and vertical runs of ≥ 3 same-colour IDLE blocks.

func mark_flashing(coords: Array) -> void
    # Set state = FLASHING for each coord in coords.

func clear_flashing() -> void
    # Set all FLASHING cells to null.

func apply_gravity() -> bool:
    # Bottom-up column scan: compact non-null, non-FLASHING blocks downward.
    # Returns true if any block moved, false if board is settled.

func rise_row() -> bool:
    # Check row 0 for any non-null cell → if found, return true (game over).
    # Otherwise shift all rows up by 1 and insert a new random row at row 11.
    # Returns false if no game-over condition.
```

**Match detection algorithm**:
1. Horizontal pass: for each row 0..11, scan left-to-right collecting consecutive same-colour `IDLE` runs. Any run ≥ 3 is added to the result set.
2. Vertical pass: for each col 0..5, scan top-to-bottom with the same logic.
3. Return the **deduplicated union** (use a `Dictionary` keyed by `Vector2i` for O(1) dedup).

**Gravity algorithm** — moves each floating block **one cell downward per call**. `FallTimer` fires repeatedly at `FALL_STEP_SEC`; one call per tick produces the visible one-cell-at-a-time fall animation.

```
moved = false
for col in 0..COLS-1:
    # scan from second-to-bottom row upward
    for row in ROWS-2 down to 0:
        if _data[row][col] != null and _data[row][col].state != FLASHING:
            if _data[row + 1][col] == null:
                _data[row + 1][col] = _data[row][col]
                _data[row][col] = null
                moved = true
return moved
```

Each call moves every unsupported block exactly one row down. The `FallTimer` keeps firing until `apply_gravity()` returns `false` (all blocks have settled).

### 7.2 `Cursor.gd`

Attached to `CursorNode`. Handles key-repeat and emits `swap_requested`.

**Signals**:
```gdscript
signal swap_requested(row: int, col: int)
signal moved(row: int, col: int)
```

**Key-repeat logic**: per-action timers `_delay_left`, `_repeat_left`; initialised to `INPUT_DELAY_SEC` on first press, then fires every `INPUT_REPEAT_SEC` while held.

### 7.3 `GameState.gd` (Autoload)

Lightweight reactive store. All mutators emit `state_changed`.

```gdscript
signal state_changed(data: Dictionary)

func add_score(points: int) -> void
func set_chain(level: int) -> void   # enforces minimum of 1
func update_highest_combo(count: int) -> void
func set_game_over() -> void
func get_state() -> Dictionary       # returns a copy of all fields
```

### 7.4 `HUD.gd`

Subscribes to `GameState.state_changed` in `_ready()`.

```gdscript
func bind(state_node: Node) -> void      # connects state_changed signal
func show_chain_label(level: int) -> void  # tween pop-in / fade-out
func show_combo_label(count: int) -> void
```

### 7.5 `GameScene.gd` (attached to `GameScene.tscn`)

Drives the `SceneState` machine. All state transitions happen here.

**State machine**:

```
IDLE
  └─ on swap_requested  → Grid.swap() → CHECK_MATCHES

CHECK_MATCHES
  ├─ find_matches() returns non-empty → mark_flashing() → start FlashTimer → FLASHING
  └─ find_matches() returns empty     → GameState.set_chain(1) → RISING

FLASHING
  └─ FlashTimer.timeout → CLEARING

CLEARING  (one-frame state)
  └─ Grid.clear_flashing() → start FallTimer → FALLING

FALLING
  └─ FallTimer.timeout → Grid.apply_gravity()
      ├─ moved = true  → stay in FALLING (timer auto-repeats)
      └─ moved = false → CHECK_MATCHES  (chain-reaction scan)

RISING
  └─ RiseTimer.timeout → Grid.rise_row()
      ├─ game_over = true  → GameState.set_game_over() → GAME_OVER
      └─ game_over = false → IDLE

GAME_OVER
  └─ (waits for input or auto-transition to GameOverScene)
```

> **CLEARING** is a distinct one-frame state so the flash-timer loop in **FLASHING** never also mutates the grid in the same frame.

**Chain tracking** inside `GameScene.gd`:

```gdscript
var _current_chain: int = 1

# On entering CHECK_MATCHES from IDLE (player swap path):
#   reset: _current_chain = 1
#   score this clear at chain_level = 1
#   then: _current_chain = 2  (so the NEXT reactive clear scores at level 2)

# On entering CHECK_MATCHES from FALLING (chain reaction path):
#   if matches found:
#     GameState.set_chain(_current_chain)   # _current_chain is already ≥ 2
#     score this clear at chain_level = _current_chain
#     _current_chain += 1                   # prepare next reaction level
#   if no matches:
#     GameState.set_chain(1)
#     _current_chain = 1
#     → go to RISING
```

**Decision recorded**: the first gravity-triggered chain reaction scores at `chain_level = 2`. This is achieved by setting `_current_chain = 2` immediately after the player-initiated clear (before any `FALLING` state), so when the first reactive `CHECK_MATCHES` runs it already holds 2.

---

## 8. Scoring Formula

```
clear_score = BASE_POINTS × block_count × combo_mult × chain_level

combo_mult  = max(1, block_count / 3)   # integer floor division
chain_level = GameState.chain_level      # 1 for first clear, 2 for first chain, …
```

Combo label fires when `block_count > 3` (i.e. `combo_mult ≥ 2`).
Chain label fires when `chain_level > 1`.

Example: 6 blocks cleared on a chain-level-2 reaction → `10 × 6 × 2 × 2 = 240 pts`.

---

## 9. Rendering Layout

```
┌─────────────────────────┐  800 px wide
│   HUD (CanvasLayer)     │  top 80 px
├─────────────────────────┤
│                         │
│   6 × 12 block grid     │  288 × 576 px  (@48 px/block)
│   centred horizontally  │  origin (256, 80)
│                         │
└─────────────────────────┘  656 px tall  (80 HUD + 12×48 grid)
```

> **Window size decision**: `CANVAS_H = 656`, not 600. `HUD_HEIGHT (80) + ROWS × BLOCK_PX (576) = 656`. A 600 px window would clip the bottom two rows of the grid.

Block pixel position: `Vector2(GRID_ORIGIN_X + col * BLOCK_PX, GRID_ORIGIN_Y + row * BLOCK_PX)`.
