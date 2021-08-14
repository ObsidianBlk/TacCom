extends Entity

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------

signal freelook_exit(c, confirm)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------

export var main_color : Color = Color(0, 0.5, 1)				setget _set_main_color
export var hair_color : Color = Color(1, 0.5, 0)				setget _set_hair_color


onready var sprite_hex = get_node("Sprite_Hex")
onready var sprite_hair = get_node("Sprite_Hair")

# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_main_color(c : Color) -> void:
	main_color = c
	_UpdateColors()

func _set_hair_color(c : Color) -> void:
	hair_color = c
	_UpdateColors()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_UpdateColors()
	visible = false
	set_process_unhandled_input(false)

func _unhandled_input(event):
	if event.is_action_pressed("up", false):
		shift_to_edge(Hexmap.EDGE.UP, true)
	if event.is_action_pressed("up_left", false):
		shift_to_edge(Hexmap.EDGE.LEFT_UP, true)
	if event.is_action_pressed("down_left", false):
		shift_to_edge(Hexmap.EDGE.LEFT_DOWN, true)
	if event.is_action_pressed("down", false):
		shift_to_edge(Hexmap.EDGE.DOWN, true)
	if event.is_action_pressed("down_right", false):
		shift_to_edge(Hexmap.EDGE.RIGHT_DOWN, true)
	if event.is_action_pressed("up_right", false):
		shift_to_edge(Hexmap.EDGE.RIGHT_UP, true)
	if event.is_action_pressed("ui_cancel", false):
		visible = false
		set_process_unhandled_input(false)
		emit_signal("freelook_exit", coord, false)
	if event.is_action_pressed("ui_accept", false):
		visible = false
		set_process_unhandled_input(false)
		emit_signal("freelook_exit", coord, true)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _UpdateColors() -> void:
	if not sprite_hex or not sprite_hair:
		return

	var mathex = sprite_hex.material
	var mathair = sprite_hair.material
	
	var main_alt_color = Color(
		main_color.r * 0.6,
		main_color.g * 0.6,
		main_color.b * 0.6,
		main_color.a
	)
	
	var hair_alt_color = Color(
		hair_color.r * 0.6,
		hair_color.g * 0.6,
		hair_color.b * 0.6,
		hair_color.a
	)
	
	var hair_alt2_color = Color(
		hair_color.r * 0.8,
		hair_color.g * 0.8,
		hair_color.b * 0.8,
		hair_color.a
	)
	
	mathex.set_shader_param("color_1_to", main_color)
	mathex.set_shader_param("color_2_to", main_alt_color)
	
	mathair.set_shader_param("color_1_to", hair_color)
	mathair.set_shader_param("color_2_to", hair_alt_color)
	mathair.set_shader_param("color_3_to", hair_alt2_color)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_freelook(c : Vector2, mode : int = TacCom.CURSOR_MODE.LOOK) -> void:
	set_coord(c)
	set_process_unhandled_input(true)
	if mode == TacCom.CURSOR_MODE.LOOK:
		if sprite_hair:
			sprite_hair.visible = false
	elif mode == TacCom.CURSOR_MODE.TARGET:
		if sprite_hair:
			sprite_hair.visible = true
	visible = true
	var parent = get_parent()
	if parent is Region:
		parent.set_target_node(self)

func _on_masking_changed() -> void:
	pass # This is to ignore the hexmap masking visibility effect.
