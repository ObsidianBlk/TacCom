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
var _propulsion_units : int = 1
var _turns_to_trigger : int = 1
var _turns_passed : int = 0
var _ordered : bool = false

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "propulsion_units" in info:
		_propulsion_units = info.propulsion_units
	if "turns_to_trigger" in info:
		_turns_to_trigger = info.turns_to_trigger
	call_deferred("emit_signal", "sublight_stats_change", _propulsion_units, _turns_to_trigger)
	#emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------


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


func command(order : String) -> bool:
	if not _processing:
		if order == "SublightEngine":
			_ordered = true
			emit_signal("pull_power", _power_required)
			emit_signal("ordered", _ordered)
			return true
		return .command(order)
	return false


func belay(order : String) -> void:
	if not _processing:
		_ordered = false
		emit_signal("release_power")
		emit_signal("ordered", _ordered)
		.belay(order)


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

