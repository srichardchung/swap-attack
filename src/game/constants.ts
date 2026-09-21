// ---------------------------------------------------------------------------
// Swap Attack — shared constants
// All row/column values are 0-indexed: row 0 = top, row 11 = bottom.
// ---------------------------------------------------------------------------

/** Number of columns in the playfield. */
export const COLS = 6;

/** Number of rows in the playfield. */
export const ROWS = 12;

/** Pixel size of one grid cell (width and height). */
export const BLOCK_SIZE = 48;

/** Number of distinct block colors. */
export const COLORS = 6;

/** Milliseconds a matched block flashes before being cleared. */
export const FLASH_DURATION = 500;

/** Milliseconds between each gravity tick (one-cell drop per tick). */
export const FALL_STEP_MS = 50;

/** Milliseconds for one full row to rise at normal speed. */
export const RISE_SPEED_MS = 3000;

/** Base score awarded per cleared block before multipliers. */
export const BASE_POINTS = 10;

/** Milliseconds before a held movement key begins repeating. */
export const INPUT_DELAY_MS = 150;

/** Milliseconds between subsequent repeat fires of a held movement key. */
export const INPUT_REPEAT_MS = 80;

// ---------------------------------------------------------------------------
// Derived layout constants (computed from the values above)
// ---------------------------------------------------------------------------

/** Canvas width in pixels. */
export const CANVAS_WIDTH = 800;

/** Canvas height in pixels. */
export const CANVAS_HEIGHT = 600;

/** Height reserved for the HUD above the grid (pixels). */
export const HUD_HEIGHT = 80;

/** Pixel x-coordinate of the left edge of the grid (centred on canvas). */
export const GRID_ORIGIN_X = (CANVAS_WIDTH - COLS * BLOCK_SIZE) / 2; // 256

/** Pixel y-coordinate of the top edge of the grid. */
export const GRID_ORIGIN_Y = HUD_HEIGHT; // 80
