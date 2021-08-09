extends PoweredComponent
class_name SublightEngine


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal engine_propulsion(units)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _propulsion_units : int = 1
var _turns_to_trigger : int = 1
var _turns_passed : int = 0

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "propulsion_units" in info:
		_propulsion_units = info.propulsion_units
	if "turns_to_trigger" in info:
		_turns_to_trigger = info.turns_to_trigger

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func process_turn() -> void:
	if _power_available >= _power_required:
		_turns_passed += 1
		if _turns_passed == _turns_to_trigger:
			_turns_passed = 0
			emit_signal("engine_propulsion", _propulsion_units)
	else:
		_turns_passed = max(_turns_passed - 1, 0)
	# TODO: Handle Crew!


