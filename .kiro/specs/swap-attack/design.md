# Swap Attack — Design

## 1. Technology Stack

| Concern | Choice | Rationale |
|---|---|---|
| Game framework | Phaser 3 | Mature HTML5 2D engine with scene lifecycle, input, asset loading, and rendering built-in |
| Language | TypeScript | Compile-time safety; aligns with NFR-4 |
| Build tool | Vite | Sub-second HMR, native ES-module dev server, straightforward static bundle output |
| Target runtime | Browser (Chrome/Firefox/Safari) | No install required; ES2020+ target |

---

## 2. Repository & Project Structure

```
swap-attack/
├── .kiro/
│   └── specs/swap-attack/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
├── public/
│   └── assets/
│       ├── blocks/          # Block sprite sheets (6 colors + flash frame)
│       └── fonts/           # Bitmap font for HUD
├── src/
│   ├── game/
│   │   ├── main.ts          # Phaser boot config & game entry point
│   │   ├── constants.ts     # Grid dimensions, colors, timing constants
│   │   ├── types.ts         # Shared TypeScript interfaces & enums
│   │   ├── scenes/
│   │   │   ├── BootScene.ts     # Asset preloading
│   │   │   ├── GameScene.ts     # Main game loop (preload → create → update)
│   │   │   └── GameOverScene.ts # Final score display
│   │   ├── components/
│   │   │   ├── Grid.ts          # Grid data model + match/clear/fall algorithms
│   │   │   ├── Cursor.ts        # Cursor state + input handling
│   │   │   ├── BlockSprite.ts   # Visual wrapper for a single block
│   │   │   └── HUD.ts           # Score / chain / combo display layer
│   │   └── state/
│   │       └── GameState.ts     # Reactive global state (score, chain, combo)
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

---

## 3. Data Models

### 3.1 BlockColor (enum)

```typescript
// src/game/types.ts
export enum BlockColor {
  Red    = 'red',
  Blue   = 'blue',
  Green  = 'green',
  Yellow = 'yellow',
  Purple = 'purple',
  Teal   = 'teal',
}
```

### 3.2 Block (interface)

```typescript
export interface Block {
  color: BlockColor;
  state: 'idle' | 'flashing' | 'falling' | 'empty';
  flashTimer: number;   // ms remaining in flash animation
}
```

### 3.3 GridCell

```typescript
export type GridCell = Block | null;   // null = empty cell
```

### 3.4 GridData

The canonical playfield is a 2D array:

```typescript
export type GridData = GridCell[][];   // [row][col], row 0 = top
```

Dimensions live in `constants.ts`:

```typescript
export const COLS = 6;
export const ROWS = 12;
```

### 3.5 CursorState

```typescript
export interface CursorState {
  row: number;   // 0-indexed, clamped [0, ROWS-1]
  col: number;   // 0-indexed, clamped [0, COLS-2]  (left cell of 2-wide cursor)
}
```

### 3.6 GameStateData

```typescript
export interface GameStateData {
  score: number;
  chainLevel: number;
  highestCombo: number;
  isGameOver: boolean;
}
```

---

## 4. Component Design

### 4.1 `Grid.ts`

Owns all grid mutation and match logic. Stateless pure functions where possible; mutable state is the `GridData` array only.

**Public API:**

```typescript
class Grid {
  readonly data: GridData;

  constructor(cols: number, rows: number);

  // Seed the bottom half with random colored blocks
  initialize(): void;

  // Swap the two cells at (row, col) and (row, col+1)
  swap(row: number, col: number): void;

  // Scan for matches; returns all matched cell coordinates
  findMatches(): CellCoord[];

  // Mark matched cells as 'flashing'; caller drives the timer
  markFlashing(matches: CellCoord[]): void;

  // Clear all cells currently in 'flashing' state
  clearFlashing(): void;

  // Apply gravity: drop all floating blocks one step; returns true if any block moved
  applyGravity(): boolean;

  // Add a new row at the bottom, shift everything up by one.
  // Returns true if row 0 was occupied before shifting (Game Over condition).
  riseRow(): boolean;
}

export interface CellCoord { row: number; col: number; }
```

#### Match Detection Algorithm

1. **Horizontal pass**: for each row, scan left-to-right collecting consecutive same-color runs. Any run ≥ 3 is added to the match set.
2. **Vertical pass**: for each column, scan top-to-bottom with the same logic.
3. Returns the **union** of all matched coordinates (deduped by `row,col` key).

#### Gravity Algorithm

Single-pass bottom-up scan per column:

```
for col in 0..COLS:
  write_ptr = ROWS - 1
  for row in ROWS-1..0:
    if grid[row][col] is not empty and not flashing:
      move block to grid[write_ptr][col]
      write_ptr--
  fill remaining rows above write_ptr with null
```

### 4.2 `Cursor.ts`

Wraps `CursorState` and wires Phaser keyboard input.

```typescript
class Cursor {
  state: CursorState;

  constructor(scene: Phaser.Scene);

  // Called every frame; polls key state and emits 'swap' event if action key pressed
  update(delta: number): void;

