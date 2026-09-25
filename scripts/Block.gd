# Block.gd — Per-block visual state node.
# Attached to Block.tscn (Node2D root + ColorRect child).
# Colours are drawn procedurally — no external texture files needed.

class_name Block
extends Node2D

# Colour palette matching Constants.BlockColor order
const BLOCK_COLORS: Array = [
	Color(0.85, 0.2,  0.2,  1.0),   # RED
	Color(0.2,  0.4,  0.85, 1.0),   # BLUE
	Color(0.2,  0.75, 0.3,  1.0),   # GREEN
	Color(0.9,  0.8,  0.1,  1.0),   # YELLOW
	Color(0.6,  0.2,  0.85, 1.0),   # PURPLE
	Color(0.1,  0.75, 0.75, 1.0),   # TEAL
]
const FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const BORDER_COLOR := Color(0.0, 0.0, 0.0, 0.4)

var _color_rect: ColorRect
var _border_rect: ColorRect
var _current_color: int = -1
var _is_empty: bool = true
var _flash_phase: float = 0.0
var _flashing: bool = false

func _ready() -> void:
	# Build the block visually: filled rect + thin border
	_border_rect = ColorRect.new()
	_border_rect.color = BORDER_COLOR
	_border_rect.size = Vector2(Constants.BLOCK_PX, Constants.BLOCK_PX)
	add_child(_border_rect)

	_color_rect = ColorRect.new()
	_color_rect.color = Color.TRANSPARENT
	_color_rect.position = Vector2(2, 2)
	_color_rect.size = Vector2(Constants.BLOCK_PX - 4, Constants.BLOCK_PX - 4)
	add_child(_color_rect)

	set_empty()

func _process(delta: float) -> void:
	if _flashing:
		_flash_phase += delta * 10.0
		var t := (sin(_flash_phase) + 1.0) * 0.5
		_color_rect.color = lerp(BLOCK_COLORS[_current_color], FLASH_COLOR, t)

func set_color(c: int) -> void:
	_current_color = c
	_is_empty = false
	_flashing = false
	_flash_phase = 0.0
	visible = true
	_color_rect.color = BLOCK_COLORS[c]

func play_flash() -> void:
	if _current_color >= 0:
		_flashing = true
		_flash_phase = 0.0

func set_empty() -> void:
	_is_empty = true
	_flashing = false
	visible = false
