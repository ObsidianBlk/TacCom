extends Node2D
class_name Entity


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var coord : Vector2 = Vector2.ZERO		setget set_coord

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var hexmap_node : Hexmap = null

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func set_coord(c : Vector2):
	coord = Vector2(floor(c.x), floor(c.y))
	if hexmap_node:
		position = hexmap_node.coord_to_world(coord)


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	pass

# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------
func end_turn() -> void:
	pass # This should be overridden

func set_hexmap(hexmap : Hexmap) -> void:
	hexmap_node = hexmap
	set_coord(coord)

func clear_hexmap() -> void:
	hexmap_node = null


func shift_to_edge(edge : int) -> void:
	if hexmap_node:
		set_coord(hexmap_node.get_neighbor_coord(coord, edge))


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_hexmap(hm : Hexmap) -> void:
	if not hexmap_node:
		hexmap_node = hm
