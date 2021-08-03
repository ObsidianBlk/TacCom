extends Node2D
tool

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var hex_image : Texture							setget _set_hex_image
export var hex_offset : Vector2 = Vector2.ZERO			setget _set_hex_offset
export var viewport_size : Vector2 = Vector2(64, 64)	setget _set_viewport_size
export var centered : bool = true						setget _set_centered

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _cells = []
var last_position = null

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------



func _set_hex_image(i : Texture) -> void:
	hex_image = i
	for cell in _cells:
		cell.sprite.texture = i

func _set_hex_offset(o : Vector2) -> void:
	if o.x >= 0 and o.y >= 0:
		hex_offset = o
		if o.x > 0 and o.y > 0:
			_CreateGrid()
		else:
			_RemoveGrid()

func _set_viewport_size(v : Vector2) -> void:
	if v.x >= 0 and v.y >= 0:
		viewport_size = v
		if v.x > 0 and v.y > 0:
			_CreateGrid()
		else:
			_RemoveGrid()

func _set_centered(c : bool) -> void:
	centered = c
	_UpdateGridOffset()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------		

func _ready() -> void:
	last_position = global_position
	_CreateGrid()

func _process(_delta : float) -> void:
	if global_position != last_position:
		last_position = global_position	



# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _UpdateGridOffset() -> void:
	if _cells.size() > 0:
		var pos = global_position
		if (centered):
			pos -= (viewport_size * 0.5)
		var shift = Vector2(
			int(pos.x) % int(hex_offset.x),
			int(pos.y) % int(hex_offset.y)
		)
		for cell in _cells:
			var cpos = coord_to_world(cell.position) + shift
			cell.sprite.position = cpos

func _RemoveGrid() -> void:
	_cells = []
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _CreateGrid() -> void:
	_RemoveGrid()
	var width = floor((viewport_size.x / hex_offset.x)) + 2
	var height = floor((viewport_size.y / (hex_offset.y * 2)))
	for col in range(width):
		for row in range(height):
			var sprite = Sprite.new()
			sprite.texture = hex_image
			sprite.position = Vector2.ZERO #map_to_world(col, row)
			sprite.use_parent_material = true
			add_child(sprite)
			_cells.append({
				"position": Vector2(col, row),
				"sprite": sprite
			})
			_UpdateGridOffset()


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------

func map_to_world(c : int, r : int) -> Vector2:
	var x = float(c) * hex_offset.x
	var y = float(r) * (hex_offset.y*2)
	if c % 2 != 0:
		y += hex_offset.y
	return Vector2(x,y)

func coord_to_world(coord : Vector2) -> Vector2:
	return map_to_world(int(coord.x), int(coord.y))

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



