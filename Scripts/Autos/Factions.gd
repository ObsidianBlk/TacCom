extends Node


var _factions = {}


func register(faction_name : String) -> void:
	if not faction_name in _factions:
		_factions[faction_name] = {
			faction_name : 100
		}

func get_list() -> Array:
	return _factions.keys()

func exits(faction_name : String) -> bool:
	return faction_name in _factions

func set_relation(faction_A : String, faction_B : String, relation : int, mutual : bool = false) -> void:
	if faction_A in _factions and faction_B in _factions:
		_factions[faction_A][faction_B] = relation
		if mutual:
			_factions[faction_B][faction_A] = relation

func set_relations(relation_list : Array) -> void:
	for rel in relation_list:
		if rel is Array and rel.size() >= 3 and rel.size() <= 4:
			callv("set_relation", rel)

func get_relation(faction_A : String, faction_B : String) -> int:
	if faction_A in _factions:
		if faction_B in _factions[faction_A]:
			return _factions[faction_A][faction_B]
	return 0
