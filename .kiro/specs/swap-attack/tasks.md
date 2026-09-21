# Swap Attack — Implementation Tasks

> Tasks are ordered for incremental, verifiable delivery. Each task references the requirement(s) and design section(s) it satisfies.

---

## Phase 0 · Project Scaffold

### Task 0.1 — Initialize repository & remote ✅
- [x] `git init` in workspace root (skip if already initialized)
- [x] Add remote: `git remote add origin git@github.com:srichardchung/swap-attack.git`
- [x] Create `.gitignore` (node_modules, dist, .DS_Store)
- [x] Create initial `README.md`

**Acceptance criteria**:
- [x] `git remote -v` shows `origin git@github.com:srichardchung/swap-attack.git`
- [x] `.gitignore` exists and lists `node_modules/`, `dist/`, `.DS_Store`
- [x] `README.md` exists with at minimum a project title

### Task 0.2 — Configure build environment ✅
- [x] Create `package.json` with scripts (`dev`, `build`, `preview`) and dependencies (`phaser ^3.80.0`, `typescript ^5.4.0`, `vite ^5.2.0`)
- [x] Create `tsconfig.json` (ES2020 target, strict mode, bundler module resolution)
- [x] Create `vite.config.ts` (base `'./'`, port 3000, ES2020 build target)
- [x] Create `index.html` entry point pointing to `src/game/main.ts`
- [x] Run `npm install`

**Acceptance criteria**:
- [x] `npm install` exits 0 and `node_modules/phaser` exists
- [x] `npx tsc --version` prints `5.x.x` (actual: 5.9.3)
- [x] `vite.config.ts` compiles without errors (`npx tsc --noEmit` on it)
- [x] `index.html` contains `<script type="module" src="/src/game/main.ts">`
- [x] **Steering note**: no Angular, PrimeNG, Bootstrap, or NgRx packages appear in `package.json`

### Task 0.3 — Create source directory skeleton ✅
- [x] Create `src/game/constants.ts` with all constants from Design §8
- [x] Create `src/game/types.ts` with `BlockColor`, `Block`, `GridCell`, `GridData`, `CursorState`, `GameStateData` types
- [x] Create stub files (export an empty class or placeholder export): `src/game/main.ts`, `src/game/scenes/BootScene.ts`, `src/game/scenes/GameScene.ts`, `src/game/scenes/GameOverScene.ts`, `src/game/components/Grid.ts`, `src/game/components/Cursor.ts`, `src/game/components/BlockSprite.ts`, `src/game/components/HUD.ts`, `src/game/state/GameState.ts`
- [x] Create `public/assets/blocks/` and `public/assets/fonts/` directories (add `.gitkeep`)

**Acceptance criteria**:
- [x] `npx tsc --noEmit` exits 0 with no errors or warnings
- [x] All 9 stub files exist under `src/game/`
- [x] `constants.ts` exports every constant named in Design §8 with the correct type
- [x] `types.ts` exports `BlockColor` enum with 6 members, `Block` interface, `GridCell`, `GridData`, `CursorState`, `GameStateData`
- [x] Row 0 = top, row 11 = bottom throughout all types and constants (0-indexed, per steering)
- [x] `npm run build` exits 0 and produces `dist/index.html`

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
- [ ] Implement `initialize()`: fill rows 6–11 (0-indexed) with random `BlockColor` values, no three-in-a-row on initialization
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
- [ ] Before shifting, check if any cell in row 0 is non-null → if so, return `true` (Game Over)
- [ ] Shift all rows up by one (row 0 is discarded)
- [ ] Insert new random-color row at row 11 (bottom)
- [ ] Return `false` if no game-over condition
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
- [ ] `CHECK_MATCHES`: call `Grid.findMatches()`; if results → `markFlashing` + transition to `FLASHING`; else → `RISING`
- [ ] `FLASHING`: decrement `flashTimer` on all flashing blocks each frame; when all reach 0 → transition to `CLEARING`
- [ ] `CLEARING`: call `Grid.clearFlashing()` in this one-frame state, then immediately transition to `FALLING`
- [ ] `FALLING`: call `Grid.applyGravity()` every `FALL_STEP_MS`; when it returns `false` → transition to `CHECK_MATCHES` (chain reaction check)
- [ ] If `CHECK_MATCHES` after `FALLING` finds no matches → `setChain(1)` to reset, then transition to `RISING`
- [ ] `RISING`: advance rise progress; on full row rise → call `Grid.riseRow()`; if returns `true` → `GameState.setGameOver()` → `GameOverScene`; else → `IDLE`
- **Refs**: REQ-3.4 – REQ-3.7, Design §4.3

### Task 4.3 — Implement chain & combo scoring
- [ ] Track chain level across successive `CHECK_MATCHES → FALLING → CHECK_MATCHES` cycles
- [ ] Count blocks cleared per pass for combo multiplier: `Math.max(1, Math.floor(blockCount / 3))`
- [ ] Call `GameState.addScore`, `setChain`, `updateHighestCombo` with correct values
- [ ] Call `HUD.showChainLabel` when `chainLevel > 1`; call `HUD.showComboLabel` when `blockCount > 3`
- [ ] Reset chain by calling `setChain(1)` (not 0) when `FALLING → CHECK_MATCHES` finds no new matches
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
