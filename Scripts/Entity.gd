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
var _blocking : bool = false
var hexmap_node : Hexmap = null

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func set_coord(c : Vector2):
	if hexmap_node and _blocking:
		hexmap_node.set_coord_blocked(coord, false)
	coord = Vector2(floor(c.x), floor(c.y))
	if hexmap_node:
		position = hexmap_node.coord_to_world(coord)
		if _blocking:
			hexmap_node.set_coord_blocked(coord, false)


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

func set_hexmap(hexmap : Hexmap) -> void:
	if hexmap_node != null:
		hexmap_node.disconnect("masking_changed", self, "_on_masking_changed")
	hexmap_node = hexmap
	hexmap_node.connect("masking_changed", self, "_on_masking_changed")
	set_coord(coord)
	_on_masking_changed()

func clear_hexmap() -> void:
	if hexmap_node != null:
		hexmap_node.disconnect("masking_changed", self, "_on_masking_changed")
	hexmap_node = null


func shift_to_edge(edge : int, ignore_blocked : bool = false) -> void:
	if hexmap_node:
		set_coord(hexmap_node.get_neighbor_coord(coord, edge, ignore_blocked))

func damage(type : int, amount : float) -> void:
	pass

func collision_damage() -> float:
	return 0.0

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_hexmap(hm : Hexmap) -> void:
	if not hexmap_node:
		hexmap_node = hm
		hexmap_node.connect("masking_changed", self, "_on_masking_changed")

func _on_masking_changed() -> void:
	visible = hexmap_node.is_coord_masked(coord)
