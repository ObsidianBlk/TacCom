extends Node

enum CURSOR_MODE {LOOK=0, TARGET=1}
enum DAMAGE_TYPE {KINETIC=0, ENERGY=1, RADIATION=2}


onready var Ship_Node = preload("res://Object/Ship/Ship.tscn")


func create_TAC_ship() -> Ship:
	if not Ship_Node:
		return null
	
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
	
	return ship
