# Swap Attack — Implementation Tasks

> **Engine**: Godot 4.7.2 · **Language**: GDScript
> Tasks are ordered for incremental, verifiable delivery. Complete acceptance checks before marking a task done.

---

## Phase 0 · Project Scaffold

### Task 0.1 — Create Godot project ✅ (infrastructure)
- [ ] Open Godot 4.7.2, create a new project in the repository root named `swap-attack`
- [ ] Confirm `project.godot` is created at repo root
- [ ] Set window size to 800 × 600 in Project Settings → Display → Window
- [ ] Set `Main.tscn` as the main scene in Project Settings → Application → Run

**Acceptance criteria**:
- `project.godot` exists at repo root and is committed
- Running the project opens an 800 × 600 window with no errors in the Output panel

### Task 0.2 — Configure Input Map
- [ ] Open Project Settings → Input Map
- [ ] Add actions: `ui_left`, `ui_right`, `ui_up`, `ui_down`, `swap`
- [ ] Bind Arrow keys + WASD to movement actions; Space + X to `swap`
- [ ] Save project (changes persist in `project.godot`)

**Acceptance criteria**:
- All 5 actions appear in the Input Map
- No script uses hard-coded `KEY_*` constants for player input
- **Refs**: NFR-5, Design §5

### Task 0.3 — Create directory structure and stub scenes
- [ ] Create `scenes/`, `scripts/`, `assets/sprites/`, `assets/fonts/` directories
- [ ] Create stub scenes: `Main.tscn`, `GameScene.tscn`, `Block.tscn`, `GameOverScene.tscn`
- [ ] Create stub scripts: `Constants.gd`, `GameState.gd`, `Grid.gd`, `Cursor.gd`, `Block.gd`, `HUD.gd`, `AudioManager.gd`
- [ ] Register `Constants`, `GameState`, `AudioManager` as Autoloads in Project Settings → Globals
- [ ] Add `.gitkeep` to `assets/sprites/` and `assets/fonts/`

**Acceptance criteria**:
- All listed files exist in the repository
- Running `Main.tscn` produces no script errors (stubs use `pass`)
- Three Autoloads (`Constants`, `GameState`, `AudioManager`) appear in Project Settings
- **Refs**: Design §2, §3

### Task 0.4 — Populate `Constants.gd`
- [ ] Define all constants from Design §4: `COLS`, `ROWS`, `BLOCK_PX`, `COLOR_COUNT`, `FLASH_DURATION`, `FALL_STEP_SEC`, `RISE_SPEED_SEC`, `BASE_POINTS`, `INPUT_DELAY_SEC`, `INPUT_REPEAT_SEC`
- [ ] Define layout constants: `CANVAS_W`, `CANVAS_H`, `HUD_HEIGHT`, `GRID_ORIGIN_X`, `GRID_ORIGIN_Y`
- [ ] Define `BlockColor` and `BlockState` enums

**Acceptance criteria**:
- `Constants.COLS == 6`, `Constants.ROWS == 12`
- `Constants.GRID_ORIGIN_X == 256`, `Constants.GRID_ORIGIN_Y == 80`
- `Constants.BlockColor` has exactly 6 members (RED, BLUE, GREEN, YELLOW, PURPLE, TEAL)
- No other script re-defines these values
- **Refs**: Design §3, §4

---

## Phase 1 · Core Data Layer

### Task 1.1 — Implement `GameState.gd`
- [ ] Declare fields: `score`, `chain_level` (min 1), `highest_combo`, `is_game_over`
- [ ] Implement `add_score`, `set_chain` (enforces min 1), `update_highest_combo`, `set_game_over`
- [ ] Emit `state_changed` signal after every mutation
- [ ] Implement `get_state()` returning a copy Dictionary

**Acceptance criteria**:
- Instantiate in Godot debugger; call `GameState.add_score(10)` → `GameState.score == 10`
- `GameState.set_chain(0)` → `GameState.chain_level == 1` (clamped)
- `state_changed` signal fires on each mutation
- **Refs**: REQ-5.1, Design §7.3

