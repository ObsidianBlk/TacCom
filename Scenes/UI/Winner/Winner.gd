extends Control

signal mainmenu

export var winner : String = ""			setget set_winner_text

onready var label = get_node("MC/Message/Label")

func set_winner_text(w : String) -> void:
	winner = w
	if label:
		label.text = winner
	else:
		call_deferred("set_winner_text", w)


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept", false) or event.is_action_pressed("ui_cancel"):
		visible = false
		emit_signal("mainmenu")

