# Swap Attack — Requirements

> **Engine**: Godot 4.7.2 · **Language**: GDScript · **Target**: Desktop (Windows / macOS / Linux)
> All row/column references are **0-indexed**: row 0 = top, row 11 = bottom, column 0 = left edge.

---

## Overview

Swap Attack is a desktop single-player puzzle game inspired by Tetris Attack / Panel de Pon. The player controls a horizontal 2×1 cursor on a vertically-scrolling playfield of coloured blocks. By swapping adjacent blocks the player forms horizontal or vertical matches of three or more same-coloured tiles, which clear and trigger cascading chains and combos that multiply the score.

---

## Functional Requirements

### REQ-1 · Playfield Grid

- **REQ-1.1** The playfield shall consist of a fixed **6-column × 12-row** grid.
- **REQ-1.2** The grid shall be rendered as a vertically-oriented play area; row 11 is the bottom active zone and row 0 is the top boundary.
- **REQ-1.3** Each cell shall hold exactly one block or be empty (`null`).
- **REQ-1.4** Blocks shall be assigned one of **6 distinct colours**: Red, Blue, Green, Yellow, Purple, Teal.
- **REQ-1.5** On game start the grid shall be initialised with a randomised configuration filling **rows 6–11** (bottom half); rows 0–5 shall be empty. No three-in-a-row shall exist in the initial layout.
- **REQ-1.6** New rows of blocks shall rise from below at a configurable speed (`RISE_SPEED_SEC`), pushing all existing blocks upward one row at a time.
- **REQ-1.7** The game shall end (Game Over) when any block occupies **row 0** at the moment a new row would be pushed in. `Grid.rise_row()` checks row 0 for occupancy **before** shifting; returns `true` if game over, `false` otherwise.

### REQ-2 · Cursor and Swapping

- **REQ-2.1** The player cursor shall span exactly **2 columns horizontally and 1 row vertically**.
- **REQ-2.2** The cursor shall be movable via the registered Input Map actions:
  - `ui_left` / `ui_right`: move one column (left cell clamped to `[0, COLS-2]` = `[0, 4]`).
  - `ui_up` / `ui_down`: move one row (clamped to `[0, ROWS-1]` = `[0, 11]`).
- **REQ-2.3** Pressing the `swap` input action shall swap the two cells under the cursor horizontally in `Grid.swap(row, col)`.
- **REQ-2.4** The swap shall be **instant**; no animation delay shall block the next input.
- **REQ-2.5** Swapping a block with an empty cell is a valid move; the block slides into the empty cell.
- **REQ-2.6** Swapping two empty cells is a **no-op** (no state change, no match scan triggered).

### REQ-3 · Match and Clear Logic

- **REQ-3.1** After every swap or gravity settle, `Grid.find_matches()` shall scan the entire grid.
- **REQ-3.2** A match is **3 or more consecutive same-coloured blocks** in a horizontal or vertical line.
- **REQ-3.3** Overlapping matches (e.g. an L-shape) shall all be collected into the same match set and cleared in one pass.
- **REQ-3.4** Matched blocks shall enter a **flash state** lasting `FLASH_DURATION` seconds (default 0.5 s) before being removed. The flash is driven by a timer in the scene state machine, not by per-block timers.
- **REQ-3.5** While blocks are flashing the cursor shall remain operable; the player may continue moving and queuing swaps.
- **REQ-3.6** After flashing blocks are removed (`Grid.clear_flashing()`), all floating blocks above cleared cells shall fall downward until they rest on a filled cell or row 11. Gravity is applied column-by-column via `Grid.apply_gravity()`.
- **REQ-3.7** After gravity settles, `find_matches()` runs again to detect chain reactions.

### REQ-4 · Combo and Chain Engine

- **REQ-4.1** A **Combo** is clearing more than 3 blocks in a single match pass. The combo **label** (`HUD.show_combo_label`) fires only when `block_count > 3`.
- **REQ-4.2** A **Chain** is a match triggered by blocks falling after a prior clear, without any player swap in between.
- **REQ-4.3** `chain_level` equals **1** for the first player-initiated clear. It is set to **2** immediately after that first clear so the first gravity-triggered chain reaction scores at level 2. Each subsequent reactive clear increments it by 1.
- **REQ-4.4** `chain_level` resets to **1** (never 0) when gravity settles and `find_matches()` returns empty. `GameState.set_chain(1)` is the reset call.
- **REQ-4.5** Score for each clear pass: `BASE_POINTS × block_count × combo_mult × chain_level`
  - `combo_mult = max(1, block_count / 3)` (integer floor).
  - `chain_level` starts at 1 for the first clear in any sequence.
- **REQ-4.6** `HUD.show_chain_label(level)` fires when `chain_level > 1`.
- **REQ-4.7** `HUD.show_combo_label(count)` fires when `block_count > 3`.

### REQ-5 · Score Tracker

- **REQ-5.1** `GameState` (Autoload) shall track: `score` (int), `chain_level` (int, min 1), `highest_combo` (int), `is_game_over` (bool).
- **REQ-5.2** Base score per cleared block: **10 points**.
- **REQ-5.3** Score formula: `BASE_POINTS × block_count × max(1, block_count / 3) × chain_level`.
- **REQ-5.4** The HUD shall display `score`, `chain_level`, and `highest_combo` in real time, updating whenever `GameState` emits `state_changed`.
- **REQ-5.5** On Game Over the final `score` and `highest_combo` shall be displayed on the Game Over screen with a **Restart** button.

---

## Non-Functional Requirements

- **NFR-1 · Performance**: The game shall run at a stable 60 fps on mid-range desktop hardware.
- **NFR-2 · Responsiveness**: Input polling occurs every `_process` frame; no input shall be dropped during flash or fall animations.
- **NFR-3 · Maintainability**: Grid state mutation lives in `Grid.gd`; scene orchestration and state-machine timing live in `GameScene.tscn`'s attached script; score state lives in `GameState.gd`.
- **NFR-4 · Signal-driven**: Cross-node communication uses Godot signals, not direct method calls across unrelated branches of the scene tree.
- **NFR-5 · No hard-coded input keys**: All player controls are defined in the Input Map (`project.godot`); scripts reference action names only.
- **NFR-6 · GDScript only**: All logic is written in GDScript. No C#, C++, or web-stack languages are used.

---

## Constraints and Assumptions

- Single-player, score-attack mode only; no multiplayer.
- All assets (block textures, fonts) are bundled locally under `assets/`; no CDN or internet dependency at runtime.
- Audio is out of scope for the initial spec; the architecture shall leave a placeholder `AudioManager.gd` autoload for future use.
- The remote repository is `git@github.com:srichardchung/swap-attack.git`.
- The engine is **Godot 4.7.2**; no Godot 3 compatibility is required.
