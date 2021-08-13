extends Node2D

signal game_ready

onready var logo_node = get_node_or_null("Logo")
onready var region = get_node_or_null("Region")

onready var Ship_Node = preload("res://Object/Ship/Ship.tscn")
onready var Ast_Node = preload("res://Object/Asteroid/Asteroid.tscn")


func _ready() -> void:
	Factions.register("TAC")
	Factions.register("COM")
	Factions.register("NEUTRAL")
	Factions.set_relation("TAC", "COM", -100, true)
	
	if region != null:
		call_deferred("_add_ships")

func _add_ships() -> void:
	var ast = Ast_Node.instance()
	if ast:
		ast.name = "Asteroid"
		region.add_env(ast)
		ast.coord = Vector2(5, 0)
	
	_add_ship_to_region(Vector2.ZERO)
	#_add_ship_to_region(Vector2(-3, 1))
	_add_ship_to_region(Vector2(3, -1))
	emit_signal("game_ready")

func _add_ship_to_region(coord : Vector2) -> void:
	var ship = Ship_Node.instance()
	ship.texture = load("res://Assets/Graphics/TAC_Ship.png")
	ship.light_color = Color("#ded6d2")
	ship.mid_color = Color("#a4a28c")
	ship.dark_color = Color("#838164")
	ship.faction = "TAC"
	
	ship.construct_ship({
		"Command":{
			"structure":"fore",
			"info":{
				"priority":10,
				"structure":30,
				"defense":[30, 0, 10],
				"commands":2
			}
		},
		"Engineering":{
			"structure":"mid",
			"info": {
				"priority":10,
				"structure":30,
				"defense":[30,0,10],
				"power":4
			}
		},
		"SublightEngine":{
			"structure":"aft",
			"info":{
				"priority":1,
				"structure":30,
				"defense":[30,0,10],
				"power_required":1,
				"propulsion_units":1,
				"turns_to_trigger":1
			}
		},
		"ManeuverEngine":{
			"structure":"fore",
			"info":{
				"priority":5,
				"structure":30,
				"defense":[30,0,10],
				"power_required":1,
				"units_per_turn": 2,
				"turns_to_trigger":1
			}
		},
		"Sensors":{
			"structure":"fore",
			"info":{
				"priority":9,
				"structure":30,
				"defense":[30,0,10],
				"power_required":1,
				"short_radius":3,
				"long_radius":3
			}
		},
		"IonLance":{
			"structure":"fore",
			"info":{
				"priority":2,
				"structure":30,
				"defense":[30,0,10],
				"power_required":2,
				"range":12,
				"damage":8
			}
		}
	})
	
	region.add_ship(ship)
	ship.coord = coord

func _on_logo_complete() -> void:
	remove_child(logo_node)
	logo_node.queue_free()


func _on_Player_game_over(faction):
	print ("Faction ", faction, "Has lost the game!")
