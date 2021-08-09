extends Node2D

signal game_ready

onready var logo_node = get_node_or_null("Logo")
onready var region = get_node_or_null("Region")

onready var Ship_Node = preload("res://Object/Ship/Ship.tscn")


func _ready() -> void:
	Factions.register("TAC")
	Factions.register("COM")
	Factions.register("NEUTRAL")
	Factions.set_relation("TAC", "COM", -100, true)
	
	if region != null:
		call_deferred("_add_ships")

func _add_ships() -> void:
	_add_ship_to_region(Vector2.ZERO)
	_add_ship_to_region(Vector2(-3, 1))
	_add_ship_to_region(Vector2(3, -1))
	emit_signal("game_ready")

func _add_ship_to_region(coord : Vector2) -> void:
	var ship = Ship_Node.instance()
	ship.texture = load("res://Assets/Graphics/TAC_Ship.png")
	ship.light_color = Color("#ded6d2")
	ship.mid_color = Color("#a4a28c")
	ship.dark_color = Color("#838164")
	ship.faction = "TAC"
	region.add_ship(ship)
	ship.coord = coord

func _on_logo_complete() -> void:
	remove_child(logo_node)
	logo_node.queue_free()


