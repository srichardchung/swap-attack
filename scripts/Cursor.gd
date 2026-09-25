# Cursor.gd — Player cursor: position tracking and key-repeat input.
# Attach to a Node2D in GameScene. Emits signals; never calls Grid directly.

class_name Cursor
extends Node2D

signal swap_requested(row: int, col: int)
signal moved(row: int, col: int)

var row: int = 5
var col: int = 2

# Key-repeat state per action
var _held: Dictionary = {}       # action -> seconds held
var _repeated: Dictionary = {}   # action -> bool (first repeat fired)

const _MOVE_ACTIONS = ["ui_left", "ui_right", "ui_up", "ui_down"]

func _ready() -> void:
	_update_position()

func _process(delta: float) -> void:
	# Swap: just-pressed only (no repeat)
	if Input.is_action_just_pressed("swap"):
		swap_requested.emit(row, col)
		return

	# Movement with key-repeat
	for action in _MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			if not _held.has(action):
				_held[action] = 0.0
				_repeated[action] = false
				_move(action)
			else:
				_held[action] += delta
				var threshold: float = Constants.INPUT_REPEAT_SEC if _repeated[action] else Constants.INPUT_DELAY_SEC
				if _held[action] >= threshold:
					_held[action] = 0.0
					_repeated[action] = true
					_move(action)
		else:
			_held.erase(action)
			_repeated.erase(action)

func _move(action: String) -> void:
	var prev_row := row
	var prev_col := col

	match action:
		"ui_left":  col = max(0, col - 1)
		"ui_right": col = min(Constants.COLS - 2, col + 1)
		"ui_up":    row = max(0, row - 1)
		"ui_down":  row = min(Constants.ROWS - 1, row + 1)

	if row != prev_row or col != prev_col:
		_update_position()
		moved.emit(row, col)

func _update_position() -> void:
	position = Vector2(
		Constants.GRID_ORIGIN_X + col * Constants.BLOCK_PX,
		Constants.GRID_ORIGIN_Y + row * Constants.BLOCK_PX
	)
