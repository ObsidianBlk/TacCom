extends Node2D
tool


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export (int, 0, 30, 1) var columns = 0		setget _set_columns
export (int, 0, 30, 1) var rows = 0			setget _set_rows


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var hexmap_node : Node2D = get_node("Hexmap")


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_columns(c : int) -> void:
	if c > 0:
		columns = c
		_UpdateHexMapSize()

func _set_rows(r : int) -> void:
	if r > 0:
		rows = r
		_UpdateHexMapSize()



# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------



# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _UpdateHexMapSize() -> void:
	if columns > 0 and rows > 0 and hexmap_node:
		hexmap_node.create_map(columns, rows)

# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



