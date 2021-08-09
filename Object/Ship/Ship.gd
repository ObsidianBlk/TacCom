extends "res://Scripts/Entity.gd"
tool
class_name Ship

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal turn_complete

# -----------------------------------------------------------
# Constants and Enums
# -----------------------------------------------------------

enum COMPARTMENT {FORE=0, MID=1, AFT=2}

# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var faction : String = "NEUTRAL"					setget _set_faction
export var texture : Texture = null						setget _set_texture
export var tex_region_size : Vector2 = Vector2(16, 16)	setget _set_tex_region_size
export var tex_region_horizontal : bool = true			setget _set_tex_region_horizontal
export var light_color : Color = Color(0)				setget _set_light_color
export var mid_color : Color = Color(0)					setget _set_mid_color
export var dark_color : Color = Color(0)				setget _set_dark_color
export (float, 0.0, 360.0) var facing = 0.0		setget set_facing

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------

var sprite : Sprite = null
var fore_structure : ShipComponent = null
var mid_structure : ShipComponent = null
var aft_structure : ShipComponent

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_faction(f : String, force : bool = true) -> void:
	if f != "" and (f != faction or force):
		if faction != "" and is_in_group(faction):
			remove_from_group(faction)
		add_to_group(f)
	elif f == "" and faction != "" and is_in_group(faction):
		remove_from_group(faction)
	faction = f


func _set_texture(t : Texture) -> void:
	texture = t
	if sprite:
		sprite.texture = texture

func _set_tex_region_size(r : Vector2) -> void:
	if r.x > 0 and r.y > 0:
		tex_region_size = r
		_swapFacing(facing_edge())

func _set_tex_region_horizontal(e : bool) -> void:
	tex_region_horizontal = e
	_swapFacing(facing_edge())


func _set_light_color(c : Color) -> void:
	light_color = c
	if sprite:
		sprite.material.set_shader_param("color_3_to", light_color)

func _set_mid_color(c : Color) -> void:
	mid_color = c
	if sprite:
		sprite.material.set_shader_param("color_1_to", mid_color)

func _set_dark_color(c : Color) -> void:
	dark_color = c
	if sprite:
		sprite.material.set_shader_param("color_2_to", dark_color)

func set_facing(f : float) -> void:
	if f < 0:
		f = 360 - fmod(abs(f), 360)
	elif f >= 360:
		f = fmod(f, 360)
	facing = f
	_swapFacing(facing_edge())

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	sprite = get_node("Sprite")
	if sprite:
		sprite.texture = texture
		sprite.material.set_shader_param("color_3_to", light_color)
		sprite.material.set_shader_param("color_1_to", mid_color)
		sprite.material.set_shader_param("color_2_to", dark_color)
		_swapFacing(facing_edge())
	
	_set_faction(faction, true)
	var struct_info = {
		"structure":30,
		"defense":[30,0,10]
	}
	fore_structure = ShipComponent.new(struct_info)
	mid_structure = ShipComponent.new(struct_info)
	aft_structure = ShipComponent.new(struct_info)
	mid_structure.connect_to(fore_structure, true)
	mid_structure.connect_to(aft_structure, true)

	

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _swapFacing(edge : int):
	if not sprite:
		return
	
	var pos = Vector2(
		tex_region_size.x if tex_region_horizontal else 0,
		0 if tex_region_horizontal else tex_region_size.y
	)
	match (edge):
		Hexmap.EDGE.UP:
			sprite.region_rect = Rect2(pos * 0, tex_region_size)
		Hexmap.EDGE.LEFT_UP:
			sprite.region_rect = Rect2(pos, tex_region_size)
		Hexmap.EDGE.LEFT_DOWN:
			sprite.region_rect = Rect2(pos * 2, tex_region_size)
		Hexmap.EDGE.DOWN:
			sprite.region_rect = Rect2(pos * 3, tex_region_size)
		Hexmap.EDGE.RIGHT_DOWN:
			sprite.region_rect = Rect2(pos * 4, tex_region_size)
		Hexmap.EDGE.RIGHT_UP:
			sprite.region_rect = Rect2(pos * 5, tex_region_size)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func facing_edge() -> int:
	if (facing >= 330 and facing < 360) or (facing >= 0 and facing < 30):
		return Hexmap.EDGE.UP
	elif facing >= 30 and facing < 90:
		return Hexmap.EDGE.LEFT_UP
	elif facing >= 90 and facing < 150:
		return Hexmap.EDGE.LEFT_DOWN
	elif facing >= 150 and facing < 210:
		return Hexmap.EDGE.DOWN
	elif facing >= 210 and facing < 270:
		return Hexmap.EDGE.RIGHT_DOWN
	elif facing > 270 and facing < 330:
		return Hexmap.EDGE.RIGHT_UP
	return -1

func shift_to_facing() -> void:
	if hexmap_node:
		set_coord(hexmap_node.get_neighbor_coord(coord, facing_edge()))

func face_and_shift(deg : float, incremental : bool = false) -> void:
	if hexmap_node:
		set_facing(facing + deg if incremental else deg)
		shift_to_facing()

func process_turn() -> void:
	pass


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------


