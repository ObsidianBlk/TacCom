extends Node2D

onready var logo_node = get_node_or_null("Logo")
onready var region = get_node_or_null("Region")

onready var Ship_Node = preload("res://Object/Ship/Ship.tscn")


func _ready() -> void:
	Factions.register("TAC")
	Factions.register("COM")
	Factions.register("NEUTRAL")
	Factions.set_relation("TAC", "COM", -100, true)
	
	if region != null:
		var ship = Ship_Node.instance()
		ship.texture = load("res://Assets/Graphics/TAC_Ship.png")
		ship.light_color = Color("#ded6d2")
		ship.mid_color = Color("#a4a28c")
		ship.dark_color = Color("#838164")
		ship.faction = "TAC"
		print("Adding ship to region")
		region.add_ship(ship)
		region.set_target_node(ship)

func _on_logo_complete() -> void:
	remove_child(logo_node)
	logo_node.queue_free()


