extends Node
class_name ShipComponent


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal damage_taken(component)
signal destroyed(component)


# -----------------------------------------------------------
# Constants and Enums
# -----------------------------------------------------------


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _max_structure : float = 100
var _structure : float = 100
var _crew_count : int = 0


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func set_structure(sp : float) -> void:
	_structure = max(0, min(sp, _max_structure))

func get_structure() -> float:
	return _structure

func get_structure_percent() -> float:
	return _structure / _max_structure

func set_max_structure(msp : float, adjust_sp : bool = false) -> void:
	_max_structure = max(1, msp)
	if adjust_sp:
		_structure = _max_structure
	else:
		_structure = min(_structure, _max_structure)

func get_crew_count() -> int:
	return _crew_count

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

