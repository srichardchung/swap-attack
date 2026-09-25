# GameScene.gd — Scene orchestration, state machine, and game loop.
# Owns the timers and wires Grid, Cursor, HUD, and GameState together.

extends Node2D

# --- State machine ---
enum SceneState { IDLE, CHECK_MATCHES, FLASHING, CLEARING, FALLING, RISING, GAME_OVER }
var _scene_state: SceneState = SceneState.IDLE

# --- Chain tracking ---
var _current_chain: int = 1

# --- Node references (assigned in _ready) ---
var _grid: Grid
var _hud: HUD
var _cursor: Cursor
var _flash_timer: Timer
var _fall_timer: Timer
var _rise_timer: Timer
var _cursor_visual: Node2D
var _block_pool: Array = []   # _block_pool[row][col] -> Block node

# Preloaded scene
const BLOCK_SCENE = preload("res://scenes/Block.tscn")

# -------------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------------

func _ready() -> void:
	_grid   = $Grid
	_hud    = $HUD
	_cursor = $Cursor

	_flash_timer = $FlashTimer
	_fall_timer  = $FallTimer
	_rise_timer  = $RiseTimer

	# Wire timers
	_flash_timer.wait_time = Constants.FLASH_DURATION
	_flash_timer.one_shot  = true
	_flash_timer.timeout.connect(_on_flash_timer_timeout)

	_fall_timer.wait_time = Constants.FALL_STEP_SEC
	_fall_timer.one_shot  = false
	_fall_timer.timeout.connect(_on_fall_timer_timeout)

	_rise_timer.wait_time = Constants.RISE_SPEED_SEC
	_rise_timer.one_shot  = false
	_rise_timer.timeout.connect(_on_rise_timer_timeout)

	# Wire cursor
	_cursor.swap_requested.connect(_on_swap_requested)

	# Wire HUD to GameState
	_hud.bind(GameState)

	# Initialise grid data
	_grid.initialize()

	# Build block pool (ROWS × COLS Block scenes)
	var block_container: Node2D = $BlockContainer
	_block_pool.resize(Constants.ROWS)
	for r in range(Constants.ROWS):
		_block_pool[r] = []
		_block_pool[r].resize(Constants.COLS)
		for c in range(Constants.COLS):
			var block: Block = BLOCK_SCENE.instantiate()
			block.position = Vector2(
				Constants.GRID_ORIGIN_X + c * Constants.BLOCK_PX,
				Constants.GRID_ORIGIN_Y + r * Constants.BLOCK_PX
			)
			block_container.add_child(block)
			_block_pool[r][c] = block

	_sync_block_pool()

	# Draw grid background
	queue_redraw()

	# Start the rise timer
	_rise_timer.start()

	_scene_state = SceneState.IDLE

# -------------------------------------------------------------------------
# Drawing — grid background
# -------------------------------------------------------------------------

func _draw() -> void:
	# Dark background behind grid
	var grid_rect := Rect2(
		Constants.GRID_ORIGIN_X,
		Constants.GRID_ORIGIN_Y,
		Constants.COLS * Constants.BLOCK_PX,
		Constants.ROWS * Constants.BLOCK_PX
	)
	draw_rect(grid_rect, Color(0.1, 0.1, 0.15))

	# Grid lines
	for r in range(Constants.ROWS + 1):
		var y := Constants.GRID_ORIGIN_Y + r * Constants.BLOCK_PX
		draw_line(
			Vector2(Constants.GRID_ORIGIN_X, y),
			Vector2(Constants.GRID_ORIGIN_X + Constants.COLS * Constants.BLOCK_PX, y),
			Color(0.3, 0.3, 0.4, 0.5), 1.0
		)
	for c in range(Constants.COLS + 1):
		var x := Constants.GRID_ORIGIN_X + c * Constants.BLOCK_PX
		draw_line(
			Vector2(x, Constants.GRID_ORIGIN_Y),
			Vector2(x, Constants.GRID_ORIGIN_Y + Constants.ROWS * Constants.BLOCK_PX),
			Color(0.3, 0.3, 0.4, 0.5), 1.0
		)

	# Cursor highlight (2 cells wide)
	if _scene_state != SceneState.GAME_OVER:
		var cx := Constants.GRID_ORIGIN_X + _cursor.col * Constants.BLOCK_PX
		var cy := Constants.GRID_ORIGIN_Y + _cursor.row * Constants.BLOCK_PX
		draw_rect(
			Rect2(cx, cy, Constants.BLOCK_PX * 2, Constants.BLOCK_PX),
			Color(1.0, 1.0, 0.0, 0.35)
		)
		draw_rect(
			Rect2(cx, cy, Constants.BLOCK_PX * 2, Constants.BLOCK_PX),
			Color(1.0, 1.0, 0.0, 0.9), false, 2.0
		)

