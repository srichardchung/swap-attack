# GameState.gd — Autoload: reactive score / chain / combo state.
# All mutations emit state_changed so the HUD can update without direct calls.

class_name GameState
extends Node

# --- Signals ---
signal state_changed(data: Dictionary)

# --- State fields ---
var score: int = 0
var chain_level: int = 1          # minimum 1; never 0
var highest_combo: int = 0
var is_game_over: bool = false

# --- Mutations ---

func add_score(points: int) -> void:
	score += points
	_emit()

func set_chain(level: int) -> void:
	chain_level = max(1, level)   # enforce minimum of 1
	_emit()

func update_highest_combo(block_count: int) -> void:
	if block_count > highest_combo:
		highest_combo = block_count
	_emit()

func set_game_over() -> void:
	is_game_over = true
	_emit()

func reset() -> void:
	score = 0
	chain_level = 1
	highest_combo = 0
	is_game_over = false
	_emit()

# --- Read-only snapshot ---

func get_state() -> Dictionary:
	return {
		"score": score,
		"chain_level": chain_level,
		"highest_combo": highest_combo,
		"is_game_over": is_game_over
	}

# --- Internal ---

func _emit() -> void:
	state_changed.emit(get_state())
