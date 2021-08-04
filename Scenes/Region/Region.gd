extends Node2D
tool
class_name Region


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var target_path : NodePath = ""		setget _set_target_path


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var target : Node2D = null


# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var hexmap_node : Hexmap = get_node("Hexmap")
onready var camera_node : Camera2D = get_node("Camera")


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_target_path(t : NodePath) -> void:
	target_path = t
	if target_path != "":
		target = get_node(target_path)
	else:
		target = null


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	pass

func _process(_delta : float) -> void:
	if Engine.editor_hint:
		return
	
	var forceUpdate = false	
	if target == null:
		_set_target_path(target_path)
		if not target:
			return
		camera_node.current = true
		forceUpdate = true
	if camera_node.position != target.position or forceUpdate:
		#print("setting Camera")
		camera_node.position = target.position
		hexmap_node.position = target.position

# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------
func get_hexmap() -> Hexmap:
	return hexmap_node

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