func _process(_delta: float) -> void:
	queue_redraw()   # redraw cursor every frame

# -------------------------------------------------------------------------
# Cursor / swap input
# -------------------------------------------------------------------------

func _on_swap_requested(swap_row: int, swap_col: int) -> void:
	if _scene_state != SceneState.IDLE:
		return
	_grid.swap(swap_row, swap_col)
	AudioManager.play_swap()
	_sync_block_pool()
	_current_chain = 1
	GameState.set_chain(1)
	_enter_check_matches()

# -------------------------------------------------------------------------
# State machine
# -------------------------------------------------------------------------

func _enter_check_matches() -> void:
	_scene_state = SceneState.CHECK_MATCHES
	var matches: Array = _grid.find_matches()

	if matches.size() > 0:
		# Score this clear
		var block_count: int = matches.size()
		var combo_mult: int  = max(1, block_count / 3)
		GameState.add_score(Constants.BASE_POINTS * block_count * combo_mult * _current_chain)
		GameState.update_highest_combo(block_count)

		if _current_chain > 1:
			_hud.show_chain_label(_current_chain)
		if block_count > 3:
			_hud.show_combo_label(block_count)

		_current_chain += 1

		# Flash then clear
		_grid.mark_flashing(matches)
		_sync_block_pool()
		_scene_state = SceneState.FLASHING
		_flash_timer.start()

		# Speed up rising every 500 points
		_update_rise_speed()
	else:
		# No matches — reset chain and move to rising
		GameState.set_chain(1)
		_current_chain = 1
		_scene_state = SceneState.RISING

func _on_flash_timer_timeout() -> void:
	_scene_state = SceneState.CLEARING
	_grid.clear_flashing()
	_sync_block_pool()
	AudioManager.play_match()
	_fall_timer.start()
	_scene_state = SceneState.FALLING

func _on_fall_timer_timeout() -> void:
	var moved: bool = _grid.apply_gravity()
	_sync_block_pool()
	if not moved:
		_fall_timer.stop()
		# Chain reaction check
		_enter_check_matches()

func _on_rise_timer_timeout() -> void:
	if _scene_state != SceneState.IDLE and _scene_state != SceneState.RISING:
		return
	var game_over: bool = _grid.rise_row()
	_sync_block_pool()
	if game_over:
		AudioManager.play_game_over()
		GameState.set_game_over()
		_scene_state = SceneState.GAME_OVER
		_rise_timer.stop()
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/GameOverScene.tscn")
	else:
		_scene_state = SceneState.IDLE

# -------------------------------------------------------------------------
# Block pool sync
# -------------------------------------------------------------------------

func _sync_block_pool() -> void:
	var data: Array = _grid.get_data()
	for r in range(Constants.ROWS):
		for c in range(Constants.COLS):
			var cell = data[r][c]
			var block: Block = _block_pool[r][c]
			if cell == null:
				block.set_empty()
			elif cell["state"] == Constants.BlockState.FLASHING:
				block.set_color(cell["color"])
				block.play_flash()
			else:
				block.set_color(cell["color"])

# -------------------------------------------------------------------------
# Rising speed progression (REQ-5.2 / Task 5.2)
# -------------------------------------------------------------------------

func _update_rise_speed() -> void:
	var milestones: int = GameState.score / 500
	var new_wait: float = max(0.5, Constants.RISE_SPEED_SEC - milestones * 0.1)
	_rise_timer.wait_time = new_wait
