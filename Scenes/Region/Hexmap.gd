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

enum EDGE {UP=0, LEFT_UP=1, LEFT_DOWN=2, DOWN=3, RIGHT_DOWN=4, RIGHT_UP=5}

# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var hex_image : Texture							setget _set_hex_image
export var hex_offset : Vector2 = Vector2.ZERO			setget _set_hex_offset
export var hex_color : Color = Color(0,1,0.1)			setget _set_hex_color
export var viewport_size : Vector2 = Vector2(64, 64)	setget _set_viewport_size
export var centered : bool = true						setget _set_centered

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var ready = false
var _cell_grid = []
var _cell_info = {}
var _positional_offset = Vector2.ZERO
var _highlights = {}

var last_position = null

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------



func _set_hex_image(i : Texture) -> void:
	hex_image = i
	for cell in _cell_grid:
		cell.sprite.texture = i

func _set_hex_offset(o : Vector2) -> void:
	if o.x >= 0 and o.y >= 0:
		hex_offset = o
		if o.x > 0 and o.y > 0:
			_CreateGrid()
		else:
			_RemoveGrid()

func _set_hex_color(c : Color) -> void:
	hex_color = c
	if _cell_grid.size() > 0:
		for cell in _cell_grid:
			pass
			#if not ("%sx%s" % [cell.c, cell.r] in _highlight):
			#	_AssignColorToSprite(cell.sprite, hex_color)

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
		_positional_offset = Vector2(cx * hex_offset.x, cy * (hex_offset.y*2) + hex_offset.y)
	else:
		_positional_offset = Vector2.ZERO
	_UpdateGridOffset()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------		

func _ready() -> void:
	ready = true
	_set_centered(centered)
	if _cell_grid.size() <= 0:
		_CreateGrid()

func _process(_delta : float) -> void:
	if global_position != last_position:
		last_position = global_position
		_UpdateGridOffset()
	update()



# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _key(c : Vector2) -> String:
	return "%sx%s" % [floor(c.x), floor(c.y)]

func _AssignCellInfo(coord : Vector2, property : String, value) -> void:
	var key = _key(coord)
	if value == null:
		if key in _cell_info:
			_cell_info[key].erase(property)
			if _cell_info[key].keys().size() <= 0:
				_cell_info.erase(key)
	else:
		if not key in _cell_info:
			_cell_info[key] = {}
		_cell_info[key][property] = value

func _GetCellInfo(coord : Vector2, property : String, default_value = null):
	var key = _key(coord)
	if key in _cell_info:
		if property in _cell_info[key]:
			return _cell_info[key][property]
	return default_value

func _AssignColorToSprite(sprite : Sprite, color : Color, z : int = 0) -> void:
	var mat = sprite.material
	var color_alias = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.4)
	mat.set_shader_param("color_1_from", BASE_COLOR)
	mat.set_shader_param("color_1_to", color)
	mat.set_shader_param("color_2_from", ALIAS_COLOR)
	mat.set_shader_param("color_2_to", color_alias)
	sprite.z_index = z

func _UpdateGridOffset() -> void:
	if _cell_grid.size() > 0:
		for cell in _cell_grid:
			cell.global_coord = world_to_coord(cell.sprite.global_position)
			#if cell.global_coord.x < 0 or cell.global_coord.y < 0:
			#	cell.sprite.visible = false
			#else:
			#	cell.sprite.visible = true
			if cell.global_coord in _highlights:
				_AssignColorToSprite(cell.sprite, _highlights[cell.global_coord], 1)
			else:
				_AssignColorToSprite(cell.sprite, hex_color, 0)


func _RemoveGrid() -> void:
	if not ready:
		return

	_cell_grid = []
	for c in get_children():
		remove_child(c)
		c.call_deferred("queue_free")
		#c.queue_free()

