# Swap Attack — Requirements

## Overview

Swap Attack is a 2D tile-swapping puzzle game inspired by Tetris Attack / Panel de Pon. The player controls a horizontal 2×1 cursor on a vertically-scrolling playfield of colored blocks. By swapping adjacent blocks, the player forms horizontal or vertical matches of three or more same-colored tiles, which clear and trigger cascading chains and combos for score multipliers.

---

## Functional Requirements

### REQ-1 · Playfield Grid

- **REQ-1.1** The playfield shall consist of a fixed 6-column × 12-row grid of colored blocks.
- **REQ-1.2** The grid shall be rendered as a vertically-oriented play area with the bottom row being the active zone.
- **REQ-1.3** Each cell in the grid shall hold exactly one block or be empty.
- **REQ-1.4** Blocks shall be assigned one of 6 distinct colors (e.g., red, blue, green, yellow, purple, teal).
- **REQ-1.5** The grid shall be initialized with a randomized starting configuration of blocks occupying rows 7–12 (bottom half), with the top half empty.
- **REQ-1.6** New rows of blocks shall rise from the bottom of the playfield at a configurable speed, pushing existing blocks upward.
- **REQ-1.7** The game shall end (Game Over) when any block is pushed above row 1 (the top boundary).

### REQ-2 · Cursor & Swapping

- **REQ-2.1** The player cursor shall span exactly 2 columns horizontally and 1 row vertically.
- **REQ-2.2** The cursor shall be movable with arrow keys or WASD:
  - Left / Right: move cursor one column horizontally (clamped to columns 1–5 for the left cell).
  - Up / Down: move cursor one row vertically (clamped to rows 1–12).
- **REQ-2.3** Pressing the designated swap key (Space or X) shall swap the two blocks (or empty cells) currently under the cursor horizontally.
- **REQ-2.4** Swapping shall be instant; no animation delay shall block the next swap input.
- **REQ-2.5** Swapping an empty cell with a block shall be a valid move (the block slides into the empty cell).
- **REQ-2.6** Swapping two empty cells shall be a no-op (no state change).

### REQ-3 · Match & Clear Logic

- **REQ-3.1** After every swap or block drop, the system shall scan the entire grid for matches.
- **REQ-3.2** A match is defined as 3 or more consecutive same-colored blocks in a horizontal or vertical line.
- **REQ-3.3** Overlapping matches (e.g., an L-shape) shall all be cleared in the same pass.
- **REQ-3.4** Matched blocks shall enter a **flash** state lasting 500 ms before being removed.
- **REQ-3.5** While blocks are flashing, the cursor shall remain operable (the player may queue more swaps).
- **REQ-3.6** After flashing blocks are removed, all floating blocks above cleared cells shall fall downward one cell at a time until they rest on a solid surface or the grid floor.
- **REQ-3.7** After blocks finish falling, the match scan shall run again to detect chain reactions (see REQ-4).

### REQ-4 · Combo & Chain Engine

- **REQ-4.1** A **Combo** is defined as clearing more than 3 blocks in a single match pass (e.g., clearing 5 blocks at once = Combo ×2).
- **REQ-4.2** A **Chain** is defined as a match triggered by blocks falling after a prior clear, without any player swap in between.
- **REQ-4.3** The chain counter shall increment by 1 for each successive reactive clear.
- **REQ-4.4** The chain counter shall reset to 0 when blocks finish settling and no further matches are detected.
- **REQ-4.5** Score multipliers shall be applied as follows:
  - Combo multiplier: `floor(cleared_count / 3)`
  - Chain multiplier: `chain_level` (1× for first clear, 2× for first chain reaction, etc.)
- **REQ-4.6** Visual feedback (on-screen label) shall display the active chain level (e.g., "Chain ×2") while a chain is in progress.
- **REQ-4.7** Visual feedback shall display a combo indicator (e.g., "Combo ×3") when a multi-block clear occurs.

### REQ-5 · Score Tracker

- **REQ-5.1** The game shall maintain a global reactive state object tracking:
  - `score`: cumulative integer score for the current session.
  - `chainLevel`: current active chain counter (resets between chains).
  - `highestCombo`: the largest single-pass block clear recorded this session.
- **REQ-5.2** Base score per cleared block shall be 10 points.
- **REQ-5.3** Final score for a clear event: `base_score × block_count × combo_multiplier × chain_multiplier`.
- **REQ-5.4** The score, chain level, and highest combo shall be displayed in the game HUD in real time.
- **REQ-5.5** On Game Over, the final score shall be displayed on a results screen.

---

## Non-Functional Requirements

- **NFR-1 · Performance**: The game shall run at a stable 60 fps on modern desktop browsers (Chrome, Firefox, Safari).
- **NFR-2 · Responsiveness**: Input polling shall occur every frame; no input shall be dropped during flash/fall animations.
- **NFR-3 · Maintainability**: All game logic shall be separated from rendering concerns. Grid state manipulation shall live in `Grid.ts`, scene orchestration in `GameScene.ts`.
- **NFR-4 · Type Safety**: All public interfaces, data models, and function signatures shall be fully typed in TypeScript with no implicit `any`.
- **NFR-5 · Build**: The project shall build to a static bundle via Vite, with hot-module replacement enabled in development mode.
- **NFR-6 · Browser Compatibility**: The build target shall be `ES2020`+ with no IE11 support required.

---

## Constraints & Assumptions

- The initial release targets a single-player, score-attack mode only (no multiplayer).
- Asset loading (block sprites, UI fonts) shall use Phaser's built-in loader; no external CDN assets at runtime.
- Audio is out of scope for the initial spec but the architecture shall leave hooks for a future `AudioManager`.
- The remote repository is `git@github.com:srichardchung/swap-attack.git`.
