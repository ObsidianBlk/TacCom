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
			hexmap_node.set_coord_blocked(coord, true)


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	pass

# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _wrapRange(v : float, minV : float, maxV : float, maxInclusive : bool = false) -> float:
	var d = maxV - minV
	while v < minV:
		v += d
	if maxInclusive:
		while v > maxV:
			v -= d
	else:
		while v >= maxV:
			v -= d
	return v

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

func is_physical() -> bool:
	return _blocking

func angle_to_entity(e : Entity) -> float:
	return 360 - _wrapRange(rad2deg(position.angle_to_point(e.position)) -90.0, 0.0, 360.0)

func angle_to_coord(c : Vector2) -> float:
	var cpos = hexmap_node.coord_to_world(c)
	return 360 - _wrapRange(rad2deg(position.angle_to_point(cpos)) -90.0, 0.0, 360.0)

func edge_from_coord(c : Vector2) -> int:
	if c != coord:
		var angle = angle_to_coord(c)
		if (angle >= 330 and angle < 360) or (angle >= 0 and angle < 30):
			return Hexmap.EDGE.UP
		elif angle >= 30 and angle < 90:
			return Hexmap.EDGE.LEFT_UP
		elif angle >= 90 and angle < 150:
			return Hexmap.EDGE.LEFT_DOWN
		elif angle >= 150 and angle < 210:
			return Hexmap.EDGE.DOWN
		elif angle >= 210 and angle < 270:
			return Hexmap.EDGE.RIGHT_DOWN
		elif angle > 270 and angle < 330:
			return Hexmap.EDGE.RIGHT_UP
	return -1

func shift_to_edge(edge : int, ignore_blocked : bool = false) -> void:
	if hexmap_node:
		set_coord(hexmap_node.get_neighbor_coord(coord, edge, ignore_blocked))

func damage(type : int, amount : float) -> void:
	pass

func collide(e : Entity, one_way : bool = false) -> void:
	if not one_way:
		e.collide(self, true)

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