func _CreateGrid() -> void:
	if not ready:
		return

	_RemoveGrid()
	hex_image.get_width()
	var width = floor((viewport_size.x / hex_offset.x)) + 2
	var height = floor((viewport_size.y / (hex_offset.y * 2))) +2
	#var width = floor(viewport_size.x / hex_image.get_width()) + 2
	#var height = floor(viewport_size.y / hex_image.get_height()) + 2
	for col in range(-1, width):
		for row in range(-1, height):
			var sprite = Sprite.new()
			sprite.texture = hex_image
			sprite.position = map_to_world(col, row)
			#sprite.use_parent_material = true
			sprite.material = ShaderMaterial.new()
			sprite.material.shader = preload("res://Shaders/Fragment/colorswap.shader")
			add_child(sprite)
			_cell_grid.append({
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

func set_cell_weight(c : int, r : int, weight : float) -> void:
	_AssignCellInfo(Vector2(c, r), "weight", weight if weight > 1 else null)

func set_coord_weight(coord : Vector2, weight : float) -> void:
	set_cell_weight(int(coord.x), int(coord.y), weight)

func set_cell_blocked(c : int, r : int, blocked : bool = true) -> void:
	_AssignCellInfo(Vector2(c, r), "blocked", true if blocked else null)

func set_coord_blocked(coord : Vector2, blocked : bool = true) -> void:
	set_cell_blocked(int(coord.x), int(coord.y), blocked)

func highlight_cell(c : int, r : int, color : Color, noupdate : bool = false) -> void:
	_highlights[Vector2(c, r)] = color
	if not noupdate:
		_UpdateGridOffset()

func clear_highlight_cell(c : int, r : int, noupdate : bool = false) -> void:
	_highlights.erase(Vector2(c, r))
	if not noupdate:
		_UpdateGridOffset()

func highlight_coord(coord : Vector2, color : Color) -> void:
	highlight_cell(int(coord.x), int(coord.y), color)

func highlight_coords(coords : Array, color : Color) -> void:
	for c in coords:
		if c is Vector2:
			highlight_cell(int(c.x), int(c.y), color, true)
	_UpdateGridOffset()

func clear_highlight_coord(coord : Vector2) -> void:
	clear_highlight_cell(int(coord.x), int(coord.y))

func clear_highlight_coords(coords : Array) -> void:
	for c in coords:
		if c is Vector2:
			clear_highlight_cell(int(c.x), int(c.y), true)
	_UpdateGridOffset()

func clear_highlights() -> void:
	_highlights = {}

func get_cells_at_distance(c : int, r : int, radius : int, inclusive : bool = false) -> Array:
	var cells = []
	var handled = {}
	handled["%sx%s"%[c, r]] = 0
	var tagged = [{"c":c, "r":r, "d":0}]
	var ti = 0
	while ti < tagged.size():
		var cell = tagged[ti]
		if (cell.d < radius and inclusive) or (cell.d == radius):
			cells.append(Vector2(cell.c, cell.r))
		if cell.d < radius:
			for e in EDGE.keys():
				var ncoord = get_neighbor_coord(Vector2(cell.c, cell.r), EDGE[e])
				var key = "%sx%s"%[ncoord.x, ncoord.y]
				if not key in handled:
					tagged.append({"c":ncoord.x, "r":ncoord.y, "d": cell.d + 1})
					handled[key] = cell.d + 1
		ti += 1
	return cells

func get_cells_at_distance_from_coord(coord : Vector2, radius : int, inclusive : bool = false) -> Array:
	return get_cells_at_distance(int(coord.x), int(coord.y), radius, inclusive)


func get_simple_path(from : Vector2, to : Vector2) -> Array:
	# Breath First Search
	var cells = []
	var frontier = [from]
	var came_from = {}
	came_from[from] = null
	
	while frontier.size() > 0:
		var cell = frontier.pop_back()
		for e in EDGE.keys():
			var next_cell = get_neighbor_coord(cell, EDGE[e])
			if not _GetCellInfo(next_cell, "blocked", false) and not next_cell in came_from:
				frontier.push_back(next_cell)
				came_from[next_cell] = cell
				if next_cell == to:
					frontier.clear()
	
	var cur = to
	while came_from[cur] != null:
		cells.push_front(cur)
		cur = came_from[cur]
	
	return cells


func get_astar_path(from : Vector2, to : Vector2, min_weight : float = 1) -> Array:
	var cells = []
	var frontier = PriorityQueue.new()
	frontier.put(from, 0)
	var came_from = {}
	var cost = {}
	came_from[from] = null
	cost[from] = 0
	
	while not frontier.empty():
		var cell = frontier.pop()
		
		for e in EDGE.keys():
			var next_cell = get_neighbor_coord(cell, EDGE[e])
			var blocked = _GetCellInfo(next_cell, "blocked", false)
			var new_cost = cost[cell] + max(_GetCellInfo(next_cell, "weight", min_weight), min_weight)
			if not blocked and (not next_cell in cost or cost[next_cell] > new_cost):
				cost[next_cell] = new_cost
				var priority = new_cost + (abs(to.x - next_cell.x) + abs(to.y - next_cell.y))
				frontier.put(priority, next_cell)
				came_from[next_cell] = cell
				if next_cell == to:
					frontier.clear()
		
	var cur = to
	while came_from[cur] != null:
		cells.push_front(cur)
		cur = came_from[cur]
	
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



