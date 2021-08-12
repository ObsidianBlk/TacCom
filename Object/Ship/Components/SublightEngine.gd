extends PoweredComponent
class_name SublightEngine


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal sublight_propulsion(units)
signal sublight_stats_change(propulsion_units, turns_to_trigger)
signal ordered(o)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _max_propulsion_units : int = 1
var _min_turns_to_trigger : int = 1
var _propulsion_units : int = 1
var _turns_to_trigger : int = 1
var _turns_passed : int = 0
var _ordered : bool = false

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "propulsion_units" in info:
		_max_propulsion_units = info.propulsion_units
		_propulsion_units = info.propulsion_units
	if "turns_to_trigger" in info:
		_min_turns_to_trigger = info.turns_to_trigger
		_turns_to_trigger = info.turns_to_trigger
	call_deferred("emit_signal", "sublight_stats_change", _propulsion_units, _turns_to_trigger)
	#emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	._handle_damage(type, amount, emitBlowback)
	if (_structure / ostruct) < 0.75 and _turns_to_trigger > 0:
		if _propulsion_units > 1:
			_propulsion_units -= 1
		else:
			_turns_to_trigger += 1
			if _turns_to_trigger - _min_turns_to_trigger > 4:
				_turns_to_trigger = 0
				_propulsion_units = 0
		emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func report_info() -> void:
	if not _processing:
		emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)
		emit_signal("ordered", _ordered)
		.report_info()


func process_turn() -> void:
	if not _processing:
		if _power_available >= _power_required:
			_turns_passed += 1
			if _turns_passed == _turns_to_trigger:
				_turns_passed = 0
				emit_signal("sublight_propulsion", _propulsion_units)
				emit_signal("release_power")
				_ordered = false
		else:
			_turns_passed = max(_turns_passed - 1, 0)
		
		# TODO: Handle Crew!
		
		.process_turn()


func command(order : String, detail = null) -> bool:
	if not _processing:
		if order == "SublightEngine":
			_ordered = true
			emit_signal("pull_power", _power_required)
			emit_signal("ordered", _ordered)
			return true
		return .command(order, detail)
	return false


func belay(order : String) -> void:
	if not _processing:
		if order == "SublightEngine" and _ordered:
			_ordered = false
			emit_signal("release_power")
			emit_signal("ordered", _ordered)
		.belay(order)


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

