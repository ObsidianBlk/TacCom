extends Node
class_name ShipComponent


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal structure_changed(old_structure, new_structure, max_structure)


# -----------------------------------------------------------
# Constants and Enums
# -----------------------------------------------------------


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _initialized = false
var _job_type = Crewman.TYPE.GENERAL
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

func connect_to(c : ShipComponent) -> void:
	if _connections.find(c) < 0:
		_connections.append(c)
		c.connect("structure_changed", self, "_on_connected_structure_changed", [c])


func get_structure() -> Dictionary:
	var s = _structure
	var ms = _max_structure
	for c in _connections:
		var csi = c.get_structure()
		s += csi.structure
		ms += csi.max_structure
	return {
		"structure":s,
		"max_structure":ms
	}

func get_structure_percent() -> float:
	var si = get_structure()
	return si.structure / si.max_structure


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_connected_structure_changed(old_structure : float, new_structure : float, max_structure : float, component : ShipComponent) -> void:
	pass

