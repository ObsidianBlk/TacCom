extends Control

signal maneuver(dir)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel", false):
		emit_signal("maneuver", 0)
		hide()

func _on_Left_BTN_pressed():
	emit_signal("maneuver", -1)
	hide()

func _on_Right_BTN_pressed():
	emit_signal("maneuver", 1)
	hide()
