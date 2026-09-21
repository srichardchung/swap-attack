# Swap Attack — Implementation Tasks

> Tasks are ordered for incremental, verifiable delivery. Each task references the requirement(s) and design section(s) it satisfies.

---

## Phase 0 · Project Scaffold

### Task 0.1 — Initialize repository & remote
- [ ] `git init` in workspace root
- [ ] Add remote: `git remote add origin git@github.com:srichardchung/swap-attack.git`
- [ ] Create `.gitignore` (node_modules, dist, .DS_Store)
- [ ] Create initial `README.md`

### Task 0.2 — Configure build environment
- [ ] Create `package.json` with scripts (`dev`, `build`, `preview`) and dependencies (`phaser ^3.80.0`, `typescript ^5.4.0`, `vite ^5.2.0`)
- [ ] Create `tsconfig.json` (ES2020 target, strict mode, bundler module resolution)
- [ ] Create `vite.config.ts` (base `'./'`, port 3000, ES2020 build target)
- [ ] Create `index.html` entry point pointing to `src/game/main.ts`
- [ ] Run `npm install` and verify `npm run dev` starts the dev server
- **Refs**: Design §7

### Task 0.3 — Create source directory skeleton
- [ ] Create `src/game/constants.ts` with all constants from Design §8
- [ ] Create `src/game/types.ts` with `BlockColor`, `Block`, `GridCell`, `GridData`, `CursorState`, `GameStateData` types
- [ ] Create empty placeholder files: `main.ts`, `scenes/BootScene.ts`, `scenes/GameScene.ts`, `scenes/GameOverScene.ts`, `components/Grid.ts`, `components/Cursor.ts`, `components/BlockSprite.ts`, `components/HUD.ts`, `state/GameState.ts`
- [ ] Confirm `tsc --noEmit` passes with no errors on the empty stubs
- **Refs**: Design §2, §3

---

## Phase 1 · Core Data Layer

### Task 1.1 — Implement `GameState`
- [ ] Implement `GameStateData` store with `score`, `chainLevel`, `highestCombo`, `isGameOver`
- [ ] Implement `addScore`, `setChain`, `updateHighestCombo`, `setGameOver` mutators
- [ ] Implement `onChange` subscriber pattern
- [ ] Write manual smoke test: instantiate, mutate, confirm listeners fire
- **Refs**: REQ-5.1, Design §4.5

### Task 1.2 — Implement `Grid` constructor & initialization
- [ ] Implement `GridData` 2D array construction (ROWS × COLS, all null)
- [ ] Implement `initialize()`: fill rows 6–11 with random `BlockColor` values, no three-in-a-row on initialization
- [ ] Expose `data` as readonly
- **Refs**: REQ-1.1 – REQ-1.5, Design §4.1

### Task 1.3 — Implement `Grid.swap()`
- [ ] Validate bounds (col must be ≤ COLS-2)
- [ ] Swap `data[row][col]` and `data[row][col+1]` in place
- [ ] Handle null ↔ Block and null ↔ null cases correctly
- **Refs**: REQ-2.3 – REQ-2.6, Design §4.1

### Task 1.4 — Implement `Grid.findMatches()`
- [ ] Horizontal pass: scan each row for runs of ≥ 3 same-color blocks
- [ ] Vertical pass: scan each column for runs of ≥ 3 same-color blocks
- [ ] Return deduped `CellCoord[]` union of both passes
- [ ] Ignore cells where `block.state !== 'idle'`
- **Refs**: REQ-3.1 – REQ-3.3, Design §4.1

### Task 1.5 — Implement flash/clear cycle on `Grid`
- [ ] `markFlashing(matches)`: set matched blocks' state to `'flashing'`, set `flashTimer = FLASH_DURATION`
- [ ] `clearFlashing()`: set all `'flashing'` cells to `null`
- **Refs**: REQ-3.4, REQ-3.6, Design §4.1

### Task 1.6 — Implement `Grid.applyGravity()`
- [ ] Bottom-up column scan: compact non-empty, non-flashing blocks downward
- [ ] Return `true` if any block moved, `false` otherwise
- **Refs**: REQ-3.6, Design §4.1

### Task 1.7 — Implement `Grid.riseRow()`
- [ ] Shift all rows up by one (row 0 is lost → Game Over trigger if occupied)
- [ ] Insert new random-color row at row 11
- [ ] Return boolean indicating whether game-over condition was triggered
- **Refs**: REQ-1.6, REQ-1.7, Design §4.1

---

## Phase 2 · Input & Cursor

### Task 2.1 — Implement `Cursor`
- [ ] Register arrow keys and WASD via `scene.input.keyboard.addKeys`
- [ ] Register Space / X as swap keys
- [ ] Implement key-repeat logic with `INPUT_DELAY_MS` / `INPUT_REPEAT_MS` timers
- [ ] Clamp position: col ∈ [0, COLS-2], row ∈ [0, ROWS-1]
- [ ] Emit a `'swap'` Phaser event when swap key is pressed
- **Refs**: REQ-2.1 – REQ-2.5, Design §4.2

