extends "res://Scripts/Entity.gd"
tool
class_name Ship

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal turn_complete
signal structure_change(structure, max_structure, comp, connection)
signal power_change(available, total)
signal sublight_stats_change(propulsion_units, turns_to_trigger)

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

var ready : bool = false
var sprite : Sprite = null
var fore_structure : ShipComponent = null
var mid_structure : ShipComponent = null
var aft_structure : ShipComponent = null
var engineering : Engineering = null

var construct_def = null

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
	ready = true
	
	var struct_info = {
		"structure":30,
		"defense":[30,0,10]
	}
	fore_structure = ShipComponent.new(struct_info)
	mid_structure = ShipComponent.new(struct_info)
	aft_structure = ShipComponent.new(struct_info)
	mid_structure.connect_to(fore_structure, true)
	mid_structure.connect_to(aft_structure, true)
	
	if construct_def != null:
		construct_ship(construct_def)

	

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _swapFacing(edge : int):
	if not sprite:
		return
	
	var pos = Vector2(
		tex_region_size.x if tex_region_horizontal else 0.0,
		0.0 if tex_region_horizontal else tex_region_size.y
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
func construct_ship(def : Dictionary) -> void:
	if not ready:
		construct_def = def
		return
	
	for section in def.keys():
		if section in ["Engineering", "SublightEngine"]:
			if "info" in def[section] and "structure" in def[section]:
				var info = def[section].info
				var struct = null
				match def[section].structure:
					"fore":
						struct = fore_structure
					"mid":
						struct = mid_structure
					"aft":
						struct = aft_structure
				if struct != null:
					var comp = null
					match section:
						"Engineering":
							if engineering == null:
								comp = Engineering.new(info)
								engineering = comp
								engineering.connect("power_change", self, "_on_power_change")
						"SublightEngine":
							if engineering != null:
								comp = SublightEngine.new(info)
								comp.connect("sublight_propulsion", self, "_on_sublight_propulsion")
								comp.connect("sublight_stats_change", self, "_on_sublight_stats_change")
								engineering.connect_powered_component(comp)
					if comp != null:
						comp.connect("structure_change", self, "_on_structure_change", [section, def[section].structure])
						struct.connect_to(comp)
				else:
					print("Structure name ", def[section].structure, " unknown")
			else:
				print("Missing info or structure property")
		else:
			print("Section ", section, " not in list")



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

func shift_to_facing(units : int = 1) -> void:
	if hexmap_node:
		for _i in range(units):
			set_coord(hexmap_node.get_neighbor_coord(coord, facing_edge()))

func face_and_shift(deg : float, incremental : bool = false) -> void:
	if hexmap_node:
		set_facing(facing + deg if incremental else deg)
		shift_to_facing()

func report_info() -> void:
	var info = mid_structure.get_structure()
	emit_signal("structure_change", info.structure, info.max_structure, "Ship", "")
	mid_structure.report_info()


func process_turn() -> void:
	mid_structure.process_turn()


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_structure_change(old_structure : int, new_structure : int, max_structure : int, comp : String, connection : String) -> void:
		print("Obtained a info on ", comp, " for connection to ", connection)
		emit_signal("structure_change", new_structure, max_structure, comp, connection)
	
	
func _on_sublight_propulsion(units_to_move : int) -> void:
	shift_to_facing(units_to_move)

func _on_power_change(available : int, total : int) -> void:
	emit_signal("power_change", available, total)

func _on_sublight_stats_change(propulsion_units : int, turns_to_trigger : int) -> void:
	emit_signal("sublight_stats_change", propulsion_units, turns_to_trigger)
