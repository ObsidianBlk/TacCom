extends Node2D
tool
class_name Region


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal hexmap(hm)
signal ship_added(ship)
signal ship_removed(ship)

signal ui_lock
signal ui_release



const MAP_COLOR_TAC = Color(0,1,0)
const MAP_COLOR_COM = Color(1,0,0)
const MAP_COLOR_ASTEROID = Color("#404040")

# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var bounds : Rect2 = Rect2(0,0,0,0)		setget _set_bounds

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _target : Node2D = null


# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var Ast_Node = preload("res://Object/Asteroid/Asteroid.tscn")


onready var hexmap_node : Hexmap = get_node("Hexmap")
onready var camera_node : Camera2D = get_node("Camera")

onready var ship_container : YSort = get_node("Ships")
onready var env_container : Node2D = get_node("Env")


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_bounds(b: Rect2) -> void:
	bounds = b
	if hexmap_node:
		hexmap_node.bounds = b

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	if hexmap_node:
		hexmap_node.bounds = bounds
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

func _add_entity(ent : Entity, ent_container : Node2D, signal_name : String = "") -> void:
	var ent_parent = ent.get_parent()
	if ent_parent != ent_container:
		if ent_parent != null:
			ent_parent.remove_child(ent)
		ent_container.add_child(ent)
	ent.set_hexmap(hexmap_node)
	if ent.has_signal("animating"):
		ent.connect("animating", self, "_on_entity_animating")
	if ent.has_signal("animation_complete"):
		ent.connect("animation_complete", self, "_on_entity_animation_complete")
	if signal_name != "":
		emit_signal(signal_name, ent)

func _remove_entity(ent : Entity, ent_container : Node2D, signal_name : String = "") -> void:
	var ent_parent = ent.get_parent()
	if ent_parent == ent_container:
		ent_parent.remove_child(ent)
		ent.clear_hexmap()
		if signal_name != "":
			emit_signal(signal_name, ent)
		ent.queue_free()

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
	_add_entity(ship, ship_container, "ship_added")

func remove_ship(ship : Ship) -> void:
	_remove_entity(ship, ship_container, "ship_removed")

func add_env(env : Entity) -> void:
	_add_entity(env, env_container)

func remove_env(env : Entity) -> void:
	_remove_entity(env, env_container)

func get_ships_in_faction(faction_name : String) -> Array:
	var sig = []
	if ship_container:
		for ship in ship_container.get_children():
			if ship.is_in_group(faction_name):
				sig.append(ship)
	return sig

func get_entity_at_coord(coord : Vector2):
	for child in ship_container.get_children():
		if child is Entity:
			if child.coord == coord:
				return child
	for child in env_container.get_children():
		if child is Entity:
			if child.coord == coord:
				return child
	return null


func create_map(img_src : String) -> void:
	if not hexmap_node:
		return
	
	var image : Image = Image.new()
	if image.load(img_src) == OK:
		var w = image.get_width()
		var h = image.get_height()
		hexmap_node.reset_map()
		hexmap_node.bounds = Rect2(0, 0, w, h)
		
		image.lock()
		for i in range(w):
			for j in range(h):
				var color = image.get_pixel(i, j)
				match color:
					MAP_COLOR_TAC:
						var ship = TacCom.create_TAC_ship()
						if ship:
							add_ship(ship)
							ship.coord = Vector2(i,j)
					MAP_COLOR_COM:
						pass
					MAP_COLOR_ASTEROID:
						var ast = Ast_Node.instance()
						if ast:
							add_env(ast)
							ast.coord = Vector2(i,j)
		image.unlock()

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_entity_animating() -> void:
	emit_signal("ui_lock")

func _on_entity_animation_complete() -> void:
	emit_signal("ui_release")

