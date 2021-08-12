extends Entity

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------

signal freelook_exit(c, confirm)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------

export var color : Color = Color(1, 0.5, 0)				setget _set_color
export (Hexmap.EDGE) var edge : int = Hexmap.EDGE.UP	setget _set_edge
export var all_edges : bool = true						setget _set_all_edges


onready var sprite_hex = get_node("Sprite_Hex")
onready var sprite_hair = get_node("Sprite_Hair")

# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_color(c : Color) -> void:
	color = c
	_UpdateColorAndEdge()

func _set_edge(e : int) -> void:
	for i in Hexmap.EDGE.keys():
		if Hexmap.EDGE[i] == e:
			edge = e
			_UpdateColorAndEdge()
			break

func _set_all_edges(e : bool) -> void:
	all_edges = e
	_UpdateColorAndEdge()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_set_color(color)
	visible = false
	set_process_unhandled_input(false)

func _unhandled_input(event):
	if event.is_action_pressed("up", false):
		shift_to_edge(Hexmap.EDGE.UP)
	if event.is_action_pressed("up_left", false):
		shift_to_edge(Hexmap.EDGE.LEFT_UP)
	if event.is_action_pressed("down_left", false):
		shift_to_edge(Hexmap.EDGE.LEFT_DOWN)
	if event.is_action_pressed("down", false):
		shift_to_edge(Hexmap.EDGE.DOWN)
	if event.is_action_pressed("down_right", false):
		shift_to_edge(Hexmap.EDGE.RIGHT_DOWN)
	if event.is_action_pressed("up_right", false):
		shift_to_edge(Hexmap.EDGE.RIGHT_UP)
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
func _UpdateColorAndEdge() -> void:
	if not sprite_hex or not sprite_hair:
		return
	var c = color if all_edges else Color(1,1,1,0)
	var mathex = sprite_hex.material
	var mathair = sprite_hair.material
	for e in Hexmap.EDGE.keys():
		var i = Hexmap.EDGE[e]
		mathex.set_shader_param("color_%s_to"%[i+1], color if i == edge else c)
		mathair.set_shader_param("color_%s_to"%[i+1], c)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_freelook(c : Vector2) -> void:
	set_coord(c)
	set_process_unhandled_input(true)
	visible = true
	var parent = get_parent()
	if parent is Region:
		parent.set_target_node(self)
