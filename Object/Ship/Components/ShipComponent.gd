extends Node
class_name ShipComponent


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------


# -----------------------------------------------------------
# Constants and Enums
# -----------------------------------------------------------


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _initialized = false
var _connections = []
var _max_structure : float = 100
var _structure : float = 100


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func init(info) -> bool:
	if _initialized:
		return false
	
	if "structure" in info:
		_max_structure = info.structure
		_structure = _max_structure
	
	_initialized = true
	return true

func connect_with(c : ShipComponent) -> void:
	if _connections.find(c) < 0:
		_connections.append(c)
		c.connect_with(self)

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


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

