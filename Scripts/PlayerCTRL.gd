extends Node

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal freelook(c)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
export var faction : String = ""


var cur_ship : Ship = null

# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _unhandled_input(event):
	if event.is_action_pressed("freelook", false):
		set_process_unhandled_input(false)
		if cur_ship:
			emit_signal("freelook", cur_ship.coord)
		else:
			emit_signal("freelook", Vector2.ZERO)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_freelook_exit() -> void:
	set_process_unhandled_input(true)
	if cur_ship:
		var parent = get_parent()
		if parent is Region:
			parent.set_target_node(cur_ship)
