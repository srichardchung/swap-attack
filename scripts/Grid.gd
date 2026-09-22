# Grid.gd — Board data + match / clear / gravity algorithms.
# Attach to a Node in GameScene. All grid state mutation lives here.

class_name Grid
extends Node

# _data[row][col] holds a Dictionary {color, state} or null.
# Row 0 = top of the board; row 11 = bottom.
var _data: Array = []

# -------------------------------------------------------------------------
# Initialisation
# -------------------------------------------------------------------------

func initialize() -> void:
	_data = []
	for r in range(Constants.ROWS):
		var row: Array = []
		row.resize(Constants.COLS)
		row.fill(null)
		_data.append(row)

	# Fill rows 6-11 with random colours; no initial run of >= 3
	for r in range(6, Constants.ROWS):
		for c in range(Constants.COLS):
			var color := _pick_safe_color(r, c)
			_data[r][c] = _make_block(color)

func get_data() -> Array:
	return _data

# -------------------------------------------------------------------------
# Swap
# -------------------------------------------------------------------------

func swap(row: int, col: int) -> void:
	if col < 0 or col > Constants.COLS - 2:
		push_error("Grid.swap: col %d out of range [0, %d]" % [col, Constants.COLS - 2])
		return
	if row < 0 or row > Constants.ROWS - 1:
		push_error("Grid.swap: row %d out of range [0, %d]" % [row, Constants.ROWS - 1])
		return

	# REQ-2.6: swapping two null cells is a no-op
	if _data[row][col] == null and _data[row][col + 1] == null:
		return

	var tmp = _data[row][col]
	_data[row][col] = _data[row][col + 1]
	_data[row][col + 1] = tmp

# -------------------------------------------------------------------------
# Match detection
# -------------------------------------------------------------------------

## Returns a deduplicated Array of Vector2i(col, row) for every cell
## that belongs to a match of >= 3 consecutive same-colour IDLE blocks.
func find_matches() -> Array:
	var matched: Dictionary = {}   # Vector2i -> true, used for deduplication

	# Horizontal pass
	for r in range(Constants.ROWS):
		var run_start: int = 0
		while run_start < Constants.COLS:
			var c: int = run_start
			var run_color = _idle_color_at(r, c)
			if run_color == null:
				run_start += 1
				continue
			var run_end: int = c + 1
			while run_end < Constants.COLS and _idle_color_at(r, run_end) == run_color:
				run_end += 1
			var run_len: int = run_end - run_start
			if run_len >= 3:
				for i in range(run_start, run_end):
					matched[Vector2i(i, r)] = true
			run_start = run_end

	# Vertical pass
	for c in range(Constants.COLS):
		var run_start: int = 0
		while run_start < Constants.ROWS:
			var r: int = run_start
			var run_color = _idle_color_at(r, c)
			if run_color == null:
				run_start += 1
				continue
			var run_end: int = r + 1
			while run_end < Constants.ROWS and _idle_color_at(run_end, c) == run_color:
				run_end += 1
			var run_len: int = run_end - run_start
			if run_len >= 3:
				for i in range(run_start, run_end):
					matched[Vector2i(c, i)] = true
			run_start = run_end

	return matched.keys()

# -------------------------------------------------------------------------
# Flash and clear cycle
# -------------------------------------------------------------------------

func mark_flashing(coords: Array) -> void:
	for v in coords:
		if _data[v.y][v.x] != null:
			_data[v.y][v.x]["state"] = Constants.BlockState.FLASHING

func clear_flashing() -> void:
	for r in range(Constants.ROWS):
		for c in range(Constants.COLS):
			if _data[r][c] != null and _data[r][c]["state"] == Constants.BlockState.FLASHING:
				_data[r][c] = null

# -------------------------------------------------------------------------
# Gravity
# -------------------------------------------------------------------------

## Move each floating block down one cell per call.
## Returns true if any block moved, false when the board is settled.
func apply_gravity() -> bool:
	var moved: bool = false
	for c in range(Constants.COLS):
		# Scan from second-to-last row upward
		for r in range(Constants.ROWS - 2, -1, -1):
			var block = _data[r][c]
			if block == null:
				continue
			if block["state"] == Constants.BlockState.FLASHING:
				continue
			if _data[r + 1][c] == null:
				_data[r + 1][c] = block
				_data[r][c] = null
				moved = true
	return moved

# -------------------------------------------------------------------------
# Row rising
# -------------------------------------------------------------------------

## Pushes a new row in from the bottom.
## Returns true (game over) if row 0 has any block before the shift.
func rise_row() -> bool:
	# Check game-over condition first
	for c in range(Constants.COLS):
		if _data[0][c] != null:
			return true

	# Shift rows 0..10 upward (row 0 is discarded, row 1 becomes row 0)
	for r in range(0, Constants.ROWS - 1):
		_data[r] = _data[r + 1]

	# Generate a new random row at row 11
	var new_row: Array = []
	new_row.resize(Constants.COLS)
	for c in range(Constants.COLS):
		new_row[c] = _make_block(randi() % Constants.COLOR_COUNT)
	_data[Constants.ROWS - 1] = new_row

	return false

# -------------------------------------------------------------------------
# Private helpers
# -------------------------------------------------------------------------

func _make_block(color: int) -> Dictionary:
	return {"color": color, "state": Constants.BlockState.IDLE}

## Returns the colour of the block at (row, col) only if it is IDLE, else null.
func _idle_color_at(row: int, col: int):
	var cell = _data[row][col]
	if cell == null:
		return null
	if cell["state"] != Constants.BlockState.IDLE:
		return null
	return cell["color"]

## Pick a colour for (row, col) that doesn't create a run of >= 3 horizontally
## or vertically given what's already placed.
func _pick_safe_color(row: int, col: int) -> int:
	var forbidden: Array = []

	# Horizontal: check two cells to the left
	if col >= 2:
		var c1 = _data[row][col - 1]
		var c2 = _data[row][col - 2]
		if c1 != null and c2 != null and c1["color"] == c2["color"]:
			forbidden.append(c1["color"])

	# Vertical: check two cells above
	if row >= 2:
		var r1 = _data[row - 1][col]
		var r2 = _data[row - 2][col]
		if r1 != null and r2 != null and r1["color"] == r2["color"]:
			forbidden.append(r1["color"])

	# Pick any colour not in forbidden
	var candidates: Array = []
	for color_idx in range(Constants.COLOR_COUNT):
		if not forbidden.has(color_idx):
			candidates.append(color_idx)

	# Fallback: if all are forbidden (shouldn't happen with 6 colours), pick randomly
	if candidates.is_empty():
		return randi() % Constants.COLOR_COUNT

	return candidates[randi() % candidates.size()]
