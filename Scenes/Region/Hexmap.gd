extends Node2D
tool
class_name Hexmap

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
var ready = false
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
	ready = true
	last_position = global_position
	if _cells.size() <= 0:
		_CreateGrid()
	

func _process(_delta : float) -> void:
	if global_position != last_position:
		last_position = global_position
		#_UpdateGridOffset()



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
			int(pos.y) % int(hex_offset.y * 2)
		)
		for cell in _cells:
			var cpos = coord_to_world(cell.position)
			if cell.position == Vector2(0,0):
				print("Cell Position: ", cpos, " | Map Position: ", position)
			cell.sprite.position = cpos

func _RemoveGrid() -> void:
	if not ready:
		return

	_cells = []
	for c in get_children():
		remove_child(c)
		c.call_deferred("queue_free")
		#c.queue_free()

func _CreateGrid() -> void:
	if not ready:
		return

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
	var pos = Vector2(x,y)
	if centered:
		var cx = ceil((viewport_size.x / hex_offset.x) * 0.5)
		var cy = floor((viewport_size.y / (hex_offset.y * 2)) * 0.5)
		#print("CXY: ", Vector2(cx,cy))
		var offset = Vector2(cx * hex_offset.x, cy * hex_offset.y)
		#print("Centered Offset: ", offset)
		pos -= offset
		#print("CR: ", Vector2(c, r), " | Position: ", pos)
	return pos

func coord_to_world(coord : Vector2) -> Vector2:
	return map_to_world(int(coord.x), int(coord.y))

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



