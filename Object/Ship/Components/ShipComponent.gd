extends Reference
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
var _connections : PriorityQueue = PriorityQueue.new()
var _priority : float = 0
var _max_structure : float = 100
var _structure : float = 100

var _kinetic_defense : float = 0
var _energy_defense : float = 0
var _radiation_defense : float = 0


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary) -> void:
	if "priority" in info:
		_priority = info.priority
	
	if "structure" in info:
		_max_structure = info.structure
		_structure = _max_structure
	
	if "defense" in info and typeof(info["defense"]) == TYPE_ARRAY:
		for i in range(info.defense.size()):
			match(i):
				0:
					_kinetic_defense = info.defense[i]
				1:
					_energy_defense = info.defense[i]
				2:
					_radiation_defense = info.defense[i]

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------

func connect_to(c : ShipComponent, bidirectional : bool = false) -> void:
	if _connections.find(c) < 0:
		_connections.put(c.get_priority(), c)
		c.connect("structure_changed", self, "_on_connected_structure_changed", [c])
		if bidirectional:
			c.connect_to(self)

func get_priority() -> float:
	return _priority

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


func process_turn() -> void:
	# This method should be overridden to handle what a component will do
	# after the player clicks the "end turn" button
	pass

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_connected_structure_changed(old_structure : float, new_structure : float, max_structure : float, component : ShipComponent) -> void:
	pass

