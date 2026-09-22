# Constants.gd — Autoload: all shared numeric constants and enums for Swap Attack.
# No other script should redefine these values.

extends Node

# --- Grid dimensions ---
const COLS: int = 6
const ROWS: int = 12

# --- Rendering ---
const BLOCK_PX: int = 48
const CANVAS_W: int = 800
const CANVAS_H: int = 656        # 80 (HUD) + 12 * 48
const HUD_HEIGHT: int = 80
const GRID_ORIGIN_X: int = 256
const GRID_ORIGIN_Y: int = 80

# --- Colours ---
const COLOR_COUNT: int = 6

# --- Timing (seconds) ---
const FLASH_DURATION: float = 0.5
const FALL_STEP_SEC: float = 0.05
const RISE_SPEED_SEC: float = 2.0

# --- Input repeat ---
const INPUT_DELAY_SEC: float = 0.25
const INPUT_REPEAT_SEC: float = 0.08

# --- Scoring ---
const BASE_POINTS: int = 10

# --- Block colour enum ---
enum BlockColor {
	RED,
	BLUE,
	GREEN,
	YELLOW,
	PURPLE,
	TEAL
}

# --- Block state enum ---
enum BlockState {
	IDLE,
	FLASHING,
	FALLING
}
