extends Reference
class_name ShipComponent


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal structure_change(old_structure, new_structure, max_structure)
signal damage_blowback(type, amount)


# -----------------------------------------------------------
# Constants and Enums
# -----------------------------------------------------------


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _processing = false
var _processing_damage = false # Because damage can happen in the middle of processing.
var _processing_structure = false
var _processing_report = false
var _immortal = false
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
	
	if "immortal" in info:
		_immortal = not (info.immortal == false)
	
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
# Private Methods
# -----------------------------------------------------------

func _KineticDefense() -> float:
	return _kinetic_defense / 100

func _EnergyDefense() -> float:
	return _energy_defense / 100

func _RadiationDefense() -> float:
	return _radiation_defense / 100

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	match type:
		TacCom.DAMAGE_TYPE.KINETIC:
			var dmg = amount - (amount * _KineticDefense())
			_structure = max(0, _structure - dmg)
			#if emitBlowback and (_structure / ostruct) < 0.75:
			#	emit_signal("damage_blowback", type, dmg * 0.1)
		TacCom.DAMAGE_TYPE.ENERGY:
			var dmg = amount * (1.0 - _EnergyDefense())
			_structure = max(0, _structure - dmg) #max(0, _structure - (_structure * (dmg / 200)))
			#if emitBlowback and (_structure / ostruct) < 0.75:
			#	emit_signal("damage_blowback", TacCom.DAMAGE_TYPE.KINETIC, (ostruct - _structure) * 0.5)
		TacCom.DAMAGE_TYPE.RADIATION:
			print("Radiation detected... thankfully nothing is affected by this at the moment!")
	emit_signal("structure_change", ostruct, _structure, _max_structure)
	if _structure <= 0:
		_destroy_connections()


func _destroy_connections() -> void:
	for i in range(_connections.size()):
		var c = _connections.peek_value(i)
		if c.get_priority() != 0: # NOTE: This is a hack. Only "structures" are priority 0 ATM
			c.set_destroyed()

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------

func connect_to(c : ShipComponent, bidirectional : bool = false) -> void:
	if _connections.find(c) < 0:
		_connections.put(c.get_priority(), c)
		c.connect("structure_change", self, "_on_connected_structure_change", [c])
		if bidirectional:
			c.connect_to(self)

func get_priority() -> float:
	return _priority

func get_structure(all_connections : bool = true):
	if not _processing_structure:
		_processing_structure = true
		var s = _structure
		var ms = _max_structure
		if all_connections:
			for i in range(_connections.size()):
				var c = _connections.peek_value(i)
				var csi = c.get_structure()
				if csi != null:
					s += csi.structure
					ms += csi.max_structure
		_processing_structure = false
		return {
			"structure":s,
			"max_structure":ms
		}
	return null

func get_structure_percent() -> float:
	var si = get_structure()
	return si.structure / si.max_structure

func set_destroyed() -> void:
	if _structure > 0:
		var ostruct = _structure
		_structure = 0
		_destroy_connections()
		emit_signal("structure_change", ostruct, _structure, _max_structure)

func is_operating() -> bool:
	return _structure > 0 or _immortal

func report_info() -> void:
	if not _processing_report:
		_processing_report = true
		emit_signal("structure_change", _structure, _structure, _max_structure)
		for i in range(_connections.size()):
			var c = _connections.peek_value(i)
			c.report_info()
		_processing_report = false

func command(order : String, detail = null) -> bool:
	if not _processing:
		_processing = true
		for i in range(_connections.size()):
			var c = _connections.peek_value(i)
			if c.is_operating():
				if c.command(order, detail):
					_processing = false
					return true
		_processing = false
	return false

func belay(order : String) -> void:
	if not _processing:
		_processing = true
		for i in range(_connections.size()):
			var c = _connections.peek_value(i)
			if c.is_operating():
				c.belay(order)
		_processing = false

func process_turn() -> void:
	if not _processing:
		_processing = true
		for i in range(_connections.size()):
			var c = _connections.peek_value(i)
			if c.is_operating():
				c.process_turn()
		_processing = false

func damage(type : int, amount : float) -> void:
	if not _processing_damage:
		_processing_damage = true
		var operational = []
		for i in range(_connections.size()):
			var c = _connections.peek_value(i)
			if c.is_operating():
				operational.append(c)
		
		if operational.size() > 0:
			if _structure > 0:
				_handle_damage(type, amount * 0.5)
			amount = (amount * 0.5) / operational.size()
			for c in operational:
				c.damage(type, amount)
		elif _structure > 0:
			_handle_damage(type, amount)
		_processing_damage = false

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_connected_structure_change(old_structure : float, new_structure : float, max_structure : float, component : ShipComponent) -> void:
	pass

func _on_damage_blowback(type : int, amount : float) -> void:
	_handle_damage(type, amount)