### Task 1.2 — Implement `Grid` constructor and `initialize()`
- [ ] Build `_data`: `Array[Array]` of size `ROWS × COLS`, all `null`
- [ ] `initialize()`: fill rows 6–11 (0-indexed) with random `BlockColor` values; reject any placement that creates a run of ≥ 3 same colour
- [ ] Expose `_data` as read-only via a `get_data()` method

**Acceptance criteria**:
- `grid.get_data().size() == 12`, `grid.get_data()[0].size() == 6`
- Rows 0–5 are all `null` after `initialize()`
- No horizontal or vertical run of ≥ 3 same colour exists in rows 6–11 after `initialize()`
- **Refs**: REQ-1.1 – REQ-1.5, Design §7.1

### Task 1.3 — Implement `Grid.swap()`
- [ ] Validate `col in [0, COLS-2]` and `row in [0, ROWS-1]`; reject out-of-bounds with `push_error`
- [ ] Swap `_data[row][col]` ↔ `_data[row][col+1]`
- [ ] If both cells are `null` (REQ-2.6): no-op, do not emit or trigger match scan

**Acceptance criteria**:
- After `grid.swap(11, 0)` two cells are exchanged
- Calling `swap(11, 5)` (col out of range) prints an error and leaves `_data` unchanged
- Swapping two null cells leaves `_data` unchanged
- **Refs**: REQ-2.3 – REQ-2.6, Design §7.1

### Task 1.4 — Implement `Grid.find_matches()`
- [ ] Horizontal pass: each row, left-to-right, runs of ≥ 3 same-colour `IDLE` blocks
- [ ] Vertical pass: each col, top-to-bottom, runs of ≥ 3 same-colour `IDLE` blocks
- [ ] Return deduplicated `Array` of `Vector2i(col, row)`

**Acceptance criteria**:
- A grid row with `[RED, RED, RED, null, null, null]` returns 3 coords
- An L-shaped match (shared cell) returns each coord exactly once
- Non-IDLE (FLASHING) cells are excluded from results
- **Refs**: REQ-3.1 – REQ-3.3, Design §7.1

### Task 1.5 — Implement flash and clear cycle on `Grid`
- [ ] `mark_flashing(coords)`: set `state = BlockState.FLASHING` for each coord
- [ ] `clear_flashing()`: set all `FLASHING` cells to `null`

**Acceptance criteria**:
- After `mark_flashing([Vector2i(0,11)])`, `_data[11][0].state == BlockState.FLASHING`
- After `clear_flashing()`, those cells are `null`
- **Refs**: REQ-3.4, REQ-3.6, Design §7.1

### Task 1.6 — Implement `Grid.apply_gravity()`
- [ ] Bottom-up write-pointer scan per column (see Design §7.1 algorithm)
- [ ] Skip `FLASHING` cells
- [ ] Return `true` if any block moved, `false` if board is settled

**Acceptance criteria**:
- A column `[null, RED, null, null, …, null]` after one call becomes `[…, null, null, RED]` at row 11
- Returns `false` when all blocks already rest on filled cells or row 11
- **Refs**: REQ-3.6, Design §7.1

### Task 1.7 — Implement `Grid.rise_row()`
- [ ] Check row 0: if any cell is non-null → return `true` (game over, no shift)
- [ ] Shift rows 0..10 up by one (row 0 is discarded, row 1 becomes row 0, etc.)
- [ ] Generate a new random-colour row at row 11
- [ ] Return `false` if no game-over condition

**Acceptance criteria**:
- With row 0 empty: after `rise_row()`, old row 1 data is now at row 0; row 11 has a new non-null row; returns `false`
- With row 0 occupied: returns `true` and `_data` is unchanged
- **Refs**: REQ-1.6, REQ-1.7, Design §7.1

---

## Phase 2 · Input and Cursor

### Task 2.1 — Implement `Cursor.gd`
- [ ] Track `row` and `col`; initialise to centre of grid (`row=5, col=2`)
- [ ] `_process(delta)`: poll `ui_left/right/up/down` with key-repeat (`INPUT_DELAY_SEC` / `INPUT_REPEAT_SEC`)
- [ ] Clamp `col` to `[0, COLS-2]`, `row` to `[0, ROWS-1]`
- [ ] On `swap` action just-pressed: emit `swap_requested(row, col)`
- [ ] On position change: emit `moved(row, col)`

