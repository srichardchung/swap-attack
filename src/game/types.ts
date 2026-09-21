// ---------------------------------------------------------------------------
// Swap Attack — shared TypeScript types
// Row 0 = top, row 11 = bottom (0-indexed throughout).
// ---------------------------------------------------------------------------

/** The six possible block colors. */
export enum BlockColor {
  Red    = 'red',
  Blue   = 'blue',
  Green  = 'green',
  Yellow = 'yellow',
  Purple = 'purple',
  Teal   = 'teal',
}

/** All colors as a lookup array, used for random selection. */
export const ALL_COLORS: BlockColor[] = [
  BlockColor.Red,
  BlockColor.Blue,
  BlockColor.Green,
  BlockColor.Yellow,
  BlockColor.Purple,
  BlockColor.Teal,
];

/** Lifecycle state of a single block. */
export type BlockState = 'idle' | 'flashing' | 'falling' | 'empty';

/** A single colored block on the grid. */
export interface Block {
  color: BlockColor;
  state: BlockState;
  /** Milliseconds remaining in the flash animation (only meaningful when state === 'flashing'). */
  flashTimer: number;
}

/** One cell in the grid — either a Block or null (empty). */
export type GridCell = Block | null;

/**
 * The canonical 2-D playfield: data[row][col].
 * row 0 = top of the screen, row (ROWS-1) = bottom.
 */
export type GridData = GridCell[][];

/**
 * The cursor position — identifies the LEFT cell of its 2-wide span.
 * col ∈ [0, COLS-2], row ∈ [0, ROWS-1].
 */
export interface CursorState {
  row: number;
  col: number;
}

/** A discrete grid coordinate. */
export interface CellCoord {
  row: number;
  col: number;
}

/** The reactive score/chain/combo data kept in GameState. */
export interface GameStateData {
  score: number;
  /** Current chain level. Minimum valid value is 1 (never 0). */
  chainLevel: number;
  /** Largest block-count cleared in a single pass this session. */
  highestCombo: number;
  isGameOver: boolean;
}

/** Named states for the GameScene state machine. */
export type SceneState =
  | 'IDLE'
  | 'CHECK_MATCHES'
  | 'FLASHING'
  | 'CLEARING'
  | 'FALLING'
  | 'RISING'
  | 'GAME_OVER';
