extends Node2D
tool
class_name Region


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal hexmap(hm)

# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _target : Node2D = null


# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var hexmap_node : Hexmap = get_node("Hexmap")
onready var camera_node : Camera2D = get_node("Camera")

onready var ship_container : YSort = get_node("Ships")
onready var env_container : Node2D = get_node("Env")


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	if hexmap_node:
		emit_signal("hexmap", hexmap_node)

func _process(_delta : float) -> void:
	if Engine.editor_hint:
		return
	
	if _target != null:
		if camera_node.position != _target.position:
			#print("setting Camera")
			camera_node.position = _target.position
			hexmap_node.position = _target.position

# -----------------------------------------------------------
# "Private" Methods
# -----------------------------------------------------------

func _add_entity(ent : Entity, ent_container : Node2D) -> void:
	var ent_parent = ent.get_parent()
	if ent_parent == ent_container:
		return
	if ent_parent != null:
		ent_parent.remove_child(ent)
	ent_container.add_child(ent)
	ent.set_hexmap(hexmap_node)

func _remove_entity(ent : Entity, ent_container : Node2D) -> void:
	var ent_parent = ent.get_parent()
	if ent_parent == ent_container:
		ent_parent.remove_child(ent)
		ent.clear_hexmap()

# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------
func get_hexmap() -> Hexmap:
	return hexmap_node

func set_target_node(target) -> void:
	if target == null:
		_target = null
		camera_node.current = false
	elif target is Node2D:
		_target = target
		camera_node.current = true

func add_ship(ship : Ship) -> void:
	_add_entity(ship, ship_container)

func remove_ship(ship : Ship) -> void:
	_remove_entity(ship, ship_container)

func add_env(env : Entity) -> void:
	_add_entity(env, env_container)

func remove_env(env : Entity) -> void:
	_remove_entity(env, env_container)

func get_ships_in_faction(faction_name : String) -> Array:
	var sig = []
	for ship in ship_container.get_children():
		if ship.is_in_group(faction_name):
			sig.append(ship)
	return sig

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------



