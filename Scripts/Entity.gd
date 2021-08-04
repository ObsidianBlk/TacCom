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
	if not hexmap_node:
		var p = get_parent()
		if p is Region:
			hexmap_node = p.get_hexmap()
	if hexmap_node:
		#print("Setting Coord")
		position = hexmap_node.coord_to_world(coord)
	else:
		print("No Hexmap!")



# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	call_deferred("set_coord", coord)

# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------


func shift_by_degree(deg : float) -> void:
	if (deg >= 330 and deg < 360) or (deg >= 0 and deg < 30):
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.UP))
	elif deg >= 30 and deg < 90:
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.LEFT_UP))
	elif deg >= 90 and deg < 150:
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.LEFT_DOWN))
	elif deg >= 150 and deg < 210:
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.DOWN))
	elif deg >= 210 and deg < 270:
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.RIGHT_DOWN))
	elif deg > 270 and deg < 330:
		set_coord(hexmap_node.get_neighbor_coord(coord, Hexmap.EDGE.RIGHT_UP))

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

