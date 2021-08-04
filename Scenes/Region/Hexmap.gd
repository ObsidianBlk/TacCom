extends Node2D
tool
class_name Hexmap

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------
const BASE_COLOR = Color("#404040")
const ALIAS_COLOR = Color("#606060")
const HEX_COLOR = Color(0,1,0.1)

enum EDGE {UP=0, LEFT_UP=1, LEFT_DOWN=2, DOWN=3, RIGHT_DOWN=4, RIGHT_UP=5}

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
var _positional_offset = Vector2.ZERO
var _highlight = {}

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
	if centered and viewport_size.x > 0 and viewport_size.y > 0 and hex_offset.x > 0 and hex_offset.y > 0:
		var cx = ceil((viewport_size.x / hex_offset.x) * 0.5)
		var cy = floor((viewport_size.y / (hex_offset.y * 2)) * 0.5)
		print("CXY: ", Vector2(cx,cy))
		_positional_offset = Vector2(cx * hex_offset.x, cy * (hex_offset.y*2))
	else:
		_positional_offset = Vector2.ZERO
	_UpdateGridOffset()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------		

func _ready() -> void:
	ready = true
	_set_centered(centered)
	if _cells.size() <= 0:
		_CreateGrid()
	

func _process(_delta : float) -> void:
	if global_position != last_position:
		last_position = global_position
		_UpdateGridOffset()



# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _AssignColorToSprite(sprite : Sprite, color : Color) -> void:
	var mat = sprite.material
	var color_alias = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.4)
	mat.set_shader_param("color_1_from", BASE_COLOR)
	mat.set_shader_param("color_1_to", color)
	mat.set_shader_param("color_2_from", ALIAS_COLOR)
	mat.set_shader_param("color_2_to", color_alias)

func _UpdateGridOffset() -> void:
	if _cells.size() > 0:
		for cell in _cells:
			var cpos = coord_to_world(cell.coord)
			#if cell.coord == Vector2(0,0):
			#	print("Cell Position: ", cpos, " | Map Position: ", position)
			cell.sprite.position = cpos
			cell.global_coord = world_to_coord(cell.sprite.global_position)
			if cell.coord == Vector2(0,0):
				print("GP: ", position, " | Cell GC: ", cell.global_coord, " | Cell GP: ", cell.sprite.global_position)
			if cell.global_coord.x < 0 or cell.global_coord.y < 0:
				cell.sprite.visible = false
			else:
				cell.sprite.visible = true
				var key = "%sx%s"%[cell.global_coord.x, cell.global_coord.y]
				if key in _highlight:
					_AssignColorToSprite(cell.sprite, _highlight[key])
				else:
					_AssignColorToSprite(cell.sprite, HEX_COLOR)

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
			#sprite.use_parent_material = true
			sprite.material = ShaderMaterial.new()
			sprite.material.shader = preload("res://Shaders/Fragment/colorswap.shader")
			add_child(sprite)
			_cells.append({
				"coord": Vector2(col, row),
				"global_coord": Vector2(col, row),
				"sprite": sprite
			})
	_UpdateGridOffset()


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------

func get_neighbor_coord(coord : Vector2, edge : int) -> Vector2:
	var odd = int(abs(coord.x)) % 2 == 1
	var y_lu = 0 if odd else -1
	var y_ld = 1 if odd else 0
	var y_ru = 0 if odd else -1
	var y_rd = 1 if odd else 0
		
	match(edge):
		EDGE.UP:
			return coord + Vector2(0, -1)
		EDGE.LEFT_UP:
			return coord + Vector2(-1, y_lu)
		EDGE.LEFT_DOWN:
			return coord + Vector2(-1, y_ld)
		EDGE.DOWN:
			return coord + Vector2(0, 1)
		EDGE.RIGHT_DOWN:
			return coord + Vector2(1, y_rd)
		EDGE.RIGHT_UP:
			return coord + Vector2(1, y_ru)
	return coord

func highlight_cell(c : int, r : int, color : Color) -> void:
	var key = "%sx%s" % [c, r]
	_highlight[key] = color

func clear_highlight_cell(c : int, r : int) -> void:
	var key = "%sx%s" % [c, r]
	_highlight.erase(key)

func highlight_coord(coord : Vector2, color : Color) -> void:
	highlight_cell(int(coord.x), int(coord.y), color)

func clear_highlight_coord(coord : Vector2) -> void:
	clear_highlight_cell(int(coord.x), int(coord.y))

func clear_highlights() -> void:
	_highlight = {}

func get_cells_at_distance(c : int, r : int, radius : int, inclusive : bool = false) -> Array:
	var cells = []
	var handled = {}
	handled["%sx%s"%[c, r]] = 0
	var tagged = [{"c":c, "r":r, "d":0}]
	var ti = 0
	while ti < tagged.size():
		var cell = tagged[ti]
		if (cell.d < radius and inclusive) or (cell.d == radius):
			print("Cell.d: ", cell.d, " | Radius: ", radius, " | Inclusive: ", inclusive)
			cells.append(Vector2(cell.c, cell.r))
		if cell.d < radius:
			for e in EDGE.keys():
				var ncoord = get_neighbor_coord(Vector2(cell.c, cell.r), EDGE[e])
				var key = "%sx%s"%[ncoord.x, ncoord.y]
				if not key in handled:
					tagged.append({"c":ncoord.x, "r":ncoord.y, "d": cell.d + 1})
					handled[key] = cell.d + 1
			#key = "%sx%s"%[cell.c-1, cell.r]
			#if not key in handled:
			#	tagged.append({"c":cell.c-1, "r":cell.r, "d": cell.d + 1})
			#key = "%sx%s"%[cell.c-1, cell.r-1]
			#if not key in handled:
			#	tagged.append({"c":cell.c-1, "r":cell.r-1, "d": cell.d + 1})
			#key = "%sx%s"%[cell.c, cell.r-1]
			#if not key in handled:
			#	tagged.append({"c":cell.c, "r":cell.r-1, "d": cell.d + 1})
			#key = "%sx%s"%[cell.c+1, cell.r-1]
			#if not key in handled:
			#	tagged.append({"c":cell.c+1, "r":cell.r-1, "d": cell.d + 1})
			#key = "%sx%s"%[cell.c+1, cell.r]
			#if not key in handled:
			#	tagged.append({"c":cell.c+1, "r":cell.r, "d": cell.d + 1})
		ti += 1
	return cells

func map_to_world(c : int, r : int) -> Vector2:
	var x = float(c) * hex_offset.x
	var y = float(r) * (hex_offset.y*2)
	if c % 2 != 0:
		y += hex_offset.y
	var pos = Vector2(x,y) - _positional_offset
	return pos

func coord_to_world(coord : Vector2) -> Vector2:
	return map_to_world(int(coord.x), int(coord.y))

func world_to_coord(pos : Vector2) -> Vector2:
	pos += _positional_offset
	var c = floor(pos.x / hex_offset.x)
	var y = (pos.y - hex_offset.y) if int(c) % 2 != 0 else pos.y
	var r = floor(y / (hex_offset.y * 2))
	return Vector2(c, r)

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



