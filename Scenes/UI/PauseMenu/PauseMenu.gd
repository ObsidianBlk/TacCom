extends Control


signal resume
signal mainmenu
signal quit



func _on_BTN_Resume_pressed():
	visible = false
	emit_signal("resume")


func _on_BTN_Menu_pressed():
	visible = false
	emit_signal("mainmenu")


func _on_BTN_Quit_pressed():
	visible = false
	emit_signal("quit")
