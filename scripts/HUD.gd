# HUD.gd — Score / chain / combo display.
# Binds to GameState.state_changed signal; never calls GameScene directly.

class_name HUD
extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel
@onready var _high_combo_label: Label = $HighComboLabel
@onready var _chain_label: Label = $ChainLabel
@onready var _combo_label: Label = $ComboLabel

func _ready() -> void:
	_chain_label.modulate.a = 0.0
	_combo_label.modulate.a = 0.0

func bind(state_node: Node) -> void:
	state_node.state_changed.connect(_on_state_changed)

func _on_state_changed(data: Dictionary) -> void:
	_score_label.text = "SCORE\n%d" % data["score"]
	_high_combo_label.text = "BEST\n%d" % data["highest_combo"]

func show_chain_label(level: int) -> void:
	_chain_label.text = "CHAIN x%d!" % level
	_pop_label(_chain_label)

func show_combo_label(count: int) -> void:
	_combo_label.text = "COMBO %d!" % count
	_pop_label(_combo_label)

func _pop_label(label: Label) -> void:
	label.scale = Vector2(0.5, 0.5)
	label.modulate.a = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15)
	tw.tween_property(label, "modulate:a", 1.0, 0.15)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tw.chain()
	tw.tween_interval(0.3)
	tw.chain()
	tw.tween_property(label, "modulate:a", 0.0, 0.15)