  // Returns current cursor position
  getPosition(): CursorState;
}
```

Key bindings registered via `scene.input.keyboard.addKeys`:

| Action | Keys |
|---|---|
| Move left | ← / A |
| Move right | → / D |
| Move up | ↑ / W |
| Move down | ↓ / S |
| Swap | Space / X |

Repeat rate: 150 ms initial delay, 80 ms repeat for held movement keys (implemented with per-key timers in `update`).

### 4.3 `GameScene.ts`

Orchestrates all subsystems. Implements the Phaser scene lifecycle.

**State machine inside GameScene:**

```
IDLE → (swap input) → CHECK_MATCHES
CHECK_MATCHES → (matches found) → FLASHING
CHECK_MATCHES → (no matches)    → RISING
FLASHING → (all flash timers reach 0) → CLEARING
CLEARING → (clearFlashing() called)   → FALLING
FALLING  → (applyGravity() = false)   → CHECK_MATCHES  ← chain reaction loop
FALLING  → (applyGravity() = false, CHECK_MATCHES finds nothing) → RISING
RISING   → (row fully risen) → IDLE
```

> **CLEARING** is a distinct one-frame state between FLASHING and FALLING. Its only job is to call `Grid.clearFlashing()` and immediately transition to FALLING. It exists so the flash-timer loop in FLASHING never also mutates the grid.

**`update(time, delta)` responsibilities:**
1. Drive the flash timer on all flashing blocks.
2. Advance gravity one step per `FALL_STEP_MS` (configurable, default 50 ms).
3. Poll `Cursor.update(delta)` and handle swap events.
4. Transition the scene state machine.

### 4.4 `HUD.ts`

A Phaser `GameObjects.Container` placed above the playfield. Subscribes to `GameState` changes and re-renders text objects.

```typescript
class HUD extends Phaser.GameObjects.Container {
  bind(state: GameState): void;   // registers onChange callbacks
  showChainLabel(level: number): void;   // animates "Chain ×N" label
  showComboLabel(count: number): void;   // animates "Combo ×N" label
}
```

### 4.5 `GameState.ts`

Lightweight reactive state — no external library.

```typescript
class GameState {
  private data: GameStateData;
  private listeners: Array<(data: GameStateData) => void>;

  get(): Readonly<GameStateData>;
  addScore(points: number): void;
  // Sets chainLevel. Minimum valid value is 1. Pass 1 to reset between chains.
  setChain(level: number): void;
  updateHighestCombo(count: number): void;
  setGameOver(): void;
  onChange(fn: (data: GameStateData) => void): void;
}
```

---

## 5. Scoring Formula

```
clearScore = BASE_POINTS * blockCount * comboMultiplier * chainMultiplier

where:
  BASE_POINTS       = 10
  blockCount        = number of blocks cleared in this pass
  comboMultiplier   = Math.max(1, Math.floor(blockCount / 3))   // always ≥ 1
  chainMultiplier   = chainLevel                                 // starts at 1 for the first clear
```

**Combo label rule**: `showComboLabel` fires only when `blockCount > 3` (i.e., `comboMultiplier ≥ 2`).

**Chain reset rule**: after `FALLING → CHECK_MATCHES` finds no new matches, call `setChain(1)` — not `setChain(0)`. `chainLevel = 0` is never a valid game state.

Example: 6 blocks cleared on a 2× chain reaction → `10 × 6 × 2 × 2 = 240 pts`

---

## 6. Scene Flow

```
main.ts
  └─ Phaser.Game
       ├─ BootScene    → preloads all assets → starts GameScene
       ├─ GameScene    → main loop
       └─ GameOverScene → final score, restart button
```

---

## 7. Build Configuration

### `vite.config.ts`

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',
  server: { port: 3000 },
  build: {
    outDir: 'dist',
    target: 'es2020',
  },
});
```

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noImplicitAny": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
```

### `package.json` (key fields)

```json
{
  "scripts": {
    "dev":   "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "phaser": "^3.80.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "vite": "^5.2.0"
  }
}
```

---

## 8. Key Constants (`constants.ts`)

```typescript
export const COLS             = 6;
export const ROWS             = 12;
export const BLOCK_SIZE       = 48;         // px per cell
export const COLORS           = 6;          // number of distinct block colors
export const FLASH_DURATION   = 500;        // ms blocks flash before clearing
export const FALL_STEP_MS     = 50;         // ms per gravity tick
export const RISE_SPEED_MS    = 3000;       // ms per row rise (normal speed)
export const BASE_POINTS      = 10;
export const INPUT_DELAY_MS   = 150;        // initial key-repeat delay
export const INPUT_REPEAT_MS  = 80;         // subsequent key-repeat interval
```

---

## 9. Rendering Layout

```
┌─────────────────────────┐  ← 480 px wide canvas (800 × 600 default)
│  HUD: Score / Chain     │  (top 80 px)
├─────────────────────────┤
│                         │
│   6 × 12 Block Grid     │  (288 × 576 px  @  48 px/block)
│   centered horizontally │
│                         │
└─────────────────────────┘
```

Canvas: `800 × 600`. Grid origin: `x = (800 - 288) / 2 = 256`, `y = 80`.
