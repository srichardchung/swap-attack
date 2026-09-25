# GameOverScene.gd — Results screen shown after game over.

extends Node2D

@onready var _final_score_label: Label = $HUD/FinalScoreLabel
@onready var _high_combo_label: Label = $HUD/HighComboLabel
@onready var _restart_button: Button = $HUD/RestartButton

func _ready() -> void:
	_final_score_label.text = "SCORE: %d" % GameState.score
	_high_combo_label.text  = "BEST COMBO: %d" % GameState.highest_combo
	_restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