**Acceptance criteria**:
- Holding `ui_right` moves cursor right once immediately, then repeats every `INPUT_REPEAT_SEC` ms after `INPUT_DELAY_SEC` ms
- Cursor cannot move left of col 0 or right of col 4 (COLS-2)
- `swap_requested` fires once per key press (not per frame)
- **Refs**: REQ-2.1 – REQ-2.5, Design §7.2

---

## Phase 3 · Rendering

### Task 3.1 — Create placeholder block assets
- [ ] Create 6 solid-colour 48×48 PNG images (one per `BlockColor`) and a flash-frame PNG; place in `assets/sprites/`
- [ ] Import into Godot; confirm no import errors

**Acceptance criteria**:
- All 7 PNGs appear in the FileSystem dock with no import errors
- **Refs**: Design §9

### Task 3.2 — Implement `Block.gd` and `Block.tscn`
- [ ] `Block.tscn`: `Node2D` root + `Sprite2D` child
- [ ] `set_color(c)`: assign the corresponding texture to `Sprite2D`
- [ ] `play_flash()`: switch texture to flash frame
- [ ] `set_empty()`: hide the `Sprite2D`

**Acceptance criteria**:
- Instantiating `Block.tscn` and calling `set_color(Constants.BlockColor.RED)` shows the red texture
- Calling `set_empty()` makes the node invisible
- **Refs**: REQ-3.4, Design §6.3

### Task 3.3 — Implement `HUD.gd`
- [ ] `bind(state_node)`: connect `GameState.state_changed` to `_on_state_changed`
- [ ] `_on_state_changed(data)`: update `ScoreLabel`, `HighComboLabel` text
- [ ] `show_chain_label(level)`: tween `ChainLabel` scale 0→1→0 over 0.6 s
- [ ] `show_combo_label(count)`: same tween for `ComboLabel`

**Acceptance criteria**:
- Calling `GameState.add_score(100)` causes `ScoreLabel` to update to "100" without any direct call from `GameScene`
- `show_chain_label(2)` animates `ChainLabel` visibility
- **Refs**: REQ-4.6, REQ-4.7, REQ-5.4, Design §7.4

---

## Phase 4 · Game Loop

### Task 4.1 — Wire `GameScene.tscn` and `create()`
- [ ] Add `Grid`, `CursorNode`, `HUD`, `FlashTimer`, `FallTimer`, `RiseTimer` nodes to `GameScene.tscn`
- [ ] In `_ready()`: call `Grid.initialize()`, `HUD.bind(GameState)`, connect `Cursor.swap_requested → _on_swap_requested`
- [ ] Instantiate one `Block.tscn` per cell (`ROWS × COLS = 72`) into `Grid` node; position each at `GRID_ORIGIN + Vector2(col*BLOCK_PX, row*BLOCK_PX)`
- [ ] Set initial `_scene_state = SceneState.IDLE`

**Acceptance criteria**:
- Running `GameScene.tscn` shows 72 block nodes with correct positions and colours matching `Grid._data`
- No script errors on startup
- **Refs**: Design §6.2, §7.5

### Task 4.2 — Implement `GameScene` state machine
- [ ] `IDLE`: on `swap_requested(row, col)` → `Grid.swap(row, col)` → `_scene_state = CHECK_MATCHES`
- [ ] `CHECK_MATCHES`: call `Grid.find_matches()`
  - Non-empty → `Grid.mark_flashing(matches)` → start `FlashTimer` → `FLASHING`
  - Empty → `GameState.set_chain(1)` → `_scene_state = RISING`
- [ ] `FLASHING`: on `FlashTimer.timeout` → `_scene_state = CLEARING`
- [ ] `CLEARING`: call `Grid.clear_flashing()` → start `FallTimer` → `_scene_state = FALLING`
- [ ] `FALLING`: on `FallTimer.timeout` → `Grid.apply_gravity()`
  - `true` → stay in `FALLING`
  - `false` → `_scene_state = CHECK_MATCHES` (chain check)
- [ ] `RISING`: on `RiseTimer.timeout` → `Grid.rise_row()`
  - `true` → `GameState.set_game_over()` → `_scene_state = GAME_OVER`
  - `false` → `_scene_state = IDLE`

