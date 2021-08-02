extends Node2D
tool

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var hex_image : Texture
export var offset : Vector2 = Vector2.ZERO


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _width : int = 0
var _height : int = 0


# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------



# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------



# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _RemoveGrid() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _CreateGrid() -> void:
	_RemoveGrid()
	for col in range(_width):
		for row in range(_height):
			var sprite = Sprite.new()
			sprite.texture = hex_image
			sprite.position = map_to_world(col, row)
			sprite.use_parent_material = true
			add_child(sprite)


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------

func create_map(w : int, h : int) -> void:
	if w > 0 and h > 0:
		_width = w
		_height = h
		_CreateGrid()


func map_to_world(c : int, r : int) -> Vector2:
	var x = float(c) * offset.x
	var y = float(r) * (offset.y*2)
	if c % 2 != 0:
		y += offset.y
	return Vector2(x,y)

func coord_to_world(coord : Vector2) -> Vector2:
	return map_to_world(int(coord.x), int(coord.y))

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