---

## Phase 3 · Rendering

### Task 3.1 — Boot scene & asset loading (`BootScene.ts`)
- [ ] Load block sprite sheet (6 color frames + 1 flash frame) from `public/assets/blocks/`
- [ ] Load bitmap font from `public/assets/fonts/`
- [ ] Transition to `GameScene` on complete
- **Refs**: Design §6

### Task 3.2 — Implement `BlockSprite`
- [ ] Extend `Phaser.GameObjects.Sprite`
- [ ] Accept `BlockColor` and map to correct sprite frame
- [ ] Expose `playFlash()` method that switches to flash frame
- [ ] Expose `setEmpty()` that hides the sprite
- **Refs**: Design §4, REQ-3.4

### Task 3.3 — Implement `HUD`
- [ ] Extend `Phaser.GameObjects.Container`
- [ ] Display score, chain level, highest combo as Phaser Text objects
- [ ] Implement `bind(state: GameState)` to subscribe to state changes
- [ ] Implement `showChainLabel` and `showComboLabel` with tween pop-in/fade-out
- **Refs**: REQ-4.6, REQ-4.7, REQ-5.4, Design §4.4

---

## Phase 4 · Game Loop

### Task 4.1 — Wire `GameScene.create()`
- [ ] Instantiate `Grid`, `Cursor`, `GameState`, `HUD`
- [ ] Create `BlockSprite` pool (ROWS × COLS sprites) and position on canvas
- [ ] Place cursor graphics object
- [ ] Set initial scene state to `IDLE`
- **Refs**: Design §4.3, §9

### Task 4.2 — Implement `GameScene` state machine
- [ ] `IDLE`: poll cursor input; on swap event → call `Grid.swap()` → transition to `CHECK_MATCHES`
- [ ] `CHECK_MATCHES`: call `Grid.findMatches()`; if results → `markFlashing` + `FLASHING`; else → `RISING`
- [ ] `FLASHING`: count down `flashTimer` each frame; on all timers zero → `Grid.clearFlashing()` → `FALLING`
- [ ] `FALLING`: call `Grid.applyGravity()` on interval; when false returned → `CHECK_MATCHES` (chain check)
- [ ] `RISING`: advance rise progress; on full row rise → `Grid.riseRow()`; check game-over; return to `IDLE`
- **Refs**: REQ-3.4 – REQ-3.7, Design §4.3

### Task 4.3 — Implement chain & combo scoring
- [ ] Track chain level across successive `CHECK_MATCHES → FALLING → CHECK_MATCHES` cycles
- [ ] Count blocks cleared per pass for combo multiplier
- [ ] Call `GameState.addScore`, `setChain`, `updateHighestCombo` with correct values
- [ ] Call `HUD.showChainLabel` / `HUD.showComboLabel` on qualifying clears
- [ ] Reset `chainLevel` when `FALLING → CHECK_MATCHES` finds no new matches
- **Refs**: REQ-4.1 – REQ-4.5, Design §5

### Task 4.4 — Sync `BlockSprite` pool with `GridData`
- [ ] Every frame after state transitions, iterate `GridData` and update each `BlockSprite`
- [ ] Call `playFlash()` on newly-flashing blocks
- [ ] Call `setEmpty()` on cleared cells
- [ ] Update y-position for falling blocks using tween or lerp
- **Refs**: REQ-3.4, REQ-3.6

---

## Phase 5 · Game Over & Polish

### Task 5.1 — Implement `GameOverScene`
- [ ] Display final score from `GameState`
- [ ] Display highest combo
- [ ] Render a "Play Again" button that restarts `GameScene` with fresh state
- **Refs**: REQ-5.5, Design §6

### Task 5.2 — Rising speed progression
- [ ] Gradually decrease `RISE_SPEED_MS` as score increases (every 500 pts → reduce by 100 ms, floor 500 ms)
- **Refs**: REQ-1.6

### Task 5.3 — Production build & deployment prep
- [ ] Run `npm run build` and verify `dist/` output is correct
- [ ] Confirm no TypeScript errors (`tsc --noEmit`)
- [ ] Update `README.md` with setup and run instructions
- [ ] Commit all files and push initial commit to `git@github.com:srichardchung/swap-attack.git`
- **Refs**: NFR-5, Task 0.1

---

## Dependency Order Summary

```
0.1 → 0.2 → 0.3
0.3 → 1.1, 1.2
1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7
0.3 → 2.1
3.1 → 3.2 → 3.3
1.x + 2.1 + 3.x → 4.1 → 4.2 → 4.3 → 4.4
4.4 → 5.1 → 5.2 → 5.3
```