**Acceptance criteria**:
- Manually creating a 3-in-a-row in `_data` then calling `_scene_state = CHECK_MATCHES` triggers flash → clear → gravity cycle
- After gravity the state returns to `CHECK_MATCHES` (chain check) before `RISING`
- **Refs**: REQ-3.1 – REQ-3.7, Design §7.5

### Task 4.3 — Chain and combo scoring
- [ ] Track `_current_chain: int = 1` in `GameScene.gd`
- [ ] On `CHECK_MATCHES` (from `FALLING` path): if matches found → `GameState.set_chain(_current_chain)` → `_current_chain += 1`; if no matches → `GameState.set_chain(1)` → `_current_chain = 1`
- [ ] Calculate `combo_mult = max(1, block_count / 3)` (integer division)
- [ ] Call `GameState.add_score(BASE_POINTS × block_count × combo_mult × chain_level)`
- [ ] Call `GameState.update_highest_combo(block_count)`
- [ ] Call `HUD.show_chain_label(chain_level)` when `chain_level > 1`
- [ ] Call `HUD.show_combo_label(block_count)` when `block_count > 3`

**Acceptance criteria**:
- Clearing 6 blocks on chain level 2 → score increases by 240 (`10×6×2×2`)
- Clearing 3 blocks → no combo label shown; chain label shown only if `chain_level > 1`
- `chain_level` never goes below 1
- **Refs**: REQ-4.1 – REQ-4.5, REQ-5.3, Design §8

### Task 4.4 — Sync `Block.tscn` pool with `Grid._data`
- [ ] After every state transition that mutates `_data`, iterate all cells and call `block_pool[row][col].set_color / play_flash / set_empty` to match `_data`
- [ ] Falling blocks: tween `Block` y-position from old row pixel to new row pixel over `FALL_STEP_SEC`

**Acceptance criteria**:
- Cleared cells show invisible block sprites
- Flashing cells show the flash texture for the duration of `FlashTimer`
- Blocks visibly fall to their new positions after clearing
- **Refs**: REQ-3.4, REQ-3.6

---

## Phase 5 · Game Over and Polish

### Task 5.1 — Implement `GameOverScene.tscn`
- [ ] Display `GameState.score` in `FinalScoreLabel`
- [ ] Display `GameState.highest_combo` in `HighComboLabel`
- [ ] `RestartButton.pressed` → `get_tree().change_scene_to_file("res://scenes/GameScene.tscn")` and reset `GameState`

**Acceptance criteria**:
- After a game-over condition, `GameScene` transitions to `GameOverScene`
- Score and highest combo displayed are correct
- Pressing Restart starts a fresh game with `score=0`, `chain_level=1`, `highest_combo=0`
- **Refs**: REQ-5.5, Design §6.4

### Task 5.2 — Rising speed progression
- [ ] Every 500 score points reduce `RiseTimer.wait_time` by 0.1 s; floor at 0.5 s
- [ ] Compute new wait time in `GameState`'s `add_score` or via a signal in `GameScene`

**Acceptance criteria**:
- At score 500, `RiseTimer.wait_time` decreases noticeably
- `RiseTimer.wait_time` never goes below 0.5 s
- **Refs**: REQ-1.6

### Task 5.3 — Final verification and commit
- [ ] Run the full game; play through a chain reaction to verify scoring
- [ ] Trigger game over; confirm transition to `GameOverScene` and restart works
- [ ] Confirm no GDScript errors in the Output panel
- [ ] Update `README.md` with Godot version, setup instructions, and how to run
- [ ] Commit and push to `git@github.com:srichardchung/swap-attack.git`

**Acceptance criteria**:
- Zero errors in Output panel during a full playthrough
- `README.md` contains Godot 4.7.2 setup instructions
- Git log shows a clean commit on `main`
- **Refs**: All NFRs

---

## Dependency Order Summary

```
0.1 → 0.2 → 0.3 → 0.4
0.4 → 1.1, 1.2
1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7
0.3 → 2.1
3.1 → 3.2 → 3.3
1.x + 2.1 + 3.x → 4.1 → 4.2 → 4.3 → 4.4
4.4 → 5.1 → 5.2 → 5.3
```
